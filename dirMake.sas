/******************************************************************************************************
	Name:			dirMake
	Purpose:		Create a new folder without using x commands
	Parameters:		folder = name of new folder
					parentDir = parent directory (&path. from %getThePath used by default)
	Create Date:	July 8, 2022 
	Creator:		Brian Bieber
	
	Example:		%getThePath();	
					%dirMake(_DELETEme);
	Dependencies:	%getThePath - by default uses &path for parentDir
					%dirExist - used to check if directory already exists 
	Notes:			https://support.sas.com/content/dam/SAS/support/en/sas-global-forum-proceedings/2018/2489-2018.pdf
********************************************************************************************************/
/*
options dlcreatedir;
libname temp "U:\DOPPS\work\BrianB\Code Library\Macro library\_DELETEme";

data _null_;
	new_directory = dcreate("_DELETEme", "U:\DOPPS\work\BrianB\Code Library\Macro library\");
run;
*/

%macro dirMake(folder, parentDir);
	*Check to see if %dirExist has been defined;
/*	%if %sysmacexist(dirExist) = 0 %then %do;*/
/*		Err0r: %dirMake is dependent on %dirExist which has not been loaded.*/
/*		%goto quit;*/
/*	%end;*/
	*Use global macro variable &path if defined;
	%if %length(&parentDir)=0 %then %do;
		%if %symexist(path)	%then %let parentDir=&path.;
		%else %do;
			%put parentDir not defined. Run %getThePath() or define directly;
/*			%goto quit;*/
		%end;
	%end;

	*Check if directory exists. If not, create it;
	%if %dirExist(&parentDir.\&Folder.) %then %do;
		%put NOTE: [&parentDir.\&Folder.] already exists;
	%end;
	%else %do;
		data _null_;
			new_directory = dcreate("&folder.", "&parentDir.\");
		run;
		%put NOTE: [&parentDir.\&folder.] created;
	%end;
	%put [&parentDir.];
/*	%quit:*/
%mend;



