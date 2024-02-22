/*****************************************************************
	Name:		printTitles
	Purpose:		print the titles that were stored in &mTitle[N]. by %storeTitles;
	Parameters:	None
	Create Date:	August 28, 2013
	Creator:		Brian Bieber
	
	Example:		
	Notes:		variables &nTitles. and &mTitle[N]. are global so they can be called by %printTitles;
******************************************************************/
%macro printTitles();
	%if &nTitles. > 0 %then %do g = 1 %to &nTitles.;
		title&g. "%trim(%QUOTE(&&mTitle&g.))"; 
	%end;
%mend;