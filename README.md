# Forex Regime Detection System
## Backup & Restore Documentation

**Version**: 2.0  
**Document Date**: 2026-01-24  
**Classification**: Production System Documentation  
**Timezone Reference**: America/New_York (UTC-05:00)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Data Flow](#2-data-flow)
3. [Risk Management Logic](#3-risk-management-logic)
4. [Execution Constraints](#4-execution-constraints)
5. [Operator Restore Guide](#5-operator-restore-guide)
6. [Auditor Verification Checklist](#6-auditor-verification-checklist)
7. [Failure Modes & Invariants](#7-failure-modes--invariants)

---

## 1. Architecture Overview

### 1.1 System Topology

The Forex Regime Detection System operates as a distributed pipeline architecture with four principal components, unified through SQLite synchronization.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FOREX REGIME DETECTION SYSTEM v2.0                        │
│                    ═══════════════════════════════════                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐                                                        │
│  │   DATA LAYER     │                                                        │
│  │                  │                                                        │
│  │  C:\ForexScraper │──────┐                                                 │
│  │  ├─ scrapers/    │      │                                                 │
│  │  ├─ feeds/       │      │                                                 │
│  │  └─ data.sqlite  │      │                                                 │
│  └──────────────────┘      │                                                 │
│           │                │                                                 │
│           ▼                ▼                                                 │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                   SQLite Synchronization Bus                      │       │
│  │              (Single Source of Truth - INV-002)                   │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│           │                │                │                                │
│           ▼                ▼                ▼                                │
│  ┌──────────────┐  ┌──────────────────┐  ┌─────────────────────┐            │
│  │ ANALYSIS     │  │ RISK LAYER       │  │ EXECUTION LAYER     │            │
│  │              │  │                  │  │                     │            │
│  │ C:\ForexRegime│  │C:\ForexRiskMgmt │  │ C:\MoneyProd        │            │
│  │ ├─ models/   │  │ ├─ limits/      │  │ ├─ engine/          │            │
│  │ ├─ signals/  │  │ ├─ position/    │  │ ├─ orders/          │            │
│  │ └─ regime.db │  │ └─ risk.sqlite  │  │ └─ trades.sqlite    │            │
│  └──────────────┘  └──────────────────┘  └─────────────────────┘            │
│           │                │                       │                         │
│           └────────────────┴───────────────────────┘                         │
│                            │                                                 │
│                            ▼                                                 │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                    EXTERNAL INTERFACES                            │       │
│  │  ┌─────────────────┐           ┌─────────────────────────────┐   │       │
│  │  │ MultiCharts 16.0│           │ IBKR TWS API                │   │       │
│  │  │ Port: 8765      │           │ Ports: 7496/7497/4001/4002  │   │       │
│  │  │ Study Editor 4.0w│          │ Live/Paper/Gateway          │   │       │
│  │  └─────────────────┘           └─────────────────────────────┘   │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Component Responsibilities

| Component | Directory | Primary Function | Critical Files |
|-----------|-----------|------------------|----------------|
| **ForexScraper** | `C:\ForexScraper` | Live data acquisition from web sources | `*.py`, `*.json`, `data.sqlite` |
| **ForexRegime** | `C:\ForexRegime` | Market regime classification (trending/ranging/volatile) | `*.py`, `*.pkl`, `regime.db` |
| **ForexRiskManagement** | `C:\ForexRiskManagement` | Position sizing, drawdown control, exposure limits | `*.py`, `risk.sqlite` |
| **MoneyProd** | `C:\MoneyProd` | Order execution, trade reconciliation | `*.py`, `trades.sqlite`, `*.config` |

### 1.3 Technology Stack

| Layer | Technology | Version | Notes |
|-------|------------|---------|-------|
| Operating System | Windows Server 2022 | 21H2 | Build 20348 |
| Shell | PowerShell | 7.5.4 | Required for scripts |
| Runtime | Python | 3.14.2 | `C:\Python314\python.exe` |
| Database | SQLite | 3.x | Embedded via Python |
| Charting | MultiCharts | 16.0 | Study Editor 4.0w |
| Broker | IBKR TWS | Latest | API enabled |

---

## 2. Data Flow

### 2.1 Pipeline Stages

```
STAGE 1: ACQUISITION          STAGE 2: ANALYSIS           STAGE 3: RISK           STAGE 4: EXECUTION
═══════════════════          ═════════════════           ════════════            ══════════════════

┌─────────────────┐         ┌─────────────────┐        ┌─────────────┐         ┌─────────────────┐
│ Web Scrapers    │         │ Regime Detector │        │ Position    │         │ Order Router    │
│ ─────────────   │         │ ───────────────│        │ Sizer       │         │ ────────────    │
│                 │         │                 │        │             │         │                 │
│ • Price feeds   │────────▶│ • HMM models    │───────▶│ • Kelly     │────────▶│ • IBKR API      │
│ • Economic data │         │ • Volatility    │        │ • Drawdown  │         │ • MultiCharts   │
│ • Sentiment     │         │ • Trend         │        │ • Exposure  │         │ • Logging       │
│                 │         │                 │        │             │         │                 │
└────────┬────────┘         └────────┬────────┘        └──────┬──────┘         └────────┬────────┘
         │                           │                        │                         │
         ▼                           ▼                        ▼                         ▼
    ┌─────────┐                ┌─────────┐               ┌─────────┐              ┌─────────┐
    │ SQLite  │                │ SQLite  │               │ SQLite  │              │ SQLite  │
    │ data.db │                │regime.db│               │ risk.db │              │trades.db│
    └─────────┘                └─────────┘               └─────────┘              └─────────┘
```

### 2.2 Data Synchronization Rules

1. **Single Source of Truth**: All inter-component communication occurs via SQLite databases (INV-002)
2. **No Hardcoded Fallbacks**: If live data unavailable, system pauses rather than uses stale data (INV-003)
3. **Timezone Normalization**: All timestamps stored as America/New_York (INV-001)
4. **Atomic Transactions**: All database writes are transactional with rollback capability

### 2.3 Message Types

| Message | Source | Destination | Payload |
|---------|--------|-------------|---------|
| `PRICE_UPDATE` | ForexScraper | ForexRegime | `{pair, bid, ask, timestamp}` |
| `REGIME_SIGNAL` | ForexRegime | ForexRiskManagement | `{pair, regime, confidence, timestamp}` |
| `POSITION_REQUEST` | ForexRiskManagement | MoneyProd | `{pair, direction, size, limits}` |
| `ORDER_FILL` | MoneyProd | ForexRiskManagement | `{order_id, fill_price, quantity, timestamp}` |

---

## 3. Risk Management Logic

### 3.1 Position Sizing Framework

```python
# Simplified position sizing algorithm
def calculate_position_size(equity, risk_per_trade, stop_distance):
    """
    Kelly-derived position sizing with hard caps.
    
    Constraints:
    - max_single_position = 0.02 * equity (2%)
    - max_correlated_exposure = 0.06 * equity (6%)
    - daily_loss_limit = 0.03 * equity (3%) → SYSTEM HALT
    - weekly_loss_limit = 0.05 * equity (5%) → MANUAL REVIEW
    """
    raw_size = (equity * risk_per_trade) / stop_distance
    max_size = equity * 0.02
    return min(raw_size, max_size)
```

### 3.2 Risk Limits Matrix

| Limit Type | Threshold | Action on Breach |
|------------|-----------|------------------|
| Single Position | 2% equity | Order rejected |
| Correlated Exposure | 6% equity | New positions blocked |
| Daily Loss | 3% equity | System halt, alert |
| Weekly Loss | 5% equity | Manual review required |
| Max Open Positions | 5 | Queue new signals |

### 3.3 Drawdown Control

```
Peak Equity ────────────────────────────────────┐
                                                │
Current Equity ─────────────┐                   │ Maximum
                            │                   │ Drawdown
                            ▼                   │ Limit
                        ┌───────┐               │
                        │ 10%   │ WARNING       │
                        ├───────┤               │
                        │ 15%   │ REDUCE SIZE   │
                        ├───────┤               │
                        │ 20%   │ HALT TRADING  │
                        └───────┘               │
                                                │
Maximum Allowed Drawdown ───────────────────────┘
```

---

## 4. Execution Constraints

### 4.1 Order Routing Rules

1. **Venue Priority**: IBKR TWS (primary) → MultiCharts (signal source only)
2. **Order Types**: LIMIT orders preferred; MARKET only for urgent exits
3. **Slippage Control**: Max 3 pips slippage tolerance on entry
4. **Retry Logic**: 3 attempts with exponential backoff (1s, 2s, 4s)

### 4.2 Market Hours

| Session | UTC Time | NY Time | Components Active |
|---------|----------|---------|-------------------|
| Sydney | 21:00-06:00 | 16:00-01:00 | Scraper, Regime |
| Tokyo | 00:00-09:00 | 19:00-04:00 | Scraper, Regime |
| London | 07:00-16:00 | 02:00-11:00 | All |
| New York | 12:00-21:00 | 07:00-16:00 | All |

### 4.3 Connection Requirements

```powershell
# Health check commands
Test-NetConnection localhost -Port 7496   # IBKR TWS Live
Test-NetConnection localhost -Port 7497   # IBKR TWS Paper
Test-NetConnection localhost -Port 8765   # MultiCharts
```

---

## 5. Operator Restore Guide

### 5.1 Prerequisites Checklist

Before starting restore, verify:

- [ ] Windows Server 2022 (21H2) freshly installed
- [ ] PowerShell 7.5.4 installed and in PATH
- [ ] Python 3.14.2 installed at `C:\Python314\python.exe`
- [ ] Minimum 10 GB free disk space on C: drive
- [ ] Network access to `P:\Trading\ForexRegimeDetectionSystem\backup\`
- [ ] Administrator privileges

### 5.2 Restore Procedure

#### Step 1: Open Elevated PowerShell 7.5.4

```powershell
# Right-click PowerShell 7 → Run as Administrator
# Verify version
$PSVersionTable.PSVersion  # Should show 7.5.4
```

#### Step 2: Navigate to Backup Directory

```powershell
# Replace FullXX with actual backup name (e.g., Full20260124_120000)
cd "P:\Trading\ForexRegimeDetectionSystem\backup\FullXX"
```

#### Step 3: Verify Backup Integrity

```powershell
# Run verification only (no changes made)
.\RESTORE.ps1 -VerifyOnly -Verbose
```

Expected output:
```
[PHASE 1] PRE-FLIGHT CHECKS
  ✓ OS: Windows Server 2022
  ✓ PowerShell: 7.5.4
  ✓ Python: 3.14.2
  ✓ Disk space: XX GB free
[PHASE 2] MANIFEST VALIDATION
  ✓ Manifest checksum verified
[PHASE 3] BACKUP FILE VERIFICATION
  ✓ All files verified
VERIFICATION COMPLETE - All checks passed
```

#### Step 4: Execute Restore

```powershell
# Interactive restore (will prompt for confirmation)
.\RESTORE.ps1 -Verbose

# Or automated restore (no prompts)
.\RESTORE.ps1 -Force -Verbose
```

#### Step 5: Post-Restore Verification

```powershell
# Verify directories exist
Test-Path C:\MoneyProd
Test-Path C:\ForexRegime
Test-Path C:\ForexScraper
Test-Path C:\ForexRiskManagement

# Verify Python dependencies
C:\Python314\python.exe -c "import sqlite3; print('SQLite OK')"

# Verify external connections
Test-NetConnection localhost -Port 7496  # IBKR TWS
Test-NetConnection localhost -Port 8765  # MultiCharts
```

### 5.3 Post-Restore Configuration

```powershell
# Set environment variables
[System.Environment]::SetEnvironmentVariable("FOREX_TIMEZONE", "America/New_York", "Machine")
[System.Environment]::SetEnvironmentVariable("FOREX_DB_PATH", "C:\ForexRegime\data\regime.sqlite", "Machine")
[System.Environment]::SetEnvironmentVariable("IBKR_PORT", "7496", "Machine")
[System.Environment]::SetEnvironmentVariable("MULTICHARTS_PORT", "8765", "Machine")

# Install Python dependencies (if requirements.txt exists)
cd C:\MoneyProd
C:\Python314\python.exe -m pip install -r requirements.txt --break-system-packages
```

---

## 6. Auditor Verification Checklist

### 6.1 Integrity Verification Script

```powershell
# Full integrity verification
$manifest = Get-Content "P:\Trading\ForexRegimeDetectionSystem\backup\FullXX\MANIFEST.json" | ConvertFrom-Json

$errors = @()
$verified = 0

foreach ($dir in $manifest.directories) {
    foreach ($file in $dir.files) {
        $fullPath = Join-Path $dir.source_path $file.relative_path
        
        if (-not (Test-Path $fullPath)) {
            $errors += "MISSING: $fullPath"
            continue
        }
        
        $actualHash = (Get-FileHash $fullPath -Algorithm SHA256).Hash
        if ($actualHash -ne $file.sha256) {
            $errors += "HASH MISMATCH: $fullPath"
            continue
        }
        
        $verified++
    }
}

if ($errors.Count -eq 0) {
    Write-Host "✓ PASSED: $verified files verified" -ForegroundColor Green
} else {
    Write-Host "✗ FAILED: $($errors.Count) errors" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
```

### 6.2 Audit Checkpoints

| # | Check | Command | Expected Result |
|---|-------|---------|-----------------|
| 1 | Total file count matches manifest | `(Get-ChildItem C:\MoneyProd,C:\ForexRegime,C:\ForexScraper,C:\ForexRiskManagement -Recurse -File).Count` | Matches `total_files` in MANIFEST.json |
| 2 | No hardcoded fallbacks | `Select-String -Path "C:\*\*.py" -Pattern "fallback\|hardcode" -Recurse` | 0 matches |
| 3 | Timezone enforcement | `Select-String -Path "C:\*\*.py" -Pattern "America/New_York" -Recurse` | Present in all modules |
| 4 | SQLite-only data operations | `Select-String -Path "C:\*\*.py" -Pattern "\.sqlite\|\.db" -Recurse` | All data operations use SQLite |
| 5 | No disabled pipeline stages | `Select-String -Path "C:\*\*.py" -Pattern "# disabled\|skip.*stage\|bypass" -Recurse` | 0 matches |
| 6 | Risk limits present | `Select-String -Path "C:\ForexRiskManagement\*.py" -Pattern "max_position\|daily_loss\|drawdown" -Recurse` | All limits defined |

### 6.3 Compliance Matrix

| Invariant | Verification Method | Status |
|-----------|---------------------|--------|
| INV-001: Timezone | Search for timezone enforcement in code | ☐ |
| INV-002: SQLite only | Verify no alternative data stores | ☐ |
| INV-003: Live data | Verify no hardcoded values | ☐ |
| INV-004: Risk limits | Verify limits in RiskManagement | ☐ |
| INV-005: No disabled stages | Search for bypass patterns | ☐ |

---

## 7. Failure Modes & Invariants

### 7.1 System Invariants

| ID | Invariant | Enforcement | Violation Response |
|----|-----------|-------------|-------------------|
| **INV-001** | All timestamps MUST be America/New_York | STRICT | System halt |
| **INV-002** | SQLite is single source of truth | STRICT | No fallback allowed |
| **INV-003** | All data MUST be live (no hardcoded) | STRICT | Pause until repaired |
| **INV-004** | Risk limits are non-negotiable | STRICT | Position rejected |
| **INV-005** | Pipeline stages cannot be disabled | STRICT | Repair required |

### 7.2 Failure Mode Analysis

| Failure Mode | Detection | Impact | Recovery |
|--------------|-----------|--------|----------|
| IBKR TWS disconnection | Port 7496 unreachable | Orders rejected | Restart TWS, verify credentials |
| MultiCharts disconnection | Port 8765 unreachable | No chart signals | Restart MultiCharts |
| SQLite lock contention | Write timeout > 5s | Data sync stalled | Kill competing process |
| Scraper timeout | No data update > 60s | Stale regime classification | Check network, restart scraper |
| Hash mismatch on restore | SHA256 differs | Backup corrupted | Re-download backup |
| Timezone drift | System clock != NTP | Incorrect signals | Sync with time.windows.com |
| Disk full | < 1GB free | Write failures | Clear logs, expand storage |

### 7.3 Recovery Procedures

#### IBKR Connection Lost

```powershell
# 1. Check connection
Test-NetConnection localhost -Port 7496

# 2. Restart TWS
Stop-Process -Name "tws" -Force -ErrorAction SilentlyContinue
Start-Process "C:\TWS\tws.exe"
Start-Sleep -Seconds 30

# 3. Verify reconnection
Test-NetConnection localhost -Port 7496
```

#### SQLite Lock Recovery

```powershell
# 1. Find locking process
$db = "C:\ForexRegime\data\regime.sqlite"
Get-Process | Where-Object { $_.Modules.FileName -contains $db }

# 2. Kill if necessary (CAUTION)
# Stop-Process -Id <PID> -Force

# 3. Verify database integrity
C:\Python314\python.exe -c "import sqlite3; c=sqlite3.connect('$db'); c.execute('PRAGMA integrity_check').fetchone()"
```

### 7.4 Critical Principle

> **NO COMPONENT MAY BE DISABLED AS A "FIX"**
>
> All pipeline stages must function correctly for the system to operate. If a stage fails, it must be **repaired**, not bypassed. Disabling any invariant enforcement or pipeline stage is a violation of system integrity and will result in undefined trading behavior.

---

## Appendix A: Manifest Schema

See `MANIFEST.json` for the complete schema definition with field descriptions.

## Appendix B: Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-01 | System | Initial release |
| 2.0 | 2026-01-24 | System | Added restore framework |

---

*Document generated by Forex Regime Detection System Backup Framework v1.0.0*
