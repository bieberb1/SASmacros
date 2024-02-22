/*****************************************************************
	Name:		meanTable
	Purpose:		Create a 'table one' showing mean/% characteristics by a class variable
	Parameters:	[dsn]=data set
				[where]=restrictions
				[class]=column variable
				[varlist]=list of variables to include in the table
				[html]=create html output
				[htmlName] = name for HTML table
				[weight]=enter weight variable if weighted results desired
				[pvalue]=calculate p-value, with class variable as a predictor
				[pvalueAdj]=Variables to include as adjustments when calculating the p-value
				[pvalueExclude]=Variables to exclude when calculating p-values
				[format1to10]=format for variabes where mean is 1-10
				[format10to100] = format for variables where mean is 10-100, 
				[formatge100]=format for variables where mean is 100+, 
				[formatPercent]=format for percent variables, 
				[formatPvalue]=format for p-values
				[formatVar]=format for variables so not just variable name (use upper case when making format)
				[IQRlist] = variables that you want displayed as median (IQR)
				[colLabel = label column title (e.g. _1 = "HCV+" _0 = "HCV-")
				[colOrder] = change default order of class columns by listed the variable names in desired order
	Create Date:	August 15, 2012
	Creator:		Brian Bieber
	
	Example:		%meanTable(dsn=dopps4.m_f, varlist= gender mage mvautype,  html=1);
	Notes:		Does not calculate p-value for categorical variables
				BB130321 - added check options label to avoid warn!ng statment
				BB130708 - added parameters so the formats can be controlled
				BB130712 - added p-values for categorical (> 2 categories) variables
				BB140115 - added check for min and max to format continuous variables with mean < 1 correctly
				BB140226 - added a call to %missingTable to add a column for percent missing
				BB140908 - added IQRlist to select variable to show for median(IQR) instead of mean (SD) - p-value still mean-based
				BB150420 - added option to add format row variables in final table output
				BB160725 - changed patientN calculation to use input dataset and consider all variables in varlist
				BB161026 - fixed patientN calculation by making numVarsComma and charVarscomma dependent only on variable type (not format)
				BB170814 - added error check for patientN in the cases where there was only a single character or numeric variable
				BB171020 - added a fix for when only a single character variable (regardless of number of numerical variables)
				BB181112 - added where statement to patientN calculation to exclude cases where class variable is mi$$ing; should also consider reporting percent mi$$ing
				BB181112 - Also note that if dataset contains a _Name_ variable, proc transpose will call the column _0 instead of col1. Current solution is to drop _Name_ variable
				BB201104 - Temporary kludge to prevent character variables with more than one level from creating an error when p-value selected - works, but no p-value provided
				BB210414 - Added overall option to include column for overall.
				BB210414 - Added code to detect UTF session and change non-breaking space character
				BB211208 - Added option to label columns and change order. Also changed from switchLabel to inLabel to just set labeling back to what it was coming in
******************************************************************/

	/*
	BB150420 - code to create variable format from dataset;
	data fmt;
		set driverImport (keep = variable nameShortfinal rename = (variable = start nameShortFinal = label));
		fmtname = '$rowFormat';
	run;
	proc format cntlin=fmt; quit;
	*/
	
	
	%macro meanTable(dsn=/*dataset name*/, 
					where=1 /*restrictions*/, 
					class= /*columns*/, 
					overall= /*include overall*/, 
					varlist= /*variable list*/, 
					html=0 /*ods html file 1=yes*/, 
					htmlName=/*name of html file*/, 
					weight= /*variable with weights*/, 
					pvalue=0 /*calculate p-values*/, 
					pvalueAdj= /*Variables to adjust p-values*/, 
					pvalueExclude=/*Variables to exclude from p-value calculation*/, 
					format1to10=8.2 /*Format for variables ranging from 1-10*/, 
					format10to100 = 8.1 /*Format for variables ranging from 10-100*/, 
					formatge100=8.0 /*Format for variables ranging from 100+*/, 
					formatPercent=percent8.1 /*Format for percentage variables*/, 
					formatPvalue=pvalue6.3 /*format for p-values*/, 
					formatVar = /*format for variables listed in rows*/ , 
					IQRlist = /*variables to show IQR*/, 
					rowLevel=nPts /*Label for n row*/, 
					colLabel= /*Labels for columns*/, 
					colOrder=/*Order for columns*/,
					cleanup=/*1 deletes tables made by macro*/);
		%local openODS numVars charVars numVarsComma charVarsComma numVarsN charVarsN j i k nLevels pvalueClassAdj nClassLevels IQRfmt;

		*%let charVarsComma = ;
		*%let numVarsComma = ;
		options nosyntaxcheck;  *BB121019 - added to prevent obs=0 and no further datasets in batch mode;
		ods select none;
		proc datasets nolist nodetails lib=work memtype=data; delete MeanTable: freqTable: tableF: GEE_pEst mixed_tests3 stats_all IQR:; run;
		ods select all;

		*Check if ods destinations is open;
		%let openODS = ;
		proc sql NOPRINT;
			SELECT DESTINATION INTO :openODS SEPARATED BY ' ' FROM dictionary.destinations
			/*WHERE DESTINATION NOT IN ('LISTING' 'OUTPUT')*/
			WHERE DESTINATION IN ('HTML' 'HTML5(EGHTML)' 'PDF' 'RTF' 'PRINTER' 'MARKUP' 'DOCUMENT')
			;
		quit;
		
		%if %length(&openODS.)  %then %do i = 1 %to %sysfunc(countw(&openODS., %str( )));
			ods %scan(&openODS., &i., %str( )) SELECT NONE;
		%end;
		
		*If empty varlist, then grab all the variables AND order them alphabetically;
		%if &varList. = %then %do;
			proc sql NOPRINT; SELECT name INTO :varList SEPARATED BY ' '  FROM dictionary.columns WHERE LIBNAME='WORK' AND MEMNAME = "%upcase(&dsn.)" ORDER BY name; quit;
		%end;
		data varOrder (keep = order variable);
			length variable $50.;
			
			
			%do i = 1 %to %sysfunc(countw(&varlist., %str( )));
				order = &i.;
				variable = "%scan(&varlist, &i.)";
				output;
			%end;
			
		run;
		proc sort data=varOrder; by variable; run;

		*Determine percent missing;
		%missingTable(dsn=&dsn., print=0, where=&where. %if &class. ne  %then AND not missing(&class.); %if %length(&varlist.) %then , varlist=&varlist.;); *this makes a statsAll table with variables - variable, perc_miss;

		*Determine type of variable;
			%local varType numVars charVars;

			proc contents data=&dsn noprint out=varType 
				(keep = name type format where = 
					(upcase(name) in 
						(
							%do i = 1 %to %sysfunc(countw(&varlist., %str( ))); 
								"%upcase(%scan(&varlist., &i.))" 
							%end;
						)
					)
				); 
			run;

			proc sql NOPRINT; 
				SELECT name INTO :numVars SEPARATED BY ' ' FROM varType WHERE type = 1 AND (missing(format) OR format in ('MMDDYY' 'NOYES' 'RMUSE' 'NOYES' 'NOMYES' ));
				SELECT name INTO :charVars SEPARATED BY ' ' FROM varType WHERE type = 2 OR (type = 1 AND not missing(format) AND format not in ('MMDDYY' 'NOYES' 'RMUSE' 'NOYES' 'NOMYES'));
				
				*BB161026 - dropped clauses below as these are only used to count non-missing variables;
				SELECT name INTO :numVarsComma SEPARATED BY ',' FROM varType WHERE type = 1 /*AND (missing(format) OR format in ('MMDDYY' 'NOYES' 'RMUSE' 'NOYES' 'NOMYES' ))*/;
				SELECT name INTO :charVarsComma SEPARATED BY ',' FROM varType WHERE type = 2 /*OR (type = 1 AND not missing(format) AND format not in ('MMDDYY' 'NOYES' 'RMUSE' 'NOYES' 'NOMYES'))*/;

				SELECT count(*) INTO :numVarsN FROM varType WHERE type = 1 /*AND (missing(format) OR format in ('MMDDYY' 'NOYES' 'RMUSE' 'NOYES' 'NOMYES' ))*/;
				SELECT count(*) INTO :charVarsN FROM varType WHERE type = 2 /*OR (type = 1 AND not missing(format) AND format not in ('MMDDYY' 'NOYES' 'RMUSE' 'NOYES' 'NOMYES'))*/;
			quit;
			
		%local inLabel;
		%let inLabel = %sysfunc(getoption(LABEL));
		options nolabel;

		%if &numVars. ne  %then %do;
			proc means data=&dsn n mean median std noprint;
				where &where. %if &class. ne %then AND not missing(&class.);; 
				%if &class. ne %then class &class.;;
				%if &weight ne %then weight &weight.;;
				var &numVars.;
				output out = meanTable1 %if %length(&class.) %then %do; (where = (_type_ = 1 %if &overall.=1 %then OR _type_=0;)) %end;;	
			run;

			%if &overall.=1 AND &class. ne %then %do;
				data meanTable1;
					set meanTable1;
					if _type_ = 0 then do;
						%if %vtype(&dsn., &class.) = C %then %do; &class. = 'All'; %end;
						%else %do; &class. = -999; %end;
					end;
				run;
			%end;
			%if &IQRlist. ne %then %do;
				%do k = 1 %to %sysfunc(countw(&IQRlist., %str( )));
					%let currIQRvar = %scan(&IQRlist., &k.);
					proc summary data=&dsn.;
						where &where. %if &class. ne %then AND not missing(&class.);; 
						class &class.;
						%if &weight ne %then weight &weight.;;
						output out = IQR&k. (drop = _FREQ_ %if &class ne %then %do; where = (_type_ = 1 %if &overall.=1 %then OR _type_=0;) %end;)
								n(&currIQRvar.) = n
								min(&currIQRvar.) = min
								p25(&currIQRvar.) = p25
								p50(&currIQRvar.) = p50
								p75(&currIQRvar.) = p75
								max(&currIQRvar.) = max
							;	
					run;
					data IQRlong;
						length variableTemp $50.;
						length p50iqr $20.;
						set %if &k. ne 1 %then IQRlong;
							IQR&k. (in=inNew);

						if inNew then do;
							%if %length(&class.) %then %do;
								if _type_ = 0 then do;
									%if %vtype(&dsn., &class.) = C %then %do; &class. = 'All'; %end; 
									%else %do; &class. = -999; %end;
								end;
							%end;

							if 0 le p50 le 1 then do;
								if max = 1 AND min=0 OR (max=1 AND min=1) OR (max=0 AND min=0) then p50iqr = strip(put(p50, &formatPercent.)) || "[" || strip(put(p25, &formatPercent.)) ||  "," || strip(put(p75, &formatPercent.)) || "]";
								else p50iqr = strip(put(p50, &format1to10.)) || "[" || strip(put(p25, &format1to10.)) ||  "," || strip(put(p75, &format1to10.)) || "]";
							end;
							else if p50 ge 100 then 	p50iqr = strip(put(p50, &formatge100.)) || "[" || strip(put(p25, &formatge100.)) ||  "," || strip(put(p75, &formatge100.)) || "]";
							else if 1 le p50 le 10 then p50iqr = strip(put(p50, &format1to10.)) || "[" || strip(put(p25, &format1to10.)) ||  "," || strip(put(p75, &format1to10.)) || "]";
							else 						p50iqr = strip(put(p50, &format10to100.)) || "[" || strip(put(p25, &format10to100.)) ||  "," || strip(put(p75, &format10to100.)) || "]";


							variableTemp = "&currIQRvar."; *Created as temporary (replaced below) so I can ignore case here;
						end;

						
					run;
				%end;
				proc sort data=IQRlong; by variableTemp &class.; run;
			proc transpose data=IQRlong out=IQRwide (drop=_Name_ %if &overall.=1 AND %length(&class.) %then %do; %if %vtype(&dsn., &class.) = N AND &class. ne %then rename = (N999=All); %end;);
					by variableTemp;
					%if &class. ne %then ID &class.;;
					var p50iqr;
				run;
			%end;

			proc transpose data=meanTable1 out=meanTable2 (drop = /*min max*/ rename = (_Name_ = variable));
				%if &class. ne %then by &class.;;
				id _stat_;
				var &numVars.;
			run;

			data meanTable3;
				length variable $200.;
				length stat $20.;
				set meanTable2;
				/*BB130708 - wasn't sure why the round was in the code 2 lines below - it may serve a purpose so I commented out instead of deleting completely*/
				if not missing(mean) then do;
					if 0 le mean le 1 then do;
						if max = 1 AND min=0 OR max=1 AND min=1 OR max=0 AND min=0 then stat = strip(put(/*round(mean, 0.001)*/mean, &formatPercent.));  
						else stat = strip(put(/*round(mean, 0.001)*/mean, &format1to10.)) || "(" || strip(put(round(std, 0.01),&format1to10.))|| ")"; 
					end;
					else if mean ge 100 then 	stat = strip(put(/*round(mean, 1)*/mean, &formatge100.)) || "(" || strip(put(round(std, 1),&formatge100.)) || ")";
					else if 1 le mean lt 10 then stat = strip(put(/*round(mean, 0.01)*/mean, &format1to10.)) || "(" || strip(put(round(std, 0.01),&format1to10.))|| ")";
					else 						stat = strip(put(/*round(mean, 0.1)*/mean, &format10to100.)) || "(" || strip(put(round(std, 0.1),&format10to100.))|| ")";
				end;
			run;
			proc sort data=meanTable3; by variable; run;

		proc transpose data=meanTable3 out = meanTable4 (drop = _Name_  %if &overall.=1 AND %length(&class.) %then %do; %if %vtype(&dsn., &class.) = N  %then rename = (N999=All); %end;);
				by variable;
				%if &class. ne %then id &class.;;
				var stat;
			run;

			*Get the right case for the variable;
			%if &IQRlist. ne %then %do;
			proc sql;
				CREATE TABLE IQRwide_case as
				SELECT a.variable, b.*
				FROM  	meanTable4 as a RIGHT JOIN
						IQRwide AS b
				ON upcase(a.variable) = upcase(b.variableTemp)
				ORDER BY variable;
			quit;
	

			data meanTable4;
				merge 	meanTable4
						IQRwide_case (drop = variableTemp);
				by variable;
			run;
			%end;

			proc sql NOPRINT;
				CREATE TABLE meanTable5 AS
				SELECT a.*, b.order
				FROM meanTable4 AS a LEFT JOIN varOrder AS b
				ON upcase(a.variable) = upcase(b.variable)
				ORDER BY variable;
			quit;

			%if &pvalue. ne 0 AND &class. ne  %then %do i = 1 %to %sysfunc(countw(&numVars., %str( )));
				*ods listing close;
				ods exclude ALL;
				%let currVar = %scan(&numVars., &i.);
				%if not %index(%upcase(&pvalueExclude.),%upcase(&currVar.)) > 0  %then %do; *pValueExclude;

				proc sql NOPRINT;
					SELECT count(distinct &currVar.) INTO :nLevels
					FROM &dsn.
					WHERE &where.;
				quit;
				
				
				*Determine if any class variables in &pvalueAdj;
				%let pvalueClassAdj = ;
				%if &pvalueAdj. ne %then %do;
					proc sql NOPRINT;
						SELECT name INTO :pvalueClassAdj
						FROM dictionary.columns
						WHERE libname = 'WORK' AND memname = "%upcase(&dsn.)" AND upcase(name) in (%do v = 1 %to %sysfunc(countw(&pvalueAdj., %str( ))); 
							"%upcase(%scan(&pvalueAdj., &v.))" %end;) AND type = 'char';
					quit;
				%end;

				%if &nLevels. ne 2 %then %do;
					proc mixed data=&dsn.;
						where &where. AND not missing(&class.) AND not missing(&currVar.);
						class facid &class.  &pvalueClassAdj.;
					 	model &currVar. = &class. %if &pvalue. ne 0 %then &pvalueAdj.;;       

					 	repeated /  type=cs sub=facid; 

						ods output	Tests3			= mixed_Tests3 (where = (upcase(effect)="%upcase(&class.)"));				
					run;
					%if &i. = 1 AND %sysfunc(exist(mixed_tests3)) %then %do; /*BB130715 - this could be a problem if the first one fails*/
						data pvalues; set mixed_tests3; length variable $50.; variable = "&currVar."; pvalue=probF;  run;
					%end;
					%else %if %sysfunc(exist(mixed_tests3)) %then %do;
						data pvalues; set pvalues mixed_tests3(in=new); if new then do; variable="&currVar."; pvalue=probF; end; run; 
					%end;
					proc datasets library=work memtype=data nolist nodetails; delete mixed_tests3; run;
				%end;
				%else %do;
					proc genmod data=&dsn. descending namelen=50;
						where &where. AND not missing(&class.) AND not missing(&currVar.);
						class facid &class. &pvalueClassAdj.;
						model &currVar. = &class. %if &pvalue. ne 0 %then &pvalueAdj.; / dist=bin link=logit type3;
						repeated subject=facid / type=cs;  

						
						ods output 	type3		=GEE_type3 (where = (upcase(effect)="%upcase(&class.)" AND not missing(probChiSq)) rename=(source=effect));
					run;
					%if &i. = 1 AND %sysfunc(exist(GEE_type3)) %then %do;
						data pvalues; set GEE_type3; length variable $50.; variable = "&currVar."; pvalue=probChiSq; run;
					%end;
					%else %if %sysfunc(exist(GEE_type3)) %then %do;
						data pvalues; set pvalues GEE_type3(in=new); if new then do; variable="&currVar."; pvalue=probChisq; end; run; 
					%end;
					proc datasets library=work memtype=data nolist nodetails; delete GEE_type3; run;
				%end;
				proc sort data=pvalues; by variable; run;
				*ods listing;
				ods exclude none;
				%end; *pvalue Exclude;
			%end;
			data meanTableF;
				%if &pvalue. = 1 %then %do;
				merge 	meantable5
						pvalues (keep = variable pvalue);
				by variable;
				format pvalue &formatPvalue.;
				%end;
				%else %do;
				set meanTable5;
				by variable;
				%end;
			run;
			proc sort data=meanTableF; by order; run;
		%end;

		%if &charVars. ne  %then %do;
			*ods listing close;
			ods exclude all;
			%if &class ne  %then %do; proc sort data=&dsn.; by &class; run; %end;
			proc freq data=&dsn.;
				%if &class ne  %then by &class.;;
				where &where. %if &class. ne %then AND not missing(&class.);;
				%if &weight ne %then weight &weight.;;
				tables &charVars.;
				ods output onewayfreqs = freqTable1;
			run;
			%if &overall. ne AND &class. ne %then %do;
				proc freq data=&dsn.;
					where &where. AND not missing(&class.);;
					%if &weight ne %then weight &weight.;;
					tables &charVars.;
					ods output onewayfreqs = freqTable1all;
				run;

				data freqTable1;
					set freqTable1all (in=inAll)
						freqTable1
					;
					if inAll then %if %vtype(&dsn., &class.) = C %then &class. = 'All'; %else &class.=-999;;
				run;
			%end;
			*ods listing;
			ods exclude none;
			
			*Next 2 steps allow inclusion of classes where all data is missing and keeps order of responses;
			proc sql;
				CREATE TABLE tableLevels AS
				SELECT %if &class. ne  %then &class.,; table, count(*) AS nLevels
				FROM freqTable1
				GROUP BY %if &class. ne  %then &class.,;  table;
			quit;
			
			proc sort data=freqTable1; by %if &class. ne  %then &class.; table; run;
			data freqTable2;
				merge 	freqTable1
						tableLevels;
				by %if &class. ne  %then &class.; table;				
			run;
						

			proc sort data=freqTable2; by %if &class. ne  %then &class.; table; run;
			data freqTable3;
				set freqTable2;
				by %if &class. ne  %then &class.; table;
				retain charVar;
				retain subOrder 0;
				length charVar variable $200. freq $20.;
				array charArray{*} %do i = 1 %to %sysfunc(countw(&charVars., %str( ))); F_%scan(&charVars., &i.) %end;;
				if first.table then do;
					subOrder+1;
					charVar = substr(table, 7);
					variable = substr(table, 7);						
					freq = "";
					output;
					if nLevels > 1 OR (nLevels = 1 AND round(percent,1) = 100) then do; /*BB160722 - added round statement*/
						subOrder+1;
						do i = 1 to dim(charArray);
							%if "%SYSFUNC(getOption(ENCODING))" = "UTF-8" %then %do;
								if not missing(charArray{i}) then variable = 'c2a0'x || 'c2a0'x || 'c2a0'x || charArray{i}; *'c2a0'x  = unicode non breaking space, char(160) in excel;
							%end;
							%else %do;
								if not missing(charArray{i}) then variable = 'A0'x || 'A0'x || 'A0'x || charArray{i}; *'A0'x  = non breaking space, char(160) in excel;
							%end;
						end;
						freq = put(percent, 4.%substr(&formatPercent.,10,1))||"%";
						output;
					end;
					subOrder+1;
				end;
				else do;
					freq = put(percent, 4.%substr(&formatPercent.,10,1))||"%";
					do i = 1 to dim(charArray);
						%if "%SYSFUNC(getOption(ENCODING))" = "UTF-8" %then %do;
							if not missing(charArray{i}) then variable = 'c2a0'x || 'c2a0'x || 'c2a0'x || charArray{i}; *'c2a0'x  = unicode non breaking space, char(160) in excel;
						%end;
						%else %do;
							if not missing(charArray{i}) then variable = 'A0'x || 'A0'x || 'A0'x || charArray{i}; *'A0'x  = non breaking space, char(160) in excel;
						%end;
					end;
					output;
					subOrder+1;
				end;
			run;
			proc sort data=freqTable3; by charVar variable subOrder; run;

			data freqTableOrderTemp;
				set freqTable3;
				by charVar variable subOrder;
				if first.variable;
				keep variable subOrder charVar;
			run;
			proc sql;
				CREATE TABLE freqTableOrder AS
				SELECT a.*, b.order
				FROM freqTableOrderTemp AS a LEFT JOIN varOrder AS b
				ON upcase(a.charVar)=upcase(b.variable);
			quit;

			proc sort data=freqTable3; by charVar variable; run;
			proc transpose data=freqTable3 out=freqTable4 (drop = _Name_ %if &overall.=1 AND %length(&class.) %then %do; %if %vtype(&dsn., &class.) = N  %then rename = (N999=All); %end;);
				by charVar variable;
				%if &class. ne  %then id &class.;;
				var freq;
			run;

			%let nClassLevels = -1; *Set this so the loop below still works;
			%if %length(&class.) %then %do;
			proc sql NOPRINT;
				SELECT count(distinct &class.) INTO :nClassLevels
				FROM &dsn.
				WHERE &where.;
			quit;
			%end;
			
			%if &pvalue. ne 0 AND &class. ne  AND %eval(&nClassLevels.=2) %then %do i = 1 %to %sysfunc(countw(&charVars., %str( )));
				*ods listing close;
				ods exclude all;
				%let currVar = %scan(&charVars., &i.);				
				%if not %index(%upcase(&pvalueExclude.),%upcase(&currVar.)) > 0  %then %do; *pValueExclude;
								
				*Determine if any class variables in &pvalueAdj;
				%let pvalueClassAdj = ;
				%if &pvalueAdj. ne %then %do;
				proc sql NOPRINT;
					SELECT name INTO :pvalueClassAdj
					FROM dictionary.columns
					WHERE libname = 'WORK' AND memname = "%upcase(&dsn.)" AND upcase(name) in (%do v = 1 %to %sysfunc(countw(&pvalueAdj., %str( ))); 
						"%upcase(%scan(&pvalueAdj., &v.))" %end;) AND type = 'char';
				quit;
				%end;

				proc genmod data=&dsn. descending namelen=50;
					where &where. AND not missing(&class.) AND not missing(&currVar.);
					class facid &class. &pvalueClassAdj. &currVar.;
					model &class. = &currVar. %if &pvalue. ne 0 %then &pvalueAdj.; / dist=bin link=logit type3;
					repeated subject=facid / type=cs;  

					ods output 	type3		=GEE_PEst (where = (upcase(charVar)="%upcase(&currVar.)" AND not missing(probchisq)) rename=(source=charVar));
				run;
				%if &i. = 1 AND %sysfunc(exist(GEE_PEst)) %then %do;
					data pvaluesChar; length charVar $50.;  set GEE_PEst; length variable $50.; variable = "&currVar."; pvalue=probChiSq; run;
				%end;
				%else %if %sysfunc(exist(GEE_PEst)) %then %do;
					data pvaluesChar; length charVar $50.; set pvaluesChar GEE_Pest(in=new); if new then do; variable="&currVar."; pvalue=probChiSq; end; run; 
				%end;

				proc datasets lib=work memtype=data nolist nodetails; delete GEE_Pest; run;
				*ods listing;
				ods exclude none;
				%end 	; *pValueExclude;
			%end;
			proc sort data=freqtable4; by charVar; run;
			%if &pvalue. ne 0 AND &class. ne  AND %eval(&nClassLevels.=2) %then %do; proc sort data=pvalueschar; by charVar; run; %end;
			data freqtable5;
				%if &pvalue. ne 0 AND &class. ne  AND %eval(&nClassLevels.=2) %then %do;
				merge 	freqtable4
						pvaluesChar (keep = charVar pvalue);
				by charVar;
				format pvalue &formatPvalue.;
				%end;
				%else %do;
				set freqTable4;
				by charVar;
				%end;
			run;
			
			proc sql NOPRINT;
				CREATE TABLE freqTableF AS
				SELECT a.*, b.order, b.suborder
				FROM freqTable5 AS a LEFT JOIN freqTableOrder AS b
				ON upcase(a.charVar) = upcase(b.charVar) AND trim(upcase(a.variable)) = trim(upcase(b.variable))
				ORDER BY b.order, b.subOrder;
			quit;	

			%if &pvalue. ne 0 AND &class. ne  AND %eval(&nClassLevels.=2) %then %do;
			data freqTableF;
				set freqTableF;
				by order subOrder;
				if not first.Order then call missing(pvalue);
			run;
			%end;
		%end;
		

		*Patient N;
			proc sql;
				CREATE TABLE patientN AS
				SELECT %if &class. ne %then &class.,; put(count(*), 8.0) AS &rowLevel.
				FROM &dsn.
				WHERE &where. %if &class. ne %then AND not missing(&class.);
						/*Both numeric and character variable(s)*/
						%if &numVarsComma. ne AND &charVarsComma. ne AND &numVarsN. ne 1 AND &charVarsN. ne 1 %then AND (nmiss(&numVarsComma.) + cmiss(&charVarsComma.))  < %eval(&numVarsN. + &charVarsN.); 
						%if &numVarsComma. ne AND &charVarsComma. ne AND &numVarsN. ne 1 AND &charVarsN. eq 1 %then AND (nmiss(&numVarsComma.) + missing(&charVarsComma.))  < %eval(&numVarsN. + &charVarsN.); 
						%if &numVarsComma. ne AND &charVarsComma. ne AND &numVarsN. eq 1 AND &charVarsN. ne 1 %then AND (missing(&numVarsComma.) + cmiss(&charVarsComma.))  < %eval(&numVarsN. + &charVarsN.); 
						%if &numVarsComma. ne AND &charVarsComma. ne AND &numVarsN. eq 1 AND &charVarsN. eq 1 %then AND (missing(&numVarsComma.) + missing(&charVarsComma.))  < %eval(&numVarsN. + &charVarsN.); 

						/*Only numeric variable(s)*/
						%if &numVarsComma. ne AND &charVarsComma. eq AND &numVarsN. ne 1 %then AND nmiss(&numVarsComma.)  < &numVarsN.; 
						%if &numVarsComma. ne AND &charVarsComma. eq AND &numVarsN. eq 1 %then AND not missing(&numVarsComma.); 

						/*Only characters variable(s)*/
						%if &numVarsComma. eq AND &charVarsComma. ne AND &charVarsN. ne 1 %then AND cmiss(&charVarsComma.)  < &charVarsN.; 
						%if &numVarsComma. eq AND &charVarsComma. ne AND &charVarsN. eq 1 %then AND not missing(&charVarsComma.); 
				%if &class. ne %then GROUP BY &class.;;

				%if &overall.=1 AND &class. ne %then %do;
				INSERT INTO patientN(&class., &rowLevel.)
				SELECT %if %vtype(&dsn., &class.) = N %then -999; %else 'All';, put(count(*), 8.0) AS &rowLevel.
				FROM &dsn.
				WHERE &where. AND not missing(&class.)
						/*Both numeric and character variable(s)*/
						%if &numVarsComma. ne AND &charVarsComma. ne AND &numVarsN. ne 1 AND &charVarsN. ne 1 %then AND (nmiss(&numVarsComma.) + cmiss(&charVarsComma.))  < %eval(&numVarsN. + &charVarsN.); 
						%if &numVarsComma. ne AND &charVarsComma. ne AND &numVarsN. ne 1 AND &charVarsN. eq 1 %then AND (nmiss(&numVarsComma.) + missing(&charVarsComma.))  < %eval(&numVarsN. + &charVarsN.); 
						%if &numVarsComma. ne AND &charVarsComma. ne AND &numVarsN. eq 1 AND &charVarsN. ne 1 %then AND (missing(&numVarsComma.) + cmiss(&charVarsComma.))  < %eval(&numVarsN. + &charVarsN.); 
						%if &numVarsComma. ne AND &charVarsComma. ne AND &numVarsN. eq 1 AND &charVarsN. eq 1 %then AND (missing(&numVarsComma.) + missing(&charVarsComma.))  < %eval(&numVarsN. + &charVarsN.); 

						/*Only numeric variable(s)*/
						%if &numVarsComma. ne AND &charVarsComma. eq AND &numVarsN. ne 1 %then AND nmiss(&numVarsComma.)  < &numVarsN.; 
						%if &numVarsComma. ne AND &charVarsComma. eq AND &numVarsN. eq 1 %then AND not missing(&numVarsComma.); 

						/*Only characters variable(s)*/
						%if &numVarsComma. eq AND &charVarsComma. ne AND &charVarsN. ne 1 %then AND cmiss(&charVarsComma.)  < &charVarsN.; 
						%if &numVarsComma. eq AND &charVarsComma. ne AND &charVarsN. eq 1 %then AND not missing(&charVarsComma.); 
				;
				%end;
			quit;
				

		proc transpose data=patientN out=patientNwide (rename = (_Name_=variable %if &overall.=1 AND %length(&class.) %then %do; %if %vtype(&dsn., &class.) = N %then N999=All; %end;));
				%if &class. ne %then id &class.;;
				var &rowLevel.;
			run;

		*Combine tables;
			data tableFtemp;
				set %if &numVars. ne  %then meanTableF;
					%if &charVars. ne %then freqTableF;;
				mergeVar = variable;
				%if &charVars. ne %then if not missing(charVar) then mergeVar = charVar;;
				
			run;
			proc sql;
				CREATE TABLE tableFtemp2 AS
				SELECT a.*, b.percMiss format percent8.1
				FROM tableFTemp as a LEFT JOIN statsAll AS b
				ON upcase(strip(a.mergeVar)) = upcase(strip(b.variable))
				ORDER BY order %if &charVars. ne %then , suborder;;
			quit;
			data tableFtemp3;
				set tableFtemp2;
				by order;
				if not first.order then percMiss = .;
			run;
