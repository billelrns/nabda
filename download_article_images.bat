@echo off
chcp 65001 >nul
echo ====================================================
echo   Nabda - 39 article category images
echo ====================================================
cd /d "%~dp0"
mkdir "assets\images\articles" 2>nul

set B=https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb

curl -sL -o "assets\images\articles\cat_nutrition.png"          "%B%/hf_20260716_175129_e9d5d668-81ef-4209-b547-57b5d8a94709.png"
curl -sL -o "assets\images\articles\cat_exercise.png"           "%B%/hf_20260716_175142_bd957182-b0f7-4eda-8878-5d58499afb56.png"
curl -sL -o "assets\images\articles\cat_sleep_pregnancy.png"    "%B%/hf_20260716_175144_d36cbafa-62ec-4c27-8e54-07934c1b5b3d.png"
curl -sL -o "assets\images\articles\cat_nausea.png"             "%B%/hf_20260716_175158_8a497f48-0fe9-4627-9ed3-8e02d297378f.png"
curl -sL -o "assets\images\articles\cat_birth_prep.png"         "%B%/hf_20260716_175200_9340fc50-50ac-4411-af34-19a37b3b3495.png"
curl -sL -o "assets\images\articles\cat_breastfeeding.png"      "%B%/hf_20260716_175203_eface619-f0bc-4c7a-9c03-7bc1f6683652.png"
curl -sL -o "assets\images\articles\cat_bottle_feeding.png"     "%B%/hf_20260716_175216_b2cdcb2e-95d2-415a-aa97-5b1225909729.png"
curl -sL -o "assets\images\articles\cat_baby_sleep.png"         "%B%/hf_20260716_175218_fdacc09f-ae69-4fdc-9ac0-c4738f2e8caa.png"
curl -sL -o "assets\images\articles\cat_vaccination.png"        "%B%/hf_20260716_175220_589b19bc-62dc-411e-8044-0f01f3e17504.png"
curl -sL -o "assets\images\articles\cat_growth_0_6.png"         "%B%/hf_20260716_175235_2d01a3c2-b8e1-4614-8f54-ee2c42a0b637.png"
curl -sL -o "assets\images\articles\cat_growth_6_12.png"        "%B%/hf_20260716_175237_783b06a4-f536-49d6-99f6-e32975e2dd4a.png"
curl -sL -o "assets\images\articles\cat_toddler.png"            "%B%/hf_20260716_175238_3c50d3c3-8cf9-4e1d-86bb-57767cbf9566.png"
curl -sL -o "assets\images\articles\cat_weaning.png"            "%B%/hf_20260716_175254_59392c6b-c95e-4d16-9e05-ab539177d95e.png"
curl -sL -o "assets\images\articles\cat_first_foods.png"        "%B%/hf_20260716_175257_8f68aa0a-b696-40f9-8502-4e18120f76f3.png"
curl -sL -o "assets\images\articles\cat_home_safety.png"        "%B%/hf_20260716_175259_527e587b-7ba6-42fc-859b-ba3a2bf4ea9b.png"
curl -sL -o "assets\images\articles\cat_mental_health.png"      "%B%/hf_20260716_175313_8e9b8f1e-7498-4569-aaa2-58a8ff80e04f.png"
curl -sL -o "assets\images\articles\cat_postpartum_support.png" "%B%/hf_20260716_175315_b0b98c90-37b5-42b3-86eb-75a078ae66a4.png"
curl -sL -o "assets\images\articles\cat_cycle.png"              "%B%/hf_20260716_175317_b47b03da-882e-47a4-826c-c241d55c81fe.png"
curl -sL -o "assets\images\articles\cat_fertility.png"          "%B%/hf_20260716_175334_295e23c7-64b3-49ea-9663-76c761e58771.png"
curl -sL -o "assets\images\articles\cat_women_health.png"       "%B%/hf_20260716_175336_d7858e9b-1ac4-4195-a58e-494dfa6389a9.png"
curl -sL -o "assets\images\articles\cat_skincare.png"           "%B%/hf_20260716_175338_2b71a3b0-0543-48d7-a381-77f05e0058dd.png"
curl -sL -o "assets\images\articles\cat_fashion.png"            "%B%/hf_20260716_175352_332a8e18-0f9f-4ccb-9d51-48ffe3f027a8.png"
curl -sL -o "assets\images\articles\cat_teething.png"           "%B%/hf_20260716_175354_5e00dcfa-1b8f-4d11-8942-275463589cc4.png"
curl -sL -o "assets\images\articles\cat_baby_bath.png"          "%B%/hf_20260716_175355_bd083c24-e336-463a-a438-1aa96b517966.png"
curl -sL -o "assets\images\articles\cat_colic.png"              "%B%/hf_20260716_175410_33b7c5b3-f7e8-4214-8556-65dc8566ceb7.png"
curl -sL -o "assets\images\articles\cat_delivery_recovery.png"  "%B%/hf_20260716_175413_9f266ea6-22c4-43d6-bf91-1d43ea1e5c81.png"
curl -sL -o "assets\images\articles\cat_postpartum_fitness.png" "%B%/hf_20260716_175418_e72ec46a-15a1-4987-a0ae-e222fbe61c43.png"
curl -sL -o "assets\images\articles\cat_baby_names.png"         "%B%/hf_20260716_175433_2f50de3e-24cd-400e-87f7-1cd358b57173.png"
curl -sL -o "assets\images\articles\cat_family.png"             "%B%/hf_20260716_175436_1ab6bc21-2434-4fb2-b729-5aaf63298781.png"
curl -sL -o "assets\images\articles\cat_travel.png"             "%B%/hf_20260716_175437_c7bf5990-a179-4eb2-88ab-17f39076e0af.png"
curl -sL -o "assets\images\articles\cat_walking.png"            "%B%/hf_20260716_175451_e2a799a1-9610-46d9-8c4b-6d64707289f6.png"
curl -sL -o "assets\images\articles\cat_prenatal_checkup.png"   "%B%/hf_20260716_175454_814df4a6-c93c-4c1d-abb6-ce08dd9bdb1a.png"
curl -sL -o "assets\images\articles\cat_reading.png"            "%B%/hf_20260716_175456_ccf503be-e989-4cb5-abc3-fc2a1a34d6db.png"
curl -sL -o "assets\images\articles\cat_meal_prep.png"          "%B%/hf_20260716_175510_8cc8aef1-a14f-4f99-b9db-0a802186b619.png"
curl -sL -o "assets\images\articles\cat_newborn.png"            "%B%/hf_20260716_175514_a2ab3120-1044-41a5-95ee-70246a49726c.png"
curl -sL -o "assets\images\articles\cat_community.png"          "%B%/hf_20260716_175515_5c132867-a928-4e48-8ce9-13500ef381d6.png"
curl -sL -o "assets\images\articles\cat_growth_chart.png"       "%B%/hf_20260716_175529_90ff36a8-6e53-48d5-880f-09cad66204ff.png"
curl -sL -o "assets\images\articles\cat_spiritual.png"          "%B%/hf_20260716_175532_4dd93166-182a-4be8-a966-f5cbf6c21138.png"
curl -sL -o "assets\images\articles\cat_husband_support.png"    "%B%/hf_20260716_175535_08332efe-dad2-4f87-bdd6-f4b09e4f3aab.png"

echo.
echo ====================================================
echo   Done! 39 article images saved in assets\images\articles
echo ====================================================
pause
