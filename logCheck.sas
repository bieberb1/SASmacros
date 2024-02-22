/* CheckSASLogs.sas
 * set up to be an included file
 * 1/7/2016 modified to accept up to 4 email addresses in last argument
 
 * add appropriately revised version of this to the parent program:
 
 
 * example use
 
%LOGCHECK(
	\\data05\HP3\QIPValidation\DataPrep\IDR\&IDRPY\&xtd\safwork\log_prep4kecc_&now.txt, 
	\\data05\HP3\QIPValidation\DataPrep\IDR\&IDRPY\&xtd\safwork\lst_prep4kecc_&now.txt, 
	Dori.Bilik@ArborResearch.org);



 */



/* macro is from http://www2.sas.com/proceedings/sugi31/128-31.pdf
 * originally downloaded and modified 5/27/11
 * 1/6/12 modified to make email address a parameter
 */


%MACRO LOGCHECK(LOGNAME,LSTNAME,EMAILADDR);

%GLOBAL LOGCHECK;

DATA ADDRESS(KEEP=X);
LENGTH Y $200.;
Y=SYMGET('LOGNAME');
Z=LENGTH(Y);
X=TRIM(SUBSTR((TRIM(LEFT(Y))),1,Z-4));
RUN;

DATA _NULL_;
SET ADDRESS;
CALL SYMPUT('A',TRIM(X));
RUN;
************TO CREATE THE DATASET FOR THE ERROR AND OTHER KEYWORD MESSAGES************;
/*The Code only pulls the first two lines of every log messageif the message contains warning or Error in the
beginning of the line */
/* If line contains Error then this line is held and the full line is read unless */
/* we get '.' Otherwise next line is read. If the desired keyword is found then a flag*/
/* is attached */
DATA LOGCHECK(KEEP= COMPLETE FLAG);
	LENGTH COMPLETE $400. FLAG $14.;
	INFILE "&LOGNAME." TRUNCOVER;
	INPUT @1 LINE $5. @6 LINE1 $200. @;
	IF LINE='ERROR' OR LINE='WARNI' THEN DO;
	INPUT @1 FULL $200. @;

/* Code to check error or warning sentences in the log*/
	IF SUBSTR(REVERSE(TRIM(LEFT(FULL))),1,1)='.' THEN DO;
		INPUT;
		COMPLETE=trim(left(FULL));
	END; /****FIRST LINE******/
	ELSE DO;
		INPUT / NEXT $200. ;
		COMPLETE=TRIM(LEFT(FULL))||' '||TRIM(LEFT(NEXT));
	END;/*****SECOND LINE*****/
	IF LINE='ERROR' then FLAG="ERROR";
	ELSE IF LINE='WARNI' then FLAG="WARNING";
		OUTPUT;
	END;/****IF A ERROR OR WARNING IS FOUND*****/

	ELSE DO;
/* Code to check "Note" in the Log*/
		IF LINE='NOTE:' THEN DO;
			INPUT @1 FULL $200. @;
		IF INDEX(FULL,'truncated')>0 or INDEX(FULL,'uninitialized')>0
			OR INDEX(FULL,'lost card')>0 OR INDEX(FULL,'new line')>0
			OR INDEX(FULL,'repeats of BY values')>0 OR INDEX(FULL,'Invalid')>0 
			OR INDEX(FULL,'NOEXEC')>0 THEN DO;
				IF SUBSTR(REVERSE(TRIM(LEFT(FULL))),1,1)='.' THEN DO;
					COMPLETE=TRIM(LEFT(FULL));
				END;/****FIRST LINE******/
		ELSE DO;
			INPUT / NEXT $200. ;
			COMPLETE=TRIM(LEFT(FULL))||' '||TRIM(LEFT(NEXT));
		END;/*****SECOND LINE*****/
		IF INDEX(FULL,'truncated')>0 then FLAG="TRUNCATED";
		ELSE IF INDEX(FULL,'uninitialized')>0 then FLAG="UNINITIALIZED";
		ELSE IF INDEX(FULL,'lost card')>0 THEN FLAG="LOSTCARD";
		ELSE IF INDEX(FULL,'new line')>0 THEN FLAG="NEWLINE";
		ELSE IF INDEX(FULL,'repeats of BY values')>0 THEN FLAG="REPEATBYVALUES";
		ELSE IF INDEX(FULL,'Invalid')>0 THEN FLAG="INVALIDDATA";
		ELSE IF INDEX(FULL,'NOEXEC')>0 THEN FLAG="STOPPEDEXEC";
		OUTPUT;
		END;/****IF A KEYWORD IS FOUND*****/
	END;/*****IF NOTE: IS FOUND****/
	ELSE INPUT;/******IF NOTE IS FOUND BUT NO KEYWORD IS PRESENT IN IT******/
	END;/*****END OF NOTE: BLOCK*****/
