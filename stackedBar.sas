/********************************************************************
	Name:		stackedBAR
	Description:	Creates stacked bar plot from summarized data
	Dynamic vars:	graphX	= [Class variable for x-axis, needs to be character-not sure why]
				graphY	= []
				graphGroup= []
				yLabel	= []
	Notes:		Called by stackedBar macro
	Updates:		BB151030 - added segment labels for non-binary graphs
	Example code:
	********************************************************************/
proc template;
	DEFINE statgraph stackedBar;
		begingraph / designwidth=950px designheight=600px; *Powerpoint slide size;;
			DYNAMIC graphX graphY graphGroup yLabel
			tableX tableValue tableRow 
			binary;
			layout lattice / rows = 2 rowgutter=10 rowweights = (0.85 0.15);
				/*Stacked Bar*/
				layout overlay / 
					xaxisopts=(type=Discrete display=(tickvalues))
					yaxisopts=(label=ylabel linearopts=(viewMin=0 viewMax=100))
					border=false;

					IF (binary=0)
						BarChartParm X=graphX Y=graphY / 
							/*dataskin=sheen*/
							primary=true 
							Group=graphGroup 
							GroupOrder = data 
							_barlabel_ = binary
							NAME="grouped"
							/*Label stacked bar components*/
							segmentlabeltype=auto
							segmentlabelformat=8.0

						;
					ENDIF;

					IF (binary=1)
						BarChartParm X=graphX Y=graphY / 
							/*dataskin=sheen*/
							primary=true 
							Group=graphGroup 
							GroupOrder = data 
							_barlabel_ = binary
							NAME="grouped"
						;
					ENDIF;

					IF (binary=0)
						DiscreteLegend "grouped"/ location = outside valign=top halign=center down=2;
					ENDIF;
				endlayout; /*Bar chart*/
				/*Descriptive Table*/
				layout overlay / xaxisopts=(type=discrete display=none) walldisplay=(fill);;
					blockplot x=tableX block=tableValue / 
						class = tableRow
						display=(values label) 
						valuehalign=right 
						repeatedvalues=true 
						labelattrs=/*(size=8pt)*/graphvaluefont;
				endlayout; /*descriptive table*/
			endlayout; /*lattice*/
		endgraph;
	end;
run;

/*****************************************************************
	Name:		stackedBar
	Purpose:		Stacked bar chart adding to 100%
	Parameters:	data= [dataset] , 
				var= [variable] , 
				class= [xaxis], 
				format = [optional format for var], 
				html = [1 if ouput to html],
				binary = [1 if 1/0 variable for percent bar chart], 
				table=[1 to print table], 
				sort=[ASCENDING or DESCENDING, sorts by percent for 1/0 or first category for others],
				imageName = [control naming of image]
	Create Date:	February 22, 2012
	Creator:		Brian Bieber
	
	Example:	proc format;
					value fmAge
							LOW-<45 = "< 45"
							45-<65 = "45-64"
							65-<75 = "65-75"
							75-HIGH = "75+"
					;
				run;
	
				title "Example with continuous variable and format";
				%stackedBar(data=dopps3.m_f, 
							var=mAge, 
							class=country, 
							format=fmAge., 
							table=1
							);
				
				
				title "Example with categorical variable";
				%stackedBar(data=dopps3.m_f, 
							var=mSex, 
							class=country, 
							table=1,
							sort=DESCENDING
							);
				
				
				title "Example with binary variable";
				%stackedBar(data=dopps3.m_f, 
							var=mComDiabetes2, 
							class=country, 
							table=1,
							sort=ASCENDING,
							binary=1
							);	

	Notes:		Harmless warn_ing produced - WAR_NING: The variable _label_ in the DROP, KEEP, or RENAME list has never been referenced.
				For correct sorting, the xaxis needs to be a character variable. Not sure why.
				BB140710: Made html default and turned off listing to prevent 2 png from being created
				BB18113: Known WAR_NING produced sometimes when boxplot categories are created by format
								 	"The data for a BARCHARTPARM statement are not appropriate. The BARCHARTPARM statement expects summarized data."
								 	Made the categorical variable a character variable (instead of formatted numerical) in the very last step
				BB231215: Turned off html as default for SAS EG				 	
******************************************************************/

