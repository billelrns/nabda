@echo off
chcp 65001 >nul
echo ==================================================
echo   Nabda - Replacing icons with TRANSPARENT versions
echo ==================================================
cd /d "%~dp0"
mkdir "assets\icons_3d" 2>nul

curl -sL -o "assets\icons_3d\icon_cycle.png"         "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230112_d1f649a0-7cec-43ec-9a84-d391050d5f2c.png"
curl -sL -o "assets\icons_3d\icon_nav_baby.png"      "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230146_8e50fbd8-f4d2-441b-bc93-b6dcfd7368c2.png"
curl -sL -o "assets\icons_3d\icon_countdown.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230157_202aa766-1bfd-42af-90a9-c53828173b31.png"
curl -sL -o "assets\icons_3d\icon_nutrition.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230208_8c749f75-3622-47bd-a128-fbe803e1b1af.png"
curl -sL -o "assets\icons_3d\icon_calendar.png"      "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230211_6f37ec94-be1e-4139-82f6-49e2fe56ffdd.png"
curl -sL -o "assets\icons_3d\icon_achievements.png"  "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230216_7d11a6bf-a795-455d-9908-ec1045095839.png"
curl -sL -o "assets\icons_3d\icon_baby_care.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230231_df151739-9744-4995-9e39-06896e935c09.png"
curl -sL -o "assets\icons_3d\icon_baby_names.png"    "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230236_37b3e6c9-f280-41ee-8c20-785968e1e651.png"
curl -sL -o "assets\icons_3d\icon_privacy.png"       "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_230245_f88eb75e-770e-43ff-b3d1-f7417f10a8bf.png"
curl -sL -o "assets\icons_3d\icon_community.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044736_33bc602b-84ad-417a-9d3b-7fca7f40cbf3.png"
curl -sL -o "assets\icons_3d\icon_weight.png"        "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044738_578cf377-aedd-4cd8-af70-e5db4f4bb55c.png"
curl -sL -o "assets\icons_3d\icon_pregnancy.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044740_0138a9d6-2922-41ff-859c-81a5d169576e.png"
curl -sL -o "assets\icons_3d\icon_exercise.png"      "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044742_fbff8dfe-4fac-4424-9d53-04872ebfc3c8.png"
curl -sL -o "assets\icons_3d\icon_hospital_bag.png"  "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044754_fb6b1bef-5772-4767-8633-4e7fe859ca2a.png"
curl -sL -o "assets\icons_3d\icon_journal.png"       "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044755_65579f75-ba17-480c-82a0-fc5cd09af89e.png"
curl -sL -o "assets\icons_3d\icon_habits.png"        "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044757_590ed28c-6f2c-4ac4-b0b2-f95ff218505d.png"
curl -sL -o "assets\icons_3d\icon_stages.png"        "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044759_6c0fddd6-3ede-4e18-88f4-b408ef8ecb8f.png"
curl -sL -o "assets\icons_3d\icon_share.png"         "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044817_82cdf3f4-c364-4bd8-8b37-0228f4035f6e.png"
curl -sL -o "assets\icons_3d\icon_ai.png"            "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044819_4fd2aa42-1dde-4a93-8172-49ad5da31e6f.png"
curl -sL -o "assets\icons_3d\icon_shop.png"          "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044820_7fb8c8c0-b99e-4585-9df4-bb18d8483481.png"
curl -sL -o "assets\icons_3d\icon_notifications.png" "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260716_044822_d8de4f15-0de8-4376-92ff-64ffaf615eeb.png"

echo.
echo ==================================================
echo   Done! 21 transparent icons replaced.
echo ==================================================
pause
