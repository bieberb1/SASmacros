/*****************************************************************
	Name:			changeDir
	Purpose:		Change working directory to location of current file
	Parameters:		suff = changes working directory to a subfolder, creates this folder if it doesn't exist
	Create Date:	August 23, 2012
	Creator:		Brian Bieber
	
	Example:		%changeDir(suff=TestFolder);
	Notes:			Calls %getThePath()
					150403 update - simplified - now works on BJS
******************************************************************/

%macro changeDir(suff=/*subfolder name - will be created if it doesn't exist*/);
	%getThePath();
	options noxwait xsync;
	%if %length(&suff.) > 0 %then %do;
		x md "&path.\&suff."; *Ensure folder is available;
	%end;
	x cd "&path.\&suff.";
	options noxwait;
%mend changeDir;
