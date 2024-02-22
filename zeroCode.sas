*Zero code missing variables;
%macro ZeroCode (varlist=);
	%do i=1 %to %sysfunc(countw(&varlist., %str( )));
		%let currentvar=%scan(&varlist.,&i.);
		
		&currentvar._0c = &currentvar;
		if missing(&currentvar) then do;
			&currentvar._m = 1;
			&currentvar._0c = 0;
		end;
		else &currentvar._m = 0;
	%end;
%mend ZeroCode;