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

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  LOCAL (VS Code + AI Assistant)                                  │
│  ├─ Edit scripts/, notebooks/, models/                          │
│  ├─ Commit & push to GitHub                                     │
│  └─ No data/runs stored here                                    │
└─────────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  GOOGLE COLAB (R Runtime)                                        │
│  ├─ Clone repo from GitHub (code only)                          │
│  ├─ Mount Google Drive at /content/drive                        │
│  ├─ Install R packages (rjags, coda, tidyverse, etc.)           │
│  ├─ Install JAGS (system dependency)                            │
│  └─ Run analysis → outputs to Drive                             │
└─────────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  GOOGLE DRIVE (MyDrive/Projects/FSL_2_Final_Project/)           │
│  ├─ data/data_raw/             ← WHO CSV files                  │
│  ├─ data/data_processed/       ← Locked main-analysis table     │
│  ├─ runs/<timestamp>/          ← Per-run MCMC outputs           │
│  │   ├─ mcmc_config.yaml       ← Frozen MCMC settings           │
│  │   ├─ mcmc_output/           ← Posterior draws (.rds)          │
│  │   ├─ plots/                 ← Diagnostics, PPC figures        │
│  │   ├─ diagnostics/           ← Convergence results             │
│  │   └─ tables/                ← Summary tables                  │
│  └─ output/                    ← Final polished outputs          │
└─────────────────────────────────────────────────────────────────┘
```

**Key Principle:** Code travels through Git. Data and results stay in Drive.

---

## Quick Start (3 steps)

### 1. Open in Colab
Click the badge above or go to:
```
https://colab.research.google.com/github/armanfeili/FSL_2_Final_Project/blob/main/notebooks/main.ipynb
```

> **Note:** The notebook uses an **R kernel** — Colab will automatically launch the R runtime.

### 2. Mount Google Drive
- Click the **folder icon** in the Colab sidebar → **Mount Drive**
- Or run cell A0 and follow the prompt

### 3. Run All Cells
- **Section A**: Mounts Drive, clones repo, installs R packages + JAGS
- **Section B**: Loads WHO data, applies cleaning pipeline, locks analysis table
- **Section C**: Exploratory data analysis
- **Section D**: Fits all three JAGS models, saves MCMC output
- **Section E**: MCMC diagnostics (trace plots, R-hat, ESS)
- **Section F**: Posterior inference, predictive checks, DIC comparison
- **Section G**: Parameter recovery simulation
- **Section H**: Frequentist comparison (bonus)
- **Section I**: Sensitivity analyses
- **Section J**: Saves all results to Drive

---

## Repository Structure

```
FSL_2_Final_Project/
├── notebooks/
│   └── main.ipynb               # Colab entry point (R kernel)
├── scripts/                     # Numbered R scripts (for local runs)
├── src/
│   └── models/                  # JAGS model files (.jags)
├── data/
│   ├── data_raw/                # Original WHO CSVs (gitignored)
│   └── data_processed/          # Locked analysis table (gitignored)
├── docs/
│   ├── PROJECT_PLAN.md          # Full project plan & methodology
│   ├── TODO_PLAN.md             # Step-by-step execution checklist
│   └── QUICK_START.md           # Detailed setup guide
├── report/                      # Final PDF report source
├── tests/                       # Validation scripts
├── requirements.txt             # R package list
├── .gitignore
├── LICENSE
└── README.md                    # This file
```

**Not in repo:** Raw data, processed data, MCMC outputs, checkpoints — all in Drive or `.gitignore`d.

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

| File | Role |
|------|------|
| `TB_outcomes_2026-04-04.csv` | Treatment outcomes (response variable) |
| `TB_burden_countries_2026-04-04.csv` | Epidemiological burden (predictors) |
| `TB_data_dictionary_2026-04-04.csv` | Variable definitions and metadata |
| `TB_notifications_2026-04-04.csv` | TB notifications (if applicable) |
| `TB_provisional_notifications_2026-04-04.csv` | Provisional notifications (if applicable) |

**Unit of analysis:** One row = one country-year. All models are fitted on the **same locked main-analysis table**.

---

## R Package Stack

| Category | Packages |
|----------|----------|
| **MCMC & Bayesian** | `rjags`, `coda`, `MCMCvis` |
| **Data wrangling** | `tidyverse`, `data.table` |
| **Visualization** | `ggplot2`, `patchwork`, `corrplot` |
| **Frequentist** | `lme4`, `VGAM` |
| **Utilities** | `yaml`, `knitr`, `car` |

System dependency: **JAGS** (installed automatically in Colab via `apt-get`).

---

## Analysis Pipeline

| Phase | Description | Notebook Section |
|-------|-------------|------------------|
| 0 | Project setup & reproducibility | A |
| 1 | Research framing & design freeze | — (documented in `docs/`) |
| 2–4 | Data intake, cleaning, quality checks | B |
| 5 | Exploratory data analysis | C |
| 6 | Prior design & prior predictive checks | D |
| 7–8 | JAGS model coding, pilot testing, full MCMC | D |
| 9 | Posterior inference | F |
| 10 | Posterior predictive checks | F |
| 11 | Parameter recovery simulation | G |
| 12 | DIC model comparison | F |
| 13 | Frequentist comparison (bonus) | H |
| 14 | Sensitivity analyses | I |
| 15–17 | Report writing, validation, submission | J |

Full details in [docs/TODO_PLAN.md](docs/TODO_PLAN.md).

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

## Local Development (Optional)

```bash
# Clone
git clone https://github.com/armanfeili/FSL_2_Final_Project.git
cd FSL_2_Final_Project

# Run R scripts locally (requires R + JAGS installed)
Rscript scripts/00_setup.R
Rscript scripts/01_load_and_inspect_data.R
# ... etc.
```

Edit locally → commit → push → next Colab run pulls latest code automatically.

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