%macro stackedBar(data= , var= , class = , where= 1, format = , html = 0, binary = 0, table=0, sort= , imageName= , weight = , xlabel=N Pts , ylabel=Percent);
	options label;
	*Determine type of variable;
		%local varType;

		proc contents data=&data noprint out=varType (keep = name type where = (upcase(name)="%upcase(&var.)")); run;
		proc sql NOPRINT;
			SELECT CASE WHEN type = 1 THEN 'num'
						WHEN type = 2 THEN 'char'
						ELSE				''
						END
			INTO :varType
			FROM varType;
		quit;

		*BB121025 - prevent already formatted categorical variable that is numerical from having stats calculated;
		%if &varType. = num AND &binary. = 0 AND &format. =  %then %let varType = char;		
		/*%put vartype[&varType.] binary [&binary.] format[&format.] ;*/

	/*Cross-tab (class by group)*/
	*ods listing close;
	%local switchLabel;
	%if %sysfunc(getoption(LABEL)) = LABEL %then %do;
		options nolabel;
		%let switchLabel = 1;
	%end;
	
	ods exclude all;
	proc freq data=&data.;
		where &where.;
		%if &weight. ne %then weight &weight;;
		tables &class.*&var. / nocol nopercent sparse;
		%if &format ne %then format &var. &format.;;
		ods output crossTabFreqs=freqTable (where = (_type_ = '11'));
	run;
	
	%if &weight. ne %then %do;
		/*Unweighted table to get actual N*/
		proc freq data=&data.;
			where &where. AND not missing(&weight.);
			tables &class.*&var. / nocol nopercent sparse;
			%if &format ne %then format &var. &format.;;
			ods output crossTabFreqs=freqTableUW (where = (_type_ = '11'));
		run;
		
		data freqTable;
			merge 	freqTable
					freqTableUW (keep = &class. &var. frequency); /*Frequency will overwrite*/
			by &class. &var.;
		run;
	%end;
	ods exclude none;
	*ods listing;


	*Class stats;
	%if &varType. = num %then %do;
	proc summary data=&data. nway;
		where &where.;
		%if &weight. ne %then weight &weight;;
		class &class.;
		var &var.;
		output out = statsNum (drop = _Freq_ _Type_)
			n = N
			%if &binary.=0 %then %do;
				mean = Mean
				p50 = Median
			%end;
			;		
	run;

	proc transpose data=statsNum out=statsNumT(rename = (col1 = tableValue)) name=tableRow;
		by &class.;
	run;
	%end;
	%else %if &varType. = char %then %do;
		proc sql;
			CREATE TABLE statsChar AS
			SELECT &class., "&xlabel." AS tableRow, sum(frequency) as tableValue
			FROM freqtable
			GROUP BY &class.;
		quit;
	%end;

	*Deal with sorting for non 1/0 variables;
	%if &sort. ne  AND &binary. ne 1 %then %do;
		data freqTable  classOrder (keep = &class. classOrder firstCatPerc);  
			set freqTable;
			by &class.;
			retain firstCatPerc classOrder;
			if first.&class then do;
				firstCatPerc = rowPercent;
				classOrder=round(classOrder, 1)+1;		
			end; 
			classOrder+0.1;
			output freqTable;
			if last.&class then output classOrder;
		run;

		proc sort data=freqTable; by %if %upcase(&sort.)=DESCENDING %then DESCENDING; firstCatPerc classOrder; run;

		data %if &varType. = num %then statsNumT; %if &varType. = char %then statsChar;;
			merge 	%if &varType. = num %then statsNumT; %if &varType. = char %then statsChar;
					classOrder;
			by &class;
		run;
		proc sort data=%if &varType. = num %then statsNumT; %if &varType. = char %then statsChar;; by %if %upcase(&sort.)=DESCENDING %then DESCENDING; firstCatPerc classOrder; run;
	%end;

	
	options mergeNoBy = noWarn;
	data stackedStats;
		merge 	freqTable %if &binary = 1 %then (where = (&var = 1));
				%if &varType. = num %then statsNumT (rename = (&class.=&class.2));
				%else %if &varType. = char %then statsChar (rename = (&class.=&class.2));;
		if upcase(tableRow) in ('MEAN' 'MEDIAN') then tableValue = round(tableValue, 0.1);
		else if upcase(TableRow) = 'N' then TableRow = "&xlabel.";
		drop _type_ table _table_ missing;
		%if &binary.=1 %then rowPercent = round(rowPercent, 0.1);;
		%if &format. ne  %then &var.C = put(&var., &format.);;
	run;
	options mergeNoBy = warn;

	*Deal with sorting for 1/0 variables;
		%if &sort. ne  AND &binary.=1 %then %do;
			proc sort data=stackedStats; by %if %upcase(&sort.)=DESCENDING %then DESCENDING; rowPercent &class.; run;
		%end;

	
	%if &html. = 1 %then ods html style=Mystyle file = %if &imageName.= %then "&var._stacked.html" (title="&var. Stacked Bar"); %else "&imageName._stacked.html" (title="&imageName. Stacked Bar");;
	%if &table = 1 %then %do;
		data tableData;
			set &data;
			&var._nonMiss = not missing(&var.);
			%if &varType. = num %then %do; 
				if not missing(&var.) then &var._cont = &var.; 
				format &var._cont;
			%end;
		run;
		
		%if &binary = 1 %then %do;
			proc print data=stackedStats label; 
			id &class.; 
			var rowPercent tableValue; 
			label 	rowPercent = '%'
					tableValue = 'N Pts';
			run;
		%end;
		
		%else %if &weight =   %then %do;
		proc tabulate data=tableData;
			class &class. &var.;
			where &where.;
			var &var._nonMiss %if &varType. = num %then &var._cont;;
			%if &format. ne %then format &var. &format.;;
			tables (&class.='' ALL), 
						&var.=''*pctn<&var. all>='%'*f=8.1
						%if &varType. = num %then &var._cont=''*(mean p50='Median')*f=8.1; &var._nonMiss=''*N="&xlabel."*f=8.0 / box="&var." misstext='0';
		run;
		%end;
		%else %do;		*Weighted results - tabulate cannot weight percentages;	
			proc sort data=freqTable; by &class. %if &sort. ne  AND &binary. ne 1 %then classOrder;; run;
			proc transpose data=freqtable out=table_rowPerc (drop = _Name_);
				by &class.;
				ID &var.;
				var rowpercent; 
			run;
			
			*Table not needed if no sorting, but create anyway for merge below;
			proc sql;
				CREATE TABLE table_NptsSort AS
				SELECT &class., sum(frequency) AS Npts %if &sort. ne  AND &binary. ne 1 %then , max(firstCatPerc) AS firstCatPerc;
				FROM freqtable
				GROUP BY &class.
				ORDER BY &class.;
			quit;
			
			data table_print;
				merge 	table_rowPerc
						table_NptsSort
						%if &varType. = num  %then statsNum (keep = &class. mean median);;
				by &class.;
			run;
			%if &sort. ne %then %do; proc sort data=table_print; by %if %upcase(&sort.)=DESCENDING %then DESCENDING; firstCatPerc &class.; run; %end;
			proc print data=table_print; id &class; run;
			

		%end;
		
	
	%end;
	%if &html. = 1 %then ods listing close;;
	ods graphics / imagemap=off imagename= %if &imageName= %then "&var._stackedPlot"; %else "&imageName.";;
	proc sgrender data=stackedStats template=stackedBar object=stackedPlot; 
		DYNAMIC
			graphX = "&class."
			graphY = "rowPercent"
			%if &format. ne  %then graphgroup = "&var.C"; %else graphgroup = "&var."; 
			tableX = "&class.2"
			tableValue = "tableValue"
			tableRow = "tableRow"
			binary = "&binary."
			ylabel = "&ylabel.";
	run;
	%if &html. = 1 %then ods html close;;
	ods graphics / imagemap = off;
	%if &switchLabel. = 1 %then options label;;
	%if &html. = 1 %then ods listing;;
