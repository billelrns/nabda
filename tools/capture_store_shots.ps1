# ============================================================
#  NABDA - capture real app screenshots for the store listing
#
#  Google Play requires store screenshots to show the ACTUAL app.
#  So the picture inside the phone frame must be a real capture,
#  not an AI image. This script pulls native-resolution captures
#  from a connected phone or emulator straight into
#  marketing/store/raw/, which is what build_store_shots.py reads.
#
#  Run from the project root:
#      powershell -ExecutionPolicy Bypass -File tools\capture_store_shots.ps1
#
#  For each of the 8 shots it tells you which screen to open,
#  waits for Enter, then captures. Press S to skip a shot.
#
#  NOTE: pure ASCII on purpose. Windows PowerShell 5.1 reads .ps1
#  as ANSI unless the file starts with a BOM, so non-ASCII text
#  here would be mangled and break parsing.
# ============================================================

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Raw  = Join-Path $Root 'marketing\store\raw'
New-Item -ItemType Directory -Force -Path $Raw | Out-Null

# ---- locate adb ------------------------------------------------
$adb = $null
$cand = @(
    'adb',
    (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'),
    (Join-Path $env:USERPROFILE  'AppData\Local\Android\Sdk\platform-tools\adb.exe'),
    'C:\Android\Sdk\platform-tools\adb.exe'
)
foreach ($c in $cand) {
    try { & $c version *> $null; if ($LASTEXITCODE -eq 0) { $adb = $c; break } } catch { }
}
if (-not $adb) {
    Write-Host 'adb not found.' -ForegroundColor Red
    Write-Host 'Install Android platform-tools, or open Android Studio once so the SDK is set up.'
    Write-Host 'Alternative: take the screenshots on the phone (Power+VolDown), copy the PNG files'
    Write-Host ("into {0} and rename them 01_week.png .. 08_ai.png" -f $Raw)
    exit 1
}
Write-Host ("adb: {0}" -f $adb) -ForegroundColor DarkGray

$devs = (& $adb devices) | Select-String -Pattern "\tdevice$"
if (-not $devs) {
    Write-Host 'No device connected.' -ForegroundColor Red
    Write-Host 'Plug in the phone with USB debugging on, or start an emulator, then re-run.'
    exit 1
}
Write-Host ("device(s): {0}" -f $devs.Count) -ForegroundColor Green
Write-Host ''

# ---- the 8 shots ----------------------------------------------
$shots = @(
    @{ id = '01_week';         screen = 'Home / pregnancy tab - the week card with fetus size and due date' },
    @{ id = '02_encyclopedia'; screen = 'Nabda medical encyclopedia - the article list' },
    @{ id = '03_names';        screen = 'Baby names - the girls list, Algeria filter on' },
    @{ id = '04_cycle';        screen = 'Cycle tab - calendar / ovulation' },
    @{ id = '05_baby';         screen = 'Baby tab - month-by-month care' },
    @{ id = '06_tools';        screen = 'Kick counter OR hospital bag OR pregnancy journal' },
    @{ id = '07_community';    screen = 'Community - posts feed with usernames' },
    @{ id = '08_ai';           screen = 'AI chat - a question with an answer on screen' }
)

$ok = 0; $skip = 0
foreach ($s in $shots) {
    Write-Host ''
    Write-Host ("[{0}]" -f $s.id) -ForegroundColor Cyan
    Write-Host ("  open: {0}" -f $s.screen) -ForegroundColor Yellow
    $a = Read-Host '  Enter = capture, S = skip'
    if ($a -match '^[sS]') { $skip++; Write-Host '  skipped' -ForegroundColor DarkGray; continue }

    $out = Join-Path $Raw ($s.id + '.png')
    # exec-out keeps the PNG binary clean (no CRLF translation)
    & $adb exec-out screencap -p | Set-Content -Path $out -Encoding Byte
    if (-not (Test-Path $out)) { Write-Host '  FAILED' -ForegroundColor Red; continue }

    $len = (Get-Item $out).Length
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($out)
    $w = $img.Width; $h = $img.Height
    $img.Dispose()

    $col = 'Green'
    $note = ''
    if ($w -lt 1080) { $col = 'Yellow'; $note = '  <-- under 1080px wide, use a higher-res device if you can' }
    Write-Host ("  saved {0}x{1}  {2:N0} bytes{3}" -f $w, $h, $len, $note) -ForegroundColor $col
    $ok++
}

Write-Host ''
Write-Host ("captured {0} | skipped {1}" -f $ok, $skip) -ForegroundColor Green
Write-Host ''
Write-Host 'Next: tell Claude the captures are ready, or build them yourself with:' -ForegroundColor Yellow
Write-Host '   python marketing\store\build_store_shots.py'
