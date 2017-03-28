/*
PROGRAM     : GLAS1100.PRG
DESCRIPTION : JOURNAL VOUCHER ENTRY PROGRAM
AUTHOR      : ERLACHICA
CREATED     : JUNE 24, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

#include "INKEY.CH"
#include "LOFL.CH"

local cScrn
private aBrAcs:={}, nSelBrCnt:=1, dVTranDate,;
        cVBrCode:=left(cSelectBr,3), cStatCode, cJVNumber, dJVDate, cJVTypeCode, cJVTypeName,;
		cParticlr1, cParticlr2, cParticlr3, cParticlr4, cParticlr5, cParticlr6, cForAprvl,;
		aTranDtls:={}, nTDtDebit:=0, nTDtCredit:=0, aOldVal:={}
private lTabGLDtls, aGLDtls:={}, nGLDtlsCnt:=0, nGLDtDebit, nGLDtCredit, cGLDtScrn, cGLNameScrn, lJVSaved:=.f., nTopRow:=9, nMaxRLineNo:=13
private aGL:={}, nGLCnt:=0, aColumn:={'DEBIT ','CREDIT'}
private lAddRFPUDF:=.f.

DispJVScrn()

if !OpenBrEntry('JV')
   return
endif

if !OpenTmpGL()
   return
endif

OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+'F4-Search  ESC-Exit')
cGLDtScrn := savescreen(15,0,22,79)
do while .t.
   inkey(0)
   do case
      case lastkey() == K_INS .and. 'ADD'$cModAccess
	       JVAddEdit('A')
	  case lastkey() == K_F2 .and. 'EDIT'$cModAccess .and. cStatCode == '1' .and. cForAprvl$'ER'
	       JVAddEdit('E')
	  case lastkey() == K_F4
	       VSearch('JV')
	  case lastkey() == K_F6 .and. 'CANCEL'$cModAccess .and. cStatCode == '1' .and. cForAprvl$'ER'
	       VCancel('JV',10)
	  case lastkey() == K_F8 .and. 'EDIT'$cModAccess .and. cForAprvl$'ER'
	       VForChckng('JV')
	  case lastkey() == K_TAB .and. cStatCode == '1'
	       setcolor('w+/rb,n/w,,,w+/rb')
		   if !cForAprvl$'ER'
		      cGLNameScrn := savescreen(23,1,23,78)
			  if !empty(substr(aTranDtls[1],79,22))
			     @23,1 say ' Full GL Name: '+substr(aTranDtls[1],17,28)+alltrim(substr(aTranDtls[1],79,22))+' ' color 'n+/rb'
			  endif
			  OptionBar('TAB-Go Back')
			  achoice(15,1,20,78,aTranDtls,,'VTabUDF')
		   else
			  OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
			  
			  lTabGLDtls  := .t.
			  cScrn       := savescreen(,,,)
			  aGLDtls     := aclone(aTranDtls)
			  nGLDtlsCnt  := 0
			  nGLDtDebit  := nTDtDebit
			  nGLDtCredit := nTDtCredit
			  
			  do while .t.
			     if achoice(15,1,20,78,aGLDtls,,'JVGLDtUDF',nGLDtlsCnt) == 0
				    if lJVSaved
					   lJVSaved := .f.
					else
					   restscreen(,,,,cScrn)
					endif
					exit
				 endif
				 restscreen(15,0,22,79,cGLDtScrn)
				 @22,46 say trans(nGLDtDebit, '@Z 9,999,999,999.99')
				 @22,63 say trans(nGLDtCredit, '@Z 9,999,999,999.99')
			  enddo
		   endif
		   OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+;
		             iif('EDIT'$cModAccess .and. cStatCode=='1' .and. cForAprvl$'ER','F2-Edit  ','')+'F4-Search  '+;
					 iif('CANCEL'$cModAccess .and. cStatCode=='1' .and. cForAprvl$'ER','F6-Cancel  ','')+;
					 iif('EDIT'$cModAccess .and. cForAprvl$'ER','F8-For Checking  ','')+;
					 iif(cStatCode=='1','TAB-GL Entry  ','')+'ESC-Exit')//
	  case lastkey() == K_ESC
	       exit
   endcase
enddo
close databases
return

****************************
static function DispJVScrn()
****************************
@3,0,11,79 box 'ÚÄ¿³³ ³³ ' color 'n/w'
@4,1  say '      JV N§:                                JV Date:' color 'n/w'
//5,1  say '    JV Type:                             Account N§:' color 'n/w'
@5,1  say '    JV Type:' color 'n/w'
@6,1  say 'Particulars:' color 'n/w'
@7,1  say '           :' color 'n/w'
@8,1  say '           :' color 'n/w'
@9,1  say '           :' color 'n/w'
@10,1 say '           :' color 'n/w'
@11,1 say '           :' color 'n/w'
DispJVScr2()
return

*********************
function DispJVScr2()
*********************
setcolor('w+/rb,n/w,,,w+/rb')
@12,0 say 'Ã GL Entry ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
@13,0 say '³                GL Account                  ³      Debit     ³     Credit     ³'
@14,0 say 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
@15,0 say '³                                            ³                ³                ³'
@16,0 say '³                                            ³                ³                ³'
@17,0 say '³                                            ³                ³                ³'
@18,0 say '³                                            ³                ³                ³'
@19,0 say '³                                            ³                ³                ³'
@20,0 say '³                                            ³                ³                ³'
@21,0 say 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
@22,0 say '³                                       Total³                ³                ³'
@23,0 say 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
return

************************************
static function DispJVDtls(lDispAll)
************************************
local cCheckdBy

cStatCode   := TRANHEAD->trantype
cJVNumber   := TRANHEAD->brcode+'-'+TRANHEAD->trnumber
dJVDate     := TRANHEAD->trandate
cJVTypeCode := TRANHEAD->adjmntcode
cJVTypeName := iif(TRANHEAD->adjmntcode=='1','SOLD TO CURRENT',iif(TRANHEAD->adjmntcode=='2','CURRENT TO PDR',;
               iif(TRANHEAD->adjmntcode=='3','CURRENT TO LEGAL',iif(TRANHEAD->adjmntcode=='4','PDR TO LEGAL',;
			   iif(TRANHEAD->adjmntcode=='5','PDR TO CURRENT',iif(TRANHEAD->adjmntcode=='6','LEGAL TO CURRENT',;
			   iif(TRANHEAD->adjmntcode=='7','NORMAL ENTRY',iif(TRANHEAD->adjmntcode=='8','RETURNED CHECK',;
			   iif(TRANHEAD->adjmntcode=='9','SOLD RECEIVABLES',iif(TRANHEAD->adjmntcode=='A','CURRENT TO AR',''))))))))))
cParticlr1  := TRANHEAD->partix1
cParticlr2  := TRANHEAD->partix2
cParticlr3  := TRANHEAD->partix3
cParticlr4  := TRANHEAD->partix4
cParticlr5  := TRANHEAD->partix5
cParticlr6  := TRANHEAD->partix6
cCheckdBy   := TRANHEAD->chckuser
cForAprvl   := TRANHEAD->foraprvl

@4,14  say cJVNumber color 'b/w'
@4,54  say dJVDate color 'r/w'
@5,14  say cJVTypeName color 'r/w'
//@5,54 say '999-9999-99999-99999'
/*if TRANHEAD->Adjmntcode != '9' .and. TRANHEAD->adjmntcode != '1'
   @ 11, 26 say if( _11 == '     ','N/A'+ repl(' ',40+6),eval ( {||  Acctmast->(dbseek(cVBrCode+_11)),;
                                                                     '('+trans(Acctmast->acctno,'@R 9999-99999-99999') + ')  '+padr  (Acctmast->Acctname,20)   ;
                                                                } ;
                                                              ) ;
                  ) color 'w+/gr'
else
*********   @ 11, 26 say '<  T A B L E  >' color 'w+/gr'
   @ 11, 26 say ffind0100( TRANHEAD->soldto, 35 ) color 'w+/gr'      // 8.25.2001 abb
endif

if TRANHEAD->adjmntcode != '9'  .and. TRANHEAD->adjmntcode != '1'
   @ 11,  5 say '    Account Number ¯ '                      color 'bg+/gr'
else
   @ 11,  5 say '           Sold to ¯ '                      color 'bg+/gr'
endif*/
@6,14  say left(cParticlr1,65) color 'r/w'
@7,14  say left(cParticlr2,65) color 'r/w'
@8,14  say left(cParticlr3,65) color 'r/w'
@9,14  say left(cParticlr4,65) color 'r/w'
@10,14 say left(cParticlr5,65) color 'r/w'
@11,14 say left(cParticlr6,65) color 'r/w'

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
		
		if THDAPRVL->(dbseek(TRANHEAD->brcode+TRANHEAD->trnumber))
		   do while !THDAPRVL->(eof()) .and. THDAPRVL->brcode == TRANHEAD->brcode .and. THDAPRVL->trnumber == TRANHEAD->trnumber
			  THDAPRVL->(dbskip())
		   enddo
		   THDAPRVL->(dbskip(-1))
		   @23,1 say ' Returned: '+alltrim(THDAPRVL->aprvrmk)+' ' color 'w+/g'
		endif
		THDAPRVL->(dbclosearea())
