/*
PROGRAM     : GLAS4100.PRG
DESCRIPTION : CHANGE JV TRANSACTION DATE
AUTHOR      : ERLACHICA
CREATED     : OCTOBER 19, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

#include "INKEY.CH"

private cVBrCode:=left(cSelectBr,3), aBrAcs:={}, nSelBrCnt:=1, nBrAcsCnt, dVDate, nJVBackDay:=0

if !OpenBrEntry('JV')
   return
endif

nBrAcsCnt := nSelBrCnt
if !SelectBr(12)
   return
endif

if !netuse('&g_RFM_Path\DEFLTVAL',.f.,5)
   return
endif
set index to &g_RFM_Path\DEFLTVAL

if DEFLTVAL->(dbseek(padr('JVBACKDAY',10)))
   nJVBackDay := val(DEFLTVAL->defltvalue)
endif
DEFLTVAL->(dbclosearea())

OptionBar('ESC-Exit')
dVDate := ctod(right(aBrAcs[nBrAcsCnt],10))
ChngeVDate('JV')
return

****************************
function ChngeVDate(cVCateg)
****************************
local dOldVDate:=dVDate

if len(aBrAcs) > 1
   @13,19,15,60 box 'ÃÄ´³ÙÄÀ³ ' color 'w+/n'
   @14,27 say 'Latest '+cVCateg+' Date' color 'w+/n'
   @14,43 get dVDate valid !empty(dVDate) .and. dVDate>dOldVDate
else
   @11,19,14-1,60 box 'ÚÄ¿³ÙÄÀ³ ' color 'w+/n'
   @12,27 say 'Latest '+cVCateg+' Date' color 'w+/n'
   @12,43 get dVDate valid !empty(dVDate) .and. dVDate>dOldVDate - iif(cVCateg=='JV',nJVBackDay+1,0)
endif
setcursor(1)
read
setcursor(0)

if lastkey() != K_ESC
   if dVDate > date() + 1
      @24,0 say ' ERROR: ' color 'r+'
	  @24,8 say padr('Entered Date exceeds next day. Press Any Key.',72) color 'w'
	  inkey(0)
   else
	  if dow(dVDate) == 7 .or. dow(dVDate) == 1
	     @24,0 say ' ERROR: ' color 'r+'
		 @24,8 say padr('Entered Date lies on a Weekend. Press Any Key.',72) color 'w'
		 inkey(0)
	  else
		 if !netuse('&g_RFM_Path\HOLIDAYS',.f.,5)
			return
		 endif
		 set index to &g_RFM_Path\HOLIDATE
		 
		 if HOLIDAYS->(dbseek(dVDate))
		    @24,0 say ' ERROR: ' color 'r+'
			@24,8 say padr('Entered Date is a Holiday. Press Any Key.',72) color 'w'
			HOLIDAYS->(dbclosearea())
			inkey(0)
		 else
			HOLIDAYS->(dbclosearea())
			if keyreview('AC') == 2
			   SaveVDate(cVCateg)
			endif
		 endif
	  endif
   endif
endif
return

**********************************
static function SaveVDate(cVCateg)
**********************************
if !netuse('&g_RFM_Path\OL_PARAM',.f.,5)
   return
endif
set index to &g_RFM_Path\OL_PARAM

if !OL_PARAM->(dbseek('TRANHEAD'+cVCateg+'NUMBER  '+substr(aBrAcs[nBrAcsCnt],31,3)))
   @24,0 say ' ERROR: ' color 'r+'
   @24,8 say padr(substr(aBrAcs[nBrAcsCnt],31,3)+' '+alltrim(left(aBrAcs[nBrAcsCnt],30))+' has no Transaction Reference. Press Any Key.',72) color 'w'
   OL_PARAM->(dbclosearea())
   inkey(0)
else
   if OL_PARAM->(netlock('R'))
      OL_PARAM->date := dVDate
	  OL_PARAM->(dbcommit())
   endif
   OL_PARAM->(dbunlock())
   OL_PARAM->(dbclosearea())
   
   @24,0  say ' MESSAGE: ' color 'bg+'
   @24,10 say padr(cVCateg+' Date is now '+dtoc(dVDate)+'. Press Any Key.',70) color 'w'
   inkey(0)
endif
return