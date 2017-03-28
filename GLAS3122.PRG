/*
PROGRAM     : GLAS3122.PRG
DESCRIPTION : UNPOSTED PER DISBURSEMENT VOUCHER
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 10, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

private aBrAcs:={}, cVCateg:='DV', cHdDbf:='TRANHEAD', cDtDbf:='TRANDTLS', lPosted:=.f.

if !OpenBrRprt()
   return
endif

VchrNo('2',16)
return

****************
function PerDV()
****************
do while !(cTmpHd)->(eof())
   if (cTmpDt)->(dbseek((cTmpHd)->brcode+(cTmpHd)->trnumber))
      setprc(0,0)
	  PerVHdr()
	  @8,2 say chr(27)+chr(69)+' Payee: '+(cTmpHd)->trpayee     // bold on
	  @9,2 say 'Amount: '+alltrim(trans((cTmpHd)->tramount,'@Z 9,999,999,999.99'))+chr(27)+chr(70)     // bold off
	  PerVDtls(11)
   endif
   (cTmpHd)->(dbskip())
enddo
return