endcase

if cStatCode == '3'
   @23,1 say ' Cancelled: '+alltrim(TRANHEAD->cancelrmk)+' ' color 'w+/g'
endif

if lDispAll
   (gTmpGL)->(dbsetorder(1))
   if TRANDTLS->(dbseek(TRANHEAD->brcode+TRANHEAD->trnumber))
      do while !TRANDTLS->(eof()) .and. TRANDTLS->brcode = TRANHEAD->brcode .and. TRANDTLS->trnumber = TRANHEAD->trnumber
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
   TRANDTLS->(dbclosearea())
   
   if len(aTranDtls) > 0
      @22,46 say trans(nTDtDebit, '@Z 9,999,999,999.99')
	  @22,63 say trans(nTDtCredit, '@Z 9,999,999,999.99')
	  
	  achoice(15,1,20,78,aTranDtls,.f.)
   endif
endif
TRANHEAD->(dbclosearea())

OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+;
          iif('EDIT'$cModAccess .and. cStatCode=='1' .and. cForAprvl$'ER','F2-Edit  ','')+'F4-Search  '+;
		  iif('CANCEL'$cModAccess .and. cStatCode=='1' .and. cForAprvl$'ER','F6-Cancel  ','')+;
		  iif('EDIT'$cModAccess .and. cForAprvl$'ER','F8-For Checking  ','')+;
		  iif(cStatCode=='1','TAB-GL Entry  ','')+'ESC-Exit')
return

*****************************
function OpenBrEntry(cVCateg)
*****************************
local dTrnDate

if !netuse('&g_RFM_Path\OL_PARAM',.f.,5)
   return .f.
endif
set index to &g_RFM_Path\OL_PARAM

if !netuse('&g_RFM_Path\HOLIDAYS',.f.,5)
   close databases
   return .f.
endif
set index to &g_RFM_Path\HOLIDATE

if left(cOrigBr,3) == '800'
   if !netuse('&g_RFM_Path\BRANCHES',.f.,5)
      close databases
	  return .f.
   endif
   set index to &g_RFM_Path\BRANCHES
   
   if !netuse('&g_SMS_Path\USERBRCH',.f.,5)
      close databases
	  return .f.
   endif
   set index to &g_SMS_Path\USERBRCH
   
   if USERBRCH->(dbseek(str(nUserId,len(str(USERBRCH->userid)))))
      do while !USERBRCH->(eof()) .and. USERBRCH->userid == nUserId
	     if USERBRCH->defaultbr  // remove this - if head office accounting will create voucher/s for other branch/es
		    if !BRANCHES->(dbseek(USERBRCH->brcode))
		       @24,0 say ' ERROR: ' color 'r+'
			   @24,8 say padr(USERBRCH->brcode+' has no Branch Name. Press Any Key.',72) color 'w'
			   close databases
			   inkey(0)
			   return .f.
			endif
			
			if !OL_PARAM->(dbseek('TRANHEAD'+cVCateg+'NUMBER  '+USERBRCH->brcode))
		       @24,0 say ' ERROR: ' color 'r+'
			   @24,8 say padr(USERBRCH->brcode+' '+alltrim(BRANCHES->brname)+' has no Transaction Reference. Press Any Key.',72) color 'w'
			   close databases
			   inkey(0)
			   return .f.
			endif
			
			if cVCateg == 'DV' .and. OL_PARAM->date < date()
			   dTrnDate := date()
			   do while .t.
			      if HOLIDAYS->(dbseek(dTrnDate)) .or. dow(dTrnDate) == 7 .or. dow(dTrnDate) == 1
				     dTrnDate = dTrnDate + 1
				  else
					 exit
				  endif
			   enddo
			   if OL_PARAM->(netlock('R'))
			      OL_PARAM->date := dTrnDate
				  OL_PARAM->(dbcommit())
			   endif
			   OL_PARAM->(dbunlock())
			endif
			
			aadd(aBrAcs, BRANCHES->brname+USERBRCH->brcode+dtoc(OL_PARAM->date))
			exit  // remove this
		 endif  // remove this
		 USERBRCH->(dbskip())
	  enddo
   endif
   BRANCHES->(dbclosearea())
   USERBRCH->(dbclosearea())
   asort(aBrAcs)
   nSelBrCnt := ascan(aBrAcs,{|x| substr(x,31,3)==cVBrCode})
else
   if !OL_PARAM->(dbseek('TRANHEAD'+cVCateg+'NUMBER  '+cVBrCode))
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr(cSelectBr+' has no Transaction Reference. Press Any Key.',72) color 'w'
	  close databases
	  inkey(0)
	  return .f.
   endif
   
   if cVCateg == 'DV' .and. OL_PARAM->date < date()
      dTrnDate := date()
	  do while .t.
	     if HOLIDAYS->(dbseek(dTrnDate)) .or. dow(dTrnDate) == 7 .or. dow(dTrnDate) == 1
		    dTrnDate = dTrnDate + 1
		 else
			exit
		 endif
	  enddo
	  if OL_PARAM->(netlock('R'))
	     OL_PARAM->date := dTrnDate
		 OL_PARAM->(dbcommit())
	  endif
	  OL_PARAM->(dbunlock())
   endif
			
   aadd(aBrAcs, padr(right(cSelectBr,len(cSelectBr)-4),30)+left(cSelectBr,3)+dtoc(OL_PARAM->date))
endif
close databases
return .t.

