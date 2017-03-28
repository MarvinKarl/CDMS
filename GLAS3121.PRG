/*
PROGRAM     : GLAS3121.PRG
DESCRIPTION : UNPOSTED DISBURSEMENT VOUCHER SUMMARY
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 10, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

private aBrAcs:={},nBrAcsCnt:=1

if !OpenBrRprt()
   return
endif

if !SelectBr(16)
   return
endif

if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
   return
endif
set index to &g_GLAS_Path\TRANCODE

if !netuse('&g_RFM_Path\BANKACCT',.f.,5)
   return
endif
set index to &g_RFM_Path\BANKACCT

OptionBar('ESC-Exit')
if len(aBrAcs) == 1 .or. right(aBrAcs[nBrAcsCnt],3) <> '000'
   if !TRANHEAD->(dbseek(right(aBrAcs[nBrAcsCnt],3)+'2'))
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr(right(aBrAcs[nBrAcsCnt],3)+' '+alltrim(left(aBrAcs[nBrAcsCnt],30))+' has no DV Transaction. Press Any Key.',72) color 'w'
	  close databases
	  inkey(0)
	  return
   else
	  ReportPrint('UnpDVSum()')
  endif
else
   ReportPrint('UnpDVSum()')
endif
close databases
return

*******************
function UnpDVSum()
*******************
private cVCateg:='DV'

setprc(0,0)
UnpSumHdr()
UnpSumDt('2')
return