@echo off
cd /d C:\nabda_app

echo ================================================
echo   Nabda - compress images then run the app
echo ================================================
echo.

echo [1/4] Compressing new images ...
python compress_new_images.py
if errorlevel 1 echo   (skipped - install Pillow with: pip install pillow)
echo.

echo [2/4] flutter clean ...
call flutter clean >nul
echo.

echo [3/4] flutter pub get ...
call flutter pub get
echo.

echo [4/4] flutter run ...
call flutter run

pause
