# FINAL TODO PLAN — Bayesian TB Treatment Success Project

## Fully Bayesian MCMC Analysis of WHO Data, 2012–2023

> **Course:** Fundamentals of Statistical Learning II — M.Sc. in Data Science, a.y. 2025–2026
> **Last updated:** 2026-04-05
> **Note:** This is an individual final project. It is submitted as a written report and then discussed orally.

---

## How to Use This Document

- Each **Phase** is a major project milestone.
- Each **Step** within a phase is a concrete, actionable task.
- Mark progress: `[ ]` = not started · `[/]` = in progress · `[x]` = done
- **Deliverables** list what each step must produce.
- **Done-when** defines the acceptance criterion.
- Phases are sequential — complete each before starting the next unless noted otherwise.
- **Decision log:** All frozen choices (year window, predictor set, threshold, baseline region, etc.) must be recorded in `notes/decision_log.md` as they are made.

---

## Course Requirements Traceability

> **Note:** This traceability table is approximate. The authoritative mapping from course guidelines to final report sections is the report outline in Phase 16, Step 16.1. This table is provided for planning orientation only.

| # | Guideline Requirement | Phase(s) | Status |
|---|----------------------|----------|--------|
| 1 | Meaningful title | 1 (research framing + final window decision) | `[ ]` |
| 2 | Dataset illustration & analysis goals | 1 (goals), 2 (variable audit), 3 (construction), 4 (quality checks), 5 (EDA), 16 (report) | `[ ]` |
| 3 | ≥ 2 alternative statistical models | 1 (justification), 7 (coding), 8 (fitting), 16 (report) | `[ ]` |
| 4 | Role of parameters & inferential goals | 1 (model ladder), 6 (priors), 7 (model definitions), 9 (inference) | `[ ]` |
| 5 | Parameter recovery with simulated data | 11 | `[ ]` |
| 6 | MCMC output illustration | 8 | `[ ]` |
| 7 | Bayesian estimation, hypothesis testing, predictions | 9 (inference + hypothesis testing), 10 (predictions via PPC) | `[ ]` |
| 8 | Model comparison via DIC | 12 | `[ ]` |
| 9 | Recover observed data features (PPC) — "discussion on the ability of the estimated model to recover some features of the observed data" | 10 | `[ ]` |
| B1 | **Bonus:** Formal model checking diagnostics | 8 (convergence diagnostics), 10 (posterior predictive model adequacy checks) | `[ ]` |
| B2 | **Bonus:** Frequentist comparison | 13 | `[ ]` |
| F | Written report + oral discussion | 16, 17 | `[ ]` |

---

# PHASE 0 — Project Infrastructure & Reproducibility Setup

> **Goal:** Establish a clean, reproducible project scaffold before any analysis.

### Step 0.1 — Create the R project directory structure

- [x] Create the following subdirectories inside the project root:

```
scripts/            # Numbered R scripts
models/             # JAGS model files (.jags)
data_raw/           # Original WHO CSVs, preserved unchanged
data_processed/     # Cleaned/locked analysis tables
outputs/
  figures/          # All plots (EDA, diagnostics, PPC, recovery)
  tables/           # All CSV/LaTeX tables
  model_objects/    # Saved MCMC posterior draws (.rds)
  diagnostics/      # Convergence output files
  simulations/      # Parameter recovery datasets & results
report/             # Final PDF report, .Rmd or .tex source
notes/              # Internal memos, decision logs
```

- [x] Save the three raw WHO CSVs unchanged in `data_raw/`. This is the single canonical raw-data directory — do not use `data/` or any other location for raw source files.
- [x] Write a `README.md` describing the folder layout and script order.
- [x] Create `notes/decision_log.md` for recording all frozen choices (year window, predictor set, baseline region, thresholds, reparameterization decisions, recovery-study reductions).

**Deliverables:** Clean directory tree; raw data in `data_raw/`; layout README; empty decision log.
**Done-when:** The entire project can be run from the root with no manual file moving.

---

### Step 0.2 — Define the numbered script pipeline

- [x] Create an ordered script execution plan:

| # | Script | Purpose | Inputs | Outputs |
|---|--------|---------|--------|---------|
| 00 | `00_setup.R` | Load packages, set seed, define paths, helper functions | — | Environment ready |
| 01 | `01_load_and_inspect_data.R` | Import raw CSVs, audit dimensions & keys | `data_raw/` CSVs | `intake_summary.csv` |
| 02 | `02_build_main_analysis_table.R` | Merge, filter, standardize, lock dataset | `data_raw/` CSVs | `main_analysis_table_locked.csv/.rds`, `attrition_table.csv` |
| 03 | `03_eda.R` | All exploratory plots & tables | Locked table | Figures + tables |
| 04 | `04_prior_predictive_checks.R` | Simulate from priors, verify plausibility | Locked table | Prior predictive plots |
| 05 | `05_fit_model_1_binomial.R` | Fit M1 via JAGS | Locked table, JAGS file | Posterior draws |
| 06 | `06_fit_model_2_betabinomial.R` | Fit M2 via JAGS | Locked table, JAGS file | Posterior draws |
| 07 | `07_fit_model_3_hierarchical_betabinomial.R` | Fit M3 via JAGS | Locked table, JAGS file | Posterior draws |
| 08 | `08_mcmc_diagnostics.R` | Trace plots, R-hat, ESS, formal tests | Posterior draws | Diagnostic figures + tables |
| 09 | `09_posterior_inference.R` | Summaries, intervals, directional probs | Posterior draws | Inference tables |
| 10 | `10_posterior_predictive_checks.R` | Y_rep generation, test quantities, p-values | Posterior draws + locked table | PPC figures + tables |
| 11 | `11_parameter_recovery.R` | Simulate → refit → evaluate coverage/bias | Locked table + chosen true parameters (optionally posterior means) | Recovery tables + plots |
| 12 | `12_compute_dic.R` | Observed-data log-likelihood DIC | Posterior draws + locked table | DIC comparison table |
| 13 | `13_frequentist_comparison.R` | GLM, beta-binom, GLMM analogues | Locked table | Comparison table |
| 14 | `14_sensitivity_analyses.R` | 5 sensitivity checks | Various | Sensitivity tables |
| 15 | `15_make_tables_and_figures.R` | Polish all outputs for report | All outputs | Report-ready assets |
| 16 | `16_write_report_support_outputs.R` | Export final numbers for abstract/appendix | All outputs | Summary file |

