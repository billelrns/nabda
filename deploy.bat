@echo off
chcp 65001 >nul
title Nabda - Security Deploy
color 0A
cd /d "%~dp0"

echo.
echo =============================================
echo   Nabda - Deploiement securitaire
echo =============================================
echo.

echo [1/4] Mise a jour des dependances...
call flutter pub get
if errorlevel 1 goto error

echo.
echo [2/4] Construction du site web...
call flutter build web --release
if errorlevel 1 goto error

echo.
echo [3/4] Deploiement des regles Firestore...
call firebase.cmd deploy --only firestore:rules

echo.
echo [4/4] Deploiement du site...
call firebase.cmd deploy --only hosting
if errorlevel 1 goto error

echo.
echo =============================================
echo   SUCCES! Visitez https://nabda.online
echo =============================================
echo.
pause
exit /b 0

:error
echo.
echo =============================================
echo   ECHEC - Verifiez les messages ci-dessus
echo =============================================
echo.
pause
exit /b 1
