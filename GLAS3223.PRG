/* 

	System Name 	:	GLAS

	Program ID		:	GLAS3223.PRG
	Description		:	DISBURSEMENT VOUCHER REPORT
	Author			:	ESVIRTUSIO
	Date Started	:	FEBRUARY 10, 2017
	Date Finished	:	

	UPDATES			:	---

 */ 

#include "INKEY.CH"
#include "SETCURS.CH"

SET SOFTSEEK ON
SET DELETED ON
SET CENTURY ON
SET SCOREBOARD OFF

private cSCREEN, nPAGE := 0, dSTART := date(), dEND := date()

cSCREEN := savescreen(,,,)

if !NETUSE('&g_RFM_PATH\BRANCHES',.F.,5)
   return
endif
ordlistadd( '&g_RFM_PATH\BRANCHES' )

if !NETUSE('&g_RFM_PATH\PERSONEL',.F.,5)
   return
endif
ordlistadd( '&g_RFM_PATH\INITIALS' )

// GLAS

if !NETUSE('&g_GLAS_PATH\GLTRANDT',.F.,5)
   return
endif
ordlistadd( '&g_GLAS_PATH\GLTRANDT' )


if !NETUSE('&g_GLAS_PATH\GLCODE',.F.,5)
   return
endif
ordlistadd( '&g_GLAS_PATH\GLCODE' )

if !NETUSE('&g_GLAS_PATH\GLTRANHD',.F.,5)
   return
endif

ordlistadd( '&g_GLAS_PATH\GLHDBCDN' )

if getdate()
	reportprint('RGLAS3223()')
endif

close database

return

*****************************
*
static function getdate()
*****************************
   local lretval := .f., cscr := savescreen(,,,)

   @ 10,10 clear to 13,32
   @ 10,10 to 13,32
   @ 11,11 say 'From ╞ ' get dSTART picture '@D' valid !empty(dSTART)
   @ 12,11 say ' End ╞ ' get dEND picture '@D' valid !empty(dEND)

   setcursor(3)
   read
   setcursor(0)

   if lastkey() != K_ESC
      lretval := .t.
   endif


   restscreen(,,,,cscr)
   
 return lretval

FUNCTION RGLAS3223()
local nCTR, nTOTAMT := 0, cGLNAME, nORNUM := 0, nDEBIT, nCREDIT, nGDEBIT, nGCREDIT

header()
nGCREDIT := 0
nGDEBIT := 0
//Gltranhd->(dbseek(g_PAR_BRCH+'2')) 
seek g_PAR_BRCH+'2'+dtos(dSTART) softseek
do while !Gltranhd->(eof()) .and. Gltranhd->trancode == '2' .and. Gltranhd->trandate <= dEND
	//if Gltranhd->trandate >= dSTART .and. Gltranhd->trandate <= dEND
	if prow() > 53
		setfont('PICA')
		nROW:=len('Page '+ alltrim(str(nPAGE)))
		@ 60,01 say alltrim(gUSER_ID) + ' '+ dtoc(DATE()) + ' ' + TIME() + ' GLAS3223'
		@ 60,132-nROW say 'Page ' + alltrim(str(nPAGE))
		setfont('UNCONDENSED')
		__eject()
		header()
	endif
	
	@ prow()+1, 04 say Gltranhd->trandate
	@ prow()  , 19 say Gltranhd->post_date
	@ prow()  , 33 say Gltranhd->brcode+Gltranhd->trnumber picture '@R 999-99999999'
	if Gltrandt->(dbseek(Gltranhd->brcode+Gltranhd->trnumber))
	nCTR := 1
	nDEBIT := 0
	nCREDIT := 0
		do while Gltrandt->brcode+Gltrandt->trnumber == Gltranhd->brcode+Gltranhd->trnumber
		
			if Glcode->(dbseek(substr(Gltrandt->glcode,7,3)+Gltrandt->glcode))
				cGLNAME := padr(Glcode->glname,50)
			endif
			
			if nCTR > 1
				if Gltrandt->drcr == '1'
					@ prow()+1, 47 say transform(Gltrandt->glcode,'@R 9-99-99-9999-99') + ' ' + cGLNAME
					@ prow()  ,119 say Gltrandt->amount picture '999,999,999.99'
					nDEBIT += Gltrandt->amount
					nGDEBIT += Gltrandt->amount
				else
					@ prow()+1, 51 say transform(Gltrandt->glcode,'@R 9-99-99-9999-99') + ' ' + cGLNAME
					@ prow()  ,135 say Gltrandt->amount picture '999,999,999.99'
					nCREDIT += Gltrandt->amount
					nGCREDIT += Gltrandt->amount
				endif
				
				if nCTR == 2
					if !empty(Gltranhd->partix2)
						@ prow() ,151 say Gltranhd->partix2
					endif
				endif
				if nCTR == 3
					if !empty(Gltranhd->partix3)
						@ prow() ,151 say Gltranhd->partix3
					endif
				endif
				if nCTR == 4
					if !empty(Gltranhd->partix3)
						@ prow() ,151 say Gltranhd->partix4
					endif
				endif
				if nCTR == 5
					if !empty(Gltranhd->partix3)
						@ prow() ,151 say Gltranhd->partix5
					endif
				endif
				if nCTR == 6
					if !empty(Gltranhd->partix3)
						@ prow() ,151 say Gltranhd->partix6
					endif
				endif

			else
				if Gltrandt->drcr == '1'
					@ prow()  , 47 say transform(Gltrandt->glcode,'@R 9-99-99-9999-99') + ' ' + cGLNAME
					@ prow()  ,119 say Gltrandt->amount picture '999,999,999.99'

					@ prow()  ,151 say Gltranhd->partix1
					@ prow()  ,223 say Gltranhd->usercode
					nDEBIT += Gltrandt->amount
					nGDEBIT += Gltrandt->amount
				else
					@ prow()  , 51 say transform(Gltrandt->glcode,'@R 9-99-99-9999-99') + ' ' + cGLNAME
					@ prow()  ,135 say Gltrandt->amount picture '999,999,999.99'

					@ prow()  ,151 say Gltranhd->partix1
					@ prow()  ,223 say Gltranhd->usercode
					nCREDIT += Gltrandt->amount
					nGCREDIT += Gltrandt->amount
				endif
			endif
			
			nCTR++
		
			Gltrandt->(dbskip())
		enddo
	endif
	
	if nCTR == 3
		if !empty(Gltranhd->partix3)
			@ prow()+1,151 say Gltranhd->partix3
		endif
	endif
	
	if nCTR == 4
		if !empty(Gltranhd->partix4)
			@ prow()+1,151 say Gltranhd->partix4
		endif
	endif
	
	if nCTR == 5
		if !empty(Gltranhd->partix5)
			@ prow()+1,151 say Gltranhd->partix5
		endif
	endif
	
	if nCTR == 6
		if !empty(Gltranhd->partix6)
			@ prow()+1,151 say Gltranhd->partix6
		endif
	endif
	
	
	@ prow()+1, 119 say 'дддддддддддддд дддддддддддддд'
	@ prow()+1, 119 say nDEBIT picture '999,999,999.99'
	@ prow()  ,135 say nCREDIT picture '999,999,999.99'

	nORNUM++
	//endif
