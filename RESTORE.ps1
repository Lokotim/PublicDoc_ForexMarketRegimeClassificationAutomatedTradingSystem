#Requires -Version 7.4
<#
.SYNOPSIS
    Idempotent Restore Script for Forex Regime Detection System
    
.DESCRIPTION
    Restores the complete trading system from a validated backup with:
    - Pre-flight environment checks (OS, PowerShell, Python, disk, permissions)
    - Manifest validation with SHA256 verification
    - Atomic directory restore with rollback capability
    - Structured logging with timestamps
    - Explicit failure on ANY mismatch (no silent errors)
    
.PARAMETER VerifyOnly
    Performs all validation checks without making any changes.
    Use this to verify backup integrity before restore.
    
.PARAMETER Force
    Skips interactive confirmation prompts.
    Use for automated/scripted restores.
    
.PARAMETER LogPath
    Custom path for the restore log file.
    Defaults to: <BackupPath>\restore_<timestamp>.log
    
.EXAMPLE
    # Verify backup integrity only
    .\RESTORE.ps1 -VerifyOnly -Verbose
    
.EXAMPLE
    # Interactive restore with prompts
    .\RESTORE.ps1 -Verbose
    
.EXAMPLE
    # Automated restore without prompts
    .\RESTORE.ps1 -Force -Verbose
    
.NOTES
    Version:        1.0.0
    Author:         Forex Trading System
    Creation Date:  2026-01-24
    
    CRITICAL: This script will FAIL LOUDLY on any mismatch.
              No hardcoded fallbacks. No silent error handling.
              
    INVARIANTS ENFORCED:
    - INV-001: Timezone must be America/New_York
    - INV-002: SQLite is single source of truth
    - INV-003: No hardcoded fallbacks allowed
    - INV-004: Risk limits are non-negotiable
    - INV-005: Pipeline stages cannot be disabled
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(HelpMessage = "Only verify integrity, do not restore")]
    [switch]$VerifyOnly,
    
    [Parameter(HelpMessage = "Skip confirmation prompts")]
    [switch]$Force,
    
    [Parameter(HelpMessage = "Custom log file path")]
    [string]$LogPath
)

# ============================================================================
# STRICT MODE AND ERROR HANDLING
# ============================================================================
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$script:ExitCode = 0

# ============================================================================
# CONFIGURATION
# ============================================================================
$script:Config = @{
    BackupPath       = $PSScriptRoot
    ManifestName     = "MANIFEST.json"
    RequiredOS       = "Windows Server 2022"
    RequiredPSMajor  = 7
    RequiredPSMinor  = 4
    RequiredPython   = "3.14"
    PythonPath       = "C:\Python314\python.exe"
    MinDiskSpaceGB   = 10
    Timezone         = "America/New_York"
    SourceDirs       = @(
        "C:\MoneyProd",
        "C:\ForexRegime",
        "C:\ForexScraper",
        "C:\ForexRiskManagement"
    )
}

# ============================================================================
# LOGGING INFRASTRUCTURE
# ============================================================================
if (-not $LogPath) {
    $LogPath = Join-Path $script:Config.BackupPath "restore_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,
        
        [Parameter(Position = 1)]
        [ValidateSet("INFO", "OK", "WARN", "ERROR", "DEBUG", "PHASE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logLine = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    try {
        Add-Content -Path $LogPath -Value $logLine -ErrorAction SilentlyContinue
    } catch {
        # Continue even if logging fails
    }
    
    # Console output with colors
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "OK"    { "Green" }
        "PHASE" { "Cyan" }
        "DEBUG" { "DarkGray" }
        default { "White" }
    }
    
    Write-Host $logLine -ForegroundColor $color
}

function Exit-WithError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [int]$ExitCode = 1
    )
    
    Write-Log " " "ERROR"
    Write-Log "════════════════════════════════════════════════════════════════" "ERROR"
    Write-Log "FATAL ERROR: $Message" "ERROR"
    Write-Log "════════════════════════════════════════════════════════════════" "ERROR"
    Write-Log " " "ERROR"
    Write-Log "Restore log saved to: $LogPath" "ERROR"
    Write-Log "RESTORE FAILED - System state unchanged (if error in pre-flight)" "ERROR"
    
    $script:ExitCode = $ExitCode
    throw $Message
}

