/*****************************************************************
	Name:		m_toFrom_q
	Purpose:		rename m to q or q to m variables
	Parameters:	varlist = [list of variables that you want to change the prefix]
				newPrefix = [prefix to replace with]
				oldPefix = [prefix that needs to be replaced] - if this is blank, the macro will just add the new prefix
	Create Date:	February 22, 2013 (updated)
	Creator:		Brian Bieber
	
	Example:		
	Notes:		2012/10/10 Took out variable names out of dataset and variable specifications to avoid length problems
******************************************************************/


%macro m_toFrom_q (varlist = , newPrefix = q , oldPrefix = m);
	%do i = 1 %to %sysfunc(countw(&varlist., %str( )));
		rename %scan(&varlist., &i.) = &newPrefix.%SUBSTR(%scan(&varlist., &i.),%if &oldPrefix. = %then 1; %else 2;);
	%end;
%mend m_toFrom_q;