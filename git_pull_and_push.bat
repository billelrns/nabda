@echo off
chcp 65001 >nul
echo ============================================================
echo   Nabda - Sync with GitHub (pull --rebase then push)
echo ============================================================
cd /d "%~dp0"
del /f .git\index.lock 2>nul

echo.
echo [1/4] Saving any uncommitted work ...
git add -A
git commit -m "chore: local changes before sync" 2>nul

echo.
echo [2/4] Fetching remote ...
git fetch origin

echo.
echo [3/4] Rebasing local commits on top of remote ...
git pull --rebase origin main
if errorlevel 1 (
  echo.
  echo   ^!^! Conflict detected. Nothing was lost.
  echo   Run:  git rebase --abort     to cancel
  echo   then tell Claude about it.
  pause
  exit /b 1
)

echo.
echo [4/4] Pushing to GitHub ...
git push origin main
if errorlevel 1 (
  echo   ^!^! Push still failed - check internet connection.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   Done!  github.com/billelrns/nabda
echo ============================================================
git log --oneline -3
pause
