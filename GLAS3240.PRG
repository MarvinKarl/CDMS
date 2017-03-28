/* 

	System Name 	:	GLAS

	Program ID		:	GLAS3240.PRG
	Description		:	CASH RECEIPTS REPORT
	Author			:	ESVIRTUSIO
	Date Started	:	JANUARY 16, 2017
	Date Finished	:	

	UPDATES			:	---

 */ 

#include "INKEY.CH"
#include "SETCURS.CH"


SET DELETED ON
SET CENTURY ON
SET SCOREBOARD OFF

private cSCREEN, cUSERID := space(6), iPASSWORD:=space(30), nPAGE := 0, nORFC, dSTART := date(), dEND := date()
private aSTATUS_  := {'1-ACTIVE          ',;
				      '2-FOR CANCELLATION',;
				      '3-CANCELLED       ' }

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

if !NETUSE('&g_GLAS_PATH\GLTRANHD',.F.,5)
   return
endif

ordlistadd( '&g_GLAS_PATH\GLHDBCDN' )

if !NETUSE('&g_GLAS_PATH\GLTRANDT',.F.,5)
   return
endif
ordlistadd( '&g_GLAS_PATH\GLTRANDT' )


if !NETUSE('&g_GLAS_PATH\GLCODE',.F.,5)
   return
endif
ordlistadd( '&g_GLAS_PATH\GLCODE' )


if getdate()
	reportprint('RGLAS3240()')
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

FUNCTION FRDISP( mAR_, mAX, mcut, mfixed )
//---------------------------------------------------------------------------
local mBX, mCX

if !empty( mAX )
   if ( mBX := ascan( mAR_, { | v | substr( v, 1, mcut ) == mAX } ) ) > 0
        mCX := upper( substr( mAR_[ mBX ], mfixed, 16 ) )
   else   
        mCX := space( 16 )
   endif     
else
   mCX := space( 16 )        
endif   
return( mCX )

FUNCTION RGLAS3240()
local nCTR, nTOTAMT := 0, cGLNAME, nORNUM := 0, nDEBIT, nCREDIT, nGDEBIT, nGCREDIT

header()
nORFC := 0
nGCREDIT := 0
nGDEBIT := 0
Gltranhd->(dbseek(g_PAR_BRCH+'3'))
do while !Gltranhd->(eof()) .and. Gltranhd->trancode == '3'
	if Gltranhd->trandate >= dSTART .and. Gltranhd->trandate <= dEND
	if prow() > 53
		setfont('PICA')
		nROW:=len('Page '+ alltrim(str(nPAGE)))
		@ 60,01 say alltrim(gUSER_ID) + ' '+ dtoc(DATE()) + ' ' + TIME() + ' GLAS3240'
		@ 60,132-nROW say 'Page ' + alltrim(str(nPAGE))
		setfont('UNCONDENSED')
		__eject()
		header()
	endif
	
	@ prow()+1, 04 say Gltranhd->trandate
	@ prow()  , 18 say Gltranhd->brcode+Gltranhd->trnumber picture '@R 999-99999999'
	if Gltrandt->(dbseek(Gltranhd->brcode+Gltranhd->trnumber))
	nCTR := 1
	nDEBIT := 0
	nCREDIT := 0
		do while Gltrandt->brcode+Gltrandt->trnumber == Gltranhd->brcode+Gltranhd->trnumber
		
			if Glcode->(dbseek(substr(Gltrandt->glcode,7,3)+Gltrandt->glcode))
				cGLNAME := padr(Glcode->glname,40)
			endif
			
			if nCTR > 1
				if Gltrandt->drcr == '1'
					@ prow()+1, 31 say transform(Gltrandt->glcode,'@R 9-99-99-9999-99') + ' ' + cGLNAME
					@ prow()  , 92 say Gltrandt->amount picture '999,999,999.99'
					nDEBIT += Gltrandt->amount
					nGDEBIT += Gltrandt->amount
				else
					@ prow()+1, 35 say transform(Gltrandt->glcode,'@R 9-99-99-9999-99') + ' ' + cGLNAME
					@ prow()  ,107 say Gltrandt->amount picture '999,999,999.99'
					if nCTR == 2
						if !empty(Gltranhd->partix2)
							@ prow()  ,194 say Gltranhd->partix2
						endif
					endif
					if nCTR == 3
						if !empty(Gltranhd->partix3)
							@ prow()  ,194 say Gltranhd->partix3
						endif
					endif
					nCREDIT += Gltrandt->amount
					nGCREDIT += Gltrandt->amount
				endif

			else
				if Gltrandt->drcr == '1'
					@ prow()  , 31 say transform(Gltrandt->glcode,'@R 9-99-99-9999-99') + ' ' + cGLNAME
					@ prow()  , 92 say Gltrandt->amount picture '999,999,999.99'
					@ prow()  ,122 say padr(Gltranhd->trpayee,39)
					if Gltranhd->aprvcancel
						@ prow()  ,162 say '**CANCELLED**' + alltrim(Gltranhd->aprvuser) + ' ' + Gltranhd->aprvtime
					else
						@ prow()  ,162 say Gltranhd->bankname
						@ prow()  ,178 say Gltranhd->trcheck	
					endif

					@ prow()  ,194 say Gltranhd->partix1
					@ prow()  ,265 say Gltranhd->usercode
					nDEBIT += Gltrandt->amount
					nGDEBIT += Gltrandt->amount
				else
					@ prow()  , 35 say transform(Gltrandt->glcode,'@R 9-99-99-9999-99') + ' ' + cGLNAME
					@ prow()  ,107 say Gltrandt->amount picture '999,999,999.99'
					@ prow()  ,122 say padr(Gltranhd->trpayee,39)
					if Gltranhd->aprvcancel
						@ prow()  ,162 say '**CANCELLED**' + alltrim(Gltranhd->aprvuser) + ' ' + Gltranhd->aprvtime
					else
						@ prow()  ,162 say Gltranhd->bankname
						@ prow()  ,178 say Gltranhd->trcheck	
					endif
					@ prow()  ,194 say Gltranhd->partix1
					@ prow()  ,265 say Gltranhd->usercode
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
			@ prow()+1,194 say Gltranhd->partix3
		endif
	endif
	
	@ prow()+1, 92 say 'дддддддддддддд дддддддддддддд'
	@ prow()+1, 92 say nDEBIT picture '999,999,999.99'
	@ prow()  ,107 say nCREDIT picture '999,999,999.99'

	nORNUM++
	endif
