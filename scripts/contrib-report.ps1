# WarmPath Contributor Activity Report (PowerShell)
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "               WarmPath Contributor Activity Report               " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- 1. Commits by Author ---" -ForegroundColor Yellow
git shortlog -sn --all
Write-Host ""

Write-Host "--- 2. Lines Added and Removed by Author ---" -ForegroundColor Yellow
git log --numstat --pretty="%an" | ForEach-Object {
    if ($_ -match '^\d+\s+\d+') {
        $parts = $_ -split '\s+'
        [PSCustomObject]@{
            Added = [int]$parts[0]
            Removed = [int]$parts[1]
        }
    }
} | Measure-Object -Property Added, Removed -Sum | Format-Table
Write-Host ""

Write-Host "--- 3. Recent Commits on Current Branch ---" -ForegroundColor Yellow
git log -n 8 --oneline
Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Report complete." -ForegroundColor Cyan
