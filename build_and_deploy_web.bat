@echo off
cd /d "%~dp0"
echo ============================================================
echo   Nabda - Build web + Deploy to nabda.online + Push GitHub
echo ============================================================

echo.
echo [0/5] Compressing new images (important for web size) ...
python compress_new_images.py
if errorlevel 1 echo   (skipped - install Pillow with: pip install pillow)

echo.
echo [1/5] Cleaning old web build ...
rmdir /s /q build\web 2>nul

echo.
echo [2/5] flutter pub get ...
call flutter pub get

echo.
echo [3/5] Building Flutter web (this takes a few minutes) ...
call flutter build web --release
if errorlevel 1 (
  echo.
  echo   !! Build failed - fix errors above and retry.
  pause
  exit /b 1
)

echo.
echo [4/5] Deploying to Firebase Hosting ...
call firebase deploy --only hosting
if errorlevel 1 (
  echo   !! Deploy failed - check internet / firebase login.
)

echo.
echo [5/5] Pushing pending commits to GitHub ...
del /f .git\index.lock 2>nul
git add -A
git commit -m "chore: web build - article images unified"
git push origin main

echo.
echo ============================================================
echo   Done!  https://nabda.online   ^|   github.com/billelrns/nabda
echo   (Ctrl+F5 in the browser to bypass cache)
echo ============================================================
pause
