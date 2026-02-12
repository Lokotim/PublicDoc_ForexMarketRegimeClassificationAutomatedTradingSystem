# 🏗️ ForexRegime — Complete Trading System Architecture

> **Multi-strategy algorithmic trading system** combining real-time scraping, ML ensemble, reinforcement learning, Bayesian optimization and automated execution via Interactive Brokers & MultiCharts 16.
>
> **Stack**: Python 3.14 · PowerShell 7.5 · SQLite · MultiCharts 16 (Study Editor 4.0w) · IBKR TWS · Windows Server 2022 · IIS

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Unified Pipeline (24 Phases)](#unified-pipeline-24-phases)
3. [Project Directories](#project-directories)
4. [ForexRegime — Decision Engine](#forexregime--decision-engine)
5. [ForexScraper — Data Collection](#forexscraper--data-collection)
6. [ForexRiskManagement — Risk Management](#forexriskmanagement--risk-management)
7. [MoneyProd — MultiCharts/DLL Bridge](#moneyprod--multichartsdll-bridge)
8. [Scraper — Supplementary Sources (Legacy)](#scraper--supplementary-sources-legacy)
9. [SQLite Databases](#sqlite-databases)
10. [Discord Reporter — Real-Time Monitoring](#discord-reporter--real-time-monitoring)
11. [Data Flow Diagram](#data-flow-diagram)
12. [Infrastructure](#infrastructure)

---

## System Overview

The system runs a **complete decision cycle** every hour via cron:

```
Market Data  →  22 Theories  →  ML Ensemble (5 models)  →  Meta-Signal
     ↓                                 ↓                        ↓
  8 scrapers          Bayesian Optimizer + RL Agent        Position Sizing
     ↓                                 ↓                        ↓
  Sentiment DB             4-Day Forecast                 IBKR Execution
                                                               ↓
                                                         Discord Report
```

**Traded pairs**: EURUSD · USDJPY · GBPUSD · USDCHF · AUDUSD · USDCAD · EURJPY · AUDJPY

**Accounts**: 8 IBKR accounts (4 DOM port 7496 + 4 VAL port 7497), ~$xxxK total equity.

**Strategies**: 32 MultiCharts strategies (4 per pair × 8 pairs) split between Trend Following and Mean Reversion.

---

## Unified Pipeline (24 Phases)

The single entry point is:

```powershell
clear; $env:TZ = "EST5EDT"; cd C:\ForexRegime; python unified_pipeline.py
```

Each phase is a standalone Python script executed sequentially. If any phase fails, the pipeline halts and sends a Discord alert.

| # | Phase | Script | Purpose |
|---|-------|--------|---------|
| 1 | **PHASE -1**: TWS Connectivity Guard | `scripts/tws_health_check.py` | Verifies that both TWS instances (DOM/VAL) respond on their API ports before any processing. Prevents running on stale data if IBKR is down. |
| 2 | **PHASE 0d**: GV Telemetry Health | `scripts/phase_gv_health.py` | Queries all 32 MultiCharts GlobalVariables via DLL to check that strategies are alive, AOE (Auto Order Execution) is active, and signals are synced. |
| 3 | **PHASE 0**: IBKR Positions & FX Rates | `scripts/fetch_ibkr_positions.py` | Fetches open positions and live exchange rates from all 8 IBKR accounts. Computes unrealized PnL in USD. Caches 166 FX rates. |
| 4 | **PHASE 0b**: PnL Snapshots & Tracking | `pnl_tracker.py` | Captures a PnL snapshot of each position every run. Feeds hourly aggregates for RL and the circuit breaker. Detects closed trades. |
| 5 | **PHASE 0e**: IBKR vs GV Cross-Validation | `scripts/gv_position_xval.py` | Compares actual IBKR positions with MultiCharts signals to detect desynchronizations (open position without signal, or vice versa). |
| 6 | **PHASE 1a**: FXSSI Sentiment | `scrapers/fxssi/scraper_fxssi.py` | Scrapes retail sentiment for 16 pairs from FXSSI.com. Retail sentiment is a contrarian signal: when the crowd is massively long, the system looks to short. |
| 7 | **PHASE 1b**: Scraping (7 sources) | → `ForexScraper/scraper_runner.py` | Orchestrates the 7 main scrapers (IG, Dukascopy, Myfxbook, MarketBulls, InsiderWeek COT, CFTC, ForexFactory Calendar). Details below. |
| 8 | **PHASE 2**: Theory Calculations | `calculate_theories.py` | Computes 22 financial theories per pair (PPP, Taylor Rule, BEER, carry trade, momentum, etc.) and stores scores in `theory_scores`. |
| 9 | **PHASE 0c**: Data Integrity Guard | `data_integrity_guard.py` | Post-scraping audit: detects anomalies (zero-size positions, aberrant PnL, missing data). Automatically quarantines corrupted records. |
| 10 | **PHASE 3**: ML Strategy Ensemble | `ml_strategy_ensemble.py` | ML core: 5 specialist models (L_TF, S_TF, L_MR, S_MR + Meta-Classifier) trained on features from all 3 databases. Classifies each pair into direction + regime. |
| 11 | **PHASE 4**: Bayesian Optimizer | `bayesian_optimizer.py` | Optimizes the 22 theory weights via MCMC with distribution auto-correction. Learns which theories have the most predictive power. |
| 12 | **PHASE 5**: 4-Day Forecast | `forecast_4day.py` | Projects the regime (TF/MR) over 4 days using calibrated Markov transition probabilities. Stabilizes signals to avoid intraday whipsaw. |
| 13 | **PHASE 6**: Outcome Recording | `outcome_recorder.py` | Records the actual result (IBKR PnL) of each past assignment. Feeds the feedback loop for ML, RL, and the Bayesian Optimizer. |
| 14 | **PHASE 7**: RL Training | `rl_agent.py` | Reinforcement Learning agent (tabular Q-learning) that learns the best strategy per market state. Produces direction+regime recommendations. |
| 15 | **PHASE 7b**: RL Continuous PnL Training | `rl_continuous_training.py` | Continuous RL training on unrealized PnL (not just closed trades). Captures intra-trade performance micro-signals. |
| 16 | **PHASE 7c**: Meta-Signal Resolver | `meta_signal_resolver.py` | Arbitrates conflicts between ML, Forecast, and RL. Weighted vote (ML~41%, Forecast~42%, RL~17%). Produces the FINAL signal: unanimous/majority/split. |
| 17 | **PHASE 0a-PRE**: ATR Calculation | `atr_calculator.py` | Computes Average True Range on H4 and D1 bars for each pair. ATR is the foundation of position sizing (stop-loss = 2× ATR). |
| 18 | **PHASE 0a-CB**: PnL Circuit Breaker | `scripts/pnl_circuit_breaker.py` | Safety mechanism: reduces or blocks sizing if daily drawdown exceeds thresholds (-2%, -5%, -10%). Protects against cascading losses. |
| 19 | **PHASE 0a**: Smart Position Sizing | `scripts/smart_position_sizing.py` | Computes each position size: ATR-based risk (2% per trade), max leverage constraint (2.5x), 25K minimum. Generates the authorization CSV for MultiCharts. |
| 20 | **PHASE 8a**: Crowding Outcome Sync | `sync_crowding_outcomes.py` | Syncs PnL results with crowding decisions (when too many strategies are on the same side). |
| 21 | **PHASE 8**: Crowding Penalty | `crowding_penalty.py` | Penalizes positions when the market is overcrowded (>70% of strategies in the same direction). Continuous A/B testing to validate effectiveness. |
| 22 | **PHASE 9**: Continuous Learning | `continuous_learning.py` | Meta-learning: tracks model drift (accuracy, precision, recall). Triggers retraining if accuracy drops below threshold. |
| 23 | **PHASE 10a**: Pipeline Diagnostics | `scripts/pipeline_diagnostics.py` | Comprehensive health check: verifies every component (scrapers, ML, RL, Meta, positions, equity, sizing). Generates WARN/CRIT levels for Discord. |
| 24 | **PHASE 10**: Exhaustive Report | `generate_exhaustive_report_v4.py` | Generates the interactive HTML report (17 sections, ~3MB) published to IIS. Complete monitoring dashboard accessible via browser. |

### Post-Pipeline (built into `unified_pipeline.py`)

| Step | Purpose |
|------|---------|
| IIS Publish | Copies the HTML report to `C:\inetpub\wwwroot\moneyprod\` |
| RME Sync | Synchronizes all 8 IBKR accounts via the Risk Management Engine |
| Daily P&L Check | Verifies daily loss limits |
| MC16 GV Health | Final check of all 32 MultiCharts strategies |
| Discord Reporter | Sends the complete report to Discord (positions, PnL, regimes, diagnostics) |

---

## Project Directories

```
C:\
├── ForexRegime\            # Decision engine (pipeline, ML, RL, sizing)
│   ├── scripts\            # Pipeline phase sub-scripts
│   ├── scrapers\fxssi\     # Dedicated FXSSI scraper
│   ├── data\               # SQLite databases (forex_regime.db, forex_sentiment.db)
│   ├── logs\               # Timestamped pipeline logs
│   └── reports\            # HTML reports and JSON metrics
│
├── ForexScraper\           # Data collection (7 sources)
│   ├── scrapers\           # Scraper modules (ig_com, dukascopy, myfxbook, etc.)
│   ├── storage\            # Database layer + migrations
│   └── data\               # forex_sentiment.db + logs
│
├── ForexRiskManagement\    # Risk management & execution
│   ├── risk_engine.py      # Main risk engine
│   ├── ib_client.py        # IBKR TWS API client
│   └── multicharts_client.py # MultiCharts interface
│
├── MoneyProd\              # DLL bridge: MultiCharts ↔ Pipeline
│   ├── MoneyProdSupervisor.dll  # C++ DLL loaded by MC16
│   └── strategies_auth_simple.csv # Trading authorizations
│
└── Scraper\                # Supplementary sources (COT, OECD, seasonality)
    ├── code\               # Specialized scrapers
    ├── forexclientsentiment\ # FCS scraper
    ├── forexfactory\       # Calendar scraper
    └── market_bulls\       # Seasonality
```

---

## ForexRegime — Decision Engine

### Pipeline Scripts (root)

| File | Purpose |
|------|---------|
| `unified_pipeline.py` | **Main orchestrator**. Defines the order of all 24 phases, handles errors, logging, and Discord notifications. Single entry point for the entire system. |
| `calculate_theories.py` | Computes 22 macro-financial theories per pair: Purchasing Power Parity (PPP), Taylor Rule, Behavioral Equilibrium Exchange Rate (BEER), carry trade, momentum, mean reversion, volatility, sentiment, COT positioning, seasonality, etc. Each theory produces a normalized score [-1, +1]. |
| `ml_strategy_ensemble.py` | **5-model ML ensemble** (Mixture of Experts). 4 specialists (Long-TF, Short-TF, Long-MR, Short-MR) and 1 meta-classifier. Trained on 117 features extracted from all 3 databases. Outputs per pair: direction (L/S), regime (TF/MR), confidence (0-100%). |
| `ml_classifier.py` | Base ML classifier (single-model version). Used as fallback if the ensemble fails. |
| `bayesian_optimizer.py` | Optimizes the 22 theory weights via Markov Chain Monte Carlo (MCMC). The insight: certain theories are more predictive depending on the market regime. The optimizer learns these weights dynamically with distribution auto-correction to prevent premature convergence. |
| `forecast_4day.py` | 4-day regime forecast via Markov transition probabilities calibrated on history. Stabilizes signals: a regime change requires multiple consecutive confirmations. |
| `outcome_recorder.py` | Records the actual PnL result of each past decision. This is the link between prediction and reality: without this feedback, the ML cannot improve. |
| `rl_agent.py` | Tabular Q-learning agent. States = (pair, current regime, sentiment direction). Actions = (L-TF, S-TF, L-MR, S-MR). Learns an optimal policy from recorded outcomes. |
| `rl_continuous_training.py` | RL extension: also learns from unrealized PnL (still-open positions). Captures intra-trade dynamics rather than waiting for closure. |
| `meta_signal_resolver.py` | **Final arbiter**. Combines signals from 3 sources (ML, Forecast, RL) via weighted vote. Weights are learned dynamically (~41% ML, ~42% Forecast, ~17% RL). Produces the verdict: UNANIMOUS (3/3 agree), MAJORITY (2/3), or SPLIT (conflict → flat). |
| `pnl_tracker.py` | Real-time PnL tracking. Captures snapshots of each position every pipeline run. Computes hourly aggregates, detects trade closures, and feeds the circuit breaker and RL. |
| `atr_calculator.py` | Computes Average True Range (ATR) on H4 and D1 bars. ATR measures the average volatility of a pair. A typical stop-loss = 2× ATR H4. Used by position sizing to calibrate trade size. |
| `crowding_penalty.py` | Detects "crowding": when >70% of strategies are in the same direction on a pair. Applies a sizing penalty to reduce exposure. Includes a permanent A/B test (50% treatment / 50% control) to measure actual impact. |
| `sync_crowding_outcomes.py` | Syncs PnL results with crowding cohorts (treatment vs control) so the A/B test has reliable data. |
| `continuous_learning.py` | Meta-learning system: monitors ML model accuracy over time. If performance degrades (concept drift), triggers automatic retraining. Persists learning state in SQLite. |
| `data_integrity_guard.py` | Post-ingestion safeguard. Checks data consistency: zero-size positions, aberrant PnL, inconsistent timestamps. Automatically quarantines corrupted records to prevent ML contamination. |
| `regime_classifier.py` | Market regime classification (trend-following vs mean-reversion) based on technical characteristics (Hurst exponent, half-life, volatility ratio). |
| `discord_reporter.py` | Generates and sends the post-pipeline Discord report. Rich embeds: positions, PnL, regimes, MC16 strategies, diagnostics, accounts. |
| `generate_exhaustive_report_v4.py` | Generates the interactive HTML report (17 sections) published to IIS. Complete dashboard: positions, theories, ML, RL, forecast, sizing, history. |
| `generate_strategy_authorizations.py` | Generates the CSV file that authorizes or blocks each MultiCharts strategy. Directional filter: only strategies aligned with the meta-signal are authorized (8 out of 32). |
| `alert_system.py` | Multi-channel alert system (Discord, log). Notifies on critical events: drawdown, TWS disconnection, phase failure. |
| `market_guard.py` | Market safeguard: checks trading conditions (calendar, hours, macro events). Can suspend trading before NFP or a rate decision. |

### Pipeline Scripts (`scripts/`)

| File | Purpose |
|------|---------|
| `tws_health_check.py` | Probes the API ports of both TWS instances (7496/7497). Checks TCP connectivity + API response. If a TWS is down, the pipeline halts before producing signals on stale data. |
| `phase_gv_health.py` | Reads all 32 MultiCharts GlobalVariables via `GlobalVariable.dll`. Checks: AOE active, strategy alive (heartbeat < 4h), signal/position sync. |
| `fetch_ibkr_positions.py` | Connects to both TWS, enumerates all 8 accounts, fetches positions + equity + FX rates. Stores in `ibkr_positions` and `ibkr_account_metrics`. |
| `gv_position_xval.py` | IBKR↔GV cross-validation. If MultiCharts says "flat" but IBKR has a position (or vice versa) → desync alert. |
| `smart_position_sizing.py` | Sophisticated size calculation: (1) Risk-based via ATR (2% per trade), (2) Leverage constraint (max 2.5x equity), (3) 25K minimum, (4) Kelly confidence scaling. Produces `strategies_auth_simple.csv`. |
| `pnl_circuit_breaker.py` | Cascade protection: if daily drawdown exceeds -2% → 50% sizing reduction. If -5% → minimal sizing. If -10% → trading suspended. Prevents loss spirals. |
| `pipeline_diagnostics.py` | Comprehensive post-run health audit. Checks every component (scrapers, ML, RL, Meta, positions, equity, sizing). Produces CRIT/WARN/OK/INFO categories for Discord. |
| `mc16_health_monitor.py` | Continuous MC16 strategy monitoring: heartbeat, AOE status, last update. Alerts if a strategy stops responding. |
| `mc16_strategies_sync.py` | Syncs parameters between the pipeline and MultiCharts. Ensures all 32 strategies have correct parameters (pair, direction, sizing). |
| `mc16_discord_notifier.py` | MC16-specific Discord notifier: sends strategy statuses, signal changes, executions. |
| `liveboard_server.py` | Local web server (SSE) for the real-time dashboard. Pushes position/PnL updates to the browser without refresh. |
| `db_maintenance.py` | Automatic purge: `optimizer_samples` > 5M rows (48h retention), `pnl_realized` with size=0. VACUUM if >100K rows deleted. |

### Data Files

| File | Purpose |
|------|---------|
| `optimized_weights.json` | MCMC weights for the 22 theories (separate TF and MR). Updated every run. |
| `data/forex_regime.db` | Regime database: theory_scores, ml_classifications, forecasts, rl_recommendations, meta_signals, position_sizing. |
| `data/forex_sentiment.db` | Symlink to `ForexScraper/data/forex_sentiment.db`. |
| `reports/exhaustive_report.html` | Latest interactive HTML report. |

---

## ForexScraper — Data Collection

ForexScraper retrieves sentiment, COT, economic calendar, and market mover data from 7+1 web sources in real time.

### Orchestration

| File | Purpose |
|------|---------|
| `main.py` | Scraping entry point. Initializes the database, launches all 7 scrapers sequentially, produces the summary (successes/failures). |
| `scraper_runner.py` | Wrapper called by the pipeline. Locates and executes `main.py`. Handles timeout and return code. |

### Scrapers (`scrapers/`)

| Scraper | Source | Data | Frequency |
|---------|--------|------|-----------|
| `ig_com.py` | IG.com | Client sentiment (% long/short) for 8 pairs | Hourly |
| `dukascopy_sentiment.py` | Dukascopy | Retail sentiment via API (329 pairs available) | Hourly |
| `myfxbook.py` | Myfxbook | Community sentiment (outlook long/short) | Hourly |
| `marketbulls_seasonal.py` | MarketBulls.com | Monthly seasonal tendency (via Selenium) | Hourly |
| `insiderweek_cot.py` | InsiderWeek | COT net positions + COT index (via Jina AI reader) | Hourly |
| `cftc_historical.py` | CFTC | Historical COT data (updated weekly on Friday) | Hourly check |
| `dukascopy_movers.py` | Dukascopy | Relative currency strength (currency strength scores) | Hourly |
| `forexfactory_calendar.py` | ForexFactory | Economic calendar (high/medium impact events) | Hourly |

### Storage (`storage/`)

| File | Purpose |
|------|---------|
| `database.py` | SQLite abstraction layer. Manages connections, deduplication-based inserts (hash), scraper status, migrations. |
| `migrator.py` | Schema migration system (currently v8). Applies schema changes incrementally and reversibly. |

### Database

| File | Purpose |
|------|---------|
| `data/forex_sentiment.db` | Main scraped data database. Tables: `sentiments`, `calendar_events`, `cot_data`, `currency_strength`, `scraper_status`, `pnl_realized`, `pnl_snapshots`, `meta_signals`, `ml_classifications`, `optimizer_samples`, `pipeline_diagnostics`. |

---

## ForexRiskManagement — Risk Management

The RME (Risk Management Engine) bridges between the pipeline signals and actual IBKR execution.

| File | Purpose |
|------|---------|
| `risk_engine.py` | **Central engine**. Orchestrates the risk cycle: position verification, exposure calculation, order validation, force-close if needed. Runs in single-cycle mode (called by the pipeline) or continuous mode. |
| `ib_client.py` | IBKR TWS API client (ib_insync). Manages connections to both TWS instances, fetches positions, equity, places orders. Supports failover between DOM and VAL. |
| `multicharts_client.py` | Interface with MultiCharts 16 via GlobalVariable.dll. Reads/writes global variables to sync signals (direction, sizing, AOE) between the pipeline and MC16 strategies. |
| `config.py` | Centralized configuration: TWS ports, pairs, risk limits, alert thresholds, database paths. |
| `exposure_calculator.py` | Computes total exposure per account and per currency. Verifies leverage doesn't exceed limits (2.5x). Detects dangerous concentrations. |
| `position_sizer.py` | Low-level size calculation: converts the signal (direction + regime + confidence) into lot quantity, accounting for ATR, equity, and circuit breaker. |
| `forceclose_engine.py` | Emergency mechanism: automatically closes positions if drawdown exceeds critical thresholds or a major macro event is imminent. |
| `health_monitor.py` | RME self-health monitoring: uptime, API latency, connection errors, order queue. |
| `hybrid_client.py` | Hybrid IBKR+MC16 client. Coordinates both systems to avoid order conflicts (MC16 wants to open but IBKR wants to close). |
| `init_database.py` | Initializes the `risk_management.db` schema: positions, orders, health checks, metrics tables. |
| `bars_importer.py` | Imports OHLC bars from IBKR to feed ATR calculation and ML features when Yahoo Finance is unavailable. |
| `diagnostic.py` | Complete RME diagnostic: connection states, orphan positions, pending orders, desynchronizations. |
| `run_rme.py` | RME launcher script in single-cycle mode (called by the pipeline in post-processing). |

---

## MoneyProd — MultiCharts/DLL Bridge

MoneyProd bridges the Python world (pipeline) and the MultiCharts/C++ world (execution).

| File | Purpose |
|------|---------|
| `MoneyProdSupervisor.dll` | C++ DLL loaded by MultiCharts 16 as an external study. Reads GlobalVariables to retrieve pipeline signals, checks authorizations in the CSV, and controls order execution. It's the "gatekeeper" that prevents MC16 from trading without pipeline authorization. |
| `MoneyProdSupervisor.cpp` | C++ source for the DLL. Interfaces with the MultiCharts Study Editor 4.0w API. |
| `strategies_auth_simple.csv` | **Critical file**. Lists all 32 strategies with their status (AUTHORIZED/BLOCKED). Only strategies aligned with the meta-signal are authorized (typically 8/32). Updated by `smart_position_sizing.py` every run. Format: `account,pair,strategy_id,direction,regime,size,status`. |
| `exhaustive_report.html` | Report copy for the IIS server (moneyprod.com). |

---

## Scraper — Supplementary Sources (Legacy)

The `Scraper/` directory contains historical scrapers for less frequent data (detailed COT, OECD, in-depth seasonality). These scrapers are orchestrated by `run_all.py` and run independently from the main pipeline.

| Subdirectory | Purpose |
|---|---|
| `code/` | OECD scrapers (PPP, interest rates), advanced Dukascopy, MarketBulls seasonality |
| `forexclientsentiment/` | FCS (ForexClientSentiment) scraper with cookie management and DOM parsing |
| `forexfactory/` | Advanced ForexFactory scraper (calendar with HTML parsing) |
| `market_bulls/` | MarketBulls seasonality scraper (Selenium, chart extraction) |
| `Duka/` | Advanced Dukascopy scrapers (intraday movers, ranking) |
| `run_all.py` | Orchestrator for all supplementary scrapers |

---

## SQLite Databases

The system uses 3 SQLite databases, all synchronized to New York timezone (EST/EDT).

### `forex_sentiment.db` (ForexScraper)

The largest database (~314 MB). Contains all scraped data and intermediate results.

| Table | Purpose | Volume |
|-------|---------|--------|
| `sentiments` | Retail sentiment by source/pair/timestamp | ~50K rows |
| `calendar_events` | ForexFactory economic events | ~11K rows |
| `cot_data` | COT net positions + index | ~5K rows |
| `currency_strength` | Dukascopy relative strength | ~10K rows |
| `theory_scores` | Scores for all 22 theories per pair | ~8 rows (latest) |
| `ml_classifications` | ML ensemble results | ~1.5K rows |
| `meta_signals` | Final signals from the Meta-Signal Resolver | ~8K rows |
| `optimizer_samples` | Bayesian Optimizer MCMC chains | ~2.5M rows (purged at 48h) |
| `pnl_snapshots` | PnL snapshots per position | ~600 rows |
| `pnl_realized` | Closed trades with actual PnL | ~100 rows |
| `pipeline_diagnostics` | Diagnostic results per run | latest run only |
| `scraper_status` | Status of each scraper (last run, success/failure) | ~10 rows |
| `rl_experiences` | RL experiences (state, action, reward) | ~3K rows |

### `forex_regime.db` (ForexRegime)

Regime and decision database.

| Table | Purpose |
|-------|---------|
| `ohlc_bars` | H4 OHLC bars (Yahoo Finance + IBKR fallback) |
| `atr_values` | Computed ATR per pair/timeframe |
| `ibkr_positions` | Live IBKR positions |
| `ibkr_account_metrics` | Equity and metrics per account |
| `ibkr_executions` | Execution history |
| `fx_rates_cache` | Exchange rates (166 currencies) |
| `strategy_assignments` | Direction+regime assignments per pair |
| `position_sizing` | Computed sizes per account/pair |
| `crowding_decisions` | Crowding decisions with A/B cohort |
| `learning_state` | Continuous learning state (model version, accuracy) |
| `rl_qtable` | RL agent Q-table |

### `risk_management.db` (ForexRiskManagement)

Risk layer database.

| Table | Purpose |
|-------|---------|
| `health_checks` | TWS health check results |
| `risk_events` | Risk events (circuit breaker, force close) |
| `order_history` | Order history |
| `gv_telemetry` | MC16 GlobalVariable telemetry |

---

## Discord Reporter — Real-Time Monitoring

The Discord reporter (`discord_reporter.py`) sends 2 messages after each pipeline run:

### Message 1: Pipeline Status

```
✅ Pipeline Complete — All phases OK
```
or
```
❌ Pipeline FAILED — Check logs immediately
```

### Message 2: Full Report (embeds)

| Section | Content |
|---------|---------|
| **Header** | Date, total equity, snap PnL, account/position count |
| **Regimes** | Direction + regime + confidence for all 8 pairs |
| **MC16 Strategies** | 32/32 AOE, synced, PnL per pair |
| **System & Accounts** | SQLite, ATR, IBKR, Meta, RL status |
| **DOM/VAL** | Equity per account (4+4) |
| **Action Required** | CRIT/WARN items needing human attention |

### Alert Levels

| Level | Color | Meaning |
|-------|-------|---------|
| All Systems Normal | 🟢 Green | Everything working, 0 WARN |
| Warnings | 🟡 Yellow | Non-critical warnings (e.g., RL 5/8) |
| CRITICAL | 🔴 Red | Immediate action required |

---

## Data Flow Diagram

```
                        ┌─────────────────────────────────────┐
                        │       CRON (every hour, 24/7)       │
                        │    unified_pipeline.py (24 phases)  │
                        └─────────────┬───────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              ▼                       ▼                       ▼
    ┌─────────────────┐   ┌─────────────────┐    ┌──────────────────┐
    │   DATA LAYER    │   │  SIGNAL LAYER   │    │ EXECUTION LAYER  │
    │                 │   │                 │    │                  │
    │ • IBKR Positions│   │ • 22 Theories   │    │ • ATR Sizing     │
    │ • 8 Scrapers    │   │ • ML Ensemble   │    │ • Circuit Breaker│
    │ • PnL Tracking  │   │ • Bayesian Opt  │    │ • Auth CSV       │
    │ • Integrity Chk │   │ • 4-Day Forecast│    │ • MC16 GV Sync   │
    │                 │   │ • RL Agent      │    │ • IBKR Orders    │
    │                 │   │ • Meta-Resolver │    │                  │
    └────────┬────────┘   └────────┬────────┘    └────────┬─────────┘
             │                     │                      │
             ▼                     ▼                      ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                     SQLite (3 databases)                        │
    │  forex_sentiment.db  │  forex_regime.db  │  risk_management.db │
    └─────────────────────────────────────────────────────────────────┘
             │                     │                      │
             ▼                     ▼                      ▼
    ┌──────────────┐   ┌──────────────────┐    ┌──────────────────┐
    │   REPORTING  │   │  LEARNING LOOP   │    │   RISK MGMT      │
    │              │   │                  │    │                  │
    │ • Discord    │   │ • Outcomes → ML  │    │ • RME Engine     │
    │ • IIS Report │   │ • PnL → RL      │    │ • Exposure Calc  │
    │ • Diagnostics│   │ • A/B Crowding   │    │ • Force Close    │
    │              │   │ • Weight Update  │    │ • Health Monitor │
    └──────────────┘   └──────────────────┘    └──────────────────┘
```

---

## Infrastructure

### Server

| Component | Details |
|-----------|---------|
| OS | Windows Server 2022 (21H2) |
| Timezone | America/New_York (EST5EDT) |
| Python | 3.14.3 |
| PowerShell | 7.5.4 |
| MultiCharts | 16.0 (Study Editor 4.0w) |
| IBKR TWS | Latest (2 instances: DOM port 7496, VAL port 7497) |
| IIS | Hosts the HTML report on moneyprod.com |
| SQLite | All data centralized (no DB server) |

### Cron / Scheduler

The pipeline runs via Windows Task Scheduler:
- **Frequency**: Every hour (24/7)
- **Command**: `powershell -Command "cd C:\ForexRegime; python unified_pipeline.py"`
- **Typical duration**: ~3-4 minutes per run

### Monitoring

| Channel | Usage |
|---------|-------|
| Discord (webhook) | Real-time alerts, post-pipeline report |
| IIS (moneyprod.com) | Interactive HTML dashboard |
| Logs (`ForexRegime/logs/`) | Complete history of each run |
| Liveboard (SSE) | Local real-time dashboard |

---

## License

Proprietary. All rights reserved.
