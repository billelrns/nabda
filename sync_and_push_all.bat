@echo off
chcp 65001 >nul
echo ============================================================
echo   Nabda - Sync folders + Push to GitHub
echo ============================================================
cd /d "%~dp0"

echo.
echo [1/4] Sync -^> OneDrive\nabda_app ...
robocopy "C:\nabda_app" "C:\Users\AMT mobile\OneDrive\nabda_app" /MIR /XD build .dart_tool .git .idea node_modules /XF *.log /NFL /NDL /NJH /NJS /nc /ns /np
echo     done.

echo.
echo [2/4] Sync -^> D:\nabda_app ...
robocopy "C:\nabda_app" "D:\nabda_app" /MIR /XD build .dart_tool .idea node_modules /XF *.log /NFL /NDL /NJH /NJS /nc /ns /np
echo     done.

echo.
echo [3/4] Staging git changes ...
del /f .git\index.lock 2>nul
git add -A

echo.
echo [4/4] Commit + push ...
git commit -m "feat: article images system - 343 unique article images (compressed), local image resolver wired into app + web, shop category products from Firestore, fixed corrupted files"
git push origin main

echo.
echo ============================================================
echo   Done! github.com/billelrns/nabda
echo ============================================================
pause
