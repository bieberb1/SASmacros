/*****************************************************************
	Name:		boxplot_AR
	Purpose:		Create patient and facility boxplots with 5th and 95th percentiles as whiskers
				Sort as needed
				Output html/table as needed
	Parameters:	data 		= [dataset name]
				varlist 		= [list of y-axis variables for which a boxplot for each will be made]
				classlist 	= [list of x-axis variables for which a boxplot for each will be made]
				where		= [restriction list]
				pat			= [1 requests creation of patient-level boxplot]
				fac			= [1 requests creation of facility-level boxplot]
				min_fac_pat	= [# of patients with non-missing data for variable of interest necessary for facility to be included in facility boxplot]
				yaxislabel	= [label for the y-axis]
				group		= [boxplot fill will change based on this variable]
				sort			= [sort order, ASCENDING->sort by ascending mean or median, DESCENDING->sort by descending mean or median, ALPHABETICAL->sort by alphabetical class variable]
				table		= [output table with graph statistics]
				fac_stat		= [specify what facility-level value (mean or median) to graph in facility plot]
				html			= [1 requests html output]
				format		= [specify format for statistics]
				weight		= [variable to weight results by]
				lowerPercentile = [percentile for lower whisker]
				upperPercentile = [percentile for upper whisker]
				htmlStyle		 = [Style for html output, default=myStyle created above]
				showOutliers	= [1 requests to show outliers - > 95th percentile or < 5th percentile]
	Create Date:	
	Creator:		Brian Bieber
	
	Example:		*%boxplot_AR (data = dopps4.m_f, varlist = malbumingdl mhgbgdl, classlist = country, sort = DESC, table = 1, 
							fac_stat = median, where=country ne 'Japan', html = 1);
	Notes:		BB140502 - moved class variable from id to class statement in proc summary for facility boxplots
				BB140709 - added capability to include grouping variable to determine color
				BB140710 - turned html on by default, closed the listing destination - should probably dynamically determine listing 
				BB140909 - added capability to show outliers with showOutilers =  and removing "extreme=FALSE" in template
				BB190304 - added automatic label for facility outliers
******************************************************************/

%macro boxplot_AR (data = , varlist = , classlist = , where = 1, pat = 1, fac = 1, min_fac_pat = 5, yaxislabel = &var., group=, showOutliers = ,
				sort = ASCENDING, table = 0, fac_stat = MEAN, html = 1, format = 8.1, weight= , lowerPercentile=5, upperPercentile=95, htmlStyle=myStyle, imageName=&var.);
 %local ibox ybox TitleTxt title_flag fac_title_text;
 proc sql NOPRINT; SELECT sum(type='T' AND number = 1) INTO :title_flag FROM dictionary.titles; quit;
 %if &title_flag. = 1 %then %do;
	proc sql NOPRINT; SELECT text INTO :TitleTxt FROM dictionary.titles WHERE type='T' AND number = 1; quit;
 %end;
 options nolabel;
