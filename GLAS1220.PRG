/*
PROGRAM     : GLAS1220.PRG
DESCRIPTION : DISBURSEMENT VOUCHER ENTRY PROGRAM
AUTHOR      : ERLACHICA
CREATED     : AUGUST 12, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

#include "INKEY.CH"
#include "LOFL.CH"

local cScrn
private aBrAcs:={}, nSelBrCnt:=1, dVTranDate,;
        cVBrCode:=left(cSelectBr,3), cStatCode, cDVNumber, dDVDate, cPayee, nAmount, cCheckNo, cBankBrCode,;
        cBankCode, cBankGLCode, cParticlr1, cParticlr2, cParticlr3, cParticlr4, cParticlr5, cParticlr6,;
		cPreprdBy, cForAprvl
private aTranDtls:={}, nTDtDebit:=0, nTDtCredit:=0, aOldVal:={}
private lTabGLDtls, aGLDtls:={}, nGLDtlsCnt:=0, nGLDtDebit, nGLDtCredit, cGLDtScrn, cGLNameScrn, lDVSaved:=.f., nTopRow:=10, nMaxRLineNo:=12
private aBankBr:={}, nBankBrCnt:=0, aBank:={}, nBankCnt:=0, aDefltBank:={}, aGL:={}, nGLCnt:=0, aColumn:={'DEBIT ','CREDIT'}
private lRFPModule:=.f., lAddRFPUDF:=.f., cBnkGLCd

DispDVScrn()

if cVBrCode <> '800'
   @24,0 say ' ERROR: ' color 'r+'
   @24,8 say padr('GLAS is in '+alltrim(cSelectBr)+'. Press Any Key.',72) color 'w'
   inkey(0)
   return
endif

if !OpenBrEntry('DV')
   return
endif

if !netuse('&g_RFM_Path\BRANCHES',.f.,5)
   return
endif
set index to &g_RFM_Path\BRNAME

do while !BRANCHES->(eof())
   aadd(aBankBr, BRANCHES->brname+'  '+BRANCHES->brcode)
   BRANCHES->(dbskip())
enddo
BRANCHES->(dbclosearea())

if !netuse('&g_RFM_Path\BANKACCT',.f.,5)
   return
endif
set index to &g_RFM_Path\BANKNAME

do while !BANKACCT->(eof())
   if BANKACCT->brcode == left(cOrigBr,3)
      aadd(aDefltBank, BANKACCT->bankname+'  '+BANKACCT->bankcode+BANKACCT->brcode+BANKACCT->glcode)
   endif
   BANKACCT->(dbskip())
enddo
aBank := aclone(aDefltBank)
BANKACCT->(dbclosearea())

if len(aDefltBank) == 0
   @24,0 say ' ERROR: ' color 'r+'
   @24,8 say padr('No Bank Account found. Press Any Key.',72) color 'w'
   inkey(0)
   return
endif

if !OpenTmpGL()
   return
endif

OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+'F4-Search  ESC-Exit')
cGLDtScrn := savescreen(18,0,22,79)
do while .t.
   inkey(0)
   do case
      case lastkey() == K_INS .and. 'ADD'$cModAccess
	       DVAddEdit('A')
	  case lastkey() == K_F2 .and. 'EDIT'$cModAccess .and. cStatCode == '1' .and. left(cPreprdBy,3) <> 'SG1' .and. cForAprvl$'ER'
	       DVAddEdit('E')
	  case lastkey() == K_F4
	       VSearch('DV')
	  case lastkey() == K_F6 .and. 'CANCEL'$cModAccess .and. cStatCode == '1' .and. left(cPreprdBy,3) <> 'SG1' .and. cForAprvl$'ER'
	       VCancel('DV',11,.f.)
	  case lastkey() == K_F8 .and. 'EDIT'$cModAccess .and. left(cPreprdBy,3) <> 'SG1' .and. cForAprvl$'ER'
	       VForChckng('DV')
	  case lastkey() == K_TAB .and. cStatCode == '1'
	       setcolor('w+/rb,n/w,,,w+/rb')
		   if left(cPreprdBy,3) == 'SG1' .or. !cForAprvl$'ER'
		      cGLNameScrn := savescreen(23,1,23,78)
			  if !empty(substr(aTranDtls[1],79,22))
			     @23,1 say ' Full GL Name: '+substr(aTranDtls[1],17,28)+alltrim(substr(aTranDtls[1],79,22))+' ' color 'n+/rb'
			  endif
			  OptionBar('TAB-Go Back')
			  achoice(18,1,20,78,aTranDtls,,'VTabUDF')
		   else
			  OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
			  
			  lTabGLDtls  := .t.
			  cScrn       := savescreen(,,,)
			  aGLDtls     := aclone(aTranDtls)
			  nGLDtlsCnt  := 0
			  nGLDtDebit  := nTDtDebit
			  nGLDtCredit := nTDtCredit
			  
			  do while .t.
			     if achoice(18,1,20,78,aGLDtls,,'DVGLDtUDF',nGLDtlsCnt) == 0
				    if lDVSaved
					   lDVSaved := .f.
					else
					   restscreen(,,,,cScrn)
					endif
					exit
				 endif
				 restscreen(18,0,22,79,cGLDtScrn)
				 @22,46 say trans(nGLDtDebit, '@Z 9,999,999,999.99')
				 @22,63 say trans(nGLDtCredit, '@Z 9,999,999,999.99')
			  enddo
		   endif
		   OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+;
		             iif('EDIT'$cModAccess .and. cStatCode=='1' .and. left(cPreprdBy,3)<>'SG1' .and. cForAprvl$'ER','F2-Edit  ','')+'F4-Search  '+;
					 iif('CANCEL'$cModAccess .and. cStatCode=='1' .and. left(cPreprdBy,3)<>'SG1' .and. cForAprvl$'ER','F6-Cancel  ','')+;
					 iif('EDIT'$cModAccess .and. left(cPreprdBy,3)<>'SG1' .and. cForAprvl$'ER','F8-For Checking  ','')+;
					 iif(cStatCode=='1','TAB-GL Entry  ','')+'ESC-Exit')
	  case lastkey() == K_ESC
	       exit
   endcase
enddo
close databases
return

*********************
function DispDVScrn()
*********************
@3,0,14,79 box 'ÚÄ¿³³ ³³ ' color 'n/w'
@4,1  say '      DV N§:                                DV Date:' color 'n/w'
@5,1  say '      Payee:' color 'n/w'
@6,1  say '     Amount:                               Check N§:' color 'n/w'
@7,1  say 'Bank Branch:' color 'n/w'
@8,1  say '       Bank:' color 'n/w'
@9,1  say 'Particulars:' color 'n/w'
@10,1 say '           :' color 'n/w'
@11,1 say '           :' color 'n/w'
@12,1 say '           :' color 'n/w'
@13,1 say '           :' color 'n/w'
@14,1 say '           :' color 'n/w'
DispDVScr2()
return

*********************
function DispDVScr2()
*********************
setcolor('w+/rb,n/w,,,w+/rb')
@15,0 say 'Ã GL Entry ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
@16,0 say '³                GL Account                  ³      Debit     ³     Credit     ³'
@17,0 say 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
@18,0 say '³                                            ³                ³                ³'
@19,0 say '³                                            ³                ³                ³'
@20,0 say '³                                            ³                ³                ³'
@21,0 say 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
@22,0 say '³                                       Total³                ³                ³'
@23,0 say 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
return

***************************
function DispDVDtls(lTDtls)
***************************
local cBankName, cCheckdBy, cCancelRmk

if !lRFPModule
   nBankBrCnt := ascan(aBankBr,{|x| right(x,3)==TRANHEAD->brtrbank})
endif

if !netuse('&g_RFM_Path\BANKACCT',.f.,5)
   return
endif
set index to &g_RFM_Path\BANKACCT
BANKACCT->(dbseek(TRANHEAD->brtrbank+TRANHEAD->trbank))

cStatCode   := TRANHEAD->trantype
cDVNumber   := TRANHEAD->brcode+'-'+TRANHEAD->trnumber
dDVDate     := TRANHEAD->trandate
cPayee      := TRANHEAD->trpayee
nAmount     := TRANHEAD->tramount
cCheckNo    := TRANHEAD->trcheck
cBankBrCode := TRANHEAD->brtrbank
cBankCode   := TRANHEAD->trbank
cBankName   := BANKACCT->bankname
cParticlr1  := TRANHEAD->partix1
cParticlr2  := TRANHEAD->partix2
cParticlr3  := TRANHEAD->partix3
cParticlr4  := TRANHEAD->partix4
if !lRFPModule
   cBankGLCode := BANKACCT->glcode
   cBnkGLCd    := BANKACCT->glcode	// ADDED ESV 10.25.2016 to use to other module (GLAS1100.PRG)
   cParticlr5  := TRANHEAD->partix5
   cParticlr6  := TRANHEAD->partix6
endif
cPreprdBy   := TRANHEAD->usercode
cCheckdBy   := TRANHEAD->chckuser
cForAprvl   := TRANHEAD->foraprvl
cCancelRmk  := TRANHEAD->cancelrmk
BANKACCT->(dbclosearea())
TRANHEAD->(dbclosearea())

@4,14  say cDVNumber color 'b/w'
@4,27  say iif(lRFPModule .and. left(cPreprdBy,3)<>'SG1',' *OTHER* ',iif(!lRFPModule .and. left(cPreprdBy,3)=='SG1',' *RFP* ','')) color 'w+/b'
@4,54  say dDVDate color 'r/w'
@5,14  say left(cPayee,65) color 'r/w'
@6,14  say alltrim(trans(nAmount,'@Z 9,999,999,999.99')) color 'r/w'
@6,54  say cCheckNo color 'r/w'
@7,14  say cBankBrCode color 'r/w'
@7,18  say if(lRFPModule .and. left(cPreprdBy,3)=='SG1',left(aBrAcs[nSelBrCnt],30),iif(lRFPModule .and. left(cPreprdBy,3)<>'SG1','',left(aBankBr[nBankBrCnt],30))) color 'gr/w'
@8,14  say cBankCode color 'r/w'
@8,18  say cBankName color 'gr/w'
@9,14  say left(cParticlr1,65) color 'r/w'
@10,14 say left(cParticlr2,65) color 'r/w'
@11,14 say left(cParticlr3,65) color 'r/w'
@12,14 say left(cParticlr4,65) color 'r/w'
if !lRFPModule
   @13,14 say left(cParticlr5,65) color 'r/w'
   @14,14 say left(cParticlr6,65) color 'r/w'
endif

if cStatCode == '3'
   @23,1 say ' Cancelled: '+alltrim(cCancelRmk)+' ' color 'w+/g'
endif

do case
   case cForAprvl == 'F'
        @3,65 say ' FOR CHECKING ' color 'w+/r'
   case cForAprvl == 'C'
        @3,69-len(alltrim(cCheckdBy)) say ' CHECKED-'+alltrim(cCheckdBy)+' ' color 'w+/r'
   case cForAprvl == 'R'
        if !netuse('&g_GLAS_Path\THDAPRVL',.f.,5)
		   return
		endif
		set index to &g_GLAS_Path\THDAPRVL
		
		if THDAPRVL->(dbseek(strtran(cDVNumber,'-','')))
		   do while !THDAPRVL->(eof()) .and. THDAPRVL->brcode+THDAPRVL->trnumber == strtran(cDVNumber,'-','')
		      THDAPRVL->(dbskip())
		   enddo
		   THDAPRVL->(dbskip(-1))
		   @23,1 say ' Returned: '+alltrim(THDAPRVL->aprvrmk)+' ' color 'w+/g'
		endif
		THDAPRVL->(dbclosearea())
endcase

if lTDtls
   if cStatCode == '1'
      (gTmpGL)->(dbsetorder(1))
	  if TRANDTLS->(dbseek(strtran(cDVNumber,'-','')))
	     do while !TRANDTLS->(eof()) .and. TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cDVNumber,'-','')
		    if (gTmpGL)->(dbseek(TRANDTLS->glcode))
			   aadd(aTranDtls, left(trans(TRANDTLS->glcode,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
			                   trans(if(TRANDTLS->drcr=='1',TRANDTLS->amount,0.00),'@Z 9,999,999,999.99')+'³'+;
							   trans(if(TRANDTLS->drcr=='2',TRANDTLS->amount,0.00),'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+TRANDTLS->drcr)
			   do case
			      case TRANDTLS->drcr == '1'
				       nTDtDebit  := nTDtDebit + TRANDTLS->amount
				  case TRANDTLS->drcr == '2'
				       nTDtCredit := nTDtCredit + TRANDTLS->amount
			   endcase
			endif
			TRANDTLS->(dbskip())
		 enddo
	  endif
	  @22,46 say trans(nTDtDebit, '@Z 9,999,999,999.99')
	  @22,63 say trans(nTDtCredit, '@Z 9,999,999,999.99')
	  achoice(18,1,20,78,aTranDtls,.f.)
   endif
   TRANDTLS->(dbclosearea())
endif

if lRFPModule
   OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+;
             iif('EDIT'$cModAccess .and. cStatCode=='1' .and. left(cPreprdBy,3)=='SG1' .and. cForAprvl$'R','F2-Edit  ','')+'F4-Search  '+;
			 iif('CANCEL'$cModAccess .and. cStatCode=='1' .and. left(cPreprdBy,3)=='SG1' .and. cForAprvl$'R','F6-Cancel  ','')+;
			 iif(cStatCode=='1','TAB-GL Entry  ','')+'ESC-Exit')
else
   OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+;
             iif('EDIT'$cModAccess .and. cStatCode=='1' .and. left(cPreprdBy,3)<>'SG1' .and. cForAprvl$'ER','F2-Edit  ','')+'F4-Search  '+;
			 iif('CANCEL'$cModAccess .and. cStatCode=='1' .and. left(cPreprdBy,3)<>'SG1' .and. cForAprvl$'ER','F6-Cancel  ','')+;
			 iif('EDIT'$cModAccess .and. left(cPreprdBy,3)<>'SG1' .and. cForAprvl$'ER','F8-For Checking  ','')+;
			 iif(cStatCode=='1','TAB-GL Entry  ','')+'ESC-Exit')
endif
return

**********************************
static function DVAddEdit(cOption)
**********************************
local nReview, cScrn:=savescreen(,,,)
private cPyee:=iif(cOption=='A',space(60),cPayee), nAmt:=iif(cOption=='A',0,nAmount), cChkNo:=iif(cOption=='A',space(15),cCheckNo),;
        cBnkBrCd:=iif(cOption=='A',space(3),cBankBrCode), cBnkCode:=iif(cOption=='A',space(3),cBankCode),;
		cParti1:=iif(cOption=='A',space(70),cParticlr1), cParti2:=iif(cOption=='A',space(70),cParticlr2), cParti3:=iif(cOption=='A',space(70),cParticlr3),;
		cParti4:=iif(cOption=='A',space(70),cParticlr4), cParti5:=iif(cOption=='A',space(70),cParticlr5), cParti6:=iif(cOption=='A',space(70),cParticlr6)
private lMoreParti, nOldAmt, cOldBnkCode, cOldBnkGLC  //, cBnkGLCd,; transfer to Main Program Declaration
		

lTabGLDtls  := .f.
aGLDtls     := {}
nGLDtDebit  := 0

OptionBar('ESC-Exit')
if cOption == 'A'
   DispDVScrn()
   @3,69 say '[ADD MODE]' color 'g/w'
   if !SelTranBr('DV',12)
      restscreen(,,,,cScrn)
	  return
   endif
   
   nGLDtCredit := 0
   nBankBrCnt  := 0
   nBankCnt    := 0
   
   @4,14 say cVBrCode+'-99999999' color 'b/w'
   @4,54 say dVTranDate color 'n/w'
else
   @3,68 say '[EDIT MODE]' color 'g/w'
   nGLDtCredit := nTDtCredit
   nOldAmt     := nAmount
   cOldBnkCode := cBankCode
   cOldBnkGLC  := cBankGLCode
   aGLDtls     := aclone(aTranDtls)
   @6,14 say alltrim(trans(nAmount,'@Z 9,999,999,999.99')) color 'n/w'
endif

setcolor('w/n,bg+/b,,,n/w')
do while .t.
   lMoreParti := .t.
   
   @5,14  get  cPyee picture '@!' valid !empty(cPyee)
   @6,14  gget nAmt calculator picture '@B 9,999,999,999.99' valid !empty(nAmt)
   @6,54  get  cChkNo picture '@!' valid !empty(cChkNo) .and. GetCheckNo()
   @7,14  get  cBnkBrCd picture '@!' valid GetBankBr()
   @8,14  get  cBnkCode picture '@!' valid GetBank(cOption)
   @9,14  get  cParti1 picture '@!S65' valid !empty(cParti1)
   @10,14 get  cParti2 picture '@!S65' when lMoreParti valid GetNxtParti(cParti2,@cParti3,@cParti4,@cParti5,@cParti6)
   @11,14 get  cParti3 picture '@!S65' when lMoreParti valid GetNxtParti(cParti3,@cParti4,@cParti5,@cParti6)
   @12,14 get  cParti4 picture '@!S65' when lMoreParti valid GetNxtParti(cParti4,@cParti5,@cParti6)
   @13,14 get  cParti5 picture '@!S65' when lMoreParti valid GetNxtParti(cParti5,@cParti6)
   @14,14 get  cParti6 picture '@!S65' when lMoreParti
   setcursor(1)
   read
   setcursor(0)
   
   if lastkey() == K_ESC
      if KeyReview('RC') == 0
		 restscreen(,,,,cScrn)
		 exit
	  endif
   else
	  do case
	     case cOption == 'A'
			  GLDtAddEdit('A',.t.,9)
			  @22,46 say trans(nGLDtDebit, '@Z 9,999,999,999.99')
			  @22,63 say trans(nGLDtCredit, '@Z 9,999,999,999.99')
			  
			  nGLDtlsCnt := len(aGLDtls)
			  do while .t.
			     if achoice(18,1,20,78,aGLDtls,,'DVGLDtUDF',nGLDtlsCnt) == 0
				    if lDVSaved
					   lDVSaved := .f.
					   @3,69 to 3,78 color 'n/w'
					else
					   restscreen(,,,,cScrn)
					endif
					return
				 endif
				 restscreen(18,0,22,79,cGLDtScrn)
				 @22,46 say trans(nGLDtDebit, '@Z 9,999,999,999.99')
				 @22,63 say trans(nGLDtCredit, '@Z 9,999,999,999.99')
			  enddo
		 case cOption == 'E'
		      nReview := KeyReview('ARC')
			  do case
			     case nReview == 0
					  restscreen(,,,,cScrn)
					  exit
				 case nReview == 2
				      if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
					     return
					  endif
					  set index to &g_GLAS_Path\TRANHEAD, &g_GLAS_Path\TRANCODE, &g_GLAS_Path\TRANBANK, &g_GLAS_Path\TRANLCRJ, &g_GLAS_Path\TRANDATE
					  
					  if !TRANHEAD->(dbseek(strtran(cDVNumber,'-','')))
					     @24,0 say ' ERROR: ' color 'r+'
						 @24,8 say padr('DV not found. Press Any Key.',72) color 'w'
						 TRANHEAD->(dbclosearea())
						 inkey(0)
						 return
					  else
						 if nAmt <> nOldAmt .or. cBnkCode <> cOldBnkCode
							if !netuse('&g_GLAS_Path\TRANDTLS',.f.,5)
							   TRANHEAD->(dbclosearea())
							   return
							endif
							set index to &g_GLAS_Path\TRGLCODE, &g_GLAS_Path\TRANDTLS
							
							if !TRANDTLS->(dbseek(cVBrCode+cOldBnkGLC+right(cDVNumber,8)))
							   @24,0 say ' ERROR: ' color 'r+'
							   @24,8 say padr('Bank GL Code not found. Press Any Key.',72) color 'w'
							   TRANHEAD->(dbclosearea())
							   TRANDTLS->(dbclosearea())
							   inkey(0)
							   return
							endif
						 endif
						 
						 if nAmt <> nOldAmt
						    if !netuse('&g_GLAS_Path\DV_LOG',.f.,5)
							   TRANHEAD->(dbclosearea())
							   if nAmt <> nOldAmt .or. cBnkCode <> cOldBnkCode
							      TRANDTLS->(dbclosearea())
							   endif
							   return
							endif
							set index to &g_GLAS_Path\DV_LOG
							
							if !DV_LOG->(dbseek(strtran(cDVNumber,'-','')))
							   @24,0 say ' ERROR: ' color 'r+'
							   @24,8 say padr('DV Log not found. Press Any Key.',72) color 'w'
							   TRANHEAD->(dbclosearea())
							   DV_LOG->(dbclosearea())
							   if nAmt <> nOldAmt .or. cBnkCode <> cOldBnkCode
							      TRANDTLS->(dbclosearea())
							   endif
							   inkey(0)
							   return
							endif
						 endif
						 
						 SaveOldVal('TRANHEAD','BRTRBANK')
						 if TRANHEAD->(netlock('R'))
						    TRANHEAD->trpayee  := cPyee
							TRANHEAD->tramount := nAmt
							TRANHEAD->brtrbank := cBnkBrCd
							TRANHEAD->trbank   := cBnkCode
							TRANHEAD->trcheck  := cChkNo
							TRANHEAD->partix1  := cParti1
							TRANHEAD->partix2  := cParti2
							TRANHEAD->partix3  := cParti3
							TRANHEAD->partix4  := cParti4
							TRANHEAD->partix5  := cParti5
							TRANHEAD->partix6  := cParti6
							TRANHEAD->usercode := cUserName
							TRANHEAD->(dbcommit())
						 endif
						 TRANHEAD->(dbunlock())
						 AuditLog('g_GLAS_Path','Edits','DV No. '+cDVNumber,'TRANHEAD','BRTRBANK')
						 
						 if nAmt <> nOldAmt .or. cBnkCode <> cOldBnkCode
							if TRANDTLS->(netlock('R'))
							   TRANDTLS->glcode := strtran(left(aGLDtls[nGLDtlsCnt],15),'-','')
							   TRANDTLS->amount := val(strtran(iif(right(aGLDtls[nGLDtlsCnt],1)=='1',substr(aGLDtls[nGLDtlsCnt],46,16), iif(right(aGLDtls[nGLDtlsCnt],1)=='2',substr(aGLDtls[nGLDtlsCnt],63,16), '0.00')),',',''))
							   TRANDTLS->(dbcommit())
							endif
							TRANDTLS->(dbunlock())
							TRANDTLS->(dbclosearea())
							
							aTranDtls  := aclone(aGLDtls)
							nTDtCredit := nGLDtCredit
						 endif
						 
						 if nAmt <> nOldAmt
						    if DV_LOG->(netlock('R'))
							   DV_LOG->amount := nAmt
							   DV_LOG->(dbcommit())
							endif
							DV_LOG->(dbunlock())
							DV_LOG->(dbclosearea())
						 endif
					  endif
					  //@3,68 to 3,78 color 'n/w'
					  DispDVDtls(.f.)
					  exit
			  endcase
	  endcase
   endif
enddo
return

****************************
static function GetCheckNo()
****************************
keyboard chr(K_ENTER)
return .t.

***************************
static function GetBankBr()
***************************
local cScrn:=savescreen(,,,)

@7,14 to iif(len(aBankBr)<10,7+len(aBankBr)+1,18),50
nBankBrCnt := achoice(8,15,iif(len(aBankBr)<10,8+len(aBankBr)-1,17),49,aBankBr,,'AchUDF',nBankBrCnt)
restscreen(,,,,cScrn)

if nBankBrCnt == 0
   keyboard chr(K_ESC)
   return .f.
endif

cBnkBrCd := right(aBankBr[nBankBrCnt],3)
@7,14 say cBnkBrCd color 'n/w'
@7,18 say left(aBankBr[nBankBrCnt],30) color 'gr/w'

if len(aBank) = 0 .or. cBnkBrCd <> substr(aBank[1],46,3)
   aBank := {}
   if cBnkBrCd == left(cOrigBr,3)
      aBank := aclone(aDefltBank)
   else
	  if !netuse('&g_RFM_Path\BANKACCT',.f.,5)
	     return .f.
	  endif
	  set index to &g_RFM_Path\BANKNAME
	  
	  do while !BANKACCT->(eof())
	     if BANKACCT->brcode == cBnkBrCd
		    aadd(aBank, BANKACCT->bankname+'  '+BANKACCT->bankcode+BANKACCT->brcode+BANKACCT->glcode)
		 endif
	  BANKACCT->(dbskip())
	  enddo
	  BANKACCT->(dbclosearea())
   endif
endif

if len(aBank) == 0
   @24,0 say ' ERROR: ' color 'r+'
   @24,8 say padr('No Bank Account found. Press Any Key.',72) color 'w'
   inkey(0)
   OptionBar('ESC-Exit')
   keyboard chr(K_ENTER)
   return .f.
endif
keyboard chr(K_ENTER)
return .t.

********************************
static function GetBank(cOption)
********************************
local nRecNo, cScrn:=savescreen(,,,)

if cOption == 'E'
   nBankCnt := ascan(aBank,{|x| substr(x,43,3)==cBnkCode})
endif
@8,14 to iif(len(aBank)<10,8+len(aBank)+1,18),60
nBankCnt := achoice(9,15,iif(len(aBank)<10,9+len(aBank)-1,17),59,aBank,,'AchUDF',nBankCnt)
restscreen(,,,,cScrn)

if nBankCnt == 0
   keyboard chr(K_ESC)
   return .f.
endif

cBnkCode := substr(aBank[nBankCnt],43,3)
cBnkGLCd := right(aBank[nBankCnt],11)
@8,14 say cBnkCode color 'n/w'
@8,18 say left(aBank[nBankCnt],40) color 'gr/w'

if nAmt <> nOldAmt .or. cBnkCode <> cOldBnkCode
   nRecNo := (gTmpGL)->(recno())
   if cBnkCode <> cOldBnkCode
      (gTmpGL)->(dbsetorder(1))
	  if !(gTmpGL)->(dbseek(right(aBank[nBankCnt],11)))
		 @24,0 say ' ERROR: ' color 'r+'
		 @24,8 say padr('Bank GL Code not found. Press Any Key.',72) color 'w'
		 inkey(0)
		 cBnkCode := space(3)
		 restscreen(,,,,cScrn)
		 return .f.
	  endif
   endif
   
   if len(aGLDtls) == 0
      aadd(aGLDtls, left(trans(right(aBank[nBankCnt],11),'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
	                space(16)+'³'+ trans(nAmt,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'2')
	  nGLDtCredit := nAmt
   else
	  nGLDtlsCnt := ascan(aGLDtls,{|x| strtran(left(x,15),'-','')==cOldBnkGLC})
	  if cBnkCode == cOldBnkCode
		 afill(aGLDtls, left(aGLDtls[nGLDtlsCnt],62)+trans(nAmt,'@Z 9,999,999,999.99')+substr(aGLDtls[nGLDtlsCnt],79),nGLDtlsCnt,1)
	  else
		 afill(aGLDtls, left(trans(right(aBank[nBankCnt],11),'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
		                space(16)+'³'+trans(nAmt,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'2',nGLDtlsCnt,1)
	  endif
	  nGLDtCredit := nGLDtCredit - nOldAmt + nAmt
   endif
   (gTmpGL)->(dbgoto(nRecNo))
   
   @22,63 say trans(nGLDtCredit, '@Z 9,999,999,999.99') color 'w+/rb'
   setcolor(',,,,w+/rb')
   achoice(18,1,20,78,aGLDtls,.f.)
   setcolor(',,,,n/w')
endif
return .t.

*********************************************
function DVGLDtUDF(status,curr_elem,curr_row)
*********************************************
local nSeqNo, lInterBr:=.f., nDelColumn, nDelAmount, aGLDtDebit:={}, aGLDtCredit:={}, nReview

do case
   case lastkey() == K_INS
		GLDtAddEdit('A',.t.,9)
		nGLDtlsCnt := len(aGLDtls)
		return 1
   case lastkey() == K_F2
        nGLDtlsCnt := curr_elem
		if strtran(left(aGLDtls[curr_elem],15),'-','') == cBnkGLCd // right(aBank[nBankCnt],11) ESV 10.25.2016 change to variable
		   @24,0 say ' ERROR: ' color 'r+'
		   @24,8 say padr('GL '+left(aGLDtls[curr_elem],15)+' is not editable. Press Any Key.',72) color 'w'
		   inkey(0)
		   OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
		   return 2
		else
		   GLDtAddEdit('E',.t.,9)
		   return 1
		endif
   case lastkey() == K_DEL
		if strtran(left(aGLDtls[curr_elem],15),'-','') == cBnkGLCd //right(aBank[nBankCnt],11) ESV 10.25.2016 change to variable
		   @24,0 say ' ERROR: ' color 'r+'
		   @24,8 say padr('GL '+left(aGLDtls[curr_elem],15)+' cannot be removed. Press Any Key.',72) color 'w'
		   inkey(0)
		   OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
		   return 2
		else
		   nDelColumn := val(right(aGLDtls[curr_elem],1))
		   nDelAmount := val(strtran(iif(nDelColumn==1,substr(aGLDtls[curr_elem],46,16), iif(nDelColumn==2,substr(aGLDtls[curr_elem],63,16), '0.00')),',',''))
		   do case
		      case nDelColumn == 1
			       nGLDtDebit  := nGLDtDebit - nDelAmount
			  case nDelColumn == 2
			       nGLDtCredit := nGLDtCredit - nDelAmount
		   endcase
		   
		   if len(aGLDtls) > 1
		      for nCnt := curr_elem to len(aGLDtls)
			      if nCnt <> len(aGLDtls)
				     afill(aGLDtls,aGLDtls[nCnt+1],nCnt,1)
				  endif
			  next nCnt
		   else
			  restscreen(18,0,22,79,cGLDtScrn)
			  @24,0  say ' MESSAGE: ' color 'bg+'
			  @24,10 say padr('DV is discarded. Press Any Key.',70) color 'w'
			  inkey(0)
		   endif
		   
		   asize(aGLDtls,len(aGLDtls)-1)
		   nGLDtlsCnt := curr_elem
		   return 1
		endif
   case lastkey() == K_ESC
		for nCnt := 1 to len(aGLDtls)
		    if substr(aGLDtls[nCnt],10,1) == '8' .and. substr(aGLDtls[nCnt],10,3) <> cVBrCode
			   lInterBr := .t.
			   exit
			endif
		next nCnt
		
		if !lTabGLDtls
		   nReview := KeyReview('ARC')
		   do case
		      case nReview == 0
			       return 0
			  case nReview == 1
			       OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
				   return 2
			  case nReview == 2
				   if round(nGLDtDebit,2) <> round(nGLDtCredit,2)
				      @24,0 say ' ERROR: ' color 'r+'
					  @24,8 say padr('GL Entries are not balance. Press Any Key.',72) color 'w'
					  inkey(0)
					  OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
					  return 2
				   else
					  if !netuse('&g_RFM_Path\OL_PARAM',.f.,5)
					     return 0
					  endif
					  set index to &g_RFM_Path\OL_PARAM
					  
					  if !OL_PARAM->(dbseek('TRANHEAD'+'DVNUMBER  '+cVBrCode))
					     @24,0 say ' ERROR: ' color 'r+'
						 @24,8 say padr('DV Sequence Number not found. Press Any Key.',72) color 'w'
						 OL_PARAM->(dbclosearea())
						 inkey(0)
					  else
						 if OL_PARAM->lastseqnum == 39999999
					        @24,0 say ' ERROR: ' color 'r+'
							@24,8 say padr('DV Sequence Number has reached the maximum limit. Press Any Key.',72) color 'w'
							OL_PARAM->(dbclosearea())
							inkey(0)
						 else
							if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
					           OL_PARAM->(dbclosearea())
							   return 0
							endif
							set index to &g_GLAS_Path\TRANHEAD, &g_GLAS_Path\TRANCODE, &g_GLAS_Path\TRANBANK, &g_GLAS_Path\TRANLCRJ, &g_GLAS_Path\TRANDATE
							
							if !netuse('&g_GLAS_Path\TRANDTLS',.f.,5)
						       OL_PARAM->(dbclosearea())
							   TRANHEAD->(dbclosearea())
							   return 0
							endif
							set index to &g_GLAS_Path\TRANDTLS, &g_GLAS_Path\TRGLCODE
							
							if !netuse('&g_GLAS_Path\DV_LOG',.f.,5)
						       OL_PARAM->(dbclosearea())
							   TRANHEAD->(dbclosearea())
							   TRANDTLS->(dbclosearea())
							   return 0
							endif
							set index to &g_GLAS_Path\DV_LOG
							
							@24,0  say ' MESSAGE: ' color 'bg+'
							@24,10 say padr('Saving Record. Kindly Wait...',70) color 'w'
							if TRANHEAD->(netlock('A'))
				               if OL_PARAM->(netlock('R'))
						          OL_PARAM->lastseqnum := nSeqNo := OL_PARAM->lastseqnum+1
								  OL_PARAM->(dbcommit())
							   endif
							   OL_PARAM->(dbunlock())
							   OL_PARAM->(dbclosearea())
							   
							   TRANHEAD->trancode  := '2'
							   TRANHEAD->trantype  := '1'
							   TRANHEAD->brcode    := cVBrCode
							   TRANHEAD->trnumber  := padl(nSeqNo,8,'0')
							   TRANHEAD->trandate  := dVTranDate
							   TRANHEAD->trpayee   := cPyee
							   TRANHEAD->tramount  := nAmt
							   TRANHEAD->brtrbank  := cBnkBrCd
							   TRANHEAD->trbank    := cBnkCode
							   TRANHEAD->trcheck   := cChkNo
							   TRANHEAD->partix1   := cParti1
							   TRANHEAD->partix2   := cParti2
							   TRANHEAD->partix3   := cParti3
							   TRANHEAD->partix4   := cParti4
							   TRANHEAD->partix5   := cParti5
							   TRANHEAD->partix6   := cParti6
							   TRANHEAD->usercode  := cUserName
							   TRANHEAD->post_date := date()
							   TRANHEAD->foraprvl  := 'E'
							   TRANHEAD->interbr   := lInterBr
							   TRANHEAD->(dbcommit())
							endif
							TRANHEAD->(dbunlock())
							
							for nCnt := 2 to len(aGLDtls)
							    if TRANDTLS->(netlock('A'))
						           TRANDTLS->trancode := '2'
								   TRANDTLS->brcode   := cVBrCode
								   TRANDTLS->trnumber := padl(nSeqNo,8,'0')
								   TRANDTLS->glcode   := strtran(left(aGLDtls[nCnt],15),'-','')
								   TRANDTLS->drcr     := right(aGLDtls[nCnt],1)
								   TRANDTLS->amount   := val(strtran(iif(right(aGLDtls[nCnt],1)=='1',substr(aGLDtls[nCnt],46,16), iif(right(aGLDtls[nCnt],1)=='2',substr(aGLDtls[nCnt],63,16), '0.00')),',',''))
								   TRANDTLS->(dbcommit())
								endif
								TRANDTLS->(dbunlock())
							next nCnt
							if TRANDTLS->(netlock('A'))
							   TRANDTLS->trancode := '2'
							   TRANDTLS->brcode   := cVBrCode
							   TRANDTLS->trnumber := padl(nSeqNo,8,'0')
							   TRANDTLS->glcode   := strtran(left(aGLDtls[1],15),'-','')
							   TRANDTLS->drcr     := right(aGLDtls[1],1)
							   TRANDTLS->amount   := val(strtran(iif(right(aGLDtls[1],1)=='1',substr(aGLDtls[1],46,16), iif(right(aGLDtls[1],1)=='2',substr(aGLDtls[1],63,16), '0.00')),',',''))
							   TRANDTLS->(dbcommit())
							endif
							TRANDTLS->(dbunlock())
							TRANDTLS->(dbclosearea())
							
							if DV_LOG->(netlock('A'))
						       DV_LOG->trancode  := '2'
							   DV_LOG->trantype  := '1'
							   DV_LOG->brcode    := cVBrCode
							   DV_LOG->trnumber  := padl(nSeqNo,8,'0')
							   DV_LOG->trandate  := dVTranDate
							   DV_LOG->payor     := cPyee
							   DV_LOG->amount    := nAmt
							   DV_LOG->post_date := date()
							   DV_LOG->(dbcommit())
							endif
							DV_LOG->(dbunlock())
							DV_LOG->(dbclosearea())
							AuditLog('g_GLAS_Path','Adds','DV No. '+cVBrCode+'-'+padl(nSeqNo,8,'0'))
							
							setcolor(',,,,w+/rb')
							
							aTranDtls  := aclone(aGLDtls)
							nTDtDebit  := nGLDtDebit
							nTDtCredit := nGLDtCredit
							lDVSaved   := .t.
							DispDVDtls(.f.)
						 endif
					  endif
					  return 0
				   endif
		   endcase
		else
		   if len(aGLDtls) <> len(aTranDtls)
		      lDVSaved := .t.
		   else
			  if nGLDtDebit <> nTDtDebit .or. nGLDtCredit <> nTDtCredit
			     lDVSaved := .t.
			  else
				 for nCnt := 1 to len(aGLDtls)
				     if aGLDtls[nCnt] <> aTranDtls[nCnt]
					    lDVSaved := .t.
						exit
					 endif
				 next nCnt
			  endif
		   endif
		   
		   if !lDVSaved
		      return 0
		   else
			  lDVSaved := .f.
			  nReview := KeyReview('ARC')
			  do case
			     case nReview == 0
				      return 0
				 case nReview == 1
				      OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
					  return 2
				 case nReview == 2
					  if round(nGLDtDebit,2) <> round(nGLDtCredit,2)
				         @24,0 say ' ERROR: ' color 'r+'
						 @24,8 say padr('GL Entries are not balance. Press Any Key.',72) color 'w'
						 inkey(0)
						 OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
						 return 2
					  else
						 if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
						    return 0
						 endif
						 set index to &g_GLAS_Path\TRANHEAD, &g_GLAS_Path\TRANCODE, &g_GLAS_Path\TRANBANK, &g_GLAS_Path\TRANLCRJ, &g_GLAS_Path\TRANDATE
						 
						 if !TRANHEAD->(dbseek(strtran(cDVNumber,'-','')))
						    @24,0 say ' ERROR: ' color 'r+'
							@24,8 say padr('DV not found. Press Any Key.',72) color 'w'
							TRANHEAD->(dbclosearea())
							inkey(0)
						 else
							if !netuse('&g_GLAS_Path\TRANDTLS',.f.,5)
							   TRANHEAD->(dbclosearea())
							   return 0
							endif
							set index to &g_GLAS_Path\TRANDTLS, &g_GLAS_Path\TRGLCODE
							
							if !TRANDTLS->(dbseek(strtran(cDVNumber,'-','')))
							   @24,0 say ' ERROR: ' color 'r+'
							   @24,8 say padr('GL Entries not found. Press Any Key.',72) color 'w'
							   TRANHEAD->(dbclosearea())
							   TRANDTLS->(dbclosearea())
							   inkey(0)
							else
							   if !netuse('&g_GLAS_Path\DV_LOG',.f.,5)
							      TRANHEAD->(dbclosearea())
								  TRANDTLS->(dbclosearea())
								  return 0
							   endif
							   set index to &g_GLAS_Path\DV_LOG
							   
							   if !DV_LOG->(dbseek(strtran(cDVNumber,'-','')))
							      @24,0 say ' ERROR: ' color 'r+'
								  @24,8 say padr('DV Log not found. Press Any Key.',72) color 'w'
								  TRANHEAD->(dbclosearea())
								  TRANDTLS->(dbclosearea())
								  DV_LOG->(dbclosearea())
								  inkey(0)
							   else
								  @24,0  say ' MESSAGE: ' color 'bg+'
								  @24,10 say padr('Saving Record. Kindly Wait...',70) color 'w'
								  //if TRANHEAD->(netlock('R'))
								     //TRANHEAD->tramount := nGLDtDebit
									 //TRANHEAD->interbr  := lInterBr
									 //TRANHEAD->(dbcommit())
								  //endif
								  //TRANHEAD->(dbunlock())
								  TRANHEAD->(dbclosearea())	// ESV 10.26.2016 COMMENT BEFORE
								  
								  for nCnt := 1 to len(aGLDtls)
								      do case
									     case right(aGLDtls[nCnt],1) == '1'
										      aadd(aGLDtDebit, left(aGLDtls[nCnt],15)+substr(aGLDtls[nCnt],46,16))
										 case right(aGLDtls[nCnt],1) == '2'
										      aadd(aGLDtCredit, left(aGLDtls[nCnt],15)+substr(aGLDtls[nCnt],63,16))
									  endcase
								  next nCnt
								  
								  for nCnt := 1 to len(aGLDtDebit)
								      if TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cDVNumber,'-','') .and. TRANDTLS->drcr == '1'
									     SaveOldVal('TRANDTLS','AMOUNT')
										 if TRANDTLS->(netlock('R'))
										    TRANDTLS->glcode := strtran(left(aGLDtDebit[nCnt],15),'-','')
											TRANDTLS->drcr   := '1'
											TRANDTLS->amount := val(strtran(right(aGLDtDebit[nCnt],16),',',''))
											TRANDTLS->(dbcommit())
										 endif
										 TRANDTLS->(dbunlock())
										 AuditLog('g_GLAS_Path','Edits','GL Code '+left(aGLDtDebit[nCnt],15)+' for DV No. '+cDVNumber,'TRANDTLS','AMOUNT')
									  else
										 if TRANDTLS->(netlock('A'))
										    TRANDTLS->trancode := '2'
											TRANDTLS->brcode   := cVBrCode
											TRANDTLS->trnumber := right(cDVNumber,len(TRANDTLS->trnumber))
											TRANDTLS->glcode   := strtran(left(aGLDtDebit[nCnt],15),'-','')
											TRANDTLS->drcr     := '1'
											TRANDTLS->amount   := val(strtran(right(aGLDtDebit[nCnt],16),',',''))
											TRANDTLS->(dbcommit())
										 endif
										 TRANDTLS->(dbunlock())
										 AuditLog('g_GLAS_Path','Adds','GL Code '+left(aGLDtDebit[nCnt],15)+' for DV No. '+cDVNumber)
									  endif
									  TRANDTLS->(dbskip())
								  next nCnt
								  
								  if TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cDVNumber,'-','') .and. TRANDTLS->drcr == '1'
								     do while !TRANDTLS->(eof()) .and. TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cDVNumber,'-','') .and. TRANDTLS->drcr == '1'
									    AuditLog('g_GLAS_Path','Deletes','GL Code '+trans(TRANDTLS->glcode, '@R 9-99-99-9999-99')+' for DV No. '+cDVNumber)
										if TRANDTLS->(netlock('R'))
										   TRANDTLS->(dbdelete())
										endif
										TRANDTLS->(dbunlock())
										TRANDTLS->(dbskip())
									 enddo
								  endif
								  
								  for nCnt := 1 to len(aGLDtCredit)
								      if TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cDVNumber,'-','') .and. TRANDTLS->drcr == '2'
									     SaveOldVal('TRANDTLS','AMOUNT')
										 if TRANDTLS->(netlock('R'))
										    TRANDTLS->glcode := strtran(left(aGLDtCredit[nCnt],15),'-','')
											TRANDTLS->drcr   := '2'
											TRANDTLS->amount := val(strtran(right(aGLDtCredit[nCnt],16),',',''))
											TRANDTLS->(dbcommit())
										 endif
										 TRANDTLS->(dbunlock())
										 AuditLog('g_GLAS_Path','Edits','GL Code '+left(aGLDtCredit[nCnt],15)+' for DV No. '+cDVNumber,'TRANDTLS','AMOUNT')
									  else
										 if TRANDTLS->(netlock('A'))
										    TRANDTLS->trancode := '2'
											TRANDTLS->brcode   := cVBrCode
											TRANDTLS->trnumber := right(cDVNumber,len(TRANDTLS->trnumber))
											TRANDTLS->glcode   := strtran(left(aGLDtCredit[nCnt],15),'-','')
											TRANDTLS->drcr     := '2'
											TRANDTLS->amount   := val(strtran(right(aGLDtCredit[nCnt],16),',',''))
											TRANDTLS->(dbcommit())
										 endif
										 TRANDTLS->(dbunlock())
										 AuditLog('g_GLAS_Path','Adds','GL Code '+left(aGLDtCredit[nCnt],15)+' for DV No. '+cDVNumber)
									  endif
									  TRANDTLS->(dbskip())
								  next nCnt
								  
								  if TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cDVNumber,'-','') .and. TRANDTLS->drcr == '2'
								     do while !TRANDTLS->(eof()) .and. TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cDVNumber,'-','') .and. TRANDTLS->drcr == '2'
									    AuditLog('g_GLAS_Path','Deletes','GL Code '+trans(TRANDTLS->glcode, '@R 9-99-99-9999-99')+' for DV No. '+cDVNumber)
										if TRANDTLS->(netlock('R'))
										   TRANDTLS->(dbdelete())
										endif
										TRANDTLS->(dbunlock())
										TRANDTLS->(dbskip())
									 enddo
								  endif
								  TRANDTLS->(dbclosearea())
								  
								  //if DV_LOG->(netlock('R'))
								     //DV_LOG->amount := nGLDtDebit
									 //DV_LOG->(dbcommit())
								  //endif
								  //DV_LOG->(dbunlock())
								  DV_LOG->(dbclosearea()) // ESV 10.26.2016 COMMENT BEFORE
								  
								  aTranDtls  := aclone(aGLDtls)
								  nTDtDebit  := nGLDtDebit
								  nTDtCredit := nGLDtCredit
								  lDVSaved   := .t.
							   endif
							endif
						 endif
						 return 0
					  endif
			  endcase
		   endif
		endif
endcase
return 2