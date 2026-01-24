# ForexRegime Unified Pipeline - Addendum

> **Complete Architecture Documentation**  
> Machine Learning • Reinforcement Learning • Bayesian Optimization

---

| Attribute | Value |
|-----------|-------|
| Document Version | 22.0 addendum |
| Pipeline Version | 5.0 |
| Date | January 24, 2026 |
| Environment | Windows Server 2022 (21H2) |
| Python Version | 3.14.2 |
| Database | SQLite 3.x (forex_data.db, risk_management.db) |
| Timezone | America/New_York (EST/EDT) |

### System Specifications

| 11 | 22 | 8 | 8 |
|:--:|:--:|:--:|:--:|
| Pipeline Phases | Trading Theories | Currency Pairs | IBKR Accounts |

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. System Architecture Overview](#2-system-architecture-overview)
- [3. Market Guard System (NEW)](#3-market-guard-system-new)
- [4-15. Core Pipeline Phases](#4-15-core-pipeline-phases)
- [16. Risk Management Engine (RME) - UPDATED](#16-risk-management-engine-rme---updated)
- [17. Discord Notifications - UPDATED](#17-discord-notifications---updated)
- [18. Appendices](#18-appendices)

---

## 1. Executive Summary

The ForexRegime Unified Pipeline is a sophisticated quantitative trading system that combines real-time sentiment analysis, machine learning regime detection, Bayesian optimization, and reinforcement learning to generate actionable trading signals across 8 major currency pairs. The system processes data from 7+ external sources, calculates 22 distinct trading theories, and produces optimized strategy assignments updated every execution cycle.

### Version 22.0 Updates (January 2026)

- **Market Guard**: Automatic pipeline blocking during IBKR IDEALPRO closed hours and holidays
- **Enhanced RME**: Real-time IBKR account sync with 8/8 account monitoring
- **Discord Alerts**: Comprehensive pipeline health reports with regime balance monitoring
- **Health Monitor**: Circuit breaker, P&L tracking, and automated health checks
- **NY Timezone**: All timestamps synchronized to America/New_York

### 1.1 Core Objectives

- **Regime Detection**: Classify market conditions as Trend-Following (TF) or Mean-Reverting (MR) using an ensemble of 22 quantitative theories weighted by Bayesian MCMC optimization.
- **Adaptive Strategy Selection**: Dynamically assign optimal trading strategies based on current market regime, sentiment confluence, and momentum indicators.
- **Risk Management**: Integrate real-time ATR calculations from IBKR, position sizing (1% risk per trade), and crowding penalties to manage portfolio risk.
- **Market Hours Protection**: Prevent calculations during market closed hours to avoid stale data.
- **Continuous Learning**: Employ reinforcement learning (Q-learning) to improve strategy selection based on historical outcome feedback.

### 1.2 Key Performance Indicators

| Metric | Value | Description |
|--------|-------|-------------|
| Pipeline Duration | ~2 minutes | Full 11-phase execution time |
| Total Portfolio Equity | $xxxxxxxxx | 8 IBKR accounts aggregated |
| IBKR Accounts | 8/8 connected | All accounts synced |
| TF/MR Distribution | 25%/75% | Balanced regime allocation |
| ATR Data Freshness | 0 min | Live from IBKR H4 bars |
| Market Guard | Active | Blocks WE + IBKR holidays |

---

## 2. System Architecture Overview

The ForexRegime system follows a modular, pipeline-based architecture where each phase processes data sequentially, storing intermediate results in centralized SQLite databases. This design ensures data consistency, enables auditability, and allows for independent testing of each component.

### 2.1 Pipeline Execution Flow

| Phase | Name | Script | Output |
|-------|------|--------|--------|
| Guard | Market Hours Check | `market_guard.py` | Block/Allow |
| 1a | FXSSI Sentiment | `scraper_fxssi.py` | 16 pairs sentiment |
| 1b | Multi-Source Scraping | `scraper_runner.py` | 41 data records |
| 2 | Theory Calculations | `calculate_theories.py` | 22 theories × 8 pairs |
| 3 | ML Classifier | `ml_classifier.py` | TF/MR regime labels |
| 4 | Bayesian Optimizer | `bayesian_optimizer.py` | Optimized weights |
| 5a | 4-Day Forecast | `forecast_4day.py` | 40 forecasts |
| 5b | ATR Calculation | `atr_calculator.py` | 8 pairs ATR (IBKR) |
| 5c | RME IBKR Sync | `rme_step.py` | 8 accounts synced |
| 5d | Health Check | `health_monitor.py` | System status |
| 6 | Outcome Recording | `outcome_recorder.py` | Performance metrics |
| 7 | RL Training | `rl_agent.py` | Q-table updates |
| 8 | Crowding Penalty | `crowding_penalty.py` | Adjusted signals |
| 9 | Continuous Learning | `continuous_learning.py` | Learning metrics |
| 10 | Report Generation | `generate_exhaustive_report_v4.py` | HTML report |
| 11 | Discord Report | `discord_reporter.py` | Webhook notification |

### 2.2 Directory Structure

```
C:\ForexRegime\
├── unified_pipeline.py          # Main orchestrator
├── market_guard.py              # Market hours protection (NEW)
├── market_hours.json            # IBKR holidays config (NEW)
├── health_monitor.py            # System health checks (NEW)
├── risk_config.json             # Risk parameters (NEW)
├── discord_reporter.py          # Discord notifications (UPDATED)
├── atr_calculator.py            # IBKR ATR calculation
├── rme_step.py                  # RME account sync (NEW)
├── calculate_theories.py        # 22 theory calculations
├── ml_classifier.py             # Regime classification (V7)
├── bayesian_optimizer.py        # MCMC weight optimization
├── data\forex_data.db           # Main SQLite database
└── scrapers\                    # Data collection modules

C:\ForexRiskManagement\
├── data\risk_management.db      # RME SQLite database
└── health_monitor.py            # Health monitoring script
```

---

## 3. Market Guard System (NEW)

The Market Guard is a critical safety component that prevents pipeline execution during IBKR IDEALPRO market closed hours. This ensures no calculations are performed on stale data and prevents false signals during weekends and holidays.

### 3.1 Market Hours Configuration

| Parameter | Value |
|-----------|-------|
| Market Open | Sunday 17:00 ET |
| Market Close | Friday 17:00 ET |
| Weekend Block | Saturday (all day), Sunday < 17:00 ET |
| Config File | `market_hours.json` |
| Timezone | America/New_York (auto DST) |

### 3.2 IBKR Holidays 2026-2027

The Market Guard includes all IBKR-observed US holidays when IDEALPRO Forex markets are closed:

| 2026 Holidays | 2027 Holidays |
|---------------|---------------|
| Jan 1 - New Year's Day | Jan 1 - New Year's Day |
| Jan 20 - MLK Day | Jan 18 - MLK Day |
| Feb 16 - Presidents Day | Feb 15 - Presidents Day |
| Apr 3 - Good Friday | Mar 26 - Good Friday |
| May 25 - Memorial Day | May 31 - Memorial Day |
| Jul 3 - Independence Day (observed) | Jul 5 - Independence Day (observed) |
| Sep 7 - Labor Day | Sep 6 - Labor Day |
| Nov 26 - Thanksgiving | Nov 25 - Thanksgiving |
| Dec 25 - Christmas | Dec 24 - Christmas (observed) |

### 3.3 Guard Integration

The Market Guard is integrated at the very beginning of `unified_pipeline.py`:

```python
from market_guard import check_and_exit_if_closed

def main():
    # MARKET HOURS GUARD - IBKR IDEALPRO
    if not check_and_exit_if_closed():
        log('Pipeline stopped: Market closed')
        return 0
```

**Sample Output (Saturday):**

```
[MARKET GUARD] 2026-01-24 05:36:20 ET
[MARKET GUARD] Status: Market closed: Saturday
[MARKET GUARD] BLOCKED - Pipeline execution prevented
[MARKET GUARD] Next open: Sunday 17:00 ET
```

---

## 4-15. Core Pipeline Phases

The core pipeline phases (FXSSI Sentiment, Multi-Source Scraping, Theory Calculations, ML Classifier, Bayesian Optimizer, Forecasting, Outcome Recording, RL Training, Crowding Penalty, Continuous Learning, and Report Generation) remain as documented in version 1.0. 

### Key Updates in v2.0

- **Weekend Calendar Fix**: `calculate_theories.py` now uses baseline values (`events=0.5`, `density=0.5`) when no calendar data is available on weekends, preventing TF=0%/MR=100% imbalances.
- **NY Timezone Sync**: All timestamps throughout the pipeline are now synchronized to America/New_York timezone using `pytz`.
- **Regime Balance Monitoring**: Target distribution is TF=25%, MR=75%. Alerts are triggered if distribution deviates significantly.

---

## 16. Risk Management Engine (RME) - UPDATED

The Risk Management Engine has been significantly enhanced in v2.0 with real-time IBKR account synchronization, circuit breaker protection, and comprehensive health monitoring.

### 16.1 RME Architecture

```
unified_pipeline.py (Hourly :55)
│
├── ATR Calculator (atr_calculator.py)
│   └── IBKR OHLC → SQLite (8 pairs live)
│
├── RME Step (rme_step.py)
│   ├── 8/8 comptes IBKR sync
│   ├── 32 strategies position sizing
│   ├── Margin monitoring (50/75/90%)
│   └── CSV update (strategies_authorization.csv)
│
├── Health Monitor (health_monitor.py)
│   ├── Circuit breaker tables
│   └── Daily P&L tracking
│
└── Discord Reporter (discord_reporter.py)
    ├── Portfolio equity summary
    ├── Regime distribution alerts
    ├── Human actions required
    └── Pipeline health status
```

### 16.2 Position Sizing Formula

```
Position Size = (Account Equity × Risk%) / (ATR × ATR_Multiplier)

Where:
  Risk% = 1% per trade (configurable in risk_config.json)
  ATR = 14-period Average True Range from IBKR H4 bars
  ATR_Multiplier = 2.0 (stop distance in ATR units)
```

### 16.3 Risk Configuration (risk_config.json)

```json
{
  "risk_per_trade": 0.01,
  "max_daily_loss": 0.05,
  "circuit_breaker_threshold": 0.10,
  "margin_warning": 0.50,
  "margin_critical": 0.75,
  "margin_force_close": 0.90
}
```

### 16.4 Current Account Status

| Account | Equity | MC16 | RME |
|---------|--------|------|-----|
| Uxxxx | $xxxx | ✅ | ✅ |
| Uxxxx | $xxxx | ✅ | ✅ |
| Uxxxx | $xxxx | ✅ | ✅ |
| Uxxxx | $xxxx | ✅ | ✅ |
| Uxxxx | $xxxx | ✅ | ✅ |
| Uxxxx | $xxxx | ✅ | ✅ |
| Uxxxx | $xxxx | ✅ | ✅ |
| Uxxxx | $xxxx | ✅ | ✅ |
| **TOTAL** | **$xxxx** | **8/8** | **8/8** |

---

## 17. Discord Notifications - UPDATED

The Discord notification system has been completely rewritten to provide comprehensive pipeline health reports with real data from SQLite databases.

### 17.1 Discord Report Structure

Each hourly report includes the following sections:

| Section | Content |
|---------|---------|
| Summary | Accounts connected, health status |
| Total Portfolio | Aggregated equity across all accounts |
| Regime Distribution | Current TF/MR assignments with confidence % |
| Pipeline Health Check | SQLite, ATR age, IBKR status, Regime freshness |
| IBKR Accounts | Per-account equity and last sync time |
| Human Actions Required | Alerts requiring manual intervention |

### 17.2 Alert Types

| Icon | Alert Type | Trigger Condition |
|------|------------|-------------------|
| 🟢 | All Systems Normal | No warnings or critical issues |
| 🟡 | ATR Stale | ATR data older than 60 minutes |
| 🟡 | IBKR Stale | Account data older than 60 minutes |
| 🟡 | Regime Imbalance | TF < 20% or TF > 40% (target: 25%) |
| 🔴 | Margin Warning | Account margin > 50% |
| 🔴 | Margin Critical | Account margin > 75% |
| 🚨 | Force Close | Account margin > 90% |

### 17.3 Sample Discord Message

```
📊 ForexRegime Pipeline - All Systems Normal

Hourly Report: 2026-01-23 14:39 ET

Summary: Accounts: 8/8 connected | Health: All HEALTHY

Total Portfolio: Equity (8 accounts): $xxxx

Pipeline Health Check:
🟢 SQLite: Connected
🟢 ATR (H4-14): AUDJPY:45 | AUDUSD:18 | EURJPY:60 | EURUSD:21... (0min)
🟢 IBKR: 8/8 accounts (2min ago)
🟢 Regimes: 8/8 (0min ago)
```

---

## 18. Appendices

### 18.1 Glossary

| Term | Definition |
|------|------------|
| TF | Trend-Following regime - market is trending |
| MR | Mean-Reverting regime - market is ranging |
| ATR | Average True Range - volatility measure |
| RME | Risk Management Engine - position sizing and monitoring |
| MCMC | Markov Chain Monte Carlo - sampling algorithm |
| IDEALPRO | IBKR's forex ECN market |
| Circuit Breaker | Automatic trading halt on excessive losses |

### 18.2 Execution Command

```powershell
cd C:\ForexRegime && python unified_pipeline.py
```

### 18.3 Scheduled Tasks

| Task Name | Schedule | Script |
|-----------|----------|--------|
| ForexPipeline | Hourly at :55 | `unified_pipeline.py` |
| ForexBackup | Daily 00:00 | `daily_backup.py` |

### 18.4 Files Created/Modified in v2.0

| File | Action | Purpose |
|------|--------|---------|
| `market_guard.py` | CREATED | Market hours protection |
| `market_hours.json` | CREATED | IBKR holidays config 2026-2027 |
| `health_monitor.py` | CREATED | Circuit breaker + P&L tracking |
| `risk_config.json` | CREATED | Risk parameters (1% per trade) |
| `rme_step.py` | CREATED | IBKR account sync step |
| `unified_pipeline.py` | MODIFIED | +Guard, +RME step, +Health check |
| `discord_reporter.py` | MODIFIED | Real data, regime balance alerts |
| `calculate_theories.py` | MODIFIED | Weekend baseline fix |
| `ib_client.py` | MODIFIED | NY timezone fix |
| `atr_calculator.py` | MODIFIED | NY timestamp output |

---

*--- End of Document ---*
