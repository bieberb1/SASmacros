/*****************************************************************
	Name:		footnoteNext
	Purpose:		Create a footnote in the next available slot
				Designed for macros the footnote outside of the macro doesn't get overwritten
	Parameters:	Desired footnote text
	Create Date:	July 22, 2013
	Creator:		Brian Bieber
	
	Example:		%titleNext(This is the next title);
	Notes:		
******************************************************************/
%macro footnoteNext(text);
	proc sql NOPRINT;
		SELECT sum(type='F') INTO :nfootnotes FROM dictionary.footnotes; 
	quit;
	%if &nfootnotes. = . %then %let nfootnotes = 0;
	%let nfootnotesNext = %eval(&nfootnotes. + 1);
	footnote&nfootnotesNext. "&text.";
%mend;
