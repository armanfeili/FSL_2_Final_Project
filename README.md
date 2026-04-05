# Bayesian Modeling of Cross-Country TB Treatment Success

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/armanfeili/FSL_2_Final_Project/blob/main/notebooks/main.ipynb)

**A Fully Bayesian MCMC Analysis of WHO Data, 2012–2023**

> **Course:** Fundamentals of Statistical Learning II — M.Sc. in Data Science, a.y. 2025–2026

---

## Project Overview

This project develops a fully Bayesian analysis of WHO tuberculosis country-year data to study treatment success in 2012–2023. The central question is:

> **Which Bayesian model best explains and predicts country-year TB treatment success: a binomial logistic model, a beta-binomial model, or a hierarchical beta-binomial model?**

The analysis compares three models of increasing complexity, fitted via MCMC (JAGS), to determine whether simple binomial sampling variability is sufficient or whether overdispersion and country-level heterogeneity must be explicitly modeled.

---

## Execution Model

> **`notebooks/main.ipynb` is the sole execution source of truth.**

All analysis code lives in a single R-kernel Jupyter notebook. The TODO plan references numbered script stages (00–16); these are *logical stages*, not runnable `.R` files. Each stage maps to a notebook section (A–J). The `scripts/` directory is reserved for optional helper utilities only.

The notebook runs identically on **Google Colab** (primary) and **locally** (requires R + JAGS). Two root variables govern all paths:

| Variable | Colab | Local |
|----------|-------|-------|
| `CODE_ROOT` | `/content/FSL_2_Final_Project` (cloned from GitHub) | Project directory on disk |
| `STORAGE_ROOT` | Google Drive (`MyDrive/Projects/FSL_2_Final_Project/`) | Same as `CODE_ROOT` |

All downstream paths (`DATA_RAW`, `OUT_FIG`, etc.) derive from these two roots.

---

## Repository Structure

```
FSL_2_Final_Project/
├── notebooks/
│   └── main.ipynb               # Sole execution entry point (R kernel)
├── data_raw/                    # Original WHO CSVs — single canonical raw-data dir (gitignored)
├── data_processed/              # Locked main-analysis table (gitignored)
├── outputs/
│   ├── figures/                 # All plots (EDA, diagnostics, PPC, recovery)
│   ├── tables/                  # All CSV/LaTeX tables, version_manifest.csv, git_metadata.yaml
│   ├── model_objects/           # Saved MCMC posterior draws (.rds)
│   ├── diagnostics/             # Convergence output files
│   └── simulations/             # Parameter recovery datasets & results
├── models/                      # JAGS model files (.jags)
├── runs/                        # Per-run timestamped MCMC output folders (gitignored)
├── report/                      # Final PDF report, .Rmd or .tex source
├── scripts/                     # Optional helper utilities (not the execution path)
├── notes/
│   └── decision_log.md          # Frozen choices (year window, predictors, baseline, etc.)
├── docs/
│   ├── PROJECT_PLAN.md          # Full project plan & methodology
│   ├── TODO_PLAN.md             # Step-by-step execution checklist
│   └── QUICK_START.md           # Detailed setup guide
├── tests/                       # Validation scripts
├── requirements.txt             # R package list
├── .gitignore
├── LICENSE
└── README.md                    # This file
```

**Not in repo (gitignored):** `data_raw/`, `data_processed/`, `outputs/`, `runs/`.

---

## How to Run

### On Google Colab (primary)

1. Click the Colab badge above or open: `https://colab.research.google.com/github/armanfeili/FSL_2_Final_Project/blob/main/notebooks/main.ipynb`
2. Mount Google Drive (sidebar folder icon, or run cell A0)
3. **Runtime → Run all**

The notebook will clone the repo, install JAGS + R packages, and write all outputs to Drive.

### Locally

```bash
git clone https://github.com/armanfeili/FSL_2_Final_Project.git
cd FSL_2_Final_Project
```

Requirements: R (≥ 4.x), JAGS (≥ 4.x), and the packages listed below. Then open `notebooks/main.ipynb` in VS Code, JupyterLab, or RStudio and run all cells. Outputs are written under the project root.

---

## Analysis Pipeline

> Each row is a *logical stage*, executed as a notebook section — not a separate `.R` script.

| # | Stage | Notebook Section | Purpose |
|---|-------|------------------|---------|
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

All models use:
- **Response:** Treatment success counts `Y_it` out of cohort `n_it`
- **Predictors:** Year, incidence, mortality, case detection (standardized), WHO region (fixed effects)
- **Priors:** Weakly informative Normal(0, 2.5²) for coefficients; Gamma(2, 0.1) for φ; Half-Normal(0, 1) for σ_u
- **MCMC:** 4 chains × 8,000 post-burn-in iterations via JAGS (`rjags`)

---

## Data Sources

| File | Location | Role |
|------|----------|------|
| `TB_outcomes_2026-04-04.csv` | `data_raw/` | Treatment outcomes (response variable) |
| `TB_burden_countries_2026-04-04.csv` | `data_raw/` | Epidemiological burden (predictors) |
| `TB_data_dictionary_2026-04-04.csv` | `data_raw/` | Variable definitions and metadata |

**Unit of analysis:** One row = one country-year. All models are fitted on the **same locked main-analysis table** (`data_processed/main_analysis_table_locked.csv`).

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

The notebook's Section A automatically saves:

| File | Location | Contents |
|------|----------|----------|
| `version_manifest.csv` | `outputs/tables/` | R version, JAGS version, all package versions |
| `git_metadata.yaml` | `outputs/tables/` | Repo URL, branch, commit SHA, timestamp |
| `setup_metadata.yaml` | `outputs/tables/` | Seed, CODE_ROOT, STORAGE_ROOT, all canonical paths |

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
| Notebook opens with Python runtime | Kernel is set to `ir` (R) — Colab should auto-detect. If not: Runtime → Change runtime type → R |
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
- [notebooks/main.ipynb](notebooks/main.ipynb) — Main Colab notebook (R kernel)

---

## Creator

Created by **[Arman Feili](https://github.com/armanfeili)** — M.Sc. in Data Science, Sapienza University of Rome

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
