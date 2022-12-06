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
					BB220803 greatly simplified, by changing to proc datasets setup
******************************************************************/


%macro deleteDatasets(dsnList= /*List of datasets, can include ':'*/, lib=WORK /*library, default=WORK*/);
	proc datasets lib=&lib. nolist;
		delete &dsnList.;
	quit;
%mend deleteDatasets;

