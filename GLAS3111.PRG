/*
PROGRAM     : GLAS3111.PRG
DESCRIPTION : UNPOSTED JOURNAL VOUCHER SUMMARY
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 05, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

private aBrAcs:={},nBrAcsCnt:=1

if !OpenBrRprt()
   return
endif

if !SelectBr(15)
   return
endif

if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
   return
endif
set index to &g_GLAS_Path\TRANCODE

OptionBar('ESC-Exit')
if len(aBrAcs) == 1 .or. right(aBrAcs[nBrAcsCnt],3) <> '000'
   if !TRANHEAD->(dbseek(right(aBrAcs[nBrAcsCnt],3)+'1'))
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr(right(aBrAcs[nBrAcsCnt],3)+' '+alltrim(left(aBrAcs[nBrAcsCnt],30))+' has no JV Transaction. Press Any Key.',72) color 'w'
	  close databases
	  inkey(0)
	  return
   else
	  ReportPrint('UnpJVSum()')
  endif
else
   ReportPrint('UnpJVSum()')
endif
close databases
return

*********************
function OpenBrRprt()
*********************
if left(cOrigBr,3) == '800'
   if !netuse('&g_RFM_Path\BRANCHES',.f.,5)
	  return .f.
   endif
   set index to &g_RFM_Path\BRANCHES
   
   if !netuse('&g_SMS_Path\USERBRCH',.f.,5)
      BRANCHES->(dbclosearea())
	  return .f.
   endif
   set index to &g_SMS_Path\USERBRCH
   
   if USERBRCH->(dbseek(str(nUserId,len(str(USERBRCH->userid)))))
	  //USERBRCH->(dbskip())  // restore this if remove USERBRCH->defaultbr
	  //if USERBRCH->userid == nUserId
	     //aadd(aBrAcs, padr('All',30)+'000')
	  //endif
	  //USERBRCH->(dbskip(-1))
	  do while !USERBRCH->(eof()) .and. USERBRCH->userid == nUserId
	     if USERBRCH->defaultbr  // remove this - if head office accounting will create voucher/s for other branch/es
		    if !BRANCHES->(dbseek(USERBRCH->brcode))
			   @24,0 say ' ERROR: ' color 'r+'
			   @24,8 say padr(USERBRCH->brcode+' has no Branch Name. Press Any Key.',72) color 'w'
			   close databases
			   inkey(0)
			   return .f.
			endif
			
			aadd(aBrAcs, BRANCHES->brname+USERBRCH->brcode)
			exit  // remove this
		 endif  // remove this
		 USERBRCH->(dbskip())
	  enddo
   endif
   BRANCHES->(dbclosearea())
   USERBRCH->(dbclosearea())
else
   aadd(aBrAcs, padr(right(cSelectBr,len(cSelectBr)-4),30)+left(cSelectBr,3))
endif
return .t.

***********************
function SelectBr(nRow)
***********************
OptionBar('ESC-Exit')
if len(aBrAcs) > 1
   @nRow-1,19,nRow+1,60 box 'ÚÄ¿³ÙÄÀ³ ' color 'w+/n'
   @nRow,21 say 'Branch' color 'w+/n'
   @nRow,58 say chr(23) color 'n/w'
   nBrAcsCnt := achoice(nRow,28,nRow,57,aBrAcs,,'AchUDF',nBrAcsCnt)
   if nBrAcsCnt == 0
      return .f.
   endif
   @nRow,28 say left(aBrAcs[nBrAcsCnt],30)+' ' color 'n/w'
endif
return .t.

*******************
function UnpJVSum()
*******************
private cVCateg:='JV'

setprc(0,0)
UnpSumHdr()
UnpSumDt('1')
return

********************
function UnpSumHdr()
********************
@0,2 say chr(18)+chr(27)+chr(77)     // chr(18)-cancel 17cpi; chr(80)-10cpi; chr(77)-12cpi; chr(15)-17cpi
@1,2 say padc(chr(27)+chr(69)+gCOMPANY,96)     // bold on
@2,2 say padc(gSYS_NAME+' ('+cSysCode+')',96)

@4,2 say padc('UNPOSTED '+iif(cVCateg=='JV','JOURNAL ',iif(cVCateg=='DV','DISBURSEMENT ',''))+'VOUCHER SUMMARY - '+alltrim(left(aBrAcs[nBrAcsCnt],30)),96)
@5,2 say padc('As of '+cmonth(date())+' '+padl(day(date()),2,'0')+', '+padl(year(date()),4)+chr(27)+chr(70),96)     // bold off

@7,2 say iif(cVCateg=='DV',chr(27)+chr(80)+chr(15),'')+replicate('Ä',iif(cVCateg=='DV',137,96))     // if DV, 10 cpi condensed
do case
   case cVCateg == 'JV'
        @8,2 say '    JV N§      JV Date        JV Type            Amount           Prepared        JV Status   '
   case cVCateg == 'DV'
		@8,2 say '    DV N§      DV Date              Bank                               Check N§           Amount           Prepared        DV Status   '
endcase
@9,2 say replicate('Ä',iif(cVCateg=='DV',137,96))
return

****************************
function UnpSumDt(cTranCode)
****************************
local nVTHdCnt:=0
private nPage:=1

if len(aBrAcs) == 1 .or. right(aBrAcs[nBrAcsCnt],3) <> '000'
   do while !TRANHEAD->(eof()) .and. TRANHEAD->brcode == right(aBrAcs[nBrAcsCnt],3) .and. TRANHEAD->trancode == cTranCode
      UnpSumDt2()
	  nVTHdCnt := nVTHdCnt + 1
	  TRANHEAD->(dbskip())
   enddo
else
   for nCnt := 1 to len(aBrAcs)
	   if TRANHEAD->(dbseek(right(aBrAcs[nCnt],3)+cTranCode))
		  do while !TRANHEAD->(eof()) .and. TRANHEAD->brcode == right(aBrAcs[nCnt],3) .and. TRANHEAD->trancode == cTranCode
			 UnpSumDt2()
			 nVTHdCnt := nVTHdCnt + 1
			 TRANHEAD->(dbskip())
		  enddo
	   endif
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

***************************
static function UnpSumDt2()
***************************
local cVForAprvl, cJVTypeName, cParticlr

cVForAprvl := iif(TRANHEAD->foraprvl=='E','ENCODED',iif(TRANHEAD->foraprvl=='F','FOR CHECKING',;
              iif(TRANHEAD->foraprvl=='C','CHECKED-'+alltrim(TRANHEAD->chckuser),iif(TRANHEAD->foraprvl=='R','RETURNED',''))))
do case
   case cVCateg == 'JV'
        cJVTypeName := iif(TRANHEAD->adjmntcode=='1','SOLD TO CURRENT ',iif(TRANHEAD->adjmntcode=='2','CURRENT TO PDR  ',;
		               iif(TRANHEAD->adjmntcode=='3','CURRENT TO LEGAL',iif(TRANHEAD->adjmntcode=='4','PDR TO LEGAL    ',;
					   iif(TRANHEAD->adjmntcode=='5','PDR TO CURRENT  ',iif(TRANHEAD->adjmntcode=='6','LEGAL TO CURRENT',;
					   iif(TRANHEAD->adjmntcode=='7','NORMAL ENTRY    ',iif(TRANHEAD->adjmntcode=='8','RETURNED CHECK  ',;
					   iif(TRANHEAD->adjmntcode=='9','SOLD RECEIVABLES',iif(TRANHEAD->adjmntcode=='A','CURRENT TO AR   ',space(16)))))))))))
		@prow()+1,2 say TRANHEAD->brcode+'-'+TRANHEAD->trnumber+'  '+dtoc(TRANHEAD->trandate)+'  '+cJVTypeName+'  '+;
		                trans(TRANHEAD->tramount,'@Z 9,999,999,999.99')+'  '+TRANHEAD->usercode+' '+dtoc(TRANHEAD->post_date)+'  '+cVForAprvl
   case cVCateg == 'DV'
        BANKACCT->(dbseek(TRANHEAD->brtrbank+TRANHEAD->trbank))
		@prow()+1,2 say TRANHEAD->brcode+'-'+TRANHEAD->trnumber+'  '+dtoc(TRANHEAD->trandate)+'  '+BANKACCT->bankname+'  '+TRANHEAD->trcheck+'  '+;
		                trans(TRANHEAD->tramount,'@Z 9,999,999,999.99')+'  '+TRANHEAD->usercode+' '+dtoc(TRANHEAD->post_date)+'  '+cVForAprvl
		@prow()+1,16 say 'Payee : '+TRANHEAD->trpayee
endcase

if TRANHEAD->trantype == '3'
   @prow()+1,16 say 'C A N C E L L E D - '+TRANHEAD->cancelrmk
endif
for nCnt1 := 1 to 6
    cParticlr := 'partix'+alltrim(str(nCnt1))
	if !empty(TRANHEAD->&cParticlr)
	   @prow()+1,16 say TRANHEAD->&cParticlr
	   if prow() >= 55
	      SumNxtPg()
		  UnpSumHdr()
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
		UnpSumHdr()
endcase
return

*******************
function SumNxtPg()
*******************
if cVCateg == 'DV'
   @prow(),pcol() say chr(18)+chr(27)+chr(77)
endif
@prow()+2,2 say padc(' Next  Page ',96,'Ä')
@prow()+1,2 say chr(27)+chr(15)+cUserName+' '+dtoc(date())+' '+TimeAsAMPM(left(time(),5))+' '+procname(8)     // condensed on
@prow(),159-len(alltrim(str(nPage))) say 'Page '+alltrim(str(nPage))+chr(18)     // condensed off
nPage := nPage + 1
eject
return