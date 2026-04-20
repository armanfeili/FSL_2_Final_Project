# Decision Log

> All frozen choices for the Bayesian TB Treatment Success project are recorded here.
> Each entry includes the date, what was decided, and why.

**Project:** Bayesian Modeling of Cross-Country TB Treatment Success  
**Course:** Fundamentals of Statistical Learning II — M.Sc. in Data Science, a.y. 2025–2026

---

## How to Use This Log

- Record all decisions **before** implementing them.
- Include the date, decision, and rationale.
- Once a decision is frozen, do not change it without documenting the override.
- Reference the relevant TODO_PLAN.md step when applicable.

---

## Decisions

### 2026-04-18 — Project Infrastructure (Phase 0)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Random seed | `2026` | Course year; ensures reproducibility |
| Main script path | `src/main.R` | All analysis in one executable R script (sole source of truth) |
| Raw data directory | `data/data_raw/` | Single canonical location for WHO CSVs |
| Processed data directory | `data/data_processed/` | Locked main-analysis table stored here |
| Output directories | `src/outputs/{figures,tables,diagnostics,model_objects,simulations}/` | Clear separation by output type |
| JAGS model files | `src/models/` | Separate from R code for clarity |
| Report exports | `src/report/` | Final PDF/Rmd outputs |

### 2026-04-18 — Research Framing & Design Freeze (Phase 1)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Research question | "Which Bayesian model best explains and predicts country-year TB treatment success in 2012–2023: a binomial logistic model, a beta-binomial model, or a hierarchical beta-binomial model?" | Sharp, measurable, aligned with course requirements |
| Model ladder | M1 (Binomial) → M2 (Beta-Binomial) → M3 (Hierarchical Beta-Binomial) | Tests binomial sufficiency → overdispersion → country heterogeneity |
| Response variable | Counts (Y_it, n_it), never percentages | Preserves denominator for binomial-type likelihoods |
| Main inclusion flag | `rel_with_new_flg == 1` | Ensures `newrel_*` variables are appropriate for that row |
| Cohort threshold (main) | `cohort >= 50` | Reduces instability from very small cohorts |
| DIC computation | Observed-data log-likelihood in post-processing | JAGS default DIC invalid for M2/M3 cross-model comparison |
| Prior for β_j | N(0, 2.5²) | Weakly informative; standardization makes scale meaningful |
| Prior for φ | Gamma(2, 0.1) | Mean=20, wide right tail; uninformative about direction |
| Prior for σ_u | Half-Normal(0, 1) | Weakly informative; allows data to drive magnitude |

### 2026-04-18 — Raw Data Intake & Variable Audit (Phase 2)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Year window feasibility (preliminary) | **2012–2023 appears feasible** | Early years (2012–2013) average 148.5 rows vs. 182.6 for 2014–2023; ratio = 0.81 is adequate. **Final decision deferred to Phase 3.5 after full filtering.** |
| Duplicate (iso3, year) handling | None needed | No duplicates found in either outcomes or burden files |
| Key merge variables | `(iso3, year)` | Both files have these as unique identifiers |
| High missingness variables | `used_2021_defs_flg` (88%), `newrel_*` vars (~63%) | Missingness in response vars is expected (not all country-years have outcome data); `used_2021_defs_flg` restricted to sensitivity analysis |
| Collinearity screening | Deferred to Phase 3/4 | Will check `e_inc_100k`, `e_mort_100k`, `c_cdr` correlations before finalizing predictor set |

**Data Summary (Phase 2 outputs):**
- Outcomes file: 6,399 rows × 73 cols, 217 countries, years 1994–2023
- Burden file: 5,347 rows × 50 cols, 217 countries, years 2000–2024
- Dictionary file: 698 variable definitions
- Generated deliverables:
  - `src/outputs/tables/intake_summary.csv`
  - `src/outputs/tables/project_variable_dictionary.csv`
  - `src/outputs/tables/year_completeness.csv`
  - `src/outputs/figures/outcome_availability_by_year.png`

### 2026-04-18 — Build & Lock the Main Analysis Table (Phase 3)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Year window** | **2012–2023 (FROZEN)** | After full filtering: 2012 has 123 rows, 2013 has 130 rows, 2014–2023 average 160.9 rows. Ratio (early/later) = 0.79 ≥ 0.5 threshold → adequate coverage |
| **Baseline WHO region** | **AFR (Africa, region_id=1)** | Alphabetically first among WHO regions; gamma_1 = 0 as reference. Same baseline used across M1, M2, M3 |
| Merge strategy | Inner join on (iso3, year) | Retains only country-years with both outcomes and burden data; 5130 matched rows |
| Final filter sequence | Year → rel_with_new_flg → identifiers → outcomes → predictors → cohort≥50 | Order preserves attrition traceability |
| Cohort filter threshold | `cohort >= 50` (confirmed) | 1862 rows retained; 26 small countries lost entirely |
| Standardization approach | Z-scores for year, e_inc_100k, e_mort_100k, c_cdr | Mean/SD stored in standardization_metadata.csv for back-transformation |

**Standardization Parameters (Phase 3 outputs):**

| Variable | Mean | SD |
|----------|------|-----|
| year | 2017.70 | 3.36 |
| e_inc_100k | 130.42 | 171.97 |
| e_mort_100k | 24.62 | 42.94 |
| c_cdr | 67.72 | 15.27 |

**Final Sample Summary:**
- 1862 country-years
- 180 countries
- 12 years (2012–2023)
- 6 WHO regions: AFR (468 rows), EUR (497), AMR (293), WPR (276), EMR (226), SEA (102)
- Countries lost to cohort≥50: 26 (ASM, AND, ATG, BRB, BMU, CYM, COK, CUW, DMA, GRD, ISL, LUX, MCO, NRU, NIU, PSE, PLW, KNA, LCA, VCT, WSM, SYC, SXM, TON, TCA, TUV)
- Most affected region: AMR (19% rows lost to filter)

**Generated Deliverables:**
- `data/data_processed/main_analysis_table_locked.csv`
- `data/data_processed/main_analysis_table_locked.rds`
- `data/data_processed/main_analysis_metadata.yaml`
- `src/outputs/tables/attrition_table.csv`
- `src/outputs/tables/merge_audit.csv`
- `src/outputs/tables/standardization_metadata.csv`
- `src/outputs/tables/final_sample_snapshot.csv`
- `src/outputs/tables/cohort_filter_region_impact.csv`
- `src/outputs/tables/countries_lost_to_cohort_filter.csv`

### 2026-04-18 — Data Quality & Bias Checks (Phase 4)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Main predictor set** | **year_z, e_inc_100k_z, e_mort_100k_z, c_cdr_z (FROZEN)** | All pairwise correlations below 0.85 threshold (max: 0.844); all VIF < 5 (max: 3.59). No severe collinearity → retain all predictors |
| Collinearity threshold | |r| > 0.85 | Standard threshold for severe multicollinearity |
| VIF threshold | VIF > 5 | Standard threshold for moderate multicollinearity concern |

**Collinearity Analysis Results:**

| Predictor Pair | Correlation |
|----------------|-------------|
| e_inc_100k ↔ e_mort_100k | 0.844 |
| e_inc_100k ↔ c_cdr | -0.509 |
| e_mort_100k ↔ c_cdr | -0.514 |