- [x] Document input/output for each script.

> **Rule:** Downstream sections read frozen exported objects (locked table, posterior draw `.rds` files, exported tables) rather than silently rebuilding them. No section should regenerate an upstream output internally.

> **Implementation note:** The notebook (`notebooks/main.ipynb`) is the sole execution source of truth. The numbered script names above describe *logical stages*, each mapped to a notebook section (A–J). No separate `.R` scripts drive execution.

**Deliverables:** Pipeline mapping table in notebook Section A.
**Done-when:** Another person can understand the execution order.

---

### Step 0.3 — Freeze software stack and reproducibility settings

- [x] Decide final R + JAGS software stack:
  - R (record version)
  - JAGS (record version)
  - R packages: `rjags`, `coda`, `ggplot2`, `dplyr`, `tidyr`, `readr`, `stringr`, `forcats`, `bayesplot`, `lme4`, `VGAM`, `aod`
- [x] Record exact package versions in a version manifest.
- [x] Set a global random seed convention (e.g., `set.seed(2026)`).
- [x] Implement setup in notebook Section A (cells A0–A7) instead of `scripts/00_setup.R`:
  - [x] Load all packages (including `bayesplot` and `aod`)
  - [x] Set seed
  - [x] Define common paths (`DATA_RAW`, `DATA_PROC`, `OUT_FIG`, `OUT_TAB`, etc.)
  - [x] Define helper functions (safe directory creation, table saving, figure saving, runtime logging)
  - [x] Define a common `ggplot2` theme
  - [x] Log Git commit SHA for reproducibility

**Deliverables:** Notebook Section A (cells A0–A7); `version_manifest.csv`; `git_metadata.yaml`.
**Done-when:** Same code produces same outputs on rerun.

---

# PHASE 1 — Research Framing & Design Freeze

> **Goal:** Lock the research question, model ladder, and analysis rules before touching data.

### Step 1.1 — Freeze the research question

- [ ] Write the final one-sentence project goal:
  > "Build a country-year WHO TB dataset for 2012–2023 and compare whether simple binomial variation, extra-binomial overdispersion, or hierarchical cross-country heterogeneity best explains and predicts TB treatment success."
- [ ] Write the formal research question:
  > "Which Bayesian model best explains and predicts country-year TB treatment success in 2012–2023: a binomial logistic model, a beta-binomial model, or a hierarchical beta-binomial model?"
- [ ] Write a short note on why DIC comparison requires all models on the same dataset.

**Deliverables:** Final wording for title, objective, research question.
**Done-when:** These statements are fixed unless the year window changes after cleaning.

---

### Step 1.2 — Freeze the model ladder

- [ ] Confirm the three Bayesian models:
  - **M1:** Binomial logistic regression (baseline — tests ordinary binomial variability)
  - **M2:** Beta-binomial regression (tests extra-binomial dispersion via phi)
  - **M3:** Hierarchical beta-binomial (tests persistent country heterogeneity via country-level random intercepts u_i and hyperparameter sigma_u)
- [ ] Write a one-paragraph justification for each model.
- [ ] Write a one-paragraph explanation of what each added layer tests.

**Deliverables:** Model ladder summary note.
**Done-when:** No ambiguity about what each model represents.

---

### Step 1.3 — Freeze analysis rules

- [ ] Document and save the following rules before any data work:
  - **Response:** `Y_it = newrel_succ`, `n_it = newrel_coh` (counts only — the observed proportion `prop_success = success / cohort` is used only for descriptive summaries and PPC test quantities; all model fitting uses counts `success` and `cohort` exclusively)
  - **Main inclusion flag:** `rel_with_new_flg == 1` (NOT `used_2021_defs_flg`)
  - **Main cohort threshold:** `cohort >= 50`
  - **Proposed year window:** 2012–2023
  - **Year-window shift rule:** Shift to 2013–2023 only if 2012–2013 are clearly too sparse
  - **Dataset lock rule:** All primary model comparisons use the same locked table
  - **DIC rule:** Observed-data log-likelihood computed in post-processing (not JAGS default DIC)

**Deliverables:** `notes/analysis_rules.md`
**Done-when:** No ad hoc decisions after model fitting starts.

---

# PHASE 2 — Raw Data Intake & Variable Audit

> **Goal:** Understand exactly what is in the WHO files before building the analysis dataset.

### Step 2.1 — Import and inspect all source files

- [ ] Load the three CSVs from `data_raw/`:
  - `TB_outcomes_2026-04-04.csv`
  - `TB_burden_countries_2026-04-04.csv`
  - `TB_data_dictionary_2026-04-04.csv`
- [ ] For each file, confirm: row count, column count, file encoding.
- [ ] Verify `iso3` and `year` exist and are correctly typed.
- [ ] Check for duplicated country names within `iso3`.
- [ ] Check for duplicated `(iso3, year)` rows within each file.

**Deliverables:** `outputs/tables/intake_summary.csv` (file name, rows, columns, duplicate key count).
**Done-when:** Merge key validity confirmed; deduplication need assessed.

---

### Step 2.2 — Build a project-specific variable dictionary

- [ ] For each variable used in the analysis, record:

| Variable | Source File | Definition | Type | Missingness % | Role | Main or Sensitivity |
|----------|------------|------------|------|---------------|------|---------------------|
| `iso3` | Both | Country code | char | — | Identifier | Main |
| `year` | Both | Calendar year | int | — | Predictor | Main |
| `newrel_succ` | Outcomes | Treatment successes | int | ? | Response (Y) | Main |
| `newrel_coh` | Outcomes | Cohort size | int | ? | Response (n) | Main |
| `rel_with_new_flg` | Outcomes | Comparability flag | binary | ? | Filter | Main |
| `used_2021_defs_flg` | Outcomes | Post-2021 definitions | binary | ? | Filter | Sensitivity only |
| `g_whoregion` | Burden | WHO region | char | ? | Categorical predictor | Main |
| `e_inc_100k` | Burden | Incidence per 100k | numeric | ? | Continuous predictor | Main |
| `e_mort_100k` | Burden | Mortality per 100k | numeric | ? | Continuous predictor | Main |
| `c_cdr` | Burden | Case detection ratio | numeric | ? | Continuous predictor | Main |
| `e_tbhiv_prct` | Burden | TB-HIV co-infection % | numeric | ? | Continuous predictor | Sensitivity only |

