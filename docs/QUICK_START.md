# Quick Start Guide

**Run the Bayesian TB Treatment Success analysis locally or on Colab in R.**

This guide walks you through running the full analysis pipeline using `src/main.R`.

---

## Prerequisites

**For local execution (recommended):**
- R (≥ 4.x)
- JAGS (≥ 4.x) — install from https://mcmc-jags.sourceforge.io/ or via Homebrew (`brew install jags`)
- WHO TB data files in `data/data_raw/`

**For Colab execution:**
- Google account (for Colab and optional Drive integration)
- WHO TB data files in `data/data_raw/`

---

## Step-by-Step

### 1. Run Locally (Recommended)

```bash
# Clone the repository
git clone https://github.com/armanfeili/FSL_2_Final_Project.git
cd FSL_2_Final_Project

# Run the main analysis script
Rscript src/main.R
```

**Alternative methods:**
- In RStudio: Open `src/main.R` and click "Source"
- In R console: `source("src/main.R")`

### 2. Run on Google Colab (Optional)

1. Upload `src/main.R` to Colab or use the GitHub repo
2. Set up R runtime
3. Run the script

> The script auto-detects whether it's running on Colab and will install JAGS and R packages automatically.

### 2. Mount Google Drive (Optional, Colab only)

Mount your Drive if you want outputs to persist across sessions:

1. Click the **folder icon** (📁) in the Colab left sidebar
2. Click **Mount Drive**
3. Authorize if prompted

Or simply run section **A0** of the script — it will check whether Drive is already mounted.

### 3. Verify R Runtime

After opening, confirm you're running R (not Python). The first code cell should show R syntax. You can also check:

```r
R.version.string
# [1] "R version 4.x.x ..."
```

### 4. Run the Script

The script runs sequentially through all sections:

#### **Section A — Setup (Environment + R Packages)**

| Section | Description | Duration |
|---------|-------------|----------|
| A0 | Detect environment (Colab/local) | <1 sec |
| A1 | Set up directory paths | <1 sec |
| A2 | Clone/pull repo from GitHub (Colab only) | ~10 sec |
| A3 | Install R packages + JAGS system library | ~2-5 min (first time) |
| A4 | Load all R libraries | ~5 sec |
| A5 | Set random seed + ggplot2 theme | <1 sec |

**What happens:**
- Drive mounted at `/content/drive/MyDrive/`
- Repo cloned to `/content/FSL_2_Final_Project/`
- R packages installed: `rjags`, `coda`, `MCMCvis`, `tidyverse`, `lme4`, `VGAM`, etc.
- JAGS installed as system dependency via `apt-get`
- Drive folder structure created: `data/`, `runs/`, `output/`

#### **Section B — Data Loading & Cleaning**

| Section | Description | Duration |
|---------|-------------|----------|
| B0 | Load raw WHO CSV files | ~5 sec |
| B1 | Run data cleaning pipeline | ~10 sec |
| B2 | Build sample attrition table | <1 sec |

**What happens:**
- Loads `TB_outcomes_2026-04-04.csv`, `TB_burden_countries_2026-04-04.csv`, `TB_data_dictionary_2026-04-04.csv`, `TB_notifications_2026-04-04.csv`, and `TB_provisional_notifications_2026-04-04.csv` (as needed)
- Merges on `(iso3, year)`, applies filters (2012–2023, `rel_with_new_flg == 1`, `cohort ≥ 50`)
- Constructs `success`, `cohort`, standardized predictors, region/country indices
- Locks the main-analysis table for all subsequent model fitting
- Produces attrition table showing row/country/year counts at each filter step

#### **Section C — Exploratory Data Analysis**

| Section | Description |
|---------|-------------|
| C0 | Descriptive summaries, distributions, temporal trends, bivariate plots |

**What you'll see:**
- Cohort size distribution histogram
- Success rate distribution (overall and by WHO region)
- Temporal trend plots stratified by region
- Correlation matrix among predictors
- Country-level spread assessment

#### **Section D — MCMC Modeling with JAGS**

