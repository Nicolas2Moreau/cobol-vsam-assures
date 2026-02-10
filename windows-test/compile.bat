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

REM Compilation PGMERR
echo [1/3] Compilation PGMERR...
cobc -x -free -I %COPYPATH% %COBOLPATH%\PGMERR.cbl -o %OUTPATH%\PGMERR.exe
if errorlevel 1 (
    echo ERREUR: Echec compilation PGMERR
    pause
    exit /b 1
)
echo OK - PGMERR compile

REM Compilation PGMVSAM
echo [2/3] Compilation PGMVSAM...
cobc -x -free -I %COPYPATH% %COBOLPATH%\PGMVSAM.cbl -o %OUTPATH%\PGMVSAM.exe
if errorlevel 1 (
    echo ERREUR: Echec compilation PGMVSAM
    pause
    exit /b 1
)
echo OK - PGMVSAM compile

REM Compilation MAJASSU
echo [3/3] Compilation MAJASSU...
cobc -x -free -I %COPYPATH% %COBOLPATH%\MAJASSU.cbl -o %OUTPATH%\MAJASSU.exe
if errorlevel 1 (
    echo ERREUR: Echec compilation MAJASSU
    pause
    exit /b 1
)
echo OK - MAJASSU compile

echo.
echo ========================================
echo Compilation terminee avec succes !
echo ========================================
echo.
echo Executables generes dans %OUTPATH%\
echo.

pause
