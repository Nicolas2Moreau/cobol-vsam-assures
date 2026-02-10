@echo off
REM ========================================
REM Script d'execution MAJASSU
REM ========================================

echo.
echo ========================================
echo EXECUTION MAJASSU - Mise a jour assures
echo ========================================
echo.

REM Verifier que les programmes sont compiles
if not exist bin\MAJASSU.exe (
    echo ERREUR: MAJASSU.exe non trouve
    echo Lancez compile.bat d'abord
    pause
    exit /b 1
)

REM Verifier que les donnees sont initialisees
if not exist WORK\ASSURES.dat (
    echo ERREUR: ASSURES.dat non trouve
    echo Lancez init.bat d'abord
    pause
    exit /b 1
)

if not exist WORK\MVTS.dat (
    echo ERREUR: MVTS.dat non trouve
    echo Lancez init.bat d'abord
    pause
    exit /b 1
)

REM Supprimer l'ancien fichier anomalies s'il existe
if exist WORK\ETATANO.txt del WORK\ETATANO.txt

REM Lancer MAJASSU
echo Lancement du traitement...
echo.
bin\MAJASSU.exe
set RETCODE=%errorlevel%

echo.
echo ========================================
if %RETCODE% equ 0 (
    echo TRAITEMENT TERMINE AVEC SUCCES
) else (
    echo ATTENTION: Code retour %RETCODE%
)
echo ========================================
echo.

REM Afficher le fichier anomalies s'il existe
if exist WORK\ETATANO.txt (
    echo Fichier anomalies (WORK\ETATANO.txt) :
    echo ----------------------------------------
    type WORK\ETATANO.txt
    echo ----------------------------------------
) else (
    echo Aucun fichier anomalies genere
)

echo.
echo Pour retester avec donnees initiales : reset.bat
echo.

pause
