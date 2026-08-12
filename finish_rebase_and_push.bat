@echo off
chcp 65001 >nul
echo ============================================================
echo   Nabda - Finish rebase (conflict resolved) + push
echo ============================================================
cd /d "%~dp0"
del /f .git\index.lock 2>nul

echo.
echo [1/3] Marking conflict as resolved ...
git add lib/screens/shop/shop_page.dart
git add -A

echo.
echo [2/3] Continuing rebase ...
set GIT_EDITOR=true
git rebase --continue
if errorlevel 1 (
  echo   Rebase may already be finished, or another conflict appeared.
  git status --short
)

echo.
echo [3/3] Pushing to GitHub ...
git push origin main
if errorlevel 1 (
  echo   ^!^! Push failed. Check internet, then run this file again.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   Done!  github.com/billelrns/nabda
echo ============================================================
git log --oneline -3
pause
