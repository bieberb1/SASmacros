/************************************************************************************************************
	Title:	Load macro functions
	---------------------------------------------------------------------------------------------------------
	Purpose:	Load macro functions from their source files. Before loading each macro, %requireMacros
				checks if a macro of the same name already exists, and if so it does not load the macro. If
				the name does not exist, then %requireMacros loads it from source, and then finally checks
				that the macro exists.

				This macro is useful for loading any dependencies within your own custom macro, because they
				will only be loaded the first time your macro is called.

				%requireMacros creates a global macro variable named macroNotFound and sets it equal to the
				number of requested macro functions that could not be loaded (i.e., the number of err0rs).
				(Exception: if you specify an invalid path, then macroNotFound is set to -1.) Thus, after
				calling %requireMacros, you can check if any macro failed to load by writing
					%if &macroNotFound %then...
				This condition will be met unless all macros are successfully loaded.
	---------------------------------------------------------------------------------------------------------
	Parameters: 
		macro1, macro2, etc.	The name of a macro (without the %), followed optionally by a space and then
				its physical file name (with or without quotes), e.g., myMacro "myMacro.sas". If the file is
				not specified, it is assumed to have the same name as the macro, followed by ".sas". If the
				file name does not include a path, it is assumed to be the current directory unless you set
				the PATH parameter.
		path	The path/directory where all the source files live.
	---------------------------------------------------------------------------------------------------------
	Path and Name:  U:\DOPPS\work\Daniel Scratch\Macros\requireMacros.sas
	Created Date:   March 6, 2018
	Created By:     Daniel Muenz
*************************************************************************************************************/

%macro requireMacros(macro1, macro2, macro3, macro4, macro5, macro6, macro7, macro8, macro9, macro10,
	macro11, macro12, macro13, macro14, macro15, macro16, macro17, macro18, macro19, macro20, path=);
%global macroNotFound;
%let macroNotFound = 0;

%* if PATH is specified, make sure it exists and ends in a slash;
%if %sysevalf(%superq(path)^=,boolean) %then %do;
	%let path = %qsysfunc(prxchange(s{^(?:'(.*)'|"(.*)")$}{\1\2}, 1, &path));

	%local sep;
	%if &sysSCP ne WIN or %index(&path, /) %then %let sep = /;
	%else %let sep = \;
	%if %qsubstr(&path,%length(&path),1) ne &sep %then %let path = &path&sep;

	%if not %sysfunc(fileExist(&path)) %then %do;
		%put ER%str(ROR): The specified PATH does not exist. No macros will be loaded.;
		%let macroNotFound = -1;
		%return;
	%end;
%end;

%* loop through each of the macroX parameters;
%local i macro source;
%let i = 1;
%do %while(%symlocal(macro&i));
	%if %sysevalf(%superq(macro&i)=,boolean) %then %goto next;

	%* get the macro name;
	%let macro = %sysfunc(prxchange(s{^\s*(\w+).*$}{\1}, 1, &&macro&i));
	%if not %sysfunc(prxmatch({^\w+$}, &macro)) %then %do;
		%put ER%str(ROR): Argument &i to macro REQUIREMACROS is invalid. It should be a macro name;
		%put ER%str(ROR)- followed optionally by its source file.;
		%let macroNotFound = %eval(&macroNotFound + 1);
		%goto next;
	%end;

	%* if the macro already exists, move on to the next macro;
	%if %sysMacExist(&macro) %then %goto next;

	%* get the macro source file and %include it;
	%let source = %qsysfunc(prxchange(s{^\s*&macro\s*}{}, 1, &&macro&i));
	%if %sysevalf(%superq(source)=,boolean) %then %let source = &macro..sas;
	%else %let source = %qsysfunc(prxchange(s{^(?:'(.*)'|"(.*)")$}{\1\2}, 1, &source));
	%let source = &path&source;

	%include "&source";

	%* now check again if the macro exists;
	%if %sysMacExist(&macro) %then %do;
		%put NOTE: The macro %upcase(&macro) was loaded from &source.;
	%end;
	%else %do;
		%put ER%str(ROR): The macro %upcase(&macro) could not be loaded.;
		%let macroNotFound = %eval(&macroNotFound + 1);
	%end;

	%next:
	%let i = %eval(&i + 1);
%end;
%mend;
