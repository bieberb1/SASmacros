/*****************************************************************
	Name:			kill
	Purpose:		Delete all datasets in a folder
	Parameters:		lib=library where datasets reside
	Create Date:	August 3, 2022
	Creator:		Brian Bieber
	
	Example:		%kill();
	Notes:
******************************************************************/

%macro kill(lib=WORK /*library, default=WORK*/);
	proc datasets lib=&lib. kill nolist; quit;
%mend;

