/************************************************************************************************************
	Title:	Read in and save a setup file for IVEware
	---------------------------------------------------------------------------------------------------------
	Purpose:	This macro makes it easy to create IVEware setup files (ie, files ending in .set). You call
				the macro, follow it with a semi-colon (required), then on the next line write your IVEware
				commands, and finally on a new line type four semi-colons (;;;;). E.g., here is a basic
				example:

					%mifile;
					DATAIN mydata;
					DATAOUT mydata_mi all;
					DEFAULT transfer; *transfer all vars in dataset that are not imputed;

					CONTINUOUS
					var1 var2 var3
					var4
					;

					ITERATIONS 10; *number of times IVEware will cycle through models;
					MULTIPLES 20; *number of output datasets;

					SEED 121106; *use a seed so results are reproducible;
					run;
					;;;;

				[End of example]

				This creates a file named mi.set in the current directory. You can change the file name using
				the first positional parameter to the macro, e.g. %mifile(my file.set);.

				Note the following:
				1. You can include SAS-style comments (both *; and slash-star-star-slash), and the
				   macro will remove them before saving the file.
				2. You can omit the final "run;" statement. The macro will add it for you if it's missing.
	---------------------------------------------------------------------------------------------------------
	Path and Name:  U:\DOPPS\work\Daniel Scratch\Macros\miFile.sas
	Created Date:   April 4, 2018
	Created By:     Daniel Muenz
	---------------------------------------------------------------------------------------------------------
	Parameters (all parameters are optional):
		file	(Positional) Name of output file. Does not have to be quoted. Default is "mi.set". You can
				also specify keywords like LOG or PRINT, in which case no external file is saved.
		data	(Keyword) SAS dataset in which to store commands. Default is _null_, meaning do not store the
				commands.
		length	(Keyword) Maximum length of a line for reading in the setup file. Default is 1000, which
				should be big enough, but you can increase if necessary. Note that this is the length of a
				line, not the length of a statement; a statement can be arbitrarily long by splitting over
				multiple lines. If the line length is too small, text will be cut off.
		lines	(Keyword) Maximum number of lines allowed when reading in the setup file. Default is 10000,
				which should be big enough, but you can increase if necessary. Note that this is the number of
				lines, not the number of statements. If there are any lines beyond the maximum, they will not
				be output and an err0r will be raised.
		resolve	(Keyword) Yes/No flag to resolve macro functions (starting with %) and variables (starting
				with &) when reading the setup file. Default is Yes. For a macro function, the entire
				expression must appear on a single line, otherwise it will not resolve correctly. If the
				resolved expression is longer than the maximum line length, then use the LENGTH parameter to
				increase the maximum.
	---------------------------------------------------------------------------------------------------------
	Known issues:
		1. For a macro function call to resolve correctly, the entire call must appear on one line.
		2. This probably doesn't matter, but if an input line starts with a *, then it is interpreted as
		   the beginning of a comment, even if it is not preceded (on a previous line) by a semicolon.
*************************************************************************************************************/

%macro mifile(file, data=_null_, length=1000, lines=10000, resolve=yes);
%if %length(&file) = 0 %then %let file = "mi.set";
%else %if not %sysfunc(prxmatch({^('[^'']*'|"[^""]*")$}, &file)) and %sysfunc(prxmatch({\W}, &file)) %then %let file = "&file";

%if %sysfunc(prxmatch({^\s*(YES|Y|TRUE|T|1)\s*$}i, &resolve)) %then %let resolve = 1;
%else %do;
	%if not %sysfunc(prxmatch({^\s*(NO|NO|FALSE|F|0)\s*$}i, &resolve)) %then %do;
		%put WAR%str(NING): Invalid value for RESOLVE parameter. Macro expressions will not be resolved.;
		%put WAR%str(NING)- Valid values meaning Yes are: YES, Y, TRUE, T, and 1.;
		%put WAR%str(NING)- Valid values meaning No are:  NO, N, FALSE, F, and 0.;
	%end;
	%let resolve = 0;
