/*****************************************************************
	Name:		storeTitles
	Purpose:		Stores up to ten pre-existing titles in &mTitle[N]. where N=1..10 
	Parameters:	None
	Create Date:	August 28, 2013
	Creator:		Brian Bieber
	
	Example:		
	Notes:		variables &nTitles. and &mTitle[N]. are global so they can be called by %printTitles;
******************************************************************/
%macro storeTitles();
	%global mTitle1 mTitle2 mTitle3 mTitle4 mTitle5 mTitle6 mTitle7 mTitle8 mTitle9 mTitle10 nTitles;
	%let nTitles = 0;
	%do g = 1 %to 10; %let mTitle&g. = ;%end;
	proc sql NOPRINT;
		SELECT sum(type='T') INTO :nTitles FROM dictionary.titles; 
		%if &nTitles. > 0 %then %do g = 1 %to &nTitles.;

		SELECT compress(text, '"') INTO :mTitle&g. FROM dictionary.titles WHERE number = &g.;
		%end;
	quit;
%mend storeTitles;
