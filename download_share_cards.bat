@echo off
cd /d "%~dp0"
if not exist "assets\images\share_cards" mkdir "assets\images\share_cards"
set BASE=https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb

echo [1/5] week card ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260813_234246_3001c74f-0c26-4fbe-8c79-880b5fbdca25.png' -OutFile 'assets\images\share_cards\card_week.png'"

echo [2/5] fetus size card ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260813_234258_3472b15d-bbfd-4cf5-ab07-0f2f0550c581.png' -OutFile 'assets\images\share_cards\card_size.png'"

echo [3/5] countdown card ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260813_234310_54d71219-24bd-4e47-beae-7fee62546e56.png' -OutFile 'assets\images\share_cards\card_countdown.png'"

echo [4/5] achievement card ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260813_234323_82a493c8-5229-466f-828a-857992582ea6.png' -OutFile 'assets\images\share_cards\card_achievement.png'"

echo [5/5] progress card ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/hf_20260813_234336_9b93f1f4-ef3e-422d-aecd-0738e83cb7f0.png' -OutFile 'assets\images\share_cards\card_progress.png'"

echo.
echo Compressing ...
python -c "import glob,os; from PIL import Image; [ (lambda p: (lambda im: im.resize((900,int(900*im.size[1]/im.size[0])), Image.LANCZOS).convert('RGB').save(p,format='JPEG',quality=88,optimize=True))(Image.open(p)))(p) for p in glob.glob('assets/images/share_cards/*.png') ]; print('done')" 2>nul

echo.
dir /b "assets\images\share_cards"
pause