/*
			proc sql;
				CREATE TABLE tableF AS
				SELECT a.* %if &pvalue. ne 0 %then %do;, b.pvalue format &formatPvalue. %end;
				FROM TableFtemp AS a %if &pvalue. ne 0 %then %do; LEFT JOIN pvalues AS b
				ON upcase(a.variable)=upcase(b.outcome) %end;
				ORDER by order %if &charVars. ne %then %do;, suborder %end;; 
			quit;
*/
			data TableF; 
				%if %length(&colOrder.) %then format &colOrder.;;
				set TableFtemp3
					patientNWide;

				%if &class. =  %then rename col1 = mean_prevalence;;
				drop order mergeVar %if &charVars. ne %then suborder charVar;; 
				%if &formatVar. ne %then if variable ne "&rowLevel." AND not index(variable, 'A0'x) then variable = upcase(variable);; *BB150424 - avoid issues with overlapping formats due to case;
				label 	percMiss 		= 'Missing'
						variable = 'Variable'
						%if &class.=  %then col1 = 'Mean or %';
						%if %length(&colLabel.) %then &colLabel.;
				;
			run;

		%if %length(&openODS.)  %then %do i = 1 %to %sysfunc(countw(&openODS., %str( )));
			ods %scan(&openODS., &i., %str( )) SELECT ALL;
		%end;
		*ods listing;
		ods exclude none;

		%if &html=1 %then ods html style=journal %if &htmlName. =  %then file="MeanTableBy&class..html"; %else file = "&htmlName..html";;
		%if &pvalue.=1 %then footnote "p-value adjustments: [&pvalueAdj.]";;
		%if %length(&where.) > 1 %then %do; %titleNext(restriction: &where.); %end;
		options label;
		proc print data=TableF label;	
			id variable; 
			%if &formatVar. ne %then format variable &formatVar.;;
		run;
		%if &html=1 %then ods html close;;
		
		ods select none;
		ods select all;
		options syntaxcheck &inLabel.;	
		%if &pvalue.=1 %then footnote;;	

		%if &cleanup. = 1 %then %do;
		proc datasets nodetails nolist library=work memtype=data; 
			delete
				MeanTable: 
				freqTable: 
				tableF: 
				GEE_pEst 
				mixed_tests3 
				stats_all 
				IQR
				varOrder
				varOrderM
				varType
				missChar
				missCharWide
				statsAll
				statsNum
				tableLevels
				patientN
				patientNwide
				DSNtrim:
			; 
		run;
		%end;
	%mend meanTable;