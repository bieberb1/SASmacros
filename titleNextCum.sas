/*****************************************************************
	Name:		titleNextCum
	Purpose:		Create a title in the next available slot
				This includes titles defined after %storeTitles called
				Designed for macros the title outside of the macro doesn't get overwritten
	Parameters:	Desired title text
	Create Date:	July 22, 2013
	Creator:		Brian Bieber
	
	Example:		%titleNext(This is the next title);
	Notes:		
******************************************************************/
%macro titleNextCum(text);
	proc sql NOPRINT;
		SELECT sum(type='T') INTO :nTitlesCum FROM dictionary.titles; 
	quit;
	%if &nTitlesCum. = . %then %let nTitlesCum = 0;
	%let nTitlesNext = %eval(&nTitlesCum. + 1);
	title&nTitlesNext. "%BQUOTE(&text.)";
%mend;
