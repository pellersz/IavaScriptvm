@ECHO OFF
set arg=%1

sertvm %arg%
if ERRORLEVEL 1 (del sertvm_frvctvs.bbl & exit 1)
bison -dvt IavaScriptvm.y
if ERRORLEVEL 1 (del IavaScriptvm.tab* sertvm_frvctvs.bbl & exit 1)
flex -Ca IavaScriptvm.lex
if ERRORLEVEL 1 (del lex.yy.c IavaScriptvm.tab* sertvm_frvctvs.bbl & exit 1)
g++ lex.yy.c IavaScriptvm.tab.c -o p
if ERRORLEVEL 1 (del p.exe lex.yy.c IavaScriptvm.tab* sertvm_frvctvs.bbl & exit 1)
type sertvm_frvctvs.bbl | p > prodvco.txt
del p.exe lex.yy.c IavaScriptvm.tab* sertvm_frvctvs.bbl 
