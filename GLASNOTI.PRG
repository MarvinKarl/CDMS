/*
PROGRAM     : GLASNOTI.PRG
DESCRIPTION : NOTIFICATION - LIST OF PAYEES READY FOR DISBURSEMENT
AUTHOR      : ERLACHICA
CREATED     : JANUARY 18, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

#include "INKEY.CH"

local cOrigColor:=setcolor(), cScrn:=savescreen(,,,)
private aPayee:={}

if !netuse('&g_SMS_Path\USERBRCH',.f.,5)
   return
endif
set index to &g_SMS_Path\USERBRCH

if !netuse('&g_DAAS_Path\PAYEE',.f.,5)
   close databases
   return
endif
set index to &g_DAAS_Path\PAYEE

if !netuse('&g_DAAS_Path\ACCTMAST',.f.,5)
   close databases
   return
endif
set index to &g_DAAS_Path\ACCTMAST

gTmpPayee := CreateTmp(g_GLAS_Tmp)
dbcreate(g_GLAS_Tmp+'\'+gTmpPayee, { {'APRVDATE','D',8,0}, {'ACCTNO','C',11,0}, {'PAYNAME','C',70,0}, {'AMOUNT','N',12,2}, {'VALDATE','D',8,0},;
                                     {'TYPE','C',1,0}, {'PAYEECODE','C',6,0}, {'WITH_WTAX','L',1,0}, {'VATINCL','L',1,0}, {'DISI','C',1,0},;
									 {'DVNUMBER','C',8,0}, {'ACCTNAME','C',50,0}, {'UNIT','C',40,0}, {'JVNUMBER','C',8,0} } )

if !netuse('&g_GLAS_Tmp\&gTmpPayee',.f.,5)
   close databases
   return
endif
index on dtoc(aprvdate)+acctno+payeecode to (g_GLAS_Tmp+'\'+gTmpPayee)

@24,0  say ' MESSAGE: ' color 'bg+'
@24,10 say padr('Extracting Request for Payment...',70) color 'w'
if USERBRCH->(dbseek(str(nUserId,len(str(USERBRCH->userid)))))
   do while !USERBRCH->(eof()) .and. USERBRCH->userid == nUserId
      if PAYEE->(dbseek(USERBRCH->brcode))
	     do while !PAYEE->(eof()) .and. left(PAYEE->acctno,3) == USERBRCH->brcode
		    if !empty(PAYEE->aprvdate) .and. empty(PAYEE->dvnumber) .and. ACCTMAST->(dbseek(PAYEE->acctno))
			   (gTmpPayee)->(dbappend())
			   (gTmpPayee)->aprvdate  := PAYEE->aprvdate
			   (gTmpPayee)->acctno    := PAYEE->acctno
			   (gTmpPayee)->payname   := PAYEE->payname
			   (gTmpPayee)->amount    := PAYEE->amount
			   (gTmpPayee)->valdate   := ACCTMAST->valdate
			   (gTmpPayee)->type      := PAYEE->type
			   (gTmpPayee)->payeecode := PAYEE->payeecode
			   (gTmpPayee)->with_wtax := PAYEE->with_wtax
			   (gTmpPayee)->vatincl   := PAYEE->vatincl
			   (gTmpPayee)->disi      := PAYEE->disi
			   (gTmpPayee)->acctname  := ACCTMAST->acctname
			   (gTmpPayee)->unit      := ACCTMAST->unit
			   (gTmpPayee)->jvnumber  := ACCTMAST->jvnumber
			endif
			PAYEE->(dbskip())
		 enddo
	  endif
	  USERBRCH->(dbskip())
   enddo
endif
USERBRCH->(dbclosearea())
PAYEE->(dbclosearea())
ACCTMAST->(dbclosearea())

if (gTmpPayee)->(recc()) == 0
   (gTmpPayee)->(dbclosearea())
else
   (gTmpPayee)->(dbgotop())
   do while !(gTmpPayee)->(eof())
      aadd(aPayee, ' '+dtoc((gTmpPayee)->aprvdate)+' ³ '+trans((gTmpPayee)->acctno,'@R 999-99-99999-9')+' ³ '+left((gTmpPayee)->payname,29)+' ³ '+;
	               trans((gTmpPayee)->amount, '@Z 999,999,999.99')+' '+dtoc((gTmpPayee)->valdate)+;
				   iif((gTmpPayee)->type=='1','PROCEEDS ',iif((gTmpPayee)->type=='2','INCENTIVE',space(9))))
	  (gTmpPayee)->(dbskip())
   enddo
   (gTmpPayee)->(dbclosearea())
   
   setcolor('n/w,bg+/b')
   OptionBar('ENTER-Continue')
   @2,1 say 'NOTIFICATION' color 'w+'
   @3,1 say 'REQUEST FOR PAYMENT READY FOR DISBURSEMENT' color 'w+'
   @4,0  say 'ÚÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
   @5,0  say '³  Approved  ³   Account N§   ³             Payee             ³      Amount    ³'
   @6,0  say 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
   @7,0  say '³            ³                ³                               ³                ³'
   @8,0  say '³            ³                ³                               ³                ³'
   @9,0  say '³            ³                ³                               ³                ³'
   @10,0 say '³            ³                ³                               ³                ³'
   @11,0 say '³            ³                ³                               ³                ³'
   @12,0 say '³            ³                ³                               ³                ³'
   @13,0 say '³            ³                ³                               ³                ³'
   @14,0 say '³            ³                ³                               ³                ³'
   @15,0 say '³            ³                ³                               ³                ³'
   @16,0 say '³            ³                ³                               ³                ³'
   @17,0 say '³            ³                ³                               ³                ³'
   @18,0 say '³            ³                ³                               ³                ³'
   @19,0 say '³            ³                ³                               ³                ³'
   @20,0 say 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
   @21,0 say '³  Booking Date:                                                               ³'
   @22,0 say '³Classification:                                                               ³'
   @23,0 say 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
   @20,79-len(' '+alltrim(str(len(aPayee)))+' Record'+iif(len(aPayee)>1,'s','')+' ') say;
       ' '+alltrim(str(len(aPayee)))+' Record'+iif(len(aPayee)>1,'s','')+' ' color 'w/n'
   @21,17 say substr(aPayee[1],79,10) color 'r/w'
   @22,17 say right(aPayee[1],9) color 'r/w'
   
   achoice(7,1,22,78,aPayee,,'PayeeUDF')
   restscreen(,,,,cScrn)
   setcolor(cOrigColor)
endif
return

********************************************
function PayeeUDF(status,curr_elem,curr_row)
********************************************
do case
   case lastkey() == K_UP .or.  lastkey() == K_DOWN
        @21,17 say substr(aPayee[curr_elem],79,10) color 'r/w'
		@22,17 say right(aPayee[curr_elem],9) color 'r/w'
   case lastkey() == K_ENTER
        return 1
endcase
return 2
