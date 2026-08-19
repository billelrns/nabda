@echo off
cd /d "%~dp0"
echo ============================================================
echo   Nabda - Deploy Firestore security rules
echo ============================================================
echo.

echo [1/3] Checking Firebase login ...
call firebase login:list
echo.

echo [2/3] Current project:
call firebase use
echo.

echo [3/3] Deploying firestore.rules ...
call firebase deploy --only firestore:rules

echo.
echo ============================================================
echo   Done. Rules are live immediately (no app rebuild needed).
echo ============================================================
pause