| Cell | Description | Duration |
|------|-------------|----------|
| D0 | Create timestamped run folder, set MCMC config | <1 sec |
| D1 | Fit Model 1: Binomial Logistic | ~5-15 min |
| D2 | Fit Model 2: Beta-Binomial | ~10-30 min |
| D3 | Fit Model 3: Hierarchical Beta-Binomial | ~15-45 min |

**What happens:**
- Each model is defined as a JAGS model string
- Data list prepared for JAGS: `Y`, `n`, predictor matrix `X`, `region[]`, `country[]`
- MCMC: 4 chains × 4,000 burn-in × 8,000 post-burn-in iterations
- Posterior draws saved to Drive as `.rds` files

**MCMC settings (configurable in D0):**
```r
mcmc_cfg <- list(
  n_chains   = 4,
  n_burnin   = 4000,
  n_iter     = 8000,
  n_thin     = 1,
  seed       = 42
)
```

#### **Section E — MCMC Diagnostics**

| Cell | Description |
|------|-------------|
| E0 | Trace plots, density plots, ACF, R-hat, ESS, Geweke |

**Target thresholds:**
- R-hat < 1.01 (acceptable: < 1.05)
- ESS > 400 per key parameter

#### **Section F — Posterior Inference & Model Comparison**

| Cell | Description |
|------|-------------|
| F0 | Posterior summaries: means, medians, 95% CIs, HPD intervals |
| F1 | Posterior predictive checks: 4 test quantities |
| F2 | DIC model comparison (observed-data log-likelihood) |

