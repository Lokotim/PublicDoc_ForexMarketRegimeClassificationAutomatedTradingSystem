# SYSTEM ARCHITECTURE

## Table of Contents
1. [High-Level Architecture](#high-level-architecture)
2. [Component Design](#component-design)
3. [Data Flow](#data-flow)
4. [Technology Decisions](#technology-decisions)
5. [Scalability Considerations](#scalability-considerations)

---

## 1. HIGH-LEVEL ARCHITECTURE

### 1.1 Multi-Tier Architecture

The ForexRegime system follows a **layered architecture** pattern with clear separation of concerns:

\\\
┌────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                        │
│  - IIS Web Server (Windows Server 2022)                       │
│  - HTML Report Generation (10 sections, responsive)           │
│  - Real-time LIVE indicator (countdown, market hours check)   │
│  - Public URL: https://moneyprod.com                          │
└────────────────────────────┬───────────────────────────────────┘
                             ↓
┌────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                         │
│  - unified_pipeline.py (main orchestrator)                     │
│  - generate_complete_final.py (report generator)               │
│  - Theory calculation engine (22 theories)                     │
│  - ML classifier (Random Forest)                               │
│  - MCMC optimizer (Bayesian parameter tuning)                  │
└────────────────────────────┬───────────────────────────────────┘
                             ↓
┌────────────────────────────────────────────────────────────────┐
│                      DATA ACQUISITION LAYER                    │
│  - ForexScraper (8 source scrapers)                           │
│  - Playwright-based headless browsers                          │
│  - Async parallel execution (asyncio.gather)                   │
│  - Anti-detection measures (stealth mode)                      │
└────────────────────────────┬───────────────────────────────────┘
                             ↓
┌────────────────────────────────────────────────────────────────┐
│                      DATA STORAGE LAYER                        │
│  - SQLite 3.43 (development, 142 MB)                          │
│  - 5 core tables (sentiment, theories, classifications, etc.)  │
│  - Migration planned: PostgreSQL 15 (production scale)         │
│  - Future: TimescaleDB (time-series optimization)              │
└────────────────────────────────────────────────────────────────┘
\\\

### 1.2 Design Principles

**Modularity**: Each layer is independently testable and replaceable
- Scrapers can be added/removed without affecting ML layer
- ML model can be swapped (Random Forest → Neural Network)
- Database can be migrated (SQLite → PostgreSQL) transparently

**Fault Tolerance**: Multiple levels of error handling
- Scraper failures → 3-retry with exponential backoff → Fallback to cached data
- Database locks → Incremental delay retry
- ML prediction errors → Use last classification
- MCMC divergence → Early stopping + revert to previous weights

**Observability**: Comprehensive logging and monitoring
- Structured JSON logs (timestamp, level, module, metadata)
- Windows Event Viewer integration
- Execution time tracking per phase
- Success/failure rate metrics

---

## 2. COMPONENT DESIGN

### 2.1 Data Ingestion (ForexScraper)

**Architecture Pattern**: Strategy Pattern (one scraper per source)

**Key Components**:

1. **Base Scraper Interface**
   - Standardized methods: scrape(), validate(), retry_logic()
   - Common error handling
   - Timeout management (30s per source)

2. **Source-Specific Scrapers** (8 implementations)
   - IGSentimentScraper (retail positioning)
   - DukascopyScraper (Swiss bank data)
   - MyfxbookScraper (social trading)
   - CFTCScraper (institutional COT)
   - SSIScraper (sentiment index)
   - ForexClientSentimentScraper (multi-broker)
   - MarketBullsScraper (seasonal patterns)
   - TradingViewScraper (crowd sentiment)

3. **Parallel Execution Engine**
   - asyncio.gather() for concurrent scraping
   - Semaphore limiting (max 5 simultaneous)
   - Total time: ~50-60 seconds for all 8 sources

**Technology Choices**:
- **Playwright** (vs Selenium): Better JavaScript rendering, faster, modern API
- **Async/Await** (vs threading): Better I/O handling, lower overhead
- **Headless browsers** (vs requests): Required for JavaScript-heavy sites

### 2.2 Theory Calculation Engine

**Architecture Pattern**: Pipeline Pattern (sequential theory calculations)

**22 Theories Organized in 3 Categories**:

**Trend Following (10)**:
1. COT Momentum → Institutional flow direction
2. Retail Contrarian → Fade retail sentiment
3. Extreme Positioning → Follow extremes
4. Seasonal Patterns → Calendar effects
5. Relative Strength → Cross-pair momentum
6. Volume Confirmation → Liquidity validation
7. Cross-Asset Correlation → Risk-on/risk-off
8. Macro Trend Alignment → Economic data
9. Moving Average Crossovers → Technical signals
10. Breakout Confirmation → Range expansion

**Mean Reversion (10)**:
1. Retail Bias → Follow retail extremes (contrary to TF)
2. Institutional Contrarian → Fade institutions
3. Overbought/Oversold → RSI-based
4. Sentiment Extremes → Sentiment mean reversion
5. Historical Mean Reversion → Statistical reversion
6. Volatility Compression → Low volatility → expansion
7. Range-Bound Indicators → Bollinger Bands
8. RSI Divergence → Price vs RSI divergence
9. Bollinger Band Reversion → Band touch signals
10. Pair Correlation Breakdown → Correlation shocks

**Statistical Validation (3)**:
1. Kendall Tau → Trend persistence test
2. Variance Ratio → Random walk hypothesis
3. Hurst Exponent → Long-term memory (H>0.5: trending, H<0.5: MR)

**Implementation Details**:
- All theories output normalized scores: [-1, +1]
- Vectorized NumPy operations (10x faster than loops)
- Caching of intermediate calculations
- Execution time: ~5 seconds for 22 theories × 9 pairs

### 2.3 Machine Learning Classifier

**Architecture Pattern**: Supervised Learning Pipeline

**Components**:

1. **Feature Engineering**
   - Input: 22 theory scores + 2 sentiment metrics
   - Normalization: StandardScaler (mean=0, std=1)
   - Feature selection: All 22 features retained (no dimensionality reduction needed)

2. **Model: Random Forest Classifier**
   - 100 decision trees (n_estimators=100)
   - Max depth: 10 (prevents overfitting)
   - Min samples split: 20 (ensures statistical significance)
   - Class balancing: Automatic (class_weight='balanced')

3. **Training Process**
   - Dataset: 6 months historical (370K records)
   - Labeling: Retroactive regime classification (ADX, R², autocorrelation)
   - Train/Test: 80/20 chronological split (no data leakage)
   - Validation: Time-series cross-validation (expanding window)

4. **Inference Pipeline**
   - Real-time prediction: <100ms per pair
   - Output: Class label (TF/MR) + confidence score [0, 1]
   - Threshold: 0.5 (can be tuned for precision/recall trade-off)

**Why Random Forest?**
- ✅ Handles non-linear relationships (theory interactions)
- ✅ Robust to outliers (financial data is noisy)
- ✅ Provides feature importances (interpretability)
- ✅ Fast inference (<10ms)
- ❌ Not deep learning: Simple enough to validate, complex enough to capture patterns

### 2.4 MCMC Bayesian Optimizer

**Architecture Pattern**: Markov Chain Monte Carlo Sampler

**Problem Formulation**:
- **Objective**: Maximize classification accuracy
- **Parameters**: 20 theory weights (10 TF + 10 MR)
- **Constraints**: Simplex (∑weights = 1.0), non-negativity (weights ≥ 0)

**Algorithm: Metropolis-Hastings**

**Pseudocode** (high-level):
\\\
Initialize w_current = uniform(0.1, 0.1, ..., 0.1)  # 20 weights
accuracy_current = evaluate_accuracy(w_current)

For iteration i = 1 to 100:
    # Propose new weights
    w_proposed = w_current + normal(0, σ=0.05)
    w_proposed = project_to_simplex(w_proposed)  # Normalize
    
    # Evaluate on validation set
    accuracy_proposed = evaluate_accuracy(w_proposed)
    
    # Acceptance probability (Metropolis criterion)
    α = min(1.0, accuracy_proposed / accuracy_current)
    
    # Accept with probability α
    if random() < α:
        w_current = w_proposed
        accuracy_current = accuracy_proposed
    
    # Log sample for analysis
    log_sample(i, w_current, accuracy_current, α)

Return w_best  # Highest accuracy weights
\\\

**Key Design Decisions**:

1. **Proposal Distribution**: Gaussian (σ=0.05)
   - Too small → Slow exploration
   - Too large → Low acceptance rate
   - Optimal: 20-40% acceptance rate

2. **Simplex Projection**: Normalize to sum=1.0
   - Ensures valid probability distribution
   - Preserves non-negativity

3. **Convergence Detection**: Weight variance threshold
   - If variance < 0.001 for 10 iterations → Converged
   - Typical: ~70-80 iterations

4. **Backtest Evaluation**: 3-month rolling window
   - Prevents overfitting to recent data
   - Validates on unseen historical periods

**Performance**:
- Iterations: 100 (early stopping at 73)
- Acceptance rate: 32% (healthy)
- Accuracy improvement: +1.9% (82.3% → 84.2%)
- Compute time: ~28 minutes (can be parallelized)

### 2.5 Web Publishing Layer

**Architecture Pattern**: Template + Direct Copy

**Components**:

1. **HTML Report Generator** (generate_complete_final.py)
   - 10 sections: Executive summary, theories, ML results, MCMC, etc.
   - Responsive design (mobile-friendly)
   - PDF export button (print-optimized CSS)
   - LIVE indicator (real-time countdown, market hours check, LinkedIn link)

2. **LIVE Indicator Features**
   - Position: Fixed top-right (right:240px, top:20px)
   - Market hours check: Sunday 17:00 ET → Friday 17:00 ET
   - Countdown: "Next update in: mm:ss" (green) or "Market Closed" (red)
   - LinkedIn: Golden link to Timothy Lokotar profile
   - Animation: Pulsating green dot (CSS @keyframes)

3. **IIS Publishing**
   - **Direct file copy** (shutil.copy) - Abandoned symbolic links due to reliability issues
   - Source: C:\ForexRegime\reports\index.html
   - Destination: C:\inetpub\wwwroot\index.html
   - Cache control: web.config with no-cache headers

4. **Automated Cleanup**
   - Close Edge browser processes (taskkill /F /IM msedge.exe)
   - Prevents memory leaks from repeated report openings

**Technology Choices**:
- **Plain HTML/CSS/JS** (vs React/Angular): Simplicity, no build step, fast load
- **Direct copy** (vs symbolic link): 100% reliability (symlinks broke intermittently)
- **IIS** (vs Nginx/Apache): Native Windows Server integration, zero config

---

## 3. DATA FLOW

### 3.1 Hourly Execution Cycle

\\\
Time :55 → Scheduled Task: ForexRegime_Hourly_NY
│
├─ Market hours check (Sunday 17h ET - Friday 17h ET)
│  └─ If closed → Exit (log skip)
│
├─ Phase 1: Data Scraping (~50 seconds)
│  ├─ Launch 8 Playwright browsers in parallel
│  ├─ Extract sentiment data (long%, short%, net positioning)
│  ├─ Validate data (range checks, completeness)
│  └─ Insert into sentiment_hourly table
│
├─ Phase 2: Theory Calculations (~5 seconds)
│  ├─ Load last 24 hours of sentiment data
│  ├─ Calculate 22 theories (vectorized NumPy)
│  ├─ Normalize scores to [-1, +1]
│  └─ Insert into theory_scores table
│
├─ Phase 3: ML Classification (~1 second)
│  ├─ Load theory scores as feature vector (22 dimensions)
│  ├─ Random Forest prediction (100 trees)
│  ├─ Output: TF/MR + confidence
│  └─ Insert into ml_classifications table
│
├─ Phase 4: MCMC Optimization (~30 seconds, conditional)
│  ├─ Check: Accuracy improved since last run?
│  │  └─ No → Skip
│  │  └─ Yes → Run MCMC chain (100 iterations)
│  ├─ Learn optimal theory weights
│  └─ Update optimizer_weights, optimizer_performance tables
│
└─ Phase 5: Report Generation & Publishing (~5 seconds)
   ├─ Generate HTML report (10 sections)
   ├─ Inject LIVE indicator
   ├─ Copy to IIS directory (C:\inetpub\wwwroot\index.html)
   ├─ Close Edge browser processes
   └─ Log success

Time :05 → Scheduled Task: ForexRegime_CopyReport
│
└─ Backup verification
   ├─ Ensure IIS file is up-to-date
   ├─ Re-copy if needed
   └─ Close Edge processes
\\\

### 3.2 Data Lineage

\\\
Raw Sentiment Data (8 sources)
    ↓ [Validation]
SQLite: sentiment_hourly table
    ↓ [Theory Engine]
SQLite: theory_scores table (22 scores × 9 pairs)
    ↓ [ML Classifier]
SQLite: ml_classifications table (TF/MR predictions)
    ↓ [MCMC Optimizer, conditional]
SQLite: optimizer_weights, optimizer_performance tables
    ↓ [Report Generator]
HTML Files: exhaustive_report.html, index.html
    ↓ [IIS Publishing]
Public Web: https://moneyprod.com
\\\

---

## 4. TECHNOLOGY DECISIONS

### 4.1 Language: Python 3.14

**Rationale**:
- ✅ Rich ML ecosystem (scikit-learn, TensorFlow, PyTorch)
- ✅ Async/await for concurrent I/O (scraping)
- ✅ NumPy/Pandas for vectorized financial computations
- ✅ Playwright for web scraping (better than Selenium)
- ✅ Rapid prototyping → Production (same language)

**Alternatives Considered**:
- ❌ R: Weaker web scraping libraries
- ❌ Java: Verbose, slower development
- ❌ C++: Overkill for I/O-bound tasks

### 4.2 Database: SQLite → PostgreSQL

**Current: SQLite 3.43**
- ✅ Zero configuration
- ✅ Embedded (no server process)
- ✅ Sufficient for 9 pairs × 8 sources
- ❌ Single-writer lock (bottleneck at scale)
- ❌ Limited to ~1TB (SSD constraint)

**Future: PostgreSQL 15**
- ✅ Multi-writer concurrency (100x write throughput)
- ✅ Scales to petabytes
- ✅ Advanced indexing (B-tree, GiST for time-series)
- ✅ Production-grade (ACID compliance)
- ⏳ Migration planned for Q1 2026

**Alternatives Considered**:
- ❌ MySQL: Less sophisticated time-series support
- ❌ MongoDB: Overkill (relational schema is simple)
- ❌ TimescaleDB: Future option (PostgreSQL extension for time-series)

### 4.3 Web Scraping: Playwright

**Rationale**:
- ✅ Modern API (async/await native)
- ✅ Excellent JavaScript rendering (Chromium, Firefox, WebKit)
- ✅ Anti-detection features (stealth mode)
- ✅ Fast: 6.2 seconds avg per source
- ✅ Active development (Microsoft-backed)

**Alternatives Considered**:
- ❌ Selenium: Slower, outdated API, more detectable
- ❌ Requests + BeautifulSoup: Can't handle JavaScript sites
- ❌ Scrapy: Better for large-scale crawling, not for dynamic sites

### 4.4 ML Framework: scikit-learn

**Rationale**:
- ✅ Random Forest implementation: Battle-tested, production-ready
- ✅ Simple API (fit, predict, score)
- ✅ Fast inference (<10ms per prediction)
- ✅ No GPU required (CPU-efficient)
- ✅ Extensive documentation, community support

**Alternatives Considered**:
- ❌ TensorFlow/PyTorch: Overkill for tabular data (22 features)
- ❌ XGBoost: Marginal accuracy gain, more complex tuning
- ✅ Future: LSTM for time-series prediction (regime transitions)

### 4.5 Scheduler: Windows Task Scheduler

**Rationale**:
- ✅ Native OS integration (zero dependencies)
- ✅ Reliable (runs even if user not logged in)
- ✅ Market hours check built-in (via PowerShell)
- ✅ Logs to Windows Event Viewer
- ✅ Windowless execution (pythonw.exe)

**Alternatives Considered**:
- ❌ Cron (Linux): Requires WSL or Linux server
- ❌ Airflow: Heavyweight for single-pipeline system
- ❌ Celery: Requires Redis/RabbitMQ, more complexity

---

## 5. SCALABILITY CONSIDERATIONS

### 5.1 Current Bottlenecks

| Bottleneck | Impact | Solution |
|------------|--------|----------|
| SQLite single-writer | Limits to ~10 writes/sec | Migrate to PostgreSQL (1000x improvement) |
| Sequential scrapers | Some sources block async | Distributed scraping (Scrapy cluster) |
| Single-threaded MCMC | 28 minutes per run | Parallel tempering (multi-chain MCMC) |
| Monolithic pipeline | Hard to scale horizontally | Microservices (Docker + Kubernetes) |

### 5.2 Scalability Targets

**Year 2026 Goals**:

| Metric | Current | Target 2026 | Multiplier |
|--------|---------|-------------|------------|
| Currency Pairs | 9 | 100 | 11x |
| Data Sources | 8 | 50 | 6x |
| Hourly Data Points | 513 | 5,000 | 10x |
| Database Size | 142 MB | 10 GB | 70x |
| ML Predictions/Hour | 216 | 2,400 | 11x |
| End-to-End Latency | 60s | 10s | 6x faster |

### 5.3 Architecture Evolution

**Phase 1 (Current): Monolithic**
\\\
[Single Python Process]
  ├─ Scrapers (8)
  ├─ Theory Engine
  ├─ ML Classifier
  ├─ MCMC Optimizer
  └─ Report Generator
     ↓
[SQLite Database]
     ↓
[IIS Web Server]
\\\

**Phase 2 (Q1-Q2 2026): Dockerized**
\\\
[Docker Container: Scrapers]
     ↓
[Docker Container: Theory + ML]
     ↓
[PostgreSQL Database]
     ↓
[Docker Container: Web Server (Nginx)]
\\\

**Phase 3 (Q3-Q4 2026): Microservices (Kubernetes)**
\\\
[Kubernetes Cluster]
  ├─ Pod: Scraper Service (50 replicas, 1 per source)
  ├─ Pod: Theory Service (auto-scaling)
  ├─ Pod: ML Service (GPU-enabled)
  ├─ Pod: MCMC Service (distributed)
  └─ Pod: Web API (RESTful)
       ↓
[PostgreSQL Cluster (3-node HA)]
       ↓
[Redis Cache]
       ↓
[Grafana Dashboard (monitoring)]
\\\

### 5.4 Cost-Benefit Analysis

**Current Infrastructure Cost**: ~\,540/year
- Windows Server license: \/year
- Azure VM (8 cores, 32 GB): \,800/year
- Storage: \/year

**Scaled Infrastructure Cost** (2026 target): ~\,000/year
- Kubernetes cluster (5 nodes): \,000/year
- PostgreSQL managed (Azure): \,000/year
- Storage (10 GB + logs): \,000/year

**Value Generated**:
- Automation savings: \,000/year (720 hours manual analysis avoided)
- Trading performance: [Proprietary]
- Academic value: MSc thesis, publications

**ROI**: 450% (conservative, excluding trading profits)

---

## CONCLUSION

This architecture demonstrates:

✅ **Modularity**: Clear separation of concerns, independently replaceable components  
✅ **Scalability**: Designed for 10x growth (9 → 100 pairs)  
✅ **Reliability**: 100% uptime over 720+ hours, comprehensive error handling  
✅ **Performance**: Sub-60-second end-to-end latency  
✅ **Maintainability**: Extensive logging, monitoring, documentation  
✅ **Production-Ready**: Live system with real users (https://moneyprod.com)

The architecture balances **simplicity** (SQLite, monolithic Python) for current needs with **extensibility** (PostgreSQL, microservices) for future scale.

---

**Last Updated**: November 23, 2025
