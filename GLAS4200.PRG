/*
PROGRAM     : GLAS4200.PRG
DESCRIPTION : CHANGE DV TRANSACTION DATE
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 20, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

private cVBrCode:=left(cSelectBr,3), aBrAcs:={}, nSelBrCnt:=1, nBrAcsCnt, dVDate

if !OpenBrEntry('DV')
   return
endif

nBrAcsCnt := nSelBrCnt
if !SelectBr(12)
   return
endif

OptionBar('ESC-Exit')
dVDate := ctod(right(aBrAcs[nBrAcsCnt],10))
ChngeVDate('DV')
return