- [ ] Fill in actual missingness rates after loading.

**Deliverables:** `outputs/tables/project_variable_dictionary.csv`
**Done-when:** Every analysis variable has a documented purpose.

---

### Step 2.3 — Audit outcome availability over time

- [ ] Tabulate by year: count of rows with non-missing `newrel_succ`, `newrel_coh`, `rel_with_new_flg`.
- [ ] Check whether 2012–2013 are sparse after applying the comparability flag.
- [ ] Plot available rows by year (before and after main inclusion flag).

**Deliverables:** Year-by-year completeness table; availability plot.
**Done-when:** Evidence for whether 2012–2023 is feasible.

---

# PHASE 3 — Build & Lock the Main Analysis Table

> **Goal:** Create the single frozen dataset that all primary models will use.

### Step 3.1 — Select relevant columns

- [ ] From outcomes: keep `iso3`, `year`, `newrel_succ`, `newrel_coh`, `rel_with_new_flg`, `used_2021_defs_flg`.
- [ ] From burden: keep `iso3`, `year`, `g_whoregion`, `e_inc_100k`, `e_mort_100k`, `c_cdr`, `e_tbhiv_prct`.

**Deliverables:** Trimmed outcome and burden datasets.
**Done-when:** No irrelevant columns remain.

---

### Step 3.2 — Merge datasets

- [ ] Merge outcomes and burden on `(iso3, year)`.
- [ ] Report: matched rows, unmatched rows from each side, duplicate keys.
- [ ] Resolve any duplicates transparently (prove none exist or apply documented rule).

**Deliverables:** Merged dataset; merge audit table.
**Done-when:** One row = one country-year, no ambiguous duplicates.

---

### Step 3.3 — Construct analysis variables

- [ ] Create: `success = newrel_succ`, `cohort = newrel_coh`, `prop_success = success / cohort` (descriptive/PPC use only — never used as modeled response).
- [ ] Create `country_id` (numeric index for hierarchical model).
- [ ] Create `region_id` (numeric index for JAGS). **Baseline region rule:** Choose the baseline region explicitly (e.g., the most interpretable reference region or alphabetically first), set it to `region_id = 1` with gamma_1 = 0, and use the same baseline across M1, M2, and M3. Record this choice in `notes/decision_log.md`.
- [ ] Standardize continuous predictors (z-scores): `year_z`, `e_inc_100k_z`, `e_mort_100k_z`, `c_cdr_z`.
- [ ] Store raw predictor values and standardization means/SDs.

**Deliverables:** Dataset with model-ready variables; `standardization_metadata.csv`.
**Done-when:** Dataset is directly usable in JAGS.

---

### Step 3.4 — Apply the filtering pipeline & build attrition table

- [ ] Apply filters **in this exact order**, recording row/country/year counts after each step:

| Step | Filter | Rows | Countries | Years |
|------|--------|------|-----------|-------|
| 0 | Raw merged rows | ? | ? | ? |
| 1 | Restrict to years 2012–2023 | ? | ? | ? |
| 2 | `rel_with_new_flg == 1` | ? | ? | ? |
| 3 | Drop missing/invalid identifiers | ? | ? | ? |
| 4 | Drop missing/invalid outcomes (`cohort > 0`, `success >= 0`, `success <= cohort`) | ? | ? | ? |
| 5 | Drop rows with missing core predictors | ? | ? | ? |
| 6 | Apply `cohort >= 50` | ? | ? | ? |

- [ ] **After Step 2 (`rel_with_new_flg == 1`):** Explicitly report the retained rows, retained countries, and retained years in both the attrition table and the EDA summary. This is a required transparency element per the project plan.

**Deliverables:** Complete `attrition_table.csv`.
**Done-when:** Row-loss at every step is documented.

---

### Step 3.5 — Evaluate year-window feasibility

- [ ] Inspect row counts for 2012 and 2013 after filtering.
- [ ] Inspect country coverage in those years.
- [ ] **Decision:** Keep 2012–2023 if retention is adequate; shift to 2013–2023 only if clearly too sparse.
- [ ] Write a year-window decision memo.

> **Year-window freeze rule:** The final year window must be frozen immediately after this step and before any prior predictive check, model fit, DIC calculation, or sensitivity analysis. If the window changes from the proposed 2012–2023, then the title, abstract, all captions, all filenames, and the final report text must all be updated consistently. Record the frozen window in `notes/decision_log.md`.

**Deliverables:** Year-window decision note.
**Done-when:** Final window is fixed before any model fitting.

---

### Step 3.6 — Lock the main-analysis table

- [ ] Export final dataset as `data_processed/main_analysis_table_locked.csv` and `.rds`.
- [ ] Save metadata file in `.yaml` format (use `.yaml` consistently across all phases) containing: row count, country count, year count, variable names, date created, filter rules, year window, baseline region.
- [ ] **From this point forward, all primary model scripts read exactly this locked file and do not rebuild it internally.**

**Deliverables:** Locked table + `main_analysis_metadata.yaml`.
**Done-when:** All primary model scripts use this single file.

---

### Step 3.7 — Produce the final-sample snapshot

- [ ] Create a compact summary table:

| Item | Value |
|------|-------|
| Final number of countries | ? |
| Final year range | ? |
| Final number of country-years | ? |
| Countries/regions lost to `cohort >= 50` filter | ? |
| Countries/regions disproportionately affected by `cohort >= 50` | ? |

- [ ] This snapshot should appear early in the report alongside the attrition table.

**Deliverables:** `outputs/tables/final_sample_snapshot.csv`
**Done-when:** A reader can immediately understand the retained sample scope.

