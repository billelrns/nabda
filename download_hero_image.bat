@echo off
cd /d "%~dp0"
echo Downloading new home hero image ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260813_134749_e8f3188b-db39-467f-89bc-53b095090163.png' -OutFile 'assets\images\hero_home.png'"
if exist "assets\images\hero_home.png" (
  echo OK - saved to assets\images\hero_home.png
) else (
  echo FAILED - check your internet connection
)
echo.
echo Compressing it ...
python -c "from PIL import Image; im=Image.open('assets/images/hero_home.png').convert('RGB'); w,h=im.size; r=900.0/max(w,h); im=im.resize((int(w*r),int(h*r)), Image.LANCZOS) if max(w,h)>900 else im; im.save('assets/images/hero_home.png', format='JPEG', quality=85, optimize=True); print('compressed')" 2>nul
echo.
pause
