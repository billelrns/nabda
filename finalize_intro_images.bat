@echo off
cd /d "%~dp0"
cd assets\images\intro

echo Backing up old images ...
if exist intro_welcome.png ren intro_welcome.png intro_welcome_OLD.png
if exist intro_journey.png ren intro_journey.png intro_journey_OLD.png
if exist intro_privacy.png ren intro_privacy.png intro_privacy_OLD.png

echo Applying selected options (1=B, 2=B, 3=A) ...
copy /Y intro_welcome_B.png intro_welcome.png >nul
copy /Y intro_journey_B.png intro_journey.png >nul
copy /Y intro_privacy_A.png intro_privacy.png >nul

cd /d "%~dp0"
echo.
echo Compressing to 1080px wide ...
python -c "import glob; from PIL import Image; [(lambda p: (lambda im: im.convert('RGB').resize((1080,int(1080*im.size[1]/im.size[0])), Image.LANCZOS).save(p, format='JPEG', quality=88, optimize=True))(Image.open(p)))(p) for p in ['assets/images/intro/intro_welcome.png','assets/images/intro/intro_journey.png','assets/images/intro/intro_privacy.png']]; print('compressed 3 images')"

echo.
echo Cleaning up option files ...
del /Q "assets\images\intro\intro_welcome_A.png" 2>nul
del /Q "assets\images\intro\intro_welcome_B.png" 2>nul
del /Q "assets\images\intro\intro_journey_A.png" 2>nul
del /Q "assets\images\intro\intro_journey_B.png" 2>nul
del /Q "assets\images\intro\intro_privacy_A.png" 2>nul
del /Q "assets\images\intro\intro_privacy_B.png" 2>nul

echo.
dir /b "assets\images\intro"
echo.
echo Done. Old images kept as *_OLD.png in case you want them back.
pause