%mend stackedBar;
	
/*
*Preliminary work an a side-by side stacked bar that adds to 100%;
*https://blogs.sas.com/content/iml/2014/04/08/construct-a-stacked-bar-chart-in-sas-where-each-bar-equals-100.htmlsassas;
*https://blogs.sas.com/content/graphicallyspeaking/2014/04/06/g100-with-sgplot/;


proc format;
	value fPrePeak
		1 = 'Pre'
		2 = 'Peak'
	;
run;

%macro prePeak(dsn=ISN, class=ISNregion_abb, varPrefix=);
	%local vFmt vLabel;

	*Get format and label;
	proc sql NOPRINT;
		SELECT format, transtrn(label, "Before the COVID-19 pandemic", "")
		INTO :vFmt, :vLabel
		FROM dictionary.columns
		WHERE libname = 'WORK' AND memname = %upcase("&dsn.") AND upcase(name) = %upcase("&varPrefix._PRECOVID");
	quit;


	data tempGraph (keep = &class. graphVar timing);
		set isn (in=inPre 	keep = &class. &varPrefix._PreCOVID &varPrefix._COVIDpeak);
		where nmiss(&varPrefix._PreCOVID, &varPrefix._COVIDpeak)=0;

		format timing fPrePeak.;
		format graphVar &vFmt.;

		do i = 1 to 2;
			if i = 1 then do;
				timing = i;
				graphVar = &varPrefix._PreCOVID;
				output;
			end;
			else if i = 2 then do;
				timing = 2;
				graphVar = &varPrefix._COVIDPeak;
				output;
			end;
		end;
	run;

	proc sort data=tempGraph; by &class. timing; run;
	proc freq data=tempGraph order=freq noprint;  
	by &class. timing;                      
	tables graphVar / out=FreqOutSorted;        
	run;

	title bold height=11pt "&vLabel.";
	title2 height=10pt "Pre compared to during COVID peak";
	proc sgpanel data=FreqOutSorted;
		panelby &class. / noborder nowall noheaderborder novarname columns=5 rows=2;
		vbar timing / group = graphVar response=percent;
		colaxis display=(nolabel);
		rowaxis label='% of respondents';
		keylegend / noborder title = ' ' position=top;
	run;

	proc tabulate data=freqOutSorted;
		class &class. timing graphVar;
		var percent count;
		tables &class.=''*timing='', graphVar=''*percent=''*max='%'*f=8.1 count=''*sum='N fac'*f=8.0;
	run;
%mend prePeak;

ods graphics / reset width = 8in height=4.5in;

ods html style = myStyle file = "PracticeChanges_preDuring COVID peak.html";
footnote height=8pt "Eur-E/C=Europe (East/Central), LaAmer=Latin America, MidEast=Middle East, Rus/NI=Newly ind. states & Russia, NA/C=N. America/Caribbean, Asia-NE=Asia (North/East), Asia-SE/O=Asia (SE/Oceania), Asia-S=Asia (South), Eur-W=Europe (Western)";
	%prePeak(varPrefix=PDB1);
	%prePeak(varPrefix=PDB2);
	%prePeak(varPrefix=PDB3);
	%prePeak(varPrefix=PDB4);
	%prePeak(varPrefix=PDB6);
	%prePeak(varPrefix=PDC1);
ods html close;
*/