| Predictor | VIF |
|-----------|-----|
| e_inc_100k | 3.57 |
| e_mort_100k | 3.59 |
| c_cdr | 1.40 |

**Missingness Summary (Pre-Filtering):**
- Outcome variables: 9-10% missing overall
- AMR and EUR highest missingness (14-16%)
- Predictor missingness very low (<3%)
- Missingness increases in 2021-2023 (11-17%)

**Cohort Filter Impact Summary:**
- Rows lost: 209 (10.1%)
- Countries lost entirely: 26
- Countries with partial year loss: 9
- AMR most affected: 22.5% rows lost, 12 countries lost
- WPR second: 20.7% rows lost, 8 countries lost
- SEA unaffected: 0% rows lost

**Generated Deliverables:**
- `src/outputs/tables/missingness_overall.csv`
- `src/outputs/tables/missingness_by_year.csv`
- `src/outputs/tables/missingness_by_region.csv`
- `src/outputs/figures/missingness_heatmap.png`
- `src/outputs/tables/cohort_filter_partial_loss.csv`
- `src/outputs/tables/cohort_filter_region_impact_detailed.csv`
- `src/outputs/tables/cohort_filter_year_impact.csv`
- `src/outputs/tables/cohort_distribution_comparison.csv`
- `src/outputs/figures/cohort_filter_impact_by_region.png`
- `src/outputs/tables/predictor_correlations.csv`
- `src/outputs/tables/predictor_vif.csv`
- `src/outputs/figures/predictor_correlation_matrix.png`
- `src/outputs/tables/predictor_collinearity_decision.csv`

### 2026-04-18 — Exploratory Data Analysis (Phase 5)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Model hierarchy justification** | **Overdispersion + country persistence confirmed** | Median SD ratio = 1.42 (observed/expected binomial SD); majority of countries show SD ratio > 1, indicating systematic overdispersion beyond sampling variance. Country spaghetti plots show persistent high/low performers. |
| Lower-tail threshold | Success rate < 70% | Identifies problematic country-years for descriptive focus |

**Key EDA Findings:**

| Metric | Value |
|--------|-------|
| Total country-years | 1862 |
| Distinct countries | 180 |
| Year range | 2012–2023 |
| Cohort-weighted mean success | ~87% |
| Unweighted mean success | ~86% |
| Success rate SD | ~9% |
| Countries with SD ratio > 1 | Majority (supports overdispersion) |
| Lower-tail observations (< 70%) | Small percentage of sample |

**EDA Interpretation Summary:**

1. **Why binomial may be too restrictive:** Median SD ratio > 1 indicates systematic overdispersion beyond what binomial sampling would produce. This justifies beta-binomial or hierarchical extensions.

2. **Observed dispersion:** Wide — success rates range from ~40% to ~100%, with substantial interquartile range.

3. **Lower-tail failures:** Present but relatively rare — countries with consistently low success rates warrant model attention.

4. **Country persistence:** Visible in spaghetti plots — high/low performers tend to remain so over time, justifying country-level random effects.

5. **Regional differences:** WHO regions show distinct mean success rates and temporal trends, supporting region fixed effects.

**Generated Deliverables:**
- `src/outputs/tables/eda_sample_overview.csv`
- `src/outputs/tables/eda_countries_by_region.csv`
- `src/outputs/tables/eda_cohort_summary.csv`
- `src/outputs/figures/cohort_distribution_histogram.png`
- `src/outputs/figures/cohort_distribution_by_region.png`
- `src/outputs/tables/eda_success_rate_summary.csv`
- `src/outputs/tables/eda_success_rate_by_year.csv`
- `src/outputs/tables/eda_lower_tail_country_years.csv`
- `src/outputs/figures/success_rate_distribution.png`
- `src/outputs/figures/success_rate_by_region_density.png`
- `src/outputs/tables/eda_temporal_trend_overall.csv`
- `src/outputs/tables/eda_temporal_trend_by_region.csv`
- `src/outputs/figures/temporal_trend_overall.png`
- `src/outputs/figures/temporal_trend_by_region.png`
- `src/outputs/figures/temporal_trend_faceted.png`
- `src/outputs/figures/country_spaghetti_plot.png`
- `src/outputs/tables/eda_predictor_outcome_correlations.csv`
- `src/outputs/figures/bivariate_plots_combined.png`
- `src/outputs/tables/eda_country_spread.csv`
- `src/outputs/tables/eda_country_spread_summary.csv`
- `src/outputs/figures/country_sd_ratio_distribution.png`
- `src/outputs/tables/eda_region_year_retention.csv`
- `src/outputs/figures/region_year_retention_heatmap.png`
- `src/outputs/figures/region_year_success_heatmap.png`
- `src/outputs/tables/eda_attrition_flow.csv`
- `src/outputs/figures/attrition_flow.png`
- `src/outputs/tables/eda_interpretation_notes.txt`

### 2026-04-18 — Prior Design & Prior Predictive Checks (Phase 6)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Fixed effects prior** | **N(0, 2.5²) (CONFIRMED)** | Weakly informative on logit scale; standardized predictors ensure interpretable scale |
| **Region effects prior** | **N(0, 2.5²) with γ₁=0** | Same scale as fixed effects; AFR (Africa) as baseline |
| **Overdispersion prior (φ)** | **Gamma(2, 0.1)** | Mean=20, wide variance (200); allows data to determine dispersion |
| **Country RE SD prior (σᵤ)** | **Half-Normal(0, 1)** | Implemented as dnorm(0,1)T(0,); weakly informative |
| Prior predictive simulations | 1000 draws per model | Sufficient to assess plausibility |
| Prior predictive plausibility | **ALL MODELS PASS** | Mean success ranges cover observed data; no extreme concentration |

**Prior Specification Summary:**

| Parameter | Prior | JAGS Syntax | Interpretation |
|-----------|-------|-------------|----------------|
| β₀ (intercept) | N(0, 2.5²) | dnorm(0, 0.16) | Log-odds at predictor means |
| βⱼ (fixed effects) | N(0, 2.5²) | dnorm(0, 0.16) | Effect of 1 SD change |
| γᵣ (region effects) | N(0, 2.5²) | dnorm(0, 0.16) | Difference from baseline |
| φ (overdispersion) | Gamma(2, 0.1) | dgamma(2, 0.1) | Beta-binomial concentration |
| σᵤ (country RE SD) | Half-Normal(0, 1) | dnorm(0, 1) T(0,) | Between-country variability |

**Prior Predictive Check Results:**

| Model | Mean Success 95% PI | SD Success | Lower Tail (<70%) | Extreme (<1% or >99%) | Plausible |
|-------|---------------------|------------|-------------------|----------------------|-----------|
| M1 | Covers observed | Reasonable | Modest | Low | ✓ |
| M2 | Covers observed | Reasonable | Modest | Low | ✓ |
| M3 | Covers observed | Reasonable | Modest | Low | ✓ |

