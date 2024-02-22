/*****************************************************************
	Name:		recordCount
	Purpose:		Determine number of records in dataset
	Parameters:	[dsn] = dataset
	Output: 		Number of records in dataset
	Create Date:	October 10, 2013
	Creator:		SAS website
	
	Example:		
	Notes:		http://sascommunity.org/wiki/Determining_the_number_of_observations_in_a_SAS_data_set_efficiently
				This can be called anywhere in a program since it is a completely macro version
******************************************************************/
%macro recordCount(dsn);
	%local nobs dsnid;
	%let nobs=.;
	 
	/* Open the data set of interest*/
	%let dsnid = %sysfunc(open(&dsn.));
	 
	/*If the open was successful get the number of observations and CLOSE &dsn*/
	%if &dsnid. %then %do;
	     %let nobs=%sysfunc(attrn(&dsnid.,nlobs));
	     %let rc  =%sysfunc(close(&dsnid.));
	%end;
	%else %do;
	     %put Unable to open &dsn. - %sysfunc(sysmsg());
	%end;
	 
	/*Return the number of observations*/
	&nobs.
%mend recordCount;