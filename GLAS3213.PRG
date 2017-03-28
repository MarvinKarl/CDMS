/*
PROGRAM     : GLAS3213.PRG
DESCRIPTION : POSTED PER JOURNAL VOUCHER
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 14, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

private aBrAcs:={}, cVCateg:='JV', cHdDbf:='GLTRANHD', cDtDbf:='GLTRANDT', lPosted:=.t.

if !OpenBrRprt()
   return
endif

VchrNo('1',17)
return