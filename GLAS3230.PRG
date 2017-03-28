/* 

	System Name 	:	GLAS

	Program ID		:	GLAS3230.PRG
	Description		:	Per GL Account
	Author			:	ESVIRTUSIO
	Date Started	:	Feb 13, 2017
	Date Finished	:	Feb 13, 2017

	UPDATES			:	---

 */ 

#include "INKEY.CH"
#include "SETCURS.CH"

SET SOFTSEEK ON
SET DELETED ON
SET CENTURY ON
SET SCOREBOARD OFF

private cSCREEN, _keys
private cGLCODE := space(11), cGLNAME, dSTART := ctod('09/01/2016'), dEND := date()
private cSRCH := space(20)
cSCREEN := savescreen(,,,)

if !NETUSE('&g_RFM_PATH\BRANCHES',.F.,5)
   return
endif
ordlistadd( '&g_RFM_PATH\BRANCHES' )

if !NETUSE('&g_GLAS_PATH\GLCODE',.F.,5)
   return
endif
ordlistadd( '&g_GLAS_PATH\GLCODE' )
ordlistadd( '&g_GLAS_PATH\GLNAME2' )

if !NETUSE('&g_GLAS_PATH\GLTRANHD',.F.,5)
   return
endif
ordlistadd( '&g_GLAS_PATH\GLTRANHD' )

if !NETUSE('&g_GLAS_PATH\GLTRANDT',.F.,5)
   return
endif
ordlistadd( '&g_GLAS_PATH\GLDTGLCD' )

if getGL()
	reportprint('RGLAS3230()')
endif

close database

return

*****************************
*
static function getGL()
*****************************
	local lretval := .f., cscr := savescreen(,,,)

	@ 10,10 clear to 14,77
	@ 10,10 to 14,77
	@ 11,11 say '   GL Code ¯ ' get cGLCODE    picture '@R 9-99-99-9999-99';
				valid lastkey() == K_ENTER .and. eval( { || DISPLABEL(1,cGLCODE) 	  		  ,;
				cGLCODE := cGLCODE		  ,;	
				if( empty( cGLCODE ),nil,cGLCODE),.T. } )
	@ 11,41 get cGLNAME when .f. color 'gr+/n'
	@ 12,11 say 'Start Date ¯ ' get dSTART when lastkey() != K_ESC pict '@D' valid !empty(dSTART)
	@ 13,11 say '  End Date ¯ ' get dEND when lastkey() != K_ESC pict '@D' valid !empty(dEND)
	lretval := .t.
	setcursor(3)
	read
	setcursor(0)

	// if lastkey() == K_ENTER
	  // lretval := .t.
	// endif

	if !Gltrandt->(dbseek('800'+cGLCODE))
		@ 24,00 clear to 24,80
		@ 24,00 say 'MESSAGE:' color 'R+/n'
		@ 24,08 say '>>> GL Code not found...' color 'w+/n'
		inkey(0)	
		lretval := .f.
		return lretval
	endif

   restscreen(,,,,cscr)

return lretval

