@echo off
REM ========================================
REM Script de compilation GNUCobol
REM ========================================

echo.
echo ========================================
echo Compilation des programmes COBOL
echo ========================================
echo.

REM Definir les chemins
set COPYPATH=COPY
set COBOLPATH=COBOL
set OUTPATH=bin

REM Creer le repertoire bin si necessaire
if not exist %OUTPATH% mkdir %OUTPATH%

REM ========================================
REM 1. Compilation LOADKSDS (utilitaire)
REM ========================================
echo [1/2] Compilation LOADKSDS (chargement KSDS)...
cobc -x -I %COPYPATH% %COBOLPATH%\LOADKSDS.cbl -o %OUTPATH%\LOADKSDS.exe
if errorlevel 1 (
    echo ERREUR: Echec compilation LOADKSDS
    pause
    exit /b 1
)
echo OK - LOADKSDS compile

REM ========================================
REM 2. Compilation MAJASSU + PGMVSAM + PGMERR
REM    (tout ensemble pour que les CALL fonctionnent)
REM ========================================
echo [2/2] Compilation MAJASSU (avec PGMVSAM + PGMERR)...
cobc -x -I %COPYPATH% %COBOLPATH%\MAJASSU.cbl %COBOLPATH%\PGMVSAM.cbl %COBOLPATH%\PGMERR.cbl -o %OUTPATH%\MAJASSU.exe
if errorlevel 1 (
    echo ERREUR: Echec compilation MAJASSU
    pause
    exit /b 1
)
echo OK - MAJASSU compile (avec PGMVSAM et PGMERR integres)

echo.
echo ========================================
echo Compilation terminee avec succes !
echo ========================================
echo.
echo Executables generes :
echo - %OUTPATH%\LOADKSDS.exe (utilitaire chargement)
echo - %OUTPATH%\MAJASSU.exe  (programme principal)
echo.
echo Prochaine etape : init.bat (initialiser les donnees)
echo.

pause
