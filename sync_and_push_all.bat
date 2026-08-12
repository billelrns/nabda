@echo off
cd /d "%~dp0"
echo ============================================================
echo   Nabda - Sync folders + Push to GitHub
echo ============================================================

echo.
echo [1/5] Sync -^> OneDrive\nabda_app ...
robocopy "C:\nabda_app" "C:\Users\AMT mobile\OneDrive\nabda_app" /MIR /XD build .dart_tool .git .idea node_modules /XF *.log /NFL /NDL /NJH /NJS /nc /ns /np
echo     done.

echo.
echo [2/5] Sync -^> D:\nabda_app ...
robocopy "C:\nabda_app" "D:\nabda_app" /MIR /XD build .dart_tool .idea node_modules /XF *.log /NFL /NDL /NJH /NJS /nc /ns /np
echo     done.

echo.
echo [3/5] Stage all changes ...
del /f .git\index.lock 2>nul
git add -A

echo.
echo [4/5] Commit ...
git commit -m "chore: sync latest changes"

echo.
echo [5/5] Pull --rebase then push ...
git pull --rebase origin main
git push origin main

echo.
echo ============================================================
echo   Done - github.com/billelrns/nabda
echo ============================================================
pause