**Key DIC note:** For Models 2 & 3, DIC is computed from the beta-binomial log-PMF (not JAGS's default conditional DIC), ensuring valid cross-model comparison.

#### **Section G — Parameter Recovery**

| Cell | Description | Duration |
|------|-------------|----------|
| G0 | Simulate 50 datasets per model, refit, evaluate coverage | ~hours |

#### **Section H — Frequentist Comparison (Bonus)**

| Cell | Description |
|------|-------------|
| H0 | GLM (M1), VGAM beta-binomial (M2), GLMM (M3) |

#### **Section I — Sensitivity Analyses**

| Cell | Description |
|------|-------------|
| I0 | 5 sensitivity checks (cohort threshold, TB-HIV, prior variants, post-2021 definitions) |

#### **Section J — Save Results**

| Cell | Description |
|------|-------------|
| J0 | Summary of all outputs saved to Drive, session info |

---

## Understanding the Output

### Project Folder Structure

After running, your project will have this structure:

```
FSL_2_Final_Project/
├── data/
│   ├── data_raw/                       # WHO CSV files (input)
│   └── data_processed/                 # Locked analysis table (generated)
├── src/
│   ├── main.R                          # Main analysis script (source of truth)
│   ├── models/                         # JAGS model files (.jags)
│   ├── scripts/                        # Optional helper scripts
│   ├── report/                         # Final report exports
│   ├── tests/                          # Smoke tests
│   └── outputs/
│       ├── figures/                    # All plots (EDA, diagnostics, PPC)
│       ├── tables/                     # CSV/LaTeX tables, manifests
│       ├── diagnostics/                # Convergence output files
│       ├── model_objects/              # Saved MCMC posterior draws (.rds)
│       ├── simulations/                # Parameter recovery results
│       └── runs/                       # Timestamped run folders
│           └── 2026-04-05_14-30_bayesian_tb/
│               ├── mcmc_config.yaml
│               ├── mcmc_output/
│               ├── plots/
│               ├── diagnostics/
│               └── tables/
└── docs/                               # Documentation
```

### Key Output Files

| File | Description |
|------|-------------|
| `mcmc_config.yaml` | Frozen MCMC settings for this run |
| `model_objects/model1_samples.rds` | Model 1 posterior draws |
| `model_objects/model2_samples.rds` | Model 2 posterior draws |
| `model_objects/model3_samples.rds` | Model 3 posterior draws |
| `tables/posterior_summaries.csv` | Parameter estimates and intervals |
| `tables/dic_comparison.csv` | DIC values for all three models |
| `plots/trace_*.png` | MCMC trace plots |
| `plots/ppc_*.png` | Posterior predictive check figures |

---

## Customization

### Adjust MCMC Settings

In **Section D**, cell D0, modify `mcmc_cfg`:

```r
mcmc_cfg <- list(
  n_chains   = 4,       # Number of MCMC chains
  n_burnin   = 4000,    # Burn-in iterations (increase if mixing poor)
  n_iter     = 8000,    # Post-burn-in iterations per chain
  n_thin     = 1,       # Thinning (increase if memory issues)
  seed       = 42       # Random seed
)
```

### Change Year Window

In **Section B**, modify the cleaning pipeline:

```r
# Default: 2012–2023
# If early years are sparse, shift:
dat <- dat %>% filter(year >= 2013, year <= 2023)
```

### Modify Priors

In **Section D**, edit the JAGS model strings:

```r
# Default: weakly informative
beta0 ~ dnorm(0, 1/(2.5*2.5))

# More informative:
beta0 ~ dnorm(0, 1/(1.0*1.0))

# Alternative phi prior:
phi ~ dgamma(1, 0.1)  # instead of dgamma(2, 0.1)
```

---

## Troubleshooting

### JAGS Not Found (Local)

**Error:**
```
Error in jags.model(...) : could not find JAGS
```

**Fix (macOS):**
```bash
brew install jags
```

**Fix (Ubuntu/Debian):**
```bash
sudo apt-get update && sudo apt-get install -y jags
```

**Fix (Windows):**
Download and install from https://mcmc-jags.sourceforge.io/

### JAGS Installation Fails (Colab)

**Error:**
```
E: Unable to locate package jags
```

**Fix:**
```r
system("apt-get update -qq && apt-get install -y -qq jags")
```

### R Package Install Fails

**Error:**
```
ERROR: installation of package 'rjags' had non-zero exit status
```

**Fix:**
1. Ensure JAGS is installed first (cell A3 handles this)
2. Re-run the package installation cell
3. If still failing: `install.packages("rjags", repos = "https://cloud.r-project.org")`

### MCMC Convergence Issues

**Symptom:** R-hat > 1.05 or ESS < 100

**Fix:**
1. Increase burn-in: `n_burnin = 8000`
2. Increase iterations: `n_iter = 16000`
3. Check predictor standardization
4. For Model 3: try non-centered parameterization (`u_i = sigma_u * z_i`, `z_i ~ N(0,1)`)

### Drive Disconnects During Long Run

**Fix:**
- Keep the Colab tab active (don't close it)
- Save intermediate results to Drive frequently
- For very long runs, consider using Colab Pro for longer session limits

### Memory Errors

**Error:**
```
Error: cannot allocate vector of size X.X Gb
```

**Fix:**
- Increase thinning: `n_thin = 5` (keeps every 5th draw)
- Monitor fewer parameters
- For parameter recovery: reduce from 50 to 30 simulated datasets

---

## Expected Timings (Colab Standard)

| Task | Duration |
|------|----------|
| Setup (Section A) | ~3-5 min (first time); ~30 sec (cached) |
| Data loading & cleaning (Section B) | ~15 sec |
| EDA (Section C) | ~30 sec |
| Model 1 MCMC (Section D) | ~5-15 min |
| Model 2 MCMC (Section D) | ~10-30 min |
| Model 3 MCMC (Section D) | ~15-45 min |
| Diagnostics (Section E) | ~1-2 min |
| Inference & DIC (Section F) | ~5-10 min |
| Parameter Recovery (Section G) | ~2-6 hours |
| Frequentist (Section H) | ~2-5 min |
| Sensitivity (Section I) | ~30 min - 2 hours |
| **Total (without recovery)** | **~1-2 hours** |
| **Total (with recovery)** | **~4-8 hours** |

---

## What's Next?

1. **Read the full [PROJECT_PLAN.md](PROJECT_PLAN.md)** for detailed methodology
2. **Follow the [TODO_PLAN.md](TODO_PLAN.md)** checklist for execution
3. **Upload WHO data files** to `data/data_raw/` (in Drive or the repo)
4. **Run the script** end-to-end:
   ```bash
   Rscript src/main.R
   ```
5. **Write the final report** using outputs from Drive

---

**Questions?** See [README.md](../README.md) or open an issue on GitHub!
