@echo off
chcp 65001 >nul
echo ============================================
echo   Nabda - Downloading all generated assets
echo ============================================
cd /d "%~dp0"

mkdir "assets\icons_3d" 2>nul
mkdir "assets\images\intro" 2>nul
mkdir "marketing_videos" 2>nul

echo.
echo [1/3] Downloading 21 icons into assets\icons_3d ...
curl -sL -o "assets\icons_3d\icon_community.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205536_551b7fd8-5c95-417c-80a4-6bc53d5635d2.png"
curl -sL -o "assets\icons_3d\icon_nav_baby.png"      "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_211148_2276829e-6dad-4fde-b80f-fc637673754f.png"
curl -sL -o "assets\icons_3d\icon_cycle.png"         "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205551_f1ce4a35-92d2-4e86-bef4-d1565b10292b.png"
curl -sL -o "assets\icons_3d\icon_weight.png"        "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205552_cafc78b2-4ea6-4103-99f2-2eb2a98aa79b.png"
curl -sL -o "assets\icons_3d\icon_pregnancy.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205557_9c51046c-f0bc-48f9-b137-83f20641f1db.png"
curl -sL -o "assets\icons_3d\icon_countdown.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205559_6dc1643f-26c8-4a43-abd8-f00ffdb67d85.png"
curl -sL -o "assets\icons_3d\icon_nutrition.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205600_382062b3-608f-4ef3-b5e9-ca9ac3fe1fad.png"
curl -sL -o "assets\icons_3d\icon_exercise.png"      "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205614_cf303c95-659c-4c76-9dc5-44006438f14f.png"
curl -sL -o "assets\icons_3d\icon_calendar.png"      "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205616_09f0a4a2-e001-44b0-a518-d80f4f920b4d.png"
curl -sL -o "assets\icons_3d\icon_hospital_bag.png"  "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205623_675bb423-cce0-4c69-ae57-35a4d9079658.png"
curl -sL -o "assets\icons_3d\icon_journal.png"       "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_210024_fb0cc4c8-aa42-4a5b-ba65-6a419b7eb837.png"
curl -sL -o "assets\icons_3d\icon_achievements.png"  "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205627_6242ea9b-a57d-4384-9b5f-143d865fa6a9.png"
curl -sL -o "assets\icons_3d\icon_baby_care.png"     "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205630_e87b7b4a-2e1a-4c23-ab53-f4c3d6d602c7.png"
curl -sL -o "assets\icons_3d\icon_habits.png"        "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205644_8b58b010-33f0-442e-9ae6-738310703076.png"
curl -sL -o "assets\icons_3d\icon_stages.png"        "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205646_89cb84f1-8c47-424a-a315-11485e7bdc6c.png"
curl -sL -o "assets\icons_3d\icon_baby_names.png"    "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205648_1c1d6648-d8c5-4f63-a199-e85d460a0e87.png"
curl -sL -o "assets\icons_3d\icon_share.png"         "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205654_acc3f0a6-f74e-4717-b1e5-10e31f71c910.png"
curl -sL -o "assets\icons_3d\icon_ai.png"            "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205656_e96162f9-e372-44d9-b16c-f1deaffe2ed6.png"
curl -sL -o "assets\icons_3d\icon_shop.png"          "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205715_e9cb7693-6a1d-4dd6-9a47-4a3f998bafaf.png"
curl -sL -o "assets\icons_3d\icon_notifications.png" "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205716_116944b6-4547-4a8e-9b14-6bd432175128.png"
curl -sL -o "assets\icons_3d\icon_privacy.png"       "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_205718_dc21f959-81fa-4086-b6f1-532c502dffa5.png"

echo [2/3] Downloading 3 intro photos into assets\images\intro ...
curl -sL -o "assets\images\intro\intro_welcome.png"  "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_210804_31b4fb1d-fb49-43c2-8bc7-9154046e19a0.png"
curl -sL -o "assets\images\intro\intro_journey.png"  "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_210818_a128eba2-3799-4fce-8d63-42ad0682439a.png"
curl -sL -o "assets\images\intro\intro_privacy.png"  "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_210831_7e89d05d-93d6-4113-916b-33a89e1f168c.png"

echo [3/3] Downloading 7 marketing videos into marketing_videos ...
curl -sL -o "marketing_videos\logo_anim_v1_square_5s.mp4"        "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_193214_736901c8-2a4a-40b8-a311-5203002044fd.mp4"
curl -sL -o "marketing_videos\logo_anim_v2_kawaii_square_5s.mp4" "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_193810_3c0cf028-126d-4b32-a954-a70e195718af.mp4"
curl -sL -o "marketing_videos\logo_ad_pro_vertical_10s_v1.mp4"   "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_194547_4d6b4750-7d46-40b8-b437-7a772fd92d1e.mp4"
curl -sL -o "marketing_videos\logo_ad_pro_vertical_10s_v2.mp4"   "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_195615_6b996ae9-b518-46c9-97d3-3d925bc48a2d.mp4"
curl -sL -o "marketing_videos\logo_ad_med_vertical_10s.mp4"      "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_201339_86f5c499-60ec-4b23-8856-73e3b57ef2de.mp4"
curl -sL -o "marketing_videos\logo_zoom_5hearts_square_10s.mp4"  "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260712_202532_ebc719c8-9e93-47ee-be6f-3d5e69948d4b.mp4"
curl -sL -o "marketing_videos\icon_baby_preview_anim.mp4"        "https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260715_211614_2782efd5-3ab9-4102-87d1-efc97978f706.mp4"

echo.
echo ============================================
echo   Done! Check assets\icons_3d (21 files),
echo   assets\images\intro (3), marketing_videos (7)
echo ============================================
pause