RUN;

PROC SORT DATA=LOGCHECK out=LOGCHECK1;
BY FLAG;
RUN;

************TO Add Serial number in error message************;
DATA LOGCHECK3;
	SET LOGCHECK1;
	LENGTH TEXT2 $22 ;
	COUNT1=_N_;
	IF COUNT1<10 THEN COUNT=COMPRESS(LEFT('00')||COUNT1);
	ELSE IF COUNT1<100 THEN COUNT=COMPRESS(LEFT('0')||COUNT1);
	ELSE COUNT=COUNT1;
	TEXT2=TRIM(LEFT(COUNT))|| " " || TRIM(LEFT(FLAG));
RUN;

************TO CREATE THE DATASET FOR SUMMMARY************;
PROC SUMMARY DATA=LOGCHECK1 NWAY MISSING;
	BY FLAG;
	OUTPUT OUT=test_sum7(DROP=_TYPE_ RENAME=(FLAG=TEXT1 _FREQ_=COMPLETE));
	RUN;

data test_sum7(drop=x);
	set test_sum7(rename=(complete=x));
	complete=put(x,best4.);
run;

DATA LOGCHECK3(DROP=COMPLETE count1 count RENAME=(TEXT2=TEXT1 TEXT=COMPLETE));
	SET LOGCHECK3;
	TEXT = COMPLETE;
RUN;

/************
	TO CREATE MASTER DATASETS WHICH WILL GENERATE DIFFERENT DATASETS 
	TO BE WRITTEN IN THE MAIL
 *************/

DATA STRING9(drop= i);
	LENGTH TEXT1 $ 50 COMPLETE $ 100 ;
	COMPLETE='';
	do i=1 to 4;
		if i=1 then TEXT1= "THE SPECIFIC MESSAGES ARE AS FOLLOWS";
		if i=2 then TEXT1=" ";
		if i=3 then do;TEXT1="ORDER# KEYWORD";
		COMPLETE="DETAILED KEYWORD MESSAGE";end;
		if i=4 then do;TEXT1="------- --------";
		COMPLETE=" ---------------------------";end;
		output;
	end;
RUN;

DATA STRING10(drop= i);
	LENGTH TEXT1 $ 50 COMPLETE $ 100 ;
	COMPLETE='';
	do i=1 to 3;
		if i=1 then TEXT1= "BELOW IS A BREAKDOWN OF THE KEYWORDS FOUND:";
		if i=2 then do;TEXT1="KEYWORD";
		COMPLETE="#OF OCCURENCES";end;
		if i=3 then do;TEXT1="---------";
		COMPLETE="-----------------";end;
	output;
	end;
run;

DATA CLIENT;
	LENGTH TEXT1 $ 50 COMPLETE $ 200 ;
	TEXT1="ERROR CHECK REPORT";
	COMPLETE='';
RUN;

DATA CLIENT1(DROP=SASTIME TIME DATE HHMM SASDAT DATE1);
	LENGTH TEXT1 $ 50 COMPLETE $ 200 ;
	TIME=TIME();
	DATE=DATE();
	SASTIME=INPUT(TIME,15.);
	HHMM=PUT(SASTIME,TIME5.);
	TEXT1=TRIM(LEFT("TIME:"))||" "||TRIM(LEFT(HHMM));
	SASDAT=INPUT(DATE,15.);
	DATE1=PUT(SASDAT,MMDDYY8.);
	COMPLETE=TRIM(LEFT("DATE:"))||" "||TRIM(LEFT(DATE1));
