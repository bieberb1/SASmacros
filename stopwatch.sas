/******************************************************************************************************
	Name:			stopWatch
	Purpose:		Calculate running time for code
	Parameters:		command=start or stop
	Output:			timerDuration (global macro variable)			
	Create Date:	July 8, 2022 
	Creator:		Brian Bieber
					Adapted from: https://blogs.sas.com/content/sgf/2015/01/21/sas-timer-the-key-to-writing-efficient-sas-code/
	
	Example:		%stopWatch(start);
					data _null_;
						call sleep(1000);
					run;
					%stopWatch(stop);
	Dependencies:	None 
	Notes:	
********************************************************************************************************/

%macro stopwatch(command /*enter 'start' or 'stop'*/);
	%global timerStart timerDuration;

	/*Start timer*/
	%if %str(%lowcase(&command)) = %str(start) %then %do;
		%let timerStart = %sysfunc(datetime());
		%let timerDuration = ;
	%end; 
	/*Stop timer - print duration*/
	%else %if %str(%lowcase(&command)) = %str(stop) %then %do;
		/*Check that stopwatch was started*/
		%if %length(&timerStart) = 0 %then %do;
			%put Err0r: stopwatch never started;
		%end;
		/*Calculate/print duration*/
		%else %do;
			%let timerDuration = %sysfunc(sum(%sysfunc(datetime()),-&timerStart));
			%put TOTAL DURATION: %qsysfunc(putn(&timerDuration, time13.2));
			%let timerStart = ;
		%end;
	%end;
%mend;





