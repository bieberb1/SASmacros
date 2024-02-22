/*****************************************************************
	Name:		missCode
	Purpose:	create variables with m_ prefix, set to 1 if missing
	Parameters:	varlist = [list of variables]
	Create Date:	February 27, 2014 (updated)
	Creator:		Brian Bieber
	
	Example:		
	Notes:		Used by %missingTable
*******************************************************************/

%macro missCode(varlist);
	%local i;
	%do i = 1 %to %sysfunc(countw(&varlist., %str( )));
		%let currVar = %scan(&varlist., &i.);
		m_&currVar. = missing(&currVar.);
	%end;
%mend missCode;
