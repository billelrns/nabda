@echo off
cd /d "%~dp0"
if not exist "assets\images\intro" mkdir "assets\images\intro"
set BASE=https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb

echo Downloading onboarding screen 2 - option A ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260828_225526_51896fa6-eb65-45c6-8333-8edc4912130f.png' -OutFile 'assets\images\intro\intro_journey_A.png'"

echo Downloading onboarding screen 2 - option B ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260828_225526_f2d8fa8c-15f3-457a-b361-a153b1c4eed7.png' -OutFile 'assets\images\intro\intro_journey_B.png'"

echo.
echo Saved to assets\images\intro\
echo Compare intro_journey_A.png and intro_journey_B.png
echo.
start "" "assets\images\intro"
pause
