# Bayesian Modeling of Cross-Country TB Treatment Success

**A Fully Bayesian MCMC Analysis of WHO Data, 2012–2023**

> **Course:** Fundamentals of Statistical Learning II — M.Sc. in Data Science, a.y. 2025–2026

---

## Project Overview

This project develops a fully Bayesian analysis of WHO tuberculosis country-year data to study treatment success in 2012–2023. The central question is:

> **Which Bayesian model best explains and predicts country-year TB treatment success: a binomial logistic model, a beta-binomial model, or a hierarchical beta-binomial model?**

The analysis compares three models of increasing complexity, fitted via MCMC (JAGS), to determine whether simple binomial sampling variability is sufficient or whether overdispersion and country-level heterogeneity must be explicitly modeled.

---

## Execution Model

> **`src/main.R` is the sole execution source of truth.**

All analysis code lives in a single R script. The TODO plan references numbered script stages (00–16); these are *logical stages*, each corresponding to a section in the main script (A–J). The `src/scripts/` directory is reserved for optional helper utilities only.

The script runs identically on **Google Colab** (with R kernel) and **locally** (requires R + JAGS). A `PROJECT_ROOT` variable governs all paths, pointing to the repository root.

**How to run:**
```bash
# From project root
Rscript src/main.R

# Or, source in an R session
source("src/main.R")
```

> **Note:** If needed, an HTML report can later be generated from `src/main.R` using `knitr::spin()` or `rmarkdown`, but the R script remains the single source of truth for execution.

| Variable | Colab | Local |
|----------|-------|-------|
| `PROJECT_ROOT` | `/content/FSL_2_Final_Project` (cloned from GitHub) | Repository root on disk |

All downstream paths (`DATA_RAW`, `DATA_PROCESSED`, `FIGURES_DIR`, etc.) derive from `PROJECT_ROOT`.

---

## Repository Structure

```
FSL_2_Final_Project/
├── data/
│   ├── data_raw/                # Original WHO CSVs — single canonical raw-data dir
│   └── data_processed/          # Locked main-analysis table
├── src/
│   ├── main.R                   # Sole execution entry point (R script)
│   ├── models/                  # JAGS model files (.jags)
│   ├── scripts/                 # Optional helper utilities (not the execution path)
│   ├── tests/
│   │   └── test_smoke.py        # Smoke tests for project structure
│   ├── report/                  # Final PDF report, .Rmd or .tex source
│   └── outputs/
│       ├── figures/             # All plots (EDA, diagnostics, PPC, recovery)
│       ├── tables/              # All CSV/LaTeX tables, version_manifest.csv, git_metadata.yaml
│       ├── model_objects/       # Saved MCMC posterior draws (.rds)
│       ├── diagnostics/         # Convergence output files
│       └── simulations/         # Parameter recovery datasets & results
├── docs/
│   ├── PROJECT_PLAN.md          # Full project plan & methodology
│   ├── TODO_PLAN.md             # Step-by-step execution checklist
│   └── QUICK_START.md           # Detailed setup guide
├── notes/
│   └── decision_log.md          # All frozen choices (year window, predictors, etc.)
├── .gitignore
├── LICENSE
└── README.md                    # This file
```

**Note:** Data files may be gitignored. Place raw WHO CSV files in `data/data_raw/`.

---

## How to Run

### On Google Colab

1. Upload `src/main.R` to Colab or use the GitHub repo URL
2. Set runtime to R (if using a notebook interface)
3. Run the script

The script will clone the repo, install JAGS + R packages, and write all outputs to the appropriate directories.

### Locally (Recommended)

```bash
git clone https://github.com/armanfeili/FSL_2_Final_Project.git
cd FSL_2_Final_Project

# Run the main analysis script
Rscript src/main.R
```

Requirements: R (≥ 4.x), JAGS (≥ 4.x), and the packages listed below. Outputs are written under `src/outputs/`.

**Alternative methods:**
- In RStudio: Open `src/main.R` and run Source
- In R console: `source("src/main.R")`

---

## Analysis Pipeline

> Each row is a *logical stage*, executed as a script section — not a separate `.R` script.

| # | Stage | Script Section | Purpose |
|---|-------|----------------|---------|
| 00 | Setup | **A** | Load packages, seed, paths, helpers |
| 01 | Load & inspect data | **B0** | Import raw CSVs, audit dimensions & keys |
| 02 | Build main analysis table | **B1–B2** | Merge, filter, standardize, lock dataset |
| 03 | EDA | **C** | Exploratory plots & tables |
| 04 | Prior predictive checks | **D** (pre-fit) | Simulate from priors, verify plausibility |
| 05 | Fit M1 (binomial) | **D1** | JAGS fit for Model 1 |
| 06 | Fit M2 (beta-binomial) | **D2** | JAGS fit for Model 2 |
| 07 | Fit M3 (hierarchical) | **D3** | JAGS fit for Model 3 |
| 08 | MCMC diagnostics | **E** | Trace plots, R-hat, ESS, convergence tests |
| 09 | Posterior inference | **F0** | Summaries, intervals, directional probabilities |
| 10 | Posterior predictive checks | **F1** | Y_rep, test quantities, Bayesian p-values |
| 11 | Parameter recovery | **G** | Simulate, refit, coverage/bias |
| 12 | DIC comparison | **F2** | Observed-data log-likelihood DIC |
| 13 | Frequentist comparison | **H** | GLM, VGAM, GLMM analogues |
| 14 | Sensitivity analyses | **I** | 5 robustness checks |
| 15 | Polish outputs | **J** | Final report-ready assets |
| 16 | Report support outputs | **J** | Export final numbers for abstract/appendix |

Full details in [docs/TODO_PLAN.md](docs/TODO_PLAN.md).

