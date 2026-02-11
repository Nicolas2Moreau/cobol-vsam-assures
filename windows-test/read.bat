@echo off
REM ========================================
REM LECTURE FICHIERS KSDS ET ESDS
REM ========================================

set COPYPATH=COPY
set COBOLPATH=COBOL
set OUTPATH=bin

REM Recompiler READDATA à chaque fois (petit programme)
echo Compilation READDATA.cbl...
cobc -x -I %COPYPATH% %COBOLPATH%\READDATA.cbl -o %OUTPATH%\READDATA.exe 2>nul
if errorlevel 1 (
    echo ERREUR : Echec compilation READDATA.cbl
    pause
    exit /b 1
)
echo.

REM Exécuter READDATA
%OUTPATH%\READDATA.exe

echo.
pause
