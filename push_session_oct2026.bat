@echo off
chcp 65001 >nul
title Nabda - Push session (Oct 2026) to GitHub
cd /d "%~dp0"
echo ============================================================
echo   Nabda - commit + push to github.com/billelrns/nabda
echo ============================================================
echo.

if exist ".git\index.lock" del /f /q ".git\index.lock"

echo [1/5] Remove leaked service account key from Git tracking (file stays on disk) ...
git rm --cached --quiet --ignore-unmatch "nabda-import/serviceAccount.json"
echo.

echo [2/5] Safety check - secrets must NOT be staged ...
git add -A
git diff --cached --name-only | findstr /I /R "serviceAccount adminsdk key\.properties \.jks$ google-services\.json firebase_options\.dart" >nul
if not errorlevel 1 (
    echo [STOP] A secret file is staged. Aborting. Check .gitignore
    git diff --cached --name-only | findstr /I /R "serviceAccount adminsdk key\.properties \.jks$ google-services\.json firebase_options\.dart"
    git reset --quiet
    pause
    exit /b 1
)
echo     OK - no secrets staged.
echo.

echo [3/5] Commit ...
git commit -q -m "feat: nabda.online v2 + admin console + markets (DZ/SA) + app parity" ^
 -m "Website: multi-page site, unified shell, shop with per-product URLs, standalone articles, encyclopedia, community birth-month clubs with 3D month icons, SVG carousel arrows, fiqh (273 rulings), qadaa tracker, twin names, multi-baby add/edit/delete synced live with the app" ^
 -m "Admin /admin: users, coupons, app ads, broadcast notifications, support and password-reset requests, reports, markets module, product convert/copy to another market, per-market orders and revenue" ^
 -m "Markets: Algeria + Saudi Arabia, per-market prices/stock/dialect text, /sa routes, no currency conversion, Saudi checkout and shipping" ^
 -m "App: market layer in CountryCurrencyService, isShopHidden on all product lists, birth-month club carousel, baby edit/delete, live qadaa sync, SA price fields in admin editor, version 1.0.2+4" ^
 -m "Rules: ads collection, SA stock decrement. Docs: CLAUDE.md + NABDA_PROJECT_HISTORY.md"
if errorlevel 1 echo     (nothing new to commit)
echo.

echo [4/5] Push ...
git push origin main
if errorlevel 1 (
    echo.
    echo [FAILED] Push failed: check internet / GitHub login (Personal Access Token^).
    pause
    exit /b 1
)
echo.

echo [5/5] Mirror copies (OneDrive, D:, Google Drive for desktop if installed) ...
if exist "C:\Users\AMT mobile\OneDrive\nabda_app" robocopy "C:\nabda_app" "C:\Users\AMT mobile\OneDrive\nabda_app" /MIR /XD build .dart_tool .git .idea node_modules /XF *.log *.jks serviceAccount.json key.properties /NFL /NDL /NJH /NJS /nc /ns /np
if exist "D:\nabda_app" robocopy "C:\nabda_app" "D:\nabda_app" /MIR /XD build .dart_tool .idea node_modules /XF *.log /NFL /NDL /NJH /NJS /nc /ns /np
if exist "G:\My Drive\nabda_app" robocopy "C:\nabda_app" "G:\My Drive\nabda_app" /MIR /XD build .dart_tool .git .idea node_modules /XF *.log *.jks serviceAccount.json key.properties /NFL /NDL /NJH /NJS /nc /ns /np
if exist "G:\Mon Drive\nabda_app" robocopy "C:\nabda_app" "G:\Mon Drive\nabda_app" /MIR /XD build .dart_tool .git .idea node_modules /XF *.log *.jks serviceAccount.json key.properties /NFL /NDL /NJH /NJS /nc /ns /np
echo.
echo ============================================================
echo   Done!  https://github.com/billelrns/nabda
echo ============================================================
pause