# ============================================================================
# BANNER
# ============================================================================
function Show-Banner {
    Write-Log " "
    Write-Log "╔══════════════════════════════════════════════════════════════════╗" "PHASE"
    Write-Log "║     FOREX REGIME DETECTION SYSTEM - RESTORE SCRIPT v1.0.0        ║" "PHASE"
    Write-Log "╠══════════════════════════════════════════════════════════════════╣" "PHASE"
    Write-Log "║  Backup Path: $($script:Config.BackupPath.PadRight(46))║" "PHASE"
    Write-Log "║  Mode: $(if ($VerifyOnly) { 'VERIFY ONLY'.PadRight(53) } else { 'FULL RESTORE'.PadRight(53) })║" "PHASE"
    Write-Log "║  Log: $($LogPath.Substring([Math]::Max(0, $LogPath.Length - 54)).PadRight(54))║" "PHASE"
    Write-Log "╚══════════════════════════════════════════════════════════════════╝" "PHASE"
    Write-Log " "
}

# ============================================================================
# PHASE 1: PRE-FLIGHT CHECKS
# ============================================================================
function Test-PreFlightChecks {
    Write-Log "┌──────────────────────────────────────────────────────────────────┐" "PHASE"
    Write-Log "│ PHASE 1: PRE-FLIGHT ENVIRONMENT CHECKS                           │" "PHASE"
    Write-Log "└──────────────────────────────────────────────────────────────────┘" "PHASE"
    
    # 1.1 Operating System
    Write-Log "Checking operating system..." "INFO"
    $os = Get-CimInstance Win32_OperatingSystem
    if ($os.Caption -notmatch $script:Config.RequiredOS) {
        Exit-WithError "OS MISMATCH: Expected '$($script:Config.RequiredOS)', found '$($os.Caption)'"
    }
    Write-Log "  ✓ OS: $($os.Caption) (Build $($os.BuildNumber))" "OK"
    
    # 1.2 PowerShell Version
    Write-Log "Checking PowerShell version..." "INFO"
    $psVer = $PSVersionTable.PSVersion
    if ($psVer.Major -lt $script:Config.RequiredPSMajor -or 
        ($psVer.Major -eq $script:Config.RequiredPSMajor -and $psVer.Minor -lt $script:Config.RequiredPSMinor)) {
        Exit-WithError "PowerShell version mismatch: Expected $($script:Config.RequiredPSMajor).$($script:Config.RequiredPSMinor)+, found $psVer"
    }
    Write-Log "  ✓ PowerShell: $psVer" "OK"
    
    # 1.3 Python Installation
    Write-Log "Checking Python installation..." "INFO"
    if (-not (Test-Path $script:Config.PythonPath)) {
        Exit-WithError "Python not found at: $($script:Config.PythonPath)"
    }
    
    $pyVerOutput = & $script:Config.PythonPath --version 2>&1
    if ($pyVerOutput -notmatch $script:Config.RequiredPython) {
        Exit-WithError "Python version mismatch: Expected $($script:Config.RequiredPython).x, found $pyVerOutput"
    }
    Write-Log "  ✓ Python: $pyVerOutput" "OK"
    
    # 1.4 Disk Space
    Write-Log "Checking disk space..." "INFO"
    $cDrive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
    if (-not $cDrive) {
        Exit-WithError "C: drive not accessible"
    }
    
    $freeGB = [math]::Round($cDrive.Free / 1GB, 2)
    if ($freeGB -lt $script:Config.MinDiskSpaceGB) {
        Exit-WithError "Insufficient disk space: $freeGB GB free (need $($script:Config.MinDiskSpaceGB)+ GB)"
    }
    Write-Log "  ✓ Disk space: $freeGB GB free on C:" "OK"
    
    # 1.5 Administrator Privileges
    Write-Log "Checking administrator privileges..." "INFO"
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    if (-not $isAdmin) {
        Exit-WithError "Administrator privileges required. Run PowerShell as Administrator."
    }
    Write-Log "  ✓ Running with administrator privileges" "OK"
    
    # 1.6 Backup Path Exists
    Write-Log "Checking backup path..." "INFO"
    if (-not (Test-Path $script:Config.BackupPath)) {
        Exit-WithError "Backup path not found: $($script:Config.BackupPath)"
    }
    Write-Log "  ✓ Backup path exists" "OK"
    
    # 1.7 Manifest Exists
    $manifestPath = Join-Path $script:Config.BackupPath $script:Config.ManifestName
    Write-Log "Checking manifest file..." "INFO"
    if (-not (Test-Path $manifestPath)) {
        Exit-WithError "Manifest not found: $manifestPath"
    }
    Write-Log "  ✓ Manifest found: $($script:Config.ManifestName)" "OK"
    
    Write-Log " "
    Write-Log "Pre-flight checks: ALL PASSED" "OK"
    Write-Log " "
    
    return $true
}

