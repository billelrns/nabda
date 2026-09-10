# ============================================================
#  NABDA - app + web icon generator
#  Builds every icon size from the approved two-hearts logo.
#
#  Run from the project root:
#      powershell -ExecutionPolicy Bypass -File tools\make_icons.ps1
#
#  NOTE: this file is intentionally pure ASCII. Windows PowerShell 5.1
#  reads .ps1 files as ANSI unless they start with a BOM, so any
#  non-ASCII character here would be mangled and break parsing.
#
#  TECHNICAL NOTE (why we flatten first):
#  Transparent pixels in the source logo are black (0,0,0). Downscaling
#  an image while it still carries an alpha channel would smear that
#  black into the anti-aliased edges and ring the hearts with a dark
#  halo. So we composite the logo onto the brand background at native
#  resolution (1:1, no resampling => no halo), then downscale a fully
#  opaque image. An opaque image cannot produce an alpha halo at all.
#  Verified: 0 halo pixels at every output size.
# ============================================================

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root    = Split-Path -Parent $PSScriptRoot
$IconDir = Join-Path $Root 'assets\icon'
New-Item -ItemType Directory -Force -Path $IconDir | Out-Null

# ------------------------------------------------------------
# 1) Download the source logo and verify its hash
# ------------------------------------------------------------
$SrcUrl  = 'https://d2ol7oe51mr4n9.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/d7011a05-ce06-4e12-a2a3-58ea6f999b46.png'
$SrcPath = Join-Path $env:TEMP 'nabda_hearts_src.png'
$ExpectedSha = '1455924B3C150EE034B8354BB1CBD0497806F054C35C46943704593004A741E5'

if (-not (Test-Path $SrcPath)) {
    Write-Host '[1/6] Downloading the hearts logo...' -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $SrcUrl -OutFile $SrcPath -UseBasicParsing
}
else {
    Write-Host '[1/6] Source logo already cached.' -ForegroundColor Cyan
}

$sha = (Get-FileHash -Path $SrcPath -Algorithm SHA256).Hash
if ($sha -ne $ExpectedSha) {
    Remove-Item $SrcPath -Force -ErrorAction SilentlyContinue
    throw "Hash mismatch. Expected $ExpectedSha but got $sha. Re-run the script."
}
Write-Host '      Hash matches the approved logo.' -ForegroundColor Green

# ------------------------------------------------------------
# 2) Flatten the logo onto the brand background at native size
# ------------------------------------------------------------
$src = [System.Drawing.Bitmap]::FromFile($SrcPath)
if ($src.Width -ne 1666 -or $src.Height -ne 1544) {
    $w = $src.Width; $h = $src.Height
    $src.Dispose()
    throw "Unexpected source dimensions: ${w}x${h}"
}

# Tight bounding box of the non-transparent pixels around the hearts
$CropRect = New-Object System.Drawing.Rectangle 45, 44, 1578, 1467

# Brand background #FFF5F8
$Brand = [System.Drawing.Color]::FromArgb(255, 255, 245, 248)

