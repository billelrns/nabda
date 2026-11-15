# ═══════════════════════════════════════════════════════════════════
#  بناء nabda.online: الموقع الثابت في الجذر + تطبيق Flutter Web تحت /app/
#
#  من PowerShell:  .\tool\build_site.ps1                (بناء كامل مع Flutter)
#                  .\tool\build_site.ps1 -SkipFlutter   (الموقع فقط — سريع، يحتفظ بـ /app السابق إن وُجد)
#  من cmd.exe:     powershell -ExecutionPolicy Bypass -File tool\build_site.ps1 -SkipFlutter
#
#  ثم للمعاينة:    firebase hosting:channel:deploy preview --expires 7d
#  وللإنتاج:       firebase deploy --only hosting
# ═══════════════════════════════════════════════════════════════════
param([switch]$SkipFlutter)
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$appBackup = 'build/_app_keep'
if ($SkipFlutter) {
  Write-Host '1/5  تخطّي Flutter (الموقع فقط) ...' -ForegroundColor Cyan
  if (Test-Path $appBackup) { Remove-Item $appBackup -Recurse -Force }
  if (Test-Path 'build/web/app') { Move-Item 'build/web/app' $appBackup }
  if (Test-Path 'build/web') { Remove-Item 'build/web' -Recurse -Force }
  New-Item 'build/web' -ItemType Directory -Force | Out-Null
  if (Test-Path $appBackup) { Move-Item $appBackup 'build/web/app' }
  else { Write-Host '     (لا توجد نسخة Flutter سابقة — الرابط /app/ لن يعمل في هذا البناء)' -ForegroundColor Yellow }
} else {
  Write-Host '1/5  بناء Flutter Web تحت /app/ ...' -ForegroundColor Cyan
  flutter build web --release --base-href /app/
  if ($LASTEXITCODE -ne 0) { throw 'فشل flutter build web' }

  Write-Host '2/5  نقل مخرجات Flutter إلى build/web/app ...' -ForegroundColor Cyan
  $tmp = 'build/_flutter_web'
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  Move-Item 'build/web' $tmp
  New-Item 'build/web' -ItemType Directory | Out-Null
  Move-Item $tmp 'build/web/app'
  # flutter build ينسخ كل web/ داخل التطبيق — نحذف ملفات الموقع الثابت المكرّرة من /app (توفير ~100MB)
  foreach ($d in @('data', 'img', 'js', 'css', 'vendor')) { if (Test-Path "build/web/app/$d") { Remove-Item "build/web/app/$d" -Recurse -Force } }
  $sitePages = @('home', 'pregnancy', 'baby', 'cycle', 'fertility', 'community', 'shop', 'product', 'cart', 'checkout', 'account', 'login', 'article', 'articles', 'admin', 'fiqh', 'qadaa', '404')
  foreach ($pg in $sitePages) { if (Test-Path "build/web/app/$pg.html") { Remove-Item "build/web/app/$pg.html" -Force } }
  Get-ChildItem 'build/web/app' -Filter 'sitemap*.xml' | Remove-Item -Force
}

Write-Host '3/5  نسخ صفحات الموقع الثابت إلى الجذر ...' -ForegroundColor Cyan
# ملفات Flutter الخاصة تبقى تحت /app فقط
$flutterOnly = @('index.html', 'flutter_bootstrap.js', 'manifest.json', 'flutter_service_worker.js', 'main.dart.js', 'version.json')
Get-ChildItem 'web' -Force | Where-Object { $flutterOnly -notcontains $_.Name } | ForEach-Object {
  Copy-Item $_.FullName -Destination 'build/web' -Recurse -Force
}
# الصفحة الرئيسية للموقع = home.html
Copy-Item 'web/home.html' 'build/web/index.html' -Force

Write-Host '4/5  توليد خرائط الموقع ...' -ForegroundColor Cyan
try { python tool/gen_sitemap.py } catch { Write-Host '     (python غير متوفّر — نستعمل خرائط الموقع الموجودة)' -ForegroundColor Yellow }
Copy-Item 'web/sitemap*.xml' 'build/web/' -Force

Write-Host '5/5  فحص سريع ...' -ForegroundColor Cyan
foreach ($f in @('index.html', 'pregnancy.html', 'shop.html', 'product.html', 'article.html', 'admin.html', 'data/articles/meta.json')) {
  if (-not (Test-Path "build/web/$f")) { throw "ملف ناقص: $f" }
}
$size = (Get-ChildItem build/web -Recurse | Measure-Object Length -Sum).Sum / 1MB
Write-Host ("جاهز — الحجم {0:N0} MB" -f $size) -ForegroundColor Green
Write-Host 'للمعاينة:  firebase hosting:channel:deploy preview --expires 7d' -ForegroundColor Yellow
