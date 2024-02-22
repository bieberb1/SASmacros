/*****************************************************************
	Name:		vType
	Purpose:		Determine type of variable and populate &vType. with C or N
	Parameters:	[data] = dataset
				[variable] = variable for which you want the type 
	Output:		N or C depending on numeric or character variable 
	Create Date:	October 10, 2013
	Creator:		Brian Bieber
	
	Example:		
	Notes:		Only give character (C) or numeric (N)
******************************************************************/
%macro vType(data,variable);
	%let dsid=%sysfunc(open(&data.,i));
	%if &dsid. ne 0 %then %do;
		%let varN = %sysfunc(varnum(&dsid., &variable.));
		%if &varN. ne 0 %then %do;
			%let vType = %sysfunc(varType(&dsid., &varN.));
			%let rc=%sysfunc(close(&dsid));
		%end;
		%else %put Unable to access [&variable] in [&data.] - %sysfunc(sysmsg());
	%end;
	%else %put Unable to open &data. - %sysfunc(sysmsg());
	&vType.
%mend vType;