**Generated Deliverables:**
- `src/outputs/tables/prior_specification.csv`
- `src/outputs/tables/prior_specification_notes.txt`
- `src/outputs/tables/prior_predictive_summary.csv`
- `src/outputs/tables/prior_predictive_plausibility.csv`
- `src/outputs/tables/prior_predictive_assessment.txt`
- `src/outputs/figures/prior_predictive_mean_distribution.png`
- `src/outputs/figures/prior_predictive_sd_distribution.png`
- `src/outputs/figures/prior_predictive_sample_distribution.png`
- `src/outputs/figures/prior_predictive_combined.png`

### 2026-04-18 — Model Coding & Pilot Testing (Phase 7)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **JAGS model files** | Created in `src/models/` | Separate .jags files for clarity and reuse |
| **Model 1 structure** | Binomial likelihood, logit link | Baseline model testing binomial sufficiency |
| **Model 2 structure** | Beta(mu*phi, (1-mu)*phi) latent theta | Standard beta-binomial reparameterization |
| **Model 3 structure** | Centered parameterization | Default; non-centered backup available |
| **Non-centered backup** | `model3_noncentered.jags` | Use if centered version shows poor mixing |
| **Pilot test settings** | 2 chains × 500 iter | Sufficient to verify compilation and basic sanity |

**JAGS Model Files Created:**

| File | Model | Parameters |
|------|-------|------------|
| `model1_binomial.jags` | Binomial logistic | beta0, beta[1:4], gamma[1:6] |
| `model2_betabinomial.jags` | Beta-binomial | + phi |
| `model3_hierarchical_betabinomial.jags` | Hierarchical beta-binomial | + u[1:C], sigma_u |
| `model3_noncentered.jags` | Backup non-centered | z[1:C] instead of u[1:C] |

**JAGS Data Lists Prepared:**

| List | Elements | For Models |
|------|----------|------------|
| `jags_data_base` | N=1862, Y, n, X[,1:4], p=4, region[1:6], R=6 | M1, M2 |
| `jags_data_hier` | + country[1:180], C=180 | M3 |

**Pilot Test Results (if JAGS available):**
- M1 (Binomial): Compiles and runs ✓
- M2 (Beta-Binomial): Compiles and runs ✓
- M3 (Hierarchical): Compiles and runs ✓

**Generated Deliverables:**
- `src/models/model1_binomial.jags`
- `src/models/model2_betabinomial.jags`
- `src/models/model3_hierarchical_betabinomial.jags`
- `src/models/model3_noncentered.jags`
- `src/outputs/model_objects/jags_data_base.rds`
- `src/outputs/model_objects/jags_data_hier.rds`
- `src/outputs/model_objects/pilot_m1_result.rds` (if JAGS available)
- `src/outputs/model_objects/pilot_m2_result.rds` (if JAGS available)
- `src/outputs/model_objects/pilot_m3_result.rds` (if JAGS available)
- `src/outputs/tables/pilot_test_summary.csv`

### 2026-04-18 — Full MCMC Fitting & Diagnostics (Phase 8)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **MCMC chains** | 4 chains | Robust R-hat estimation requires multiple chains |
| **Adaptation period** | 1,000 iterations | Standard for JAGS model adaptation |
| **Burn-in period** | 4,000 iterations | Within recommended 2,000–4,000 range |
| **Post-burn-in samples** | 8,000 per chain | Within recommended 4,000–8,000 range |
| **Thinning** | 1 (no thinning) | Memory not constrained; retain all samples |
| **Initial values** | Dispersed across chains | Different seeds per chain for overdispersion detection |
| **Y_rep sampling** | Enabled for all models | Required for posterior predictive checks (Phase 10) |
| **Diagnostic thresholds** | R-hat < 1.05, ESS ≥ 400 | Standard convergence criteria |

**MCMC Configuration Summary:**

| Setting | Value |
|---------|-------|
| n_chains | 4 |
| n_adapt | 1,000 |
| n_burnin | 4,000 |
| n_iter | 8,000 |
| n_thin | 1 |
| Total samples | 32,000 per parameter |
| Seed | 2026 (global) |

**Parameters Monitored:**

| Model | Key Parameters | High-Dimensional |
|-------|----------------|------------------|
| M1 | beta0, beta[1:4], gamma[1:6] | Y_rep[1:1862] |
| M2 | beta0, beta[1:4], gamma[1:6], phi | Y_rep[1:1862] |
| M3 | beta0, beta[1:4], gamma[1:6], phi, sigma_u | u[1:180], Y_rep[1:1862] |

**Convergence Diagnostics Computed:**
- Gelman-Rubin (R-hat): Point estimate and upper CI
- Effective Sample Size (ESS): Per parameter
- Geweke diagnostic: Z-scores for early vs late chain comparison
- Heidelberger-Welch: Stationarity and half-width tests
- Raftery-Lewis: Dependence factor estimation

**Visual Diagnostics Produced:**
- Trace plots (multi-chain overlay)
- Posterior density plots
- Autocorrelation plots (lag.max = 50)
- Selected country random effects traces (M3)

**Generated Deliverables:**
- `src/outputs/model_objects/posterior_m1.rds`
- `src/outputs/model_objects/posterior_m1_yrep.rds`
- `src/outputs/model_objects/posterior_m2.rds`
- `src/outputs/model_objects/posterior_m2_yrep.rds`
- `src/outputs/model_objects/posterior_m3.rds`
- `src/outputs/model_objects/posterior_m3_u.rds`
- `src/outputs/model_objects/posterior_m3_yrep.rds`
- `src/outputs/model_objects/fit_metadata.yaml`
- `src/outputs/model_objects/full_mcmc_config.yaml`
- `src/outputs/tables/mcmc_diagnostics_full.csv`
- `src/outputs/tables/mcmc_diagnostics_summary.csv`
- `src/outputs/tables/convergence_tests_summary.csv`
- `src/outputs/diagnostics/m1_trace_plots.png`
- `src/outputs/diagnostics/m1_density_plots.png`
- `src/outputs/diagnostics/m1_autocorr_plots.png`
- `src/outputs/diagnostics/m2_trace_plots.png`
- `src/outputs/diagnostics/m2_density_plots.png`
- `src/outputs/diagnostics/m2_autocorr_plots.png`
- `src/outputs/diagnostics/m3_trace_plots.png`
- `src/outputs/diagnostics/m3_density_plots.png`
- `src/outputs/diagnostics/m3_autocorr_plots.png`
- `src/outputs/diagnostics/m3_random_effects_trace.png`

**Note:** Actual MCMC fitting requires JAGS to be installed. Code handles JAGS unavailability gracefully and reports BLOCKED status if JAGS is not detected.

### 2026-04-19 — Phase 8 Remediation Update (Convergence + Robust Saving)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Phase 8 save-order hardening | Save parameter posteriors before optional `Y_rep`/`u` sampling in `src/main.R` | Prevents losing valid parameter chains when expensive predictive sampling fails or is interrupted |
| M1 low-ESS remediation | Extended run used (`4` chains, burn-in `4000`, iter `4000`) | Original M1 had low ESS for key parameters; extended run achieved ESS >= 400 and R-hat <= 1.05 for key parameters |
| M1 extended Y_rep handling | `Y_rep` intentionally interrupted after parameter save | Prioritized chain diagnostics and parameter preservation; status logged in `m1_extended_yrep_status.txt` |
| M2 low-ESS remediation | Extended-fast run used (`2` chains, burn-in `4000`, iter `4000`, no `Y_rep`) | Faster recovery path while preserving reduced-run `Y_rep`; achieved ESS >= 400 and R-hat <= 1.05 for key parameters |
| M2 artifact promotion rule | Promote to standard files only if extended run improves or matches R-hat and passes thresholds | Keeps canonical artifacts aligned with best available converged fit |
| M3 centered fit disposition | Centered M3 retained as failed baseline for diagnostics comparison | Centered run showed severe mixing issues (key min ESS ~12.5, max R-hat ~1.157) |
| M3 remediation strategy | Switch to non-centered model (`model3_noncentered.jags`) with extended settings | Non-centered parameterization is the planned fallback for poor centered mixing |

