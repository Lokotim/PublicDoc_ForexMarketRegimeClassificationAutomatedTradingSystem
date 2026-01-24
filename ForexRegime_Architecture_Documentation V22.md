# ForexRegime Unified Pipeline

> **Complete Architecture Documentation**  
> Machine Learning • Reinforcement Learning • Bayesian Optimization

---

| Attribute | Value |
|-----------|-------|
| Document Version | 22.0 |
| Pipeline Version | 4.0 |
| Date | January 23, 2026 |
| Environment | Windows Server 2022 (21H2) |
| Python Version | 3.14.2 |
| Database | SQLite 3.x (forex_data.db) |
| Timezone | America/New_York (EST/EDT) |

### System Specifications

| 11 | 22 | 8 | 7+ |
|:--:|:--:|:--:|:--:|
| Pipeline Phases | Trading Theories | Currency Pairs | Data Sources |

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. System Architecture Overview](#2-system-architecture-overview)
- [3. Phase 1a: FXSSI Sentiment Scraping](#3-phase-1a-fxssi-sentiment-scraping)
- [4. Phase 1b: Multi-Source Data Scraping](#4-phase-1b-multi-source-data-scraping)
- [5. Phase 2: Theory Calculations (22 Theories)](#5-phase-2-theory-calculations-22-theories)
- [6. Phase 3: ML Classifier (Regime Detection)](#6-phase-3-ml-classifier-regime-detection)
- [7. Phase 4: Bayesian MCMC Optimizer](#7-phase-4-bayesian-mcmc-optimizer)
- [8. Phase 5: 4-Day Forecasting System](#8-phase-5-4-day-forecasting-system)
- [9. Phase 6: Outcome Recording](#9-phase-6-outcome-recording)
- [10. Phase 7: Reinforcement Learning Agent](#10-phase-7-reinforcement-learning-agent)
- [11. Phase 8: Crowding Penalty System](#11-phase-8-crowding-penalty-system)
- [12. Phase 9: Continuous Learning Metrics](#12-phase-9-continuous-learning-metrics)
- [13. Phase 10: Exhaustive Report Generation](#13-phase-10-exhaustive-report-generation)
- [14. External Integrations](#14-external-integrations)
- [15. Database Schema & Data Flow](#15-database-schema--data-flow)
- [16. Risk Management Engine (RME)](#16-risk-management-engine-rme)
- [17. Appendices](#17-appendices)

---

## 1. Executive Summary

The ForexRegime Unified Pipeline is a sophisticated quantitative trading system that combines real-time sentiment analysis, machine learning regime detection, Bayesian optimization, and reinforcement learning to generate actionable trading signals across 8 major currency pairs. The system processes data from 7+ external sources, calculates 22 distinct trading theories, and produces optimized strategy assignments updated every execution cycle.

### 1.1 Core Objectives

- **Regime Detection**: Classify market conditions as Trend-Following (TF) or Mean-Reverting (MR) using an ensemble of 22 quantitative theories weighted by Bayesian MCMC optimization.
- **Adaptive Strategy Selection**: Dynamically assign optimal trading strategies based on current market regime, sentiment confluence, and momentum indicators.
- **Risk Management**: Integrate real-time ATR calculations from IBKR, position sizing, and crowding penalties to manage portfolio risk.
- **Continuous Learning**: Employ reinforcement learning (Q-learning) to improve strategy selection based on historical outcome feedback.
- **Production Reporting**: Generate comprehensive HTML reports published to IIS web server with Discord notifications for real-time monitoring.

### 1.2 Key Performance Indicators

| Metric | Value | Description |
|--------|-------|-------------|
| Pipeline Duration | ~2 minutes | Full 11-phase execution time |
| Data Points Processed | 63,655 | Total data points in report |
| Scraper Success Rate | 100% | 41/41 items scraped successfully |
| Regime Stability | 100% | No transitions in current run |
| TF/MR Distribution | 37.5%/62.5% | 3 TF, 5 MR assignments |
| MCMC Acceptance Rate | 100% | Bayesian optimizer convergence |

---

## 2. System Architecture Overview

The ForexRegime system follows a modular, pipeline-based architecture where each phase processes data sequentially, storing intermediate results in a centralized SQLite database. This design ensures data consistency, enables auditability, and allows for independent testing of each component.

### 2.1 Pipeline Execution Flow

| Phase | Name | Script | Output |
|-------|------|--------|--------|
| 1a | FXSSI Sentiment | `scraper_fxssi.py` | 16 pairs sentiment |
| 1b | Multi-Source Scraping | `scraper_runner.py` | 41 data records |
| 2 | Theory Calculations | `calculate_theories.py` | 22 theories × 8 pairs |
| 3 | ML Classifier | `ml_classifier.py` | TF/MR regime labels |
| 4 | Bayesian Optimizer | `bayesian_optimizer.py` | Optimized weights |
| 5 | 4-Day Forecast | `forecast_4day.py` | 40 forecasts |
| 6 | Outcome Recording | `outcome_recorder.py` | Performance metrics |
| 7 | RL Training | `rl_agent.py` | Q-table updates |
| 8 | Crowding Penalty | `crowding_penalty.py` | Adjusted signals |
| 9 | Continuous Learning | `continuous_learning.py` | Learning metrics |
| 10 | Report Generation | `generate_exhaustive_report_v4.py` | HTML report |

### 2.2 Directory Structure

```
C:\ForexRegime\
├── unified_pipeline.py          # Main orchestrator
├── calculate_theories.py        # 22 theory calculations
├── ml_classifier.py             # Regime classification (V7)
├── bayesian_optimizer.py        # MCMC weight optimization
├── forecast_4day.py             # Multi-day forecasting
├── outcome_recorder.py          # Performance tracking
├── rl_agent.py                  # Q-learning agent
├── crowding_penalty.py          # A/B testing penalties
├── forex_data.db                # SQLite database
├── optimized_weights.json       # Bayesian output
└── scrapers\                    # Data collection modules
```

### 2.3 Technology Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| Language | Python 3.14.2 | Core pipeline logic |
| Database | SQLite 3.x | Centralized data storage |
| Web Scraping | Playwright, Selenium, Requests | Multi-source data collection |
| ML/Statistics | NumPy, SciPy, scikit-learn | Calculations and classification |
| Broker API | IBKR TWS API | Real-time prices and ATR |
| Charting | MultiChart 16.0 | Signal visualization |
| Web Server | IIS (Windows) | Report hosting |
| Notifications | Discord Webhooks | Alert delivery |
| Scheduling | Windows Task Scheduler | Automated execution |

---

## 3. Phase 1a: FXSSI Sentiment Scraping

FXSSI (Forex Sentiment & Strategy Index) provides retail trader positioning data showing the percentage of traders long vs short for each currency pair. This contrarian indicator is valuable because retail traders are often wrong at market extremes.

### 3.1 Data Source

| Attribute | Value |
|-----------|-------|
| URL | https://fxssi.com/current-forex-sentiment |
| Pairs Covered | 16 major and cross pairs |
| Update Frequency | Real-time (scraped each run) |
| Data Format | Long%/Short% ratios |
| Scraping Method | Playwright (headless browser) |

### 3.2 Sentiment Calculation

The raw Long%/Short% data is converted to a normalized sentiment score ranging from -1.0 (extremely bearish) to +1.0 (extremely bullish):

```
sentiment = (Long% - Short%) / 100

Example: AUDUSD with 16% Long / 84% Short
→ sentiment = (16 - 84) / 100 = -0.68
```

### 3.3 Sample Output (January 23, 2026)

| Pair | Long% | Short% | Sentiment | Interpretation |
|------|-------|--------|-----------|----------------|
| AUDJPY | 25% | 75% | -0.50 | Bearish crowd |
| AUDUSD | 16% | 84% | -0.68 | Very bearish crowd |
| EURAUD | 72% | 28% | +0.44 | Bullish crowd |
| EURGBP | 51% | 49% | +0.02 | Neutral |
| EURUSD | 28% | 72% | -0.44 | Bearish crowd |
| USDCHF | 85% | 15% | +0.70 | Very bullish crowd |
| XAUUSD | 62% | 38% | +0.24 | Mildly bullish |

### 3.4 Contrarian Usage

FXSSI sentiment is used as a contrarian indicator in the theory calculations. When retail traders are extremely positioned in one direction (|sentiment| > 0.60), this often signals an impending reversal.

**Trading Logic:**
- `Sentiment < -0.60` → Contrarian bullish signal
- `Sentiment > +0.60` → Contrarian bearish signal
- `-0.60 ≤ Sentiment ≤ +0.60` → No strong signal

---

## 4. Phase 1b: Multi-Source Data Scraping

The ForexScraper module orchestrates data collection from 7 distinct sources, each providing unique market insights.

### 4.1 Data Sources Overview

| Source | Type | Method | Data Provided | Pairs |
|--------|------|--------|---------------|-------|
| IG.com | Broker Sentiment | Playwright | Client positioning | 8 |
| Dukascopy | Broker Sentiment | REST API | Trader sentiment | 338 |
| MyFXBook | Retail Sentiment | Playwright | Community positions | 72 |
| MarketBulls | Seasonality | Selenium | Historical patterns | 12 |
| CFTC | COT Report | CSV Download | Institutional positions | 8 |
| Dukascopy Movers | Currency Strength | REST API | Relative strength | 8 |
| ForexFactory | Calendar | JSON API | Economic events | All |

### 4.2 IG.com Sentiment Scraper

IG Group publishes client positioning data showing the percentage of their clients who are long vs short on each instrument.

| Pair | Net Position | Interpretation |
|------|--------------|----------------|
| EURUSD | -8.0 | Slight majority short |
| USDJPY | -22.0 | Moderate short bias |
| USDCHF | +66.0 | Strong long bias |
| AUDUSD | -6.0 | Slight majority short |

### 4.3 Dukascopy Sentiment API

Dukascopy Bank provides sentiment data via a REST API endpoint that returns positioning for over 330 instruments.

```
API Endpoint: https://freeserv.dukascopy.com/2.0/index.php?...

sentiment = (long_volume - short_volume) / (long_volume + short_volume) × 100
```

### 4.4 MyFXBook Community Outlook

MyFXBook aggregates positioning data from thousands of trading accounts connected to their platform.

> **Note:** MyFXBook uses volume-weighted positioning, which means accounts with larger positions have more influence on the aggregate sentiment reading.

### 4.5 MarketBulls Seasonal Patterns

MarketBulls provides seasonal tendency data showing historical price changes for specific calendar periods.

| Pair | Seasonal Change | Interpretation |
|------|-----------------|----------------|
| EURUSD | -0.0094 | Historically weak this period |
| GBPUSD | +0.0030 | Slight historical strength |
| USDJPY | -0.5400 | Yen typically strengthens |
| EURJPY | -1.6506 | Strong historical decline |

### 4.6 CFTC Commitments of Traders (COT)

The CFTC COT report provides weekly positioning data for institutional traders (commercials, large speculators, small speculators) in currency futures markets.

> **Update Frequency:** Weekly (released Friday for Tuesday data). The scraper maintains a local cache and only re-downloads when new data is available.

### 4.7 Dukascopy Currency Strength (Movers)

Currency strength scores measure the relative performance of individual currencies against a basket.

| Currency | Strength Score | Pair Calculation | Result |
|----------|---------------|------------------|--------|
| EUR | +103.24 | EURUSD = EUR - USD | +145.58 |
| GBP | +59.42 | GBPUSD = GBP - USD | +101.77 |
| USD | -42.35 | USDJPY = USD - JPY | -2.48 |
| JPY | -39.86 | EURJPY = EUR - JPY | +143.10 |

---

## 5. Phase 2: Theory Calculations (22 Theories)

The heart of the ForexRegime system is its calculation of 22 distinct quantitative theories, each providing a different perspective on market conditions.

### 5.1 Theory Categories

| Category | Theories | Purpose |
|----------|----------|---------|
| Sentiment | 4 | Retail/institutional positioning |
| Momentum | 4 | Price trend direction and strength |
| Mean Reversion | 4 | Overbought/oversold conditions |
| Volatility | 3 | Market regime detection |
| Seasonal | 2 | Historical calendar patterns |
| Carry Trade | 2 | Interest rate differentials |
| Technical | 3 | Price pattern recognition |

### 5.2 Complete Theory List

| # | Theory Name | Signal Range | Description |
|---|-------------|--------------|-------------|
| 1 | fxssi_sentiment | [-1, +1] | FXSSI retail positioning |
| 2 | ig_sentiment | [-100, +100] | IG client sentiment |
| 3 | dukascopy_sentiment | [-100, +100] | Dukascopy trader sentiment |
| 4 | myfxbook_sentiment | [-100, +100] | MyFXBook community outlook |
| 5 | sentiment_confluence | [-1, +1] | Weighted average of all sentiment |
| 6 | rsi_14 | [0, 100] | 14-period RSI |
| 7 | rsi_divergence | [-1, +1] | Price vs RSI divergence |
| 8 | macd_histogram | Continuous | MACD histogram value |
| 9 | macd_signal | [-1, +1] | MACD crossover signal |
| 10 | bollinger_position | [-1, +1] | Position within Bollinger Bands |
| 11 | bollinger_squeeze | [0, 1] | Band width percentile |
| 12 | atr_percentile | [0, 100] | ATR relative to history |
| 13 | volatility_regime | [0, 1] | High/low volatility classification |
| 14 | trend_strength | [-1, +1] | ADX-based trend strength |
| 15 | price_momentum | [-1, +1] | Rate of change normalized |
| 16 | seasonal_tendency | Pips | Historical seasonal move |
| 17 | seasonal_direction | [-1, +1] | Seasonal bias direction |
| 18 | cot_positioning | [-1, +1] | Institutional position change |
| 19 | cot_extreme | [0, 1] | Position percentile vs history |
| 20 | carry_differential | Continuous | Interest rate spread |
| 21 | currency_strength | [-200, +200] | Relative strength score |
| 22 | correlation_regime | [-1, +1] | Correlation to risk assets |

### 5.3 Theory Calculation Details

#### 5.3.1 Sentiment Confluence

Sentiment Confluence combines all sentiment sources with dynamic weighting based on data freshness and source reliability:

```
sentiment_confluence = (w₁ × fxssi + w₂ × ig + w₃ × dukascopy + w₄ × myfxbook) / Σw

Data age penalty: w = w₀ × exp(-age_minutes / 120)
```

#### 5.3.2 Volatility Regime Detection

The volatility regime theory uses ATR percentile ranking:

```
atr_percentile = percentile_rank(ATR_14, lookback=252 days)

volatility_regime = 1 if atr_percentile > 70 else 0 if atr_percentile < 30 else 0.5
```

#### 5.3.3 Trend Strength Calculation

Trend strength combines ADX with directional indicators:

```
direction = +1 if +DI > -DI else -1
strength = (ADX - 20) / 80  # Normalized to [0, 1]
trend_strength = direction × min(strength, 1.0)
```

---

## 6. Phase 3: ML Classifier (Regime Detection)

The ML Classifier V7 is the core decision engine that determines whether each currency pair is in a Trend-Following (TF) or Mean-Reverting (MR) regime.

### 6.1 Classification Algorithm

1. **Score Calculation**: Weighted sum of 22 theory values using Bayesian-optimized weights
2. **Dynamic Balancing**: Apply balance factors to correct historical TF/MR distribution bias
3. **Hysteresis**: Only transition if score difference exceeds threshold + hysteresis band
4. **Minimum Hold**: Maintain regime assignment for minimum 4 hours to prevent whipsaws
5. **Confidence**: Calculate confidence as |TF - MR| / max(|TF|, |MR|)

### 6.2 Configuration Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| margin | 0.08 | Minimum score difference for regime assignment |
| hysteresis | 0.05 | Additional buffer to prevent rapid transitions |
| min_hold | 4 hours | Minimum time before regime can change |
| tf_balance_factor | 1.30 | Multiplier to increase TF sensitivity |
| mr_balance_factor | 0.81 | Multiplier to decrease MR sensitivity |

### 6.3 Sample Classification Output

| Pair | Previous | Current | Hold Time | TF Score | MR Score | Confidence |
|------|----------|---------|-----------|----------|----------|------------|
| EURUSD | MR | MR | 0.1h | +0.607 | 0.696 | 67.9% |
| USDJPY | TF | TF | 0.1h | +0.777 | 0.638 | 77.8% |
| GBPUSD | TF | TF | 0.1h | +0.908 | 0.593 | 100.0% |
| USDCHF | MR | MR | 0.1h | -0.887 | 0.706 | 86.2% |
| AUDUSD | MR | MR | 0.1h | -0.434 | 0.566 | 76.3% |
| USDCAD | MR | MR | 0.1h | -0.788 | 0.686 | 70.3% |
| EURJPY | TF | TF | 0.1h | +0.947 | 0.748 | 89.9% |
| AUDJPY | MR | MR | 0.1h | +0.432 | 0.731 | 100.0% |

### 6.4 Regime Interpretation

**Trend-Following (TF) Regime:**  
The market is trending. Strategies should buy breakouts, trail stops, and let winners run. Key indicators: strong ADX, expanding Bollinger Bands, sentiment alignment with price direction.

**Mean-Reverting (MR) Regime:**  
The market is ranging. Strategies should fade moves to extremes, use tight profit targets, and expect reversions to mean. Key indicators: low ADX, contracting Bollinger Bands, extreme sentiment readings.

---

## 7. Phase 4: Bayesian MCMC Optimizer

The Bayesian Optimizer uses Markov Chain Monte Carlo (MCMC) sampling to find optimal weights for combining the 22 theories.

### 7.1 MCMC Algorithm

The optimizer implements Metropolis-Hastings sampling:

```
1. Initialize weights from previous run (or uniform if first run)
2. For each iteration:
   a. Propose new weights by adding Gaussian noise to current weights
   b. Calculate performance score for proposed weights
   c. Accept with probability min(1, exp(β × (new_score - old_score)))
   d. Update weights if accepted
3. After burn-in period, collect accepted samples
4. Final weights = mean of accepted samples
```

### 7.2 Performance Metric

The optimizer maximizes a composite performance metric:

```
performance = accuracy × (1 - distribution_penalty)

Where:
  accuracy = correlation(predicted_returns, actual_returns)
  distribution_penalty = |TF_count/total - 0.5| if > threshold else 0
```

### 7.3 Optimization Results

| Metric | Value |
|--------|-------|
| MCMC Iterations | 1000 |
| Burn-in Period | 200 |
| Acceptance Rate | 100% |
| Final Performance | 0.230 |
| Convergence | Achieved |

---

## 8. Phase 5: 4-Day Forecasting System

The 4-Day Forecasting System projects regime probabilities and strategy assignments over a multi-day horizon.

### 8.1 Methodology

The system uses Markov chain modeling:

```
P(regime_t+n | regime_t) = T^n × π_t

Where:
  T = 2×2 transition probability matrix
  π_t = current regime probability distribution
  n = forecast horizon in days
```

### 8.2 Strategy Assignment Output

| Pair | Direction | Strategy | Confidence |
|------|-----------|----------|------------|
| EURUSD | Short | mean_reversion | 42.66% |
| USDJPY | Long | trend_following | 28.11% |
| GBPUSD | Long | trend_following | 33.39% |
| USDCHF | Short | trend_following | 39.38% |
| AUDUSD | Long | mean_reversion | 24.58% |
| USDCAD | Short | mean_reversion | 46.14% |
| EURJPY | Long | trend_following | 55.77% |
| AUDJPY | Long | mean_reversion | 55.77% |

---

## 9. Phase 6: Outcome Recording

The Outcome Recorder tracks the performance of strategy assignments after a 96-hour (4-day) holding period.

### 9.1 Performance Summary

| Strategy | Trades | Win Rate | Avg Return | Sharpe Ratio |
|----------|--------|----------|------------|--------------|
| L mean_reversion | 1 | 100.0% | +5.12% | +2.05 |
| S mean_reversion | 1 | 100.0% | +4.97% | +1.99 |
| L trend_following | 5 | 80.0% | +2.60% | +0.99 |
| S trend_following | 1 | 0.0% | -2.12% | -0.71 |

---

## 10. Phase 7: Reinforcement Learning Agent

The RL Strategy Agent uses Q-learning to improve strategy selection over time based on recorded outcomes.

### 10.1 Q-Learning Implementation

- **State Space**: 4 discrete states based on current regime and confidence level
- **Action Space**: 2 actions (select TF strategy, select MR strategy)
- **Reward**: Actual P&L from strategy after 96-hour hold period

```
Q-Update Rule:
Q(s,a) ← Q(s,a) + α × [r + γ × max(Q(s',a')) - Q(s,a)]

Where: α=0.1 (learning rate), γ=0.95 (discount factor)
```

### 10.2 Current Q-Table Status

The agent maintains Q-values for each state-action pair. Current recommendations show Q=0.000 for all pairs, indicating insufficient training data. As outcomes accumulate, the Q-values will diverge to reflect learned preferences.

---

## 11. Phase 8: Crowding Penalty System

The Crowding Penalty System implements A/B testing to measure the effectiveness of sentiment-based position adjustments.

**Current Status:**
- Balanced distribution (TF=37.5%, MR=62.5%)
- A/B testing: 50% treatment, 50% control
- Learning threshold: 50+ outcomes required for auto-adjustment

---

## 12. Phase 9: Continuous Learning Metrics

The Continuous Learning module aggregates performance metrics across all pipeline components to detect model degradation, data quality issues, and regime shift patterns.

---

## 13. Phase 10: Exhaustive Report Generation

The final phase generates a comprehensive HTML report with 12 sections and 63,655 data points.

| Output Location | Purpose |
|-----------------|---------|
| `C:/ForexRegime/reports/exhaustive_report.html` | Local archive |
| `C:/MoneyProd/exhaustive_report.html` | Production backup |
| `C:/inetpub/wwwroot/moneyprod/exhaustive_report.html` | IIS web server |

---

## 14. External Integrations

### 14.1 IBKR TWS Integration

Interactive Brokers TWS provides real-time price data for ATR calculations and position monitoring.

| Feature | Implementation |
|---------|----------------|
| Connection | TWS on localhost:7497 |
| Data Type | Real-time bars (1-minute) |
| ATR Calculation | 14-period ATR from 4H bars |
| Update Frequency | On pipeline execution |

### 14.2 MultiChart 16.0 Integration

MultiChart receives regime signals and generates visual overlays on price charts.

```
Signal Flow:
1. Pipeline writes to strategies_authorization.csv
2. MultiChart Study reads CSV on timer
3. Study applies regime-appropriate indicator settings
4. Visual overlay shows TF/MR zones on chart
```

### 14.3 Discord Notifications

Real-time notifications are sent to Discord via webhooks:
- Pipeline execution status and timing
- Regime transitions with confidence levels
- Account equity updates from IBKR
- Data freshness alerts (ATR age, regime age)
- Error notifications for scraper failures

### 14.4 IIS Web Server

The exhaustive HTML report is published to IIS for remote monitoring at moneyprod.com.

---

## 15. Database Schema & Data Flow

All pipeline data flows through the centralized SQLite database (`forex_data.db`). The schema is maintained at version 8 with automatic migration support.

### 15.1 Core Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| sentiment_data | Raw sentiment from scrapers | pair, source, sentiment, timestamp |
| seasonal_data | Seasonal patterns | pair, period, expected_change |
| calendar_events | Economic events | datetime, currency, impact, event |
| theory_scores | Calculated theories (wide) | pair, timestamp, theory_1...theory_22 |
| ml_regime | Regime classifications | pair, regime, confidence, timestamp |
| forecasts | Multi-day projections | pair, horizon, probability, strategy |
| outcomes | Strategy performance | pair, strategy, pnl, sharpe |
| q_table | RL agent state | state, action, q_value |
| scraper_status | Execution monitoring | scraper, status, timestamp, items |

---

## 16. Risk Management Engine (RME)

The Risk Management Engine calculates position sizes, monitors account health, and enforces risk limits.

### 16.1 Position Sizing Formula

```
Position Size = (Account Equity × Risk%) / (ATR × ATR_Multiplier)

Where:
  Risk% = 1% per trade
  ATR = 14-period Average True Range from IBKR
  ATR_Multiplier = 2.0 (stop distance in ATR units)
```

### 16.2 Current Account Status

| Metric | Value |
|--------|-------|
| Accounts Monitored | 8 |
| Account Ages | 150 min each |
| ATR Data Age | 300 min |
| Regime Data Age | 0 min (fresh) |

---

## 17. Appendices

### 17.1 Glossary

| Term | Definition |
|------|------------|
| TF | Trend-Following regime - market is trending |
| MR | Mean-Reverting regime - market is ranging |
| ATR | Average True Range - volatility measure |
| MCMC | Markov Chain Monte Carlo - sampling algorithm |
| COT | Commitments of Traders - CFTC positioning report |
| ADX | Average Directional Index - trend strength |
| RSI | Relative Strength Index - momentum oscillator |
| Q-Learning | Reinforcement learning algorithm |

### 17.2 Execution Command

```powershell
cd C:\ForexRegime && python unified_pipeline.py
```

### 17.3 Scheduled Tasks

- **ForexPipeline** - Hourly execution of `unified_pipeline.py`
- **ForexBackup** - Daily backup at 00:00 (`daily_backup.py`)

---

*--- End of Document ---*
