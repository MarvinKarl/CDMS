/*
PROGRAM     : GLAS3112.PRG
DESCRIPTION : UNPOSTED PER JOURNAL VOUCHER
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 07, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

#include "INKEY.CH"

private aBrAcs:={}, cVCateg:='JV', cHdDbf:='TRANHEAD', cDtDbf:='TRANDTLS', lPosted:=.f.

if !OpenBrRprt()
   return
endif

VchrNo('1',15)
return

*******************************
function VchrNo(cTranCode,nRow)
*******************************
private cVBrCode1:=space(3), cVNumber1:=space(8), cVBrCode2:=space(3), cVNumber2:=space(8), cTmpHd, cTmpDt,;
        cPreprdBy, cCheckdBy, cAprvdBy, cForAprvl

@nRow-1,18,nRow+1,61 box 'ÚÄ¿³ÙÄÀ³ ' color 'w+/n'
@nRow,20 say cVCateg+' N§ Range' color 'w+/n'
OptionBar('ESC-Exit')
if len(aBrAcs) == 1
   cVBrCode1 := cVBrCode2 := right(aBrAcs[1],3)
   @nRow,32 say cVBrCode1+'-' color 'n/w'
   @nRow,36 get cVNumber1 picture '99999999' valid !empty(cVNumber1) color 'n/w'
   @nRow,45 say 'to'
   @nRow,48 say cVBrCode2+'-' color 'n/w'
   @nRow,52 get cVNumber2 picture '99999999' valid !empty(cVNumber2) .and. cVNumber2>=cVNumber1 color 'n/w'
else
   @nRow,32 get cVBrCode1 picture '999' valid !empty(cVBrCode1) .and. GetVBrCode(cVBrCode1) color 'n/w'
   @nRow,35 say '-' color 'n/w'
   @nRow,36 get cVNumber1 picture '99999999' valid !empty(cVNumber1) color 'n/w'
   @nRow,45 say 'to'
   @nRow,48 get cVBrCode2 picture '999' valid !empty(cVBrCode2) .and. GetVBrCode(cVBrCode2) color 'n/w'
   @nRow,51 say '-' color 'n/w'
   @nRow,52 get cVNumber2 picture '99999999' valid !empty(cVNumber2) .and. cVNumber2>=cVNumber1 color 'n/w'
endif
setcursor(1)
read
setcursor(0)

if lastkey() != K_ESC
   if !netuse('&g_GLAS_Path\&cHdDbf',.f.,5)
      return
   endif
   set index to &g_GLAS_Path\&cHdDbf
   
   if !(cHdDbf)->(dbseek(cVBrCode1+cVNumber1)) .and. ((cHdDbf)->(eof()) .or. (cHdDbf)->trancode <> cTranCode)
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr('No '+cVCateg+iif(cVNumber1<>cVNumber2,'s','')+' found. Press Any Key.',72) color 'w'
	  close databases
	  inkey(0)
   else
	  cTmpHd := CreateTmp(g_GLAS_Tmp)
	  do case
	     case cVCateg == 'JV'
		      dbcreate(g_GLAS_Tmp+'\'+cTmpHd, { {'BRCODE','C',3,0}, {'TRNUMBER','C',8,0}, {'TRANDATE','D',8,0}, {'PARTIX1','C',70,0}, {'PARTIX2','C',70,0},;
			                                    {'PARTIX3','C',70,0}, {'PARTIX4','C',70,0}, {'PARTIX5','C',70,0}, {'PARTIX6','C',70,0}, {'USERCODE','C',6,0},;
												{'PREPAREDBY','C',32,0}, {'POST_DATE','D',8,0}, {'CHECKEDBY','C',32,0}, {'CHCKDATE','D',8,0},;
												{'FORAPRVL','C',10,0} } )
		 case cVCateg == 'DV'
		      dbcreate(g_GLAS_Tmp+'\'+cTmpHd, { {'BRCODE','C',3,0}, {'TRNUMBER','C',8,0}, {'TRANDATE','D',8,0}, {'TRPAYEE','C',60,0}, {'TRAMOUNT','N',14,2},;
			                                    {'PARTIX1','C',70,0}, {'PARTIX2','C',70,0}, {'PARTIX3','C',70,0}, {'PARTIX4','C',70,0}, {'PARTIX5','C',70,0},;
												{'PARTIX6','C',70,0}, {'BANKNAME','C',40,0}, {'BANKGLCODE','C',11,0}, {'TRCHECK','C',15,0}, {'USERCODE','C',6,0},;
												{'PREPAREDBY','C',32,0}, {'POST_DATE','D',8,0}, {'CHECKEDBY','C',32,0}, {'CHCKDATE','D',8,0},;
												{'FORAPRVL','C',10,0} } )
			  
			  if !netuse('&g_RFM_Path\BANKACCT',.f.,5)
			     close databases
				 return
			  endif
			  set index to &g_RFM_Path\BANKACCT
	  endcase
	  
	  cTmpDt := CreateTmp(g_GLAS_Tmp)
	  dbcreate(g_GLAS_Tmp+'\'+cTmpDt, { {'BRCODE','C',3,0}, {'TRNUMBER','C',8,0}, {'DRCR','C',1,0}, {'GLCODE','C',11,0}, {'GLNAME','C',50,0},;
	                                    {'AMOUNT','N',14,2} } )
	  
	  if !netuse('&g_GLAS_Tmp\&cTmpHd',.f.,5)
	     close databases
		 return
	  endif
	  
	  if !netuse('&g_GLAS_Tmp\&cTmpDt',.f.,5)
	     close databases
		 return
	  endif
	  index on brcode+trnumber+drcr to (g_GLAS_Tmp+'\'+cTmpDt)
	  
	  if !netuse('&g_GLAS_Path\&cDtDbf',.f.,5)
	     close databases
		 return
	  endif
	  set index to &g_GLAS_Path\&cDtDbf
	  
	  if !OpenTmpGL()
	     close databases
		 return
	  endif
	  
	  if !netuse('&g_SMS_Path\USERMAST',.f.,5)
	     close databases
		 return
	  endif
	  set index to &g_SMS_Path\USERNAME
	  
	  do while !(cHdDbf)->(eof()) .and. (cHdDbf)->brcode+(cHdDbf)->trnumber >= cVBrCode1+cVNumber1 .and.;
	     (cHdDbf)->brcode+(cHdDbf)->trnumber <= cVBrCode2+cVNumber2 .and. (cHdDbf)->trancode == cTranCode
		 if (cHdDbf)->trantype == '1' .and. (cDtDbf)->(dbseek((cHdDbf)->brcode+(cHdDbf)->trnumber))
			cPreprdBy := iif(USERMAST->(dbseek(iif(left((cHdDbf)->usercode,3)=='SG1' .or. left((cHdDbf)->usercode,3)=='SYS',substr((cHdDbf)->usercode,4),(cHdDbf)->usercode))),;
			             left(USERMAST->firstname,1)+left(USERMAST->middlename,1)+alltrim(USERMAST->lastname),'')
			//cCheckdBy := iif(!empty((cHdDbf)->chckuser) .and. USERMAST->(dbseek((cHdDbf)->chckuser)),;
			             //left(USERMAST->firstname,1)+left(USERMAST->middlename,1)+alltrim(USERMAST->lastname),'')
			//cForAprvl := iif((cHdDbf)->foraprvl=='E','ENCODED',iif((cHdDbf)->foraprvl=='F','FOR CHCKNG',;
			             //iif((cHdDbf)->foraprvl=='C','CHECKED',iif((cHdDbf)->foraprvl=='R','RETURNED',''))))
			cCheckdBy := 'MEMARIANO'  // temporary values
			cAprvdBy  := 'AVPADUA'
			cForAprvl := ''
			
			(cTmpHd)->(dbappend())
			(cTmpHd)->brcode     := (cHdDbf)->brcode
			(cTmpHd)->trnumber   := (cHdDbf)->trnumber
			(cTmpHd)->trandate   := (cHdDbf)->trandate
			(cTmpHd)->partix1    := (cHdDbf)->partix1
			(cTmpHd)->partix2    := (cHdDbf)->partix2
			(cTmpHd)->partix3    := (cHdDbf)->partix3
			(cTmpHd)->partix4    := (cHdDbf)->partix4
			(cTmpHd)->partix5    := (cHdDbf)->partix5
			(cTmpHd)->partix6    := (cHdDbf)->partix6
			(cTmpHd)->usercode   := (cHdDbf)->usercode
			(cTmpHd)->preparedby := cPreprdBy
			(cTmpHd)->post_date  := (cHdDbf)->post_date
			(cTmpHd)->checkedby  := cCheckdBy
			(cTmpHd)->chckdate   := (cHdDbf)->chckdate
			(cTmpHd)->foraprvl   := cForAprvl
			if cVCateg == 'DV'
			   BANKACCT->(dbseek((cHdDbf)->brtrbank+(cHdDbf)->trbank))
			   (cTmpHd)->trpayee    := (cHdDbf)->trpayee
			   (cTmpHd)->tramount   := (cHdDbf)->tramount
			   (cTmpHd)->bankname   := BANKACCT->bankname
			   (cTmpHd)->bankglcode := BANKACCT->glcode
			   (cTmpHd)->trcheck    := (cHdDbf)->trcheck
			endif
			
			do while !(cDtDbf)->(eof()) .and. (cDtDbf)->brcode+(cDtDbf)->trnumber == (cHdDbf)->brcode+(cHdDbf)->trnumber
			   if (gTmpGL)->(dbseek((cDtDbf)->glcode))
			      (cTmpDt)->(dbappend())
				  (cTmpDt)->brcode   := (cDtDbf)->brcode
				  (cTmpDt)->trnumber := (cDtDbf)->trnumber
				  (cTmpDt)->drcr     := (cDtDbf)->drcr
				  (cTmpDt)->glcode   := (cDtDbf)->glcode
				  (cTmpDt)->glname   := (gTmpGL)->glname
				  (cTmpDt)->amount   := (cDtDbf)->amount
			   endif
			   (cDtDbf)->(dbskip())
			enddo
		 endif
		 (cHdDbf)->(dbskip())
	  enddo
	  
	  if (cTmpHd)->(recc()) == 0
	     @24,0 say ' ERROR: ' color 'r+'
		 @24,8 say padr('No valid '+cVCateg+iif(cVNumber1<>cVNumber2,'s','')+' found. Press Any Key.',72) color 'w'
		 close databases
		 ferase('&g_GLAS_Tmp\&cTmpHd'+'.DBF')
		 ferase('&g_GLAS_Tmp\&cTmpDt'+'.DBF')
		 ferase('&g_GLAS_Tmp\&cTmpDt'+'.NTX')
		 inkey(0)
	  else
		 (cHdDbf)->(dbclosearea())
		 (cDtDbf)->(dbclosearea())
		 (gTmpGL)->(dbclosearea())
		 USERMAST->(dbclosearea())
		 if cVCateg == 'DV'
		    BANKACCT->(dbclosearea())
		 endif
		 
		 dbselectarea(cTmpHd)
		 (cTmpHd)->(dbgotop())
		 OptionBar('ESC-Exit')
		 do case
		    case cVCateg == 'JV'
			     ReportPrint('PerJV()')
			case cVCateg == 'DV'
			     ReportPrint('PerDV()')
		 endcase
		 close databases
		 ferase('&g_GLAS_Tmp\&cTmpHd'+'.DBF')
		 ferase('&g_GLAS_Tmp\&cTmpDt'+'.DBF')
		 ferase('&g_GLAS_Tmp\&cTmpDt'+'.NTX')
	  endif
   endif
endif
return

********************************
static function GetVBrCode(cVBr)
********************************
if ascan(aBrAcs,{|x| right(x,3)==cVBr}) == 0
   @24,0 say ' ERROR: ' color 'r+'
   @24,8 say padr(cVBr+' is invalid.',72) color 'w'
   return .f.
else
   OptionBar('ESC-Exit')
endif
return .t.

****************
function PerJV()
****************
do while !(cTmpHd)->(eof())
   if (cTmpDt)->(dbseek((cTmpHd)->brcode+(cTmpHd)->trnumber))
      setprc(0,0)
	  PerVHdr()
	  PerVDtls(8)
   endif
   (cTmpHd)->(dbskip())
enddo
return

******************
function PerVHdr()
******************
@0,2  say chr(18)+chr(27)+chr(77)     // chr(18)-cancel 17cpi; chr(80)-10cpi; chr(77)-12cpi; chr(15)-17cpi
@1,2  say padc(chr(27)+chr(69)+gCOMPANY,96)     // bold on
@2,2  say padc(gSYS_NAME+' ('+cSysCode+')',96)

@4,2  say padc(iif(!lPosted,'*** ','')+iif(cVCateg=='JV','JOURNAL ',iif(cVCateg=='DV','DISBURSEMENT ',''))+'VOUCHER'+iif(!lPosted,' ***','')+chr(27)+chr(70),96)     // bold off

@6,2  say cVCateg+' N§: '+(cTmpHd)->brcode+'-'+(cTmpHd)->trnumber
@6,79 say cVCateg+' Date: '+dtoc((cTmpHd)->trandate)
// REMOVED BY ESV 10.25.2016 AS PER KIRKS
// if !lPosted
   // @7,76 say cVCateg+' Status : '+(cTmpHd)->foraprvl
// endif
return

***********************
function PerVDtls(nRow)
***********************
local cParticlr, cLastGL:='', nTDtDebit:=0, nTDtCredit:=0
private nPage:=1

@nRow,2   say replicate('Ä',96)
@nRow+1,2 say padc('P A R T I C U L A R S',96)
@nRow+2,2 say replicate('Ä',96)
for nCnt1 := 1 to 6
    cParticlr := 'partix'+alltrim(str(nCnt1))
	if !empty((cTmpHd)->&cParticlr)
	   @prow()+1,7 say (cTmpHd)->&cParticlr
	else
	   exit
	endif
next nCnt1
@prow()+1,2 say replicate('Ä',96)
@prow()+1,4 say chr(27)+chr(80)+chr(15)+padr(space(17)+'GL ACCOUNT',85)+;
                chr(18)+chr(27)+chr(77)+'        DEBIT           CREDIT'
@prow()+1,2 say replicate('Ä',96)

do while !(cTmpDt)->(eof()) .and. (cTmpDt)->brcode+(cTmpDt)->trnumber == (cTmpHd)->brcode+(cTmpHd)->trnumber
	  do case
	     case (cTmpDt)->drcr == '1'
		      @prow()+1,4 say chr(27)+chr(80)+chr(15)+trans((cTmpDt)->glcode,'@R 9-99-99-9999-99')+'  '+(cTmpDt)->glname+space(18)+;
			                  chr(18)+chr(27)+chr(77)+trans((cTmpDt)->amount,'@Z 9,999,999,999.99')
			  nTDtDebit := nTDtDebit + (cTmpDt)->amount
		 case (cTmpDt)->drcr == '2'
		      if cVCateg == 'DV' .and. (cTmpHd)->bankglcode == (cTmpDt)->glcode
				 nTDtCredit := nTDtCredit + (cTmpDt)->amount	// ADDED BY ESV 10.25.2016 (Unbalanced Total Credit)
			     cLastGL := chr(27)+chr(80)+chr(15)+space(17)+trans((cTmpDt)->glcode,'@R 9-99-99-9999-99')+'  '+(cTmpDt)->glname+' '+;
				            chr(18)+chr(27)+chr(77)+space(16)+' '+trans((cTmpDt)->amount,'@Z 9,999,999,999.99')
			  else
				 @prow()+1,4 say chr(27)+chr(80)+chr(15)+space(17)+trans((cTmpDt)->glcode,'@R 9-99-99-9999-99')+'  '+(cTmpDt)->glname+' '+;
				                 chr(18)+chr(27)+chr(77)+space(16)+' '+trans((cTmpDt)->amount,'@Z 9,999,999,999.99')
				 nTDtCredit := nTDtCredit + (cTmpDt)->amount
			  endif
	  endcase
   
   if prow() >= 55
      PerVNxtPg()
   endif
   (cTmpDt)->(dbskip())
enddo

if !empty(cLastGL)
   @prow()+1,4 say cLastGL
endif

@prow()+1,2 say replicate('Ä',96)
@prow()+1,4 say chr(27)+chr(80)+chr(15)+padl('T O T A L S     ',85)+;
                chr(18)+chr(27)+chr(77)+trans(nTDtDebit,'@Z 9,999,999,999.99')+' '+trans(nTDtCredit,'@Z 9,999,999,999.99')
@prow()+1,2 say replicate('Ä',96)
if prow() <= iif(lPosted .and. cVCateg=='DV',51,56)
   // MODIFIED BY ESV 10.25.2016 AS PER KIRKS (POSTED/UNPOSTED MUST HAVE CHECK RECEIVED FOOTER-BEFORE,ONLYPOSTED)
   if cVCateg == 'DV'
	  @51,2 say replicate('Ä',96)
	  @52,2 say padc('C H E C K    R E C E I V E D',96)
	  @54,2 say '    Bank: '+(cTmpHd)->bankname+'      _____________________________ __________'
	  @55,2 say 'Check N§: '+(cTmpHd)->trcheck+'                                SIGNATURE OVER PRINTED NAME     DATE'
   endif
   if prow() <> 56
      @56,2 say replicate('Ä',96)
   endif
   @57,2 say 'Prepared by:                    Checked by:                      Approved by:'
   @59,2 say padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->preparedby,17))+' - '+dtoc((cTmpHd)->post_date)+chr(27)+chr(45)+chr(48),36,'_')+'  '+;
	 		 padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->checkedby,18))+chr(27)+chr(45)+chr(48),37,'_')+'  '+;
	 		 padc(chr(27)+chr(45)+chr(49)+alltrim(left(cAprvdBy,18))+chr(27)+chr(45)+chr(48),37,'_')
   @60,2 say chr(27)+chr(15)+cUserName+' '+dtoc(date())+' '+TimeAsAMPM(left(time(),5))+' '+procname(7)+iif(left((cTmpHd)->usercode,3)=='SG1' .or. left((cTmpHd)->usercode,3)=='SYS',' SYSGEN','')     // condensed on
 
   // OLD FOOTER BY ERL
   // if !lPosted
	  // @56,2 say replicate('Ä',96)
	  **//@57,2 say 'Prepared by :                   '+space(33)+'JV Status : '+(cTmpHd)->foraprvl
	  // @57,2 say 'Prepared by :                   Checked by :                     Approved by :'
	  **//@59,2 say padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->preparedby,17))+' - '+dtoc((cTmpHd)->post_date)+chr(27)+chr(45)+chr(48),36,'_')     // underline on/off
	  // /*@57,2 say 'Prepared by :                   '+iif(left((cTmpHd)->foraprvl,1)=='C','Checked by :                     ',space(33))+'JV Status : '+(cTmpHd)->foraprvl
	  // @59,2 say padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->preparedby,17))+' - '+dtoc((cTmpHd)->post_date)+chr(27)+chr(45)+chr(48),36,'_')+'  '+;
	            // iif(left((cTmpHd)->foraprvl,1)=='C',padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->checkedby,18))+' - '+dtoc((cTmpHd)->chckdate)+chr(27)+chr(45)+chr(48),37,'_'),'')     // underline on/off*/
	  // @59,2 say padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->preparedby,17))+' - '+dtoc((cTmpHd)->post_date)+chr(27)+chr(45)+chr(48),36,'_')+'  '+;
	            // padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->checkedby,18))+chr(27)+chr(45)+chr(48),37,'_')+'  '+;
				// padc(chr(27)+chr(45)+chr(49)+alltrim(left(cAprvdBy,18))+chr(27)+chr(45)+chr(48),37,'_')
	  // @60,2 say chr(27)+chr(15)+cUserName+' '+dtoc(date())+' '+TimeAsAMPM(left(time(),5))+' '+procname(7)     // condensed on
   // else
	  // if cVCateg == 'DV'
	     // @51,2 say replicate('Ä',96)
		 // @52,2 say padc('C H E C K    R E C E I V E D',96)
		 // @54,2 say '    Bank : '+(cTmpHd)->bankname+'     _____________________________ __________'
		 // @55,2 say 'Check N§ : '+(cTmpHd)->trcheck+'                               SIGNATURE OVER PRINTED NAME     DATE'
	  // endif
	  // @56,2 say replicate('Ä',96)
	  // @57,2 say 'Prepared by :                   Checked by :                     Approved by :'
	  // @59,2 say padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->preparedby,17))+' - '+dtoc((cTmpHd)->post_date)+chr(27)+chr(45)+chr(48),36,'_')+'  '+;
	            // replicate('_',31)+'  '+replicate('_',31)
	  // /*@59,2 say padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->preparedby,17))+' - '+dtoc((cTmpHd)->post_date)+chr(27)+chr(45)+chr(48),36,'_')+'  '+;
	              // padc(chr(27)+chr(45)+chr(49)+alltrim(left((cTmpHd)->checkedby,18))+' - '+dtoc((cTmpHd)->chckdate)+chr(27)+chr(45)+chr(48),37,'_')+'  '+;
				  // padc(chr(27)+chr(45)+chr(49)+alltrim(left(cAprvdBy,18))+' - '+dtoc((cTmpHd)->aprvdate)+chr(27)+chr(45)+chr(48),37,'_')*/
	  // @60,2 say chr(27)+chr(15)+cUserName+' '+dtoc((cTmpHd)->aprvdate)+' '+TimeAsAMPM(left((cTmpHd)->aprvtime,5))+' '+procname(7)     // condensed on
   // endif
   //@60,2 say chr(27)+chr(15)+cUserName+' '+dtoc(date())+' '+TimeAsAMPM(left(time(),5))+' '+procname(7)     // condensed on
   @60,159-len(alltrim(str(nPage))) say 'Page '+alltrim(str(nPage))+chr(18)     // condensed off
endif
eject
return

***************************
static function PerVNxtPg()
***************************
@prow()+2,2 say padc(' Next  Page ',96,'Ä')
@prow()+1,2 say chr(27)+chr(15)+cUserName+' '+dtoc(date())+' '+TimeAsAMPM(left(time(),5))+' '+procname(8)     // condensed on
@prow(),159-len(alltrim(str(nPage))) say 'Page '+alltrim(str(nPage))+chr(18)     // condensed off
nPage := nPage + 1

eject
PerVHdr()
@8,2  say replicate('Ä',96)
@9,4  say chr(27)+chr(80)+chr(15)+padr(space(17)+'GL ACCOUNT',85)+;
          chr(18)+chr(27)+chr(77)+'        DEBIT           CREDIT'
@10,2 say replicate('Ä',96)
return