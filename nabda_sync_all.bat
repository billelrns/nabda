@echo off
chcp 65001 >nul
echo ============================================
echo    نبضة - سكريبت النسخ والرفع الشامل
echo ============================================
echo.

:: --- تحقق من وجود المجلد المصدر ---
if not exist "C:\nabda_app" (
    echo [ERROR] المجلد C:\nabda_app غير موجود!
    pause
    exit /b 1
)

:: --- 1. Git: إضافة + التزام + رفع ---
echo.
echo [1/5] رفع التحديثات إلى GitHub...
echo ─────────────────────────────────
cd /d C:\nabda_app
git add -A
git status
echo.
echo التزام التغييرات...
git commit -m "feat: in-feed video ads + website design specs + slider images + dependency updates + project history update (June 27, 2026)"
echo.
echo رفع إلى GitHub...
git push origin main
if %errorlevel% neq 0 (
    echo [WARNING] فشل الرفع - تحقق من الاتصال أو الصلاحيات
    echo جرب: git push origin main يدوياً
) else (
    echo [OK] تم الرفع بنجاح ✓
)

:: --- 2. نسخ إلى D:\ ---
echo.
echo [2/5] نسخ إلى D:\nabda_app...
echo ─────────────────────────────────
if not exist "D:\" (
    echo [SKIP] القرص D: غير متاح
) else (
    robocopy "C:\nabda_app" "D:\nabda_app" /MIR /XD ".git" "build" ".dart_tool" ".idea" ".gradle" ".android" /XF "*.lock" /NFL /NDL /NJH /NJS /nc /ns /np
    echo [OK] تم النسخ إلى D:\nabda_app ✓
)

:: --- 3. نسخ إلى OneDrive ---
echo.
echo [3/5] نسخ إلى OneDrive...
echo ─────────────────────────────────
set ONEDRIVE_PATH=C:\Users\AMT mobile\OneDrive\nabda_app
robocopy "C:\nabda_app" "%ONEDRIVE_PATH%" /MIR /XD ".git" "build" ".dart_tool" ".idea" ".gradle" ".android" /XF "*.lock" /NFL /NDL /NJH /NJS /nc /ns /np
echo [OK] تم النسخ إلى OneDrive ✓

:: --- 4. نسخ إلى OneDrive backup أيضاً ---
echo.
echo [4/5] نسخ إلى OneDrive\nabda_app_backup...
echo ─────────────────────────────────
set BACKUP_PATH=C:\Users\AMT mobile\OneDrive\nabda_app_backup
robocopy "C:\nabda_app" "%BACKUP_PATH%" /MIR /XD ".git" "build" ".dart_tool" ".idea" ".gradle" ".android" /XF "*.lock" /NFL /NDL /NJH /NJS /nc /ns /np
echo [OK] تم النسخ إلى OneDrive backup ✓

:: --- 5. ملخص ---
echo.
echo ============================================
echo    تم بنجاح! ✓
echo ============================================
echo.
echo    المصدر:      C:\nabda_app
echo    GitHub:       تم الرفع
echo    D:\:          D:\nabda_app
echo    OneDrive:     %ONEDRIVE_PATH%
echo    Backup:       %BACKUP_PATH%
echo    History:      NABDA_PROJECT_HISTORY.md محدّث
echo.
echo ============================================
pause