********************
function OpenTmpGL()
********************
if empty(gTmpGL)
   if !netuse('&g_GLAS_Path\GLCODE',.f.,5)
	  return .f.
   endif
   
   if GLCODE->(recc()) == 0
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr('No GL found. Press Any Key.',72) color 'w'
	  close databases
	  inkey(0)
	  return .f.
   else
	  gTmpGL := CreateTmp(g_GLAS_Tmp)
      dbcreate(g_GLAS_Tmp+'\'+gTmpGL, { {'GLCODE','C',11,0}, {'GLNAME','C',50,0} } )
	  
	  if !netuse('&g_GLAS_Tmp\&gTmpGL',.f.,5)
	     close databases
		 return .f.
	  endif
	  index on glcode to (g_GLAS_Tmp+'\'+gTmpGL)
	  index on glname to (g_GLAS_Tmp+'\N'+substr(gTmpGL,2))
	  set index to (g_GLAS_Tmp+'\'+gTmpGL), (g_GLAS_Tmp+'\N'+substr(gTmpGL,2))
	  
	  @24,0  say ' MESSAGE: ' color 'bg+'
	  @24,10 say padr('Initializing GL...',70) color 'w'
	  do while !GLCODE->(eof())
	     if !GLCODE->nopost
		    (gTmpGL)->(dbappend())
			(gTmpGL)->glcode := GLCODE->glcode
			(gTmpGL)->glname := GLCODE->glname
		 endif
		 GLCODE->(dbskip())
	  enddo
   endif
   GLCODE->(dbclosearea())
else
   if !netuse('&g_GLAS_Tmp\&gTmpGL',.f.,5)
	  return .f.
   endif
   set index to (g_GLAS_Tmp+'\'+gTmpGL), (g_GLAS_Tmp+'\N'+substr(gTmpGL,2))
endif
return .t.

**********************************
static function JVAddEdit(cOption)
**********************************
local nReview, cScrn:=savescreen(,,,)
private cJVTCode:=iif(cOption=='A',' ',cJVTypeCode), cJVTName:=iif(cOption=='A',space(16),cJVTypeName),;
        cParti1:=iif(cOption=='A',space(70),cParticlr1), cParti2:=iif(cOption=='A',space(70),cParticlr2), cParti3:=iif(cOption=='A',space(70),cParticlr3),;
		cParti4:=iif(cOption=='A',space(70),cParticlr4), cParti5:=iif(cOption=='A',space(70),cParticlr5), cParti6:=iif(cOption=='A',space(70),cParticlr6),;
		nJVTypeCnt:=0, lMoreParti
private aJVType:={'NORMAL ENTRY    7', 'CURRENT TO PDR  2', 'CURRENT TO LEGAL3', 'PDR TO LEGAL    4', 'PDR TO CURRENT  5',;
                  'LEGAL TO CURRENT6', 'SOLD TO CURRENT 1', 'RETURNED CHECK  8', 'SOLD RECEIVABLES9', 'CURRENT TO AR   A'}

lTabGLDtls  := .f.
aGLDtls     := {}
nGLDtDebit  := 0
nGLDtCredit := 0

OptionBar('ESC-Exit')
if cOption == 'A'
   DispJVScrn()
   @3,69 say '[ADD MODE]' color 'g/w'
   if !SelTranBr('JV',10)
      restscreen(,,,,cScrn)
	  return
   endif
   
   @4,14 say cVBrCode+'-99999999' color 'b/w'
   @4,54 say dVTranDate color 'n/w'
else
   @3,68 say '[EDIT MODE]' color 'g/w'
endif

setcolor('w/n,bg+/b,,,n/w')
do while .t.
   lMoreParti := .t.
   keyboard chr(K_ENTER)
   
   @5,14  get cJVTName valid GetJVType()
   @6,14  get cParti1 picture '@!S65' valid !empty(cParti1)
   @7,14  get cParti2 picture '@!S65' when lMoreParti valid GetNxtParti(cParti2,@cParti3,@cParti4,@cParti5,@cParti6)
   @8,14  get cParti3 picture '@!S65' when lMoreParti valid GetNxtParti(cParti3,@cParti4,@cParti5,@cParti6)
   @9,14  get cParti4 picture '@!S65' when lMoreParti valid GetNxtParti(cParti4,@cParti5,@cParti6)
   @10,14 get cParti5 picture '@!S65' when lMoreParti valid GetNxtParti(cParti5,@cParti6)
   @11,14 get cParti6 picture '@!S65' when lMoreParti
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
			  GLDtAddEdit('A',.f.,8)
			  @22,46 say trans(nGLDtDebit, '@Z 9,999,999,999.99')
			  @22,63 say trans(nGLDtCredit, '@Z 9,999,999,999.99')
			  
			  do while .t.
			     if achoice(15,1,20,78,aGLDtls,,'JVGLDtUDF',nGLDtlsCnt) == 0
				    if lJVSaved
					   lJVSaved := .f.
					   @3,69 to 3,78 color 'n/w'
					else
					   restscreen(,,,,cScrn)
					endif
					return
				 endif
				 restscreen(15,0,22,79,cGLDtScrn)
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
					  
					  if !TRANHEAD->(dbseek(strtran(cJVNumber,'-','')))
					     @24,0 say ' ERROR: ' color 'r+'
						 @24,8 say padr('JV not found. Press Any Key.',72) color 'w'
						 TRANHEAD->(dbclosearea())
						 inkey(0)
						 return
					  else
					     SaveOldVal('TRANHEAD','PARTIX6')
						 if TRANHEAD->(netlock('R'))
							TRANHEAD->adjmntcode := cJVTCode
							TRANHEAD->partix1    := cParti1
							TRANHEAD->partix2    := cParti2
							TRANHEAD->partix3    := cParti3
							TRANHEAD->partix4    := cParti4
							TRANHEAD->partix5    := cParti5
							TRANHEAD->partix6    := cParti6
							TRANHEAD->usercode   := cUserName
							TRANHEAD->(dbcommit())
						 endif
						 TRANHEAD->(dbunlock())
						 AuditLog('g_GLAS_Path','Edits','JV No. '+cJVNumber,'TRANHEAD','PARTIX6')
					  endif
					  @3,68 to 3,78 color 'n/w'
					  DispJVDtls(.f.)
					  exit
			  endcase
	  endcase
   endif
enddo
return

********************************
function SelTranBr(cVCateg,nRow)
********************************
local nBrAcsCnt:=1, cScrn:=savescreen(,,,)

if len(aBrAcs) > 1
   @nRow-1,15,nRow+1,65 box 'ÚÄ¿³ÙÄÀ³ ' color 'w+/n'
   @nRow,17 say 'Transaction For' color 'w+/n'
   @nRow,63 say chr(23) color 'n/w'
   nBrAcsCnt := achoice(nRow,33,nRow,62,aBrAcs,,'AchUDF',nSelBrCnt)
   if nBrAcsCnt == 0
      return .f.
   endif
   restscreen(,,,,cScrn)
endif
cVBrCode   := substr(aBrAcs[nBrAcsCnt],31,3)
dVTranDate := ctod(right(aBrAcs[nBrAcsCnt],10))
return .t.

***************************
static function GetJVType()
***************************
local cScrn:=savescreen(,,,)

@5,14 to 7,31
nJVTypeCnt := achoice(6,15,6,30,aJVType,{.t.,.f.,.f.,.f.,.f.,.f.,.f.,.f.,.f.,.f.},'AchUDF',nJVTypeCnt)
restscreen(,,,,cScrn)

if nJVTypeCnt == 0
   keyboard chr(K_ESC)
   return .f.
endif

cJVTCode := right(aJVType[nJVTypeCnt],1)
cJVTName := left(aJVType[nJVTypeCnt],16)
return .t.

****************************************************************************
function GetNxtParti(cCurrParti,cNxtParti1,cNxtParti2,cNxtParti3,cNxtParti4)
****************************************************************************
if empty(cCurrParti)
   cNxtParti1 := space(70)
   cNxtParti2 := space(70)
   cNxtParti3 := space(70)
   cNxtParti4 := space(70)
   lMoreParti  := .f.
endif
return .t.

**************************************
function GLDtAddEdit(cOption,lDV,nRow)
**************************************
local nOldColCnt, nOldAmount, cScrn:=savescreen(,,,)
private cGLCode:=space(11), cGLName, cPrevGL, cColumn:=space(6), nColumnCnt, nAmount:=0

OptionBar('ESC-Exit')
@nRow-1,2,nRow+3,77 box 'ÚÄ¿³ÙÄÀ³ ' color 'w+/r'
@nRow,3   say '    GL: ' color 'w+/r'
@nRow+1,3 say 'Column: ' color 'w+/r'
@nRow+2,3 say 'Amount: ' color 'w+/r'

if cOption == 'E'
   cGLCode    := cPrevGL := strtran(left(aGLDtls[nGLDtlsCnt],15),'-','')
   cGLName    := substr(aGLDtls[nGLDtlsCnt],17,28)+substr(aGLDtls[nGLDtlsCnt],79,22)
   nColumnCnt := nOldColCnt := val(right(aGLDtls[nGLDtlsCnt],1))
   cColumn    := iif(nColumnCnt==1,'DEBIT', iif(nColumnCnt==2,'CREDIT', space(6)))
   nAmount    := nOldAmount := val(strtran(iif(nColumnCnt==1,substr(aGLDtls[nGLDtlsCnt],46,16), iif(nColumnCnt==2,substr(aGLDtls[nGLDtlsCnt],63,16), '0.00')),',',''))
   
   @nRow,27   say cGLName color 'gr+/r'
   @nRow+2,11 say alltrim(trans(nAmount, '@Z 9,999,999,999.99')) color 'w+/r'
   
   do case
      case nColumnCnt == 1
	       nGLDtDebit  := nGLDtDebit - nAmount
	  case nColumnCnt == 2
	       nGLDtCredit := nGLDtCredit - nAmount
   endcase
endif

do while .t.
   setcolor(',w+/n,,,w+/r')
   @nRow,11   get  cGLCode picture '@R 9-99-99-9999-99' valid GetGLCode(lDV,nRow)
   @nRow+1,11 get  cColumn valid GetColumn(nRow+2)
   @nRow+2,11 gget nAmount calculator picture '@B 9,999,999,999.99' valid !empty(nAmount)
   setcursor(1)
   read
   setcursor(0)
   
   cPrevGL := cGLCode
   
   setcolor('w+/rb,n/w,,,')
   if lastkey() == K_ESC
      if KeyReview('RC') == 0
	     if cOption == 'E'
		    do case
			   case nOldColCnt == 1
			        nGLDtDebit  := nGLDtDebit + nOldAmount
			   case nOldColCnt == 2
			        nGLDtCredit := nGLDtCredit + nOldAmount
			endcase
		 endif
		 restscreen(,,,,cScrn)
		 exit
	  endif
   else
	   restscreen(,,,,cScrn)
	   OptionBar('INS-Add More GL  F2-Edit GL  DEL-Remove GL  ESC-Save/Exit')
	   
	   do case
	      case cOption == 'A'
		       aadd(aGLDtls, left(trans(cGLCode,'@R 9-99-99-9999-99')+' '+cGLName,44)+'³'+;
			                 trans(if(nColumnCnt==1,nAmount,0.00),'@Z 9,999,999,999.99')+'³'+;
							 trans(if(nColumnCnt==2,nAmount,0.00),'@Z 9,999,999,999.99')+right(cGLName,22)+str(nColumnCnt,1))
		  case cOption == 'E'
			   afill(aGLDtls, left(trans(cGLCode,'@R 9-99-99-9999-99')+' '+cGLName,44)+'³'+;
			                  trans(if(nColumnCnt==1,nAmount,0.00),'@Z 9,999,999,999.99')+'³'+;
							  trans(if(nColumnCnt==2,nAmount,0.00),'@Z 9,999,999,999.99')+right(cGLName,22)+str(nColumnCnt,1),nGLDtlsCnt,1)
	   endcase
	   
	   do case
	      case nColumnCnt == 1
		       nGLDtDebit  := nGLDtDebit + nAmount
		  case nColumnCnt == 2
		       nGLDtCredit := nGLDtCredit + nAmount
	   endcase
	   exit
   endif
enddo
return

***********************************
static function GetGLCode(lDV,nRow)
***********************************
local nCnt:=0
private nLftCol:=11, nBottRow:=21, nRghtCol:=77, nWidth:=38, nRecLen, nRecLineNo, cMessage:='GL'

setcolor('w/n,bg+/b,,,')
if cGLCode != cPrevGL .or. empty(cPrevGL)
   if !empty(cGLCode) .and. len(alltrim(cGLCode)) < 11
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr('GL Code is less than the acquired code. Press Any Key.',72) color 'w'
	  cGLCode := space(11)
	  inkey(0)
	  OptionBar('ESC-Exit')
	  return .f.
   endif
   
   do case
      case !empty(cGLCode)
	       if (gTmpGL)->glcode != cGLCode
			  (gTmpGL)->(dbsetorder(1))
		      nRECNO := (gTmpGL)->(recno())
			  if !(gTmpGL)->(dbseek(cGLCode))
				 @24,0 say ' ERROR: ' color 'r+'
				 @24,8 say padr('GL Code not found. Press Any Key.',72) color 'w'
				 (gTmpGL)->(dbgoto(nRECNO))
				 cGLCode := space(11)
				 inkey(0)
				 OptionBar('ESC-Exit')
				 return .f.
			  endif
		   endif
	  case empty(cGLCode)
		   nRECLEN := len(alltrim(str((gTmpGL)->(recc()))))
		   (gTmpGL)->(dbsetorder(2))
		   if empty(aGL)
			  (gTmpGL)->(dbgotop())
			  do while !(gTmpGL)->(eof())
				 aadd(aGL, (gTmpGL)->glname+'  '+trans((gTmpGL)->glcode,'@R 9-99-99-9999-99')+str((gTmpGL)->(recno()),nRecLen))
				 nCnt++
				 (gTmpGL)->(dbskip())
				 if nCnt == nMaxRLineNo
				    exit
				 endif
			  enddo
			  nRecLineNo := (gTmpGL)->(recno())
		   endif
		   
		   nGLCnt := RecBrowser(gTmpGL,'aGL',nGLCnt)
		   if nGLCnt == 0
		      return .f.
		   endif
		   cGLCode := (gTmpGL)->glcode
   endcase
   cGLName := (gTmpGL)->glname
   @nRow,27 say cGLName color 'gr+/r'
   
   if lDV .and. cGLCode == cBnkGLCd
      @9,11 say trans(cGLCode, '@R 9-99-99-9999-99') color 'w+/r'
	  @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr('Bank GL Code already added. Press Any Key.',72) color 'w'
	  inkey(0)
	  cGLCode := space(11)
	  @9,27 say space(len(cGLName)) color 'gr+/r'
	  OptionBar('ESC-Exit')
	  return .f.
   endif
endif
keyboard chr(K_ENTER)
return .t.
			 
*****************
function RecArr()
*****************
if !(cTmpDBF)->(eof())
   &cArrTmp := {}
   @nTopRow,nLftCol clear to nBottRow,nRghtCol
   for nCnt := 1 to nMaxRLineNo
       do case
	      case cArrTmp == 'aGL'
		       aadd(&cArrTmp, (gTmpGL)->glname+'  '+trans((gTmpGL)->glcode,'@R 9-99-99-9999-99')+str((gTmpGL)->(recno()),nRecLen))
	   endcase
	   (cTmpDBF)->(dbskip())
	   if (cTmpDBF)->(eof())
		  exit
	   endif
   next nCnt
   return .t.
endif
return .f.

************************
function GetColumn(nRow)
************************
local cScrn:=savescreen(,,,)

@nRow-1,11 to nRow+2,18
nColumnCnt := achoice(nRow,12,nRow+1,17,aColumn,,'AchUDF',nColumnCnt)
restscreen(,,,,cScrn)

if nColumnCnt == 0
   keyboard chr(K_ESC)
   return .f.
endif
cColumn := aColumn[nColumnCnt]
return .t.

*********************************************
function JVGLDtUDF(status,curr_elem,curr_row)
*********************************************
local nSeqNo, lInterBr:=.f., nDelColumn, nDelAmount, aGLDtDebit:={}, aGLDtCredit:={}, nReview

do case
   case lastkey() == K_INS
		GLDtAddEdit('A',.f.,8)
		nGLDtlsCnt := len(aGLDtls)
		return 1
   case lastkey() == K_F2
        nGLDtlsCnt := curr_elem
		GLDtAddEdit('E',.f.,8)
		return 1
   case lastkey() == K_DEL
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
		   restscreen(15,0,22,79,cGLDtScrn)
	       @24,0  say ' MESSAGE: ' color 'bg+'
		   @24,10 say padr('JV is discarded. Press Any Key.',70) color 'w'
		   inkey(0)
		endif
		
		asize(aGLDtls,len(aGLDtls)-1)
		nGLDtlsCnt := curr_elem
		return 1
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
					  
					  if !OL_PARAM->(dbseek('TRANHEAD'+'JVNUMBER  '+cVBrCode))
					     @24,0 say ' ERROR: ' color 'r+'
						 @24,8 say padr('JV Sequence Number not found. Press Any Key.',72) color 'w'
						 OL_PARAM->(dbclosearea())
						 inkey(0)
					  else
						 if OL_PARAM->lastseqnum == 29999999
					        @24,0 say ' ERROR: ' color 'r+'
							@24,8 say padr('JV Sequence Number has reached the maximum limit. Press Any Key.',72) color 'w'
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
							
							if !netuse('&g_GLAS_Path\JV_LOG',.f.,5)
						       OL_PARAM->(dbclosearea())
							   TRANHEAD->(dbclosearea())
							   TRANDTLS->(dbclosearea())
							   return 0
							endif
							set index to &g_GLAS_Path\JV_LOG
							
							@24,0  say ' MESSAGE: ' color 'bg+'
							@24,10 say padr('Saving Record. Kindly Wait...',70) color 'w'
							if TRANHEAD->(netlock('A'))
				               if OL_PARAM->(netlock('R'))
						          OL_PARAM->lastseqnum := nSeqNo := OL_PARAM->lastseqnum+1
								  OL_PARAM->(dbcommit())
							   endif
							   OL_PARAM->(dbunlock())
							   OL_PARAM->(dbclosearea())
							   
							   TRANHEAD->trancode   := '1'
							   TRANHEAD->trantype   := '1'
							   TRANHEAD->brcode     := cVBrCode
							   TRANHEAD->trnumber   := padl(nSeqNo,8,'0')
							   TRANHEAD->trandate   := dVTranDate
							   TRANHEAD->adjmntcode := cJVTCode
							   TRANHEAD->tramount   := nGLDtDebit
							   TRANHEAD->partix1    := cParti1
							   TRANHEAD->partix2    := cParti2
							   TRANHEAD->partix3    := cParti3
							   TRANHEAD->partix4    := cParti4
							   TRANHEAD->partix5    := cParti5
							   TRANHEAD->partix6    := cParti6
							   TRANHEAD->usercode   := cUserName
							   TRANHEAD->post_date  := date()
							   TRANHEAD->foraprvl   := 'E'
							   TRANHEAD->interbr    := lInterBr
							   TRANHEAD->(dbcommit())
							endif
							TRANHEAD->(dbunlock())
							
							for nCnt := 1 to len(aGLDtls)
							    if TRANDTLS->(netlock('A'))
						           TRANDTLS->trancode := '1'
								   TRANDTLS->brcode   := cVBrCode
								   TRANDTLS->trnumber := padl(nSeqNo,8,'0')
								   TRANDTLS->glcode   := strtran(left(aGLDtls[nCnt],15),'-','')
								   TRANDTLS->drcr     := right(aGLDtls[nCnt],1)
								   TRANDTLS->amount   := val(strtran(iif(right(aGLDtls[nCnt],1)=='1',substr(aGLDtls[nCnt],46,16), iif(right(aGLDtls[nCnt],1)=='2',substr(aGLDtls[nCnt],63,16), '0.00')),',',''))
								   TRANDTLS->(dbcommit())
								endif
								TRANDTLS->(dbunlock())
							next nCnt
							TRANDTLS->(dbclosearea())
							
							if JV_LOG->(netlock('A'))
						       JV_LOG->trancode  := '1'
							   JV_LOG->trantype  := '1'
							   JV_LOG->brcode    := cVBrCode
							   JV_LOG->trnumber  := padl(nSeqNo,8,'0')
							   JV_LOG->trandate  := dVTranDate
							   //if !empty(TRANHEAD->trpayee)
							      //JV_LOG->payor  := TRANHEAD->trpayee
							   //else
							      JV_LOG->payor  := cParti1
							   //endif
							   JV_LOG->amount    := nGLDtDebit
							   JV_LOG->post_date := date()
							   JV_LOG->(dbcommit())
							endif
							JV_LOG->(dbunlock())
							JV_LOG->(dbclosearea())
							AuditLog('g_GLAS_Path','Adds','JV No. '+cVBrCode+'-'+padl(nSeqNo,8,'0'))
							
							setcolor(',,,,w+/rb')
							
							aTranDtls  := aclone(aGLDtls)
							nTDtDebit  := nGLDtDebit
							nTDtCredit := nGLDtCredit
							lJVSaved   := .t.
							DispJVDtls(.f.)
						 endif
					  endif
					  return 0
				   endif
		   endcase
		else
		   if len(aGLDtls) <> len(aTranDtls)
		      lJVSaved := .t.
		   else
			  if nGLDtDebit <> nTDtDebit .or. nGLDtCredit <> nTDtCredit
			     lJVSaved := .t.
			  else
				 for nCnt := 1 to len(aGLDtls)
				     if aGLDtls[nCnt] <> aTranDtls[nCnt]
					    lJVSaved := .t.
						exit
					 endif
				 next nCnt
			  endif
		   endif
		   
		   if !lJVSaved
		      return 0
		   else
			  lJVSaved := .f.
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
						 
						 if !TRANHEAD->(dbseek(strtran(cJVNumber,'-','')))
						    @24,0 say ' ERROR: ' color 'r+'
							@24,8 say padr('JV not found. Press Any Key.',72) color 'w'
							TRANHEAD->(dbclosearea())
							inkey(0)
						 else
							if !netuse('&g_GLAS_Path\TRANDTLS',.f.,5)
							   TRANHEAD->(dbclosearea())
							   return 0
							endif
							set index to &g_GLAS_Path\TRANDTLS, &g_GLAS_Path\TRGLCODE
							
							if !TRANDTLS->(dbseek(strtran(cJVNumber,'-','')))
							   @24,0 say ' ERROR: ' color 'r+'
							   @24,8 say padr('GL Entries not found. Press Any Key.',72) color 'w'
							   TRANHEAD->(dbclosearea())
							   TRANDTLS->(dbclosearea())
							   inkey(0)
							else
							   if !netuse('&g_GLAS_Path\JV_LOG',.f.,5)
							      TRANHEAD->(dbclosearea())
								  TRANDTLS->(dbclosearea())
								  return 0
							   endif
							   set index to &g_GLAS_Path\JV_LOG
							   
							   if !JV_LOG->(dbseek(strtran(cJVNumber,'-','')))
							      @24,0 say ' ERROR: ' color 'r+'
								  @24,8 say padr('JV Log not found. Press Any Key.',72) color 'w'
								  TRANHEAD->(dbclosearea())
								  TRANDTLS->(dbclosearea())
								  JV_LOG->(dbclosearea())
								  inkey(0)
							   else
								  @24,0  say ' MESSAGE: ' color 'bg+'
								  @24,10 say padr('Saving Record. Kindly Wait...',70) color 'w'
								  if TRANHEAD->(netlock('R'))
								     TRANHEAD->tramount := nGLDtDebit
									 TRANHEAD->interbr  := lInterBr
									 TRANHEAD->(dbcommit())
								  endif
								  TRANHEAD->(dbunlock())
								  TRANHEAD->(dbclosearea())
								  
								  for nCnt := 1 to len(aGLDtls)
								      do case
									     case right(aGLDtls[nCnt],1) == '1'
										      aadd(aGLDtDebit, left(aGLDtls[nCnt],15)+substr(aGLDtls[nCnt],46,16))
										 case right(aGLDtls[nCnt],1) == '2'
										      aadd(aGLDtCredit, left(aGLDtls[nCnt],15)+substr(aGLDtls[nCnt],63,16))
									  endcase
								  next nCnt
								  
								  for nCnt := 1 to len(aGLDtDebit)
								      if TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cJVNumber,'-','') .and. TRANDTLS->drcr == '1'
										 SaveOldVal('TRANDTLS','AMOUNT')
										 if TRANDTLS->(netlock('R'))
										    TRANDTLS->glcode := strtran(left(aGLDtDebit[nCnt],15),'-','')
											TRANDTLS->drcr   := '1'
											TRANDTLS->amount := val(strtran(right(aGLDtDebit[nCnt],16),',',''))
											TRANDTLS->(dbcommit())
										 endif
										 TRANDTLS->(dbunlock())
										 AuditLog('g_GLAS_Path','Edits','GL Code '+left(aGLDtDebit[nCnt],15)+' for JV No. '+cJVNumber,'TRANDTLS','AMOUNT')
									  else
										 if TRANDTLS->(netlock('A'))
										    TRANDTLS->trancode := '1'
											TRANDTLS->brcode   := cVBrCode
											TRANDTLS->trnumber := right(cJVNumber,len(TRANDTLS->trnumber))
											TRANDTLS->glcode   := strtran(left(aGLDtDebit[nCnt],15),'-','')
											TRANDTLS->drcr     := '1'
											TRANDTLS->amount   := val(strtran(right(aGLDtDebit[nCnt],16),',',''))
											TRANDTLS->(dbcommit())
										 endif
										 TRANDTLS->(dbunlock())
										 AuditLog('g_GLAS_Path','Adds','GL Code '+left(aGLDtDebit[nCnt],15)+' for JV No. '+cJVNumber)
									  endif
									  TRANDTLS->(dbskip())
								  next nCnt
								  
								  if TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cJVNumber,'-','') .and. TRANDTLS->drcr == '1'
								     do while !TRANDTLS->(eof()) .and. TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cJVNumber,'-','') .and. TRANDTLS->drcr == '1'
									    AuditLog('g_GLAS_Path','Deletes','GL Code '+trans(TRANDTLS->glcode, '@R 9-99-99-9999-99')+' for JV No. '+cJVNumber)
										if TRANDTLS->(netlock('R'))
										   TRANDTLS->(dbdelete())
										endif
										TRANDTLS->(dbunlock())
										TRANDTLS->(dbskip())
									 enddo
								  endif
								  
								  for nCnt := 1 to len(aGLDtCredit)
								      if TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cJVNumber,'-','') .and. TRANDTLS->drcr == '2'
										 SaveOldVal('TRANDTLS','AMOUNT')
										 if TRANDTLS->(netlock('R'))
										    TRANDTLS->glcode := strtran(left(aGLDtCredit[nCnt],15),'-','')
											TRANDTLS->drcr   := '2'
											TRANDTLS->amount := val(strtran(right(aGLDtCredit[nCnt],16),',',''))
											TRANDTLS->(dbcommit())
										 endif
										 TRANDTLS->(dbunlock())
										 AuditLog('g_GLAS_Path','Edits','GL Code '+left(aGLDtCredit[nCnt],15)+' for JV No. '+cJVNumber,'TRANDTLS','AMOUNT')
									  else
										 if TRANDTLS->(netlock('A'))
										    TRANDTLS->trancode := '1'
											TRANDTLS->brcode   := cVBrCode
											TRANDTLS->trnumber := right(cJVNumber,len(TRANDTLS->trnumber))
											TRANDTLS->glcode   := strtran(left(aGLDtCredit[nCnt],15),'-','')
											TRANDTLS->drcr     := '2'
											TRANDTLS->amount   := val(strtran(right(aGLDtCredit[nCnt],16),',',''))
											TRANDTLS->(dbcommit())
										 endif
										 TRANDTLS->(dbunlock())
										 AuditLog('g_GLAS_Path','Adds','GL Code '+left(aGLDtCredit[nCnt],15)+' for JV No. '+cJVNumber)
									  endif
									  TRANDTLS->(dbskip())
								  next nCnt
								  
								  if TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cJVNumber,'-','') .and. TRANDTLS->drcr == '2'
								     do while !TRANDTLS->(eof()) .and. TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cJVNumber,'-','') .and. TRANDTLS->drcr == '2'
									    AuditLog('g_GLAS_Path','Deletes','GL Code '+trans(TRANDTLS->glcode, '@R 9-99-99-9999-99')+' for JV No. '+cJVNumber)
										if TRANDTLS->(netlock('R'))
										   TRANDTLS->(dbdelete())
										endif
										TRANDTLS->(dbunlock())
										TRANDTLS->(dbskip())
									 enddo
								  endif
								  TRANDTLS->(dbclosearea())
								  
								  if JV_LOG->(netlock('R'))
								     JV_LOG->amount := nGLDtDebit
									 JV_LOG->(dbcommit())
								  endif
								  JV_LOG->(dbunlock())
								  JV_LOG->(dbclosearea())
								  
								  aTranDtls  := aclone(aGLDtls)
								  nTDtDebit  := nGLDtDebit
								  nTDtCredit := nGLDtCredit
								  lJVSaved   := .t.
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

