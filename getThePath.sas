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
					BB230215 - modified to work with SAS EG project and adapt pathSvr to different drives
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
			/*Saved program file*/
			%if %symexist(_SASprogramFile) AND %length(&_SASprogramFile.) > 2 %then %do;
				%let pathFile = %sysfunc(compress(&_SASprogramFile., "'"));
				%let file = %qscan(&pathFile., -1, \);
			%end;
			/*File embedded in SAS EG proejct*/
			%else %if %symexist(_clientProjectPath) %then %do;
				%let pathFile = %sysfunc(compress(&_clientProjectPath., "'"));
				%let file = %qscan(&pathFile., -1, \);
			%end;
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

	%if 		%substr(&path., 1, 1) = U %then
		%let pathSvr = \\urrea.local\dopps%substr(&path., 3, %length(&path.)-2);
	%else %if 	%substr(&path., 1, 1) = S %then
		%let pathSvr = \\NAS02\share%substr(&path., 3, %length(&path.)-2);
	%else %if 	%substr(&path., 1, 1) = Q %then
		%let pathSvr = \\urrea.local\arbor%substr(&path., 3, %length(&path.)-2);
	%else %if 	%substr(&path., 1, 1) = M %then
		%let pathSvr = \\data06\dopps%substr(&path., 3, %length(&path.)-2);


	*Print global macro variables to log;
	%put pathFile [&pathFile.];
	%put file [&file.];
	%put path [&path.];
	%put pathSvr: [&pathsvr.];
%mend getThePath;
