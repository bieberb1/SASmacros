

%macro makeDir(folder, parentDir);
	*Use global macro variable &path if defined;
	%if %length(&path) = 0 %then do;
		%if %symexist(path) %let parentDir=&path.;
		%else %do;
			%put parentDir not defined. Run %getThePath() or define directly;
			%goTo quit;
		%end;
	%end;

	*Check if directory exists. If not, create it;
	%if %dirExist(&parentDir.\&Folder.) %then %put NOTE: [&parentDir.\&Folder.] already exists;
	%else %do;
		data _null_;
			new_directory = dcreate("&folder.", "&parentDir.\");
		run;
		%put NOTE: [&parentDir.\&Folder.] created;
	%end;
	%quit;
%mend;