*******************************************
function VTabUDF(status,curr_elem,curr_row)
*******************************************
local cGLDtls

do case
   case lastkey() == K_UP .or.  lastkey() == K_DOWN
        restscreen(23,1,23,78,cGLNameScrn)
		cGLDtls := iif(lAddRFPUDF,aGLDtls[curr_elem],aTranDtls[curr_elem])
		if !empty(substr(cGLDtls,79,22))
		   @23,1 say ' Full GL Name: '+substr(cGLDtls,17,28)+alltrim(substr(cGLDtls,79,22))+' ' color 'n+/rb'
		endif
   case lastkey() == K_TAB .and. !lAddRFPUDF
        restscreen(23,1,23,78,cGLNameScrn)
		return 0
   case lastkey() == K_ESC .and. lAddRFPUDF
        return 0
   case lastkey() == K_ENTER .and. lAddRFPUDF
        restscreen(23,1,23,78,cGLNameScrn)
		return 1
endcase
return 2

*************************
function VSearch(cVCateg)
*************************
local cVNo:=space(8), cScrn:=savescreen(,,,)

do case
   case cVCateg == 'JV'
        DispJVScrn()
   case cVCateg == 'DV'
        DispDVScrn()
endcase
OptionBar('ESC-Exit')

@3,66 say '[SEARCH MODE]' color 'g/w'
if !SelTranBr(cVCateg,iif(cVCateg=='JV',10,iif(cVCateg=='DV',12,0)))
   restscreen(,,,,cScrn)
   return
