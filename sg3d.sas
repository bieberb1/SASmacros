/* SG3D Macro (Visualize 3D Data in SAS)
 * Author: Yinliang Wu (yinliang.wu@sas.com)
 * Inspired by Sanjay's post: https://blogs.sas.com/content/graphicallyspeaking/2015/03/10/a-3d-scatter-plot-macro/
 * Downloaded from: https://blogs.sas.com/content/sgf/files/2022/06/SG3D_Macro.txt
 * Examples in https://blogs.sas.com/content/graphicallyspeaking/2022/07/11/a-better-3d-scatter-plot-macro/
 * 
 * Parameters:
 * Data=	Input dataset, Required
 * X, Y, Z= Three dimension variables, Required
 * Group= 	Grouping variable
 * Size=	Bubble size variable
 * Title	Specify the title
 * Footnote	Specify the footnote
 * LblX, LblY, LblZ= Axies label
 * AttrMap  Specify the attribute map for dattrmap= of SGPLOT
 * Tilt, Roll, Rotate=  					   Specify the angle of Tilt/Roll/Pan
 * Walls, BackWall,SizeWall,FloorWall 		   Control visibility of WALLs,1-visible, 0-hidden, Walls=0 can hide all walls;
 *   BackWallShadow,SideWallShadow,FloorWallShadow control visibility of Shadows on walls
 *     BackPoints,SidePoints,FloorPoints	   Control the visibility of shadow of Points
 *     BackNeedles,SideNeedles,FloorNeedles    Control the visibility of shadow of Needles
 * Axes     Control the visibility of Axis X/Y/Z
 * Ranges   Control the visibility of Range labels of Axes
 * Grids, BackGrid, SideGrid, FloorGrid        Control visibility of GRIDS,1-visible, 0-hidden, Girds=0 can hide all grids;
 * GridNum                                     Control the number of grids, default is 5
 * MarkerColor, DataSkin, DataTransparency     Control the appearance of data markers and transparency.
 * Legend=                                     Control the visibility of lengends
 * InitData=                                   Specify 1 to initialize the WALL/GRID data, 0 to skip for animation generation.	
 */ 