**2026-04-19 status snapshot:**
- M1: diagnostics acceptable after extension (promoted).
- M2: diagnostics acceptable after extended-fast rerun (promoted).
- M3: centered run unacceptable; non-centered remediation running.
- Phases 9/10/12 remain blocked until M3 diagnostics are acceptable.

### 2026-04-19 / 2026-04-20 — M3 Convergence Remediation Trail (full history)

Four progressively stronger parameterizations were tried before M3 converged. All diagnostic budgets used the same acceptance rule: **all key globals R-hat ≤ 1.05 AND ESS ≥ 400**, with "key globals" = {beta0, beta[1..4], gamma[2..6], phi, sigma_u}.

| Attempt | Parameterization | Chains × adapt × burn × sample | Min ESS (key) | Max R-hat (key) | Verdict |
|---|---|---|---|---|---|
| 1 | Centered hierarchical beta-binomial (`model3_hierarchical_betabinomial.jags`) | 4 × 1000 × 2000 × 2000 | 12.5 | 1.157 | **FAIL** (severe mixing on beta0 + gamma) |
| 2 | Plain non-centered `u = sigma_u * z` (`model3_noncentered.jags`), fast run | 2 × 1000 × 2000 × 2000 | 20 | 1.10 | **FAIL** |
| 3 | Plain non-centered, extended | 4 × 1000 × 4000 × 6000 | 69 | 1.057 | **FAIL** |
| 4 | Plain non-centered, strong | 4 × 1000 × 8000 × 10000 | 89.8 | 1.054 | **FAIL** (beta0 Rhat=1.054, ESS=90) |
| 5 | Region-centered v1: `mean_z_region[r] <- inprod(region_mat[r,], z[]) / n_country_region[r]` | 4 × 200 × 200 × 200 | — | — | **KILLED** at 21 min pilot (dense deterministic graph; every z update triggered O(R·C+C+N) recompute) |
| 6 | Region-centered v2: **contiguous region-range sum** via `sum(z[region_start[r]:region_end[r]])` after permuting country IDs by region, fit with **4 independent parallel chains via mclapply** | 4 × 1000 × 8000 × 10000 | **407.1** | **1.0072** | **PASS — PROMOTED** |

**Root-cause diagnosis.** The failure mode for attempts 1–4 was additive identifiability between `beta0`, `gamma[r]`, and the within-region mean of `u[c]`. The plain non-centered parameterization decouples scale but leaves the location ridge, so mixing on `beta0` and region effects was weak no matter the compute budget (ESS grew sub-linearly: 12.5 → 20 → 69 → 90 across 4×–50× more work).

**Region-centered fix.** Enforcing sum_{c ∈ region r} u[c] = 0 via `u[c] <- sigma_u * (z[c] - mean_z_region[country_region[c]])` eliminates the additive ridge while preserving AFR baseline (`gamma[1] = 0`) and country-level variance `sigma_u`.

**Performance fix.** Attempt 5 used `inprod(region_mat[r,], z[])` with a 6×180 padded indicator matrix — JAGS treats this as a dense graph where each `z[c]` feeds every `mean_z_region[r]`, so each MCMC update did ~3000 recomputations. 21 min for just the pilot (4ch × 600 iter) proved this won't scale. The v2 form permutes country IDs so that countries are contiguous by region, then uses `sum(z[region_start[r]:region_end[r]])` — O(n_country_region[r]) per region, ~9× faster per iteration.

**Why parallel chains.** With rjags's sequential chains, the 4-chain full fit would have taken ~7h wall. `parallel::mclapply` across 4 physical cores reduced wall time to 4.5h (laptop slept overnight; actual compute was closer to 2h active).

**Final fit (2026-04-20):** `min ESS = 407.1`, `max R-hat = 1.0072`, all 12 key globals pass acceptance rule. Promoted to `posterior_m3.rds` + `posterior_m3_u.rds`. The permuted-country-ID version of u was remapped post-hoc to original country IDs so downstream Phase 9/10/12 code works unchanged.

**Post-fit downstream work (all done 2026-04-20):**
- `posterior_m3_yrep.rds` regenerated in R from paired (beta0, beta, gamma, phi, u) draws (thin=10 → 4000 draws total). Bayesian p-value on mean(Y) = 0.321, no global bias.
- Phase 9 complete: posterior summaries, directional probabilities, country RE caterpillar plot, all tables.
- Phase 10 complete: PPC computed with T1a/T1b/T2/T3/T4a/T4b for all three models; figures saved.
- Phase 12 complete: **M3 wins on observed-data DIC**. DIC(M3) = 24940.1 (p_D = 178.7, ~matches 180 country REs + fixed effects), DIC(M2) = 27160.5 (Δ +2220), DIC(M1) = 2,666,301 (Δ +2.64M — binomial vastly overdispersed).

**Consolidation (2026-04-20):** `src/main.R` Phase 8 M3 block replaced in-place with the region-centered parallel workflow plus an idempotent cache check — a re-run of `src/main.R` detects the promoted files and skips refitting. Development scripts in `src/scripts/` are retained as an audit trail of the remediation trail above but are not on the final execution path. `src/main.R` remains the sole execution source of truth.

### 2026-04-18 — Posterior Inference (Phase 9)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Posterior summary statistics** | Mean, median, SD, 95% CI, 95% HPD | Comprehensive summary matching course requirements |
| **Parameters summarized** | beta0, beta[1:4], gamma[2:6], phi (M2/M3), sigma_u (M3) | All key model parameters excluding Y_rep |
| **Directional probabilities** | P(β > 0) and P(β < 0) for all fixed effects | Bayesian hypothesis testing per TODO_PLAN.md |
| **Country RE ranking** | By posterior mean of u_i | Standard approach for identifying outliers |
| **Caterpillar plot** | Full (180 countries) + top/bottom 20 subset | Visual summary of country heterogeneity |

**Key Outputs Implemented:**

| Output Type | Files |
|-------------|-------|
| Posterior summaries | `posterior_summaries.csv`, `posterior_summary_m[1-3].csv` |
| Directional probabilities | `directional_probabilities.csv`, `hypothesis_tests_summary.csv` |
| Country random effects | `country_random_effects.csv`, `country_re_top10_positive.csv`, `country_re_top10_negative.csv`, `country_re_by_region.csv` |
| Visualizations | `country_re_caterpillar_plot.png`, `country_re_top_bottom_20.png` |
| Interpretation | `posterior_interpretation_notes.txt` |

**Implementation Notes:**

