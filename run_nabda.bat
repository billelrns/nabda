@echo off
cd /d C:\nabda_app

echo ================================================
echo   Nabda - low memory safe build
echo ================================================
echo.

echo [1/6] Freeing memory (stopping gradle + java + dart) ...
call android\gradlew.bat --stop >nul 2>&1
taskkill /F /IM java.exe >nul 2>&1
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM kotlin-daemon.exe >nul 2>&1
echo     done.
echo.

echo [2/6] Free RAM right now:
powershell -NoProfile -Command "$os=Get-CimInstance Win32_OperatingSystem; '{0:N0} MB free of {1:N0} MB' -f ($os.FreePhysicalMemory/1KB),($os.TotalVisibleMemorySize/1KB)"
echo     ^(if free RAM is under 1500 MB, close Chrome before continuing^)
echo.
pause

echo [3/6] Compressing new images ...
python compress_new_images.py
if errorlevel 1 echo   (skipped - install Pillow with: pip install pillow)
echo.

echo [4/6] flutter clean ...
call flutter clean >nul
echo.

echo [5/6] flutter pub get ...
call flutter pub get
echo.

echo [6/6] flutter run ...
call flutter run

pause