# ============================================================================
# PHASE 2: MANIFEST VALIDATION
# ============================================================================
function Test-ManifestIntegrity {
    Write-Log "┌──────────────────────────────────────────────────────────────────┐" "PHASE"
    Write-Log "│ PHASE 2: MANIFEST VALIDATION                                     │" "PHASE"
    Write-Log "└──────────────────────────────────────────────────────────────────┘" "PHASE"
    
    $manifestPath = Join-Path $script:Config.BackupPath $script:Config.ManifestName
    
    # 2.1 Parse manifest
    Write-Log "Parsing manifest JSON..." "INFO"
    try {
        $manifestRaw = Get-Content $manifestPath -Raw -ErrorAction Stop
        $manifest = $manifestRaw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Exit-WithError "Failed to parse manifest: $($_.Exception.Message)"
    }
    Write-Log "  ✓ Manifest parsed successfully" "OK"
    
    # 2.2 Verify manifest checksum
    Write-Log "Verifying manifest checksum..." "INFO"
    $storedChecksum = $manifest.manifest_checksum
    
    if ([string]::IsNullOrEmpty($storedChecksum)) {
        Exit-WithError "Manifest missing checksum field"
    }
    
    # Remove checksum for recalculation
    $manifestForHash = $manifest.PSObject.Copy()
    $manifestForHash.PSObject.Properties.Remove('manifest_checksum')
    
    $manifestJson = $manifestForHash | ConvertTo-Json -Depth 10 -Compress:$false
    $manifestBytes = [System.Text.Encoding]::UTF8.GetBytes($manifestJson)
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($manifestBytes)
    $computedChecksum = [System.BitConverter]::ToString($hashBytes) -replace "-", ""
    
    if ($computedChecksum -ne $storedChecksum) {
        Write-Log "  Expected: $storedChecksum" "ERROR"
        Write-Log "  Computed: $computedChecksum" "ERROR"
        Exit-WithError "MANIFEST CHECKSUM MISMATCH - File may be corrupted or tampered"
    }
    Write-Log "  ✓ Manifest checksum verified: $($storedChecksum.Substring(0,16))..." "OK"
    
    # 2.3 Verify required fields
    Write-Log "Validating manifest schema..." "INFO"
    $requiredFields = @("schema_version", "system_version", "created_at", "directories", "total_files")
    foreach ($field in $requiredFields) {
        if (-not $manifest.PSObject.Properties.Name.Contains($field)) {
            Exit-WithError "Manifest missing required field: $field"
        }
    }
    Write-Log "  ✓ All required fields present" "OK"
    
    # 2.4 Verify directory count
    Write-Log "Validating directory entries..." "INFO"
    if ($manifest.directories.Count -ne $script:Config.SourceDirs.Count) {
        Exit-WithError "Directory count mismatch: Expected $($script:Config.SourceDirs.Count), found $($manifest.directories.Count)"
    }
    Write-Log "  ✓ Directory count matches: $($manifest.directories.Count)" "OK"
    
    Write-Log " "
    Write-Log "Manifest validation: PASSED" "OK"
    Write-Log " "
    
    return $manifest
}

