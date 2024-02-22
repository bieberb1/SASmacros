/************************************************************************************************************************************
	Title:			formatLocation macro
	---------------------------------------------------------------------------------------------------------
	Purpose: 		Print out location of current format libraries specified by fmtsearch
	---------------------------------------------------------------------------------------------------------
	Derived From:   https://www.9to5sas.com/sas-pathname/
	Input Data:          
	---------------------------------------------------------------------------------------------------------
	Revisions (date, nature, name):
*************************************************************************************************************************************/

%macro formatLocation();
	%let fmtlibs= %sysfunc(translate(%sysfunc(getoption(fmtsearch)),%str( ),%str(%( %))));

	Data test(keep=libnames path);
	liblist=symget('fmtlibs');

	do i=1 to countw(liblist);
	libnames=compress(scan(liblist,i,' '));
	path=pathname(libnames);
	output;
	end;
	run;
%mend formatLocation;