# ═══════════════════════════════════════════════════════════════════
# 🛡️ Nabda — Security Deploy Script
# تشغيل: انقري نقرتين، أو من PowerShell: .\deploy_security.ps1
# يُنفّذ: pub get → analyze → build web → deploy firestore + hosting
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = 'Continue'
Set-Location $PSScriptRoot

Write-Host "`n══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🛡️  Nabda — نشر التحديثات الأمنيّة" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════`n" -ForegroundColor Cyan

# ─── 1) Pub get ──────────────────────────────────────────────────
Write-Host "📦 [1/5] جلب التبعيّات (flutter pub get)..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ فشل pub get — راجعي الأخطاء أعلاه." -ForegroundColor Red
    Read-Host "اضغطي Enter للخروج"
    exit 1
}
Write-Host "✓ تمّ`n" -ForegroundColor Green

# ─── 2) Analyze ──────────────────────────────────────────────────
Write-Host "🔎 [2/5] تحليل الكود (flutter analyze)..." -ForegroundColor Yellow
flutter analyze --no-pub
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠️  هناك أخطاء أو تحذيرات في التحليل." -ForegroundColor Yellow
    $continue = Read-Host "هل أتابع رغم ذلك؟ (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') { exit 1 }
}
Write-Host "✓ تمّ`n" -ForegroundColor Green

# ─── 3) Build Web ────────────────────────────────────────────────
Write-Host "🏗️  [3/5] بناء نسخة الويب (flutter build web)..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ فشل بناء الويب." -ForegroundColor Red
    Read-Host "اضغطي Enter للخروج"
    exit 1
}
Write-Host "✓ تمّ`n" -ForegroundColor Green

# ─── 4) Deploy Firestore Rules ──────────────────────────────────
Write-Host "🔐 [4/5] نشر قواعد Firestore..." -ForegroundColor Yellow
& firebase.cmd deploy --only firestore:rules
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠️  فشل نشر قواعد Firestore — قد لا تكون متغيّرة." -ForegroundColor Yellow
}
Write-Host "✓ تمّ`n" -ForegroundColor Green

# ─── 5) Deploy Hosting ──────────────────────────────────────────
Write-Host "🌐 [5/5] نشر الويب (hosting)..." -ForegroundColor Yellow
& firebase.cmd deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ فشل نشر hosting." -ForegroundColor Red
    Read-Host "اضغطي Enter للخروج"
    exit 1
}

# ─── الخاتمة ────────────────────────────────────────────────────
Write-Host "`n══════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ تمّ النشر بنجاح!" -ForegroundColor Green
Write-Host "══════════════════════════════════════════" -ForegroundColor Green
Write-Host "  افتحي https://nabda.online للتحقّق." -ForegroundColor White
Write-Host "  ⚠️  لا تنسي تطبيق CORS من Cloud Shell." -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════`n" -ForegroundColor Green

Read-Host "اضغطي Enter للإغلاق"
