@echo off
chcp 65001 >nul
echo ============================================================
echo   Nabda - Build web + Deploy to nabda.online + Push GitHub
echo ============================================================
cd /d "%~dp0"

echo.
echo [1/4] Cleaning old web build ...
rmdir /s /q build\web 2>nul

echo.
echo [2/4] Building Flutter web (this takes a few minutes) ...
call flutter build web --release
if errorlevel 1 (
  echo.
  echo   ^!^! Build failed - fix errors above and retry.
  pause
  exit /b 1
)

echo.
echo [3/4] Deploying to Firebase Hosting ...
call firebase deploy --only hosting
if errorlevel 1 (
  echo   ^!^! Deploy failed - check internet / firebase login.
)

echo.
echo [4/4] Pushing pending commits to GitHub ...
del /f .git\index.lock 2>nul
git add -A
git commit -m "chore: web build config + article images sync" 2>nul
git push origin main

echo.
echo ============================================================
echo   Done!  https://nabda.online   ^|   github.com/billelrns/nabda
echo   (Ctrl+F5 in the browser to bypass cache)
echo ============================================================
pause