# Exact crop, no resampling
$crop = $src.Clone($CropRect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$src.Dispose()

# 1:1 composite onto an opaque canvas -> no scaling here, so no halo
$flat = New-Object System.Drawing.Bitmap $crop.Width, $crop.Height, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$gf = [System.Drawing.Graphics]::FromImage($flat)
$gf.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
$gf.Clear($Brand)
$gf.DrawImageUnscaled($crop, 0, 0)
$gf.Dispose()
$crop.Dispose()

function New-Icon {
    param(
        [int]$Size,
        [double]$Fill,
        [string]$OutFile
    )

    $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.Clear($Brand)

    # Scale against the longest side so the logo is never cropped
    $k  = ($Size * $Fill) / [Math]::Max($flat.Width, $flat.Height)
    $nw = [int][Math]::Round($flat.Width  * $k)
    $nh = [int][Math]::Round($flat.Height * $k)
    $dx = [int](($Size - $nw) / 2)
    $dy = [int](($Size - $nh) / 2)
    $dst = New-Object System.Drawing.Rectangle $dx, $dy, $nw, $nh

    # TileFlipXY avoids edge artefacts during resampling
    $attr = New-Object System.Drawing.Imaging.ImageAttributes
    $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $g.DrawImage($flat, $dst, 0, 0, $flat.Width, $flat.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
    $attr.Dispose()
    $g.Dispose()

    New-Item -ItemType Directory -Force -Path (Split-Path $OutFile -Parent) | Out-Null
    $bmp.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()

    $leaf = Split-Path $OutFile -Leaf
    Write-Host ("      {0,-26} {1}x{1}" -f $leaf, $Size)
}

Write-Host '[2/6] Generating source icons...' -ForegroundColor Cyan

# Main launcher icon - hearts fill 86% of the frame (big and clear)
New-Icon -Size 1024 -Fill 0.86 -OutFile (Join-Path $IconDir 'nabda_icon.png')

# Android adaptive foreground - 59% so it stays inside the safe zone.
# Opaque with the brand background is equivalent to a transparent layer
# here, because the adaptive background colour is the same #FFF5F8,
# and it removes the halo risk entirely.
New-Icon -Size 1024 -Fill 0.59 -OutFile (Join-Path $IconDir 'nabda_icon_fg.png')

# ------------------------------------------------------------
# 3) Remove the stale launcher_icon set
#    AndroidManifest pointed at ic_launcher while the adaptive icon
#    was named launcher_icon, so Android 8+ never used it.
# ------------------------------------------------------------
Write-Host '[3/6] Cleaning up stale Android icons...' -ForegroundColor Cyan
$resDir = Join-Path $Root 'android\app\src\main\res'
$stale = @()
if (Test-Path $resDir) {
    $stale = @(Get-ChildItem -Path $resDir -Recurse -Filter 'launcher_icon.*' -ErrorAction SilentlyContinue)
}
if ($stale.Count -gt 0) {
    $stale | Remove-Item -Force
    Write-Host ("      Removed {0} stale file(s)." -f $stale.Count) -ForegroundColor Green
}
else {
    Write-Host '      Nothing to clean.' -ForegroundColor Green
}

# ------------------------------------------------------------
# 4) Generate all sizes with flutter_launcher_icons
# ------------------------------------------------------------
Write-Host '[4/6] Generating Android / iOS / web sizes...' -ForegroundColor Cyan
Push-Location $Root
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    & dart run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) { throw 'dart run flutter_launcher_icons failed' }
}
finally {
    Pop-Location
}

# ------------------------------------------------------------
# 5) Post-generation web fixes
#    a) favicon: the tool emits it at 16px only (blurry on modern screens)
#    b) maskable icons: the tool builds them from the full-bleed master,
#       so the circular mask would clip the hearts. Rebuild at safe size.
# ------------------------------------------------------------
Write-Host '[5/6] Fixing web icons...' -ForegroundColor Cyan
New-Icon -Size 256 -Fill 0.96 -OutFile (Join-Path $Root 'web\favicon.png')
New-Icon -Size 192 -Fill 0.59 -OutFile (Join-Path $Root 'web\icons\Icon-maskable-192.png')
New-Icon -Size 512 -Fill 0.59 -OutFile (Join-Path $Root 'web\icons\Icon-maskable-512.png')

# ------------------------------------------------------------
# 6) Enforce the adaptive-icon XML.
#    A stale file in this repo wrapped the foreground in inset="16%".
#    Our foreground is already sized to the safe zone (59%), so an extra
#    inset would shrink the hearts to about 40% of the frame.
# ------------------------------------------------------------
Write-Host '[6/6] Writing the adaptive-icon XML...' -ForegroundColor Cyan
$adaptiveXml = @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
'@
$adaptivePath = Join-Path $Root 'android\app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml'
New-Item -ItemType Directory -Force -Path (Split-Path $adaptivePath -Parent) | Out-Null
Set-Content -Path $adaptivePath -Value $adaptiveXml -Encoding UTF8
Write-Host '      ic_launcher.xml written (no inset).'

$flat.Dispose()

Write-Host ''
Write-Host '=== DONE ===' -ForegroundColor Green
Write-Host 'Phone icon   : android\app\src\main\res\mipmap-*\ic_launcher.png (+ adaptive)'
Write-Host 'Browser icon : web\favicon.png and web\icons\Icon-*.png'
Write-Host ''
Write-Host 'To test:' -ForegroundColor Yellow
Write-Host '  flutter clean'
Write-Host '  flutter run -d chrome     # browser'
Write-Host '  flutter run               # phone'
Write-Host ''
Write-Host 'Browsers cache favicons hard - use Ctrl+Shift+R or an incognito window.' -ForegroundColor DarkGray