%end;

data &data;
	* Read in setup file from datalines4;
	length rawLine $&length;
	infile datalines4 length=lg eof=done;
	input rawLine $varying&length.. lg;

	* Put all the input lines into a vector, ie transpose the input to one long row. We do this
	  so that we can iterate over all the lines multiple times within a single data step. And the
	  reason we want to do that is so we can remove comments and resolve macro expressions.;
	array line[&lines] $&length;
	array blank[&lines];
	retain line: blank:;
	line[_N_] = rawLine;
	blank[_N_] = (prxmatch('{^\s*$}', rawLine) > 0); * make a note of blank lines, so we can keep them;

	return;
	done:

	/* At this point, we have read the entire input file. Now we process it to remove comments and
	   resolve macro expressions. */

	array oneLiner[2] $50 _temporary_ ('s{/\*.*?\*/}{}', 's{(^|;)(\s*)\*.*?;}{\1\2}');
	array begChars[2] $2 _temporary_ ('/*', '*');
	array endChars[2] $2 _temporary_ ('*/', ';');

	* Remove comments of both types, whether on a single line or spanning multiple lines;
	*  Type 1 comments are of the form /*comment*/  ;
	/* Type 2 comments of the form *comment;       */
	do type = 1 to 2;
		do times = 1 to 2;
			flag = 0;
			do i = 1 to _N_;
				* Comment statement begins and ends on the same line;
				if flag = 0 then line[i] = prxchange(oneLiner[type], -1, line[i]);

				beg_ = index(line[i], trim(begChars[type]));
				end_ = index(line[i], trim(endChars[type]));

				if type = 2 and flag = 0 and beg_ > 0 then do;
					if not prxmatch('{(^|;)\s*$}', substrn(line[i], 1, beg_-1)) then beg_ = 0;
				end;

				* Comment spans multiple lines;
				if flag = 0 and beg_ > 0 and end_ < beg_ then do;
					line[i] = substrn(line[i], 1, beg_-1);
					flag = 1;
				end;
				else if flag = 1 then do;
					if end_ > 0 then do;
						line[i] = substr(line[i], end_+2);
						flag = 0;
					end;
					else
						line[i] = '';
				end;

				if flag = 0 then line[i] = prxchange(oneLiner[type], -1, line[i]);
			end;
		end;
	end;

	* Check if the file is now empty, and if not, find the first and last non-empty lines;
	isEmpty = 1;
	do i = 1 to _N_;
		if prxmatch('{\w}', line[i]) then do;
			isEmpty = 0;
			leave;
		end;
	end;
	if isEmpty then do;
		put "WA%str(RNING): The IVEware setup file is empty.";
	end;
	else do;
		firstNonEmpty = i;
		do lastNonEmpty = _N_ to 1 by -1;
			if prxmatch('{\w}', line[lastNonEmpty]) then leave;
		end;

		* Make sure there is a run statement at the end;
		if not prxmatch('{\brun\s*;\s*$}i', line[lastNonEmpty]) then do;
			lastNonEmpty = lastNonEmpty + 1;
			line[lastNonEmpty] = 'run;';
		end;
	end;

	* Output the setup file, writing both to &file and to the log;
	put '=============== IVEware Setup File ===============';

	length outLine $&length;
	if not isEmpty then do i = firstNonEmpty to lastNonEmpty;
		if line[i] ne '' or blank[i] then do;
			outLine = line[i];
			%if &resolve %then %do;
				if findc(outLine, '%&') then outLine = resolve(outLine);
			%end;
			%if %qupcase(&file) ne LOG %then %do;
				file &file ls=&length;
				put outLine;
			%end;
			file LOG;
			put outLine;
			output;
		end;
	end;

	file LOG;
	put '==================================================';

	keep outLine;

	datalines4
%mend mifile;
