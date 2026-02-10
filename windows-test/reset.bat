@echo off
REM ========================================
REM Script de reinitialisation (reset)
REM ========================================

echo.
echo ========================================
echo REINITIALISATION A L'ETAT INITIAL
echo ========================================
echo.

REM Verifier que WORK existe
if not exist WORK (
    echo Le repertoire WORK n'existe pas encore
    echo Lancez init.bat pour initialiser
    pause
    exit /b 0
)

echo Suppression des fichiers de travail...

REM Supprimer tous les fichiers dans WORK
del /Q WORK\*.* 2>nul

echo OK - Fichiers supprimes
echo.
echo Reinitialisation des donnees...
echo.

REM Relancer init.bat
call init.bat

echo.
echo ========================================
echo RESET TERMINE
echo ========================================
echo.
echo Etat : Donnees reinitialisees (20 assures, 11 mouvements)
echo Prochaine etape : run.bat (executer MAJASSU)
echo.