RUN;

DATA STRING2(drop= i);
	LENGTH TEXT1 $ 50 COMPLETE $ 100 ;
	COMPLETE='';
	do i=1 to 3;
		if i=1 then TEXT1= "NOTE:";
		if i=2 then TEXT1="ATTACHMENT1: THE LOGFILE THAT WAS CHECKED.";
		if i=3 then TEXT1="ATTACHMENT2: THE LIST FILE.";
		output;
	end;
run;

DATA STRING5;
	LENGTH TEXT1 $ 50 COMPLETE $ 200;
	TEXT1="KEYWORD";
	COMPLETE="#OF OCCURENCES";
RUN;

DATA BLANK1;
	LENGTH TEXT1 $ 50 COMPLETE $ 200;
	TEXT1=" ";
	COMPLETE=" ";
RUN;

DATA FINAL;
	SET CLIENT CLIENT1 BLANK1 STRING10 TEST_SUM7 BLANK1 STRING9;
RUN;

DATA MESSAGE1;
	SET LOGCHECK3;
	LENGTH LAST $ 500;
	LAST=(TEXT1)||" "||LEFT(COMPLETE);
	KEEP LAST;
RUN;

DATA QCFINAL1;
	SET FINAL;
	LENGTH LAST $ 500;
	LAST=(TEXT1)||LEFT(COMPLETE);
	KEEP LAST;
RUN;

DATA QCFINAL2;
	SET BLANK1 STRING2 BLANK1 BLANK1;
	LENGTH LAST $ 500;
	LAST=(TEXT1)||LEFT(COMPLETE);
	KEEP LAST;
RUN;

DATA QCFINAL;
	SET QCFINAL1 MESSAGE1 QCFINAL2;
RUN;

PROC SQL;
	CREATE TABLE TABLE1 AS SELECT COUNT(*) AS CNT FROM LOGCHECK;
quit;

DATA _NULL_;
	SET TABLE1;
	CALL SYMPUT('CNT',CNT);
RUN;

DATA TABLE2;
	LENGTH YES $3 NO $3;
	YES="*";
	NO=" ";
RUN;

************TO CREATE THE MACRO VARIABLE ERRORCHECK************;
DATA _NULL_;
	SET TABLE2;
	%IF &CNT.>0 %THEN %DO;
		CALL SYMPUT('LOGCHECK','*');
	%END;
	%ELSE %DO;
		CALL SYMPUT('LOGCHECK',' ');
	%END;
RUN;

%put &LOGCHECK.;

************TO Delete not required DATASETS************;
PROC DATASETS LIBRARY=WORK NOLIST;
	DELETE ADDRESS
		BLANK1
		CLIENT1
		CLIENT
		FINAL
		MESSAGE1
		LOGCHECK
		LOGCHECK1
		LOGCHECK3
		QCFINAL1
		QCFINAL2
		STRING10
		STRING2
		STRING5
		STRING9
		TABLE1
		TABLE2
		TEST_SUM7
		USERNAME;
QUIT;