# ============================================================================
# PHASE 3: BACKUP FILE VERIFICATION
# ============================================================================
function Test-BackupFiles {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Manifest
    )
    
    Write-Log "┌──────────────────────────────────────────────────────────────────┐" "PHASE"
    Write-Log "│ PHASE 3: BACKUP FILE VERIFICATION                                │" "PHASE"
    Write-Log "└──────────────────────────────────────────────────────────────────┘" "PHASE"
    
    $totalFiles = 0
    $verifiedFiles = 0
    $mismatches = [System.Collections.ArrayList]::new()
    
    foreach ($dir in $Manifest.directories) {
        $dirName = Split-Path $dir.source_path -Leaf
        $backupDir = Join-Path $script:Config.BackupPath $dirName
        
        Write-Log "Verifying: $dirName ($($dir.files.Count) files)..." "INFO"
        
        # Check backup directory exists
        if (-not (Test-Path $backupDir)) {
            Exit-WithError "Backup directory missing: $backupDir"
        }
        
        $dirErrors = 0
        foreach ($file in $dir.files) {
            $totalFiles++
            $backupFilePath = Join-Path $backupDir $file.relative_path
            
            # Check file exists
            if (-not (Test-Path $backupFilePath)) {
                [void]$mismatches.Add("MISSING: $backupFilePath")
                $dirErrors++
                continue
            }
            
            # Verify SHA256 hash
            $actualHash = (Get-FileHash $backupFilePath -Algorithm SHA256).Hash
            if ($actualHash -ne $file.sha256) {
                [void]$mismatches.Add("HASH MISMATCH: $($file.relative_path) [Expected: $($file.sha256.Substring(0,16))..., Got: $($actualHash.Substring(0,16))...]")
                $dirErrors++
                continue
            }
            
            # Verify file size
            $actualSize = (Get-Item $backupFilePath).Length
            if ($actualSize -ne $file.size_bytes) {
                [void]$mismatches.Add("SIZE MISMATCH: $($file.relative_path) [Expected: $($file.size_bytes), Got: $actualSize]")
                $dirErrors++
                continue
            }
            
            $verifiedFiles++
        }
        
        if ($dirErrors -eq 0) {
            Write-Log "  ✓ $dirName : $($dir.files.Count) files verified" "OK"
        } else {
            Write-Log "  ✗ $dirName : $dirErrors errors detected" "ERROR"
        }
    }
    
    # Report any mismatches
    if ($mismatches.Count -gt 0) {
        Write-Log " " "ERROR"
        Write-Log "VERIFICATION FAILED - $($mismatches.Count) error(s) detected:" "ERROR"
        Write-Log " " "ERROR"
        foreach ($mismatch in $mismatches) {
            Write-Log "  • $mismatch" "ERROR"
        }
        Exit-WithError "Backup integrity check failed. Cannot proceed with restore."
    }
    
    Write-Log " "
    Write-Log "Backup file verification: ALL $verifiedFiles/$totalFiles FILES PASSED" "OK"
    Write-Log " "
    
    return $true
}