function RGLAS3230()
private nPAGE := 0, nBEGBAL, nCREDIT, nDEBIT, nTCREDIT, nTDEBIT

	header()
		seek '800'+cGLCODE+dtos(dSTART) softseek 
		//seek g_PAR_BRCH+'1'+dtos(dSTART) softseek
		nBEGBAL := 0
		nDEBIT := 0
		nCREDIT := 0
		nTDEBIT := 0
		nTCREDIT := 0
		@ prow()+1, 72 say nBEGBAL picture '@( 999,999,999,999.99'
		@ prow()  , 93 say 'B E G I N N I N G   B A L A N C E'
		do while Gltrandt->brcode+Gltrandt->glcode == '800'+cGLCODE .and. Gltrandt->trandate <= dEND
		
			if prow() > 53
			
				setfont('BOLD')
				@ prow()+1, 33 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
				@ prow()  , 53 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
				@ prow()+1, 33 say nDEBIT picture '@( 999,999,999,999.99'
				@ prow()  , 53 say nCREDIT picture '@( 999,999,999,999.99'
				setfont('UNBOLD')
				nDEBIT := 0
				nCREDIT := 0
				setfont('PICA')
				nROW:=len('Page '+ alltrim(str(nPAGE)))
				@ 60,01 say alltrim(gUSER_ID) + ' '+ dtoc(DATE()) + ' ' + TIME() + ' GLAS3230'
				@ 60,83-nROW say 'Page ' + alltrim(str(nPAGE))
				//setfont('UNCONDENSED')
				__eject()
				header()
			endif
			
			@ prow()+1, 04 say Gltrandt->trandate
			@ prow()  , 19 say Gltrandt->brcode+Gltrandt->trnumber picture '@R 999-99999999'
			if Gltrandt->drcr == '1'
				@ prow()  , 33 say Gltrandt->amount picture '@( 999,999,999,999.99'
				nBEGBAL += Gltrandt->amount
				nDEBIT += Gltrandt->amount
				nTDEBIT += Gltrandt->amount
			else
				@ prow()  , 53 say Gltrandt->amount picture '@( 999,999,999,999.99'
				nBEGBAL -= Gltrandt->amount
				nCREDIT += Gltrandt->amount
				nTCREDIT += Gltrandt->amount
			endif
			@ prow()  , 72 say nBEGBAL picture '@( 999,999,999,999.99'
			if Gltranhd->(dbseek(Gltrandt->brcode+Gltrandt->trnumber))
				if !empty(Gltranhd->partix1)
					@ prow()  , 93 say Gltranhd->partix1
				endif
				if !empty(Gltranhd->partix2)
					@ prow()+1, 93 say Gltranhd->partix2
				endif
					if !empty(Gltranhd->partix3)
					@ prow()+1, 93 say Gltranhd->partix3
				endif
				if !empty(Gltranhd->partix4)
					@ prow()+1, 93 say Gltranhd->partix4
				endif
				if !empty(Gltranhd->partix5)
					@ prow()+1, 93 say Gltranhd->partix5
				endif
				if !empty(Gltranhd->partix6)
					@ prow()+1, 93 say Gltranhd->partix6
				endif
			endif
		Gltrandt->(dbskip())
		enddo
	
	setfont('BOLD')
	@ prow()+1, 33 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
	@ prow()  , 53 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
	@ prow()  , 72 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
	@ prow()+1, 33 say nTDEBIT picture '@( 999,999,999,999.99'
	@ prow()  , 53 say nTCREDIT picture '@( 999,999,999,999.99'
	@ prow()  , 72 say nBEGBAL picture '@( 999,999,999,999.99'
	@ prow()+1, 33 say 'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ'
	@ prow()  , 53 say 'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ'
	@ prow()  , 72 say 'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ'
	setfont('UNBOLD')
	
	nROW:=len('Page '+ alltrim(str(nPAGE)))
	@ 60,01 say alltrim(gUSER_ID) + ' '+ dtoc(DATE()) + ' ' + TIME() + ' GLAS3230'
	@ 60,83-nROW say 'Page ' + alltrim(str(nPAGE))
	__eject()
	setprc(0,0)
return

static function header()
	  
	setprc(0,0)
	setfont('PICA')
	setfont('BOLD')
	pagecenter( prow()+1,84, 'LEAGUE ONE FINANCE AND LEASING CORPORATION')
	setfont('UNBOLD')
	pagecenter( prow()+1,84, gSYS_NAME + ' ('+ cSYSCODE +')')
	setfont('BOLD')
	//@ prow()+1,00 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
	pagecenter( prow()+2,84, 'Per GL Account GL Entries')
	//@ prow()+1,00 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
	setfont('UNBOLD')
	pagecenter( prow()+1,84, 'For the Period of '+cmonth(dSTART)+' '+padl(day(dSTART),2,'0')+', '+padl(year(dSTART),4)+' - '+;
				   cmonth(dEND)+' '+padl(day(dEND),2,'0')+', '+padl(year(dEND),4))
	
		//          *       0         1			2		  3			4		  5			6		  7         8         9         0         1			2		  3			4		  5			6		  7         8         9					
		//          *  123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-

	setfont('BOLD')
	@ prow()+2,01 say transform(cGLCODE,'@R 9-99-99-9999-99') + ' '  + cGLNAME	
    setfont('UNBOLD')
	
	setfont('ELITE')
	setfont('CONDENSED')
	   //           *       0         1			2		  3			4		  5			6		  7         8         9         0         1			2		  3			4		  5			6		  7         8         9					
       //           *  123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456789-
	@ prow()+1,01 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
	@ prow()+1,01 say 'Transaction Date       TRN             Debit              Credit              Balance                                P A R T I C U L A R S                        '
	@ prow()+1,01 say 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
				//	      99/99/9999     999-99999999  999,999,999,999.99  999,999,999,999.99  999,999,999,999.99  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
				//	      04             19            33                  53                 72                   93
	nPAGE++

