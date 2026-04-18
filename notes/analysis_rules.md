# Analysis Rules

> Pre-committed analysis rules frozen before any model fitting.
> These rules apply to all primary model comparisons (M1, M2, M3).

**Project:** Bayesian Modeling of Cross-Country TB Treatment Success  
**Course:** Fundamentals of Statistical Learning II — M.Sc. in Data Science, a.y. 2025–2026  
**Frozen:** 2026-04-18  
**Phase:** 1 — Research Framing & Design Freeze

---

## 1. Response Variable

| Item | Specification |
|------|---------------|
| Success count | `Y_it = newrel_succ` (number of treatment successes in country i, year t) |
| Cohort size | `n_it = newrel_coh` (total cohort receiving treatment) |
| Modeling approach | **Counts only** — models are always fitted on (Y_it, n_it), never on percentages |
| Derived proportion | `prop_success = success / cohort` is used **only** for descriptive summaries and posterior predictive test quantities, never as the modeled response |

---

## 2. Main Inclusion Flag

| Rule | Value |
|------|-------|
| Primary inclusion criterion | `rel_with_new_flg == 1` |
| Rationale | This flag indicates the row uses the newer reporting framework (new + relapse cases combined via `newrel_*` variables), ensuring comparability across 2012–2023 |

> ⚠️ **Do NOT use `used_2021_defs_flg` as the main filter.** That flag is only populated for 2020–2023. Using it as a hard inclusion rule would collapse the 12-year panel to 4 years. It is reserved for sensitivity analysis only.

---

## 3. Cohort Threshold

| Analysis | Filter | Rationale |
|----------|--------|-----------|
| **Main** | `cohort >= 50` | Reduce instability from very small cohorts |
| **Sensitivity** | `cohort > 0` | Test robustness to the minimum threshold |

---

## 4. Year Window

| Rule | Specification |
|------|---------------|
| Proposed main window | **2012–2023** (12 years) |
| Shift rule | Shift to 2013–2023 **only if** 2012–2013 are clearly too sparse after applying the comparability flag and cohort filter |
| Year-window freeze timing | The final year window is frozen **immediately after data cleaning** (Phase 3) and **before** any prior predictive check, model fit, DIC calculation, or sensitivity analysis |

---

## 5. Dataset Lock Rule

> All primary model comparisons (M1, M2, M3) use the **same locked main-analysis table**.

| Principle | Description |
|-----------|-------------|
| Single source of truth | `data/data_processed/main_analysis_table_locked.csv` and `.rds` |
| No silent rebuilding | Downstream sections read the locked file; they never rebuild it internally |
| DIC validity | All models fitted on identical data enables valid DIC comparison |

---

## 6. DIC Computation Rule

| Rule | Specification |
|------|---------------|
| DIC method | **Observed-data log-likelihood** computed in post-processing |
| Not default JAGS DIC | For M2 and M3, JAGS's default DIC is based on the conditional likelihood p(Y|θ), not the marginal beta-binomial likelihood p(Y|μ,φ). This makes default DIC invalid for cross-model comparison. |
| Implementation | Compute beta-binomial log-PMF at each posterior draw, then calculate DIC from these values |

---

## 7. Predictor Specification

### 7.1 Core Predictors (Main Model)

| Variable | Source | Type | Role |
|----------|--------|------|------|
| `year` | — | Continuous (standardized) | Temporal trend |
| `g_whoregion` | Burden | Categorical (fixed effects) | Regional differences |
| `e_inc_100k` | Burden | Continuous (standardized) | Incidence burden |
| `e_mort_100k` | Burden | Continuous (standardized) | Mortality burden |
| `c_cdr` | Burden | Continuous (standardized) | Case detection performance |

### 7.2 Sensitivity-Only Predictor

| Variable | Source | Reason for Exclusion from Main Model |
|----------|--------|--------------------------------------|
| `e_tbhiv_prct` | Burden | Reduces sample size; not essential to central model-comparison question |

### 7.3 Standardization

All continuous predictors are centered and scaled (z-scores) before model fitting. This makes prior interpretation consistent across predictors on different scales.

### 7.4 Collinearity Rule

| Condition | Action |
|-----------|--------|
| If any pair among `e_inc_100k`, `e_mort_100k`, `c_cdr` has \|r\| > 0.85 | Retain the more interpretable predictor in the main model; move the other to sensitivity analysis |

> **Predictor freeze timing:** The final main predictor set is frozen **after** collinearity screening (Phase 4) and **before** any model fitting. The frozen set must be identical across M1, M2, and M3.

---

## 8. Region Encoding

| Rule | Specification |
|------|---------------|
| Encoding | Fixed effects with one baseline region set to γ₁ = 0 |
| Baseline selection | Chosen explicitly in Phase 3 (e.g., most interpretable or alphabetically first) |
| Consistency | Same baseline used across M1, M2, and M3 |

---

## 9. Model Hierarchy

> Three Bayesian models of increasing complexity, all fitted on the same locked dataset.

| Model | Likelihood | Overdispersion | Country Effects | Key Question |
|-------|-----------|----------------|-----------------|--------------|
| **M1** | Binomial | ✗ | ✗ | Is ordinary binomial variability sufficient? |
| **M2** | Beta-Binomial | ✓ (φ) | ✗ | Does extra-binomial dispersion improve fit? |
| **M3** | Beta-Binomial | ✓ (φ) | ✓ (u_i, σ_u) | Do persistent country effects remain after controlling for burden? |

---

## 10. Prior Specification

| Parameter | Prior | Rationale |
|-----------|-------|-----------|
| Fixed effects β_j | N(0, 2.5²) | Weakly informative; standardization makes scale meaningful |
| Region effects γ_r | N(0, 2.5²) with γ₁ = 0 | Same scale as fixed effects |
| Overdispersion φ | Gamma(2, 0.1) | Mean = 20, wide right tail; uninformative about direction |
| Country RE SD σ_u | Half-Normal(0, 1) | Weakly informative; allows data to drive magnitude |

---

## 11. Countries with Single Retained Year

Countries with only one retained year after filtering are **retained** in the analysis unless diagnostics suggest instability. The hierarchical prior on u_i partially pools these countries toward the global mean, so their random intercepts will be shrunk and will not distort inference.

---

## Document History

| Date | Action | Phase |
|------|--------|-------|
| 2026-04-18 | Initial creation | Phase 1 |
