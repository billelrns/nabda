@echo off
xcopy "C:\Users\AMT mobile\OneDrive\nabda_app_backup\lib\main.dart" "C:\nabda_app\lib\" /Y
xcopy "C:\Users\AMT mobile\OneDrive\nabda_app_backup\lib\screens\health\medication_tracker_screen.dart" "C:\nabda_app\lib\screens\health\" /Y
xcopy "C:\Users\AMT mobile\OneDrive\nabda_app_backup\lib\models\medication_model.dart" "C:\nabda_app\lib\models\" /Y
xcopy "C:\Users\AMT mobile\OneDrive\nabda_app_backup\lib\services\health_tracking_service.dart" "C:\nabda_app\lib\services\" /Y
xcopy "C:\Users\AMT mobile\OneDrive\nabda_app_backup\lib\screens\admin\admin_panel_screen.dart" "C:\nabda_app\lib\screens\admin\" /Y
echo Done!
pause
