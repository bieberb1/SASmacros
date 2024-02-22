/********************************************************************
	Name:			distribution_N
	Description:	Distribution graph that combines (1) histogram, (2) boxplot, and (3) fringplot for continuous variables
	Dynamic vars:	VAR		= []
					VARLABEL	= []
					TITLE	= []
					NORMAL	= []
					_BYLINE_	= []
	Notes:
	Updates:
	Code example:	proc sgrender data=dopps4.m_f template=distribution_N;
		  				dynamic var="malbumingdl" varlabel="Albumin (g/dL)" 
						title="Albumin Distribution";
					run;
********************************************************************/
proc template;
	define statgraph distribution_N;
		dynamic VAR VARLABEL TITLE NORMAL _BYLINE_;
		begingraph;
			entrytitle halign=left TITLE;
			entrytitle halign=left _BYLINE_;
			layout lattice / columns=1 rows=2  rowgutter=2px
			        rowweights=(.9 .1) columndatarange=union;
				columnaxes;
					columnaxis / label=VARLABEL;
				endcolumnaxes;
				layout overlay / yaxisopts=(offsetmin=.035);
					layout gridded / columns=2 border=true autoalign=(topleft topright);
						entry halign=left "Nobs";
						entry halign=left eval(strip(put(n(VAR),8.)));	
						entry halign=left "Mean";
						entry halign=left eval(strip(put(mean(VAR),8.1)));
						entry halign=left "P50";
						entry halign=left eval(strip(put(P50(VAR),8.1)));
						entry halign=left "StdDev";
						entry halign=left eval(strip(put(stddev(VAR),8.1)));
					endlayout;
					histogram VAR / scale=percent;
					if (exists(NORMAL))
						densityplot VAR / normal( );
					endif;
					fringeplot VAR / datatransparency=.7;
				endlayout;
				boxplot y=VAR / orient=horizontal whiskerpercentile=5;
			endlayout;
		endgraph;
	end;
run;

