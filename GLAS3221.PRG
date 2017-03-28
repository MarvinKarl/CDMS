/*
PROGRAM     : GLAS3221.PRG
DESCRIPTION : POSTED DISBURSEMENT VOUCHER SUMMARY
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 14, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

private aBrAcs:={},nBrAcsCnt:=1, dPeriodFrom:=date(), dPeriodTo:=date()

if !OpenBrRprt()
   return
endif

if !SelectBr(17)
   return
endif

if !PeriodCov(19)
   return
endif

if !netuse('&g_GLAS_Path\GLTRANHD',.f.,5)
   return
endif
set index to &g_GLAS_Path\GLHDBCDN

if !netuse('&g_RFM_Path\BANKACCT',.f.,5)
   return
endif
set index to &g_RFM_Path\BANKACCT

OptionBar('ESC-Exit')
if len(aBrAcs) == 1 .or. right(aBrAcs[nBrAcsCnt],3) <> '000'
   GLTRANHD->(dbseek(right(aBrAcs[nBrAcsCnt],3)+'2'+dtos(dPeriodFrom)))
   if GLTRANHD->(eof())
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr(right(aBrAcs[nBrAcsCnt],3)+' '+alltrim(left(aBrAcs[nBrAcsCnt],30))+' has no DV Transaction. Press Any Key.',72) color 'w'
	  close databases
	  inkey(0)
	  return
   else
	  if GLTRANHD->brcode == right(aBrAcs[nBrAcsCnt],3) .and. GLTRANHD->trancode == '2' .and.;
	     GLTRANHD->trandate >= dPeriodFrom .and. GLTRANHD->trandate <= dPeriodTo
		 ReportPrint('PstdDVSum()')
	  else
		 @24,0 say ' ERROR: ' color 'r+'
		 @24,8 say padr(right(aBrAcs[nBrAcsCnt],3)+' '+alltrim(left(aBrAcs[nBrAcsCnt],30))+' has no DV Transaction. Press Any Key.',72) color 'w'
		 close databases
		 inkey(0)
		 return
	  endif
  endif
else
   ReportPrint('PstdDVSum()')
endif
close databases
return

********************
function PstdDVSum()
********************
private cVCateg:='DV'

setprc(0,0)
PstdSumHdr()
PstdSumDt('2')
return