endif
@4,14 say cVBrCode + '-' color 'bg+/b'

@4,18 get cVNo picture '99999999' color 'bg+/b' valid !empty(cVNo)
setcursor(1)
read
setcursor(0)

if lastkey() == K_ESC
   restscreen(,,,,cScrn)
else
   cVNo := padl(alltrim(cVNo),8,'0')
   @4,14 say cVBrCode + '-' + cVNo color 'b/w'
   
   if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
	  return
   endif
   set index to &g_GLAS_Path\TRANHEAD
   
   if !TRANHEAD->(dbseek(cVBrCode+cVNo))
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr(cVBrCode+'-'+cVNo+' not found. Press Any Key.',72) color 'w'
	  TRANHEAD->(dbclosearea())
	  inkey(0)
	  restscreen(,,,,cScrn)
   else
      if TRANHEAD->trancode == iif(cVCateg=='JV','1',iif(cVCateg=='DV','2',''))
		 aTranDtls  := {}
		 nTDtDebit  := 0
		 nTDtCredit := 0
		 @3,66 to 3,78 color 'n/w'
		 
		 if !netuse('&g_GLAS_Path\TRANDTLS',.f.,5)
		    TRANHEAD->(dbclosearea())
			return
		 endif
		 set index to &g_GLAS_Path\TRANDTLS
		 
		 do case
		    case cVCateg == 'JV'
			     DispJVDtls(.t.)
			case cVCateg == 'DV'
			     DispDVDtls(.t.)
		 endcase
	  else
		 do case
            case TRANHEAD->trancode == iif(cVCateg=='JV','2',iif(cVCateg=='DV','1',''))
				 @24,0  say ' MESSAGE: ' color 'bg+'
				 @24,10 say padr(cVBrCode+'-'+cVNo+' is in '+iif(cVCateg=='JV','Disbursement',iif(cVCateg=='DV','Journal',''))+' Voucher. Press Any Key.',70) color 'w'
            case TRANHEAD->trancode == '3'
				 @24,0  say ' MESSAGE: ' color 'bg+'
				 @24,10 say padr(cVBrCode+'-'+cVNo+' is in Adjustments. Press Any Key.',70) color 'w'
         endcase
		 TRANHEAD->(dbclosearea())
		 
		 inkey(0)
		 restscreen(,,,,cScrn)
	  endif
   endif
