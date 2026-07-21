@echo off
chcp 65001 >nul
echo ============================================
echo   Nabda - Commit + Push redesign updates
echo   github.com/billelrns/nabda
echo ============================================
cd /d "%~dp0"

echo [1/4] Removing stale git lock (if any)...
del /f .git\index.lock 2>nul

echo [2/4] Staging all changes...
git add -A

echo [3/4] Committing...
git commit -m "feat: 2026 visual redesign - animated dual-heart logo, 3D icon set, glossy UI, floating fetus (38 original images), local article images (Unsplash removed), modest Arab photography set"

echo [4/4] Pushing to origin/main...
git push origin main

echo.
echo ============================================
echo   Done! Check github.com/billelrns/nabda
echo ============================================
pause