/* %if &html. = 1 %then ods listing close;;*/
 %do ibox = 1 %to %sysfunc(countw(&varlist., %str( )));
   %let var = %scan(&varlist., &ibox.); 
   %do ybox = 1 %to %sysfunc(countw(&classlist., %str( )));
    %let class = %scan(&classlist., &ybox.);
	%deleteDatasets(dsnList=stats_pat: stats_fac: boxstats_: tab_: outlier:);

	*Patient boxplot;
	%if &pat = 1 AND %vType(data=&data., variable=&var.) = N %then %do;
		proc summary data=&data NWAY;
			where &where AND not missing(&var.);
			%if &weight ne %then weight &weight.;;
			format &var.; *Ensure formatting is stripped;
			class &class;
			%if &group. ne %then id &group.;;
			output out = stats_pat (drop = _TYPE_ _FREQ_)
				n(&var)		= n
				mean(&var) 	= avg
				std(&var)	= STD
				p&lowerPercentile. (&var)	= p&lowerPercentile.
				p25(&var)	= p25
				p50(&var)	= p50
				p75(&var)	= p75
				p&upperPercentile.(&var)	= p&upperPercentile.;
		run;

		%if %recordCount(stats_pat) > 0 %then %do;
		data stats_pat;  
			set stats_pat;
			mean		= trim(left(put(round((avg),.01),&format.)));
			SD		= trim(left(put(round((std),.01),&format.)));
			median	= trim(left(put(round((p50),.01),&format.)));
			mean_Sd	= trim(left(put(round((avg),.1),&format.)))||' ('||trim(left(put(round((std),.1),&format.)))||')';
		run;

		proc transpose data=stats_pat (keep= &class p&lowerPercentile. p25 p50 p75 p&upperPercentile. avg %if &group. ne %then &group.;)
			out=boxstats_pat(rename=(col1=Yvalue));
			by &class %if &group. ne %then &group.;;
			var p&lowerPercentile. p25 p50 p75 p&upperPercentile.  avg;
		run;

		%if &showOutliers. = 1 %then %do;
			proc sort data=&data. out=outlierBase (where=(&where.)); by &class. %if &group. ne %then &group.;; run;

			data outliers (keep = &class. sstat yvalue mergeval %if &group. ne %then &group.;);
				merge 	outlierBase
						stats_pat (keep = &class. p&lowerPercentile. p&upperPercentile.);
				by &class.;

				if not missing(&var.) AND (&var. > p&upperPercentile.  OR &var. < p&lowerPercentile.) then do;
					mergeval = 99;
					sstat='OUTLIER';
					yvalue = &var.;
					output;
				end;
			run;
		%end;

		data boxstats_pat; 
			length sstat $12.;
			set boxstats_pat(where=(not missing(Yvalue)))
				%if &showOutliers. = 1 %then outliers;; 
			by &class.;  

				 if _NAME_="p&lowerPercentile."  then do; sstat='MIN'; 	mergeval=1; end;
			else if _NAME_="p25" then do; sstat='Q1'; 	mergeval=2; end;
			else if _NAME_="p50" then do; sstat='MEDIAN'; mergeval=3; end;
			else if _NAME_="avg" then do; sstat='MEAN'; 	mergeval=4; end;
			else if _NAME_="p75" then do; sstat='Q3'; 	mergeval=5; end;
			else if _NAME_="p&upperPercentile." then do; sstat='MAX';  	mergeval=6; end;
		run;
		proc sort data=boxstats_pat; by &class mergeval; run;

		data tab_pat; 
			set stats_pat;
			by &class;
			
			length  nTable stat StatName $15;
			nTable=left(put(n,comma8.));  
			label  	nTable		="N"  
					mean	="Mean" 
					sd	="Std Dev" 
					median="Median"; 

			array sname{4} nTable  mean sd median;
			do i=1 to dim(sname);
				mergeval=i;
				StatName=vlabel(sname{i});
				Stat=left(sname{i});
				output; 
			end;  
			keep &class StatName Stat p&upperPercentile. mergeval;
		run;
		data boxstats_pat; 
			merge 	tab_pat(where=(not missing(p&upperPercentile.))) 
					boxstats_pat; 
			by &class mergeval; 
			format YValue &format.;  
		run;

		*Sort as requested;
		%if %index(%upcase(&sort), ALPH) < 1 %then %do;
			data boxstats_pat; merge boxstats_pat stats_pat (keep = &class avg); by &class; run;
			%if %index(%upcase(&sort), DES) gt 0 %then %do;
				proc sort data=boxstats_pat; by DESCENDING avg &class; run;
			%end;
			%else %do;
				proc sort data=boxstats_pat; by  avg &class; run;
			%end;
		%end; 

		*set the max for the boxplot graph;
		proc sql noprint;	
			%if &showOutliers. ne 1  %then select max(p&upperPercentile.) into :maxYaxis from	stats_pat;;
			%if &showOutliers. =  1 %then select max(yvalue) into :maxYaxis from	boxstats_pat;; 
		quit; 

		*Table;
		%if &title_flag. ne 1 %then %let titleTxt = Pt Dist: &var by &class;
		title font=arial height=4 justify=left "&titleTxt.";
		%if %length(&where) gt 1 AND &title_flag. ne 1 %then %do; title2 font=arial height=2 justify=left "Restriction: [%QUOTE(&where.)]"; %end;
		%if &html = 1 %then %do; ods html file="&imageName._&class._PAT.html" (title="PAT_&class.") style=&htmlStyle.; %end;
		%if &Table = 1 %then %do;
			proc sql;
				SELECT 	&class, p&lowerPercentile. label='' AS p&lowerPercentile., p25 label='' AS p25, p50 label='' AS p50, 
						p75 label='' AS p75, p&upperPercentile. label='' AS p&upperPercentile., avg label='' AS mean, n label='' AS n_pat
				FROM stats_pat
				ORDER BY 		  %if %index(%upcase(&sort), DES) gt 0 %then %do; p50 DESCENDING, avg DESCENDING %end;
							%else %if %index(%upcase(&sort), ASC) gt 0 %then %do; p50 ASCENDING, avg ASCENDING %end;
							%else %if %index(%upcase(&sort), ALP) gt 0 %then %do; &class %end; ;
			quit;
		%end;

		*Boxplot;
		ods graphics /imagename="&imageName._pat_boxplot";
		proc sgrender data=boxstats_pat template=bygroupbox;
	  		dynamic xvar="&class" yvar="Yvalue" svar= "sstat" %if &group. ne %then GVAR="&group.";  ylabel="&yaxislabel" vmax=&maxYaxis.; 
	    run;
		%if &html = 1 %then %do; ods html close; %end;
		%end;	*recordCount > 0;
		title;
	%end;


	*Facility Boxplot;
	%if &fac.=1 AND %vType(data=&data., variable=&var.) = N %then %do;
		proc summary data=&data NWAY;
			where &where AND not missing(&var.);
			class &class. facid;
			%if &group. ne %then id &group.;;
			format &var.; *Ensure formatting is stripped;
			output out = stats_fac_temp (drop = _FREQ_ _TYPE_ where = (n ge &min_fac_pat))
				mean(&var) = avg
				median(&var) = p50
				n(&var) = n;
		run;
		
		%if %recordCount(stats_fac_temp) > 0 %then %do;

			  %if %index(%upcase(&fac_stat),MEAN) gt 0 %then %let fac_stat_varname = avg;
		%else %if %index(%upcase(&fac_stat),MED)  gt 0 %then %let fac_stat_varname = p50;

		proc summary data=stats_fac_temp NWAY;
			class &class;
			%if &group. ne %then id &group.;;
			output out = stats_fac_temp2 (drop = _FREQ_ _TYPE_)
				n(facid)				= n_Fac_numeric
				sum(n)					= n_pat_numeric
				mean(&fac_stat_varname) = facavg
				p&lowerPercentile. (&fac_stat_varname)	= p_facavg&lowerPercentile.
				p25(&fac_stat_varname)	= p_facavg25
				p50(&fac_stat_varname)	= p_facavg50
				p75(&fac_stat_varname)	= p_facavg75
				p&upperPercentile.(&fac_stat_varname)	= p_facavg&upperPercentile.;
		run;	


		%if &showOutliers. = 1 %then %do;
			data outliers_fac (keep = &class. facid sstat yvalue mergeval %if &group. ne %then &group.;);
				merge 	stats_fac_temp
						stats_fac_temp2 (keep = &class. p_facavg&lowerPercentile. p_facavg&upperPercentile.);
				by &class.;

				if not missing(&fac_stat_varname.) AND (&fac_stat_varname. > p_facavg&upperPercentile.  OR &fac_stat_varname. < p_facavg&lowerPercentile.) then do;
					mergeval = 99;
					sstat='OUTLIER';
					yvalue = &fac_stat_varname.;
					output;
				end;
			run;
		%end;

		data stats_fac;  
			set stats_fac_temp2;
			Q1_facavg		= strip(put(round((p_facavg25),.001),&format.));
			median_facavg	= strip(put(round((p_facavg50),.001),&format.));
			Q3_facavg		= strip(put(round((p_facavg75),.001),&format.));
			n_Pat			= strip(put(round((n_Pat_numeric),1),8.0));
			n_Fac			= strip(put(round((n_Fac_numeric),1),8.0));
		run;

		proc transpose data=stats_fac (keep= &class p_facavg&lowerPercentile p_facavg25 p_facavg50 p_facavg75 p_facavg&upperPercentile facavg %if &group. ne %then &group.;)
			out=boxstats_fac(rename=(col1=Yvalue));
			by &class %if &group. ne %then &group.;;
			var p_facavg&lowerPercentile. p_facavg25 p_facavg50 p_facavg75 p_facavg&upperPercentile. facavg;
		run;

		data boxstats_fac; 
			length sstat $12.;  
			set boxstats_fac(where=(not missing(Yvalue)))
				%if &showOutliers. = 1 %then outliers_fac;; 
			by &class.;
			

				 if _NAME_="p_facavg&lowerPercentile."  then do; 	sstat='MIN'; 	mergeval=1; end;
			else if _NAME_="p_facavg25" then do; 					sstat='Q1'; 	mergeval=2; end;
			else if _NAME_="p_facavg50" then do; 					sstat='MEDIAN';	mergeval=3; end;
			else if _NAME_="facavg" then do; 						sstat='MEAN';	mergeval=4; end;
			else if _NAME_="p_facavg75" then do; 					sstat='Q3'; 	mergeval=5; end;
			else if _NAME_="p_facavg&upperPercentile." then do; 	sstat='MAX'; 	mergeval=6; end;
		run;
		proc sort data=boxstats_fac; by &class mergeval; run;	

		data tab_fac; 
			set stats_fac;
			length  stat StatName $15; 
			label  	n_pat				="N Pat."  
					n_fac				="N Fac."
					Q1_facavg		="Q1" 
					median_facavg	="Median"
					Q3_facavg		="Q3" ; 

			array sname{5} n_fac n_pat Q1_facavg median_facavg Q3_facavg;
			do i=1 to dim(sname);
				mergeval=i;
				StatName=vlabel(sname{i});
				Stat=left(sname{i});
				output; 
			end;  
			keep &class facavg StatName Stat p_facavg&upperPercentile. mergeval;
		run;
		data boxstats_fac; merge tab_fac(where=(not missing(facavg))) boxstats_fac; by &class mergeval; format YValue &format.;  run;

		*Sort as requested;
		%if %index(%upcase(&sort), ALPH) eq 0 %then %do;
			data boxstats_fac; 
				merge boxstats_fac stats_fac (keep = &class facavg); 
				by &class.; 
				retain facAvg_retain;
				if first.&class. then facAvg_retain = facAvg;

				if missing(facavg) then facavg = facAvg_retain;  /*BB120416 - added for ascending sort (> 5 elements, missing sorted to top)*/
				drop facAvg_retain;
			run;
			%if %index(%upcase(&sort), DES) gt 0 %then %do;
				proc sort data=boxstats_fac; by DESCENDING facavg &class; run;
			%end;
			%else %do;
				proc sort data=boxstats_fac; by  facavg &class; run;
			%end;
		%end; 

		*set the max for the boxplot graph;
		proc sql noprint;	
			%if &showOutliers. =  %then select max(p_facavg&upperPercentile.) into :maxYaxis from	stats_fac; 
			%if &showOutliers. = 1 %then select max(yvalue) into :maxYaxis from	boxstats_fac; 
		quit; 


		*Table;
		%if %index(%upcase(&fac_stat), MED) gt 0 %then %let fac_title_text = median;
		/*%put title_flag [&title_flag.], titleTxt [&titleTxt.];*/
		%if &title_flag. ne 1 %then %let titleTxt = Fac Dist: &var. &fac_title_text. by &class; 
		title font=arial height=4 justify=left "&titleTxt.";
		%if %length(&where) gt 1 AND &title_flag. ne 1 %then %do; title2 font=arial height=2 justify=left "Restriction: [%quote(&where.)]"; %end;
		footnote2 font=arial height=1.8 justify=left italic "Facilities with at least &min_fac_pat patients with &var data";

		%if &html = 1 %then %do; ods html file="&imageName._&class._FAC.html" (title="Fac_&class.") style=&htmlStyle.; %end;
		%let fac_title_text = mean;
		%if &Table = 1 %then %do;
			proc sql;
				SELECT 	&class, 
						p_facavg&lowerPercentile. label='' AS p&lowerPercentile., p_facavg25 label='' AS p25, p_facavg50 label='' AS p50, 
						p_facavg75 label='' AS p75, p_facavg&upperPercentile. label='' AS p&upperPercentile., facavg AS mean,
						n_Pat label='' AS n_Pat, n_Fac label='' AS n_Fac
				FROM stats_fac
				ORDER BY 		  %if %index(%upcase(&sort), DES) gt 0 %then %do; p_facavg50 DESCENDING %end;
							%else %if %index(%upcase(&sort), ASC) gt 0 %then %do; p_facavg50 ASCENDING %end;
							%else %if %index(%upcase(&sort), ALP) gt 0 %then %do; &class ASCENDING %end; ;
			quit;
		%end;

		%let yaxislabel_type = mean;
		%if %index(%upcase(&fac_stat), MED) gt 0 %then %let yaxislabel_type = median;
		%if %index(%upcase(&format), PERCENT) %then %let yaxislabel_type = % of pts;
		ods graphics /imagename="&imageName._fac_boxplot";
		*Boxplot;
		proc sgrender data=boxstats_fac template=bygroupbox;
	  		dynamic xvar="&class" yvar="Yvalue" svar= "sstat" %if &group. ne %then gvar="&group."; ylabel="Facility &yaxislabel_type. &yaxislabel." vmax=&maxYaxis.; 
	    run;
		%if &html = 1 %then %do; ods html close; %end;
		%end;	*If recordCount > 0;
		title; footnote;
	%end;	
  %end;
 %end;
 options label;
/* %if &html. = 1 %then ods listing;;*/
%mend boxplot_AR;