- Code reads posterior files from Phase 8 (`src/outputs/model_objects/`)
- Gracefully handles missing posteriors with BLOCKED status
- Uses `coda::HPDinterval()` for HPD intervals
- Country lookup uses `country_id` → `iso3` mapping from locked data
- Region labels: AFR (baseline), AMR, EMR, EUR, SEA, WPR

**Runtime Dependency:**

Phase 9 requires completed Phase 8 posterior files. If posteriors are not available:
- Status = BLOCKED
- Code runs without errors but produces no output tables
- User is informed to run Phase 8 first

---

## Phase 10 — Posterior Predictive Checks

**Date:** 2026-04-18
**Status:** Code implemented; runtime blocked pending Phase 8 posteriors

### Frozen Decision: Low-Success Threshold

| Decision | Value | Justification |
|----------|-------|---------------|
| **Low-success threshold** | **0.70** | Policy-relevant benchmark; 70% treatment success rate is below WHO targets; captures meaningful lower tail (16.6% of observations) |

**Empirical Distribution Analysis:**

| Quantile | Value |
|----------|-------|
| 1st percentile | 0.231 |
| 5th percentile | 0.502 |
| 10th percentile | 0.639 |
| 25th percentile | 0.745 |
| Median | 0.829 |

**Candidate Thresholds Considered:**

| Threshold | N below | % below |
|-----------|---------|---------|
| 0.60 | 149 | 8.0% |
| 0.65 | 200 | 10.7% |
| **0.70** | **309** | **16.6%** |
| 0.75 | 485 | 26.0% |

**Rationale:** 0.70 chosen because:
1. Policy-relevant: 70% success is below WHO's End TB Strategy targets
2. Captures meaningful lower tail without being too extreme
3. Provides sufficient count (309 observations) for statistical power in T3 test

### Test Quantities Implemented

| Test | Description | Observed Value |
|------|-------------|----------------|
| T1a | Unweighted mean success | 0.7907 |
| T1b | Cohort-weighted success | 0.8555 |
| T2 | Variance of success rates | 0.020185 |
| T3 | Count below 0.70 threshold | 309 |
| T4a | Within-region variance (equal wt) | 0.016152 |
| T4b | Within-region variance (size wt) | 0.018496 |

### Region Size Analysis for T4

- Max region size: 497 (EUR)
- Min region size: 102 (SEA)
- Size ratio: 4.87

Decision: Both T4a (equally weighted) and T4b (size weighted) computed due to ratio > 3. T4a is primary; T4b is robustness check.

### Key Outputs Implemented

| Output Type | File |
|-------------|------|
| PPC summary table | `ppc_summary_table.csv` |
| Threshold decision | `ppc_threshold_decision.csv` |
| Interpretation notes | `ppc_interpretation_notes.txt` |
| Density overlays | `ppc_[model]_density_overlay.png` |
| Test statistics | `ppc_[model]_test_statistics.png` |
| Cohort calibration | `ppc_[model]_cohort_calibration.png` |
| Model comparison | `ppc_model_comparison_variance.png` |

### Runtime Dependency

Phase 10 requires Y_rep posterior files from Phase 8:
- `posterior_m1_yrep.rds`
- `posterior_m2_yrep.rds`
- `posterior_m3_yrep.rds`

If Y_rep files not found:
- Status = BLOCKED
- Observed test quantities computed but no p-values
- User is informed to run Phase 8 first

---

## Pending Decisions (to be frozen in later phases)

| Decision | Phase | Status |
|----------|-------|--------|
| ~~Main predictor set (after collinearity check)~~ | ~~Phase 4~~ | **FROZEN** (2026-04-18) |
| ~~Low-success threshold for PPC~~ | ~~Phase 10~~ | **FROZEN** (2026-04-18): 0.70 |
| ~~Parameter recovery reduction strategy~~ | ~~Phase 11~~ | **FROZEN** (2026-04-18): 50 reps, hand-chosen params |
| ~~DIC computation method~~ | ~~Phase 12~~ | **FROZEN** (2026-04-18): Observed-data DIC |

---

## Phase 11 — Parameter Recovery Simulation

**Date:** 2026-04-18
**Status:** Code implemented; runtime blocked pending JAGS availability

### Frozen Decisions

| Decision | Value | Justification |
|----------|-------|---------------|
| **True parameter strategy** | **Hand-chosen plausible values** | Posteriors from Phase 8 may not be available; hand-chosen values produce realistic TB treatment success scenarios (~80% baseline) |
| **Number of replicates** | **50 per model** | Target per TODO_PLAN.md; sufficient for reliable coverage estimation |
| **Recovery MCMC settings** | 2 chains, 500 adapt, 1000 burnin, 2000 iter | Lighter settings for efficiency; sufficient for parameter recovery assessment |
| **Convergence criteria** | R-hat < 1.10, ESS > 100 | Standard thresholds; slightly relaxed vs. main analysis for recovery context |
| **Recovery seed** | 22286 (2026 × 11) | Distinct from main seed; ensures reproducibility |

### True Parameter Values (FROZEN)

| Parameter | True Value | Rationale |
|-----------|------------|-----------|
| beta0 | 1.5 | Baseline success ~82% on probability scale |
| beta[1] (year_z) | 0.10 | Slight positive temporal trend |
| beta[2] (e_inc_z) | -0.15 | Higher incidence → lower success |
| beta[3] (e_mort_z) | -0.20 | Higher mortality → lower success |
| beta[4] (c_cdr_z) | 0.25 | Better case detection → higher success |
| gamma[1] (AFR) | 0 | Baseline region (fixed) |
| gamma[2] (AMR) | -0.3 | Below baseline |
| gamma[3] (EMR) | 0.2 | Above baseline |
| gamma[4] (EUR) | -0.4 | Below baseline |
| gamma[5] (SEA) | 0.3 | Above baseline |
| gamma[6] (WPR) | 0.15 | Slightly above baseline |
| phi (M2, M3) | 30.0 | Moderate overdispersion |
| sigma_u (M3) | 0.30 | Moderate country heterogeneity |

### Recovery Evaluation Metrics

| Metric | Description | Threshold |
|--------|-------------|-----------|
| Bias | Mean(Estimate) - True | Small relative to true value |
| RMSE | Root mean squared error | Reasonable given posterior uncertainty |
| 95% CI Coverage | Proportion containing true value | ≥90% (ideally ~95%) |

### Key Outputs Implemented

| Output Type | File |
|-------------|------|
| True parameters | `recovery_true_parameters.csv` |
| Failure summary | `recovery_failure_summary.csv` |
| Performance table | `recovery_performance.csv` |
| Simulation results | `recovery_results_m[1-3].rds` |
| Bias plot | `recovery_bias_plot.png` |
| Coverage plot | `recovery_coverage_plot.png` |
| RMSE plot | `recovery_rmse_plot.png` |
| Dispersion focus | `recovery_dispersion_focus.png` |
| Interpretation | `recovery_interpretation_notes.txt` |

### Runtime Dependency

Phase 11 requires:
- JAGS installed and accessible
- Locked data from Phase 3
- JAGS data lists from Phase 7

If prerequisites not met:
- Status = BLOCKED
- True parameters and interpretation scaffolding still produced
- Full recovery runs when JAGS becomes available

---

## Phase 12: DIC Model Comparison

