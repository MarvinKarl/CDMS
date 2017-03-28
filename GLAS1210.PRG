/*
PROGRAM     : GLAS1210.PRG
DESCRIPTION : DISBURSEMENT VOUCHER ENTRY WITH REQUEST FOR PAYMENT PROGRAM
AUTHOR      : ERLACHICA
CREATED     : JANUARY 18, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

#include "INKEY.CH"

private aBrAcs:={}, nSelBrCnt:=1, dVTranDate, cVBrCode:=left(cSelectBr,3), cStatCode, cDVNumber, cCheckNo, cPreprdBy, cForAprvl,;
        aPayee:={}, cDfltBnkCd, cDfltBnkNm, cDfltBnkGL
private aTranDtls:={}, nTDtDebit:=0, nTDtCredit:=0, aOldVal:={}, cGLNameScrn
private lRFPModule:=.t., lAddRFPUDF

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

if !netuse('&g_RFM_Path\BANKACCT',.f.,5)
   return
endif
locate for BANKACCT->defaultdv

if !BANKACCT->(found())
   @24,0 say ' ERROR: ' color 'r+'
   @24,8 say padr('No Default Bank Account found. Press Any Key.',72) color 'w'
   inkey(0)
   return
endif
cDfltBnkCd := BANKACCT->bankcode
cDfltBnkNm := alltrim(BANKACCT->bankname)
cDfltBnkGL := BANKACCT->glcode
BANKACCT->(dbclosearea())

if !OpenTmpGL()
   return
endif

if !netuse('&g_GLAS_Tmp\&gTmpPayee',.f.,5)
   return
endif
set index to (g_GLAS_Tmp+'\'+gTmpPayee)

do while !(gTmpPayee)->(eof())
   aadd(aPayee, dtoc((gTmpPayee)->aprvdate)+' '+trans((gTmpPayee)->acctno,'@R 999-99-99999-9')+' '+left((gTmpPayee)->payname,25)+' '+;
                iif((gTmpPayee)->type=='1','PROCEEDS ',iif((gTmpPayee)->type=='2','INCENTIVE',space(9)))+' '+;
				trans((gTmpPayee)->amount, '@Z 999,999,999.99')+str((gTmpPayee)->(recno()),5))
   (gTmpPayee)->(dbskip())
enddo

OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+'F4-Search  ESC-Exit')
cGLDtScrn := savescreen(18,0,22,79)
do while .t.
   inkey(0)
   do case
      case lastkey() == K_INS .and. 'ADD'$cModAccess
	       DVAddEdit('A')
	  case lastkey() == K_F2 .and. 'EDIT'$cModAccess .and. cStatCode == '1' .and. left(cPreprdBy,3) == 'SG1' .and. cForAprvl$'ER'
		   DVAddEdit('E')
	  case lastkey() == K_F4
	       VSearch('DV')
	  case lastkey() == K_F6 .and. 'CANCEL'$cModAccess .and. cStatCode == '1' .and. left(cPreprdBy,3) == 'SG1' .and. cForAprvl$'ER'
	       VCancel('DV',11,.t.)
	  case lastkey() == K_TAB .and. cStatCode == '1'
	       setcolor('w+/rb,n/w,,,w+/rb')
		   cGLNameScrn := savescreen(23,1,23,78)
		   if !empty(substr(aTranDtls[1],79,22))
		      @23,1 say ' Full GL Name: '+substr(aTranDtls[1],17,28)+alltrim(substr(aTranDtls[1],79,22))+' ' color 'n+/rb'
		   endif
		   OptionBar('TAB-Go Back')
		   
		   lAddRFPUDF := .f.
		   achoice(18,1,20,78,aTranDtls,,'VTabUDF')
		   OptionBar(iif('ADD'$cModAccess,'INS-Add  ','')+;
		             iif('EDIT'$cModAccess .and. cStatCode=='1' .and. left(cPreprdBy,3)=='SG1' .and. cForAprvl$'R','F2-Edit  ','')+'F4-Search  '+;
					 iif('CANCEL'$cModAccess .and. cStatCode=='1' .and. left(cPreprdBy,3)=='SG1' .and. cForAprvl$'R','F6-Cancel  ','')+;
					 iif(cStatCode=='1','TAB-GL Entry  ','')+'ESC-Exit')
	  case lastkey() == K_ESC
	       exit
   endcase
enddo
close databases
return

**********************************
static function DVAddEdit(cOption)
**********************************
local cPyee, nAmt, cBnkBrCd, cBnkBrNm, cParti1, cParti2, cParti3, cParti4:='',;
	  nSeqNo, aGLCode:={}, nGLCodeCnt, nSameGLAmt, nVAT:=0, nWTax, nNetOfVAT, lInterBr:=.f., nPayeeCnt, nICORecNo, lErrorICO:=.f.,;
	  nReview, cScrn:=savescreen(,,,)
private cChkNo:=iif(cOption=='A',space(15),cCheckNo), cPrevChkNo, aGLDtls:={}, nGLDtDebit:=0, nGLDtCredit:=0

OptionBar('ESC-Exit')
if cOption == 'A'
   DispDVScrn()
   setcolor('w/n,bg+/b')
   @3,69 say '[ADD MODE]' color 'g/w'
   
   if len(aPayee) == 0
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr('No Approved Request for Payment found. Press Any Key.',72) color 'w'
	  inkey(0)
	  restscreen(,,,,cScrn)
	  return
   endif
   
   if !SelTranBr('DV',12)
      restscreen(,,,,cScrn)
	  return
   endif
   
   cBnkBrCd := substr(aBrAcs[nSelBrCnt],31,3)
   cBnkBrNm := left(aBrAcs[nSelBrCnt],30)
   
   @5,1 to iif(len(aPayee)<10,6+len(aPayee)+1,17),78
   @5,2 say ' Payee '
   @6,2 say ' Approved    Account N§             Payee           Classfctn      Amount   ' color 'w/n'
   nPayeeCnt := achoice(7,2,iif(len(aPayee)<10,7+len(aPayee)-1,16),77,aPayee,,'AchUDF')
   
   restscreen(,,,,cScrn)
   if nPayeeCnt == 0
	  return
   else
	  DispDVScrn()
	  @3,69 say '[ADD MODE]' color 'g/w'
	  (gTmpPayee)->(dbgoto(val(right(aPayee[nPayeeCnt],5))))
	  
	  if !substr((gTmpPayee)->acctno,4,2) $ '51 81 91 92'  // Product is FLR/CML/ASTR/ALTR
	     if !netuse('&g_DAAS_Path\PRODUCT',.f.,5)
		    return
		 endif
		 set index to &g_DAAS_Path\PRODUCT
		 
		 PRODUCT->(dbseek(substr((gTmpPayee)->acctno,4,2)))
		 @24,0 say ' ERROR: ' color 'r+'
		 @24,8 say padr('Product '+alltrim(PRODUCT->fcltyalias)+' is not available in GLAS. Press Any Key.',72) color 'w'
		 PRODUCT->(dbclosearea())
		 inkey(0)
		 restscreen(,,,,cScrn)
		 return
	  endif
	  
	  cPyee := (gTmpPayee)->payname
	  @4,14 say cVBrCode+'-99999999' color 'b/w'
	  @4,54 say dVTranDate color 'n/w'
	  @5,14 say left(cPyee,65) color 'n/w'
	  @7,14 say cBnkBrCd color 'n/w'
	  @7,18 say cBnkBrNm color 'gr/w'
	  @8,14 say cDfltBnkCd color 'n/w'
	  @8,18 say cDfltBnkNm color 'gr/w'
	  
	  do case
	     case (gTmpPayee)->type == '1'  // Proceeds
		      do case
			     case substr((gTmpPayee)->acctno,4,2) == '51'  // Product is FLR
				      cParti1 := 'PAYMENT FOR '+upper(alltrim((gTmpPayee)->unit))
					  cParti2 := 'ACCT#: FLR '+trans((gTmpPayee)->acctno,'@R 999-99-99999-9')
					  cParti3 := 'CLIENT NAME: '+alltrim((gTmpPayee)->acctname)
					  cParti4 := 'PER JV#'+cVBrCode+'-'+(gTmpPayee)->jvnumber+' DTD '+;
					             left(dtoc((gTmpPayee)->valdate),2)+'.'+substr(dtoc((gTmpPayee)->valdate),4,2)+'.'+right(dtoc((gTmpPayee)->valdate),2)
				 case substr((gTmpPayee)->acctno,4,2) == '81' .or. substr((gTmpPayee)->acctno,4,2) == '91' .or.;
				      substr((gTmpPayee)->acctno,4,2) == '92'  // Product is CML/ASTR/ALTR
					  cParti1 := 'LOAN PROCEEDS FAO '+trans((gTmpPayee)->acctno,'@R 999-99-99999-9')+' '+alltrim((gTmpPayee)->acctname)
					  cParti2 := 'SECURITY: '+upper(alltrim((gTmpPayee)->unit))
					  cParti3 := 'PER JV#'+cVBrCode+'-'+(gTmpPayee)->jvnumber+' DATED '+;
					             left(dtoc((gTmpPayee)->valdate),2)+'.'+substr(dtoc((gTmpPayee)->valdate),4,2)+'.'+right(dtoc((gTmpPayee)->valdate),2)
			  endcase
			  @9,14  say left(cParti1,65) color 'n/w'
			  @10,14 say left(cParti2,65) color 'n/w'
			  @11,14 say left(cParti3,65) color 'n/w'
			  @12,14 say left(cParti4,65) color 'n/w'
			  
			  if !netuse('&g_RFM_Path\ORJVGL',.f.,5)
			     return
			  endif
			  set index to &g_RFM_Path\ORJVGL
			  
			  if !ORJVGL->(dbseek(left((gTmpPayee)->acctno,3)+'3'+substr((gTmpPayee)->acctno,4,2)+'  '+'1'))
			     @24,0 say ' ERROR: ' color 'r+'
				 @24,8 say padr('No GL mapping found. Press Any Key.',72) color 'w'
				 ORJVGL->(dbclosearea())
				 inkey(0)
				 restscreen(,,,,cScrn)
				 return
			  else
				 if !netuse('&g_DAAS_Path\OTHPDET',.f.,5)
				    return
				 endif
				 set index to &g_DAAS_Path\OTHPDET
				 
				 if !OTHPDET->(dbseek((gTmpPayee)->acctno))
				    @24,0 say ' ERROR: ' color 'r+'
					@24,8 say padr('No ICO Details found. Press Any Key.',72) color 'w'
					ORJVGL->(dbclosearea())
					OTHPDET->(dbclosearea())
					inkey(0)
					restscreen(,,,,cScrn)
					return
				 else
					if (gTmpGL)->(dbseek(ORJVGL->glcode))
					   nGLDtDebit := (gTmpPayee)->amount
					   aadd(aGLDtls, left(trans(ORJVGL->glcode,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
					                 trans(nGLDtDebit,'@Z 9,999,999,999.99')+'³'+;
									 trans(0.00,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'1')
					endif
					
					do while !OTHPDET->(eof()) .and. OTHPDET->acctno == (gTmpPayee)->acctno
					   if OTHPDET->paycredit == 'Y' .and. iif(!empty(OTHPDET->payeecode),OTHPDET->payeecode==(gTmpPayee)->payeecode,.t.)
					      if !ORJVGL->(dbseek(left(OTHPDET->acctno,3)+'3'+substr(OTHPDET->acctno,4,2)+OTHPDET->payclass+'2'))
						     @24,0 say ' ERROR: ' color 'r+'
							 @24,8 say padr('No ICO GL mapping found. Press Any Key.',72) color 'w'
							 ORJVGL->(dbclosearea())
							 OTHPDET->(dbclosearea())
							 inkey(0)
							 restscreen(,,,,cScrn)
							 return
						  else
							 if empty(aGLCode)
								if (gTmpGL)->(dbseek(ORJVGL->glcode))
								   aadd(aGLCode, ORJVGL->glcode)
								   aadd(aGLDtls, left(trans(ORJVGL->glcode,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
								                 trans(0.00,'@Z 9,999,999,999.99')+'³'+;
												 trans(OTHPDET->amount,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'2')
								endif
							 else
								nGLCodeCnt := ascan(aGLCode,{|x| x==ORJVGL->glcode})
								if nGLCodeCnt == 0
								   if (gTmpGL)->(dbseek(ORJVGL->glcode))
								      aadd(aGLCode, ORJVGL->glcode)
									  aadd(aGLDtls, left(trans(ORJVGL->glcode,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
									                trans(0.00,'@Z 9,999,999,999.99')+'³'+;
													trans(OTHPDET->amount,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'2')
								   endif
								else
								   if (gTmpGL)->(dbseek(ORJVGL->glcode))
								      nSameGLAmt := val(strtran(substr(aGLDtls[nGLCodeCnt+1],63,16),',',''))
									  afill(aGLDtls, left(aGLDtls[nGLCodeCnt+1],62)+trans(nSameGLAmt+OTHPDET->amount,'@Z 9,999,999,999.99')+;
									                 substr(aGLDtls[nGLCodeCnt+1],79), nGLCodeCnt+1, 1)
								   endif
								endif
							 endif
							 nGLDtCredit := nGLDtCredit + OTHPDET->amount
						  endif
					   endif
					   OTHPDET->(dbskip())
					enddo
					OTHPDET->(dbclosearea())
					ORJVGL->(dbclosearea())
				 endif
				 
				 nAmt := (gTmpPayee)->amount - nGLDtCredit
				 @6,14 say alltrim(trans(nAmt,'@Z 9,999,999,999.99')) color 'n/w'
				 
				 if (gTmpGL)->(dbseek(cDfltBnkGL))
				    aadd(aGLDtls, left(trans(cDfltBnkGL,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
					              trans(0.00,'@Z 9,999,999,999.99')+'³'+;
								  trans(nAmt,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'2')
					nGLDtCredit := (gTmpPayee)->amount
				 endif
			  endif
		 case (gTmpPayee)->type == '2'  // Incentive
		      cParti1 := iif((gTmpPayee)->disi=='1',"DEALER'S",iif((gTmpPayee)->disi=='2','SALESMAN',''))+' INCENTIVE FAO '+;
			             trans((gTmpPayee)->acctno,'@R 999-99-99999-9')+' '+alltrim((gTmpPayee)->acctname)
			  cParti2 := 'SECURITY: '+upper(alltrim((gTmpPayee)->unit))
			  cParti3 := 'PER JV#'+cVBrCode+'-'+(gTmpPayee)->jvnumber+' DATED '+;
			             left(dtoc((gTmpPayee)->valdate),2)+'.'+substr(dtoc((gTmpPayee)->valdate),4,2)+'.'+right(dtoc((gTmpPayee)->valdate),2)
			  @9,14  say left(cParti1,65) color 'n/w'
			  @10,14 say left(cParti2,65) color 'n/w'
			  @11,14 say left(cParti3,65) color 'n/w'
			  
			  if !netuse('&g_RFM_Path\ORJVGL',.f.,5)
			     return
			  endif
			  set index to &g_RFM_Path\ORJVGL
			  
			  if !ORJVGL->(dbseek(left((gTmpPayee)->acctno,3)+'3'+substr((gTmpPayee)->acctno,4,2)+'  '+'1'))
			     @24,0 say ' ERROR: ' color 'r+'
				 @24,8 say padr('No GL mapping found. Press Any Key.',72) color 'w'
				 ORJVGL->(dbclosearea())
				 inkey(0)
				 restscreen(,,,,cScrn)
				 return
			  else
				 if !(gTmpPayee)->with_wtax
				    if (gTmpGL)->(dbseek(ORJVGL->glcode))
					   nGLDtDebit := (gTmpPayee)->amount
					   aadd(aGLDtls, left(trans(ORJVGL->glcode,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
					                 trans(nGLDtDebit,'@Z 9,999,999,999.99')+'³'+;
									 trans(0.00,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'1')
					endif
					ORJVGL->(dbclosearea())
				 else
				    if !netuse('&g_RFM_Path\DEFLTVAL',.f.,5)
					   return
					endif
					set index to &g_RFM_Path\DEFLTVAL
					
					if (gTmpPayee)->vatincl
					   if !DEFLTVAL->(dbseek(padr('VAT',10)))
					      @24,0 say ' ERROR: ' color 'r+'
						  @24,8 say padr('No VAT value found. Press Any Key.',72) color 'w'
						  ORJVGL->(dbclosearea())
						  DEFLTVAL->(dbclosearea())
						  inkey(0)
						  restscreen(,,,,cScrn)
						  return
					   else
						  nVAT := val(DEFLTVAL->defltvalue)
					   endif
					endif
					
					if !DEFLTVAL->(dbseek(padr('WTAX',10)))
					   @24,0 say ' ERROR: ' color 'r+'
					   @24,8 say padr('No Withholding Tax value found. Press Any Key.',72) color 'w'
					   ORJVGL->(dbclosearea())
					   DEFLTVAL->(dbclosearea())
					   inkey(0)
					   restscreen(,,,,cScrn)
					   return
					else
					   nWTax := val(DEFLTVAL->defltvalue)
					endif
					DEFLTVAL->(dbclosearea())
					
					if (gTmpGL)->(dbseek(ORJVGL->glcode))
					   nNetOfVAT  := (gTmpPayee)->amount / ((1 + nVAT) - nWTax)
					   nGLDtDebit := nNetOfVAT + (nNetOfVAT * nVAT)
					   aadd(aGLDtls, left(trans(ORJVGL->glcode,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
					                 trans(nGLDtDebit,'@Z 9,999,999,999.99')+'³'+;
									 trans(0.00,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'1')
					endif
					
					if !ORJVGL->(dbseek(left((gTmpPayee)->acctno,3)+'3'+substr((gTmpPayee)->acctno,4,2)+'  '+'2'))
					   @24,0 say ' ERROR: ' color 'r+'
					   @24,8 say padr('No WTax GL mapping found. Press Any Key.',72) color 'w'
					   ORJVGL->(dbclosearea())
					   inkey(0)
					   restscreen(,,,,cScrn)
					   return
					else
					   if (gTmpGL)->(dbseek(ORJVGL->glcode))
					      nGLDtCredit := nNetOfVAT * nWTax
						  aadd(aGLDtls, left(trans(ORJVGL->glcode,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
						                trans(0.00,'@Z 9,999,999,999.99')+'³'+;
										trans(nGLDtCredit,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'2')
					   endif
					   ORJVGL->(dbclosearea())
					endif
				 endif
				 
				 nAmt := (gTmpPayee)->amount
				 @6,14 say alltrim(trans(nAmt,'@Z 9,999,999,999.99')) color 'n/w'
				 
				 if (gTmpGL)->(dbseek(cDfltBnkGL))
				    aadd(aGLDtls, left(trans(cDfltBnkGL,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
					              trans(0.00,'@Z 9,999,999,999.99')+'³'+;
								  trans(nAmt,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'2')
					nGLDtCredit := nGLDtCredit + (gTmpPayee)->amount
				 endif
			  endif
	  endcase
	  
	  if substr(aGLDtls[1],10,1) == '8' .and. substr(aGLDtls[1],10,3) <> cVBrCode
	     lInterBr := .t.
	  endif
	  
	  setcolor('w+/rb,n/w')
	  @22,46 say trans(nGLDtDebit, '@Z 9,999,999,999.99')
	  @22,63 say trans(nGLDtCredit, '@Z 9,999,999,999.99')
	  
	  cGLNameScrn := savescreen(23,1,23,78)
	  if !empty(substr(aGLDtls[1],79,22))
	     @23,1 say ' Full GL Name: '+substr(aGLDtls[1],17,28)+alltrim(substr(aGLDtls[1],79,22))+' ' color 'n+/rb'
	  endif
	  OptionBar('ENTER-Continue  ESC-Exit')
	  
	  lAddRFPUDF := .t.
	  if achoice(18,1,20,78,aGLDtls,,'VTabUDF') == 0
	     restscreen(,,,,cScrn)
		 return
	  endif
   endif
endif

OptionBar('ESC-Exit')
do while .t.
   setcolor('w/n,bg+/b,,,n/w')
   @6,54 get cChkNo picture '@!K' valid !empty(cChkNo) .and. GetCheckNo(cOption)
   setcursor(1)
   read
   setcursor(0)
   
   cPrevChkNo := cChkNo
   
   if lastkey() == K_ESC
      if KeyReview('RC') == 0
	     restscreen(,,,,cScrn)
		 exit
	  endif
   else
	  nReview := KeyReview('ARC')
	  do case
	     case nReview == 0
			  restscreen(,,,,cScrn)
			  exit
		 case nReview == 2
		      if cOption == 'A'
			     if round(nGLDtDebit,2) <> round(nGLDtCredit,2)
				    @24,0 say ' ERROR: ' color 'r+'
					@24,8 say padr('GL Entries are not balance. Press Any Key.',72) color 'w'
					inkey(0)
					restscreen(,,,,cScrn)
					return
				 endif
				 
				 if !netuse('&g_RFM_Path\OL_PARAM',.f.,5)
				    return
				 endif
				 set index to &g_RFM_Path\OL_PARAM
				 
				 if !OL_PARAM->(dbseek('TRANHEAD'+'DVNUMBER  '+cVBrCode))
				    @24,0 say ' ERROR: ' color 'r+'
					@24,8 say padr('DV Sequence Number not found. Press Any Key.',72) color 'w'
					OL_PARAM->(dbclosearea())
					inkey(0)
					restscreen(,,,,cScrn)
					return
				 else
					if OL_PARAM->lastseqnum == 39999999
					   @24,0 say ' ERROR: ' color 'r+'
					   @24,8 say padr('DV Sequence Number has reached the maximum limit. Press Any Key.',72) color 'w'
					   OL_PARAM->(dbclosearea())
					   inkey(0)
					   restscreen(,,,,cScrn)
					   return
					endif
				 endif
				 
				 if !netuse('&g_DAAS_Path\PAYEE',.f.,5)
				    OL_PARAM->(dbclosearea())
					return
				 endif
				 set index to &g_DAAS_Path\PAYEE, &g_DAAS_Path\PAYEEDV
				 
				 if !PAYEE->(dbseek((gTmpPayee)->acctno+(gTmpPayee)->type+(gTmpPayee)->payeecode))
				    @24,0 say ' ERROR: ' color 'r+'
					@24,8 say padr('Payee is missing in RFP. Press Any Key.',72) color 'w'
					OL_PARAM->(dbclosearea())
					PAYEE->(dbclosearea())
					inkey(0)
					restscreen(,,,,cScrn)
					return
				 else
					if !empty(PAYEE->dvnumber)
					   @24,0 say ' ERROR: ' color 'r+'
					   @24,8 say padr('Payee has a DV. Press Any Key.',72) color 'w'
					   OL_PARAM->(dbclosearea())
					   PAYEE->(dbclosearea())
					   inkey(0)
					   restscreen(,,,,cScrn)
					   return
					endif
				 endif
				 
				 if (gTmpPayee)->type == '1'
				    if !netuse('&g_DAAS_Path\OTHPDET',.f.,5)
					   OL_PARAM->(dbclosearea())
					   PAYEE->(dbclosearea())
					   return
					endif
					set index to &g_DAAS_Path\OTHPDET
					
					if !OTHPDET->(dbseek((gTmpPayee)->acctno))
					   @24,0 say ' ERROR: ' color 'r+'
					   @24,8 say padr('ICO is missing in RFP. Press Any Key.',72) color 'w'
					   OL_PARAM->(dbclosearea())
					   PAYEE->(dbclosearea())
					   OTHPDET->(dbclosearea())
					   inkey(0)
					   restscreen(,,,,cScrn)
					   return
					else
					   nICORecNo := OTHPDET->(recno())
					   do while !OTHPDET->(eof()) .and. OTHPDET->acctno == (gTmpPayee)->acctno
					      if OTHPDET->paycredit == 'Y' .and. iif(!empty(OTHPDET->payeecode),OTHPDET->payeecode==(gTmpPayee)->payeecode,.t.)
							 if OTHPDET->status == 'P' .or. !empty(OTHPDET->ornumber) .or. !empty(OTHPDET->ordate) .or. !empty(OTHPDET->amtpaid)
							    lErrorICO := .t.
								exit
							 endif
						  endif
						  OTHPDET->(dbskip())
					   enddo
					   
					   if lErrorICO
					      @24,0 say ' ERROR: ' color 'r+'
						  @24,8 say padr('ICO is paid. Press Any Key.',72) color 'w'
						  OL_PARAM->(dbclosearea())
						  PAYEE->(dbclosearea())
						  OTHPDET->(dbclosearea())
						  inkey(0)
						  restscreen(,,,,cScrn)
						  return
					   else
						  OTHPDET->(dbgoto(nICORecNo))
					   endif
					endif
				 endif
				 
				 if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
				    OL_PARAM->(dbclosearea())
					PAYEE->(dbclosearea())
					if (gTmpPayee)->type == '1'
					   OTHPDET->(dbclosearea())
					endif
					return
				 endif
				 set index to &g_GLAS_Path\TRANHEAD, &g_GLAS_Path\TRANCODE, &g_GLAS_Path\TRANBANK, &g_GLAS_Path\TRANLCRJ, &g_GLAS_Path\TRANDATE
				 
				 if !netuse('&g_GLAS_Path\TRANDTLS',.f.,5)
				    OL_PARAM->(dbclosearea())
					PAYEE->(dbclosearea())
					if (gTmpPayee)->type == '1'
					   OTHPDET->(dbclosearea())
					endif
					TRANHEAD->(dbclosearea())
					return
				 endif
				 set index to &g_GLAS_Path\TRANDTLS, &g_GLAS_Path\TRGLCODE
				 
				 if !netuse('&g_GLAS_Path\DV_LOG',.f.,5)
				    OL_PARAM->(dbclosearea())
					PAYEE->(dbclosearea())
					if (gTmpPayee)->type == '1'
					   OTHPDET->(dbclosearea())
					endif
					TRANHEAD->(dbclosearea())
					TRANDTLS->(dbclosearea())
					return
				 endif
				 set index to &g_GLAS_Path\DV_LOG
				 
				 @24,0  say ' MESSAGE: ' color 'bg+'
				 @24,10 say padr('Saving Record. Kindly Wait...',70) color 'w'
				 
				 if PAYEE->(netlock('R'))
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
					   TRANHEAD->trcheck   := cChkNo
					   TRANHEAD->brtrbank  := cBnkBrCd
					   TRANHEAD->trbank    := cDfltBnkCd
					   TRANHEAD->partix1   := cParti1
					   TRANHEAD->partix2   := cParti2
					   TRANHEAD->partix3   := cParti3
					   TRANHEAD->partix4   := cParti4
					   TRANHEAD->usercode  := 'SG1'+cUserName
					   TRANHEAD->post_date := date()
					   TRANHEAD->interbr   := lInterBr
					   TRANHEAD->foraprvl := 'C'
					   TRANHEAD->chckuser := cUserName
					   TRANHEAD->chckdate := date()
					   TRANHEAD->chcktime := time()
					   TRANHEAD->(dbcommit())
					endif
					TRANHEAD->(dbunlock())
					
					PAYEE->dvnumber := padl(nSeqNo,8,'0')
					PAYEE->(dbcommit())
					
					if (gTmpPayee)->type == '1'
					   do while !OTHPDET->(eof()) .and. OTHPDET->acctno == (gTmpPayee)->acctno
					      OTHPDET->(dbskip())
						  nICORecNo := OTHPDET->(recno())
						  OTHPDET->(dbskip(-1))
						  if OTHPDET->paycredit == 'Y' .and. iif(!empty(OTHPDET->payeecode),OTHPDET->payeecode==(gTmpPayee)->payeecode,.t.)
							 if OTHPDET->status == 'D' .and. empty(OTHPDET->ornumber) .and. empty(OTHPDET->ordate) .and. empty(OTHPDET->amtpaid)
							    if OTHPDET->(netlock('R'))
								   OTHPDET->status   := 'P'
								   OTHPDET->ornumber := padl(nSeqNo,8,'0')
								   OTHPDET->ordate   := dVTranDate
								   OTHPDET->amtpaid  := OTHPDET->amount
								   OTHPDET->oruser   := cUserName
								   OTHPDET->(dbcommit())
								endif
								OTHPDET->(dbunlock())
							 endif
						  endif
						  OTHPDET->(dbgoto(nICORecNo))
					   enddo
					   OTHPDET->(dbclosearea())
					endif
				 endif
				 PAYEE->(dbunlock())
				 PAYEE->(dbclosearea())
				 
				 for nCnt := 1 to len(aGLDtls)
				     if TRANDTLS->(netlock('A'))
					    TRANDTLS->trancode := '2'
						TRANDTLS->brcode   := cVBrCode
						TRANDTLS->trnumber := padl(nSeqNo,8,'0')
						TRANDTLS->glcode   := strtran(left(aGLDtls[nCnt],15),'-','')
						TRANDTLS->drcr     := right(aGLDtls[nCnt],1)
						TRANDTLS->amount   := val(strtran(iif(right(aGLDtls[nCnt],1)=='1',substr(aGLDtls[nCnt],46,16),;
						                      iif(right(aGLDtls[nCnt],1)=='2',substr(aGLDtls[nCnt],63,16), '0.00')),',',''))
						TRANDTLS->(dbcommit())
					 endif
					 TRANDTLS->(dbunlock())
				 next nCnt
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
				 
				 if (gTmpPayee)->(netlock('R'))
					(gTmpPayee)->(dbdelete())
				 endif
				 (gTmpPayee)->(dbunlock())
				 
				 for nCnt := nPayeeCnt to len(aPayee)
				     if nCnt <> len(aPayee)
					    afill(aPayee,aPayee[nCnt+1],nCnt,1)
					 endif
				 next nCnt
				 asize(aPayee,len(aPayee)-1)
				 
				 AuditLog('g_GLAS_Path','Adds','DV No. '+cVBrCode+'-'+padl(nSeqNo,8,'0'))
				 
				 setcolor(',,,,w+/rb')
				 aTranDtls  := aclone(aGLDtls)
				 nTDtDebit  := nGLDtDebit
				 nTDtCredit := nGLDtCredit
				 DispDVDtls(.f.)
				 exit
			  else  // save edit
				 if !netuse('&g_GLAS_Path\TRANHEAD',.f.,5)
				    return
				 endif
				 set index to &g_GLAS_Path\TRANHEAD
				 
				 if !TRANHEAD->(dbseek(strtran(cDVNumber,'-','')))
				    @24,0 say ' ERROR: ' color 'r+'
					@24,8 say padr('DV not found. Press Any Key.',72) color 'w'
					TRANHEAD->(dbclosearea())
					inkey(0)
					return
				 else
					SaveOldVal('TRANHEAD','TRCHECK')
					if TRANHEAD->(netlock('R'))
					   TRANHEAD->trcheck  := cChkNo
					   TRANHEAD->usercode := 'SG1'+cUserName
					   TRANHEAD->foraprvl := 'C'
					   TRANHEAD->chckuser := cUserName
					   TRANHEAD->chckdate := date()
					   TRANHEAD->chcktime := time()
					   TRANHEAD->(dbcommit())
					endif
					TRANHEAD->(dbunlock())
					AuditLog('g_GLAS_Path','Edits','DV No. '+cDVNumber,'TRANHEAD','TRCHECK')
					
					DispDVDtls(.f.)
					exit
				 endif
			  endif
	  endcase
   endif
enddo
return

***********************************
static function GetCheckNo(cOption)
***********************************
local nDepoBank

if cOption == 'A'
   if len(alltrim(cChkNo)) <= 2 .and. left(alltrim(cChkNo),2) <> 'MC'
      return .f.
   endif
   
   if cChkNo != cPrevChkNo .and. left(alltrim(cChkNo),2) == 'MC'
	  if !netuse('&g_RFM_Path\ORJVGL',.f.,5)
	     return .f.
	  endif
	  set index to &g_RFM_Path\ORJVGL
	  
	  if !ORJVGL->(dbseek(left((gTmpPayee)->acctno,3)+'3'+substr((gTmpPayee)->acctno,4,2)+'MC'+'1'))
	     @24,0 say ' ERROR: ' color 'r+'
		 @24,8 say padr('No MC GL mapping found. Press Any Key.',72) color 'w'
		 ORJVGL->(dbclosearea())
		 inkey(0)
		 OptionBar('ESC-Exit')
		 return .f.
	  else
		 if (gTmpGL)->(dbseek(ORJVGL->glcode))
		    nDepoBank   := val(strtran(substr(aGLDtls[len(aGLDtls)],63,16),',','')) + val(ORJVGL->formula)
			nGLDtDebit  := nGLDtDebit + val(ORJVGL->formula)
			nGLDtCredit := nGLDtCredit + val(ORJVGL->formula)
			asize(aGLDtls, len(aGLDtls)+1)
			ains(aGLDtls,2)
			afill(aGLDtls, left(trans(ORJVGL->glcode,'@R 9-99-99-9999-99')+' '+(gTmpGL)->glname,44)+'³'+;
			               trans(val(ORJVGL->formula),'@Z 9,999,999,999.99')+'³'+;
						   trans(0.00,'@Z 9,999,999,999.99')+right((gTmpGL)->glname,22)+'1', 2, 1)
			afill(aGLDtls, left(aGLDtls[len(aGLDtls)],62)+trans(nDepoBank,'@Z 9,999,999,999.99')+substr(aGLDtls[len(aGLDtls)],79), len(aGLDtls), 1)
			
			setcolor('w+/rb,,,,w+/rb')
			@22,46 say trans(nGLDtDebit, '@Z 9,999,999,999.99')
			@22,63 say trans(nGLDtCredit, '@Z 9,999,999,999.99')
			achoice(18,1,20,78,aGLDtls,.f.)
		 endif
		 ORJVGL->(dbclosearea())
	  endif
   endif
else
   if (left(alltrim(cCheckNo),2) == 'MC' .and. left(alltrim(cChkNo),2) <> 'MC') .or. (left(alltrim(cCheckNo),2) <> 'MC' .and. left(alltrim(cChkNo),2) == 'MC')
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr('MC editing is not available in GLAS. Press Any Key.',72) color 'w'
	  inkey(0)
	  OptionBar('ESC-Exit')
	  return .f.
   endif
endif
return .t.