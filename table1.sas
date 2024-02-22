/************************************************************************************************************
	Title:	Create Table 1 for a manuscript
	---------------------------------------------------------------------------------------------------------
	Purpose:	Automate the creation of Table 1 for a manuscript, allowing for different types of variables.
				See the Details section below for a description of variable types.
	---------------------------------------------------------------------------------------------------------
	Path and Name:  U:\DOPPS\work\Daniel Scratch\Macros\table1.sas
	Created Date:   Nov 17, 2017
	Created By:     Daniel Muenz
	---------------------------------------------------------------------------------------------------------
	Parameters: 
		vars		List of analysis variables, in a special format. Each variable must be followed by a
					colon (:) and then a type specification. See the Details below for valid types. After the
					type, you can optionally append three additional properties (each preceded by a colon):
					a format name (with the dot), a label (enclosed in quotes), and the number of decimal
					places for rounding (an integer from 0 to 9). You can specify all three of these
					properties or any subset, and the order does not matter. If you specify a format, it
					overrides any format already attached to the variable. Formats can only be specified for
					F and N-type variables, to determine categories. The number of decimal places can only be
					specified for M, Q, S, and R-type variables, to control rounding when printing the table.
					Valid specifications for a single variable look like
						name:type
					or
						name:type:format.:digit:"My label"
					where name is a variable name (or expression) and type is a valid type (see Details below).
					Only name and type are required. If a F or N-type variable already has a format in the
					source dataset and you want to remove it so that the variable is unformatted, you can use a
					dot (.) as in
						name:type:.
					The colons can have spaces around them, e.g. 
						name : type : format.
					A colon-delimited block, as above, specifies one variable. Multiple variables can be
					specified with a space delimiter, e.g.
						var1:type1:formata. var2:type2:"My label"
					In place of a variable name, you can also use the keyword _section_ (or _sect_ or _sec_)
					to insert a new row in the table. This keyword does not require a type, but you can attach
					a label like so: _sec_:"New section". Then the new row will have the text "New section"
					written in the first column.
		class		(Optional) Class variables. Each combination of levels of the class variables get their
					own column of output. A format and label can be attached to each class variable, delimited
					by a colon (:). E.g., if a class variable is named 'exposure', you can specify it as
						exposure:myformat.:"Levels of Exposure"
					The format and label are optional; you can specify one, neither, or both, and the order
					does not matter (but the variable must come first). The label must be enclosed in quotes.
					If you specify a format, it overrides any format already attached to the variable. To remove
					a format and make the variable unformatted, use a dot (.) as in
						exposure:.:"Levels of Exposure"
					Multiple class variables can be specified with a space-delimiter, e.g.
						country:"Exposure by country" exposure:myformat.
		data		Name of dataset with variables
		where		(Optional) Where clause for subsetting data
		specialChar	(Optional) Yes/No flag to convert particular characters into their unicode equivalents.
					The symbols >= and <= will automatically be converted to their one-character unicode 
					versions. Two asterisks (**) followed by a number will be converted to a superscript.
					Default is Yes.
		missing		(Optional) Yes/No flag to add a column showing % missingness in variables. Default is No.
		ignoreMissAll
					(Optional) Yes/No flag. If an analysis variable is completely missing within a level of a
					class, setting this option to Yes will ignore that class level when computing the percent
					missingness of the analysis variable. Default is No.
		all			(Optional) Yes/No flag to add a column showing an overall summary of the analysis variables.
					This is only relevant if you use a class variable, so you can summarize your analysis
					variables both by class and overall. Default is No.
		allText		(Optional) Header text for the overall column. Default is "All" when all=Yes and there are
					class variables. Otherwise the default is "Summary".
		allSide		(Optional) Should the overall column be on the left or right? Default is right. Options are
					LEFT, L, RIGHT, and R.
		freq		(Optional) Yes/No flag to print frequencies for binary and categorical variables. Default
					is Yes. If No, then only percents are printed.
		merge		(Optional) Yes/No flag to merge the two columns of data for each class level. I.e., merge
					N and % into one column for a B or F variable, and merge mean and sd into one column for
					an M variable. If freq = No or plusMinus = Yes, then columns are automatically merged,
					regardless of the value of merge. Otherwise, the default is No.
		n			(Optional) Yes/No flag to print the numbers of observations overall and in each class (if
					applicable). These will be printed in the header of the table. Default is Yes.
		nVar		(Optional) Name of variable used to determine sample size for the header of each column.
					If you leave this blank (the default), then the number of observations contributing to the
					column is used. If you specify a variable, then the sample size is calculated as the number
					of unique non-missing values of the variable. This would typically be something like a
					patient ID variable.
		nPrefix		(Optional) Text to put before the number of observations in table header. Default is 'n = '.
					Only relevant if paramter n=Yes. The text, along with the number, will be placed in
					parentheses, e.g. (n = 1234).
		capN		Deprecated. This parameter has no effect.
		col1Text	(Optional) Header text for column 1, i.e. the column naming all the analysis variables.
					Default is "Characteristics".
		headerSpan	(Optional) Yes/No flag to span column headers for class levels when there are 2 or more
					class variables. Default is Yes, but currently this only works when the number of class
					variables is >= 2 and <= 4.
		paddingLeft	(Optional) Number of padding spaces on the left for (1) levels of a categorical variable,
					and (2) any variable whose label starts with a space. If the latter, the number of padding
					spaces is calculated as paddingLeft times the number of leading spaces in the label.
					Default is 5, meaning 5 spaces.
		col1Width	(Optional) 
		statColWidth
					(Optional) 
		digitsLT1,digits1to10,digits10to100,digitsGE100	
					(Optional) Number of decimal places to round means, medians, std devs, Q1s, and Q3s,
					depending on the value of each statistic. E.g., if a statistic is >= 1 and < 10, then
					it is rounded to digits1to10 digits after the decimal point. The number of digits must be
					between 0 and 31 (inclusive), but should probably be a lot less than 31 because the entire
					number, including integer part and possibly decimal point and negative sign must fit in
					32 characters.
		digitsPct	(Optional) Number of decimal places to round percents for B and F variables. Default is 1.
					Should be between 0 and 10 (inclusive).
		digitsPct0	(Optional) Number of decimal places when the percent value is exactly 0 or 100, for B and F
					variables. Default is the value of digitsPct. Should be between 0 and 10 (inclusive).
		digitsPctLT1
					(Optional) Number of decimal places when the percent value is < 1 or > 99, for B and F
					variables. Default is the value of digitsPct. Should be between 0 and 10 (inclusive).
		digitsPctLimit
					(Optional) Limit such that if a percent is < digitsPctLimit then it will be printed as "<X"
					where X is the value of digitsPctLimit. Likewise, if a percent is > 100-digitsPctLimit then
					it will be printed as ">Y" where Y is the value of 100-digitsPctLimit.
		plusMinus	(Optional) Yes/No flag to put a +/- sign between mean and sd for M variables. Default
					is No, meaning sd is enclosed in parentheses. If Yes, columns are merged (see the merge
					parameter).
		IQRsep		(Optional) Delimiting character(s) to print between Q1 and Q3. Default is a comma.
		trim0		(Optional) Yes/No flag to trim trailing zeros after a decimal point. Default is No.
		secStyle	(Optional) SAS style code to format table section headers (with the _section_ keyword).
					Default is fontweight=bold.
		inject		(Optional) DATA STEP code to manipulate the Table 1 dataset right before it is printed.
					To use this option, it is generally best to first run the %table1 macro without it,
					then inspect what variables and values are available to you in the OUT dataset, and then
					rerun the macro with the option.
		injectLong	(Optional) DATA STEP code to manipulate the Table 1 dataset in long format, before it has
					been transposed to its final wide format (in which each class level has its own column).
					The code would be injected prior to that with the inject parameter (which works on the
					wide data). To use this option, it is generally best to first run the %table1 macro
					without it but with debug=yes, then inspect what variables and values are available to
					you in the _T1_LONG dataset, and then rerun the macro with the option. Typically this
					is used to edit the stat1, stat2, and/or statx columns.
		out			(Optional) Name of output dataset containing Table 1
		debug		(Optional) Yes/No flag to save temporary datasets and print extra information to the log.
					Default is No.
	---------------------------------------------------------------------------------------------------------
	Details:
		Each variable specified in the VARS parameter must have a valid type. A valid type is one or two
		letters from the following set:
		  Type  Meaning
			B	Frequency (%) of "yes"es, for a binary variable (uses only one row in table). By default,
				the value 1 means yes, and all other non-missing values mean no. You can change what counts
				as a yes by enclosing a comma-delimited set of values in parentheses after the B. E.g.,
				specifying B(0,3) means that 0 and 3 mean "yes", and every other non-missing value means no.
				This even works with character variables; just enclose the yes values in quotes, e.g.,
				B("Female"). The value-matching works on the raw data values, not the formatted values.
			F	Frequency (%) for levels of a categorical variable (each level gets a row). This is based on
				formatted values if there is a format, and raw values otherwise.
			M	Mean (SD), for a continuous variable (uses only one row)
			Q	Median (Q1-Q3), for a continuous variable (uses only one row)
			N	Number of distinct values (uses only one row). This is based on formatted values if there is
				a format, and raw values otherwise.
			S	Sum of a variable (uses only one row)
			R	Rate, for a combination of a binary variable and a time variable (uses only one row). The
				variable expression must be of the form event/time or event/time*scale, where event and time
				are variables and scale is an optional numeric constant, e.g., died/YearsAtRisk*100 to
				calculate the death rate in deaths per 100 person-years. The rate is calculated as
				sum(event)/sum(time)*scale. An observation is included in the calculation if and only if both
				event and time are not missing. The R can optionally be followed by a parenthetical, comma-
				delimited list of "yes" values (exactly like a B-type variable). Any of these values will
				count as an event, and every other non-missing value means no.
		E.g., to print the mean and SD for a variable called 'age', write age:M and optionally include a
		label. Type F can be used together with either type M or Q. In this case, the mean (SD) or median (IQR)
		is printed, followed in subsequent rows by a frequency distribution of the variable. E.g., if you
		specify age:MF:agef., where agef. formats age into <65 and >=65 categories, then the table will display
		first the mean (SD) of age and then how many records have age<65 and how many have age>=65. No other
		combinations of types are allowed.
	---------------------------------------------------------------------------------------------------------
	To do list:
		* New feature: P-values?
	---------------------------------------------------------------------------------------------------------
	Depends on:
		%validVars, %apply, %delimit, %removeSpacesAround, %nObs, %nObsVars
	---------------------------------------------------------------------------------------------------------
	Change log:
		2019-11-19 DGM Added nVar parameter
		2019-11-26 DGM Fixed a bug related to resolving macro variables holding the class names
		2020-02-06 DGM Fixed the frequency for B variables when using weights
		2020-02-24 DGM Fixed indentation of _section_ labels and added statColWidth parameter
		2020-03-10 DGM Added support for S variables
		2020-09-02 DGM Added digitsPct0, digitsPctLT1, and digitsPctLimit parameters
					   Added the macro timer
		2020-09-03 DGM Fixed a bug so that a variable can now be used multiple times
					   Added the dot (.) feature to the vars and class parameters for removing formats
		2021-04-30 DGM Fixed a bug that occurred with some complicated variable expressions, e.g.,
						specifying missing(myvar):B to count missing data used to crash the macro, but
						now it works.
*************************************************************************************************************/

