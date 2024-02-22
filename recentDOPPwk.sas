/*****************************************************************
	Name:		recentDOPPwk
	Purpose:		Grab the most recently created file with similar basenames
	Parameters:	[baseName]
	Create Date:	July 31, 2015
	Creator:		Brian Bieber
	
	Example:		%recentDOPPWK(MEDSQPRI12345);
		
	Notes:		Creates global macro &doppwkDSN.	
				Need to error trap this and clear the variable if nothing found									
******************************************************************/
%macro recentDOPPWk(baseName/*dataset prefix to search DOPPwk folder for*/);
	%global doppwkDSN;
	title "Most recent DOPPwk file with basename = &baseName.";
	proc sql NOPRINT;
		SELECT memname INTO :doppwkDSN
		FROM dictionary.tables
		WHERE libname = 'DOPPWK' AND memname LIKE "%upcase(&baseName.)%"
		HAVING modate = max(modate);
	quit;
	title;
	%if &doppwkDSN. = %then %put No dataset starting with &baseName. found in DOPPwk.;
	%else %put Most recent dataset with [&baseName.] = DOPPwk.&doppwkDSN. saved in doppwkDSN macro variable;
%mend recentDOPPWk;