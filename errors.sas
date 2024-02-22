/****************************************************************
| PROGRAM NAME: ERRORS.SAS  in c:\Books\Cleans\Patients         |
| PURPOSE: Accumulates errors for numeric variables in a SAS    |
|          data set for later reporting.                        |
|          This macro can be called several times with a        |
|          different variable each time. The resulting errors   |
|          are accumulated in a temporary SAS data set called   |
|          Errors.                                              |
| ARGUMENTS: Dsn=    - SAS data set name (assigned with a %LET) |
|            Idvar=  - Id variable (assigned with a %LET)       |
|                                                               |
|            Var     = The variable name to test                |
|            Low     = Lowest valid value                       |
|            High    = Highest valid value                      |
|            Missing = IGNORE (default) Ignore missing values   |
|                      ERROR Missing values flagged as errors   |
|                                                               |
| EXAMPLE: %let Dsn = Clean.Patients;                           |
|          %let Idvar = Patno;                                  |
|                                                               |
|          %Errors(Var=HR, Low=40, High=100, Missing=error)     |
|          %Errors(Var=SBP, Low=80, High=200, Missing=ignore)   |
|          %Errors(Var=DBP, Low=60, High=120)                   |
|          Test the numeric variables HR, SBP, and DBP in data  |
|          set Clean.patients for data outside the ranges       |
|          40 to 100, 80 to 200, and 60 to 120 respectively.    |
|          The ID variable is PATNO and missing values are to   |
|          be flagged as invalid for HR but not for SBP or DBP. 
| SOURCE:  https://blogs.sas.com/content/sgf/2022/01/11/two-macros-for-detecting-data-errors/
|          https://support.sas.com/downloads/package.htm?pid=1655
****************************************************************/
%macro Errors(Var=,    /* Variable to test     */
              Low=,    /* Low value            */
              High=,   /* High value           */
              Missing=IGNORE 
                       /* How to treat missing values         */
                       /* Ignore is the default.  To flag     */
                       /* missing values as errors set        */
                       /* Missing=error                       */);
data Tmp;
   set &amp;Dsn(keep=&amp;Idvar &amp;Var);
   length Reason $ 10 Variable $ 32;
   Variable = "&amp;Var";
   Value = &amp;Var;
   if &amp;Var lt &amp;Low and not missing(&amp;Var) then do;
      Reason='Low';
      output;
   end;
 
   %if %upcase(&amp;Missing) ne IGNORE %then %do;
      else if missing(&amp;Var) then do;
         Reason='Missing';
         output;
      end;
   %end;
 
   else if &amp;Var gt &amp;High then do;
      Reason='High';
      output;
      end;
      drop &amp;Var;
   run;
 
   proc append base=Errors data=Tmp;
   run;
 
%mend Errors;