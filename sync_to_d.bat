@echo off
chcp 65001 >nul
title Sync C:\nabda_app to D:\nabda_app
color 0B

echo.
echo =============================================
echo   Sync C:\nabda_app  =^>  D:\nabda_app
echo =============================================
echo.

if not exist "D:\nabda_app" (
    echo Creation du dossier D:\nabda_app...
    mkdir "D:\nabda_app"
)

echo Copie en cours ^(cela peut prendre 1-3 minutes^)...
echo.

REM Robocopy: mirror mode, exclude cache dirs
robocopy "C:\nabda_app" "D:\nabda_app" /MIR /R:2 /W:1 /MT:8 ^
  /XD ".dart_tool" "build" ".idea" ".gradle" "node_modules" ^
       "windows\flutter\ephemeral" "linux\flutter\ephemeral" ^
       "macos\Flutter\ephemeral" "ios\Flutter\ephemeral" ^
  /XF "*.log" ".DS_Store" ".flutter-plugins" ".flutter-plugins-dependencies" ^
  /NFL /NDL /NP

if %errorlevel% GEQ 8 (
    echo.
    echo ECHEC de la copie - code %errorlevel%
    pause
    exit /b 1
)

echo.
echo =============================================
echo   Copie terminee avec succes!
echo   Prochaine etape: ouvrez D:\nabda_app dans
echo   Cowork et lancez deploy.bat depuis la^.
echo =============================================
echo.
pause