---

## Statistical Models

Three Bayesian models are compared on the same locked country-year dataset:

| Model | Likelihood | Overdispersion | Country Effects | Key Test |
|-------|-----------|----------------|-----------------|----------|
| **M1** — Binomial Logistic | Binomial | ✗ | ✗ | Is ordinary binomial variability sufficient? |
| **M2** — Beta-Binomial | Beta-Binomial | ✓ (φ) | ✗ | Does extra-binomial dispersion improve fit? |
| **M3** — Hierarchical Beta-Binomial | Beta-Binomial | ✓ (φ) | ✓ (u_i, σ_u) | Do persistent country effects remain? |

> **M3 parameterization:** The accepted M3 uses a **region-centered non-centered** parameterization (`u[c] = sigma_u * (z[c] - mean_z_region[country_region[c]])` with `z[c] ~ N(0,1)`), which enforces `sum_{c in r} u[c] = 0` within each WHO region. This separates region fixed effects (`gamma_r`) from within-region country random effects, resolving an additive identifiability issue that made plain centered and plain non-centered parameterizations fail to converge. For efficiency, country IDs are permuted to be contiguous within region so the within-region mean is computed via a fast contiguous-range `sum()` rather than a dense `inprod()`. Chains run in parallel (`mclapply`) with independent RNG seeds. Full remediation trail in `notes/decision_log.md`.

All models use:
- **Response:** Treatment success counts `Y_it` out of cohort `n_it`
- **Predictors:** Year, incidence, mortality, case detection (standardized), WHO region (fixed effects)
- **Priors:** Weakly informative Normal(0, 2.5²) for coefficients; Gamma(2, 0.1) for φ; Half-Normal(0, 1) for σ_u
- **MCMC:** 4 chains × 8,000 post-burn-in iterations via JAGS (`rjags`); M3 uses 4 parallel chains via `parallel::mclapply` with independent RNG seeds (adapt=1000, burn=8000, sample=10000)

---

## Data Sources

| File | Location | Role |
|------|----------|------|
| `TB_outcomes_2026-04-04.csv` | `data/data_raw/` | Treatment outcomes (response variable) |
| `TB_burden_countries_2026-04-04.csv` | `data/data_raw/` | Epidemiological burden (predictors) |
| `TB_data_dictionary_2026-04-04.csv` | `data/data_raw/` | Variable definitions and metadata |

**Unit of analysis:** One row = one country-year. All models are fitted on the **same locked main-analysis table** (`data/data_processed/main_analysis_table_locked.csv`).

---

## R Package Stack

| Category | Packages |
|----------|----------|
| **MCMC & Bayesian** | `rjags`, `coda`, `MCMCvis`, `bayesplot` |
| **Data wrangling** | `tidyverse`, `data.table` |
| **Visualization** | `ggplot2`, `patchwork`, `corrplot` |
| **Frequentist** | `lme4`, `VGAM`, `aod` |
| **Utilities** | `yaml`, `knitr`, `car` |

System dependency: **JAGS** (installed automatically in Colab via `apt-get`).

---

## Reproducibility Outputs

Section A of `src/main.R` automatically saves:

| File | Location | Contents |
|------|----------|----------|
| `version_manifest.csv` | `src/outputs/tables/` | R version, JAGS version, all package versions |
| `git_metadata.yaml` | `src/outputs/tables/` | Repo URL, branch, commit SHA, timestamp |
| `setup_metadata.yaml` | `src/outputs/tables/` | Seed, PROJECT_ROOT, all canonical paths |

These files pin the exact environment for every run.

---

## Course Requirements Coverage

| # | Requirement | Status |
|---|-------------|--------|
| 1 | Fully Bayesian analysis using MCMC | ✅ JAGS via `rjags` |
| 2 | Real data from public sources | ✅ WHO TB data |
| 3 | ≥ 2 alternative statistical models | ✅ Three models |
| 4 | Parameter recovery with simulated data | ✅ 50 datasets per model |
| 5 | MCMC output illustration | ✅ Trace, density, ACF plots |
| 6 | Bayesian estimation, hypothesis testing, predictions | ✅ Posteriors, directional probabilities, PPC |
| 7 | Model comparison via DIC | ✅ Observed-data DIC |
| 8 | Recover observed data features (PPC) | ✅ Four test quantities |
| B1 | **Bonus:** Formal model checking diagnostics | ✅ Gelman-Rubin, Geweke, Heidelberger-Welch |
| B2 | **Bonus:** Frequentist comparison | ✅ GLM, VGAM, GLMM analogues |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Missing R packages | Run: `install.packages(c("rjags", "coda", "MCMCvis", "tidyverse", ...))` |
| JAGS not found | Install JAGS from https://mcmc-jags.sourceforge.io/ or via Homebrew (`brew install jags`) |
| Drive mount fails | Click folder icon in sidebar → Mount Drive. Re-authorize if prompted |
| JAGS not found | Re-run cell A3 (installs JAGS via `apt-get`) |
| Package install fails | Check internet; re-run cell A3 |
| MCMC slow / memory issues | Reduce `n_iter` or increase `n_thin` in D0 config |
| R-hat > 1.05 | Extend burn-in, re-check standardization, try non-centered parameterization for M3 |

---

## Key Documentation

- [docs/QUICK_START.md](docs/QUICK_START.md) — Detailed setup and walkthrough
- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md) — Full project plan & methodology
- [docs/TODO_PLAN.md](docs/TODO_PLAN.md) — Step-by-step execution checklist
- [src/main.ipynb](src/main.ipynb) — Main Colab notebook (R kernel)

---

## Creator

Created by **[Arman Feili](https://github.com/armanfeili)** — M.Sc. in Data Science, Sapienza University of Rome

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
