@echo off
chcp 65001 >nul
title Nabda - Build Android app
cd /d "%~dp0"
echo ============================================================
echo   Nabda - build Android app  (close Chrome and other apps first)
echo ============================================================
echo.
echo [1/3] flutter pub get ...
call flutter pub get
if errorlevel 1 goto fail
echo.
echo [2/3] Building AAB for Google Play (10-20 minutes) ...
call flutter build appbundle --release --no-tree-shake-icons
if errorlevel 1 goto fail
echo.
echo   AAB ready:  build\app\outputs\bundle\release\app-release.aab
echo   (upload this file in Play Console - Closed testing - Create new release)
echo.
choice /c YN /m "Also build an APK to install directly on a phone? Y/N"
if errorlevel 2 goto done
echo.
echo [3/3] Building APK ...
call flutter build apk --release --no-tree-shake-icons
if errorlevel 1 goto fail
echo.
echo   APK ready:  build\app\outputs\flutter-apk\app-release.apk
:done
explorer build\app\outputs
echo.
echo   Done.
pause
exit /b 0
:fail
echo.
echo   !! BUILD FAILED - take a screenshot of the error above and send it.
pause
exit /b 1
