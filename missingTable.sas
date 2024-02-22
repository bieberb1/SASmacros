/*****************************************************************
	Name:		missingTable
	Purpose:	Create table showing the percent missing for every variable in a dataset
	Parameters:	dsn = [dataset]
				where = [any restriction on dataset]
				print = [1 if you want the table printed]
				class = [class variable to compare missingness]
				varlist = [list of variables that the table should be restricted to]
				verbose = [1 if user wants type, flag (for missing 15%), min, max, mean, std]
				
	Create Date:	February 27, 2014 (updated)
	Creator:		Brian Bieber
	
	Example:		
	Notes:		much faster than missing_table macro
				flag those with missing > 15%

				Current macro dependencies
					storeTitles
					missCode
					titleNextCum
******************************************************************/

%macro missingTable (	dsn=/*dataset name*/, 
						where=1/*restriction*/, 
						print=1/*print results*/, 
						class=/*column variable - default = none*/, 
						varlist=/*list of variables, if not specificed, all included*/, 	
						formatVar=/*format for variables in final output*/, 
						html=/*1->produce html output*/, 
						htmlName=missingTable/*name of html file, default='missingTable'*/, 
						verbose=1/*stats for continuous variables if no class*/,
						cleanup=/*1 deletes tables made by macro*/
					);
	%local i varlist2 nRecords ds lib;
	proc datasets nodetails nolist library=work; delete statsAll missChar statsNum dsnTrim:; run;
	%storeTitles();
	proc format;
		value $charMiss 
				"", " "	= 'Missing'
				OTHER 	= 'Non-missing';
		value numMiss 
				., .O, .U = 'Missing'
				OTHER 	= 'Non-missing';
	run;

	data dsnTrim1;
		set &dsn  (where = (&where.));;
		%if &varlist ne  %then keep &varlist. %if %length(&class.) > 1 %then &class.;;
	run;
	
	*If empty varlist, then grab all the variables AND order them alphabetically;
	%if &varList. = %then %do;
		proc sql NOPRINT; SELECT name INTO :varList SEPARATED BY ' '  FROM dictionary.columns WHERE LIBNAME='WORK' AND MEMNAME = "DSNTRIM1" ORDER BY name; quit;
	%end;
	data varOrderM (keep = order variable);
		length variable $50.;
		
		
		%do i = 1 %to %sysfunc(countw(&varlist., %str( )));
			order = &i.;
			variable = "%scan(&varlist, &i.)";
			output;
		%end;
		
	run;
	proc sort data=varOrderM; by variable; run;
	
	proc sql NOPRINT; SELECT count(*) INTO :nRecords FROM &dsn. WHERE &where.; quit;



	%if %length(&class.) > 0 %then %do;  /*If class variable is listed*/
		proc sql NOPRINT;
			SELECT name INTO :varList2 SEPARATED BY ' '
			FROM DICTIONARY.columns 
			WHERE libname = 'WORK' AND memname = "DSNTRIM1" AND upcase(name) NE "%upcase(&class.)";
		quit;
					
		data dsnTrim2;	
			set dsnTrim1;
			%missCode(&varlist2.);
			keep m_: %if %length(&class.) > 1 %then &class.;;
		run;
		
		proc summary data=dsnTrim2 nway mean;
			class &class.;
			var m_:;
			output out = missWide1 (drop = _TYPE_ _FREQ_);
		run;
	
		proc transpose data=missWide1 out = missWide2; 
			id _STAT_;
			by &class.;
		run;
		proc sort data=missWide2; by _NAME_; run;
		proc transpose data=missWide2 out=missLong;
			by _NAME_;
			id &class.;
			var mean;
			format mean percent8.1;
		run;
		data statsAll;
			set missLong (rename = (_NAME_ = variable));
			variable = substr(variable, 3);
			if max(of _NUMERIC_) > 0.15 then flag = 'X';
		run;
		
		%if &print. = 1 %then %do;
			%if &html. = 1 %then ods html style = journal file = "&htmlName..html";;
			%titleNextCum(Missingness for variables in &dsn - by &class.);
			%titleNextCum(N records: %trim(%left(&nRecords.)));
			%if %length(&where) > 1 %then %do; %titleNextCum(Restriction [&where]); %end;
			proc print data=statsAll; id variable; run;
			title;
			%if &html. = 1 %then ods html close;;
		%end;
	%end;
	%else %if %length(&class.) le 0 %then %do;	/*No class variable - include basic stats*/
		*Count number of numeric and character variables;
		proc sql NOPRINT;
			SELECT count(*) INTO :charN
			FROM dictionary.columns
			WHERE libname="WORK" AND memname="DSNTRIM1" AND type='char';
	
			SELECT count(*) INTO :numN
			FROM dictionary.columns
			WHERE libname="WORK" AND memname="DSNTRIM1" AND type='num';
		quit;
	
		*Numeric;
			%if &numN ne 0 %then %do;
			proc summary data=dsnTrim1 mean min max n std;
				var _NUMERIC_;
				output out = statsNum (drop = _TYPE_ _FREQ_);
			run;
	
			proc transpose data=StatsNum out=StatsNum;
				id _STAT_;
			run;
			data statsNum;
				set statsNum (where = (_Name_ not in ('_TYPE_' '_FREQ_')));
				percMiss = (&nRecords-n)/&nRecords;
				rename _name_ = variable;
			run;
			%end;
	
		*Character;
			%if %eval(&charN > 0) %then %do;
			proc sql NOPRINT;
				SELECT name INTO: charList SEPARATED BY ' '
				FROM dictionary.columns
				WHERE libname = "WORK" AND memname = "DSNTRIM1" AND type='char';
	
				CREATE table missCharWide AS
					SELECT 	
					%do i=1 %to %sysfunc(countw(&charList., %str( )));
						%let currChar = %scan(&charlist, &i.);
						%if &i. = 1 %then 	max(0,nmiss(&currChar.)/count(*)) AS &currChar.;
						%else 				, max(0,nmiss(&currChar.)/count(*)) AS &currChar.;
					%end;
					FROM DSNTRIM1;
			quit;
			proc transpose data=missCharWide out=missChar (rename = (col1=percMiss)) name=variable; run;
			%end;
	

		data statsAll;
			format variable $40.;
			set %if %eval(&numN > 0) %then statsNum (in=inN);
				%if %eval(&charN > 0) %then missChar (in=inC);;
			%if %eval(&numN > 0) %then if inN then type='N';;
			%if %eval(&charN > 0) %then if inC then type='C';;
			if percMiss > 0.15 then flag = 'X';
			
			%if %length(&formatVar.) %then variable = upcase(variable);; *BB20211109: upcase variable to allow format variable that does not require correct casing;

		run;
		
		%if %length(&varList.) %then %do;
		proc sql NOPRINT undo_policy=none;
			CREATE TABLE statsAll AS
			SELECT a.*, b.order
			FROM statsAll AS a LEFT JOIN varOrderM AS b
			ON upcase(a.variable) = upcase(b.variable)
			ORDER BY variable;
		quit;
		%end;
	
	
		%if &print. = 1 %then %do;
		%if &html. = 1 %then ods html style = journal file = "&htmlName..html";;
		*All;
		%titleNextCum(Missingness for variables in &dsn);
		%titleNextCum(N records: %trim(%left(&nRecords.)));
		 %if %length(&where) > 1 %then %do; %titleNextCum(Restriction [&where]); %end;
		proc sql;
			SELECT variable LABEL='VARIABLE' %if %length(&formatVar.) %then format &formatVar.;, percMiss format percent8.1 
						%if &verbose.=1 %then %do; , type, flag %if %eval(&numN > 0) %then %do; , min FORMAT 8.2, max FORMAT 8.2, mean FORMAT 8.2, std FORMAT 8.2 %end; %end;
			FROM statsAll
			ORDER BY %if %length(&varList.) %then order,; variable;
		quit;
		title;
		%if &html. = 1 %then ods html close;;
		%end;
	%end;
	%if &cleanup. = 1 %then %do;
		proc datasets nodetails nolist library=work; 
			delete
				dsnTrim:
				missChar
				missCharWide
				missWide:
				missLong
				statsAll  
				statsNum 	
				varOrderM
			; 
		run;
	%end;
%mend missingTable;