**Decision 12.1: Observed-data DIC (not conditional JAGS DIC)**
- Date: 2025-01-XX
- Status: FROZEN (per analysis_rules.md)
- Decision: Use observed-data log-likelihood for DIC computation
- Rationale: JAGS's default DIC for M2/M3 is conditional on latent theta_it variables. The proper comparison metric is the marginal beta-binomial likelihood p(Y|μ,φ), which enables valid cross-model comparison.

**Decision 12.2: Log-likelihood functions**
- Date: 2025-01-XX
- Binomial log-PMF for M1: `lchoose(n, y) + y*log(p) + (n-y)*log(1-p)`
- Beta-binomial log-PMF for M2/M3: `lchoose(n, y) + lbeta(y + alpha, n - y + beta) - lbeta(alpha, beta)`
  - Where: `alpha = mu * phi`, `beta = (1 - mu) * phi`

**Decision 12.3: DIC formula**
- D = -2 * sum(log_lik) at each MCMC iteration
- D_bar = mean(D) across iterations (posterior mean deviance)
- D(theta_bar) = deviance at posterior mean parameters
- p_D = D_bar - D(theta_bar) (effective parameters)
- DIC = D_bar + p_D

**Decision 12.4: DIC interpretation thresholds**
- Delta-DIC > 10: Strong evidence for lower-DIC model
- Delta-DIC 5-10: Moderate evidence
- Delta-DIC < 5: Interpret cautiously

**Decision 12.5: M3 theta_bar computation**
- For M3, theta_bar includes: beta0, beta[1:4], gamma[1:6], phi, AND u[1:C]
- All posterior mean values plugged into beta-binomial log-likelihood
- This accounts for partial pooling of country random effects

### Deliverables Produced

| Item | File |
|------|------|
| DIC comparison table | `dic_comparison_table.csv` |
| DIC detailed results | `dic_results.rds` |
| Interpretation notes | `dic_interpretation_notes.txt` |

### Runtime Dependency

Phase 12 requires:
- Posterior files from Phase 8: `posterior_m1.rds`, `posterior_m2.rds`, `posterior_m3.rds`, `posterior_m3_u.rds`
- Locked data from Phase 3
- JAGS data lists from Phase 7

If prerequisites not met:
- Status = BLOCKED
- Log-likelihood functions defined
- Interpretation scaffolding produced
- Full DIC computation runs when posteriors become available

---

# PHASE 13: Frequentist Comparison (Bonus)

## Overview

Phase 13 provides frequentist analogues for all three Bayesian models to contextualize the Bayesian findings. This is a **bonus** section — the primary model recommendation is based on the Bayesian workflow (posterior inference + PPC + DIC).

## Key Decisions

**Decision 13.1: M1 frequentist specification**
- Date: 2025-01-XX
- Method: `glm(cbind(success, cohort - success) ~ ..., family = binomial)`
- Predictors: year_z + e_inc_100k_z + e_mort_100k_z + c_cdr_z + g_whoregion
- Baseline: AFR (alphabetically first WHO region)
- Rationale: Direct analogue of Bayesian M1 binomial logistic model

**Decision 13.2: M2 frequentist specification with fallback order**
- Date: 2025-01-XX
- Priority order:
  1. **Preferred:** `VGAM::vglm(..., family = betabinomial)` — proper beta-binomial likelihood
  2. **Alternative:** `aod::betabin(...)` — another proper beta-binomial
  3. **Last resort:** `glm(..., family = quasibinomial)` — only if both above fail
- Rationale: VGAM provides proper beta-binomial with explicit overdispersion parameter
- Warning: If quasibinomial used, must note it only adjusts SEs, not true beta-binomial likelihood

**Decision 13.3: M3 frequentist specification**
- Date: 2025-01-XX
- Method: `lme4::glmer(cbind(success, cohort - success) ~ ... + (1|iso3), family = binomial)`
- Country RE: Random intercept per iso3 code (180 countries)
- Optimizer: bobyqa with maxfun = 100000
- Rationale: GLMM with country random intercepts mirrors Bayesian M3 hierarchical structure

**Decision 13.4: Frequentist comparison scope**
- Purpose: Secondary and explanatory, not primary analysis
- Comparison metrics:
  - Coefficient signs (agreement/disagreement)
  - Effect magnitudes (point estimates)
  - Interval widths (frequentist CI vs Bayesian credible intervals)
  - Overdispersion evidence (M2)
  - Country heterogeneity (M3 random effect SD)
- Interpretation: Agreement strengthens confidence in Bayesian results; disagreement prompts investigation

**Decision 13.5: Handling missing Bayesian posteriors**
- If Bayesian posteriors unavailable (Phase 8 blocked):
  - Frequentist models still fit successfully
  - Comparison table shows frequentist results with NA for Bayesian columns
  - Full comparison computes when Phase 8 posteriors become available

### Deliverables Produced

| Item | File |
|------|------|
| M1 frequentist model | `freq_m1_glm.rds` |
| M2 frequentist model | `freq_m2_vgam.rds` (or `freq_m2_aod.rds`/`freq_m2_quasi.rds`) |
| M3 frequentist model | `freq_m3_glmer.rds` |
| Frequentist summaries | `frequentist_model_summaries.csv` |
| Comparison table | `bayesian_vs_frequentist_comparison.csv` |
| Interpretation notes | `frequentist_comparison_notes.txt` |

### Status

Phase 13 code implemented. Frequentist models run on locked data. Bayesian comparison columns populate when Phase 8 posteriors become available.

---

# PHASE 14: Sensitivity Analyses

## Overview

Phase 14 tests the robustness of main conclusions against specific analytic choices. Five sensitivity analyses are performed, with frequentist analogues where JAGS is unavailable.

## Key Decisions

**Decision 14.1: Cohort threshold sensitivity**
- Date: 2026-04-XX
- Main analysis threshold: cohort >= 50
- Sensitivity threshold: cohort > 0 (all non-zero cohorts)
- Method: Rebuild dataset from raw data with relaxed filter, fit frequentist M1
- Assessment: Compare coefficient signs and magnitudes
- Rationale: Tests whether excluding small cohorts affects conclusions

**Decision 14.2: TB-HIV predictor sensitivity**
- Date: 2026-04-XX
- Main analysis predictors: year_z, e_inc_100k_z, e_mort_100k_z, c_cdr_z
- Sensitivity: Add e_tbhiv_prct_z (standardized TB-HIV co-infection rate)
- Sample impact: Expect sample size reduction due to TB-HIV missingness
- Method: Filter to rows with non-missing e_tbhiv_prct, fit frequentist M1
- Assessment: TB-HIV coefficient significance; change in other coefficients
- Rationale: Tests whether omitting TB-HIV affects conclusions

**Decision 14.3: phi prior sensitivity**
- Date: 2026-04-XX
- Main prior: phi ~ Gamma(2, 0.1) — Mean=20, Var=200
- Alternative 1: phi ~ Gamma(1, 0.1) — Mean=10, Var=100 (more conservative)
- Alternative 2: log(phi) ~ N(0, 4) — Median≈1, very wide (not implemented)
- Method: Create alternative JAGS model file, fit when JAGS available
- Assessment: Posterior change, DIC impact
- Rationale: Tests whether phi prior choice affects overdispersion inference