%macro table1(vars, class=, data=, where=, weight=, specialChar=Y, missing=N, ignoreMissAll=N,
			  all=N, allText=, allSide=right, freq=Y, merge=, n=Y, nVar=, nPrefix='n = ', capN=,
			  col1Text='Characteristics', headerSpan=Y, paddingLeft=5, col1Width=, statColWidth=,
			  digitsLT1=2, digits1to10=2, digits10to100=1, digitsGE100=0,
			  digitsPct=1, digitsPct0=, digitsPctLT1=, digitsPctLimit=,
			  plusMinus=N, IQRsep=',', trim0=N, secStyle=fontweight=bold, inject=, injectLong=,
			  out=_table1, debug=N);

%local startTime; %let startTime = %sysfunc(datetime());

%* load dependecies;
%if %sysMacExist(requireMacros) %then %do;
	%requireMacros(validVars, apply, delimit, removeSpacesAround, nObs, nObsVars,
				   path=\\urrea.local\dopps\dopps\\work\Daniel Scratch\Macros)
	%if &macroNotFound %then %return;
%end;

%* validate parameters;
%if not %validVars(requiredArgs=vars-P IQRsep,
				   dataArgs=data-EO out,
				   yesnoArgs=specialChar missing ignoreMissAll all freq plusMinus merge-B n headerSpan trim0 debug,
				   keywordArgs=allSide-1(left,l,right,r),
				   numericArgs=paddingLeft-I(>=0)
						digitsLT1-I(>=0,<=10) digits1to10-I(>=0,<=10) digits10to100-I(>=0,<=10) digitsGE100-I(>=0,<=10)
						digitsPct-I(>=0,<=10) digitsPct0-BI(>=0,<=10) digitsPctLT1-BI(>=0,<=10)
						digitsPctLimit-B(>0,<=1),
				   sgSizeArgs=col1Width-B statColWidth-B)
				   %then %return;

%local pm;
%if &specialChar %then %let pm = (*ESC*){unicode 00B1};
%else %let pm = +-;

%local noClass;
%let noClass = %sysevalf(%length(&class) = 0);
%if &noClass %then %let all = 0;

%if not &freq or &plusMinus %then %do;
	%if &merge = 0 %then %put NOTE: Table columns will be merged, despite value of MERGE.;
	%let merge = 1;
%end;
%else %if %length(&merge) = 0 %then %let merge = 0;

%if %length(&allText) = 0 %then %do;
	%if &all %then %let allText = "All";
	%else %let allText = "Summary";
%end;

%if %length(&digitsPct0)=0 %then %let digitsPct0 = &digitsPct;
%if %length(&digitsPctLT1)=0 %then %let digitsPctLT1 = &digitsPct;

%* Make sure some text values are quoted (i.e., have literal quote marks around them);
%if not %sysfunc(prxmatch({^('[^'']*'|"[^""]*")$}, &IQRsep)) %then %let IQRsep = "&IQRsep";
%if not %sysfunc(prxmatch({^('[^'']*'|"[^""]*")$}, &col1Text)) %then %let col1Text = "&col1Text";
%if not %sysfunc(prxmatch({^('[^'']*'|"[^""]*")$}, &allText)) %then %let allText = "&allText";

%* And make sure some other text values are unquoted;
%let nPrefix = %qsysfunc(prxchange(s{^(?:'([^'']*)'|"([^""]*)")$}{\1\2}, 1, &nPrefix));

%* Remove all unquoted spaces from each block within VARS. This lets the user include spaces
   within a block for readability;
%let vars = %removeSpacesAround(:, &vars, keepQuoted=Yes);
%let vars = %removeSpacesAround(%str(,), &vars, keepQuoted=Yes);
%let vars = %removeSpacesAround(/, &vars, keepQuoted=Yes);
%let vars = %removeSpacesAround(*, &vars, keepQuoted=Yes);
%let vars = %removeSpacesAround(%str(%(), &vars, keepQuoted=Yes);
%let vars = %removeSpacesAround(%str(%)), &vars, keepQuoted=Yes, sides=left);

%local nBlocks;
%let nBlocks = %sysfunc(countw(&vars,,sq));

%local oldNotes oldFmtErr oldObs oldObsOptions oldVarInitChk;
%let oldNotes = %sysfunc(getoption(notes));
%let oldFmtErr = %sysfunc(getoption(fmtErr));
%let oldObsOptions = firstObs=%sysfunc(getoption(firstObs)) obs=%sysfunc(getoption(obs));
%let oldVarInitChk = %sysfunc(getoption(varInitChk));

%local readAllObsOptions;
%let readAllObsOptions = firstObs=1 obs=max;

%local tempDatasets;
%let tempDatasets = _t1_varlist _t1_fmts _t1_tempdata _t1_classes
	_t1_missingWeight _t1_missing _t1_missingClass
	_t1_classLevelsN _t1_classLevelsN2 _t1_classLevelsN3
	_t1_dataB _t1_dataF _t1_dataMQS _t1_dataN _t1_dataN2 _t1_dataR
 	_t1_long_pre _t1_long _t1_stat1 _t1_stat2;

%if not &debug %then %do; options nonotes; %end;
proc datasets noprint;
	delete &tempDatasets;
quit;
proc datasets noprint lib=%scan(&out,1);
	delete %scan(&out,2);
quit;
options &oldNotes;

%* prepare to parse the variable blocks in VARS;
%local i j block name sectionCount type explain
	hasTypeB hasTypeF hasTypeM hasTypeN hasTypeQ hasTypeS hasTypeR
	typeB    typeF    typeM    typeN    typeQ    typeS    typeR
	hasAnyVar
	extra extraBad fmt lab dig trueVals
	nameList labList digitsList fmtList typeList trueList varListNF
	nameLength labLength
	;

%let explain = 0;

%* initialize indicators for having each variable type;
%let hasTypeB = 0;
%let hasTypeF = 0;
%let hasTypeM = 0;
%let hasTypeN = 0;
%let hasTypeQ = 0;
%let hasTypeR = 0;
%let hasTypeS = 0;
%let hasAnyVar = 0;

