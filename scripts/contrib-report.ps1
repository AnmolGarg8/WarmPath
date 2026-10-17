# WarmPath Contributor Activity Report (PowerShell)
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "               WarmPath Contributor Activity Report               " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- 1. Commits by Author ---" -ForegroundColor Yellow
git shortlog -sn --all
Write-Host ""

Write-Host "--- 2. Recent Commits on main ---" -ForegroundColor Yellow
git log -n 10 --oneline
Write-Host ""

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Report complete." -ForegroundColor Cyan