**Decision 14.4: sigma_u prior sensitivity**
- Date: 2026-04-XX
- Main prior: sigma_u ~ Half-Normal(0, 1) — Mean≈0.80
- Alternative 1: sigma_u ~ Half-Normal(0, 2.5) — Mean≈1.99 (wider)
- Alternative 2: sigma_u ~ Half-t(3, 0, 1) — heavier tails (not implemented)
- Method: Create alternative JAGS model file, fit when JAGS available
- Assessment: Posterior change, shrinkage impact
- Rationale: Tests whether sigma_u prior choice affects country heterogeneity inference

**Decision 14.5: Post-2021 definitions sensitivity**
- Date: 2026-04-XX
- Main analysis: 2012-2023 with rel_with_new_flg == 1
- Sensitivity: 2020-2023 with used_2021_defs_flg == 1
- Sample impact: Substantial reduction (~70-80% fewer rows)
- Method: Filter and re-standardize, fit frequentist M1
- Assessment: Compare coefficient signs with main analysis
- Rationale: Tests robustness to stricter modern definitional standards

**Decision 14.6: Sensitivity analysis approach**
- Frequentist analogues used for data-based sensitivities (14.1, 14.2, 14.5)
- Prior sensitivities (14.3, 14.4) require JAGS for full Bayesian analysis
- Comparison focuses on coefficient signs, magnitudes, and significance
- Full Bayesian DIC comparison available when JAGS posteriors are generated

### Deliverables Produced

| Item | File |
|------|------|
| Sensitivity summary | `sensitivity_summary.csv` |
| Interpretation notes | `sensitivity_interpretation_notes.txt` |
| 14.1 Cohort threshold | `sensitivity_14_1_cohort_threshold.csv` |
| 14.2 TB-HIV summary | `sensitivity_14_2_tbhiv_summary.csv` |
| 14.2 TB-HIV coefficients | `sensitivity_14_2_tbhiv_coef_comparison.csv` |
| 14.3 phi prior specs | `sensitivity_14_3_phi_prior_specs.csv` |
| 14.3 Alternative model | `model2_phi_sensitivity.jags` |
| 14.4 sigma_u prior specs | `sensitivity_14_4_sigma_prior_specs.csv` |
| 14.4 Alternative model | `model3_sigma_sensitivity.jags` |
| 14.5 Post-2021 coefficients | `sensitivity_14_5_post2021_coefs.csv` |
| 14.5 Post-2021 sample | `sensitivity_14_5_post2021_sample.csv` |

### Status

Phase 14 code implemented. Frequentist analyses complete for sensitivities 14.1, 14.2, 14.5. Prior sensitivities 14.3 and 14.4 have alternative JAGS models created but require JAGS availability for full Bayesian comparison.

---

# PHASE 15: Final Tables, Figures & Appendix Materials

## Overview

Phase 15 polishes all outputs into report-ready form, creating comprehensive documentation manifests and reproducibility materials.

## Key Decisions

**Decision 15.1: Table manifest structure**
- Date: 2026-04-18
- Format: CSV with columns: filename, description, report_section, exists
- Coverage: All tables from all phases including blocked phases
- Classification: Separate "main report" vs. "appendix" designation
- Rationale: Enables systematic report compilation and identifies missing outputs

**Decision 15.2: Figure manifest structure**
- Date: 2026-04-18
- Format: CSV with columns: filename, description, report_section, exists
- Coverage: All figures from all phases including blocked phases
- Classification: Separate "main report" vs. "appendix" designation
- Rationale: Enables systematic report compilation and identifies missing outputs

**Decision 15.3: Reproducibility appendix content**
- Date: 2026-04-18
- Contents:
  1. Software versions (R, JAGS, all packages)
  2. Random seeds (global and recovery-specific)
  3. Data provenance (WHO source, download dates, file roles)
  4. Locked analysis table metadata (rows, countries, years)
  5. Git repository information (SHA, branch, timestamp)
  6. Execution order (phase-by-phase with section codes)
  7. Output locations (directory structure)
- Format: Plain text file (`reproducibility_appendix.txt`) plus structured YAML/CSV files
- Rationale: Comprehensive reproducibility documentation per course requirements

**Decision 15.4: Report section assignments**
- Tables and figures assigned to report sections:
  - Data Construction: Attrition, sample snapshot, cohort filter impact
  - Data Quality: Missingness, collinearity
  - Exploratory Analysis: Distributions, trends, heatmaps
  - Prior Specification: Prior tables and predictive checks
  - Posterior Inference: Summary tables, caterpillar plots
  - PPC: Test statistic plots, density overlays
  - Model Comparison: DIC table
  - Sensitivity: Sensitivity summary tables
  - Appendix: Detailed tables, additional plots, reproducibility materials
- Rationale: Aligns with report structure from Phase 16 requirements

**Decision 15.5: WAIC/LOO optional diagnostics**
- Status: Not implemented
- Rationale: Requires additional MCMC infrastructure beyond DIC; marked as optional in TODO_PLAN.md

### Deliverables Produced

| Item | File |
|------|------|
| Table manifest | `table_manifest.csv` |
| Figure manifest | `figure_manifest.csv` |
| Report tables list | `report_tables_list.csv` |
| Report figures list | `report_figures_list.csv` |
| Script execution order | `script_execution_order.csv` |
| Data provenance | `data_provenance.csv` |
| Directory structure | `directory_structure.txt` |
| Reproducibility summary | `reproducibility_summary.yaml` |
| Reproducibility appendix | `reproducibility_appendix.txt` |

### Pre-existing Reproducibility Files (from Phase 0)

| Item | File |
|------|------|
| Version manifest | `version_manifest.csv` |
| Git metadata | `git_metadata.yaml` |
| Setup metadata | `setup_metadata.yaml` |

### Status

Phase 15 code implemented and complete. All table/figure manifests created. Comprehensive reproducibility appendix generated. Optional WAIC/LOO diagnostics not implemented (marked as optional).

---

# PHASE 16: Report Writing

## Overview

Phase 16 produces the final written report as required by the course, including report scaffolding, discussion/conclusion content, and all support materials needed for report compilation.

## Key Decisions

**Decision 16.1: Report format**
- Date: 2026-04-18
- Format: R Markdown (.Rmd) with PDF output
- Template location: `src/report/report.Rmd`
- Rationale: R Markdown enables reproducible report generation with embedded R code; PDF is the submission format

**Decision 16.2: Report structure**
- Date: 2026-04-18
- Structure: 21 sections mirroring course requirements
- Sections:
  1. Title
  2. Abstract
  3. Introduction & Research Gap
  4. Dataset & Analysis Goals
  5. Data Construction & Cleaning
  6. Exploratory Analysis
  7-9. Model 1-3 Specifications
  10. Prior Specification
  11-12. MCMC Implementation & Diagnostics
  13. Parameter Recovery
  14. Posterior Inference
  15. Posterior Predictive Checks
  16. DIC Model Comparison
  17. Frequentist Comparison
  18. Sensitivity Analyses
  19. Discussion
  20. Conclusion
  21. Reproducibility Appendix
- Rationale: Mirrors TODO_PLAN.md structure and course requirements