%let sectionCount = 0; %* initialize count of _SEC_ blocks;
%let nameLength = 0;
%let labLength = 0;

%* Parse the variable blocks in VARS;
%do i = 1 %to &nBlocks;
	%let block = %scan(&vars, &i, ,sq);
	%let name = %scan(&block, 1, :,q);

	%if %sysfunc(prxmatch(/^_SEC(T|TION)?_$/, %upcase(&name))) %then %do;
		%let sectionCount = %eval(&sectionCount + 1);
		%let name = _sec&sectionCount._;
		%let type = _;
		%let lab = %scan(&block, 2, :,q);
		%let dig = .;
		%let fmt = _;
		%let trueVals = _;
		%if %length(&lab) = 0 %then %let lab = "Section &sectionCount";
		%if &debug %then %put Block &i: section &sectionCount, lab=&lab;
	%end;
	%else %do;
		%let type = %scan(&block, 2, :,q);
		%if %index(&type, %str(%()) %then %do;
			%let trueVals = %substr(&type, %index(&type, %str(%()));
			%let type = %substr(&type, 1, %index(&type, %str(%()) - 1);
		%end;
		%else %let trueVals = ;
		%let type = %upcase(&type);

		%let typeB = %eval(%index(&type, B) > 0);
		%let typeF = %eval(%index(&type, F) > 0);
		%let typeM = %eval(%index(&type, M) > 0);
		%let typeN = %eval(%index(&type, N) > 0);
		%let typeQ = %eval(%index(&type, Q) > 0);
		%let typeR = %eval(%index(&type, R) > 0);
		%let typeS = %eval(%index(&type, S) > 0);

		%if %sysfunc(prxmatch(/[^BFMNQRS]/, &type)) or %length(&type) > 2 %then %do;
			%put ER%str(ROR): Invalid type &type for variable %upcase(&name). Valid types are B, F, M, N, Q, R, and S:;
			%let explain = 1;
		%end;
		%else %if &typeB and %length(&type) > 1 %then %do;
			%put ER%str(ROR): You cannot specify the B type with other types for the same variable.;
			%return;
		%end;
		%else %if &typeN and %length(&type) > 1 %then %do;
			%put ER%str(ROR): You cannot specify the N type with other types for the same variable.;
			%return;
		%end;
		%else %if &typeR and %length(&type) > 1 %then %do;
			%put ER%str(ROR): You cannot specify the R type with other types for the same variable.;
			%return;
		%end;
		%else %if &typeR and not %sysfunc(prxmatch({^\w+/\w+(\*(\d+\.?\d*|\.\d+))?$}, &name)) %then %do;
			%put ER%str(ROR): An R-type expression must be of the form event/time or event/time*scale;
			%put ER%str(ROR)- where event and time are variables and scale is a numeric constant.;
			%return;
		%end;
		%else %if &typeM + &typeQ + &typeS > 1 %then %do;
			%put ER%str(ROR): You cannot combine the M, Q, and S types for the same variable.;
			%return;
		%end;
		%else %if %length(&type) = 0 %then %do;
			%put ER%str(ROR): You must specify a type (B, F, M, N, Q, R, or S) for variable %upcase(&name):;
			%let explain = 1;
		%end;
		%else %if %length(&trueVals) > 0 and not (&typeB or &typeR) %then %do;
			%put ER%str(ROR): Parenthetical values can be used only with the B and R type specifications.;
			%return;
		%end;

		%if &explain %then %do;
			%local oldLS s;
			%let oldLS = %sysfunc(getoption(ls));
			%let s = %str(   );
			options ls=100;
			%put B  Frequency (%) of "yes" values for a binary variable (uses only one row in table).;
			%put &s.By default, 1 means yes and all other non-missing values mean no. You can change;
			%put &s.what counts as a yes by enclosing a comma-delimited set of values in parentheses;
			%put &s.after the B. E.g., specifying B(0,3) means that 0 and 3 mean "yes" and every;
			%put &s.other non-missing value means no. This even works with character variables%str(;) just;
			%put &s.enclose the yes values in quotes, e.g., B("Female"). The value-matching works on;
			%put &s.the raw data values, not the formatted values.;

			%put F  Frequency (%) for levels of a categorical variable (each level gets a row). This;
			%put &s.is based on formatted values if there is a format, and raw values otherwise.;

			%put M  Mean (SD) for a continuous variable (uses only one row).;

			%put N  Number of distinct values (uses only one row). This is based on formatted values;
			%put &s.if there is a format, and raw values otherwise.;

			%put Q  Median (Q1-Q3), for a continuous variable (uses only one row).;

			%put R  Rate, for a combination of a binary variable and a time variable (uses only one row).;
			%put &s.The variable expression must be of the form event/time or event/time*scale, where;
			%put &s.event and time are variables and scale is an optional numeric constant, e.g.,;
			%put &s.died/YearsAtRisk*100 to calculate the death rate in deaths per 100 person-years.;
			%put &s.The rate is calculated as sum(event)/sum(time)*scale. An observation is included;
			%put &s.in the calculation if and only if both event and time are not missing. The R can;
			%put &s.optionally be followed by a parenthetical, comma-delimited list of "yes" values;
			%put &s.(exactly like a B-type variable). Any of these values will count as an event, and;
			%put &s.every other non-missing value means no. E.g., R("Cancer").;

			%put S  Sum for a variable (uses only one row).;

			options ls=&oldLS;
			%return;
		%end;

		%let fmt = ;
		%let dig = ;
		%let lab = ;
		%do j = 3 %to 5;
			%let extra = %scan(&block, &j, :, q);
			%if %sysfunc(prxmatch(/^\$?\w+\.[0-9]*$/, &extra)) or &extra = . %then %do;
				%if %length(&fmt)=0 %then %let fmt = &extra;
				%else %let extraBad = format;
			%end;
			%else %if %sysfunc(prxmatch(/^\d$/, &extra)) %then %do;
				%if %length(&dig)=0 %then %let dig = &extra;
				%else %let extraBad = number of decimal places;
			%end;
			%else %if %sysfunc(prxmatch(/^('.*'|".*")$/, &extra)) %then %do;
				%if %length(&lab)=0 %then %let lab = &extra;
				%else %let extraBad = label;
			%end;
			%else %if %length(&extra) > 0 %then %do;
				%put ER%str(ROR): The following expression is invalid in block &i:;
				%put ER%str(ROR)-    &extra;
				%if %sysfunc(prxmatch(/^\d+$/, &extra)) %then %do;
					%put ER%str(ROR)- If you meant to specify the number of decimal places, it must be;
					%put ER%str(ROR)- an integer from 0 to 9.;
				%end;
				%return;
			%end;

			%if %length(&extraBad) %then %do;
				%put ER%str(ROR): You specified more than one &extraBad in block &i:;
				%put ER%str(ROR)-    &block;
				%return;
			%end;
		%end;

		%if %length(&lab) = 0 %then %let lab = "&name";

		%if %length(&dig) > 0 and not (&typeM or &typeQ or &typeR or &typeS) %then %do;
			%put WA%str(RNING): The number of decimal places can only be specified for M, Q,;
			%put WA%str(RNING)- R, and S-type variables. The number in block &i will be ignored.;
			%if &typeB or &typeF %then %do;
				%put WA%str(RNING)- Use the digitsPct parameter to globally control the number of;
				%put WA%str(RNING)- decimal places for percentages.;
			%end;
			%let dig = ;
		%end;
		%if %length(&dig) = 0 %then %let dig = .;

		%if %length(&fmt) > 0 and not (&typeF or &typeN) %then %do;
			%put WA%str(RNING): Formats are only used for type F and N variables.;
			%put WA%str(RNING)- Format %upcase(&fmt) in block &i will be ignored.;
			%let fmt = ;
		%end;
		%if %length(&fmt) = 0 %then %let fmt = _;

		%if &typeN or &typeF %then %let varListNF = &varListNF &name;

		%if %length(&trueVals) = 0 %then %do;
			%if &typeB or &typeR %then %let trueVals = (1);
			%else %let trueVals = _;
		%end;

		%if &typeB %then %let hasTypeB = 1;
		%if &typeF %then %let hasTypeF = 1;
		%if &typeM %then %let hasTypeM = 1;
		%if &typeN %then %let hasTypeN = 1;
		%if &typeQ %then %let hasTypeQ = 1;
		%if &typeR %then %let hasTypeR = 1;
		%if &typeS %then %let hasTypeS = 1;
		%let hasAnyVar = 1;

		%if &debug %then %put Block &i: name=&name, type=&type&trueVals, fmt=&fmt, digits=&dig, lab=&lab;
	%end;

	%let nameList   = &nameList &name;
	%let labList    = &labList &lab;
	%let digitsList = &digitsList &dig;
	%let fmtList    = &fmtList &fmt;
	%let typeList   = &typeList &type;
	%let trueList   = &trueList.¶&trueVals;
	%if %length(&name) > &nameLength %then %let nameLength = %length(&name);
	%if %length(&lab) > &labLength %then %let labLength = %length(&lab);
%end;
%if &debug %then %do;
	%put nameList = &nameList;
	%put labList = &labList;
	%put digitsList = &digitsList;
	%put fmtList = &fmtList;
	%put typeList = &typeList;
	%put trueList = &trueList;
%end;

%if not &hasAnyVar %then %do;
	%put ER%str(ROR): You did not specify any variables to analyze.;
	%return;
%end;

%if not &debug %then %do; options nonotes; %end;

options &readAllObsOptions;

%* Make a dataset with all the variable names and labels, and note the order the user entered them in;
data _t1_varlist;
	array nameList[&nBlocks] $&nameLength _temporary_ (%apply('@', &nameList));
	array labList[&nBlocks] $&labLength _temporary_ (&labList);
	array digitsList[&nBlocks] _temporary_ (&digitsList);
	array fmtList[&nBlocks] $50 _temporary_ (%apply('@', &fmtList));
	array typeList[&nBlocks] $2 _temporary_ (%apply('@', &typeList));
	do i = 1 to &nBlocks;
		_name_ = upcase(nameList[i]);
		_label_ = labList[i];
		_digits_ = digitsList[i];
		_format_ = upcase(fmtList[i]);
		if _format_ = '_' then _format_ = '';
		_type_ = typeList[i];
		if index(_type_, 'F') = 2 then _type_ = reverse(_type_);
		_order_ + 1;
		if _type_ = '_' then _typeOrder_ = 0;
		else _typeOrder_ = 1;
		output;
	end;
	drop i;
	proc sort;
	by _type_ _order_;
run;

data _t1_varlist;
	set _t1_varlist;
	by _type_ _order_;
	if first._type_ then i = 0;
	i + 1;
	length _var_ $100;
	if _type_ = '_' then
		_var_ = _name_;
	else if _type_ = 'R' then
		_var_ = prxchange(cats('s{^\w+/\w+}{_RVarEvent',i,'/_RVarTime',i,'}'), 1, _name_);
	else
		_var_ = cats('_', _type_, 'Var', i);
	_var1_ = scan(_var_, 1);
	drop i;
	proc sort;
	by _name_;
run;

proc sql noprint;
	create table _t1_fmts as
	select upcase(name) as _name_ length=&nameLength, format as dataFormat
	from dictionary.columns
	where libname="%scan(&data,1)" and memname="%scan(&data,2)"
		and upcase(name) in (%apply('@', %upcase(&varListNF)) '.')
	order by _name_;
quit;

data _t1_varlist;
	merge _t1_varlist _t1_fmts;
	by _name_;
	_format_ = coalescec(_format_, dataFormat);
	if _format_ = '' then _format_ = '.';
	drop dataFormat;
	proc sort;
	by _var1_;
run;

%local varList;
proc sql noprint;
	select _var_, _format_
	into :varList separated by ' ', :fmtList separated by ' '
	from _t1_varlist
	order by _order_;
quit;
%if &debug %then %do;
	%put varList = &varList;
	%put fmtList (updated) = &fmtList;
%end;


%* Parse the CLASS block;
%local nClasses classVars classList classLabList classFmtList
	i block var extra1 extra2 fmt lab;

%if &noClass %then %do;
	%let nClasses = 1;
	%let classVars = _class1;
%end;
%else %do;
	%let class = %removeSpacesAround(:, &class, keepQuoted=Yes);
	%let nClasses = %sysfunc(countw(&class,,sq));
	%*put nClasses = &nClasses;

	%do i = 1 %to &nClasses;
		%let block  = %scan(&class, &i, ,sq);
		%let var    = %scan(&block, 1, :,q);
		%let extra1 = %scan(&block, 2, :,q);
		%let extra2 = %scan(&block, 3, :,q);
		%if %sysfunc(prxmatch(/^\$?\w+\.[0-9]*$/, &extra1)) or &extra1 = . %then %do;
			%let fmt = &extra1;
			%let lab = &extra2;
		%end;
		%else %do;
			%let fmt = &extra2;
			%let lab = &extra1;
		%end;
		%if %length(&fmt) = 0 %then %do;
			proc sql noprint;
				select format into :fmt
				from dictionary.columns
				where
					libname="%scan(&data,1)" and memname="%scan(&data,2)"
					and upcase(name) = "%upcase(&var)";
			quit;
			%if %length(&fmt) = 0 %then %let fmt = .;
		%end;
		%if %length(&lab) = 0 %then %let lab = "";

		%let classList = &classList &var;
		%let classVars = &classVars _class&i;
		%let classLabList = &classLabList &lab;
		%let classFmtList = &classFmtList &fmt;
	%end;

	%if &debug %then %do;
		%put classList = &classList;
		%put classLabList = &classLabList;
		%put classFmtList = &classFmtList;
	%end;
%end;

options fmtErr; %* fail if missing formats;
data _null_;
	%do i = 1 %to %sysfunc(countw(&fmtList &classFmtList, , s));
		%let fmt = %scan(&fmtList &classFmtList, &i, , s);
		%if &fmt ne . %then %do;
			x&i = 
				%if %substr(&fmt,1,1) = $ %then '';
				%else .;
				;
			format x&i &fmt;
		%end;
	%end;
run;
options &oldFmtErr;

%if &syserr > 0 %then %do;
	%put ER%str(ROR): Aborting &sysMacroName macro.;
	%goto errhandl;
%end;


options &oldObsOptions varInitChk=er%unquote(ror);

%* Make a copy of the input data, keeping only what we need and formatting the class variable;
data _t1_tempdata;
	set &data;
	%if %length(&where) > 0 %then where &where%str(;);

	%if &noClass %then %do;
		_class1 = &allText; %* dummy class variable;
	%end;
	%else %do;
		%do i = 1 %to &nClasses;
			_class&i = %scan(&classList, &i);
			%let fmt = %scan(&classFmtList, &i, , s);
			%if &fmt ne . %then
				format _class&i &fmt%str(;);
		%end;
	%end;

	%do i = 1 %to &nBlocks; /*%sysfunc(countw(&nameList,,s));*/
		%let type = %scan(&typeList, &i, , s);
		%if &type ne _ %then %do;
			%let name = %scan(&nameList, &i, , s);
			%let var = %scan(&varList, &i, , s);
			%let fmt = %scan(&fmtList, &i, , s);
			%let trueVals = %scan(&trueList, &i, ¶, sq);

			%if &type = B %then %do;
				if not missing(&name) then &var = (&name) in &trueVals;
				label &var = "&var (&name)";
			%end;
			%else %if &type = R %then %do;
				%if %qupcase(&trueVals) = %bquote((COUNT)) %then %do;
					%*put FOUND A COUNT VARIABLE: %scan(&name,1)!!!;
					if vtype(%scan(&name,1)) = 'C' then do;
						put "ER%str(ROR): Count variable %scan(&name,1) expected to be numeric.";
						call missing(%scan(&name,1));
					end;
					else if %scan(&name,1) < 0 then call missing(%scan(&name,1));
				%end;
				if cmiss(%sysfunc(prxchange(%str(s{[/\*]}{,}), 2, &name)))=0 then do;
					%scan(&var,1) = 
						%if %qupcase(&trueVals) = %bquote((COUNT)) %then %scan(&name,1);
						%else (%scan(&name,1) in &trueVals);
						;
					%scan(&var,2) = %scan(&name,2);
				end;			
				label %scan(&var,1) = "%scan(&var,1) (%scan(&name,1)), Event";
				label %scan(&var,2) = "%scan(&var,2) (%scan(&name,2)), Time";
			%end;
			%else %do;
				&var = &name;
				%if &fmt ne . %then
					format &var &fmt%str(;);
				label &var = "&var (&name)";
			%end;
		%end;
	%end;

	_Weight =
		%if %length(&weight)>0 %then &weight;
		%else 1;
		;
	label _Weight = '_Weight' %if %length(&weight)>0 %then "(&weight)";;

	_All = 0;

	if _er%unquote(ror_) then abort;
	keep
		%sysfunc(prxchange(s{_SEC\d+_|[/\*]|\b[\d\.]+\b}{ }, -1, &varList))
		&classVars &nVar _Weight _All;
	%if %length(&nVar) %then rename &nVar = _HeaderNVar%str(;);
run;

%if &syserr > 0 %then %do;
	%put ER%str(ROR): Aborting &sysMacroName macro.;
	%goto errhandl;
%end;


options &readAllObsOptions varInitChk=&oldVarInitChk;

%if not &debug %then %do;
	options &oldNotes;
	%put;
	%put NOTE: There were %nObs(_t1_tempdata) observations read from the data set &data..;
	options nonotes;
%end;


ods select none;
ods noresults;
ods noproctitle;

%* Remove records with invalid weight variable values;
%if %length(&weight) %then %do;
	data _t1_tempdata _t1_missingWeight;
		set _t1_tempdata;
		if missing(_Weight) or _Weight <= 0 then output _t1_missingWeight;
		else output _t1_tempdata;
	run;
%end;

%if &syserr > 0 %then %do;
	%put ER%str(ROR): Aborting &sysMacroName macro.;
	%goto errhandl;
%end;

%if not &debug and %length(&weight) %then %do;
	%local nMissWeight;
	%let nMissWeight = %nObs(_t1_missingWeight);
	%if &nMissWeight > 0 %then %do;
		options &oldNotes;
		%put;
		%put NOTE: &nMissWeight observations will be removed from table due to invalid weight.;
		options nonotes;
	%end;
%end;

%* If displaying an "All" column in addition to class-level columns, then double the input
   data. This lets us treat the doubled records, representing the "All" data, as just another
   class level.;
%if &all %then %do;
	data _t1_tempdata;
		set _t1_tempdata _t1_tempdata(in=inAll);
		if inAll then do;
			_All = 1;
			call missing(%delimit(%str(,), &classVars));
		end;
	run;
%end;

%* Count how many class levels there are, what they are called, how many records are in each level,
   and how much missingness there is in the class variable;
options missing=' ';
proc freq data=_t1_tempdata noprint;
	tables _All * %delimit(*, &classVars) / missing out=_t1_classes(drop=percent);
run;

%* Delete records with missing class from _t1_tempdata;
data _t1_tempdata _t1_missingClass;
	set _t1_tempdata(rename=(%apply(%str(@=_old@), &classVars)));
	%apply(%str(@ = vvalue(_old@);), &classVars)
	if _All or cmiss(%delimit(%str(,), &classVars)) = 0 then output _t1_tempdata;
	else output _t1_missingClass;
	drop _old_class:;
	proc sort data=_t1_tempdata;
	by _All &classVars;
run;

data _t1_classes;
	set _t1_classes(rename=(%apply(%str(@=_old@), &classVars)));
	%apply(%str(@ = vvalue(_old@);), &classVars)
	missingClass = _All=0 and cmiss(%delimit(%str(,), &classVars)) > 0;
	if not missingClass then do;
		index + 1;
		_classIndex_ = index;
	end;
	drop _old_class: index;
run;

data _t1_classes;
	set _t1_classes;
	where not missingClass;
	by &classVars notsorted;
	if first._class1 then index1 + 1;
	%if &nClasses > 1 %then %do i = 2 %to &nClasses;
		if first._class%eval(&i-1) then index&i = 0;
		if first._class&i then index&i + 1;
	%end;
	proc sort;
	by _All &classVars;
run;

data _t1_tempdata;
	merge _t1_tempdata _t1_classes(keep=_All _class:);
	by _All &classVars;
run;

proc sort data=_t1_classes;
	by _classIndex_;
run;

data _t1_classes;
	set _t1_classes;
	array classArray _class1-_class&nClasses;
	%if &specialChar %then %do; %* swap in the unicode characters;
		do over classArray;
			classArray = prxchange("s[<=][(*ESC*){unicode 2264}]", -1, classArray);
			classArray = prxchange("s[>=][(*ESC*){unicode 2265}]", -1, classArray);
			classArray = prxchange("s[\*\*\s*(-?\d+(\.\d+)?)][(*ESC*){super \1}]", -1, classArray);
			classArray = prxchange("s[\+-|\+/-][(*ESC*){unicode 00B1}]", -1, classArray);
		end;
	%end;
	length _class_ $500;
	if _All then _class_ = &allText;
	else _class_ = catx('¶', of _class1-_class&nClasses);
run;

%local nClassLevels classLevels classLevelsN classMissingN;
%let classMissingN = 0;
proc sql noprint;
	select count(_class_), _class_, count
	into :nClassLevels, :classLevels separated by '¤', :classLevelsN separated by ' '
	from _t1_classes
 	order by _classIndex_;

	select count(*)
	into :classMissingN
	from _t1_missingClass;
quit;
%let nClassLevels = &nClassLevels;

%local classNamesI classNames;
%do i = 1 %to &nClasses;
	proc sql noprint;
		select _class&i
		into :classNamesI separated by '¤'
		from (select distinct index&i, _class&i
			  from _t1_classes);
	quit;
	%let classNames = &classNames.¶%superq(classNamesI);
%end;

%* If user specified nVar parameter, use it to calculate the sample size for each class level;
%if %length(&nVar) > 0 %then %do;
	proc freq data=_t1_tempdata;
		tables _classIndex_ * _HeaderNVar;
		ods output crosstabfreqs=_t1_classLevelsN(where=(_type_='11' and frequency > 0));
	run;
	proc freq data=_t1_classLevelsN(keep=table _classIndex_);
		tables _classIndex_ / out=_t1_classLevelsN2(keep=_classIndex_ count);
	run;
	data _t1_classLevelsN3;
		merge _t1_classes(keep=_classIndex_) _t1_classLevelsN2;
		by _classIndex_;
		if count = . then count = 0;
	run;
	proc sql noprint;
		select count
		into :classLevelsN separated by ' '
		from _t1_classLevelsN3
	 	order by _classIndex_;
	quit;
%end;

%if &debug %then %do;
	%put nClassLevels  = &nClassLevels;
	%put classLevels   = %superq(classLevels);
	%put classLevelsN  = &classLevelsN;
	%put classNames    = &classNames;
	%put classMissingN = &classMissingN;
%end;


%* Note in the log how many records were kicked out due to missing the class;
%if &classMissingN > 0 %then %do;
	%if not &debug %then options &oldNotes%str(;);
	%if &all %then %do;
		%put NOTE: %unquote(&classMissingN) observations will not appear in the class portion of the;
		%put NOTE- table due to missing class.;
	%end;
	%else %put NOTE: %unquote(&classMissingN) observations will be removed from table due to missing class.;
	%if not &debug %then options nonotes%str(;);
%end;


%* Count how many missing values there are in each variable;
%local missingVarList;
%let missingVarList = %sysfunc(prxchange(s{_SEC\d+_|/\w+(\*[\d\.]+)?}{ }, -1, &varList));

%if &nClassLevels = 1 or not &ignoreMissAll %then %do;
	proc freq data=_t1_tempdata;
		where _All = &all;
		tables &missingVarList / missing;
		ods output onewayfreqs=_t1_missing;
	run;

	data _t1_missing;
		length _var1_ $100;
		set _t1_missing;
		_var1_ = substr(table, 7);
		array F[*] %apply(F_@, &missingVarList);
		if coalesceC(of F[*]) = ' ';

		length missingPct $4;
		if percent in (0 100) then
			missingPct = left(put(percent, 3.0));
		else if 0 < percent < 1 then
			missingPct = "<1";
		else if percent > 99 then
			missingPct = ">99";
		else if not missing(percent) then
			missingPct = left(put(percent, 3.0));
		missingPct = cats(missingPct, "%");

		keep _var1_ frequency missingPct;
		rename frequency=missingN;
		proc sort;
		by _var1_;
	run;

	data _t1_missing;
		merge _t1_missing(in=in1)
			  _t1_varlist(keep=_var1_ _type_ where=(_type_ ne '_'));
		by _var1_;
		if not in1 then do;
			missingN = 0;
			missingPct = '0%';
		end;
		drop _type_;
	run;
%end;
%else %do;
	proc freq data=_t1_tempdata;
		where _All = &all;
		tables (&missingVarList) * _classIndex_ / missing;
		ods output crosstabfreqs=_t1_missing(where=(_type_ = '11'));
	run;

	data _t1_missing;
		length _var1_ $100;
		set _t1_missing;
		_var1_ = prxchange('s{^Table (\w+) .*}{\1}', 1, table);
		if vvaluex(_var1_) = ' ';
		_classLevelN_ = input(scan("&classLevelsN", _classIndex_), 32.);
		if colPercent = 100 then call missing(frequency, colPercent);
	run;

	proc means data=_t1_missing nway noprint;
		class _var1_;
		var colPercent / weight=_classLevelN_;
		output out=_t1_missing(keep=_var1_ colPercent) mean=;
	run;

	data _t1_missing;
		merge _t1_missing(in=in1)
			  _t1_varlist(keep=_var1_ _type_ where=(_type_ ne '_'));
		by _var1_;
		length missingPct $4;
		if n(colPercent) then do;
			if colPercent in (0 100) then
				missingPct = left(put(colPercent, 3.0));
			else if 0 < colPercent < 1 then
				missingPct = "<1";
			else if colPercent > 99 then
				missingPct = ">99";
			else if not missing(colPercent) then
				missingPct = left(put(colPercent, 3.0));
			missingPct = cats(missingPct, "%");
		end;
		else if not in1 then
			missingPct = '0%'; %* variable is not missing at all;
		else
			missingPct = '100%'; %* variable is 100% missing in all class levels;
		drop _type_;
	run;
%end;


%* Summarize binary variables;
%if &hasTypeB %then %do;
	proc means data=_t1_tempdata n mean sum stackodsoutput;
		class _classIndex_;
		var _BVar:;
		%if %length(&weight) %then weight _Weight%str(;);
		ods output summary=_t1_dataB(keep=_classIndex_ variable n mean sum);
	run;
	data _t1_dataB;
		length _var1_ $100;
		set _t1_dataB;
		_var1_ = variable;
		_typeOrder_ = 1;
		if not missing(mean) then do;
			frequency = round(sum, 1);
			rowPercent = 100 * mean;
		end;
		else if n = 0 then frequency = 0;
		keep _var1_ _classIndex_ _typeOrder_ frequency rowPercent;
		proc sort;
		by _var1_;
	run;
%end;

%* Summarize categorical variables;
%if &hasTypeF %then %do;
	proc freq data=_t1_tempdata;
		tables _classIndex_ * (_F:);
		%if %length(&weight) %then weight _Weight%str(;);
		ods output crosstabfreqs=_t1_dataF(where=(_type_='11'));
	run;
	%if &syserr > 0 %then %do;
		%put ER%str(ROR): Aborting &sysMacroName macro.;
		%goto errhandl;
	%end;
	data _t1_dataF;
		length _var1_ $100;
		set _t1_dataF;
		by table _classIndex_ notsorted;
		_var1_ = prxchange('s{^.*\* }{}', 1, table);
		_level_ = strip(vvaluex(_var1_));
		if first._classIndex_ then _levelOrder_ = 0;
		_levelOrder_ + 1;
		_typeOrder_ = 2;
		keep _var1_ _level_ _classIndex_ _levelOrder_ _typeOrder_ frequency rowPercent;
	run;
%end;

%* Summarize continuous variables by getting mean, sd, median, q1, q3, and sum;
%if &hasTypeM or &hasTypeQ or &hasTypeS %then %do;
	%local varListMQS;
	proc sql noprint;
		select _var1_
		into :varListMQS separated by ' '
		from _t1_varlist
		where prxmatch('/[MQS]/', _type_);
	quit;
	proc means data=_t1_tempdata mean std median q1 q3 sum stackodsoutput;
		class _classIndex_;
		var &varListMQS;
		%if %length(&weight) %then weight _Weight%str(;);
		ods output summary=_t1_dataMQS;
	run;
	data _t1_dataMQS;
		length _var1_ $100;
		set _t1_dataMQS;
		_var1_ = variable;
		_typeOrder_ = 1;
		length _type_ $2;
		_type_ = prxchange('s{^_F?(.*?)Var\d+$}{\1}', 1, trim(_var1_));
		keep _var1_ _classIndex_ _typeOrder_ _type_ mean stdDev median q1 q3 sum;
	run;
%end;

%* Summarize 'number' variables, where we count the number of distinct values;
%if &hasTypeN %then %do;
	proc freq data=_t1_tempdata;
		tables _classIndex_ * (_NVar:);
		ods output crosstabfreqs=_t1_dataN(where=(_type_='11' and frequency > 0));
	run;
	proc freq data=_t1_dataN(keep=table _classIndex_);
		tables table * _classIndex_;
		ods output crosstabfreqs=_t1_dataN2(where=(_type_='11'));
	run;
	data _t1_dataN;
		length _var1_ $100;
		set _t1_dataN2;
		_var1_ = prxchange('s{^.*\* }{}', 1, table2);
		_typeOrder_ = 1;
		keep _var1_ _classIndex_ _typeOrder_ frequency;
	run;
%end;

%* Summarize event-rate expressions;
%if &hasTypeR %then %do;
	proc means data=_t1_tempdata sum stackodsoutput;
		class _classIndex_;
		var _RVarEvent: _RVarTime:;
		%if %length(&weight) %then weight _Weight%str(;);
		ods output summary=_t1_dataR(keep=_classIndex_ Variable Sum);
	run;
	data _t1_dataR;
		set _t1_dataR;
		VarIndex = input(prxchange('s{^\w+?(\d+)$}{\1}', 1, strip(variable)), 10.);
	run;
	data _t1_dataR;
		length _var1_ $100;
		merge _t1_dataR(where=(index(Variable,'Time'))  rename=(Sum=Time))
			  _t1_dataR(where=(index(Variable,'Event')) rename=(Sum=Events));
		by _classIndex_ VarIndex;
		_var1_ = variable;
		_typeOrder_ = 1;
		proc sort;
		by _var1_;
	run;
	data _t1_dataR;
		merge _t1_dataR(in=inR) _t1_varlist(keep=_var1_ _name_);
		by _var1_;
		if inR;
		if cmiss(Events,Time)=0 and Time ne 0 then do;
			Rate = Events / Time;
			scale = input(scan(_name_, 2, "*"), 32.);
			if not missing(scale) then Rate = Rate * scale;
		end;
		keep _var1_ _classIndex_ _typeOrder_ Rate Events Time scale;
	run;
%end;

ods select all;
ods results;


%* Combine the summary data for all variables. This produces a 'long' dataset, with a record for each combination
   of variable level and class level (a variable will only have multiple levels when using the F type).;
data _t1_long_pre;
	retain _var1_ _typeOrder_ %if &hasTypeF %then _level_;;
	length _type_ $2;
	set
		%if &hasTypeB %then _t1_dataB;
		%if &hasTypeF %then _t1_dataF;
		%if &hasTypeM or &hasTypeQ or &hasTypeS %then _t1_dataMQS;
		%if &hasTypeN %then _t1_dataN;
		%if &hasTypeR %then _t1_dataR(drop=Events Time scale);
		inDsName=source
		;
	if missing(_type_) then _type_ = substr(reverse(strip(source)),1,1);
	%if not &hasTypeF %then %do;
		_level_ = "";
		_levelOrder_ = .;
	%end;
	%else %do;
		if missing(_level_) then _level_ = "";
	%end;
	proc sort;
	by _var1_ _typeOrder_ _levelOrder_ _classIndex_;
run;

data _t1_long;
	merge _t1_varList(keep=_name_ _var1_ _digits_)
		  _t1_long_pre(in=in1);
	by _var1_;
	if in1;
	if _type_ = 'F' then _digits_ = .;

	length stat1 stat2 statx $200;
	call missing(stat1, stat2);
	%if &hasTypeB or &hasTypeF %then %do;
		if _type_ in ('B' 'F') then do;
			if missing(rowPercent) and frequency = 0 then do;
				stat1 = '-';
				stat2 = '(-)';
				statx = '-';
			end;
			else do;
				stat1 = left(put(frequency, 32.));
				if rowPercent in (0 100) then
					pctChar = left(put(rowPercent, 32.&digitsPct0));
				%if %length(&digitsPctLimit)>0 %then %do;
				else if 0 < rowPercent < &digitsPctLimit then
					pctChar = "<&digitsPctLimit";
				else if rowPercent > round(100-&digitsPctLimit,1e-9) then
					pctChar = cats(">", round(100-&digitsPctLimit,1e-9));
				%end;
				else if 0 < rowPercent < 0.95 or rowPercent >= 99.05 then
					pctChar = left(put(rowPercent, 32.&digitsPctLT1));
				else if not missing(rowPercent) then
					pctChar = left(put(rowPercent, 32.&digitsPct));
				%if &trim0 %then %do;
					pctChar = prxchange('s{(\.[0-9]*?[1-9])0+$}{\1}', 1, strip(pctChar));
					pctChar = prxchange('s{\.0+$}{}', 1, strip(pctChar));
				%end;
				stat2 = cats("(", pctChar, "%)");
				%if &merge and &freq %then %do;
					statx = catx(" ", stat1, stat2);
				%end;
				%else %do;
					statx = cats(pctChar, "%");
				%end;
			end;
		end;
	%end;
	%if &hasTypeM or &hasTypeQ or &hasTypeS %then %do;
		array statN[6]      mean  stdDev  median  q1  q3  sum;
		array statC[6] $100 meanC stdDevC medianC q1C q3C sumC;
		if _type_ in ('M' 'Q' 'S') then do;
			do i = 1 to dim(statN);
				if missing(statN[i]) then statC[i] = '-';
				else if missing(_digits_) then do;
					     if   -1 < statN[i] < 1   then statC[i] = put(statN[i], 32.&digitsLT1);
					else if  -10 < statN[i] < 10  then statC[i] = put(statN[i], 32.&digits1to10);
					else if -100 < statN[i] < 100 then statC[i] = put(statN[i], 32.&digits10to100);
					else                               statC[i] = put(statN[i], 32.&digitsGE100);
				end;
				else do; %* has _digits_;
					if _digits_ = 0 then
						statC[i] = put(statN[i], 32.);
					else do;
						statC[i] = put(round(statN[i], 10**-_digits_), 32.10);
						statC[i] = prxchange(cats('s[^(.*\.\d{',_digits_,'})0*$][\1]'), 1, strip(statC[i]));
					end;
				end;
				%if &trim0 %then %do;
					statC[i] = prxchange('s{(\.[0-9]*?[1-9])0+$}{\1}', 1, strip(statC[i]));
					statC[i] = prxchange('s{\.0+$}{}', 1, strip(statC[i]));
				%end;
			end;
			if _type_ = 'M' then do;
				stat1 = left(meanC);
				stat2 = cats("(", stdDevC, ")");
				if &plusMinus then statx = catx(" &pm ", stat1, stdDevC);
				else statx = catx(" ", stat1, stat2);
			end;
			else if _type_ = 'Q' then do;
				stat1 = left(medianC);
				if missing(q1) then stat2 = '[-]';
				else stat2 = catx(&IQRsep, cats("[",q1C), cats(q3C,"]"));
				statx = catx(" ", stat1, stat2);
			end;
			else if _type_ = 'S' then do;
				stat1 = left(sumC);
				statx = stat1;
			end;
			if stat1 = '-' then statx = '-';
		end;
	%end;
	%if &hasTypeN %then %do;
		if _type_ = 'N' then do;
			stat1 = left(put(frequency, 32.));
			statx = stat1;
		end;
	%end;
	%if &hasTypeR %then %do;
		if _type_ = 'R' then do;
			if missing(rate) then stat1 = '-';
			else if missing(_digits_) then do;
				     if   -1 < rate < 1   then stat1 = put(rate, 32.&digitsLT1);
				else if  -10 < rate < 10  then stat1 = put(rate, 32.&digits1to10);
				else if -100 < rate < 100 then stat1 = put(rate, 32.&digits10to100);
				else                           stat1 = put(rate, 32.&digitsGE100);
			end;
			else do; %* has _digits_;
				if _digits_ = 0 then
					stat1 = put(rate, 32.);
				else do;
					stat1 = put(round(rate, 10**-_digits_), 32.10);
					stat1 = prxchange(cats('s[^(.*\.\d{',_digits_,'})0*$][\1]'), 1, strip(stat1));
				end;
			end;
			%if &trim0 %then %do;
				stat1 = prxchange('s{(\.[0-9]*?[1-9])0+$}{\1}', 1, strip(stat1));
				stat1 = prxchange('s{\.0+$}{}', 1, strip(stat1));
			%end;
			stat1 = left(stat1);
			statx = stat1;
		end;
	%end;

	keep _name_ _var1_ _typeOrder_ _type_ _levelorder_ _classIndex_ _level_ stat1 stat2 statx;
run;

%if %sysevalf(%superq(injectLong)^=,boolean) %then %do;
	data _t1_long;
		set _t1_long;
		&injectLong;
	run;
%end;

%if &syserr > 0 %then %do;
	%put ER%str(ROR): Aborting &sysMacroName macro.;
	%goto errhandl;
%end;

%* Transpose data to wide format, with one record for each variable level. There will be a separate column for each
   class level. If we are printing frequencies (FREQ = Yes), then we tranpose the long data twice: once for stat1
   (ie, frequencies, means, medians) and once for stat2 (ie, percents, sds, IQRs). Otherwise we only transpose once,
   for statx.;
%if not &merge %then %do;
	%do i = 1 %to 2;
		proc transpose data=_t1_long name=_oldname_ out=_t1_stat&i(drop=_oldname_) prefix=stat&i._;
			by _var1_ _typeOrder_ _levelOrder_ _level_ notsorted;
			var stat&i;
		run;
	%end;

	%* Merge the wide stat1 and stat2 datasets;
	data &out;
		merge _t1_stat1 _t1_stat2;
		by _var1_ _typeOrder_ _levelOrder_ _level_;
	run;
%end;
%else %do;
	proc transpose data=_t1_long name=_oldname_ out=&out(drop=_oldname_) prefix=stat_;
		by _var1_ _typeOrder_ _levelOrder_ _level_ notsorted;
		var statx;
	run;
%end;

%if &syserr > 0 %then %do;
	%put ER%str(ROR): Aborting &sysMacroName macro.;
	%goto errhandl;
%end;


%* For variables specified only as type F, add in an extra row above to contain the variable label;
data &out;
	merge &out _t1_varlist(keep=_var1_ _typeOrder_);
	by _var1_ _typeOrder_;
run;


%* Merge in the variable labels and order, as specified by the user;
data &out;
	length _column1_ $200;
	merge _t1_varlist(drop=_typeOrder_) &out _t1_missing;
	by _var1_;
	if _typeOrder_ in (0 1) then _column1_ = _label_; %* create the 1st column of the table;
	else _column1_ = _level_;
	%if &specialChar %then %do; %* swap in the unicode characters;
		_column1_ = prxchange("s[<=][(*ESC*){unicode 2264}]", -1, _column1_);
		_column1_ = prxchange("s[>=][(*ESC*){unicode 2265}]", -1, _column1_);
		_column1_ = prxchange("s[\*\*\s*(-?\d+(\.\d+)?)][(*ESC*){super \1}]", -1, _column1_);
		_column1_ = prxchange("s[\+-|\+/-][(*ESC*){unicode 00B1}]", -1, _column1_);
	%end;
	%if &paddingLeft > 0 %then %do;
		if _column1_ ne ' ' then do;
			if _typeOrder_ in (0 1) and first(_column1_) = ' ' then do;
				leadingSpaces = length(_column1_) - length(left(_column1_));
				_column1_ = repeat('a0'x, leadingSpaces*&paddingLeft-1) || left(_column1_);
			end;
			if _typeOrder_ = 2 then do;
				leadingSpaces = length(_label_) - length(left(_label_));
				_column1_ = repeat('a0'x, (leadingSpaces+1)*&paddingLeft-1) || _column1_;
			end;
		end;
		drop leadingSpaces;
	%end;
	if _typeOrder_ = 2 then call missing(of missing:);
	if _type_ = 'F' and _typeOrder_ = 1 then call missing(of stat:);

	label
	%local labelI;
	%do i = 1 %to &nClassLevels;
		%let labelI = %qscan(%superq(classLevels),&i,¤);
		%if &merge %then stat_&i = "&labelI";
		%else stat1_&i = "&labelI"  stat2_&i = "&labelI";
	%end;
		;

	%if &all or &noClass %then %do;
		rename
			%if &merge %then stat_&nClassLevels = stat_all;
			%else stat1_&nClassLevels = stat1_all  stat2_&nClassLevels = stat2_all;
			;
	%end;

	proc sort;
	by _order_ _typeOrder_ _levelOrder_ _level_;
run;

%if %sysevalf(%superq(inject)^=,boolean) %then %do;
	data &out;
		set &out;
		&inject;
	run;
%end;


%if not &debug %then %do;
	options &oldNotes;
	%nObsVars(&out, note=yes)
	options nonotes;
%end;

/* Example values of macro vars neeeded/helpful for printing the table:
classList     = country gender
classLabList  = "Country by Gender" ""
nClasses      = 2
nClassLevels  = 8
classLevels   = Europe¶Female¤Europe¶Male¤N. America¶Female¤N. America¶Male¤Other¶Female¤Other¶Male¤Japan¶Female¤Japan¶Male
classLevelsN  = 1175 2140 8480 10712 237 310 686 1431
classNames    = ¶Europe¤Japan¤N. America¤Other¶Female¤Male
*/
*options mprint mlogic;

%local nText j classLevelsI;
%* Print Table 1;
options missing=' ';
proc report data=&out nowd split='¶' style(header)=[verticalalign=bottom] contents='';
	column _order_ _typeOrder_ (&col1Text _column1_)

		%if (&all or &noClass) and &allSide=L %then %do;
			(
			%if &n %then %let nText = ¶(&nPrefix%scan(&classLevelsN,&nClassLevels));
			"%scan(%superq(classLevels),&nClassLevels,¤)&nText"
			%if &merge %then stat_all; %else stat1_all stat2_all;
			)
		%end;

		%if not &noClass %then (;
		%if %length(&classLabList) > 0 %then %scan(&classLabList, 1, ,sq);

		%if &headerSpan and &nClasses >= 2 and &nClasses <= 4 %then %do;
			%local statVar payload class1Levels index
				class1Level sameClass1  class2Level sameClass2  class3Level sameClass3;

			%if &n %then %let nText = ¶(&nPrefix%nrstr(%scan(&classLevelsN, &index)));

			%if &merge %then %let statVar = %nrstr(stat_&index);
			%else %let statVar = %nrstr(stat1_&index stat2_&index);

			%let payload = %nrstr(
				("%qscan(%qscan(%superq(classLevels), &index, ¤), &nClasses, ¶)&nText" &statVar)
			);

			%let class1Levels = %qscan(%superq(classNames), 1, ¶);
			%let index = 1;
			%do i = 1 %to %sysfunc(countw(&class1Levels, ¤));
				%let class1Level = %qscan(&class1Levels, &i, ¤);
				("&class1Level" (%scan(&classLabList, 2, ,sq)
				%let sameClass1 = 1;
				%do %while(&sameClass1);
					%if &nClasses = 2 %then %do;
						%unquote(%unquote(&payload))
						%let index = %eval(&index + 1);			
					%end;
					%else %do;
						%let class2Level = %qscan(%qscan(%superq(classLevels), &index, ¤), 2, ¶);
						("&class2Level" (%scan(&classLabList, 3, ,sq)
						%let sameClass2 = 1;
						%do %while(&sameClass2);
							%if &nClasses = 3 %then %do;
								%unquote(%unquote(&payload))
								%let index = %eval(&index + 1);
							%end;
							%else %do;
								%let class3Level = %qscan(%qscan(%superq(classLevels), &index, ¤), 3, ¶);
								("&class3Level" (%scan(&classLabList, 4, ,sq)
								%let sameClass3 = 1;
								%do %while(&sameClass3);
									%unquote(%unquote(&payload))
									%let index = %eval(&index + 1);
									%if %qscan(%qscan(%superq(classLevels), &index, ¤), 3, ¶) ne &class3Level or
										%qscan(%qscan(%superq(classLevels), &index, ¤), 2, ¶) ne &class2Level or
										%qscan(%qscan(%superq(classLevels), &index, ¤), 1, ¶) ne &class1Level %then %let sameClass3 = 0;
								%end;
								))
							%end;
							%if %qscan(%qscan(%superq(classLevels), &index, ¤), 2, ¶) ne &class2Level or
								%qscan(%qscan(%superq(classLevels), &index, ¤), 1, ¶) ne &class1Level %then %let sameClass2 = 0;
						%end;
						))
					%end;
					%if %qscan(%qscan(%superq(classLevels), &index, ¤), 1, ¶) ne &class1Level %then %let sameClass1 = 0;
				%end;
				))
			%end;
		%end;

		%else %if not &noClass %then %do i = 1 %to &nClassLevels - &all;
			%let classLevelsI = %scan(%superq(classLevels), &i, ¤, m);
			%do j = 1 %to &nClasses;
				(%if &n and &j=&nClasses %then "%qscan(%superq(classLevelsI),&j,¶,m)¶(&nPrefix%scan(&classLevelsN,&i))";
				 %else "%qscan(%superq(classLevelsI),&j,¶,m)";
			%end;
			%if &merge %then stat_&i; %else stat1_&i stat2_&i;
			%do j = 1 %to &nClasses;
				)
			%end;
		%end;

		%if not &noClass %then );

		%if (&all or &noClass) and &allSide=R %then %do;
			(
			%if &n %then %let nText = ¶(&nPrefix%scan(&classLevelsN,&nClassLevels));
			"%scan(%superq(classLevels),&nClassLevels,¤)&nText"
			%if &merge %then stat_all; %else stat1_all stat2_all;
			)
		%end;

		%if &missing %then ("% Missing" missingPct);
		;

	define _order_ / order noprint;
	define _typeOrder_ / order noprint;
	define _column1_ / "" %if %length(&col1Width) %then style(column)=[tagattr='wraptext:no' width=&col1Width];;
	%do i = 1 %to &nClassLevels;
		%let index = &i;
		%if (&all or &noClass) and &i = &nClassLevels %then %let index = all;
		%if &merge %then %do;
			define stat_&index / "" center %if %length(&statColWidth) %then style(column)=[tagattr='wraptext:no' width=&statColWidth];;
		%end;
		%else %do;
			define stat1_&index / "" display style(column)=[paddingRight=0.03in borderRightStyle=hidden borderRightWidth=0pt] right;
			define stat2_&index / "" display style(column)=[paddingLeft=0.03in borderLeftStyle=hidden borderLeftWidth=0pt];
		%end;
	%end;
	%if &missing %then define missingPct / "" center%str(;);
	%if &sectionCount > 0 %then %do; %* Make section headers bold;
		compute _column1_;
			if _typeOrder_ = 0 then call define('_c3_', 'style', "style=[&secStyle]");
		endcomp;
	%end;
run; quit;
options missing=.;
ods proctitle;

%errhandl:
%if not &debug %then %do;
	options nonotes;
	proc datasets noprint;
		delete &tempDatasets;
	quit;
%end;
options &oldNotes &oldFmtErr &oldObsOptions varInitChk=&oldVarInitChk;
%if &oldNotes = NOTES %then %do;
	%put NOTE: Macro &sysMacroName used %unquote(%sysfunc(putn(%sysfunc(datetime())-&startTime, 16.2))) seconds.; 
	%put ;
%end;
%mend table1;

/* Example usage

* include dependencies;
%include "U:\DOPPS\work\Daniel Scratch\Macros\requireMacros.sas";

*** Example 1 ***;

proc format;
	value agef
		low-<65 = '<65'
		65-high = '>=65'
		;
	value $region
		"Belgium","France","Spain","Sweden","UK","Germany","Italy","Russia" = "Europe"
		"Canada","US" = "N. America"
		"Japan" = "Japan"
		Other = "Other"
		;
run;

*ods excel file='test.xlsx';
* characteristics by study region and gender;
%table1(facID:N:'# of facilities'
		patientID:N:'# of patients'
		Gender:F
		mAge:MF:agef.:"Age"
		Vintage:Q:3
		all_died_7:B:"Died"
		all_died_7/all_patYrs_7*100:R:"Deaths per 100 person-years"
		mComCAD:B:"Coronary Heart Disease"
		mComDiabetes:B:"Diabetes",
		class=country:region.:"Country by Gender" gender,
		data=dopps6.m_f, debug=yes);
*ods excel close;

* characteristics by diabetic status. Do not print frequencies for categorical variables;
%table1(patientID:N:"Number of patients"
		mAge:MF:agef.:"Age"
		Gender:F
		Vintage:Q
		all_died_7:B:"Died"
		all_died_7/all_patYrs_7*100:R:"Deaths per 100 person-years"
		mComDiabetes:B
		mComCAD:B:"Coronary Heart Disease",
		class=mComDiabetes:"Diabetic",
		data=dopps6.m_f,
		n=No, freq=No);


*** Example 2 ***;

* create fake data to play with;
data mydata;
	array cntry[5] $25 _temporary_ ("US" "Brazil" "Germany" "Japan" "France");
	call streaminit(12345);
	do patientID = 1 to 97;
		quartile = rand('Table', 1/4, 1/4, 1/4);
		male = rand('Bernoulli', 0.6);
		mAge = round(rand('Normal', 60, 15), 1);
		BMI = round(rand('Normal', 32, 6), 0.001);
		vintage = rand('Gamma', 1.5, 2);
		nDrugs = rand('Poisson', 2.5);
		cntryCode = 1 + rand('Binom', quartile/5, 4); drop cntryCode;
		country = cntry[cntryCode];
		facilityID = 10**(cntryCode - 1) + rand('Poisson', 3);
		array all _numeric_;
		do over all;
			if vname(all) not in ('patientID' 'facilityID') and rand('Bernoulli', 0.1) then all = .;
		end;
		output;
	end;
run;

proc format;
	value agef
		low-<65 = '<65'
		65-high = '>=65'
		;
	value bmif
		low-<25 = '<25'
		25-<35 = '25-35'
		35-high = '>=35'
		;
	value quartile
		1 = '1st'
		2 = '2nd'
		3 = '3rd'
		4 = '4th'
		;
run;

%table1(male:B:'Male'
		mAge:QF:agef.:"Patient's age, yrs"
		Vintage:M
		BMI:F:"Body mass index":bmif.
		nDrugs:F
		patientID:N:"Number of patients"
		facilityID:N:"Number of facilities"
		country:N:"Number of countries",
		class=Quartile:quartile.:"Quartile of something", all=y,
		data=mydata, IQRsep=-, freq=No, n=No);
*/
