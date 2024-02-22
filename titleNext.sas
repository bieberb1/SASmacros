/*****************************************************************
	Name:		titleNext
	Purpose:		Create a title in the next available slot based on the &nTitles (set in %storeTitles) 
				This excludes titles defined after %storeTitles called
				Designed for macros so the title outside of the macro doesn't get overwritten
	Parameters:	Desired title text
	Create Date:	July 22, 2013
	Creator:		Brian Bieber
	
	Example:		%titleNext(This is the next title);
	Notes:		
******************************************************************/
%macro titleNext(text);
	%if &nTitles. = . %then %let nTitles = 0;
	%let nTitlesNext = %eval(&nTitles. + 1);
	title&nTitlesNext. "%BQUOTE(&text.)";
%mend;