return


FUNCTION DISPLABEL(lfound,fBX)
local mcolor  := setcolor(), mscreen := savescreen( ,,, ), mlogic := .t.
private nPREVSELECT := 0, PRO := 0,PROS := .F., nTOP := .F.,mPRESS := .F.

aTranrecs := {}
aTranpos  := {}
_APalmSec := {}

do case

	case lfound == 1
		fShadow( 09, 24, 23, 78, 2, 'w/n' )
		dbselectarea('GLCODE')
		//GLCODE->(ordsetfocus(1),dbgotop())
		if(GLCODE->(dbseek(alltrim(substr(fBX,7,3)+fBX))),.t.,GLCODE->(dbgotop()))
		__DISPRECDB(1)
		
		@ 10,25 say '      CODE                       GLNAME              '  color 'w/gr+'
		//            9-99-99-9999-99 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
		do while .t.
		mBX := achoice(11,25, 22, 77, aTranRecs, .t.,'KEYFUNC')
			do case
				case lastkey() == K_ESC
					exit
				case lastkey() == K_ENTER
					if mPRESS
						exit
					endif
			endcase
		enddo
		setcolor       ( mcolor )
		restscreen     ( ,,,, mscreen )

   
endcase

return padr(mBX,19)

FUNCTION __DISPRECDB(lfound)
local nCTR := 0

do case
	case lfound == 1
		_keys := 1
		dbselectarea('GLCODE')
		
		//GLCODE->(dbseek(g_PAR_BRCH+cSRCH))

		do while  !GLCODE->(eof()) // GLCODE->brcode == g_PAR_BRCH 
			if !empty(GLCODE->brcode) .and. !GLCODE->nopost
			nCTR++

			aadd ( aTranRecs,  padr(' ',' ') + transform(GLCODE->glcode,'@R 9-99-99-9999-99') + ' ' + padr( upper(GLCODE->glname),36) )
			aadd ( _APalmSec,GLCODE->glcode)
			endif
/* 			if nCTR > 11
				exit		
			endif */

			GLCODE->(dbskip(+1))
		enddo

endcase

return 


FUNCTION KEYFUNC (status, curr_elem, curr_row)
local key    := lastkey(),mSAY,lchar := ' '
local __nCTR := 0, getlist := {}, menulist := {},nORGPOS := 0
local _lfound := .f., mscreen1 := savescreen1( ,,, )


do case

	case _keys == 1

		do case
			case key == K_ESC
				return 0

			case key == K_ENTER
				GLCODE->(ordsetfocus(1))
				mPRESS := .T.
				__mseekvar := alltrim(_APalmSec[curr_elem])
				if GLCODE->(dbseek(substr(__mseekvar,7,3)+__mseekvar))
					cGLCODE := GLCODE->glcode
					cGLNAME := padr(GLCODE->glname,36)
				endif
				return 0

			case key >= 32 .and. key <= 254

				lchar	:= upper(chr(lastkey()))
				nORGPOS := recno()
				__keyboard(lchar)

				@ 23,25  say ''
				@ 23,26 get cSRCH pict '@!'

				setcursor( 3 )
				read
				setcursor( 0 )

				restscreen1     ( ,,,, mscreen1 )

				if lastkey() == K_ENTER
					GLCODE->(ordsetfocus(2))
					mPRESS := .F.
					if GLCODE->(dbseek(rtrim(cSRCH)))
						aTranRecs   := {}
						_APalmSec   := {}
						__DISPRECDB(1)

						
						@ 11,25 clear to 22, 77
					else
						error('GLCODE not found!')
						dbgoto(nORGPOS)
					endif
				endif
				return 0

	endcase
	
endcase

return 2