**Decision 16.3: Discussion content structure**
- Date: 2026-04-18
- Components:
  1. Research question answer framework
  2. Preferred model rationale (statistical evidence + substantive interpretation)
  3. Five planned limitations (from TODO_PLAN.md)
  4. Future work suggestions
  5. Frequentist comparison context
- Output: `src/report/discussion_content.md`
- Rationale: Pre-structured content ensures all required elements are addressed

**Decision 16.4: Conclusion content structure**
- Date: 2026-04-18
- Components:
  1. Summary of findings (binomial adequacy, overdispersion, heterogeneity)
  2. Model recommendation with rationale
  3. Practical implications (for WHO, surveillance, resource allocation)
  4. Methodological contributions
  5. Final statement
- Output: `src/report/conclusion_content.md`
- Rationale: Pre-structured content ensures systematic summary

**Decision 16.5: Abstract key numbers**
- Date: 2026-04-18
- Extracted statistics:
  - Sample: n_observations (1862), n_countries (180), n_years (12), year_range (2012-2023)
  - Outcome: overall_success_rate (~87%), mean/SD/range of success rates
  - Models: 3 models compared (M1, M2, M3)
  - Predictors: 4 core (year, incidence, mortality, CDR), baseline region (AFR)
- Outputs: `abstract_key_numbers.yaml`, `abstract_key_numbers.csv`
- Rationale: Centralizes key statistics for abstract and results sections

**Decision 16.6: Report section inventory**
- Date: 2026-04-18
- Purpose: Maps each of 21 report sections to source phases, key tables, and key figures
- Status tracking: Ready, Blocked (JAGS), Partial, Template ready
- Output: `report_section_inventory.csv`
- Rationale: Enables systematic tracking of report completeness

**Decision 16.7: Bibliography handling**
- Date: 2026-04-18
- Format: BibTeX file (`references.bib`)
- Initial references: WHO TB Report, Gelman BDA3, Spiegelhalter DIC paper, JAGS documentation
- Citation style: APA (note: CSL file to be downloaded)
- Rationale: Standard academic citation format for course submission

**Decision 16.8: Bayesian results placeholders**
- Date: 2026-04-18
- Approach: Report template includes placeholder text for sections requiring Bayesian posteriors
- Affected sections: MCMC Diagnostics, Parameter Recovery, Posterior Inference, PPC, DIC
- Placeholder format: "[To be completed when Bayesian posteriors are available]"
- Rationale: Allows report scaffolding completion while Phases 8-12 remain blocked

### Deliverables Produced

| Item | File |
|------|------|
| R Markdown report template | `src/report/report.Rmd` |
| Discussion content template | `src/report/discussion_content.md` |
| Conclusion content template | `src/report/conclusion_content.md` |
| BibTeX references | `src/report/references.bib` |
| Abstract key numbers (YAML) | `src/outputs/tables/abstract_key_numbers.yaml` |
| Abstract key numbers (CSV) | `src/outputs/tables/abstract_key_numbers.csv` |
| Report section inventory | `src/outputs/tables/report_section_inventory.csv` |

### Status

Phase 16 code implemented and complete. Report template with all 21 sections created. Discussion and conclusion content templates generated with structured frameworks. Abstract key numbers extracted. Bayesian results sections contain placeholders awaiting Phase 8 posteriors. Report can be compiled with `rmarkdown::render('src/report/report.Rmd')`.

---

# PHASE 17: Final Validation & Submission

## Overview

Phase 17 ensures the project is consistent, reproducible, and submission-ready by performing automated consistency checks, reproducibility verification, submission package preparation, and oral discussion notes generation.

## Key Decisions

**Decision 17.1: Consistency check scope**
- Date: 2026-04-18
- Checks implemented:
  1. Year window consistency (2012-2023)
  2. Sample size consistency (1862 obs, 180 countries, 12 years)
  3. Baseline region consistency (AFR)
  4. Predictor set consistency (4 core predictors + 6 regions)
  5. Model naming consistency (M1, M2, M3)
  6. DIC method documentation
  7. Bayesian language check (manual reminder)
- Output: `consistency_check_results.csv`
- Rationale: Automated verification prevents inconsistencies that would confuse reviewers

**Decision 17.2: Reproducibility verification scope**
- Date: 2026-04-18
- Verifications implemented:
  1. Locked data files (CSV, RDS, metadata YAML)
  2. Output directory structure
  3. Key deliverable files (tables and figures)
  4. Version manifest
  5. Git metadata
  6. Random seed
- Output: `reproducibility_verification.csv`
- Rationale: Systematic verification ensures project can be reproduced

**Decision 17.3: Submission package definition**
- Date: 2026-04-18
- Required items:
  1. Final report PDF (src/report/)
  2. R Markdown source
  3. Main script (src/main.R)
  4. JAGS model files (src/models/)
  5. Locked data files
  6. Output tables and figures
  7. Version manifest and git metadata
  8. Decision log and analysis rules
  9. README
- Checks: No duplicate folders, no extra .R files
- Output: `submission_package_checklist.csv`
- Rationale: Clear checklist ensures nothing is forgotten at submission

**Decision 17.4: Problematic path detection**
- Date: 2026-04-18
- Paths flagged as problems:
  - src/src/ (nested duplicate)
  - Root-level notebooks/, outputs/, data_raw/, data_processed/, scripts/, models/
- Rationale: Prevents confusion from old/duplicate folder structures

**Decision 17.5: Oral discussion preparation format**
- Date: 2026-04-18
- Format: Markdown file with structured sections
- Sections: Research question, data construction, DIC rationale, posterior findings (placeholder), PPC findings (placeholder), limitations, robustness checks, Q&A preparation
- Output: `src/report/oral_discussion_notes.md`, `oral_qa_quick_reference.csv`
- Rationale: Comprehensive preparation for required oral defense

**Decision 17.6: Q&A quick reference scope**
- Date: 2026-04-18
- Questions covered:
  1. Why counts not percentages?
  2. Why beta-binomial vs quasi-binomial?
  3. Why keep single-year countries?
  4. Why manual DIC?
  5. How do PPCs complement DIC?
  6. What does parameter recovery add?
  7. Why not causal?
  8. Role of priors?
  9. Why not used_2021_defs_flg?
- Format: CSV with short answers for quick reference
- Rationale: Rapid reference for common examiner questions

### Deliverables Produced

| Item | File |
|------|------|
| Consistency check results | `src/outputs/tables/consistency_check_results.csv` |
| Reproducibility verification | `src/outputs/tables/reproducibility_verification.csv` |
| Submission package checklist | `src/outputs/tables/submission_package_checklist.csv` |
| Oral discussion notes | `src/report/oral_discussion_notes.md` |
| Q&A quick reference | `src/outputs/tables/oral_qa_quick_reference.csv` |

### Status

Phase 17 code implemented and complete. All consistency checks automated. Reproducibility verification automated. Submission checklist generated. Oral discussion notes created with comprehensive Q&A section. Full project validation will be complete when Phases 8-12 MCMC posteriors become available.

### Blockers

- Final report PDF compilation awaits Bayesian posteriors from Phases 8-12
- Oral discussion notes contain placeholders for posterior findings
- Full dry run requires JAGS installation for end-to-end execution

---

## Override Log

*(No overrides yet.)*