---

# PHASE 4 — Data Quality & Bias Checks

> **Goal:** Ensure the locked table is defensible.

### Step 4.1 — Missingness audit (pre-filtering)

- [ ] Compute overall missingness rates for all relevant variables.
- [ ] Break down missingness by year and by WHO region.
- [ ] Optionally create a country-year missingness heatmap.

**Deliverables:** Missingness summary table; optional heatmap.
**Done-when:** Can explain what missingness drives sample retention.

---

### Step 4.2 — Cohort-filter impact audit

- [ ] Compare rows before vs after `cohort >= 50`.
- [ ] Report:
  - Rows lost
  - Countries lost entirely
  - Countries partially lost (some years retained, others dropped)
  - Regions disproportionately affected
  - Years disproportionately affected

**Deliverables:** Cohort-filter impact table and figure.
**Done-when:** Can discuss whether the threshold introduces regional, temporal, or country-level selection bias.

---

### Step 4.3 — Predictor collinearity screening

- [ ] Compute pairwise correlations among `e_inc_100k`, `e_mort_100k`, `c_cdr`.
- [ ] Apply threshold: if |r| > 0.85, flag.
- [ ] Optionally compute VIF-style diagnostics.
- [ ] **Decision:** If collinearity too high, retain the more interpretable predictor in main model; move the other to sensitivity only.

> **Predictor freeze rule:** After collinearity screening, the final main predictor set is frozen and must be identical across M1, M2, and M3. Any dropped predictor is moved to sensitivity analyses only. Record the frozen predictor set in `notes/decision_log.md`.

**Deliverables:** Collinearity table; predictor-retention decision note.
**Done-when:** Final main predictor set is stable, justified, and frozen for all main models.

---

# PHASE 5 — Exploratory Data Analysis (EDA)

> **Goal:** Describe the retained sample and motivate the model hierarchy.

### Step 5.1 — Sample overview

- [ ] Report: total country-years, distinct countries, distinct years, year range, countries per WHO region.

### Step 5.2 — Cohort size distribution

- [ ] Histogram of cohort sizes.
- [ ] Summary statistics: min, Q1, median, mean, Q3, max.
- [ ] Compare cohort sizes by region.

### Step 5.3 — Observed success-rate distribution

- [ ] Histogram/density of `prop_success` (descriptive use only).
- [ ] Summary by region and by year.
- [ ] Identify lower-tail country-years.
- [ ] Compute and compare:
  - **Unweighted country-year mean:** (1/N) Σ (Y_it / n_it) — each country-year counts equally.
  - **Cohort-weighted aggregate success rate:** Σ Y_it / Σ n_it — reflects population-weighted performance.
- [ ] Label both consistently as "unweighted country-year mean" and "cohort-weighted aggregate success rate" wherever they appear in EDA and PPC outputs.

### Step 5.4 — Temporal trend analysis

- [ ] Plot average success rate over time.
- [ ] Stratify by WHO region.
- [ ] Optional country-level spaghetti plot.

### Step 5.5 — Bivariate predictor–outcome relationships

- [ ] Scatter/smooth plots: success rate vs incidence, vs mortality, vs case detection ratio.
- [ ] Optionally repeat by region.

### Step 5.6 — Country-level spread assessment

- [ ] Compute per-country mean and SD of observed success rate.
- [ ] Identify consistently high/low performers.
- [ ] Assess whether spread exceeds plausible binomial sampling noise.

### Step 5.7 — Region-year retention heatmap

- [ ] Cross-tabulate retained rows by region × year.
- [ ] Check whether some regions disappear in certain years.

### Step 5.8 — Attrition flow as EDA output

- [ ] Reproduce the attrition table or flow diagram from Phase 3.4 as a polished EDA/report-facing visualization.

### Step 5.9 — Write EDA interpretation notes

- [ ] Answer: Why might a plain binomial model be too restrictive? Is the observed dispersion wide? Are there lower-tail failures? Is there country persistence?

