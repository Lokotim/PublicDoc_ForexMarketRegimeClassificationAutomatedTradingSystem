# MoneyProd - System Architecture

**Autonomous Institutional-Grade FX Trading Pipeline**

Combining ML Ensemble, Bayesian Optimization, Reinforcement Learning, Implied Volatility Analysis, and Real-Time Risk Management

| Metric | Value |
|---|---|
| Pipeline Phases | 30+ |
| ML Models | 5 MoE |
| Currency Pairs | 8 |
| Features / Pair | 117 |
| Trading Accounts | 8 |
| Data Sources | 7 |
| Databases | 3 |
| Active Strategies | 32 |

**Author:** Timothy Lokotar
- [LinkedIn](https://linkedin.com/in/timothy-lokotar/)
- [MoneyProd](https://www.moneyprod.com/)

> Production System | Live Trading | Real Broker Integration
> Technical Architecture Document | February 2026

---

## Table of Contents

1. [Executive Summary](#01-executive-summary)
2. [High-Level Architecture](#02-high-level-architecture)
3. [Data Collection Layer](#03-data-collection-layer)
4. [Feature Engineering](#04-feature-engineering)
5. [ML Strategy Ensemble](#05-ml-strategy-ensemble)
6. [Bayesian Optimizer](#06-bayesian-optimizer)
7. [Reinforcement Learning Agent](#07-reinforcement-learning-agent)
8. [Meta-Signal Resolver](#08-meta-signal-resolver)
9. [4-Day Forecast System](#09-4-day-forecast-system)
10. [Implied Volatility Surface](#10-implied-volatility-surface)
11. [Position Sizing & Kelly Criterion](#11-position-sizing--kelly-criterion)
12. [Risk Management Framework](#12-risk-management-framework)
13. [Database Architecture](#13-database-architecture)
14. [Live Monitoring & Observability](#14-live-monitoring--observability)
15. [Continuous Learning System](#15-continuous-learning-system)
16. [Pipeline Execution Timeline](#16-pipeline-execution-timeline)

---

## 01. Executive Summary

MoneyProd is a production-grade, fully autonomous foreign exchange trading system that operates on an 8-pair portfolio (EURUSD, USDJPY, GBPUSD, USDCHF, AUDUSD, USDCAD, EURJPY, AUDJPY) across 8 live brokerage accounts. The system executes a 30+ phase unified pipeline every hour, integrating 7 real-time data sources, a 5-model Mixture of Experts (MoE) classifier, Bayesian weight optimization via MCMC, a Q-learning reinforcement learning agent, and a multi-layered risk management framework.

The pipeline produces a strategy authorization CSV consumed by 32 live strategies running on a charting platform connected to Interactive Brokers via dual IB Gateway instances. The entire system is designed with non-circular data flow: raw data feeds all models, but models never feed back into feature calculation, preventing data leakage and feedback loops.

### Design Principles

- **Non-circular data flow:** Features feed all models; models never feed back into feature calculation
- **Safety-first:** Multiple circuit breakers, position reconciliation, and graceful degradation
- **Real data only:** No synthetic fallbacks; the system skips pairs without genuine data
- **Hourly retraining:** Walk-forward validation with 2-bar gap prevents temporal leakage
- **Modular pipeline:** 8 sequential stages with internal parallelism, ~191 seconds total
- **Multi-account diversification:** 8 accounts with 4 strategies each = 32 strategy slots

### System Overview Flow

```
7 Data Sources (IG, Dukascopy, Myfxbook, FXSSI, MarketBulls, CFTC, ForexFactory)
    |
    v
Feature Engineering: 117 features / pair across 20 categories
    |
    v
ML Strategy Ensemble: 5-Model Mixture of Experts
    |
    v
Bayesian Optimizer (MCMC) + RL Agent (Q-Learning) + 4-Day Forecast
    |
    v
Meta-Signal Resolver: 3-source conflict arbitration
    |
    v
Smart Position Sizing: Kelly + ATR + IV + Circuit Breaker
    |
    v
32 Live Strategies on 8 Accounts via Broker API
```

### Technology Stack

| Component | Technology | Purpose |
|---|---|---|
| Broker API | IB Gateway + ib_insync | Live positions, FX rates, H4 bars, order execution |
| ML Core | NumPy + Custom Ridge | Specialist models, feature engineering, meta-classifier |
| Optimization | MCMC Metropolis-Hastings | Bayesian posterior weight optimization (22 theories) |
| RL Agent | Q-Learning (tabular) | Strategy selection from realized trade outcomes |
| Persistence | SQLite (WAL mode) | 3 databases, thread-safe concurrent writes |
| Orchestration | ThreadPoolExecutor | Parallel phase execution with dependency ordering |
| Alerting | Discord Webhooks | Real-time position changes, errors, pipeline status |
| IV Surface | ETF Options (IB V30) | Implied volatility, VRP, term structure analysis |

---

## 02. High-Level Architecture

The system follows a staged pipeline architecture with 8 sequential stages. Within each stage, phases execute in parallel using Python's ThreadPoolExecutor. Data flows strictly downward: raw market data is collected, features are engineered, models classify each pair, signals are arbitrated, and position sizes are computed for live execution.

### Pipeline Stage Map

```
                    UNIFIED PIPELINE ORCHESTRATOR
                /          |          |           \
  S1: Data        S2: IBKR      S3: ML        S4: Post-ML
  Collection      + Theories    Ensemble       Fan-Out
  (58s)           (2s)          (109s)         (10s)
       |              |              |              |
  S5: RL+CB      S6: Meta      S7: Sizing     S8: Post-CSV
  (2s)           Signal (<1s)  + CSV (1s)      (9s)
```

### Unidirectional Data Flow

The pipeline enforces strict unidirectional flow. Each stage consumes outputs from previous stages but never writes back to upstream tables.

```
7 Scrapers + IBKR API + CFTC + ForexFactory
    |
    v
Feature Engineering: 117 features/pair (20 categories)
    |
    v
ML Ensemble (5 models) --> Bayesian Optimizer (MCMC)
    |                         |
    v                         v
4-Day Forecast         RL Q-Learning Agent
    |                         |
    v                         v
   META-SIGNAL RESOLVER (Conflict Arbitration)
    |
    v
Smart Position Sizing (Kelly + ATR + IV + Circuit Breaker)
    |
    v
strategies_auth_simple.csv --> 32 Live Strategies
```

---

## 03. Data Collection Layer

The data collection layer (Stage 1) executes 7 phases in parallel, gathering real-time market data from diverse sources. Each scraper is independent and fault-tolerant: if one source fails, the pipeline continues with degraded but functional data coverage. The stage completes in approximately 58 seconds.

### Seven Data Sources

| Source | Data Type | Update Freq | Pairs |
|---|---|---|---|
| IG.com | Retail positioning % | Hourly | 8 core pairs |
| Dukascopy | Sentiment + currency strength | 4-hourly | 8 pairs + 325 cross-pairs |
| Myfxbook | Community sentiment (L/S %) | Daily | 8 pairs |
| FXSSI | Order sentiment [-1, +1] | Hourly | 16 pairs |
| Market Bulls | Seasonal tendency | Monthly | 12 pairs (8 mapped) |
| CFTC (COT) | Net positioning, OI, commercials | Weekly | 7 currencies |
| ForexFactory | Economic events, impact levels | Real-time | All currencies |

### Additional Data Feeds

- **Implied Volatility:** CurrencyShares ETF options (FXE, FXB, FXY, FXF, FXA, FXC) via IB V30 API. Cross-pairs (EURJPY, AUDJPY) computed via correlation-adjusted decomposition.
- **OHLC Price Bars:** H4 timeframe from broker API with Yahoo Finance fallback. Cached in SQLite; ~900 bars per pair.
- **ATR Calculation:** 14-period Average True Range on H4 bars, plus D1 aggregation for daily volatility context.

### Example: EURUSD Sentiment Aggregation

*Real data from pipeline execution on 2026-02-19. Five sources are normalized to [-1, +1] and merged:*

| Source | Raw Value | Normalized | Interpretation |
|---|---|---|---|
| IG.com | -6.0 | -0.06 | Slightly more shorts than longs among retail |
| Dukascopy | -11.46 | -0.11 | Moderate bearish positioning |
| Myfxbook | +8.0 | +0.08 | Slightly bullish community sentiment |
| FXSSI | +0.04 | +0.04 | Near-neutral order flow |
| Market Bulls | -0.001 | -0.001 | Negligible seasonal tendency (February) |

> **Note:** The disagreement between sources is itself a feature (sentiment_range = 0.19, sentiment_volatility = 0.08). High disagreement signals market uncertainty.

### ATR Volatility Profile (H4, 14-period)

| Pair | ATR (pips) |
|---|---|
| USDJPY | 48.9 |
| EURJPY | 46.2 |
| AUDJPY | 38.2 |
| GBPUSD | 34.4 |
| USDCAD | 26.8 |
| AUDUSD | 20.4 |
| EURUSD | 19.6 |
| USDCHF | 18.8 |

*Higher ATR pairs receive smaller position sizes to normalize dollar risk.*

---

## 04. Feature Engineering

Each currency pair is represented by 117 features drawn from 20 categories. These features combine scraped sentiment data, CFTC positioning, price-based technical indicators, and derived composite signals. All features are normalized to [-1, +1] or [0, 1] ranges for ML compatibility.

### 22 Financial Theories (Phase 2)

After data collection, 22 financial theories are computed from the scraped data. Each outputs a value in [-1, +1] where positive indicates a long bias.

| Category | # | Example Theories |
|---|---|---|
| Sentiment | 8 | retail_bias, sentiment_momentum, extreme_sentiment, retail_inst_divergence |
| COT | 4 | cot_momentum, cot_commercial, cot_open_interest, cot_positioning |
| Momentum | 4 | base_momentum, momentum_differential, multi_factor_trend, relative_strength |
| Calendar | 2 | upcoming_events, calendar_density |
| Advanced | 4 | cot_acceleration, strength_sent_confirm, sent_cot_agreement, event_asymmetry |

### Feature Composition (117 per pair)

| Category | Count |
|---|---|
| Theories | 22 |
| Price-Based | 8 |
| Sentiment | 5 |
| COT | 6 |
| Calendar | 4 |
| Strategy Outcomes | 6 |
| Regime History | 4 |
| Transition Probs | 4 |
| RL Signals | 3 |
| Positions | 4 |
| Composites | 9 |
| **Other (Strength, Vol, PnL)** | **42** |

### Full Feature Category Breakdown

| Category | # | Description |
|---|---|---|
| Sentiment Scores | 5 | Mean, std, extreme, consensus, contrarian from 5 sources |
| Currency Strength | 4 | Dukascopy base/quote scores and differential |
| COT Positioning | 6 | Net position, commercial, OI, change %, z-score |
| Calendar Impact | 4 | Proximity to events, high-impact count, total events |
| Theory Scores | 22 | All 22 theories as raw feature inputs |
| Price-Based | 8 | Hurst exponent, half-life, variance ratio, ACF, momentum |
| Regime History | 4 | Persistence, transition frequency, TF/MR flags |
| Transition Probs | 4 | P(TF->TF), P(TF->MR), P(MR->TF), P(MR->MR) |
| Strategy Outcomes | 6 | Historical avg PnL %, win rate, count (TF and MR) |
| RL Signals | 3 | Average reward, reward trend, experience count |
| Volatility/ATR | 2 | ATR value and normalized ATR |
| Open Positions | 4 | Active flag, direction, size, unrealized PnL % |
| Realized PnL | 4 | Average %, win rate, last trade result, trade count |
| Derived Composites | 9 | TF/MR evidence scores, balance, alignment metrics |

> **Key Design:** All 117 features are computed from real data only. No synthetic fallbacks. If a data source is missing, that feature is set to 0 (neutral).

---

## 05. ML Strategy Ensemble

The ML Strategy Ensemble v2.0 is a 5-Model Mixture of Experts (MoE) architecture that classifies each currency pair into one of four strategy types: Long Trend Following (L_TF), Short Trend Following (S_TF), Long Mean Reversion (L_MR), or Short Mean Reversion (S_MR). This classification drives all downstream decisions.

### Architecture: 4 Specialists + 1 Meta-Classifier

```
            117 FEATURES PER PAIR
           /      |       |      \
    L_TF       S_TF     L_MR     S_MR
  Specialist  Specialist Specialist Specialist
           \      |       |      /
            META-CLASSIFIER
                  |
    STRATEGY + DIRECTION + CONFIDENCE
```

### Meta-Classifier: Three-Step Decision

**Step 1: Regime Detection (Trend Following vs Mean Reversion)**

The meta-classifier determines whether the market environment favors Trend Following (TF) or Mean Reversion (MR) using multiple statistical indicators from H4 bars:

- **Hurst Exponent (H):** H > 0.6 = trending (TF); H < 0.4 = mean-reverting (MR). Rescaled range analysis, 90-bar window.
- **Variance Ratio:** VR > 1.05 = autocorrelation (TF); VR < 0.95 = negative autocorrelation (MR). Lo-MacKinlay test.
- **Half-Life:** HL < 30 bars = fast mean reversion (MR); HL > 60 = slow drift (TF). Ornstein-Uhlenbeck process.
- **ACF:** Positive lag-1 ACF = TF score; negative ACF = MR score.
- **Calendar Proximity:** Upcoming high-impact events bias toward MR (reduced trending).

**Step 2: Direction Detection (Long vs Short)**

For TF: follow momentum (5-day momentum strongest signal, currency strength, COT). For MR: contrarian positions from Bollinger band extremes, RSI, and sentiment.

**Step 3: Confidence Calculation**

```python
confidence = 0.5 + 0.3 * regime_margin + 0.2 * direction_margin
regime_margin  = |TF_score - MR_score| / (|TF| + |MR|)
direction_margin = |dir_score| / (|dir_score| + 1.0)
final_confidence = clip(confidence, 0.30, 0.95)
```

### Training Methodology

- **Walk-Forward Validation:** 90-bar training, 6-bar forward labels. 2-bar gap prevents lookahead bias.
- **Label Generation:** From realized price returns. Continuation = TF; reversals = MR. Return magnitude = sample weight.
- **Specialist Learning:** Ridge regression (L2). Each specialist scores its own strategy from features.
- **Hourly Retraining:** Every pipeline run, all specialists retrain with fresh data.

### Example: Live Classification (2026-02-19)

| Pair | Strategy | Dir | Regime | Conf | Hurst |
|---|---|---|---|---|---|
| EURUSD | L_TF | L | trend_following | 65% | 0.718 |
| USDJPY | L_TF | L | trend_following | 75% | 0.769 |
| GBPUSD | L_TF | L | trend_following | 79% | 0.738 |
| USDCHF | S_MR | S | mean_reversion | 61% | 0.730 |
| AUDUSD | S_MR | S | mean_reversion | 69% | 0.714 |
| USDCAD | L_TF | L | trend_following | 74% | 0.727 |
| EURJPY | L_TF | L | trend_following | 82% | 0.731 |
| AUDJPY | S_TF | S | trend_following | 86% | 0.737 |

> **Distribution:** 75% TF / 25% MR | 62% Long / 38% Short
> Diversity check: BALANCED regime, BALANCED direction | 117 features/pair | 3 databases connected

---

## 06. Bayesian Optimizer

The Bayesian Optimizer uses Markov Chain Monte Carlo (MCMC) via the Metropolis-Hastings algorithm to optimize the weights of 22 financial theories. The optimizer learns which theories are most predictive and adjusts their influence on classification.

### MCMC Optimization Flow

```
Initialize from prior domain-expert weights
    |
    v
Propose: current + Normal(0, sigma=0.12)
    |
    v
Score: likelihood from trade outcome accuracy
    |
    v
Accept/Reject: Metropolis-Hastings criterion
    |
    v
Adapt temperature every 20 iterations (target 30% accept)
    |
    v
After 2000 iterations: posterior mean of post-burn-in samples
```

### Pseudocode

```python
for iteration in range(2000):
    proposed = current + Normal(0, sigma=0.12)
    score_new = likelihood(proposed, trade_outcomes)
    acceptance = min(1, score_new / score_old)
    if random() < acceptance:
        current = proposed  # Accept
    if iteration % 20 == 0:
        adapt_temperature(target_accept_rate=0.30)
```

### Data Sources for Training

- **Hard Outcomes:** Realized trades with known PnL (weight = 1.0). Gold standard from broker executions.
- **Soft Outcomes:** Partial signals from unrealized positions (weight < 0.5). Faster feedback, lower confidence.
- **Safety Minimum:** 15 effective outcomes required. Below this, prior weights are preserved.

### Convergence Diagnostics

- **Burn-In:** First 20% of MCMC samples discarded for chain convergence.
- **Drift Check:** Compare mean weights between first/second half of post-burn-in. Target: < 5% drift.
- **Distribution Balance:** Penalty if TF/MR split exceeds 85/15 in either direction.

> **Safety Guard:** If n_effective < 15 or final_performance < -2.0, the optimizer reverts to prior domain-expert weights. No trading on poorly-calibrated weights.

---

## 07. Reinforcement Learning Agent

The RL Agent uses tabular Q-Learning to learn optimal strategy selection from trade outcomes. Unlike the ML ensemble which classifies based on features, the RL agent learns from the consequences of past decisions, providing a complementary signal.

### RL Learning Loop

```
ENVIRONMENT: Live FX Market
    |
    v
STATE: (pair, regime, direction, confidence)
    |
    v
RL AGENT: Q-Table Lookup
    |
    v
ACTION: (TF/MR, Long/Short)
    |
    v
REWARD: PnL + trajectory + drawdown
    |
    └──────── feedback ────────┘
```

### State-Action Space

```
State = (pair, regime_norm, direction_signal, confidence_bucket)
  pair:              EURUSD, USDJPY, ... (8 pairs)
  regime_norm:       'trend_following' or 'mean_reversion'
  direction_signal:  'P' (positive) or 'N' (negative)
  confidence_bucket: 'lo' (<55%), 'md' (55-70%), 'hi' (70%+)

Actions = { (TF, Long), (TF, Short), (MR, Long), (MR, Short) }
```

### Q-Learning Update & Reward

```python
Q(s,a) <- Q(s,a) + 0.1 * [reward + 0.95 * max_a' Q(s',a') - Q(s,a)]

reward = (pnl_pct * 10.0)        # Primary PnL signal
       + 0.3 * slope_sign        # Are we improving?
       + 0.2 * drawdown_penalty  # Risk-adjusted
       + realtime_pnl_signal     # Live position feedback
reward = clamp(reward, -10, +10)
```

### Observation Mode & Continuous Training

- **Observation until 50+ outcomes:** Trains Q-table but defers recommendations to ML ensemble.
- **Real-Time Feedback:** Unrealized PnL creates soft-weighted RL experiences every pipeline run.
- **Retraining Trigger:** Sortino < -0.3 or Sharpe < -0.5 initiates aggressive retraining.

---

## 08. Meta-Signal Resolver

The Meta-Signal Resolver is the critical arbitration layer that reconciles potentially conflicting signals from three independent sources: the ML Classifier, the 4-Day Forecast, and the RL Agent. It produces a single unified trading decision per pair.

### Three-Source Consensus Architecture

```
ML Classifier (46%)    4-Day Forecast (38%)    RL Agent (16%)
         \                    |                    /
          \                   |                   /
           WEIGHTED DIRECTION VOTING
                     |
                     v
     AGREEMENT: UNANIMOUS / MAJORITY / SPLIT / FLAT
                     |
                     v
  FINAL: Direction + Strategy + Confidence + Sizing Multiplier
```

### Agreement Classification

| Level | Condition | Conf Adj | Sizing |
|---|---|---|---|
| UNANIMOUS | All 3 sources agree on direction | +10% | Floor 50%, up to 100% |
| MAJORITY | 2 of 3 sources agree | No change | Floor 40%, sizing 75% |
| SINGLE | Only 1 source active | -5% | Floor 25%, sizing 50% |
| SPLIT | Sources disagree | -30% | Floor 25%, sizing 25% |
| NO_DATA | No sources available | N/A | FLAT (no trade) |

### Example: Pipeline Output (2026-02-19)

*All 8 pairs achieved UNANIMOUS agreement between ML and Forecast (RL in observation mode):*

| Pair | ML | Forecast | RL | Final | Conf | Sizing |
|---|---|---|---|---|---|---|
| AUDJPY | S | S | --- | S trend | 97% | x0.87 |
| AUDUSD | S | S | --- | S mean_rev | 80% | x0.70 |
| EURJPY | L | L | --- | L trend | 93% | x0.83 |
| EURUSD | L | L | --- | L trend | 76% | x0.66 |
| GBPUSD | L | L | --- | L trend | 89% | x0.55 |
| USDCAD | L | L | --- | L trend | 84% | x0.74 |
| USDCHF | S | S | --- | S mean_rev | 72% | x0.62 |
| USDJPY | L | L | --- | L trend | 85% | x0.75 |

> **Note:** RL Agent shows '---' (observation mode: 10/50 required outcomes). GBPUSD sizing x0.55 due to active SHOCK (VRP z=+12.14).

---

## 09. 4-Day Forecast System

The 4-Day Forecast propagates ML regime classification forward using calibrated transition probabilities. It modulates confidence without overriding the ML regime decision.

### Regime Transition Model

```
    TF (Trend Following) <──── 5% ────> MR (Mean Reversion)
         |                                    |
    P(TF->TF) = 95%                   P(MR->MR) = 92%
         |                                    |
         └──────────── 8% ───────────────────┘
```

### Forecast Propagation Steps

1. **Day 1:** 100% current regime (as classified by ML)
2. **Day 2-4:** Apply transition probabilities iteratively
3. **Confidence:** Average conviction across 4 days, boost if ML > 60%
4. **Direction:** Propagated from ML classification (never overridden)

### Example: EURJPY Forecast

*ML classified EURJPY as L_TF with 82% confidence. 4-day forecast: TF persistence = 95%*

```
Day 1: 100% TF (ML confidence 82%)
Day 2:  95% TF,  5% MR
Day 3:  90% TF, 10% MR
Day 4:  86% TF, 14% MR
=> Cumulative confidence: 84.87% (boosted from 82%)
```

> **Critical Rule:** The forecast NEVER overrides the ML regime decision. It only modulates confidence up or down based on regime persistence probability.

---

## 10. Implied Volatility Surface

The IV Surface module collects 30-day implied volatility from CurrencyShares ETF options. For 6 direct USD pairs, IV is read from ETF options. For cross-pairs, IV is computed via correlation-adjusted decomposition of constituent ETFs.

### ETF-to-Pair Mapping & IV Regimes

| ETF | Pair | IV 30d | VRP | Regime |
|---|---|---|---|---|
| FXE | EURUSD | 5.94% | +0.02% | COMPLACENT (IV ~ RV) |
| FXY | USDJPY | 9.59% | -0.62% | PRICED (IV < RV) |
| FXB | GBPUSD | 7.60% | +1.13% | FEARFUL (IV >> RV, z=+2.25) |
| FXF | USDCHF | 8.18% | -0.50% | SURPRISE (IV << RV) |
| FXA | AUDUSD | 9.03% | -0.59% | SURPRISE (IV << RV) |
| FXC | USDCAD | 8.88% | +2.49% | FEARFUL (IV >> RV, z=+2.34) |
| cross | EURJPY | 10.67% | +2.44% | COMPLACENT (cross decomp) |
| cross | AUDJPY | 11.74% | -0.39% | SURPRISE (cross decomp) |

### IV Regime to Strategy Mapping

| Regime | Primary Strategy | Sizing Impact |
|---|---|---|
| FEARFUL | Breakout 51% | Kelly reduced to 0.70x |
| COMPLACENT | Momentum 35% | Full Kelly |
| SURPRISE | Momentum 38% | IV scale 60% |
| PRICED | Trend 45% | IV scale 70% |

### Volatility Risk Premium (VRP)

VRP = IV - RV. Positive VRP: market fears more than realized (FEARFUL). Negative VRP: market underprices risk (SURPRISE). This drives strategy weighting and Kelly adjustments per pair.

---

## 11. Position Sizing & Kelly Criterion

Smart Position Sizing v7 computes optimal sizes per account-pair, integrating Kelly fraction, ATR volatility, IV regime adjustments, and leverage limits.

### Position Sizing Pipeline

```
Account Equity x Risk % (2.0%)
    |
    v
/ (ATR x Multiplier) = Base Size
    |
    v
x Kelly Fraction (from meta confidence)
    |
    v
x IV Regime Scale (60-100%)
    |
    v
x Meta Sizing Multiplier (25-130%)
    |
    v
clamp(MIN=25K, MAX=leverage_limit)
    |
    v
FINAL POSITION SIZE
```

### Constraint Categories

- **LEVERAGE+KELLY:** Sized by Kelly fraction and leverage limit (most common)
- **LEVERAGE+KELLY+IV:** Additional IV regime adjustment (FEARFUL=85%, SURPRISE=60%, PRICED=70%)
- **MIN-25K:** Floored at $25,000 minimum (broker IdealPro requirement)
- **SKIP:** Too small after adjustments; pair skipped for this account

### Example: Account 1 Sizing

| Account | Pair | ATR Qty | Lev Max | Final | Constraint |
|---|---|---|---|---|---|
| Acct 1 | AUDJPY | 348,250 | 68,010 | 35,000 | LEVERAGE+KELLY(87%)+IV(60%) |
| Acct 1 | AUDUSD | 653,013 | 68,010 | 28,000 | LEVERAGE+KELLY(70%)+IV(60%) |
| Acct 1 | EURJPY | 287,367 | 68,010 | 56,000 | LEVERAGE+KELLY(83%) |
| Acct 1 | EURUSD | 678,196 | 68,010 | 44,000 | LEVERAGE+KELLY(66%) |

### Portfolio Leverage Validation

*All 8 accounts validated between 1.11x and 1.63x equity (max allowed: 2.5x):*

| Account | Leverage |
|---|---|
| Acct 4 | 1.63x |
| Acct 3 | 1.47x |
| Acct 1 | 1.43x |
| Acct 2 | 1.34x |
| Acct 5 | 1.14x |
| Acct 6 | 1.14x |
| Acct 7 | 1.11x |
| Acct 8 | 1.11x |

---

## 12. Risk Management Framework

Multiple independent safety layers ensure no single failure causes uncontrolled risk exposure.

### Multi-Layer Safety Architecture

| Layer | Mechanism | Trigger | Action |
|---|---|---|---|
| Market Hours | IBKR IdealPro | Fri 17:00 - Sun 17:00 | Halt pipeline entirely |
| Connectivity | TWS port probe | Gateway unreachable | Abort Stage 1, Discord alert |
| Data Integrity | Schema validation | Missing/corrupt tables | Log warning, continue degraded |
| Cross-Validation | IBKR vs GV check | Position desync | Discord @here, reconcile |
| Circuit Breaker | PnL threshold | Daily DD > -5% | Reduce all sizes 50-100% |
| Crowding | Cohort analysis | Crowd % > 70% | Reduce sizing by penalty factor |
| IV Shock | VRP z-score | VRP z > +2.0 | Reduce Kelly to 0.70x |
| Equity Guard | Account monitor | Equity < threshold | Halt new positions |

### Defense-in-Depth

```
                    MARKET HOURS GATE
                  TWS CONNECTIVITY CHECK
                DATA INTEGRITY GUARD
              ML + RL CLASSIFICATION
            META-SIGNAL RESOLVER
         CIRCUIT BREAKER + SHOCK DETECTOR
       POSITION SIZING (Kelly + ATR + IV)
             BROKER EXECUTION
```

### Shock Opportunity Detector (White Swan)

- **RECOVERY:** IV declining from peak (>10% off). Contrarian Kelly boost 1.05x.
- **SHOCK:** Active VRP spike + extreme sentiment. Kelly reduced to 0.70x.

### Position Reconciliation

Cross-validation of broker vs platform positions every run. Latest: 6/6 validated OK. Any desync triggers immediate Discord critical alert.

---

## 13. Database Architecture

Three-database architecture with SQLite WAL mode for concurrent read/write access from multiple pipeline phases.

### Three-Database Topology

```
              SHARED DATA API (shared_data.py)
             /              |               \
forex_sentiment.db    forex_regime.db    risk_management.db
     (~3.2 GB)           (~1.3 MB)           (~12 MB)
  Main: sentiment,    Regime: OHLC bars,   Risk: equity,
  theories, ML,       ensemble              positions, ATR,
  RL experiences      classifications       realized PnL
```

### Shared Data API

```python
get_live_state()     -> IBKR snapshot (max 300s stale)
get_fx_rates()       -> Currency conversion rates (USD base)
get_atr('H4')        -> 14-period ATR for position sizing
get_account_equity() -> Total portfolio equity (excludes paper)
get_positions()      -> Open position list
get_ohlc_bars(pair, timeframe='H4', limit=500)
```

### Key Tables per Database

| Database | Key Tables | Purpose |
|---|---|---|
| forex_sentiment | sentiment_hourly, cot_data | Raw scraped data + calendar events |
| forex_sentiment | theory_scores, ml_classifications | 22 theories + ML outputs per pair |
| forex_sentiment | rl_experiences, rl_q_table | RL training data + persisted Q-table |
| forex_sentiment | meta_signals, optimizer_weights | Arbitration results + MCMC weights |
| forex_regime | ohlc_bars, ensemble_classifications | H4 price bars + regime decisions |
| forex_regime | strategy_assignments | 4-day forecast assignments |
| risk_management | ibkr_account_metrics | Account equity snapshots |
| risk_management | ibkr_positions, atr_data | Live positions + ATR values |
| risk_management | pnl_realized, daily_pnl | Realized PnL + daily tracking |

---

## 14. Live Monitoring & Observability

### Liveboard (Real-Time Dashboard)

A persistent background process subscribes to open positions and account summaries. Publishes JSON every 3 seconds to a web dashboard for human monitoring.

### Monitoring Architecture

```
IBKR Gateway (7496/7497)
    |
    v
Liveboard Process (port 5089)
    |
    v
Web Dashboard (moneyprod.com/live/)
    |
    v
Discord Webhooks (real-time alerts)
    |
    v
Pipeline Diagnostics (Phase 10a)
```

### Discord Notification Types

```
INFO    -> Pipeline started/completed, CSV generated
WARNING -> Non-critical failures, drawdown alerts
ERROR   -> Critical failures, IBKR down, desync detected
SIGNAL  -> New long/short position signals
DESYNC  -> Position mismatch broker vs platform
```

### Pipeline Diagnostics Summary (2026-02-19)

- Scrapers: 8/8 fresh data sources validated
- ML: 8/8 classified, avg confidence 74%, balanced TF/MR
- Meta: 8/8 resolved, avg meta confidence 85%
- Positions: 6 live positions synced across 5 accounts
- Circuit Breaker: NORMAL (sizing 100%)
- Portfolio: 8 accounts, CV=14% (well-balanced)
- Result: 0 CRITICAL | 6 WARNING | 27 OK | 10 INFO

---

## 15. Continuous Learning System

Monitors performance metrics in real-time, triggers retraining on degradation. Versioned learning state persisted to SQLite for continuity.

### Performance Metrics

| Metric | Formula | Target | Trigger |
|---|---|---|---|
| Win Rate | wins / total_trades | > 55% | Retraining if sustained < 40% |
| Sharpe | (mean_pnl / std_pnl) * sqrt(260) | > 1.0 | Alert if < -0.5 |
| Sortino | (mean_pnl / downside_std) * sqrt(260) | > 1.5 | Retrain if < -0.3 |
| Max DD | peak_to_trough / peak | < -10% | Circuit breaker activation |
| Profit Factor | gross_wins / gross_losses | > 1.5 | Review if < 1.0 |

### Adaptive Retraining Schedule

- **Every pipeline run:** ML Specialists retrain (90-bar walk-forward)
- **Every pipeline run:** RL Agent processes new outcomes, updates Q-table
- **Daily:** Full Bayesian optimization if sufficient outcomes
- **Weekly:** Gelman-Rubin convergence diagnostic on MCMC chains
- **On degradation:** Immediate retraining triggered by Sortino < -0.3

### Continuous Learning Feedback Loop

```
Live Trading -> Realized P&L
    |
    v
Outcome Recording (hard + soft outcomes)
    |
    v
RL Agent Q-Table Update + Bayesian MCMC Rerun
    |
    v
Performance Metrics (Sharpe, Sortino, Win Rate)
    |
    v
Degradation Detected? -> Retraining Trigger
    |
    v
Updated Models Feed Next Pipeline Run
```

### Crowding Penalty A/B Testing

Half of decisions receive crowding penalty (treatment), half at full size (control). After 50+ outcomes, system compares PnL/Sharpe and adjusts penalty factor.

*Current: threshold=70%, penalty=0.608, boost=1.629. Treatment PnL: +0.16% | Control PnL: +0.17%. Action: penalty weakened.*

---

## 16. Pipeline Execution Timeline

The unified pipeline executes in 8 sequential stages with internal parallelism. Total: 191 seconds. CSV delivered at 181s (well within 5-minute target).

### Stage-by-Stage Timing

| Stage | Name | Phases | Time | Critical Path |
|---|---|---|---|---|
| 1 | Data Collection | 7 | 58s | Scrapers (parallel, I/O bound) |
| 2 | IBKR + Theories | 3 | 2s | 22 theory calculations |
| 3 | ML Ensemble + Concurrent | 5 | 109s | ML training (CPU bound, critical) |
| 4 | Post-ML Fan-Out | 3 | 10s | Bayesian + Forecast + Outcomes |
| 5 | RL + Circuit Breaker | 2 | 2s | Q-learning update |
| 6 | Meta-Signal Resolver | 1 | < 1s | Conflict arbitration |
| 7 | Position Sizing + CSV | 1 | 1s | CSV generation (TIME CRITICAL) |
| 8 | Post-CSV (deferred) | 7 | 9s | Reports, learning (no deadline) |

### Visual Execution Timeline

```
S1: Data    |████████████████████████████████                                    |  0-58s
S2: IBKR    |                                ██                                  | 58-60s
S3: ML      |                                  ██████████████████████████████████ | 60-169s
S4: Post-ML |                                                                  ██| 169-179s
S5: RL+CB   |                                                                    | 179-181s
S6: Meta    |                                                                    | 181s
S7: CSV     |                                                                    | 181-182s
S8: Post    |                                                                  ██| 182-191s
            0s                  60s                 120s              181s    191s
                                                                      ^
                                                                  CSV READY
```

### Failure Handling

- **Critical (ML, Meta, Sizing):** Pipeline halts. Discord @here alert.
- **Non-critical (FXSSI, GV, Report):** Continue with warning. Trading unaffected.
- **Post-CSV:** Failures logged but trading already live (CSV delivered).

---

## Architectural Summary

| Component | Value |
|---|---|
| Data Sources | 7 live |
| Features | 117/pair |
| ML Models | 5 MoE |
| Optimizer | MCMC |
| RL Agent | Q-Learn |
| Arbitration | 3-source |
| Risk Layers | 8 indep. |
| Pipeline | 191s |

MoneyProd represents a complete, production-grade autonomous trading system combining machine learning, Bayesian optimization, reinforcement learning, and quantitative finance into a unified pipeline. Every component is designed for robustness: non-circular data flows, multiple independent safety layers, graceful degradation, and continuous self-improvement.

---

**Timothy Lokotar**
- [LinkedIn](https://linkedin.com/in/timothy-lokotar/)
- [MoneyProd](https://www.moneyprod.com/)
