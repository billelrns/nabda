@echo off
chcp 65001 >nul
echo ============================================================
echo   Nabda - Install article_titles.json as an app asset
echo ============================================================
cd /d "%~dp0"

if not exist "assets\data" mkdir "assets\data"
copy /Y "article_titles.json" "assets\data\article_titles.json" >nul
if errorlevel 1 (
  echo   ^!^! Copy failed.
  pause
  exit /b 1
)
echo   OK: assets\data\article_titles.json
echo.

echo Running flutter pub get ...
call flutter pub get

echo.
echo ============================================================
echo   Done. Now run:  flutter run   (full restart)
echo ============================================================
pause
