@echo off
cd /d "%~dp0"
echo ============================================================
echo   Fix detached HEAD and push to GitHub
echo ============================================================
echo.

echo [1/7] Backup current work to branch backup-2026-08-12 ...
git branch -f backup-2026-08-12 HEAD
echo.

echo [2/7] Attach main to current work (end detached HEAD) ...
git checkout -B main HEAD
echo.

echo [3/7] Fetch remote ...
git fetch origin main
echo.

echo [4/7] Remote commits you do not have locally:
git log --oneline HEAD..origin/main
echo.

echo [5/7] Rebase main on top of remote, keeping your files ...
git reset --soft origin/main
git add -A
echo.

echo [6/7] Create one clean commit ...
git commit -m "fix(images): unify article image resolution across all screens + add 47 AI images (d001-d030, f001-f007, b001-b010) + correct news image mapping + names articles carousel"
echo.

echo [7/7] Push ...
git push origin main
echo.

echo ============================================================
echo   Done - github.com/billelrns/nabda
echo   Safety branch: backup-2026-08-12
echo ============================================================
pause
