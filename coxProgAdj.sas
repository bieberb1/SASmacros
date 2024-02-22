/*****************************************************************
	Name:		CoxProgAdj
	Purpose:		Progessively adjust a cox model
	Parameters:	List of datasets
	Create Date:	January 20, 2012
	Creator:		Brian Bieber
	
	Example:		%coxProgAdj(dsn=mq, strata=country, adj1=mage vintage, adj2=mhgbgdl, adj3=malbumingdl);
	Notes:		BB130325 - added class statement - still need to tweak so output shows estimates for levels of class variable
				BB150521 - added capability to include output for a single class variable (should be enclosed in quotes)
******************************************************************/
%macro coxProgAdj (dsn = , 
					outcome=all_died_7, 
					TaR=all_patyrs_7, 
					where=1, 
					strata = phase country, 
					clusterVar=facid,
					verbose=0,
					cleanup=0,
					html=, 
					htmlName=coxProgressiveAdj_&sysdate9.,
					class=, 
					classref=,
					adj1=, 
					adj2=, 
					adj3=, 
					adj4=, 
					adj5=, 
					adj6=, 
					adj7=, 
					adj8=, 
					adj9=,
					adj10=
					);

	%local i x labelAtStart;
	*Clean up any leftover tables;
	proc datasets nolist nodetails lib=work memtype=data; delete  HRall HRfinal cox_PEst Cox_Nobs Cox_Censor modelN; run;
	%let i = 1;
	%let adjAll = &adj1;
	%let labelAtStart = %sysfunc(getoption(label));
	options nolabel; *Prevent length problems in datasets;

	*Check for titles;
	%if &verbose.=0 %then ods exclude all;;
	%storeTitles();
	%do %while (%length(&&adj&i) > 1);
		%printTitles();
		%if &ntitles. le 1 %then %do;
			%titleNext(PHREG: progressive adjustment time to &outcome);
			%titleNextCum(Restriction(s): &where);
		%end;
		%titleNextCum(Model &i);
		proc phreg data=&dsn covsandwich(aggregate);
			%if %length(&strata) > 1 %then %do; strata &strata; %end;
			id &clusterVar.;
			where &where;
			%if %length(&class.) AND %length(&classRef.) %then %do; class &class. (ref = "&classRef."); %end;
			%else %if %length(&class.) %then %do; class &class; %end;
			model &TaR*&outcome(0) = &adjAll. / ties=exact rl;

			ods output 	ParameterEstimates		=Cox_PEst 
						Nobs					=Cox_Nobs (keep = nObsRead nObsUsed)
						CensoredSummary			=Cox_Censor;
		run;
		proc sql NOPRINT; SELECT max(event) INTO :events FROM Cox_censor; quit;

		%if &i = 1 %then %do;  
			data HRall; length parameter $40.; set Cox_Pest; model=&i; order = _n_; run; 
		 	data modelN; set cox_nObs; events = &events; model=1; run;
		%end;
		%else %do; 
			data HRall; set HRall cox_PEst (in=new); if new then do; model=&i; order = &i*10+_n_; end; run; 
			data modelN; set modelN cox_nObs (in=new);  if new then do; events = &events; model=&i; end; run;
		%end;
		*Increment i and cumulate adjustments;
		%let i = %eval(&i+1);
		%let adjAll = &adjAll &&adj&i;
	%end;
	%if &verbose.=0 %then ods exclude none;;	

	proc sort data=HRall; by parameter %if %length(&class.) %then classval0; model; run;
	data HRFinal;
		set HRall;
		by parameter %if %length(&class.) %then classval0; model;
		retain 
			orderMin
			%do x=1 %to %eval(&i-1);
				HR&x 
			%end;
			%do x=1 %to %eval(&i-1);
				HRll&x
			%end;
			%do x=1 %to %eval(&i-1);
				HRul&x
			%end;
			%do x=1 %to %eval(&i-1);
				p&x
			%end;
		;
		array HR(*) HR1--HR%eval(&i-1);
		array HRll(*) HRll1--HRll%eval(&i-1);
		array HRul(*) HRul1--HRul%eval(&i-1);
		array p(*) p1--p%eval(&i-1);

		%if %length(&class.) %then %do; 
			if first.classval0 then do y=1 to %eval(&i-1);
		%end;
		%else %do;
			if first.parameter then do y=1 to %eval(&i-1);
		%end;
				HR(y) = .; HRll(y)= .; HRul(y) = .; p(y) = . ;
				orderMin = order;
			end;

		HR(model) = hazardRatio;
		HRll(model) = HRlowerCL;
		HRul(model) = HRupperCL;
		p(model) = probChisq;
	
		
		%if %length(&class.) %then %do; 
		if last.classval0;
		%end;
		%else %do; 
		if last.parameter;
		%end;

		%do x=1 %to %eval(&i-1);
			if not missing(HR&x) then HR95CI&x = strip(put(HR&x, 8.2)) || "(" || strip(put(HRll&x,8.2)) || "-" || strip(put(HRul&x,8.2)) || ")";
		%end;
		

		format p1-p%eval(&i-1) pvalue6.3;
		drop HRupperCL HRlowerCL;
		keep parameter %if %length(&class.) %then classval0; HR: p1-p%eval(&i-1) orderMin;
	run;
	proc sort data=HRall; by model order; run;
	proc sort data=HRFinal; by orderMin; run;
	

	%if &html=1 %then %do; ods html style=meadow file = "&htmlName..html";  %end;
	options nolabel;
	%printTitles();
	%if &ntitles. le 1 %then %do;
		%titleNext(PHREG: progressive adjustment time to &outcome);
		%titleNextCum(Restriction(s): &where);
	%end;
	proc tabulate data=HRall;
		class model;
		class parameter %if %length(&class.) %then classval0; /  order = data missing;
		var HazardRatio HRLowerCL HRUpperCL probChisq;
		tables parameter=''%if %length(&class.) %then *classval0='';, model*((HazardRatio='HR' HRLowerCL='HR_LCL' HRUpperCL='HR_UCL')*max=''*f=8.3 probChisq='p-value'*max=''*f=pvalue8.3);
	run;
	

	proc sql;
		SELECT model, nObsRead, nObsUsed, NObsUsed/nObsRead AS percUsed FORMAT percent8.1, events
		FROM modelN;
	quit;
	options label;
	
	proc print data=HRFinal; 
		id parameter;
		var %if %length(&class.) %then classval0; %do x=1 %to %eval(&i-1); HR95CI&x p&x %end; ;
	run;
	%if &html=1 %then %do; ods html close; %end;

	options &labelAtStart.;

	%if &cleanup. = 1 %then %do;
		proc datasets lib=work mtype=data nolist nodetails; delete HRall HRfinal cox_: modelN; run;
	%end;
%mend coxProgAdj;