endif
return

******************************
function VCancel(cVCateg,nRow)
******************************
local cVNumber:=iif(cVCateg=='JV',cJVNumber,iif(cVCateg=='DV',cDVNumber,'')), cCancelRmk:=space(30), cCheckdBy, nICORecNo, lErrorICO:=.f.,;
      cScrn:=savescreen(,,,)

OptionBar('ESC-Exit')
@3,66 say '[CANCEL MODE]' color 'g/w'

@nRow-1,20,nRow+1,59 box 'ÚÄ¿³ÙÄÀ³ ' color 'w+/r'
@nRow,21 say 'Reason:' color 'w+/r'
@nRow,29 get cCancelRmk picture '@!' color 'w+/n' valid !empty(cCancelRmk)
setcursor(1)
read
setcursor(0)

if lastkey() == K_ESC
   restscreen(,,,,cScrn)
else
	@nRow,29 say cCancelRmk color 'w+/r'
	if keyreview('AC') == 0
	   restscreen(,,,,cScrn)
	else
	   if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
	      return
	   endif
	   set index to &g_GLAS_Path\TRANHEAD
	   
	   if !TRANHEAD->(dbseek(strtran(cVNumber,'-','')))
	      @24,0 say ' ERROR: ' color 'r+'
		  @24,8 say padr(cVCateg+' not found. Press Any Key.',72) color 'w'
		  TRANHEAD->(dbclosearea())
		  inkey(0)
		  restscreen(,,,,cScrn)
		  return
	   endif
	   
	   if TRANHEAD->trantype == '3'
	      @24,0 say ' ERROR: ' color 'r+'
		  @24,8 say padr(cVCateg+' already cancelled. Press Any Key.',72) color 'w'
		  cCancelRmk := TRANHEAD->cancelrmk
		  cStatCode  := TRANHEAD->trantype
		  cForAprvl  := TRANHEAD->foraprvl
		  cCheckdBy  := TRANHEAD->chckuser
		  TRANHEAD->(dbclosearea())
		  inkey(0)
		  restscreen(,,,,cScrn)
		  do case
		     case cVCateg == 'JV'
			      DispJVScr2()
			 case cVCateg == 'DV'
			      DispDVScr2()
		  endcase
		  @3,69-len(alltrim(cCheckdBy)) say ' CHECKED-'+alltrim(cCheckdBy)+' ' color 'w+/r'
		  @23,1 say ' Cancelled: '+alltrim(cCancelRmk)+' ' color 'w+/g'
		  OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+'F4-Search  ESC-Exit')
		  return
	   endif
	   
	   if !netuse('&g_GLAS_Path\TRANDTLS',.f.,5)
	      TRANHEAD->(dbclosearea())
		  return
	   endif
	   set index to &g_GLAS_Path\TRANDTLS, &g_GLAS_Path\TRGLCODE
	   
	   if !TRANDTLS->(dbseek(strtran(cVNumber,'-','')))
	      @24,0 say ' ERROR: ' color 'r+'
		  @24,8 say padr('GL Entries not found. Press Any Key.',72) color 'w'
		  TRANHEAD->(dbclosearea())
		  TRANDTLS->(dbclosearea())
		  inkey(0)
		  restscreen(,,,,cScrn)
		  return
	   endif
	   
	   if cVCateg == 'DV' .and. lRFPModule
	      if !netuse('&g_DAAS_Path\PAYEE',.f.,5)
		     TRANHEAD->(dbclosearea())
			 TRANDTLS->(dbclosearea())
		  return
		  endif
		  set index to &g_DAAS_Path\PAYEEDV
		  
		  if !PAYEE->(dbseek(right(cVNumber,8)))
		     @24,0 say ' ERROR: ' color 'r+'
			 @24,8 say padr("Payee's DV is missing in RFP. Press Any Key.",72) color 'w'
			 TRANHEAD->(dbclosearea())
			 TRANDTLS->(dbclosearea())
			 PAYEE->(dbclosearea())
			 inkey(0)
			 restscreen(,,,,cScrn)
			 return
		  endif
		  
		  if !netuse('&g_DAAS_Path\ACCTMAST',.f.,5)
		     TRANHEAD->(dbclosearea())
			 TRANDTLS->(dbclosearea())
			 PAYEE->(dbclosearea())
			 return
		  endif
		  set index to &g_DAAS_Path\ACCTMAST
		  
		  if !ACCTMAST->(dbseek(PAYEE->acctno))
		     @24,0 say ' ERROR: ' color 'r+'
			 @24,8 say padr("Payee's Account is missing in RFP. Press Any Key.",72) color 'w'
			 TRANHEAD->(dbclosearea())
			 TRANDTLS->(dbclosearea())
			 PAYEE->(dbclosearea())
			 ACCTMAST->(dbclosearea())
			 inkey(0)
			 restscreen(,,,,cScrn)
			 return
		  endif
		  
		  if PAYEE->type == '1'
		     if !netuse('&g_DAAS_Path\OTHPDET',.f.,5)
			    TRANHEAD->(dbclosearea())
				TRANDTLS->(dbclosearea())
				PAYEE->(dbclosearea())
				ACCTMAST->(dbclosearea())
				return
			 endif
			 set index to &g_DAAS_Path\OTHPDET
			 
			 if !OTHPDET->(dbseek(PAYEE->acctno))
			    @24,0 say ' ERROR: ' color 'r+'
				@24,8 say padr("Payee's ICO is missing in RFP. Press Any Key.",72) color 'w'
				TRANHEAD->(dbclosearea())
				TRANDTLS->(dbclosearea())
				PAYEE->(dbclosearea())
				ACCTMAST->(dbclosearea())
				OTHPDET->(dbclosearea())
				inkey(0)
				restscreen(,,,,cScrn)
				return
			 else
				nICORecNo := OTHPDET->(recno())
				do while !OTHPDET->(eof()) .and. OTHPDET->acctno == PAYEE->acctno
				   if OTHPDET->paycredit == 'Y' .and. OTHPDET->ornumber <> right(cVNumber,8) .and. iif(!empty(OTHPDET->payeecode),OTHPDET->payeecode==PAYEE->payeecode,.t.)
					  lErrorICO := .t.
					  exit
				   endif
				   OTHPDET->(dbskip())
				enddo
				
				if lErrorICO
				   @24,0 say ' ERROR: ' color 'r+'
				   @24,8 say padr('Discrepancy in ICO DV. Press Any Key.',72) color 'w'
				   TRANHEAD->(dbclosearea())
				   TRANDTLS->(dbclosearea())
				   PAYEE->(dbclosearea())
				   ACCTMAST->(dbclosearea())
				   OTHPDET->(dbclosearea())
				   inkey(0)
				   restscreen(,,,,cScrn)
				   return
				else
				   OTHPDET->(dbgoto(nICORecNo))
				endif
			 endif
		  endif
	   endif
	   
	   cStatCode := '3'
	   cForAprvl := 'C'
	   
	   if TRANHEAD->(netlock('R'))
	      TRANHEAD->trantype  := cStatCode
		  TRANHEAD->cancelrmk := cCancelRmk
		  TRANHEAD->foraprvl  := cForAprvl
		  TRANHEAD->chckuser  := cUserName
		  TRANHEAD->chckdate  := date()
		  TRANHEAD->chcktime  := time()
		  TRANHEAD->(dbcommit())
	   endif
	   TRANHEAD->(dbunlock())
	   TRANHEAD->(dbclosearea())
	   AuditLog('g_GLAS_Path','Cancels',cVCateg+' No. '+cVNumber)
	   
	   do while !TRANDTLS->(eof()) .and. TRANDTLS->brcode+TRANDTLS->trnumber == strtran(cVNumber,'-','')
	      if TRANDTLS->(netlock('R'))
		     TRANDTLS->(dbdelete())
		  endif
		  TRANDTLS->(dbunlock())
		  TRANDTLS->(dbskip())
	   enddo
	   TRANDTLS->(dbclosearea())
	   
	   restscreen(,,,,cScrn)
	   do case
	      case cVCateg == 'JV'
		       DispJVScr2()
		  case cVCateg == 'DV'
		       DispDVScr2()
			   if lRFPModule
			      if PAYEE->(netlock('R'))
				     PAYEE->dvnumber := space(8)
					 PAYEE->(dbcommit())
				  endif
				  PAYEE->(dbunlock())
				  
				  if PAYEE->type == '1'
				     do while !OTHPDET->(eof()) .and. OTHPDET->acctno == PAYEE->acctno
					    if OTHPDET->paycredit == 'Y' .and. OTHPDET->ornumber == right(cVNumber,8) .and. iif(!empty(OTHPDET->payeecode),OTHPDET->payeecode==PAYEE->payeecode,.t.)
						   if OTHPDET->(netlock('R'))
						      OTHPDET->status   := 'D'
							  OTHPDET->ornumber := space(8)
							  OTHPDET->ordate   := ctod('//')
							  OTHPDET->amtpaid  := 0
							  OTHPDET->oruser   := space(6)
							  OTHPDET->(dbcommit())
						   endif
						   OTHPDET->(dbunlock())
						endif
						OTHPDET->(dbskip())
					 enddo
					 OTHPDET->(dbclosearea())
				  endif
				  
				  if (gTmpPayee)->(netlock('A'))
					 (gTmpPayee)->aprvdate  := PAYEE->aprvdate
					 (gTmpPayee)->acctno    := PAYEE->acctno
					 (gTmpPayee)->payname   := PAYEE->payname
					 (gTmpPayee)->amount    := PAYEE->amount
					 (gTmpPayee)->valdate   := ACCTMAST->valdate
					 (gTmpPayee)->type      := PAYEE->type
					 (gTmpPayee)->payeecode := PAYEE->payeecode
					 (gTmpPayee)->vatincl   := PAYEE->vatincl
					 (gTmpPayee)->disi      := PAYEE->disi
					 (gTmpPayee)->acctname  := ACCTMAST->acctname
					 (gTmpPayee)->unit      := ACCTMAST->unit
					 (gTmpPayee)->jvnumber  := ACCTMAST->jvnumber
					 (gTmpPayee)->(dbcommit())
				  endif
				  (gTmpPayee)->(dbunlock())
				  PAYEE->(dbclosearea())
				  ACCTMAST->(dbclosearea())
				  
				  aadd(aPayee, dtoc((gTmpPayee)->aprvdate)+' '+trans((gTmpPayee)->acctno,'@R 999-99-99999-9')+' '+left((gTmpPayee)->payname,25)+' '+;
				               iif((gTmpPayee)->type=='1','PROCEEDS ',iif((gTmpPayee)->type=='2','INCENTIVE',space(9)))+' '+;
							   trans((gTmpPayee)->amount, '@Z 999,999,999.99')+str((gTmpPayee)->(recno()),5))
				  asort(aPayee)
			   endif
	   endcase
	   @3,69-len(alltrim(cUserName)) say ' CHECKED-'+alltrim(cUserName)+' ' color 'w+/r'
	   @23,1 say ' Cancelled: '+alltrim(cCancelRmk)+' ' color 'w+/g'
	   OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+'F4-Search  ESC-Exit')
	endif
