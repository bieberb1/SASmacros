/******************************************************************************************************
	Name:			format
	Purpose:		format a macro variable
	Parameters:		value, 
					format
	Output:			timerDuration (global macro variable)			
	Create Date:	July 8, 2022 
	Creator:		https://blogs.sas.com/content/sastraining/2017/10/16/how-to-format-a-macro-variable/
	
	Example:		%put [%format(%sysfunc(datepart(%sysfunc(dateTime()))), MMDDYY10.)];
					%let x=1111;
					%put [%format(&x, dollar11)];
	Dependencies:	None 
	Notes:	
********************************************************************************************************/

%macro format(value,format);
	%if %datatyp(&value)=CHAR
		%then %sysfunc(putc(&value,&format));
	%else %left(%qsysfunc(putn(&value,&format)));
%mend format;

