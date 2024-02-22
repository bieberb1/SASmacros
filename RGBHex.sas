%macro RGBHex(rr,gg,bb);
    %sysfunc(compress(CX%sysfunc(putn(&rr,hex2.))
    %sysfunc(putn(&gg,hex2.))
    %sysfunc(putn(&bb,hex2.))))
%mend RGBHex;