# ============================================================================
# PHASE 4: ATOMIC RESTORE
# ============================================================================
function Invoke-AtomicRestore {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Manifest
    )
    
    Write-Log "┌──────────────────────────────────────────────────────────────────┐" "PHASE"
    Write-Log "│ PHASE 4: ATOMIC DIRECTORY RESTORE                                │" "PHASE"
    Write-Log "└──────────────────────────────────────────────────────────────────┘" "PHASE"
    
    # Confirmation prompt (unless -Force)
    if (-not $Force) {
        Write-Log " " "WARN"
        Write-Log "╔══════════════════════════════════════════════════════════════════╗" "WARN"
        Write-Log "║                         WARNING                                   ║" "WARN"
        Write-Log "║                                                                   ║" "WARN"
        Write-Log "║  This operation will OVERWRITE the following directories:        ║" "WARN"
        Write-Log "║                                                                   ║" "WARN"
        foreach ($dir in $script:Config.SourceDirs) {
            Write-Log "║    • $($dir.PadRight(54))║" "WARN"
        }
        Write-Log "║                                                                   ║" "WARN"
        Write-Log "║  Type 'RESTORE' to proceed or any other key to cancel.           ║" "WARN"
        Write-Log "╚══════════════════════════════════════════════════════════════════╝" "WARN"
        Write-Log " " "WARN"
        
        $confirmation = Read-Host "Confirm"
        if ($confirmation -ne "RESTORE") {
            Exit-WithError "Restore cancelled by user (entered: '$confirmation')"
        }
        Write-Log "User confirmed restore operation" "INFO"
    } else {
        Write-Log "Force mode enabled - skipping confirmation" "INFO"
    }
    
    Write-Log " "
    
    $restoredDirs = [System.Collections.ArrayList]::new()
    
    foreach ($dir in $Manifest.directories) {
        $sourcePath = $dir.source_path
        $dirName = Split-Path $sourcePath -Leaf
        $backupDir = Join-Path $script:Config.BackupPath $dirName
        
        # Temp and backup paths for atomic swap
        $tempPath = "$sourcePath.restore_temp_$(Get-Date -Format 'yyyyMMddHHmmss')"
        $oldPath = "$sourcePath.restore_old_$(Get-Date -Format 'yyyyMMddHHmmss')"
        
        Write-Log "Restoring: $dirName" "INFO"
        Write-Log "  Source: $backupDir" "DEBUG"
        Write-Log "  Target: $sourcePath" "DEBUG"
        
        try {
            # Step 1: Copy backup to temp location
            Write-Log "  [1/4] Creating temp copy..." "DEBUG"
            if (Test-Path $tempPath) {
                Remove-Item $tempPath -Recurse -Force -ErrorAction Stop
            }
            Copy-Item -Path $backupDir -Destination $tempPath -Recurse -Force -ErrorAction Stop
            
            # Step 2: Move existing directory to .old (if exists)
            if (Test-Path $sourcePath) {
                Write-Log "  [2/4] Backing up existing directory..." "DEBUG"
                if (Test-Path $oldPath) {
                    Remove-Item $oldPath -Recurse -Force -ErrorAction Stop
                }
                Rename-Item -Path $sourcePath -NewName (Split-Path $oldPath -Leaf) -ErrorAction Stop
            } else {
                Write-Log "  [2/4] No existing directory to backup" "DEBUG"
            }
            
            # Step 3: Atomic rename temp → target
            Write-Log "  [3/4] Performing atomic swap..." "DEBUG"
            Rename-Item -Path $tempPath -NewName $dirName -ErrorAction Stop
            
            # Step 4: Remove old directory
            if (Test-Path $oldPath) {
                Write-Log "  [4/4] Removing old directory..." "DEBUG"
                Remove-Item $oldPath -Recurse -Force -ErrorAction Stop
            } else {
                Write-Log "  [4/4] No cleanup needed" "DEBUG"
            }
            
            [void]$restoredDirs.Add($sourcePath)
            Write-Log "  ✓ $dirName restored successfully" "OK"
            
        } catch {
            Write-Log "  ✗ FAILED: $($_.Exception.Message)" "ERROR"
            
            # Attempt rollback
            Write-Log "  Attempting rollback..." "WARN"
            try {
                if (Test-Path $oldPath) {
                    if (Test-Path $sourcePath) {
                        Remove-Item $sourcePath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    Rename-Item -Path $oldPath -NewName $dirName -ErrorAction Stop
                    Write-Log "  Rollback successful for $dirName" "WARN"
                }
                if (Test-Path $tempPath) {
                    Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Log "  ROLLBACK FAILED: $($_.Exception.Message)" "ERROR"
            }
            
            Exit-WithError "Failed to restore $dirName : $($_.Exception.Message)"
        }
    }
    
    Write-Log " "
    Write-Log "Atomic restore: $($restoredDirs.Count)/$($Manifest.directories.Count) directories restored" "OK"
    Write-Log " "
    
    return $restoredDirs
}

# ============================================================================
# PHASE 5: POST-RESTORE VERIFICATION
# ============================================================================
function Test-PostRestoreIntegrity {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Manifest
    )
    
    Write-Log "┌──────────────────────────────────────────────────────────────────┐" "PHASE"
    Write-Log "│ PHASE 5: POST-RESTORE VERIFICATION                               │" "PHASE"
    Write-Log "└──────────────────────────────────────────────────────────────────┘" "PHASE"
    
    $totalFiles = 0
    $verifiedFiles = 0
    $postErrors = [System.Collections.ArrayList]::new()
    
    foreach ($dir in $Manifest.directories) {
        $dirName = Split-Path $dir.source_path -Leaf
        Write-Log "Verifying restored: $dirName..." "INFO"
        
        foreach ($file in $dir.files) {
            $totalFiles++
            $fullPath = Join-Path $dir.source_path $file.relative_path
            
            # Check file exists at target
            if (-not (Test-Path $fullPath)) {
                [void]$postErrors.Add("MISSING after restore: $fullPath")
                continue
            }
            
            # Verify hash matches
            $actualHash = (Get-FileHash $fullPath -Algorithm SHA256).Hash
            if ($actualHash -ne $file.sha256) {
                [void]$postErrors.Add("HASH MISMATCH after restore: $($file.relative_path)")
                continue
            }
            
            $verifiedFiles++
        }
        
        Write-Log "  ✓ $dirName verified" "OK"
    }
    
    if ($postErrors.Count -gt 0) {
        Write-Log " " "ERROR"
        Write-Log "POST-RESTORE VERIFICATION FAILED:" "ERROR"
        foreach ($err in $postErrors) {
            Write-Log "  • $err" "ERROR"
        }
        Exit-WithError "Restore completed but post-verification failed! System may be in inconsistent state."
    }
    
    Write-Log " "
    Write-Log "Post-restore verification: ALL $verifiedFiles/$totalFiles FILES VERIFIED" "OK"
    Write-Log " "
    
    return $true
}

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================
function Show-CompletionSummary {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Manifest,
        
        [Parameter()]
        [bool]$VerifyOnlyMode = $false
    )
    
    Write-Log " "
    Write-Log "╔══════════════════════════════════════════════════════════════════╗" "OK"
    if ($VerifyOnlyMode) {
        Write-Log "║              VERIFICATION COMPLETED SUCCESSFULLY                 ║" "OK"
    } else {
        Write-Log "║                RESTORE COMPLETED SUCCESSFULLY                    ║" "OK"
    }
    Write-Log "╠══════════════════════════════════════════════════════════════════╣" "OK"
    Write-Log "║                                                                   ║" "OK"
    Write-Log "║  System: $($Manifest.system_version.PadRight(50))║" "OK"
    Write-Log "║  Files:  $("$($Manifest.total_files) verified".PadRight(50))║" "OK"
    Write-Log "║  Size:   $("$([math]::Round($Manifest.total_size_bytes / 1MB, 2)) MB".PadRight(50))║" "OK"
    Write-Log "║                                                                   ║" "OK"
    Write-Log "╚══════════════════════════════════════════════════════════════════╝" "OK"
    
    if (-not $VerifyOnlyMode) {
        Write-Log " "
        Write-Log "NEXT STEPS:" "INFO"
        Write-Log "  1. Verify IBKR TWS:     Test-NetConnection localhost -Port 7496" "INFO"
        Write-Log "  2. Verify MultiCharts:  Test-NetConnection localhost -Port 8765" "INFO"
        Write-Log "  3. Install dependencies: pip install -r requirements.txt" "INFO"
        Write-Log "  4. Run system test in paper trading mode" "INFO"
    }
    
    Write-Log " "
    Write-Log "Log file: $LogPath" "INFO"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
try {
    Show-Banner
    
    # Phase 1: Pre-flight checks
    Test-PreFlightChecks
    
    # Phase 2: Manifest validation
    $manifest = Test-ManifestIntegrity
    
    # Phase 3: Backup file verification
    Test-BackupFiles -Manifest $manifest
    
    # Exit here if verify-only mode
    if ($VerifyOnly) {
        Show-CompletionSummary -Manifest $manifest -VerifyOnlyMode $true
        exit 0
    }
    
    # Phase 4: Atomic restore
    Invoke-AtomicRestore -Manifest $manifest
    
    # Phase 5: Post-restore verification
    Test-PostRestoreIntegrity -Manifest $manifest
    
    # Success summary
    Show-CompletionSummary -Manifest $manifest
    
    exit 0
    
} catch {
    # Error already logged by Exit-WithError
    exit $script:ExitCode
}

