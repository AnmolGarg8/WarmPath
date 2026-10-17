# scripts/demo/db_snapshot.ps1
# Creates and restores pg_dump snapshots of the local demo database.
# Refuses to run against remote, staging, or production databases.

param (
    [Parameter(Position=0)]
    [ValidateSet("save", "backup", "restore", "load", "list")]
    [string]$Action = "save",

    [Parameter(Position=1)]
    [string]$SnapshotFile = "",

    [string]$ContainerName = "postgres",
    [string]$DbUser = "warmpath",
    [string]$DbName = "warmpath_db"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$SnapshotDir = Join-Path $RepoRoot "data\snapshots"
$BackendDir = Join-Path $RepoRoot "backend"

# --- SAFETY REFUSAL CHECK ---
# Check DATABASE_URL in backend/.env if it exists
$EnvFile = Join-Path $BackendDir ".env"
$DatabaseUrl = "postgresql://warmpath:secretpassword@localhost:5432/warmpath_db"

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match "^\s*DATABASE_URL\s*=\s*(.+)$") {
            $DatabaseUrl = $matches[1].Trim().Trim('"').Trim("'")
        }
    }
}

# Run safety validator via Python db_safety module
$SafetyScript = Join-Path $PSScriptRoot "db_safety.py"
$SafetyCheck = python -c "
import sys
from scripts.demo.db_safety import is_safe_local_database
safe, reason = is_safe_local_database('$DatabaseUrl')
if not safe:
    print(f'[SAFETY REFUSAL] {reason}', file=sys.stderr)
    sys.exit(1)
print(f'[SAFETY CHECK] {reason}')
"

if ($LASTEXITCODE -ne 0) {
    Write-Error "[SAFETY REFUSAL] Refusing to snapshot/restore: Target database does not match local demo criteria.`n$DatabaseUrl"
    exit 1
}

Write-Host "[SAFETY PASS] Verified target database is local demo container ($DbName)." -ForegroundColor Green

# Ensure snapshot directory exists
if (-not (Test-Path $SnapshotDir)) {
    New-Item -ItemType Directory -Path $SnapshotDir -Force | Out-Null
}

switch ($Action) {
    { $_ -in "save", "backup" } {
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        if (-not $SnapshotFile) {
            $SnapshotFile = Join-Path $SnapshotDir "warmpath_demo_$Timestamp.sql"
        } elseif (-not [System.IO.Path]::IsPathRooted($SnapshotFile)) {
            $SnapshotFile = Join-Path $SnapshotDir $SnapshotFile
        }

        Write-Host "[SNAPSHOT] Exporting pg_dump from container '$ContainerName' to '$SnapshotFile'..." -ForegroundColor Cyan

        # Execute pg_dump via docker compose
        Push-Location $BackendDir
        try {
            docker compose exec -T $ContainerName pg_dump -U $DbUser --clean --if-exists $DbName | Out-File -FilePath $SnapshotFile -Encoding utf8
        } finally {
            Pop-Location
        }

        if ((Test-Path $SnapshotFile) -and (Get-Item $SnapshotFile).Length -gt 0) {
            $SizeKb = [math]::Round((Get-Item $SnapshotFile).Length / 1KB, 1)
            Write-Host "[SNAPSHOT] SUCCESS: Database snapshot saved ($SizeKb KB): $SnapshotFile" -ForegroundColor Green
        } else {
            Write-Error "[SNAPSHOT] ERROR: Snapshot file is empty or was not created."
            exit 1
        }
    }

    { $_ -in "restore", "load" } {
        if (-not $SnapshotFile) {
            # Find latest snapshot in directory
            $Latest = Get-ChildItem -Path $SnapshotDir -Filter "*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if (-not $Latest) {
                Write-Error "[SNAPSHOT] No snapshots found in $SnapshotDir to restore."
                exit 1
            }
            $SnapshotFile = $Latest.FullName
        } elseif (-not [System.IO.Path]::IsPathRooted($SnapshotFile)) {
            $SnapshotFile = Join-Path $SnapshotDir $SnapshotFile
        }

        if (-not (Test-Path $SnapshotFile)) {
            Write-Error "[SNAPSHOT] Snapshot file not found: $SnapshotFile"
            exit 1
        }

        Write-Host "[SNAPSHOT] Restoring database '$DbName' from '$SnapshotFile'..." -ForegroundColor Yellow

        Push-Location $BackendDir
        try {
            Get-Content $SnapshotFile | docker compose exec -T $ContainerName psql -U $DbUser -d $DbName
        } finally {
            Pop-Location
        }

        Write-Host "[SNAPSHOT] SUCCESS: Database restored to known-good demo state from $SnapshotFile." -ForegroundColor Green
    }

    "list" {
        Write-Host "Available WarmPath Demo Snapshots in $SnapshotDir :" -ForegroundColor Cyan
        Get-ChildItem -Path $SnapshotDir -Filter "*.sql" | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    }
}
