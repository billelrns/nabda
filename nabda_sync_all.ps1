# PowerShell script for Nabda sync all (ASCII only to prevent encoding/parser bugs in Windows PowerShell)
Write-Host "============================================"
Write-Host "   Nabda - Sync and Backup Script"
Write-Host "============================================"
Write-Host ""

if (-not (Test-Path "C:\nabda_app")) {
    Write-Host "[ERROR] C:\nabda_app does not exist!"
    Pause
    Exit
}

cd C:\nabda_app

# 1. Git Push
Write-Host ""
Write-Host "[1/5] Pushing updates to GitHub..."
git add -A
git status
git commit -m "feat: child care articles + birth clubs and cohort private chats"
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Git push failed. Try running it manually."
} else {
    Write-Host "[OK] Git push succeeded."
}

# 2. Copy to D:\
Write-Host ""
Write-Host "[2/5] Copying to D:\nabda_app..."
if (-not (Test-Path "D:")) {
    Write-Host "[SKIP] Drive D: not available."
} else {
    robocopy "C:\nabda_app" "D:\nabda_app" /MIR /XD ".git" "build" ".dart_tool" ".idea" ".gradle" ".android" /XF "*.lock" /NFL /NDL /NJH /NJS /nc /ns /np
    Write-Host "[OK] Copy to D:\ completed."
}

# 3. Copy to OneDrive
Write-Host ""
Write-Host "[3/5] Copying to OneDrive..."
$ONEDRIVE_PATH = "C:\Users\AMT mobile\OneDrive\nabda_app"
robocopy "C:\nabda_app" $ONEDRIVE_PATH /MIR /XD ".git" "build" ".dart_tool" ".idea" ".gradle" ".android" /XF "*.lock" /NFL /NDL /NJH /NJS /nc /ns /np
Write-Host "[OK] Copy to OneDrive completed."

# 4. Copy to OneDrive Backup
Write-Host ""
Write-Host "[4/5] Copying to OneDrive backup..."
$BACKUP_PATH = "C:\Users\AMT mobile\OneDrive\nabda_app_backup"
robocopy "C:\nabda_app" $BACKUP_PATH /MIR /XD ".git" "build" ".dart_tool" ".idea" ".gradle" ".android" /XF "*.lock" /NFL /NDL /NJH /NJS /nc /ns /np
Write-Host "[OK] Copy to OneDrive backup completed."

# 5. Summary
Write-Host ""
Write-Host "============================================"
Write-Host "   Done!"
Write-Host "============================================"
Write-Host "Source: C:\nabda_app"
Write-Host "GitHub: Pushed"
Write-Host "D:\: D:\nabda_app"
Write-Host "OneDrive: $ONEDRIVE_PATH"
Write-Host "Backup: $BACKUP_PATH"
Write-Host "============================================"
Write-Host "Press any key to continue..."
$null = [Console]::ReadKey($true)