%macro SG3D (Data=,  X=X, Y=Y, Z=Z, Group=, Size=,
              Title=, Footnote=, 
              LblX=%quote(&X), LblY=%quote(&Y), LblZ=%quote(&Z),               
              Attrmap=attrmap, 			  
			  Tilt=65, Roll=0, Rotate=-55,  
			  Walls=1, BackWall =1,SideWall =1,FloorWall =1,
              BackWallShadow=0,SideWallShadow=0,FloorWallShadow=1,
			  BackPoints=0,SidePoints=0,FloorPoints=0, PointsTransparency=0.8,
              BackNeedles=0,SideNeedles=0,FloorNeedles=0, ParallelNeedles=1,
              Axes=1, Ranges=1,  
			  Grids=1, BackGrid =1,SideGrid =1,FloorGrid =1, GridNum=5,
			  MarkerColor=darkblue, DataSkin=Sheen, DataTransparency =0.1, 
			  Legend=0,
              InitData=1);

  %if &InitData=1 %then %do;
	/*--Matrix functions FCMP Wrapper--*/
	proc fcmp outlib=work.funcs.matrix;
	  subroutine MatInv(Mat[*,*], InvMat[*,*]);
	    outargs InvMat;
	    call inv(Mat, InvMat);
	  endsub;
	  subroutine MatMult(A[*,*], B[*,*], C[*,*]);
	    outargs C;
	    call mult(A, B, C);
	  endsub;
	  subroutine MatIdent(A[*,*]);
	    outargs A;
	    call identity(A);
	  endsub;
	run;
	options cmplib=work.funcs; 
	 
	/*--Compute data ranges--*/
	%global XMIN XMAX YMIN YMAX ZMIN ZMAX;
	data _null_;
	  retain xmin xmax ymin ymax zmin zmax;
	  if _N_=1 then do;
	  	xmin=&X; xmax=&X; ymin=&Y; ymax=&Y; zmin=&Z; zmax=&Z;
	  end; 

	  set &Data end=last;

	  xmin=min(xmin, &X);  xmax=max(xmax, &X);
	  ymin=min(ymin, &Y);  ymax=max(ymax, &Y);
	  zmin=min(zmin, &Z);  zmax=max(zmax, &Z);
	  if last then do;
	    call symput("xmin", xmin); call symput("xmax", xmax);
	    call symput("ymin", ymin); call symput("ymax", ymax);
	    call symput("zmin", zmin); call symput("zmax", zmax);
	  end;
	run; 

	/*--Normalize Points data to -1 to +1 ranges--*/
	data data_Points;
	  keep &Group &Size x y z xf yf zf xb yb zb xb2 yb2 zb2 xs ys zs xs2 ys2 zs2;
	  xrange=&xmax-&xmin;
	  yrange=&ymax-&ymin;
	  zrange=&zmax-&zmin;

	  set &data;

	  /*--data points--*/
	  x=2*(&X-&xmin)/xrange -1;
	  y=2*(&Y-&ymin)/yrange -1;
	  z=2*(&Z-&zmin)/zrange -1;

	  /*--Floor--*/
	  xf = x; yf = y; zf =-1;
	  
	  /*--Back Wall--*/	    
	  xb =-1; yb = y; zb = z;
    %if &ParallelNeedles=1 %then %do; 
      xb2=-1; yb2=y; zb2 =-1;
    %end;
	%else %do; 
	  xb2= x; yb2=y; zb2 = z;
	%end;

	  /*--Side Wall--*/
	  xs = x; ys = 1; zs = z;
	%if &ParallelNeedles=1 %then %do; 
	  xs2= x; ys2= 1; zs2=-1;
	%end;
	%else %do;  
	  xs2= x; ys2= y; zs2= z;
	%end;
	run; 

	/*Nomralized Walls data*/
	data wall_Axes; 	  
	  length id $ 8 group $ 8;
	  id="X1-Axis"; group="D"; xw=-1; yw=-1; zw=-1;   xw2= 1; yw2=-1; zw2=-1;   xl= 0; yl=-1;     zl=-1; label=1; output;
	  id="X3-Axis"; group="L"; xw=-1; yw=-1; zw= 1;   xw2= 1; yw2=-1; zw2= 1;   xl= 1; yl= 0;     zl=-1; label=2; output;
	  id="X4-Axis"; group="D"; xw=-1; yw= 1; zw= 1;   xw2= 1; yw2= 1; zw2= 1;   xl=-1; yl=-1.08;  zl= 0; label=3; output;
	  id="Y1-Axis"; group="D"; xw=-1; yw=-1; zw= 1;   xw2=-1; yw2= 1; zw2= 1;   xl= 1; yl=-1 ;    zl= -1; label=4; output;

	  id="Y3-Axis"; group="D"; xw= 1; yw=-1; zw=-1;   xw2= 1; yw2= 1; zw2=-1;   xl= 1; yl= 1 ;    zl=-1; label=5; output;
	  id="Y4-Axis"; group="L"; xw= 1; yw=-1; zw= 1;   xw2= 1; yw2= 1; zw2= 1;   xl=-1; yl=-1.08 ; zl= 1; label=6; output;

	  id="Z1-Axis"; group="D"; xw=-1; yw=-1; zw=-1;   xw2=-1; yw2=-1; zw2= 1;   xl=-1; yl=-1.08 ; zl=-1; label=9; output;
	  id="Z2-Axis"; group="L"; xw= 1; yw=-1; zw=-1;   xw2= 1; yw2=-1; zw2= 1;   xl=-1; yl=-1;      zl=-1; label=7; output;
	  id="Z4-Axis"; group="D"; xw= 1; yw= 1; zw=-1;   xw2= 1; yw2= 1; zw2= 1;   xl= 1; yl=-1;      zl=-1; label=8; output;
	  
	%if &Walls=1 %then %do;
	  %if &FloorWALL=1 %then %do;
	  id="Bottom";  group="D"; xw=-1; yw=-1; zw=-1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Bottom";  group="D"; xw= 1; yw=-1; zw=-1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Bottom";  group="D"; xw= 1; yw= 1; zw=-1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Bottom";  group="D"; xw=-1; yw= 1; zw=-1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  %end;
	  %if &BackWALL=1 %then %do;
	  id="Back";    group="D"; xw=-1; yw=-1; zw=-1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Back";    group="D"; xw=-1; yw= 1; zw=-1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Back";    group="D"; xw=-1; yw= 1; zw= 1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Back";    group="D"; xw=-1; yw=-1; zw= 1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  %end;
	  %if &SideWALL=1 %then %do;
	  id="Right";   group="D"; xw=-1; yw= 1; zw=-1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Right";   group="D"; xw= 1; yw= 1; zw=-1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Right";   group="D"; xw= 1; yw= 1; zw= 1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  id="Right";   group="D"; xw=-1; yw= 1; zw= 1;   xw2= .; yw2= .; zw2= .; xl= .; yl= .; zl= .; label= .; output;
	  %end;
	%end;
	run;  

	/*Normalized Girds data*/;
    data wall_Grids;
      id="Grids"; 
	  step=0.4;
    %if 0< %eval(&GRIDNUM) %then %do;
	  step=2.0/&GRIDNUM;
    %end; 

    %if &FloorGrid=1 %then %do;
	  /*Floor??grid lines parallel to the y-axis, need group2 var to fix grouping color issue;*/
	  group2="Bottom"; zg=-1; zg2=zg;
	  yg=-1; yg2=1; 
	  do xg=-1 to 1 by step;
	    xg2=xg; output;
	  end;   
	  xg=-1; xg2=1; 
	  do yg=-1 to 1 by step;
	    yg2=yg; output;
	  end;  
    %end;

    %if &BackGrid=1 %then %do;
      /*Back??grid lines parallel to the Z-axis;*/
	  group2="Back"; xg=-1; xg2=xg;  
	  zg=-1; zg2=1;
	  do yg=-1 to 1 by step;
        yg2=yg; output;
	  end;  
	  yg=-1;yg2=1;
	  do zg=-1 to 1 by step;
	    zg2=zg; output;
	  end;  
    %end;

    %if &SideGrid=1 %then %do;
      /*Right??grid lines parallel to the X-axis;*/
	  group2="Right"; yg=1; yg2=yg; 
	  xg=-1; xg2=1;
	  do zg=-1 to 1 by step;
	    zg2=zg; output;
	  end; 
	  zg=-1; zg2=1;
	  do xg=-1 to 1 by step;
	    xg2=xg; output;
	  end;
    %end; 
    run; 

    /*Merge all data for projection*/
    data data_All;
      set data_Points wall_Axes wall_Grids indsname=inds;
	  source=scan(inds,-1,'.'); 
    run;
  %END;

  /*--Project the data--*/
  data data_all_proj; 
	if _N_=1 then do;	  
	  array m[4,4] _temporary_;  /*--Projection Matrix--*/
	  array rx[4,4] _temporary_; /*--X rotation Matrix--*/
	  array ry[4,4] _temporary_; /*--Y rotation Matrix--*/
	  array rz[4,4] _temporary_; /*--Z rotation Matrix--*/

	  array u[4,4] _temporary_;  /*--Intermediate Matrix--*/
	  array v[4,4] _temporary_;  /*--Intermediate Matrix--*/
	  array w[4,4] _temporary_;  /*--Final View Matrix--*/

	  array d[4,1] _temporary_;  /*--World Data Array --*/
	  array p[4,1] _temporary_;  /*--Projected Data Array --*/

	  retain r t f n ;
	  r=1; l=-1; t= 1; b=-1;  f=1; n=-1;
	  
	  /*--Set up projection matrix--*/
	  m[1,1]=2/(r-l); m[1,2]=0.0;      m[1,3]=0.0;      m[1,4]=-(r+l)/(r-l);
	  m[2,1]=0.0;     m[2,2]=2/(t-b);  m[2,3]=0.0;      m[2,4]=-(t+b)/(t-b);
	  m[3,1]=0.0;     m[3,2]=0.0;      m[3,3]=-2/(f-n); m[3,4]=-(f+n)/(f-n);
	  m[4,1]=0.0;     m[4,2]=0.0;      m[4,3]=0.0;      m[4,4]=1.0;

	  fac=constant("PI")/180;
      retain fac;
	  ALPHA=&Tilt*fac; BETA=&Roll*fac; GAMMA=&Rotate*fac; /*Argument is in DEGREE*/	  
 
	  /*--Set up X rotation matrix Rx(ALPHA)--*/
	  rx[1,1]=1;     rx[1,2]=0.0;        rx[1,3]=0.0;        rx[1,4]=0.0;
	  rx[2,1]=0.0;   rx[2,2]=cos(ALPHA); rx[2,3]=-sin(ALPHA); rx[2,4]=0.0;
	  rx[3,1]=0.0;   rx[3,2]=sin(ALPHA); rx[3,3]=cos(ALPHA);  rx[3,4]=0.0;
	  rx[4,1]=0.0;   rx[4,2]=0.0;        rx[4,3]=0.0;        rx[4,4]=1.0;

	  /*--Set up Y rotation matrix Ry(BETA)--*/
	  ry[1,1]=cos(BETA);  ry[1,2]=0.0;  ry[1,3]=sin(BETA);  ry[1,4]=0.0;
	  ry[2,1]=0.0;        ry[2,2]=1.0;  ry[2,3]=0.0;       ry[2,4]=0.0;
	  ry[3,1]=-sin(BETA); ry[3,2]=0.0;  ry[3,3]=cos(BETA);  ry[3,4]=0.0;
	  ry[4,1]=0.0;       ry[4,2]=0.0;   ry[4,3]=0.0;       ry[4,4]=1.0;

	  /*--Set up Z rotation matrix Rz(GAMMA)--*/
	  rz[1,1]=cos(GAMMA);  rz[1,2]=-sin(GAMMA); rz[1,3]=0.0;  rz[1,4]=0.0;
	  rz[2,1]=sin(GAMMA);  rz[2,2]= cos(GAMMA); rz[2,3]=0.0;  rz[2,4]=0.0;
	  rz[3,1]=0.0;         rz[3,2]=0.0;        rz[3,3]=1.0;  rz[3,4]=0.0;
	  rz[4,1]=0.0;         rz[4,2]=0.0;        rz[4,3]=0.0;  rz[4,4]=1.0;
	  
	  /*--Build transform matris--*/
	  call MatMult(rz, m, u);
	  call MatMult(ry, u, v);
	  call MatMult(rx, v, w);
	end;
    set data_All;
    if source="DATA_POINTS" then do;  
	  /*--Transform data--*/
	  d[1,1]=x; d[2,1]=y; d[3,1]=z; d[4,1]=1;
	  call MatMult(w, d, p);
	  xd=p[1,1]; yd=p[2,1]; zd=p[3,1]; wd=p[4,1];

	  /*--Transform floor drop shadow--*/
	  d[1,1]=xf; d[2,1]=yf; d[3,1]=zf; d[4,1]=1;
	  call MatMult(w, d, p);
	  xf=p[1,1]; yf=p[2,1]; zf=p[3,1]; wf=p[4,1];

	  /*--Transform back wall shadow--*/
	  d[1,1]=xb; d[2,1]=yb; d[3,1]=zb; d[4,1]=1;
	  call MatMult(w, d, p);
	  xb=p[1,1]; yb=p[2,1]; zb=p[3,1]; wb=p[4,1];

	  d[1,1]=xb2; d[2,1]=yb2; d[3,1]=zb2; d[4,1]=1;
	  call MatMult(w, d, p);
	  xb2=p[1,1]; yb2=p[2,1]; zb2=p[3,1]; wb2=p[4,1];

	  /*--Transform side wall shadow--*/
	  d[1,1]=xs; d[2,1]=ys; d[3,1]=zs; d[4,1]=1;
	  call MatMult(w, d, p);
	  xs=p[1,1]; ys=p[2,1]; zs=p[3,1]; ws=p[4,1];

	  d[1,1]=xs2; d[2,1]=ys2; d[3,1]=zs2; d[4,1]=1;
	  call MatMult(w, d, p);
	  xs2=p[1,1]; ys2=p[2,1]; zs2=p[3,1]; ws2=p[4,1];

	  keep &Group &Size xd yd zd xf yf zf xb yb zb xb2 yb2 zb2 xs ys zs xs2 ys2 zs2;
    end;
    else do; 
	  /*--Transform walls--*/
	  d[1,1]=xw; d[2,1]=yw; d[3,1]=zw; d[4,1]=1;
	  call MatMult(w, d, p);
	  xw=p[1,1]; yw=p[2,1]; zw=p[3,1];

	  /*--Transform axes--*/
	  d[1,1]=xw2; d[2,1]=yw2; d[3,1]=zw2; d[4,1]=1;
	  call MatMult(w, d, p);
	  xw2=p[1,1]; yw2=p[2,1]; zw2=p[3,1]; 

	  /*--Transform labels--*/
	  d[1,1]=xl; d[2,1]=yl; d[3,1]=zl; d[4,1]=1;
	  call MatMult(w, d, p);
	  xl=p[1,1]; yl=p[2,1]; zl=p[3,1];

	  /*--Set axis labels--*/ 
	  if label eq 1 then lbx="&Lblx";
	  if label eq 2 then lby="&Lbly";
	  if label eq 3 then lbz="&Lblz";
 
	  /*--Calcuate the X/Y text rotate angle from a line, Z always=270--*/
	  if id="X1-Axis" or id="Y1-Axis" or id="Z1-Axis" then do; 
	    if (xw2-xw)= 0 then theta=-constant("PI")/2.0;
		else theta=atan( (yw2-yw)/(xw2-xw) );
		theta_d=theta/ fac;  
		if id = "X1-Axis" then call symput("LBLXRotate", theta_d); 
		if id = "Y1-Axis" then call symput("LBLYRotate", theta_d);
        if id = "Z1-Axis" then call symput("LBLZRotate", theta_d);  
	  end;

	  /*--Transform Grids--*/
	  d[1,1]=xg; d[2,1]=yg; d[3,1]=zg; d[4,1]=1;
	  call MatMult(w, d, p);
	  xg=p[1,1]; yg=p[2,1]; zg=p[3,1];

	  /*--Transform Grids--*/
	  d[1,1]=xg2; d[2,1]=yg2; d[3,1]=zg2; d[4,1]=1;
	  call MatMult(w, d, p);
	  xg2=p[1,1]; yg2=p[2,1]; zg2=p[3,1];
	  keep xg yg zg xg2 yg2 zg2 group2; 

	  if label eq 4 then lbxmax="&XMAX";
	  if label eq 5 then lbymax="&YMAX";
	  if label eq 6 then lbzmax="&ZMAX"; 
	  if label eq 7 then lbxmin="&XMIN";
	  if label eq 8 then lbymin="&YMIN";
	  if label eq 9 then lbzmin="&ZMIN"; 
	  keep lbxmax lbymax lbzmax lbxmin lbymin lbzmin;

	  keep id group xw yw zw xw2 yw2 zw2 xl yl zl lbx lby lbz label; 
    end;
  run;

  /*--Sort projected data by Z--*/
  proc sort data=data_all_proj;
    by &group descending zd; /*fix the z-depth and grouping color issue*/
  run;
 
  /*--Draw the graph with projected data--*/
  %if %str(&title)^=%str() %then %do;
    title "&Title";
  %end;
  %else %do;
    title;
  %end;

  %if %str(&footnote)^=%str() %then %do;
    footnote j=c  h=0.7 " &footnote | Rotate (&Tilt &Roll &Rotate)";
  %end;
  %else %do;
    footnote;
  %end;

  %let DATTRMAP=;
  %if %str(&ATTRMAP)^=%str() %then %do; %let DATTRMAP=%str(dattrmap=&Attrmap); %end;
    proc sgplot data=data_all_proj nowall noborder aspect=1 noautolegend &DATTRMAP subpixel;  

  /*--WALL--*/
  %if &Walls=1 %then %do;
      polygon id=id x=xw y=yw / group=id attrid=Walls fill lineattrs=(color=lightgray) transparency=0.1;
  %end;

  /*--Grids--*/
  %if &GRIDS=1 %then %do; 
      vector x=xg2 y=yg2 / xorigin=xg yorigin=yg group=group2 noarrowheads attrid=Grids;
  %end;
 
  /*--Draw Needls and Shadows of Point on WALL--*/
  %if &Walls=1 %then %do;
    /*--Back wall shadow--*/
    %if &BackWallShadow=1 %then %do; 
	  /*--BackNeedls--*/ 
      %if &BackNeedles=1 %then %do; 
        vector x=xb y=yb / xorigin=xb2 yorigin=yb2 noarrowheads lineattrs=(color=gray) transparency=0.9; 
	  %end;
	  /*--BackPoints--*/
	  %if &BackPoints=1 %then %do; 
        %if &GROUP= %then %do;
          %if &SIZE= %then %do; 
            scatter x=xb y=yb / markerattrs=(symbol=circlefilled size=5)  transparency=&PointsTransparency;
	      %end;
	      %else %do;
            bubble x=xb y=yb size=&Size  / name='s' nomissinggroup dataskin=&DATASKIN bradiusmax=6 bradiusmin=1 transparency=&PointsTransparency;  
	      %end;
	    %end;
	    %else %do;
	      %if &SIZE= %then %do;
            scatter x=xb y=yb / markerattrs=(symbol=circlefilled size=5) group=&group transparency=&PointsTransparency;
          %end;
		  %else %do;
            bubble x=xb y=yb size=&Size  / group=&Group name='s' nomissinggroup dataskin=&DATASKIN bradiusmax=6 bradiusmin=1 transparency=&PointsTransparency;  
          %end;
        %end;
	  %end;
    %end;
    /*--Side wall shadow--*/
    %if &SideWallShadow=1 %then %do; 
      %if &SideNeedles=1 %then %do; 
        vector x=xs y=ys / xorigin=xs2 yorigin=ys2 noarrowheads lineattrs=(color=gray) transparency=&PointsTransparency;
	  %end;
	  %if &SidePoints=1 %then %do; 
	    %if &GROUP= %then %do;
	      %if &SIZE= %then %do;
            scatter x=xs y=ys / markerattrs=(symbol=circlefilled size=5)  transparency=&PointsTransparency;
          %end;
		  %else %do;
            bubble x=xs y=ys size=&Size  / name='s' nomissinggroup dataskin=&DATASKIN bradiusmax=6 bradiusmin=1 transparency=&PointsTransparency;  
		  %end;
	    %end;
	    %else %do;
          %if &SIZE= %then %do;
		    scatter x=xs y=ys / markerattrs=(symbol=circlefilled size=5) group=&group transparency=&PointsTransparency;
		  %end;
		  %else %do;
		    bubble x=xs y=ys size=&Size  / group=&Group name='s' nomissinggroup dataskin=&DATASKIN bradiusmax=6 bradiusmin=1 transparency=&PointsTransparency;  
		  %end;
        %end;
	  %end;
    %end;
    /*--Floor shadow--*/
    %if &FloorWallShadow=1 %then %do;  
      %if &FloorNeedles=1 %then %do;  
        vector x=xd y=yd / xorigin=xf yorigin=yf noarrowheads lineattrs=(color=gray) transparency=0.7 ;
	  %end;
	  %if &FloorPoints=1 %then %do;  
        %if &GROUP= %then %do;
	      %if &SIZE= %then %do;
            scatter x=xf y=yf / markerattrs=(symbol=circlefilled size=5)   transparency=&PointsTransparency;
		  %end;
		  %else %do;
		    bubble x=xf y=yf size=&Size  /  name='s' nomissinggroup dataskin=&DATASKIN bradiusmax=6 bradiusmin=1 transparency=&PointsTransparency;  
		  %end;
	    %end;
	    %else %do;
          %if &SIZE= %then %do;
		    scatter x=xf y=yf / markerattrs=(symbol=circlefilled size=5) group=&group transparency=&PointsTransparency;
		  %end;
		  %else %do;
            bubble x=xf y=yf size=&Size  / group=&Group name='s' nomissinggroup dataskin=&DATASKIN bradiusmax=6 bradiusmin=1 transparency=&PointsTransparency;  
          %end;
        %end;
	  %end;
    %end;
  %end;  
 
  /*--Data--*/
  %if &SIZE= %then %do;
    %if &GROUP= %then %do;
	  scatter x=xd y=yd /name='s' nomissinggroup dataskin=&DATASKIN markerattrs=(symbol=circlefilled size=6 color="&MARKERCOLOR") transparency=&DATATRANSPARENCY;
    %end;
    %else %do;
      scatter x=xd y=yd / group=&Group name='s' nomissinggroup dataskin=&DATASKIN markerattrs=(symbol=circlefilled size=6) transparency=&DATATRANSPARENCY ;
    %end;
  %end;
  %else %do;
    %if &GROUP= %then %do;
      bubble x=xd y=yd size=&Size  /  name='s' nomissinggroup dataskin=&DATASKIN bradiusmax=6 bradiusmin=1 transparency=&DATATRANSPARENCY;  
    %end;
    %else %do;
      bubble x=xd y=yd size=&Size  / group=&Group name='s' nomissinggroup dataskin=&DATASKIN bradiusmax=6 bradiusmin=1 transparency=&DATATRANSPARENCY;  
    %end;
  %end;
 
  /*--Axes--*/
  %if &AXES=1 %then %do;   	 
    vector x=xw2 y=yw2 / xorigin=xw yorigin=yw group=group noarrowheads attrid=Axes; 
    text x=xl y=yl text=lbx / position=bottom rotate=&LBLXROTATE;
    text x=xl y=yl text=lby / position=bottom rotate=&LBLYROTATE;
    text x=xl y=yl text=lbz / position=center rotate=&LBLZROTATE;

    /*--Range labels--*/
    %if &RANGES=1 %then %do; 
      text x=xl y=yl text=lbxmax / position=bottomleft rotate=&LBLXROTATE textattrs=( size=7pt );
      text x=xl y=yl text=lbymax / position=bottomleft rotate=&LBLYROTATE textattrs=( size=7pt );
      text x=xl y=yl text=lbzmax / position=center     rotate=&LBLZROTATE textattrs=( size=7pt );

      text x=xl y=yl text=lbxmin / position=bottom rotate=&LBLXROTATE textattrs=( size=7pt );
      text x=xl y=yl text=lbymin / position=bottom rotate=&LBLYROTATE textattrs=( size=7pt );
      text x=xl y=yl text=lbzmin / position=left   rotate=&LBLZROTATE textattrs=( size=7pt );  
    %end;
  %end;

  %if &LEGEND=1 %then %do;   	 
    keylegend 's' / autoitemsize;
  %end;
  xaxis  display=none offsetmin=0.05 offsetmax=0.05 min=-1.6 max=1.6;
  yaxis  display=none offsetmin=0.05 offsetmax=0.05 min=-1.6 max=1.6; 
run; 
%mend SG3D;

			  
/*--Define Attributes map for walls, axes, grids--*/
data attrmap;
  length ID $ 9 fillcolor $ 10 linecolor $ 10 linepattern $ 10;
  input id $ value $10-20 fillcolor $ linecolor $ linepattern $;
  datalines;
Walls    Bottom     cxF9F9F9   cxdfdfdf   Solid
Walls    Back       cxE7E7E7   cxefefef   Solid
Walls    Right      cxF0F0F0   cxffffff   Solid
Axes     D          white      black      Solid
Axes     L          white      gray       ShortDash
Grids    Bottom     cxdfdfdf   cxdfdfdf   Solid 
Grids    Back       cxefefef   cxdfdfdf   Solid
Grids    Right      cxffffff   cxdfdfdf   Solid
run; 
