/*****************************************************************
	Name:			mixedProgAdj
	Purpose:		Progessively adjust a cox model
	Parameters:		
	Create Date:	August 20, 2012
	Creator:		Brian Bieber
	
	Example:		%mixedProgAdj(dsn=mq, outcome=mhgbgdl, adj1=mage, adj2=malbumingdl, adj3=vintage);
		
	Notes:			Future iterations
						estimates for levels of class variable
						error trapping
						choose different output table types						
******************************************************************/

%macro mixedProgAdj (dsn=/*dataset name*/, 
                    outcome=/*outcome of interest*/, 
                    clusteringVars=facid /*variables for clustering in repeated statement (default=facid)*/,
                    where=1/*where considtion (default=1)*/, 
                    html=0/*create HTML table (default=0)*/, 
                    htmlName=/*name of HTML table*/,
					adj1=/*variables to adjust for in model 1*/, 
                    adj2=/*variables to adjust for in model 2*/, 
                    adj3=/*variables to adjust for in model 3*/, 
                    adj4=/*variables to adjust for in model 4*/, 
                    adj5=/*variables to adjust for in model 5*/, 
                    adj6=/*variables to adjust for in model 6*/, 
                    adj7=/*variables to adjust for in model 7*/, 
                    adj8=/*variables to adjust for in model 8*/, 
                    adj9=/*variables to adjust for in model 9*/, 
                    adj10=/*variables to adjust for in model 10*/,  
					class=/*class variables*/,
					fmt=8.3/*number format for model estimates*/,
                    verbose=1/*include all model output (default=1)*/
                    );

	%local i j adjAll;

	*Clean up any leftover tables;
    proc datasets nolist nodetails nowarn library=work memtype=data; delete mixed_: betaAll betaN; run;
	
	%let i = 1;
	%let adjAll = &adj1.;

	*Check for titles;
	%storeTitles();
    %if &verbose. ne 1 %then ods exclude all;;
	%do %while (%length(&&adj&i) > 1);
		%printTitles()
		%titleNext(Mixed Model: progressive adjustment - outcome=&outcome.)
		%titleNextCum(Restriction(s): &where)
		%titleNextCum(Model &i)
		

		proc mixed data=&dsn plots=none;
			where &where. AND not missing(&outcome.);;
			class &clusteringVars. &class.;	
		 	model &outcome. = &adjAll. / solution cl;       

		 	repeated /  type=cs sub=&clusteringVars.;  

			ods output	Nobs			= mixed_nobs (keep = nobsRead nobsUsed label where = (label = 'Number of Observations Read')) /*keep label only to delete rows 2 and 3*/
						SolutionF		= mixed_solutionF
			;				
		run;

		data mixed_solutionF;
			length effect $40.;
			set mixed_solutionF;
			model = &i.;
			subOrder = _n_;
		run;

		*Collate datasets;
		data betaAll;
			set %if &i. ne 1 %then betaAll;
				mixed_solutionF (in=inNew);
		run;

		data nAll;
			set %if &i. ne 1 %then nAll;
				mixed_nobs (in=inNew drop=label);
			if inNew then model = &i.;
		run;


        proc datasets nolist nodetails nowarn library=work memtype=data; delete mixed_:; run;

		*Increment i and cumulate adjustments;
		%let i = %eval(&i+1);
		%let adjAll = &adjAll &&adj&i;
		%printTitles();
	%end;	
    %if &verbose. ne 1 %then ods exclude none;;

	%if &html. = 1 %then ods html style = journal %if %length(&htmlName.) %then file = "&htmlName..html"; %else file = "mixed_progAdj_&outcome..html";;;
	%printTitles()
	%titleNext(Mixed Model: progressive adjustment - outcome=&outcome)
	%titleNextCum(Restriction(s): &where)
	%titleNextCum(Model results)
	proc report data=betaAll nowd;
		column suborder effect model , (estimate lower upper probt CI95);
		define suborder / noprint order group;
		define model / group across;
		define effect / group;
		define estimate  / MAX f=&fmt.;
		define lower  / noprint MAX f=&fmt;
		define upper / noprint MAX f=&fmt;
		define probt / noprint MAX f=pvalue8.3;
		define CI95 / computed format=$30.;

		compute CI95 / char length=30;
		%do j = 1 %to %eval(&i.-1);
			if 0 le _c%eval(&j.*5+1)_ lt 0.05 then 	_c%eval(&j.*5+2)_ 	= "(" || strip(put(_c%eval(&j.*5-1)_, &fmt)) || ","  || strip(put(_c%eval(&j.*5)_, &fmt))  || ")*";
			else if _c%eval(&j.*5+1)_ > 0.05 then	_c%eval(&j.*5+2)_ 	= "(" || strip(put(_c%eval(&j.*5-1)_, &fmt)) || ","  || strip(put(_c%eval(&j.*5)_, &fmt))  || ")";
			else 									_c%eval(&j.*5+2)_ 	= "";
		%end;
		endcomp;
	run;

	%printTitles();
	%titleNext(Mixed Model: progressive adjustment - outcome=&outcome)
	%titleNextCum(Restriction(s): &where)
	%titleNextCum(Observations per model)
	proc sql;
		SELECT model, nobsread, nobsused, nobsread-nobsused AS nObsMiss
		FROM nAll;
	quit;
	%if &html. = 1 %then ods html close;;
%mend mixedProgAdj;