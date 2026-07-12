@echo off
title Nabda - Git Push
color 0A
cd /d "%~dp0"

echo.
echo ==================================================
echo   Nabda - Commit + Push to GitHub
echo ==================================================
echo.

REM Verification of Git repo
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Not a Git repository.
    pause
    exit /b 1
)

REM Remove stale lock file if it exists
if exist ".git\index.lock" (
    echo [INFO] Removing stale lock file .git\index.lock ...
    del /f /q ".git\index.lock"
    echo [OK] Lock removed.
    echo.
)

echo GitHub remote:
git remote get-url origin
echo.

echo ==================================================
echo   Modified files:
echo ==================================================
git status --short
echo.
echo Press any key to CONTINUE with commit + push...
pause >nul
echo.

echo [1/3] git add -A ...
git add -A
if errorlevel 1 goto error

echo [2/3] git commit ...
git commit -m "feat: nabda.online redesign - landing + shop + admin slug + security" -m "Landing: new hero carousel with 5 slides, Cairo font, glassy navbar, baby names section, hearts animation" -m "Shop: /shop page with Firestore products, categories, product detail modal, deep linking via slug" -m "Admin: slug field for products, multi-image upload, CSP fix for blob URLs" -m "Security: custom domain email delivery, security headers, users_directory for admin privacy, AI rate limiting"

echo.
echo [3/3] git push origin main ...
git push origin main
if errorlevel 1 goto error

echo.
echo ==================================================
echo   SUCCESS - Pushed to GitHub
echo ==================================================
echo   https://github.com/billelrns/nabda
echo ==================================================
echo.
pause
exit /b 0

:error
echo.
echo ==================================================
echo   FAILED - see error above
echo ==================================================
echo.
echo Possible reasons:
echo   - GitHub authentication needed (use Personal Access Token)
echo   - Internet connection issue
echo   - Merge conflict with remote
echo.
pause
exit /b 1