endif
return

****************************
function VForChckng(cVCateg)
****************************
local cVNumber:=iif(cVCateg=='JV',cJVNumber,iif(cVCateg=='DV',cDVNumber,'')), cCheckdBy, cScrn:=savescreen(,,,)

@3,60 say '[FOR CHECKING MODE]' color 'g/w'
if keyreview('AC') == 0
   restscreen(,,,,cScrn)
else
   if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
	  return
   endif
   set index to &g_GLAS_Path\TRANHEAD
   
   if !TRANHEAD->(dbseek(strtran(cVNumber,'-','')))
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr(cVCateg+' not found. Press Any Key.',72) color 'w'
	  TRANHEAD->(dbclosearea())
	  inkey(0)
	  restscreen(,,,,cScrn)
   else
	  if !TRANHEAD->foraprvl $ 'ER'
	     @24,0 say ' ERROR: ' color 'r+'
		 @24,8 say padr(cVCateg+' already for checking. Press Any Key.',72) color 'w'
		 cForAprvl := TRANHEAD->foraprvl
		 if cForAprvl == 'C'
		    cCheckdBy := TRANHEAD->chckuser
		 endif
		 TRANHEAD->(dbclosearea())
		 inkey(0)
	  else
	     cCheckdBy := cUserName
		 cForAprvl := 'F'
		 if TRANHEAD->(netlock('R'))
		    TRANHEAD->foraprvl := cForAprvl
			if cForAprvl == 'C'
			   TRANHEAD->chckuser := cCheckdBy
			   TRANHEAD->chckdate := date()
			   TRANHEAD->chcktime := time()
			endif
			TRANHEAD->(dbcommit())
		 endif
		 TRANHEAD->(dbunlock())
		 TRANHEAD->(dbclosearea())
		 AuditLog('g_GLAS_Path','For Checking',cVCateg+' No. '+cVNumber)
	  endif
	  
	  @3,60 to 3,78 color 'n/w'
	  do case
	     case cForAprvl == 'F'
		      @3,65 say ' FOR CHECKING ' color 'w+/r'
		 case cForAprvl == 'C'
		      @3,69-len(alltrim(cCheckdBy)) say ' CHECKED-'+alltrim(cCheckdBy)+' ' color 'w+/r'
	  endcase
	  OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+'F4-Search  '+iif(cStatCode=='1','TAB-GL Entry  ','')+'ESC-Exit')
   endif