Gltranhd->(dbskip())
enddo

@ prow()+1, 119 say 'дддддддддддддд дддддддддддддд'
@ prow()+1, 18 say 'Number of DVs ╞ ' + transform(nORNUM,'9999')
@ prow()  , 56 say 'GRAND TOTAL ╞ '
@ prow()  , 119 say nGDEBIT picture '999,999,999.99'
@ prow()  ,135 say nGCREDIT picture '999,999,999.99'
@ prow()+1, 119 say 'мммммммммммммм мммммммммммммм'
setfont('PICA')
@ prow() + 2,2 say padc('-  -  -  E  N  D    O  F    R  E  P  O  R  T  -  -  -',132)
nROW:=len('Page '+ alltrim(str(nPAGE)))
@ 60,01 say alltrim(gUSER_ID) + ' '+ dtoc(DATE()) + ' ' + TIME() + ' GLAS3223'
@ 60,132-nROW say 'Page ' + alltrim(str(nPAGE))
__eject()
setprc(0,0)
return nil

static function header()

setprc(0,0)
nPAGE++
setfont('PICA')
setfont('BOLD')
pagecenter( prow()+1,132, 'LEAGUE ONE FINANCE AND LEASING CORPORATION')
setfont('UNBOLD')
pagecenter( prow()+1,132, gSYS_NAME + ' ('+ cSYSCODE +')')
setfont('BOLD')
pagecenter( prow()+2,132, 'DISBURSEMENT VOUCHER REPORT')
pagecenter( prow()+1,132, 'For the Period of '+cmonth(dSTART)+' '+padl(day(dSTART),2,'0')+', '+padl(year(dSTART),4)+' - '+;
               cmonth(dEND)+' '+padl(day(dEND),2,'0')+', '+padl(year(dEND),4))
setfont('UNBOLD')

setfont('PICA')
setfont('CONDENSED')
	//          *       0         1			2		  3			4		  5			6		  7         8         9         0         1			2		  3			4		  5			6		  7         8         9		    0         1			2		  3			4		  5			6		  7         8         9 			
    //          *  123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-
@ prow()+2,01 say 'дддддддддддддддд  дддддддддддд  дддддддддддд  дддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд  дддддддддддддд  дддддддддддддд  дддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд  дддддд'
@ prow()+1,01 say 'Transaction Date  Date Encoded      TRN                               GL ACCOUNT                                           Debit          Credit                                   Particulars                                 User ' 
@ prow()+1,01 say 'дддддддддддддддд  дддддддддддд  дддддддддддд  дддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд  дддддддддддддд  дддддддддддддд  дддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд  дддддд'
//                    99/99/9999     999-99999999                9-99-99-9999-99 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX      999,999,999.99  999,999,999.99  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  XXXXXX
//                                                                   9-99-99-9999-99 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
//                    4              19            33            47  51                                                                  119             135             151                                                                     223        

return
