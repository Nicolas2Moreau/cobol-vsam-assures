@echo off
REM ========================================
REM Script d'initialisation des donnees
REM ========================================

echo.
echo ========================================
echo INITIALISATION DES DONNEES
echo ========================================
echo.

REM Verifier que les programmes sont compiles
if not exist bin\LOADKSDS.exe (
    echo ERREUR: LOADKSDS.exe non trouve
    echo Lancez compile.bat d'abord
    pause
    exit /b 1
)

if not exist bin\MAJASSU.exe (
    echo ERREUR: MAJASSU.exe non trouve
    echo Lancez compile.bat d'abord
    pause
    exit /b 1
)

REM Creer le repertoire WORK si necessaire
if not exist WORK mkdir WORK

echo [1/2] Copie fichier MVTS (ESDS - mouvements)...
copy /Y DATA\MVTS WORK\MVTS.dat > nul
if errorlevel 1 (
    echo ERREUR: Echec copie MVTS
    pause
    exit /b 1
)
echo OK - MVTS.dat cree (11 mouvements)

echo [2/2] Chargement KSDS ASSURES (20 assures)...
echo.
bin\LOADKSDS.exe
if errorlevel 1 (
    echo.
    echo ERREUR: Echec chargement KSDS
    pause
    exit /b 1
)

echo.
echo ========================================
echo INITIALISATION TERMINEE
echo ========================================
echo.
echo Fichiers crees dans WORK/ :
echo - ASSURES.dat (KSDS - 20 assures)
echo - ASSURES.idx (index KSDS)
echo - MVTS.dat    (ESDS - 11 mouvements)
echo.
echo Prochaine etape : run.bat (executer MAJASSU)
echo.

pause