**Deliverables (all sub-steps):** Figures in `outputs/figures/`, tables in `outputs/tables/`, polished attrition flow, EDA interpretation memo.
**Done-when:** EDA leads naturally into the model section; observed overdispersion is (or isn't) documented.

---

# PHASE 6 — Prior Design & Prior Predictive Checks

> **Goal:** Verify the Bayesian models are well-posed before fitting.

### Step 6.1 — Finalize and document all priors

- [ ] Fixed effects: beta_j ~ N(0, 2.5²) for j = 0, 1, …, p
- [ ] Region effects: gamma_r ~ N(0, 2.5²) with gamma_1 = 0 (baseline)
- [ ] Overdispersion: phi ~ Gamma(2, 0.1) [mean = 20, var = 200]
- [ ] Country RE SD: sigma_u ~ Half-Normal(0, 1)
- [ ] Document why standardization makes these priors interpretable.

### Step 6.2 — Implement prior predictive simulations

- [ ] For each model: draw parameters from priors → compute logit link → generate latent theta (M2/M3) → simulate Y.
- [ ] **Use the real retained cohort sizes from the locked main-analysis table** when simulating prior predictive replicated data. This keeps the predictive scale realistic.
- [ ] Compute resulting success-rate summaries.

### Step 6.3 — Evaluate prior predictive plausibility

- [ ] Check distributions don't concentrate at 0 or 1.
- [ ] Compare mean, variance, and lower-tail frequency to plausible ranges.
- [ ] If implausible, adjust priors and re-check.

**Deliverables:** Prior specification note; prior predictive plots; plausibility assessment.
**Done-when:** Priors generate plausible data for this TB treatment context.

---

# PHASE 7 — Model Coding & Pilot Testing

> **Goal:** Code each JAGS model and verify it runs correctly before long MCMC runs.

### Step 7.1 — Prepare JAGS data lists

- [ ] Create R lists with: `N`, `Y`, `n`, predictor matrix `X`, `region[]`, `R`, `country[]`, `C`.
- [ ] Create separate lists for M1, M2, M3 (M1 doesn't need `country[]`/`C`; M1 doesn't need `phi`).

### Step 7.2 — Implement & pilot-test Model 1 (Binomial Logistic)

- [ ] Write `models/model1_binomial.jags`.
- [ ] Run short pilot chain (~500 iterations).
- [ ] Verify: model compiles, parameter dimensions correct, draws finite, no obvious bugs.

### Step 7.3 — Implement & pilot-test Model 2 (Beta-Binomial)

- [ ] Write `models/model2_betabinomial.jags` using latent theta_it construction:
  ```
  theta[i] ~ dbeta(mu[i]*phi, (1-mu[i])*phi)
  Y[i] ~ dbin(theta[i], n[i])
  ```
- [ ] Run short pilot chain.
- [ ] Verify: mu stays in (0,1), phi samples reasonably, latent theta plausible.

### Step 7.4 — Implement & pilot-test Model 3 (Hierarchical Beta-Binomial)

- [ ] Write `models/model3_hierarchical_betabinomial.jags` adding `u[country[i]]` to the logit link.
- [ ] Run short pilot chain.
- [ ] Verify: country indexing correct, u_i dimension correct, sigma_u positive and finite.

> **Countries with one retained year:** Countries that have only a single retained year after filtering are retained in the main analysis unless diagnostics specifically suggest instability. The hierarchical prior on u_i automatically partially pools these countries toward the global mean, so their random intercepts are shrunk and will not distort inference. If convergence issues arise for these countries, flag and discuss them.

### Step 7.5 — Prepare non-centered backup for Model 3

- [ ] Write backup JAGS file with `u_i = sigma_u * z_i`, `z_i ~ N(0,1)`.
- [ ] Use only if centered parameterization mixes poorly.

**Deliverables:** Three JAGS model files (`model1_binomial.jags`, `model2_betabinomial.jags`, `model3_hierarchical_betabinomial.jags`); pilot fit objects; optional backup model.
**Done-when:** All three models run successfully and return sensible pilot output.

---

# PHASE 8 — Full MCMC Fitting & Diagnostics

> **Goal:** Fit all primary models and verify chain quality.

### Step 8.1 — Set final MCMC settings

- [ ] Chains: 4
- [ ] Burn-in: 2,000–4,000 iterations
- [ ] Post-burn-in: 4,000–8,000 iterations per chain
- [ ] Thinning: only if memory is an issue
- [ ] Initial values: dispersed across chains
- [ ] Random seed: fixed and recorded

### Step 8.2 — Fit all three models on locked dataset

- [ ] For each model: run pilot → inspect quick diagnostics → run final chains.
- [ ] Save: posterior draws, monitored parameters, runtime, timestamp, seed, model file used.
- [ ] Log runtime and timestamp for each model fit.

### Step 8.3 — Save posterior draws in standardized format

- [ ] Export posterior samples as `.rds` files with common naming/structure.

### Step 8.4 — Produce visual MCMC diagnostics (for each model)

- [ ] Trace plots for key parameters: `beta_0`, `beta_1`–`beta_4`, region effects (`gamma_r`, with baseline `gamma_1 = 0`), `phi`, `sigma_u`, selected `u_i`.
- [ ] Posterior density plots.
- [ ] Autocorrelation plots.
- [ ] Multi-chain overlaid trace plots.

### Step 8.5 — Compute numerical diagnostics

- [ ] R-hat (target < 1.01, acceptable < 1.05).
- [ ] Effective sample size (target > 400 per key parameter).
- [ ] Monte Carlo standard error.
- [ ] Flag any problematic parameters.

### Step 8.6 — Run formal convergence tests

- [ ] Gelman-Rubin (multi-chain convergence).
- [ ] Geweke (early vs late chain comparison).
- [ ] Heidelberger-Welch (stationarity + half-width).
- [ ] Raftery-Lewis (required run length estimation) — if feasible.

### Step 8.7 — Resolve mixing problems (if any)

- [ ] If diagnostics poor: extend chains, re-check scaling, try non-centered parameterization for M3, document changes.

**Deliverables:** Posterior draw files; diagnostics figures; diagnostics summary table; formal convergence test results.
**Done-when:** All final posteriors come from chains with acceptable diagnostics.

---

# PHASE 9 — Posterior Inference

> **Goal:** Extract and interpret substantive results.

### Step 9.1 — Compute posterior summaries (for each model)

- [ ] Posterior mean, median, 95% equal-tail credible interval, 95% HPD interval.
- [ ] For: fixed effects (`beta_0`, `beta_1`–`beta_4`), region effects (`gamma_r`, with baseline `gamma_1 = 0`), `phi` (M2/M3), `sigma_u` (M3).

### Step 9.2 — Compute directional posterior probabilities (Bayesian hypothesis testing)

> This step covers the "hypothesis testing" component of the course guideline on "Bayesian estimation, hypothesis testing, predictions."

- [ ] P(beta_incidence < 0 | y) — higher burden → lower success?
- [ ] P(beta_mortality < 0 | y)
- [ ] P(beta_cdr > 0 | y) — better detection → higher success?
- [ ] Optionally: posterior probabilities that specific region contrasts (gamma_r) are above/below zero.

### Step 9.3 — Summarize country-level random intercepts (Model 3)

- [ ] Posterior means and credible intervals for each u_i.
- [ ] Rank countries by posterior mean random effect.
- [ ] Identify strongest positive/negative residual countries.
- [ ] Caterpillar plot.

### Step 9.4 — Write substantive interpretation

- [ ] Interpret all effects in words, not only coefficient tables.
- [ ] Address: burden associations, region importance after adjustment, posterior evidence for overdispersion, persistent country heterogeneity.

**Deliverables:** Posterior summary tables; directional probability table; country RE table/plot; interpretation note.
**Done-when:** Statistical output translated into substantive language.

---

# PHASE 10 — Posterior Predictive Checks

> **Goal:** Assess whether the estimated models can recover key features of the observed data. This phase directly addresses the course guideline: "discussion on the ability of the estimated model to recover some features of the observed data."

### Step 10.1 — Generate replicated datasets (for each model)

- [ ] For each posterior draw: simulate Y_rep using real n_it; compute replicated success rates.

### Step 10.2 — Choose and freeze the low-success threshold

- [ ] Inspect the empirical lower tail of the observed success-rate distribution.
- [ ] Consider candidate thresholds (e.g., 0.70, 10th percentile, a policy-relevant benchmark).
- [ ] **Choose one threshold**, justify it in writing, and freeze it before the main PPC comparison.
- [ ] The same frozen threshold must be used across all three models.
- [ ] Record the chosen threshold in `notes/decision_log.md`.

### Step 10.3 — Compute four formal test quantities

| # | Test Quantity | Formula | Key Diagnostic |
|---|--------------|---------|----------------|
| T1 | Mean success rate | **Unweighted country-year mean:** (1/N) Σ Y_it/n_it; **Cohort-weighted aggregate:** Σ Y_it / Σ n_it | Central tendency |
| T2 | Variance of success rates ⭐ | Var(Y_it/n_it) | Overdispersion |
| T3 | Count below frozen low-success threshold | Σ 1(Y_it/n_it < c) | Lower tail |
| T4 | Within-region variance (equally weighted) | (1/R) Σ_r Var_within_r | Regional heterogeneity |

- [ ] Compute posterior predictive p-values for each test quantity and model.
- [ ] For T1, compute and report both the **unweighted country-year mean** and **cohort-weighted aggregate success rate**; label each consistently using these exact terms.
- [ ] For T4, check whether region sizes are highly unequal. If so, also compute a weighted alternative (each region's variance weighted by its number of country-years) as a robustness check, and justify which version is reported as primary.

### Step 10.4 — Produce graphical PPCs

- [ ] Observed vs replicated distribution overlay (histogram/density).
- [ ] Observed statistic marked against replicated distribution.
- [ ] Small vs large cohort calibration check.

### Step 10.5 — Write model adequacy conclusions

- [ ] Does M1 understate variance? Do M2/M3 better capture lower-tail? Does M3 reproduce within-region heterogeneity?

**Deliverables:** PPC summary table + figures; interpretation note.
**Done-when:** Observed-data feature recovery is fully assessed for all three models.

---

# PHASE 11 — Parameter Recovery Simulation

> **Goal:** Verify that the Bayesian procedure can reliably recover true parameter values under the assumed data-generating mechanism. This phase directly addresses the course guideline: "check the ability of a fully Bayesian analysis to recover model parameters with data simulated from the model."

### Step 11.1 — Design the recovery simulation

- [ ] For each of the three models: choose true parameter values from one consistent strategy (either fitted posterior means from real data, or plausible hand-chosen values). **Choose one strategy and use it consistently across all models.** Document the exact true parameter vector used for each model.
- [ ] **Use the same cleaned design structure** as the observed locked table: same cohort sizes n_it, same predictor matrix X, same country IDs, same region IDs. Only the response counts Y are regenerated from the model.
- [ ] Fix and record random seed.
- [ ] Target: 50 simulated datasets per model. If computationally prohibitive, perform 30 with explicit justification and record the reduction reason in `notes/decision_log.md`.

### Step 11.2 — Simulate datasets and refit

- [ ] Generate synthetic datasets (only Y regenerated; design held fixed).
- [ ] Refit each model to its own simulated data.
- [ ] Save posterior summaries and convergence diagnostics for each replicate.
- [ ] Log runtime and timestamp for simulation loops.

### Step 11.3 — Handle convergence failures

- [ ] Store convergence diagnostics (R-hat, ESS) for each refit.
- [ ] Define what counts as a failed replicate (e.g., R-hat > 1.10 for key parameters, or ESS < 100).
- [ ] Report the number of failed replicates transparently.
- [ ] Exclude failed replicates only with explicit justification — never silently.

### Step 11.4 — Evaluate recovery performance

- [ ] Compute: bias, RMSE, 95% equal-tail credible interval coverage, 95% HPD coverage (if feasible).
- [ ] Pay special attention to phi and sigma_u.

### Step 11.5 — Write recovery interpretation

- [ ] Which parameters recovered well? Which are difficult? Is coverage acceptable? Is sigma_u identifiable enough?

**Deliverables:** Recovery summary tables + plots; interpretation note.
**Done-when:** Recovery study demonstrates inferential credibility for all three models.

---

# PHASE 12 — DIC Model Comparison

> **Goal:** Quantitative model ranking on the same dataset.

> ⚠️ **Critical warning:** Do NOT use JAGS's default DIC for M2 or M3 as the primary comparison metric. The latent `theta_it` representation makes the default deviance conditional on latent variables rather than the observed-data beta-binomial likelihood. **Primary DIC must be based on observed-data log-likelihood computed in post-processing.**

### Step 12.1 — Implement observed-data log-likelihood functions

- [ ] Binomial log-PMF for M1.
- [ ] Beta-binomial log-PMF for M2 and M3 (computed from mu_it and phi, NOT from conditional theta_it).

### Step 12.2 — Compute posterior deviance at each MCMC iteration

- [ ] For each saved iteration: evaluate log-likelihood for every observation → sum → D = -2 log L.

### Step 12.3 — Compute DIC

- [ ] Posterior mean deviance `D_bar`.
- [ ] Deviance at posterior mean parameters `D(theta_bar)`. **For M3, "posterior mean parameters" means:** posterior mean fixed effects (beta), posterior mean region effects (gamma_r), posterior mean phi, **and** posterior mean country-level random intercepts (u_i). Plug all of these into the observed-data log-likelihood to compute `D(theta_bar)`.
- [ ] Effective parameters `p_D = D_bar − D(theta_bar)`.
- [ ] `DIC = D_bar + p_D`.

> **WAIC/LOO note:** WAIC or LOO-CV may be computed only as appendix-level supplementary diagnostics. They must not delay the primary DIC-based model comparison workflow.

### Step 12.4 — Interpret DIC differences

| Delta-DIC | Interpretation |
|-----------|----------------|
| > 10 | Strong evidence for lower-DIC model |
| 5–10 | Moderate evidence |
| < 5 | Interpret cautiously |

- [ ] Write conclusion on preferred model and confidence level.

**Deliverables:** DIC comparison table; interpretation note.
**Done-when:** Primary model recommendation is quantitatively supported.

---

# PHASE 13 — Frequentist Comparison (Bonus)

> **Goal:** Mirror each Bayesian model with a frequentist analogue.

### Step 13.1 — Fit frequentist analogues

| Bayesian | Frequentist | R Code |
|----------|-------------|--------|
| M1: Binomial | Binomial GLM | `glm(cbind(success, cohort-success) ~ ..., family=binomial)` |
| M2: Beta-binomial | Beta-binomial regression (see fallback order below) | See priority list |
| M3: Hierarchical | Mixed-effects logistic | `lme4::glmer(cbind(success, cohort-success) ~ ... + (1|country), family=binomial)` |

**Frequentist M2 — explicit fallback order:**

1. **Preferred:** `VGAM::vglm(..., family = betabinomial)` — fits a proper beta-binomial model with explicit overdispersion.
2. **Alternative:** `aod::betabin(...)` — another proper beta-binomial implementation.
3. **Last resort only:** `glm(..., family = quasibinomial)` — use only if both beta-binomial packages fail to converge or are incompatible with the data structure.

> ⚠️ **Warning:** If quasibinomial is used as the M2 frequentist analogue, state clearly in the report that it only adjusts standard errors for overdispersion but does **not** fit an explicit beta-binomial likelihood. It is therefore only a fallback approximation, not a full structural analogue of Bayesian M2. **Do not present quasibinomial results as a true likelihood-based beta-binomial counterpart** — the comparison section must remain methodologically honest about this distinction.

### Step 13.2 — Compare outputs

- [ ] Compare: coefficient signs, effect magnitudes, interval widths (frequentist confidence intervals vs Bayesian credible intervals), overdispersion evidence, country heterogeneity evidence.
- [ ] Produce a clean Bayesian-vs-frequentist comparison table.
- [ ] Note: the frequentist comparison is secondary and explanatory. The primary model recommendation is based on the Bayesian workflow (posterior inference + PPC + DIC). The frequentist section serves to contextualize the Bayesian findings, not to override them.

**Deliverables:** Frequentist model objects; comparison table.
**Done-when:** Section is concise but methodologically clean.

---

# PHASE 14 — Sensitivity Analyses

> **Goal:** Show that main conclusions are not fragile artifacts of specific analytic choices.

### Step 14.1 — Sensitivity: Cohort threshold

- [ ] Rebuild dataset with `cohort > 0` (no minimum).
- [ ] Refit preferred model (or all three).
- [ ] Compare parameter signs, DIC ranking, predictive results.

### Step 14.2 — Sensitivity: Additional predictor (TB-HIV)

- [ ] Add `e_tbhiv_prct` to the model.
- [ ] Rebuild eligible sample (expect sample size loss).
- [ ] Refit and compare conclusions.

### Step 14.3 — Sensitivity: phi prior

- [ ] Try alternative: phi ~ Gamma(1, 0.1) or log(phi) ~ N(0, 2²).
- [ ] Compare posterior and model ranking changes.

### Step 14.4 — Sensitivity: sigma_u prior

- [ ] Try alternative: sigma_u ~ Half-Normal(0, 2.5) or Half-t(3, 0, 1).
- [ ] Compare changes.

### Step 14.5 — Sensitivity: Post-2021 stricter definitions

- [ ] Restrict to 2020–2023 where `used_2021_defs_flg == 1`.
- [ ] Refit preferred model or full ladder.
- [ ] Compare substantive findings.

**Deliverables:** Five sensitivity tables; summary note.
**Done-when:** Main conclusions survive (or transparently fail) under alternative choices.

---

# PHASE 15 — Final Tables, Figures & Appendix Materials

> **Goal:** Polish all outputs into report-ready form.

### Step 15.1 — Finalize all tables

- [ ] Polish: attrition table, final-sample snapshot, variable dictionary, missingness table, collinearity table, posterior summaries, DIC table, PPC table, recovery table, sensitivity summary table, frequentist comparison table.

### Step 15.2 — Finalize all figures

- [ ] Polish all figures with consistent styling, labeling, naming: cohort distribution, success-rate distribution, temporal trends, predictor relationships, region-year heatmap, MCMC diagnostics, PPC plots, country random-effect caterpillar, recovery plots.

### Step 15.3 — Prepare appendix materials

- [ ] Package versions, seeds, script order, file structure, data provenance.
- [ ] Optional additional diagnostics (WAIC/LOO if attempted).

**Deliverables:** Report-ready tables, figures, and appendix materials (version manifest, seeds, script order, data provenance).
**Done-when:** No analysis section depends on rough console output.

---

# PHASE 16 — Report Writing

> **Goal:** Produce the final written report as required by the course.

### Step 16.1 — Draft report section by section

Follow this structure (mirrors course requirements):

| # | Section | Source |
|---|---------|--------|
| 1 | Title | Phase 1 (research framing + final window decision) |
| 2 | Abstract | Synthesis |
| 3 | Introduction & Research Gap | Phase 1 |
| 4 | Dataset & Analysis Goals | Phases 1, 2 |
| 5 | Data Construction & Cleaning | Phases 3, 4 |
| 6 | Exploratory Analysis | Phase 5 |
| 7 | Model 1: Binomial Logistic | Phase 7 |
| 8 | Model 2: Beta-Binomial | Phase 7 |
| 9 | Model 3: Hierarchical Beta-Binomial | Phase 7 |
| 10 | Prior Specification | Phase 6 |
| 11 | MCMC Implementation | Phase 8 |
| 12 | MCMC Diagnostics | Phase 8 |
| 13 | Parameter Recovery | Phase 11 |
| 14 | Posterior Inference | Phase 9 |
| 15 | Posterior Predictive Checks | Phase 10 |
| 16 | DIC Model Comparison | Phase 12 |
| 17 | Frequentist Comparison | Phase 13 |
| 18 | Sensitivity Analyses | Phase 14 |
| 19 | Discussion (including Limitations) | Synthesis |
| 20 | Conclusion | Synthesis |
| 21 | Reproducibility Appendix | Phases 0, 15 |

### Step 16.2 — Write the Discussion

- [ ] Answer the research question.
- [ ] Explain why preferred model is preferred.
- [ ] Address **all five planned limitations explicitly:**
  1. **Ecological fallacy:** Country-level data cannot support individual-level causal claims.
  2. **Reporting heterogeneity:** Countries differ in data quality, surveillance capacity, and conventions.
  3. **Outcome-definition changes over time:** Shift from `new_sp_*` to `newrel_*` framework; partially mitigated by `rel_with_new_flg` filter and post-2021 sensitivity.
  4. **Missingness and selective retention:** Filtered rows may not be missing at random; attrition table helps assess this but residual selection bias cannot be ruled out.
  5. **Non-causal interpretation:** Models estimate covariate-conditional associations, not causal effects.
- [ ] Suggest future work.

### Step 16.3 — Write the Conclusion

- [ ] Summarize: binomial adequacy, posterior evidence for overdispersion, posterior evidence for country heterogeneity, model recommendation.

### Step 16.4 — Compile reproducibility appendix

- [ ] Include: R/JAGS versions, R package versions, random seeds, script order, directory layout, data provenance (source URLs, download dates).

**Deliverables:** Full draft report (PDF); appendix materials.
**Done-when:** All analysis is written in narrative form, not just coded.

---

# PHASE 17 — Final Validation & Submission

> **Goal:** Ensure everything is consistent, reproducible, and submission-ready.

### Step 17.1 — Internal consistency check

- [ ] Year window matches in: title, abstract, all captions, filenames.
- [ ] Sample sizes match across all tables.
- [ ] Baseline region is consistent across all models.
- [ ] Predictor set is consistent across main models.
- [ ] DIC is computed on the identical dataset.
- [ ] Model numbering (M1, M2, M3) is consistent throughout.
- [ ] No Bayesian results described with "significance" language.

### Step 17.2 — Reproducibility dry run

- [ ] From a clean R session, rerun the full pipeline in script order.
- [ ] Verify main tables and figures regenerate correctly.
- [ ] Verify report compiles.
- [ ] Verify locked data file is the one actually used everywhere.

### Step 17.3 — Prepare submission package

- [ ] Final written report in PDF.
- [ ] All final tables and figures.
- [ ] Main scripts in execution order.
- [ ] JAGS model files.
- [ ] `notes/decision_log.md` (frozen choices are a reproducibility artifact).
- [ ] README with rerun instructions.
- [ ] No duplicate/obsolete files, no ambiguous names.

### Step 17.4 — Oral discussion preparation

> **Note:** The course requires the project to be submitted as a written report and then discussed orally. Oral preparation is therefore a required component, not optional.

- [ ] Prepare a short presentation covering:
  - Research question & motivation
  - Why WHO TB data, why three models
  - Main analysis table construction
  - Why DIC requires same locked dataset
  - Main posterior findings
  - PPC findings
  - Preferred model & why
  - Key limitations & robustness checks
- [ ] Prepare answers for likely questions:
  - Why not analyze percentages directly?
  - Why beta-binomial rather than quasi-binomial?
  - Why keep countries with only one year in M3?
  - Why compute DIC manually rather than use JAGS default?
  - How do PPCs complement DIC?
  - What does parameter recovery add beyond model fit?
  - Why is this not a causal analysis?
  - What is the role of the priors in this project?
  - Why is `used_2021_defs_flg` not the main filter?

**Deliverables:** Submission-ready archive; oral discussion notes or slides.
**Done-when:** A reviewer can open the project and understand exactly what was submitted.

---

# MASTER CHECKLIST (use at the very end)

### Data ✓
- [ ] Raw files preserved unchanged in `data_raw/`
- [ ] Merge key audited
- [ ] Variable dictionary completed
- [ ] Main-analysis table locked
- [ ] Attrition table completed
- [ ] Final-sample snapshot completed
- [ ] Year window frozen and recorded in decision log
- [ ] Predictor set frozen and recorded in decision log
- [ ] Baseline region frozen and recorded in decision log

### Modeling ✓
- [ ] All three Bayesian models fit successfully
- [ ] Diagnostics acceptable (R-hat, ESS, visual, formal tests)
- [ ] Posterior summaries exported
- [ ] PPC completed (4 test quantities + plots)
- [ ] DIC completed (observed-data log-likelihood, NOT default JAGS DIC for M2/M3)
- [ ] Parameter recovery study completed

### Extensions ✓
- [ ] Frequentist comparison completed
- [ ] All 5 sensitivity analyses completed
- [ ] Appendix materials compiled

### Report ✓
- [ ] Report fully drafted (all 20+ sections)
- [ ] Tables polished
- [ ] Figures polished
- [ ] Discussion written (with all 5 limitations)
- [ ] Conclusion written
- [ ] Internal consistency verified

### Submission ✓
- [ ] Archive prepared
- [ ] README included
- [ ] Decision log complete
- [ ] Oral notes prepared
- [ ] Dry run completed
- [ ] Final PDF exported

---

# PRIORITY TIERS (if time is short)

### Tier 1 — Minimum Passing (must complete)
- Locked main-analysis table
- EDA
- Three Bayesian models fitted
- Basic MCMC diagnostics (trace + R-hat + ESS)
- Posterior summaries
- Posterior predictive checks
- DIC comparison
- Written report

### Tier 2 — Strong Project (highly recommended)
- Formal convergence tests (Geweke, Heidelberger-Welch)
- Parameter recovery simulation (≥30 datasets)
- Frequentist comparison
- All 5 sensitivity analyses
- Reproducibility appendix
- Oral discussion preparation

### Tier 3 — Excellence (nice to have)
- WAIC/LOO-CV in appendix
- Country-year missingness heatmap
- Non-centered parameterization comparison
- 50+ recovery datasets
- Polished oral presentation slides

---

# ONE-SENTENCE EXECUTION SUMMARY

> Build one locked country-year WHO TB dataset → fit three Bayesian models on that exact table → verify MCMC quality → assess observed-data feature recovery with PPCs → demonstrate parameter recovery under simulation → compare models with DIC (observed-data log-likelihood) → test robustness with frequentist and sensitivity analyses → write a fully reproducible report and prepare for oral defense.