************MACRO TO SEND MAIL************;
%MACRO MAIL;
	
	data _null_;
		%let email1 = %qscan("&EMAILADDR.",1," ");
		%let email2 = " ";
		%let email3 = " ";
		%let email4 = " ";
		%let NEA = %eval(%sysfunc(countc("&EMAILADDR.",%str('@'))));
		%if &NEA > 1 %then %do;
			%let email1 = %qscan("&EMAILADDR.",1," ");
			%if &NEA ge 2 %then %let email2 = %qscan("&EMAILADDR.",2," ");
			%if &NEA ge 3 %then %let email3 = %qscan("&EMAILADDR.",3," ");
			%if &NEA = 4 %then %let email4 = %qscan("&EMAILADDR.",4," ");
		%end;
	run;

	%if &NEA > 1 %then %do;
		%if &NEA = 2 %then %do;
			FILENAME OUTMAIL EMAIL
			TO= "&email1." 
			SUBJECT="LOG CHECK REPORT &now." 
			CC= "&email2."
			ATTACH=("&LOGNAME." "&LSTNAME.");
			DATA _NULL_;
				SET QCFINAL;
				FILE OUTMAIL;
				PUT LAST;
			RUN;
		%end;
		%else %if &NEA = 3 %then %do;
			FILENAME OUTMAIL EMAIL
			TO= "&email1." 
			SUBJECT="LOG CHECK REPORT &now." 
			CC= ("&email2." "&email3.")
			ATTACH=("&LOGNAME." "&LSTNAME.");
			DATA _NULL_;
				SET QCFINAL;
				FILE OUTMAIL;
				PUT LAST;
			RUN;
		%end;
		%else %if &NEA = 4 %then %do;
			FILENAME OUTMAIL EMAIL
			TO= "&email1." 
			SUBJECT="LOG CHECK REPORT &now." 
			CC= ("&email2." "&email3." "&email4.")
			ATTACH=("&LOGNAME." "&LSTNAME.");
			DATA _NULL_;
				SET QCFINAL;
				FILE OUTMAIL;
				PUT LAST;
			RUN;
		%end;
	%end;
	%else %do;
		FILENAME OUTMAIL EMAIL
		TO= "&email1." 
		SUBJECT="LOG CHECK REPORT &now." 
		ATTACH=("&LOGNAME." "&LSTNAME.");
		DATA _NULL_;
			SET QCFINAL;
			FILE OUTMAIL;
			PUT LAST;
		RUN;
	%end;
%MEND MAIL;

%MACRO MAILOK;
	data _null_;
		%let email1 = %qscan("&EMAILADDR.",1," ");
		%let email2 = " ";
		%let email3 = " ";
		%let email4 = " ";
		%let NEA = %eval(%sysfunc(countc("&EMAILADDR.",%str('@'))));
		%if &NEA > 1 %then %do;
			%let email1 = %qscan("&EMAILADDR.",1," ");
			%if &NEA ge 2 %then %let email2 = %qscan("&EMAILADDR.",2," ");
			%if &NEA ge 3 %then %let email3 = %qscan("&EMAILADDR.",3," ");
			%if &NEA = 4 %then %let email4 = %qscan("&EMAILADDR.",4," ");
		%end;
	run;

	%if &NEA > 1 %then %do;
		%if &NEA = 2 %then %do;
			FILENAME OUTMAIL EMAIL
			TO= "&email1." 
			SUBJECT="LOG CHECK REPORT &now." 
			CC= "&email2."
			ATTACH=("&LOGNAME." "&LSTNAME.");
			DATA _NULL_;
				FILE OUTMAIL;
				PUT "No problems found in these logs";
			RUN;
		%end;
		%else %if &NEA = 3 %then %do;
			FILENAME OUTMAIL EMAIL
			TO= "&email1." 
			SUBJECT="LOG CHECK REPORT &now." 
			CC= ("&email2." "&email3.")
			ATTACH=("&LOGNAME." "&LSTNAME.");
			DATA _NULL_;
				FILE OUTMAIL;
				PUT "No problems found in these logs";
			RUN;
		%end;
		%else %if &NEA = 4 %then %do;
			FILENAME OUTMAIL EMAIL
			TO= "&email1." 
			SUBJECT="LOG CHECK REPORT &now." 
			CC= ("&email2." "&email3." "&email4.")
			ATTACH=("&LOGNAME." "&LSTNAME.");
			DATA _NULL_;
				FILE OUTMAIL;
				PUT "No problems found in these logs";
			RUN;
		%end;
	%end;
	%else %do;
		FILENAME OUTMAIL EMAIL
		TO= "&email1." 
		SUBJECT="LOG CHECK REPORT &now." 
		ATTACH=("&LOGNAME." "&LSTNAME.");
		DATA _NULL_;
			FILE OUTMAIL;
			PUT "No problems found in these logs";
		RUN;
	%end;
%MEND MAILOK;

DATA _NULL_;
	%IF &CNT.>0 %THEN %DO;
		%MAIL;
	%END;
	%ELSE %DO;
		%MAILOK;
	%END;
RUN;

PROC DATASETS LIBRARY=WORK NOLIST;
	DELETE QCFINAL;
QUIT;

%MEND LOGCHECK; /*END OF LOGCHECK MACRO*/

