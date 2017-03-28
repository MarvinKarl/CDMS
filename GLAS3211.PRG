/*
PROGRAM     : GLAS3211.PRG
DESCRIPTION : POSTED JOURNAL VOUCHER SUMMARY
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 13, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

#include "INKEY.CH"

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

OptionBar('ESC-Exit')
if len(aBrAcs) == 1 .or. right(aBrAcs[nBrAcsCnt],3) <> '000'
   GLTRANHD->(dbseek(right(aBrAcs[nBrAcsCnt],3)+'1'+dtos(dPeriodFrom)))
   if GLTRANHD->(eof())
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr(right(aBrAcs[nBrAcsCnt],3)+' '+alltrim(left(aBrAcs[nBrAcsCnt],30))+' has no JV Transaction. Press Any Key.',72) color 'w'
	  close databases
	  inkey(0)
	  return
   else
	  if GLTRANHD->brcode == right(aBrAcs[nBrAcsCnt],3) .and. GLTRANHD->trancode == '1' .and.;
	     GLTRANHD->trandate >= dPeriodFrom .and. GLTRANHD->trandate <= dPeriodTo
		 ReportPrint('PstdJVSum()')
	  else
		 @24,0 say ' ERROR: ' color 'r+'
		 @24,8 say padr(right(aBrAcs[nBrAcsCnt],3)+' '+alltrim(left(aBrAcs[nBrAcsCnt],30))+' has no JV Transaction. Press Any Key.',72) color 'w'
		 close databases
		 inkey(0)
		 return
	  endif
  endif
else
   ReportPrint('PstdJVSum()')
endif
close databases
return

************************
function PeriodCov(nRow)
************************
local cScrn:=savescreen(,,,)

OptionBar('ESC-Exit')
if len(aBrAcs) > 1
   @nRow-1,19,nRow+1,60 box 'ÃÄ´³ÙÄÀ³ ' color 'w+/n'
   @nRow,21 say 'Period Coverage' color 'w+/n'
   @nRow,48 say '-' color 'n/w'
   @nRow,38 get dPeriodFrom valid !empty(dPeriodFrom)
   @nRow,49 get dPeriodTo valid !empty(dPeriodTo) .and. dPeriodTo>=dPeriodFrom .and. dPeriodTo<=date()
else
   @nRow-3,19,nRow-1,60 box 'ÚÄ¿³ÙÄÀ³ ' color 'w+/n'
   @nRow-2,21 say 'Period Coverage' color 'w+/n'
   @nRow-2,48 say '-' color 'n/w'
   @nRow-2,38 get dPeriodFrom valid !empty(dPeriodFrom)
   @nRow-2,49 get dPeriodTo valid !empty(dPeriodTo) .and. dPeriodTo>=dPeriodFrom .and. dPeriodTo<=date()
endif
setcursor(1)
read
setcursor(0)

if lastkey() == K_ESC
   restscreen(,,,,cScrn)
   return .f.
endif
return .t.

********************
function PstdJVSum()
********************
private cVCateg:='JV'

setprc(0,0)
PstdSumHdr()
PstdSumDt('1')
return

*********************
function PstdSumHdr()
*********************
@0,2 say chr(18)+chr(27)+chr(77)     // chr(18)-cancel 17cpi; chr(80)-10cpi; chr(77)-12cpi; chr(15)-17cpi
@1,2 say padc(chr(27)+chr(69)+gCOMPANY,96)     // bold on
@2,2 say padc(gSYS_NAME+' ('+cSysCode+')',96)

@4,2 say padc(iif(cVCateg=='JV','JOURNAL ',iif(cVCateg=='DV','DISBURSEMENT ',''))+'VOUCHER SUMMARY - '+alltrim(left(aBrAcs[nBrAcsCnt],30)),96)
@5,2 say padc('For the Period of '+cmonth(dPeriodFrom)+' '+padl(day(dPeriodFrom),2,'0')+', '+padl(year(dPeriodFrom),4)+' - '+;
               cmonth(dPeriodTo)+' '+padl(day(dPeriodTo),2,'0')+', '+padl(year(dPeriodTo),4)+chr(27)+chr(70),96)     // bold off

@7,2 say iif(cVCateg=='DV',chr(27)+chr(80)+chr(15),'')+replicate('Ä',iif(cVCateg=='DV',138,97))     // if DV, 10 cpi condensed
do case
   case cVCateg == 'JV'
        @8,2 say '    JV N§      JV Date        JV Type            Amount           Prepared          Approved     '
   case cVCateg == 'DV'
		@8,2 say '    DV N§      DV Date              Bank                               Check N§           Amount           Prepared          Approved     '
endcase
@9,2 say replicate('Ä',iif(cVCateg=='DV',138,97))
return

*****************************
function PstdSumDt(cTranCode)
*****************************
local nVTHdCnt:=0
private nPage:=1

if len(aBrAcs) == 1 .or. right(aBrAcs[nBrAcsCnt],3) <> '000'
   do while !GLTRANHD->(eof()) .and. GLTRANHD->brcode == right(aBrAcs[nBrAcsCnt],3) .and. GLTRANHD->trancode == cTranCode .and.;
            GLTRANHD->trandate >= dPeriodFrom .and. GLTRANHD->trandate <= dPeriodTo
	  PstdSumDt2()
	  nVTHdCnt := nVTHdCnt + 1
	  GLTRANHD->(dbskip())
   enddo
else
   for nCnt := 1 to len(aBrAcs)
	   GLTRANHD->(dbseek(right(aBrAcs[nCnt],3)+cTranCode+dtos(dPeriodFrom)))
	   do while !GLTRANHD->(eof()) .and. GLTRANHD->brcode == right(aBrAcs[nCnt],3) .and. GLTRANHD->trancode == cTranCode .and.;
	            GLTRANHD->trandate >= dPeriodFrom .and. GLTRANHD->trandate <= dPeriodTo
		  PstdSumDt2()
		  nVTHdCnt := nVTHdCnt + 1
		  GLTRANHD->(dbskip())
	   enddo
   next nCnt
endif
@prow()+1,2 say alltrim(str(nVTHdCnt))+' Record'+iif(nVTHdCnt>1,'s','')
if prow() < 59
   if cVCateg == 'DV'
      @prow(),pcol() say chr(18)+chr(27)+chr(77)
   endif
   @59,2 say replicate('Ä',96)
   @60,2 say chr(27)+chr(15)+cUserName+' '+dtoc(date())+' '+TimeAsAMPM(left(time(),5))+' '+procname(6)     // condensed on
   @60,159-len(alltrim(str(nPage))) say 'Page '+alltrim(str(nPage))+chr(18)     // condensed off
endif
eject
return

****************************
static function PstdSumDt2()
****************************
local cJVTypeName, cParticlr

do case
   case cVCateg == 'JV'
        cJVTypeName := iif(GLTRANHD->adjmntcode=='1','SOLD TO CURRENT ',iif(GLTRANHD->adjmntcode=='2','CURRENT TO PDR  ',;
		               iif(GLTRANHD->adjmntcode=='3','CURRENT TO LEGAL',iif(GLTRANHD->adjmntcode=='4','PDR TO LEGAL    ',;
					   iif(GLTRANHD->adjmntcode=='5','PDR TO CURRENT  ',iif(GLTRANHD->adjmntcode=='6','LEGAL TO CURRENT',;
					   iif(GLTRANHD->adjmntcode=='7','NORMAL ENTRY    ',iif(GLTRANHD->adjmntcode=='8','RETURNED CHECK  ',;
					   iif(GLTRANHD->adjmntcode=='9','SOLD RECEIVABLES',iif(GLTRANHD->adjmntcode=='A','CURRENT TO AR   ',space(16)))))))))))
		@prow()+1,2 say GLTRANHD->brcode+'-'+GLTRANHD->trnumber+'  '+dtoc(GLTRANHD->trandate)+'  '+cJVTypeName+'  '+;
		                trans(GLTRANHD->tramount,'@Z 9,999,999,999.99')+'  '+GLTRANHD->usercode+' '+dtoc(GLTRANHD->post_date)+'  '+;
						GLTRANHD->aprvuser+dtoc(GLTRANHD->aprvdate)
   case cVCateg == 'DV'
        BANKACCT->(dbseek(GLTRANHD->brtrbank+GLTRANHD->trbank))
		@prow()+1,2 say GLTRANHD->brcode+'-'+GLTRANHD->trnumber+'  '+dtoc(GLTRANHD->trandate)+'  '+BANKACCT->bankname+'  '+GLTRANHD->trcheck+'  '+;
		                trans(GLTRANHD->tramount,'@Z 9,999,999,999.99')+'  '+GLTRANHD->usercode+' '+dtoc(GLTRANHD->post_date)+'  '+;
						GLTRANHD->aprvuser+dtoc(GLTRANHD->aprvdate)
		@prow()+1,16 say 'Payee : '+GLTRANHD->trpayee
endcase

if GLTRANHD->trantype == '3'
   @prow()+1,16 say 'C A N C E L L E D - '+GLTRANHD->cancelrmk
endif
for nCnt1 := 1 to 6
    cParticlr := 'partix'+alltrim(str(nCnt1))
	if !empty(GLTRANHD->&cParticlr)
	   @prow()+1,16 say GLTRANHD->&cParticlr
	   if prow() >= 55
	      SumNxtPg()
		  PstdSumHdr()
	   endif
	else
	   exit
	endif
next nCnt1

do case
   case prow() <> 9
        @prow()+1,2 say ' '
   case prow() >= 55
        SumNxtPg()
		PstdSumHdr()
endcase
return