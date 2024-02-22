/************************************************************************************************************************************
	Title:			Utility macros
	---------------------------------------------------------------------------------------------------------
	Purpose: 		Call macros that are not generally standalone macros, but used by many of my other macros
	---------------------------------------------------------------------------------------------------------
	Notes: 
	---------------------------------------------------------------------------------------------------------
	Revisions (date, nature, name):
*************************************************************************************************************************************/

*Title macros;
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\storeTitles.sas";
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\printTitles.sas";
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\titleNext.sas";
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\titleNextCum.sas";

*Directory change;
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\GetThePath.sas";
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\ChangeDir.sas";

*Other;
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\deleteDatasets.sas";
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\missCode.sas";
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\RGBHex.sas";
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\zeroCode.sas";
%include "\\urrea.local\dopps\dopps\work\BrianB\Code Library\Macro Library\vType.sas";



