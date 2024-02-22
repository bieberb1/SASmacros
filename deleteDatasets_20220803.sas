/*****************************************************************
	Name:			DeleteDatsets
	Purpose:		Delete list of datasets from folder
	Parameters:		dsnList=List of datasets
					lib=library where datasets reside
	Create Date:	January 20, 2012
	Creator:		Brian Bieber
	
	Example:		%DeleteDatasets(cox_PEst cox_Nobs);
	Notes:			BB130121 edit to allow dataset lists (cox_:)
					BB130715 change i to delete2i to avoid interference with other macros
					BB131017 macro variables local and fixed missing parentheses for cmpres
					BB131223 added check to ensure the when searching for a list with a '_' at the end, it does not search for blank and delete the dataset without the '_' tag
					BB200114 added option to change to different folder
******************************************************************/


%macro deleteDatasets(dsnList= /*List of datasets, can include ':'*/, lib=WORK /*library, default=WORK*/);
	%local dataList currentDSN delete1i delete2i currDataList;
	%let dataList=;
	%do delete1i = 1 %to %sysfunc(countw(&dsnList., %str( )));
		%let currentDSN = %scan(&dsnList., &delete1i.);
		*Deal with colon modifier indicating list of datasets with same prefix;
		%if %index(&currentDSN., :) > 0 %then %do;
			proc sql NOPRINT;
				SELECT distinct memname INTO :dataList SEPARATED BY ' ' FROM dictionary.columns
				WHERE libname = "%upcase(&lib.)" AND memname LIKE "%UPCASE(%CMPRES(%SUBSTR(&currentDSN., 1, %eval(%length(&currentDSN.)-1)))%)" escape '^';
			quit;
			
			%if %length(&datalist.) > 0 %then %do delete2i = 1 %to %sysfunc(countw(&dataList., %str( )));
				%let currDataList = %scan(&datalist., &delete2i.);
				%if %sysfunc(exist(&lib..&currDataList.)) AND &currDataList. ne %upcase(%substr(&dsnList., 1, %eval(%length(&dsnList.)-2))) %then %do; proc sql; drop table &lib..&currDataList.; quit; %end;
			%end;
		%end;
		%else %do;
			%if %sysfunc(exist(&lib..&currentDSN.)) %then %do; proc sql; drop table &lib..&currentDSN.; quit; %end;
		%end;
	%end;
%mend deleteDatasets;
