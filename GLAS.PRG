/*
PROGRAM     : GLAS.PRG
DESCRIPTION : GLAS MAIN PROGRAM
AUTHOR      : ERLACHICA
CREATED     : JUNE 24, 2016
UPDATED     : <DEV> <DATE> <ENHANCEMENT>
*/

private cSysCode:='GLAS', g_GLAS_Tmp, gTmpGL, gTmpPayee

set softseek on

callmod('GLASNOTI()')

if !empty(gTmpGL)
   ferase('&g_GLAS_Tmp\&gTmpGL'+'.DBF')
   ferase('&g_GLAS_Tmp\&gTmpGL'+'.NTX')
   ferase('&g_GLAS_Tmp\N'+substr(gTmpGL,2)+'.NTX')
endif

if !empty(gTmpPayee)
   ferase('&g_GLAS_Tmp\&gTmpPayee'+'.DBF')
   ferase('&g_GLAS_Tmp\&gTmpPayee'+'.NTX')
endif
return