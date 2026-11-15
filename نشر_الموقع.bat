@echo off
chcp 65001 >nul
title Nabda - Deploy nabda.online
cd /d "%~dp0"
echo ============================================================
echo   Nabda - build + deploy nabda.online
echo ============================================================
echo.
echo [1/3] Building site + app (takes several minutes) ...
powershell -ExecutionPolicy Bypass -File tool\build_site.ps1
if errorlevel 1 (
  echo.
  echo   !! BUILD FAILED - take a screenshot of the error above and send it.
  pause
  exit /b 1
)
echo.
echo [2/3] Uploading a TEST version (preview) ...
call firebase hosting:channel:deploy preview --expires 7d
echo.
echo   Open the "Channel URL" link above on your PHONE and your COMPUTER and test.
echo.
choice /c YN /m "Everything OK? Y = publish to nabda.online  /  N = cancel"
if errorlevel 2 (
  echo   Cancelled - nothing changed on nabda.online.
  pause
  exit /b 0
)
echo.
echo [3/3] Publishing to nabda.online ...
call firebase deploy --only hosting
echo.
echo ============================================================
echo   Done!  https://nabda.online   (Ctrl+F5 to refresh)
echo ============================================================
pause
