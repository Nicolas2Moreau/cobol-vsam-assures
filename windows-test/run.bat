@echo off
REM ========================================
REM Script d'execution MAJASSU
REM ========================================

echo.
echo ========================================
echo Execution MAJASSU - Mise a jour assures
echo ========================================
echo.

REM Definir les chemins
set BINPATH=bin
set DATAPATH=DATA
set LOGPATH=logs

REM Creer le repertoire logs si necessaire
if not exist %LOGPATH% mkdir %LOGPATH%

REM Verifier que les programmes sont compiles
if not exist %BINPATH%\MAJASSU.exe (
    echo ERREUR: MAJASSU.exe non trouve
    echo Lancez compile.bat d'abord
    pause
    exit /b 1
)

REM Definir les variables d'environnement pour les fichiers
set ETATANO=%DATAPATH%\ETATANO.txt
set ASSURES=%DATAPATH%\ASSURES.dat
set MVTS=%DATAPATH%\MVTS.dat

REM Lancer MAJASSU avec redirection des logs
echo Lancement du traitement...
echo.
%BINPATH%\MAJASSU.exe > %LOGPATH%\execution.log 2>&1

REM Verifier le code retour
if errorlevel 1 (
    echo.
    echo ERREUR: Le traitement a echoue
    echo Consultez %LOGPATH%\execution.log pour details
    pause
    exit /b 1
)

echo.
echo ========================================
echo Traitement termine avec succes !
echo ========================================
echo.
echo Resultats :
echo - Log execution : %LOGPATH%\execution.log
echo - Anomalies     : %ETATANO%
echo.

REM Afficher le contenu du log
type %LOGPATH%\execution.log

echo.
pause
