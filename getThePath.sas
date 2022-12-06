/******************************************************************************************************
	Name:			getThePath
	Purpose:		Acquire path and file name for current file
	Parameters:		none
	Create Date:	August 23, 2012
	Creator:		Brian Bieber
	
	Example:		%getThePath();
	Notes:			Called by %changeDir to change working directory to location where current file lives
					BB120910 - modified to work for batch submission
					BB181120 - modified to not interfere with IVEware macro of same name
					BB220708 - modified to work with SAS Enterprise Guide
********************************************************************************************************/

%macro getThePath();
	%global 
		pathFile 
		file 
		path 
		pathSvr
	;
	
	/*SAS Enterprise Guide*/
	%if %symexist(_clientApp) %then %do;
		%if &_clientApp. = 'SAS Enterprise Guide' %then %do;
			%let pathFile = %sysfunc(compress(&_SASprogramFile., "'"));
			%let file = %qscan(&pathFile., -1, \);
		%end;
		%else %put _clientApp = [&_clientApp.]. getThePath not programmed yet.;
	%end;
	/*Base SAS*/
	%else %do;
		/*Enhanced editor*/
		%if %length(%sysfunc(getoption(SysIn))) = 0 %then %do;
			%let pathFile = %sysget(SAS_EXECFILEPATH);
			%let file = %sysget(SAS_EXECFILENAME);
		%end;
		/*Batch submission*/
		%else %do;
			%let pathFile = %sysfunc(getoption(SysIn));
			%let file = %scan(%sysfunc(getoption(SysIn)), -1,\);
		%end;
	%end;

	%let path = %substr(&pathFile., 1, %index(&pathFile., &file.)-2);
	%let pathSvr = \\urrea.local\dopps%substr(&path., 3, %length(&path.)-2);
		*Specific to U:\DOPPS. Should probably be changed;

	*Print global macro variables to log;
	%put pathFile [&pathFile.];
	%put file [&file.];
	%put path [&path.];
	%put pathSvr: [&pathsvr.];
%mend getThePath;
