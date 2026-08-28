@echo off
cd /d "%~dp0"
if not exist "assets\images\intro" mkdir "assets\images\intro"
set BASE=https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb

echo Downloading onboarding screen 3 - option A ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260828_225954_972786f9-8614-4760-a884-e21cd7721fa8.png' -OutFile 'assets\images\intro\intro_privacy_A.png'"

echo Downloading onboarding screen 3 - option B ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260828_225954_06320f7f-8990-4ff2-b9ac-b57881133c49.png' -OutFile 'assets\images\intro\intro_privacy_B.png'"

echo.
echo Saved to assets\images\intro\
echo Compare intro_privacy_A.png and intro_privacy_B.png
echo.
start "" "assets\images\intro"
pause
