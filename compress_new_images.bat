@echo off
chcp 65001 >nul
echo ================================================
echo   ضغط الصور الجديدة (d001-d030 + f001-f007 + a031)
echo ================================================
cd /d C:\nabda_app

python -c "import PIL" 2>nul
if errorlevel 1 (
  echo [!] Pillow غير مثبت — جاري التثبيت...
  pip install pillow
)

python compress_new_images.py
echo.
echo تم. اضغط أي زر للخروج.
pause >nul
