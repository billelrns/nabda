@echo off
chcp 65001 >nul
title Nabda - Sync C:\nabda_app to OneDrive + D:\nabda_app
color 0B
setlocal

echo.
echo ==================================================
echo   Nabda - Synchronisation vers OneDrive + D:\
echo ==================================================
echo.

set "SOURCE=C:\nabda_app"
set "DEST_ONEDRIVE=%USERPROFILE%\OneDrive\nabda_app"
set "DEST_DRIVE_D=D:\nabda_app"

echo Source        : %SOURCE%
echo Destination 1 : %DEST_ONEDRIVE%   (OneDrive)
echo Destination 2 : %DEST_DRIVE_D%    (Disque D)
echo.

REM ---------- 1) OneDrive ----------
echo [1/2] Copie vers OneDrive ^(peut prendre 1-3 minutes^)...
echo.

if not exist "%DEST_ONEDRIVE%" mkdir "%DEST_ONEDRIVE%"

robocopy "%SOURCE%" "%DEST_ONEDRIVE%" /MIR /R:2 /W:1 /MT:8 /NFL /NDL /NP /XD ".dart_tool" "build" ".idea" ".gradle" "node_modules" ".vscode" "windows\flutter\ephemeral" "linux\flutter\ephemeral" "macos\Flutter\ephemeral" "ios\Flutter\ephemeral" /XF "*.log" ".DS_Store" ".flutter-plugins" ".flutter-plugins-dependencies" "firebase-debug.log"

if %errorlevel% GEQ 8 (
    echo.
    echo   ECHEC copie OneDrive - code %errorlevel%
    echo   Astuce: pausez OneDrive puis relancez.
) else (
    echo   OK - OneDrive synchronise
)
echo.

REM ---------- 2) D:\ ----------
echo [2/2] Copie vers D:\nabda_app ^(peut prendre 1-3 minutes^)...
echo.

if not exist "D:\" (
    echo   ATTENTION: Le disque D: n'existe pas sur cette machine.
    goto end
)

if not exist "%DEST_DRIVE_D%" mkdir "%DEST_DRIVE_D%"

robocopy "%SOURCE%" "%DEST_DRIVE_D%" /MIR /R:2 /W:1 /MT:8 /NFL /NDL /NP /XD ".dart_tool" "build" ".idea" ".gradle" "node_modules" ".vscode" "windows\flutter\ephemeral" "linux\flutter\ephemeral" "macos\Flutter\ephemeral" "ios\Flutter\ephemeral" /XF "*.log" ".DS_Store" ".flutter-plugins" ".flutter-plugins-dependencies" "firebase-debug.log"

if %errorlevel% GEQ 8 (
    echo   ECHEC copie D:\
) else (
    echo   OK - D:\ synchronise
)
echo.

:end
echo ==================================================
echo   Synchronisation terminee !
echo ==================================================
echo   Destinations :
echo    - %DEST_ONEDRIVE%
echo    - %DEST_DRIVE_D%
echo.
echo   Fichiers exclus : build/, .dart_tool/, node_modules/,
echo                    ephemeral/, logs, .DS_Store
echo ==================================================
echo.
pause
endlocal