endif
return

******************************************
function SaveOldVal(cSourceDbf,cLastField)
******************************************
aOldVal := {}
for nFldCnt := 1 to (cSourceDbf)->(fieldpos(cLastField))
    aadd(aOldVal,(cSourceDbf)->(fieldget(nFldCnt)))
next nFldCnt
return

******************************************************************
function AuditLog(cPath,cAction,cIdentifier,cSourceDbf,cLastField)
******************************************************************
if !netuse(&cPath+'\DROP',.f.,5)
   return
endif
set index to (&cPath+'\DROP')

if cAction == 'Edits'
   for nFldCnt := 1 to (cSourceDbf)->(fieldpos(cLastField))
       if (cSourceDbf)->(fieldget(nFldCnt)) <> aOldVal[nFldCnt]
	      if DROP->(netlock('A'))
		     DROP->user_id := cUserName
			 DROP->date    := date()
			 DROP->time    := time()
			 DROP->action  := cAction+' '+cIdentifier+': '+cSourceDbf+'.'+(cSourceDbf)->(fieldname(nFldCnt))+' from '+alltrim(transform(aOldVal[nFldCnt],''))+;
			                  ' to '+alltrim(transform((cSourceDbf)->(fieldget(nFldCnt)),''))
			 DROP->(dbcommit())
		  endif
		  //lEdited := .t.
	   endif
   next nFldCnt
else
   if DROP->(netlock('A'))
      DROP->user_id := cUserName
	  DROP->date    := date()
	  DROP->time    := time()
	  DROP->action  := cAction+' '+cIdentifier
	  DROP->(dbcommit())
   endif
endif
DROP->(dbunlock())
DROP->(dbclosearea())
return