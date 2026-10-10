# ============================================================
#  NABDA - media bridge
#
#  Claude generates images on Higgsfield (CloudFront). Claude's own
#  Linux workspace is firewalled off from CloudFront, so it cannot
#  pull them. Your machine can. This script is that bridge: it reads
#  marketing/video/media_manifest.json and downloads every file into
#  marketing/video/src/ where Claude CAN read it.
#
#  Run from the project root:
#      powershell -ExecutionPolicy Bypass -File tools\fetch_media.ps1
#
#  Re-run any time Claude says the manifest was updated. Already
#  downloaded files are skipped, so re-running is cheap and safe.
#
#  NOTE: pure ASCII on purpose. Windows PowerShell 5.1 reads .ps1 as
#  ANSI unless the file starts with a BOM, so non-ASCII text here
#  would be mangled and break parsing.
# ============================================================

$ErrorActionPreference = 'Stop'

$Root     = Split-Path -Parent $PSScriptRoot
$Manifest = Join-Path $Root 'marketing\video\media_manifest.json'
$DestDir  = Join-Path $Root 'marketing\video\src'

if (-not (Test-Path $Manifest)) {
    throw "Manifest not found: $Manifest"
}
New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

$m = Get-Content $Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
$base = $m.base
Write-Host ("Manifest dated {0} - {1} file(s)" -f $m.generated, $m.files.Count) -ForegroundColor Cyan
Write-Host ("Destination: {0}" -f $DestDir) -ForegroundColor DarkGray
Write-Host ''

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ok = 0; $skip = 0; $fail = 0
foreach ($f in $m.files) {
    $out = Join-Path $DestDir $f.name

    if ((Test-Path $out) -and ((Get-Item $out).Length -gt 1024)) {
        Write-Host ("  [skip] {0}" -f $f.name) -ForegroundColor DarkGray
        $skip++
        continue
    }

    # the manifest may hold a full URL or a name relative to 'base'
    $url = $f.url
    if ($url -notmatch '^https?://') { $url = $base + $url }

    try {
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 120
        $len = (Get-Item $out).Length
        if ($len -lt 1024) { throw "file too small ($len bytes)" }
        Write-Host ("  [ok]   {0,-22} {1,8:N0} bytes   {2}" -f $f.name, $len, $f.desc) -ForegroundColor Green
        $ok++
    }
    catch {
        Write-Host ("  [FAIL] {0} -- {1}" -f $f.name, $_.Exception.Message) -ForegroundColor Red
        Remove-Item $out -Force -ErrorAction SilentlyContinue
        $fail++
    }
}

Write-Host ''
Write-Host ("Downloaded {0} | skipped {1} | failed {2}" -f $ok, $skip, $fail) `
    -ForegroundColor $(if ($fail -gt 0) { 'Yellow' } else { 'Green' })

if ($fail -eq 0) {
    Write-Host ''
    Write-Host 'Done. Tell Claude the media is ready.' -ForegroundColor Yellow
}
else {
    Write-Host ''
    Write-Host 'Some files failed. Re-run the script; finished ones are skipped.' -ForegroundColor Yellow
}
