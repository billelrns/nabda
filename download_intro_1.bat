@echo off
cd /d "%~dp0"
if not exist "assets\images\intro" mkdir "assets\images\intro"
set BASE=https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb

echo Downloading onboarding screen 1 - option A ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260828_224923_0487e52e-6797-4393-96e3-80a03b9a2a31.png' -OutFile 'assets\images\intro\intro_welcome_A.png'"

echo Downloading onboarding screen 1 - option B ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260828_224923_321abccb-4aa9-4535-b551-d2e880ba2cb9.png' -OutFile 'assets\images\intro\intro_welcome_B.png'"

echo.
echo Saved to assets\images\intro\
echo Open the folder and compare intro_welcome_A.png and intro_welcome_B.png
echo.
start "" "assets\images\intro"
pause