Gltranhd->(dbskip())
enddo

@ prow()+1, 92 say 'дддддддддддддд дддддддддддддд'
@ prow()+1, 18 say 'Number of ORs ╞ ' + transform(nORNUM,'9999')
@ prow()  , 56 say 'GRAND TOTAL ╞ '
@ prow()  , 92 say nGDEBIT picture '999,999,999.99'
@ prow()  ,107 say nGCREDIT picture '999,999,999.99'
@ prow()+1, 92 say 'мммммммммммммм мммммммммммммм'
setfont('PICA')
@ prow() + 2,2 say padc('-  -  -  E  N  D    O  F    R  E  P  O  R  T  -  -  -',132)
nROW:=len('Page '+ alltrim(str(nPAGE)))
@ 60,01 say alltrim(gUSER_ID) + ' '+ dtoc(DATE()) + ' ' + TIME() + ' GLAS3240'
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
pagecenter( prow()+2,132, 'CASH RECEIPTS REPORT')
pagecenter( prow()+1,132, 'For the Period of '+cmonth(dSTART)+' '+padl(day(dSTART),2,'0')+', '+padl(year(dSTART),4)+' - '+;
               cmonth(dEND)+' '+padl(day(dEND),2,'0')+', '+padl(year(dEND),4))
setfont('UNBOLD')

setfont('ELITE')
setfont('CONDENSED')
	//          *       0         1			2		  3			4		  5			6		  7         8         9         0         1			2		  3			4		  5			6		  7         8         9		    0         1			2		  3			4		  5			6		  7         8         9 			
    //          *  123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-
@ prow()+2,01 say 'дддддддддддддддд дддддддддддд дддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд дддддддддддддд дддддддддддддд ддддддддддддддддддддддддддддддддддддддд ддддддддддддддд ддддддддддддддд дддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд дддддд'
@ prow()+1,01 say 'Transaction Date     TRN                              GL ACCOUNT                                 Debit        Credit                      Payor                        Bank        Check Number                               Particulars                                User ' 
@ prow()+1,01 say 'дддддддддддддддд дддддддддддд дддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд дддддддддддддд дддддддддддддд ддддддддддддддддддддддддддддддддддддддд ддддддддддддддд ддддддддддддддд дддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд дддддд'
//                    99/99/9999    999-99999999 9-99-99-9999-99 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     999,999,999.99 999,999,999.99 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXX XXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX XXXXXX
//                                                   9-99-99-9999-99 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
//                    4             18           31  35                                                       92             107            122                                     162             178             194                                                                    265        

return
