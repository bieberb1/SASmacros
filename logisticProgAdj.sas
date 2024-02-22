/*****************************************************************
	Name:		logisticProgAdj
	Purpose:		Progressively adjust logistic model
	Parameters:	dsn= ,
				where = , 
				outcome=, 
				class = , 
				html= ,
				fmt = ,
				corrStructure = , 
				adj1, adj2, etc = 
				
	Create Date:	December 8th, 2014
	Creator:		Brian Bieber
	
	Example:		
	Notes:		BB140708	need to add a 'pick' option to get single parameters
						should add baseAdjustment option for base adjustments
						should addd error checking to prevent infinite loops	
						should add table naming capability
						should make table  names to a convention
						should keep track of model n's
						should empirically determine variable lengths
******************************************************************/
%macro logisticProgAdj (dsn=/*dataset name*/, 
                        outcome=/*outcome variable name (should be numeric 1/0)*/, 
                        where=1/*where considtion (default=1)*/, 
                        clusteringVars=facid/*variables for clustering in repeated statement (default=facid)*/,
                        html=0/*create html output (default=0)*/, 
                        htmlName=genmod_progAdj/*html file name (default=genmod_progAdj)*/,
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
					    fmt=8.2/*odds ration format (defulat=8.2)*/,
					    corrStructure=cs/*correlation structure for clustering (default=cs)*/,
                        verbose=1/*include all model output (default=1)*/
                        );

	%local i j adjAll;
	
  %if &htmlName. = genmod_progAdj %then %let htmlName = genmod_progAjd_&outcome.;

	*Clean up any leftover tables;
	%deleteDatasets(dsnList=gee_: orAll orn);
	%let i = 1;
	%let adjAll = &adj1.;

	*Check for titles;
	%storeTitles();
    %if &verbose. ne 1 %then ods exclude all;;
	%do %while (%length(&&adj&i) > 1);
		%printTitles();
		%titleNext(Logistic Model: progressive adjustment - outcome=&outcome.);
		%titleNextCum(Restriction(s): &where);
		%titleNextCum(Model &i);
		
		%put [&i.];


		proc genmod data=&dsn. plots=none descending;
			where &where. AND not missing(&outcome.);
			class &clusteringVars. &class.;
			model &outcome. = &adjAll.  / dist=bin link=logit;
			repeated subject=&clusteringVars. / type=&corrStructure.;  

			ods output 	GEEEmpPEst		=GEE_PEst (where = (parm ne 'Intercept'))
						NObs 			=GEE_NObs (keep = nobsRead nobsUsed label where = (label = 'Number of Observations Read')) ; *keep label only to delete rows 2 and 3;
		run;

		data gee_PEst;
			length parm $40.;
			set GEE_Pest;
			model = &i.;
			subOrder = _n_;
		run;

		*Collate datasets;
		data orAll;
			set %if &i. ne 1 %then orAll;
				gee_pEst (in=inNew);
		run;

		data nAll;
			set %if &i. ne 1 %then nAll;
				gee_nobs (in=inNew drop=label);
			if inNew then model = &i.;
		run;


/*		%deleteDatasets(dsnList=gee_:);*/

		*Increment i and cumulate adjustments;
		%let i = %eval(&i+1);
		%let adjAll = &adjAll &&adj&i;
		%printTitles();
	%end;	
    %if &verbose. ne 1 %then ods exclude none;;

	data orALL;
		set orALL;
		OR = exp(estimate);
		OR_lower = exp(lowerCL);
		OR_upper = exp(upperCL);
		CI95 = 	'(' ||
					strip(put(exp(lowerCL), &fmt.)) || 	
					'-' ||
					strip(put(exp(upperCL), &fmt.)) ||
					')';

		%if %length(&class.) > 0 %then if not missing(level1) then parm = strip(parm) || "_" || strip(level1);;
	run;

	%if &html. = 1 %then ods html style = journal file = "&htmlName..html";;
	%printTitles();
	%titleNext(Logistic Model: progressive adjustment - outcome=&outcome);
	%titleNextCum(Restriction(s): &where);
	%titleNextCum(Model results);
	
	proc report data=orAll nowd;
		column suborder parm  model , (OR OR_lower OR_upper probz CI95);
		define suborder / noprint order group;
		define model / group across;
		define parm / group;
		define OR  / MAX f=&fmt.;
		define OR_lower  / noprint MAX f=&fmt.;
		define OR_upper / noprint MAX f=&fmt.;
		
		define probz / noprint MAX f=pvalue8.3;
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
	%titleNext(Logistic Model: progressive adjustment - outcome=&outcome);
	%titleNextCum(Restriction(s): &where);
	%titleNextCum(Observations per model);
	proc sql;
		SELECT model, nobsread, nobsused, nobsread-nobsused AS nObsMiss
		FROM nAll;
	quit;
	%if &html. = 1 %then ods html close;;
%mend logisticProgAdj;