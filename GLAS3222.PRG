/*
PROGRAM     : GLAS3222.PRG
DESCRIPTION : POSTED PER DISBURSEMENT VOUCHER
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 14, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

private aBrAcs:={}, cVCateg:='DV', cHdDbf:='GLTRANHD', cDtDbf:='GLTRANDT', lPosted:=.t.

if !OpenBrRprt()
   return
endif

VchrNo('2',17)
return