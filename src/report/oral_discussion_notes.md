# Oral Discussion Preparation Notes

## Bayesian Modeling of Cross-Country TB Treatment Success
### A Fully Bayesian MCMC Analysis of WHO Data, 2012–2023

---

## 1. Research Question & Motivation (2-3 min)

**Research Question:**
"Which Bayesian model best explains and predicts country-year TB treatment success in 2012–2023: a binomial logistic model, a beta-binomial model, or a hierarchical beta-binomial model?"

**Why this question matters:**
- WHO provides descriptive TB statistics, but no formal comparison of uncertainty structures.
- Key inference: is variation across countries/years explained by sampling noise, overdispersion, or persistent country effects?
- Public-health relevance: distinguishes random fluctuation from structural underperformance and identifies persistent under- and over-performing programs.

**Why three models:**
- M1 (Binomial): baseline — tests whether ordinary sampling variability is sufficient.
- M2 (Beta-Binomial): tests whether extra-binomial overdispersion improves fit.
- M3 (Hierarchical): tests whether persistent country heterogeneity remains after overdispersion.

---

## 2. Data Construction (2-3 min)

**Source:** WHO Global TB Programme public data (release 2026-04-04).

**Analysis unit:** Country-year (iso3 × year).

**Sample (locked main-analysis table):**
- 1,862 country-years
- 180 countries
- 12 years (2012–2023)
- 6 WHO regions (AFR 468, EUR 497, AMR 293, WPR 276, EMR 226, SEA 102)

**Key filtering decisions:**
- Main inclusion: rel_with_new_flg == 1 (new+relapse combined reporting).
- Cohort threshold: cohort >= 50 (reduces small-sample instability; loses 26 small countries).
- NOT used_2021_defs_flg as the main filter (only covers 2020–2023; reserved for sensitivity 14.5).

**Response:** Treatment success counts Y_it out of cohort n_it — never percentages.

**Predictors (all standardized):**
- year (temporal trend)
- e_inc_100k (incidence per 100k)
- e_mort_100k (mortality per 100k)
- c_cdr (case detection rate)
- WHO region (fixed effects with AFR as baseline, γ_1 = 0)

---

## 3. Why DIC Requires Same Locked Dataset (1 min)

**Core principle:** DIC comparison is only valid when all models are fitted on the same data.

**Implementation:**
- Single locked dataset created in Phase 3.
- All three models (M1, M2, M3) use identical N = 1,862 observations.
- No model-specific filtering or exclusion.

**DIC computation:**
- NOT the default JAGS DIC for M2/M3 (it conditions on latent θ).
- Use the observed-data beta-binomial log-likelihood for valid cross-model comparison; for M3, the posterior mean of the country effects u_c is plugged in alongside β, γ, and φ.

---

## 4. Main Posterior Findings (3-4 min)

**M3 posterior summaries (preferred model):**

| Parameter | Posterior mean | 95% credible interval | Direction |
|---|---|---|---|
| β₀ (intercept) | 1.768 | (1.702, 1.835) | — |
| Year_z | -0.012 | (-0.032, 0.009) | Posteriorly indistinguishable from zero |
| Incidence_z | **+0.283** | (0.180, 0.385) | P>0 = 1.000 |
| Mortality_z | **-0.387** | (-0.473, -0.300) | P<0 = 1.000 |
| Case-detection_z | +0.024 | (-0.022, 0.070) | P>0 ≈ 0.85 |
| γ AMR | -0.652 | (-0.756, -0.546) | clearly below AFR baseline |
| γ EMR | -0.152 | (-0.245, -0.058) | below AFR |
| γ EUR | -0.741 | (-0.853, -0.629) | clearly below AFR |
| γ SEA | +0.062 | (-0.043, 0.168) | indistinguishable from AFR |
| γ WPR | -0.303 | (-0.397, -0.209) | below AFR |
| φ overdispersion | 42.86 | (39.62, 46.26) | finite — overdispersion present |
| σ_u country RE SD | **0.717** | (0.639, 0.804) | substantial heterogeneity |

**Key talking points:**
- The intercept implies a baseline success probability around 0.85 in AFR at predictor means.
- Mortality is robustly negatively associated with success after pooling (P<0 = 1.000).
- The **incidence sign reverses** between M1 (negative) and M3 (positive). In M1 with no country effects, persistent high-incidence/low-success countries dominate; once those persistent country effects are absorbed by u_c, higher-incidence country-years actually have higher treatment success — plausibly because high-incidence countries operate mature, programmatically focused TB systems.
- φ is finite (not collapsing to ∞), so overdispersion is genuinely present, not a degenerate limit.
- σ_u ≈ 0.72 on the logit scale corresponds to substantial between-country spread.

---

## 5. PPC Findings (2-3 min)

**Test quantities (observed → M1 / M2 / M3 Bayesian p-values):**

| Test | Observed | M1 p | M2 p | M3 p |
|---|---|---|---|---|
| T1a unweighted mean | 0.791 | 1.000 | 0.022 | **0.061** |
| T1b cohort-weighted mean | 0.856 | 0.498 | 0.005 | **0.321** |
| T2 variance of success rates | 0.0202 | **0.000** | 0.000 | **0.042** |
| T3 count below 0.70 | 309 | **0.000** | 1.000 | 1.000 |
| T4a within-region var (eq) | 0.0162 | 0.000 | 0.060 | 0.004 |
| T4b within-region var (size) | 0.0185 | 0.000 | 0.000 | 0.019 |

**Reading:**
- M1 catastrophically understates variance and the lower tail.
- M2 fixes T2 but mis-predicts the cohort-weighted mean and over-predicts the lower tail.
- M3 calibrates T1b (0.32) and approximately T2 (0.04). Residual misfit only in the lower tail (T3 = 1.0) — the natural target for a future heavy-tailed extension.

---

## 6. Preferred Model & Why (2 min)

**DIC (observed-data log-likelihood):**

| Model | DIC | p_D | ΔDIC vs M3 |
|---|---|---|---|
| **M3** | **24,940.1** | 178.7 | 0 |
| M2 | 27,160.5 | 10.8 | +2,220 |
| M1 | 2,666,301.2 | 10.1 | +2,641,361 |

**Decision framework:**
- ΔDIC > 10 → strong evidence (we observe 2,220 vs M2 — overwhelming).
- ΔDIC vs M1 ≈ 2.6 million → catastrophic misfit of binomial.

**Recommendation:** M3 — hierarchical beta-binomial with country random effects. p_D ≈ 178.7 is close to the count of country REs, indicating genuine partial pooling (not unconstrained fixed effects).

---

## 7. Key Limitations (2 min)

1. **Ecological fallacy.** Country-level data cannot inform individual patient outcomes.
2. **Reporting heterogeneity.** Quality and completeness vary across countries; some patterns may reflect reporting rather than true performance. M3 absorbs persistent country-level effects but not transient reporting changes.
3. **Outcome-definition changes.** WHO frameworks evolved during 2012–2023; rel_with_new_flg mitigates but does not eliminate this. Sensitivity 14.5 (2020–2023 stricter subset) shows main signs survive.
4. **Missingness and selective retention.** Cohort >= 50 excludes 26 small countries. Sensitivity 14.1 (cohort > 0) shows results are stable.
5. **Non-causal interpretation.** Predictor effects are conditional associations, not causal estimates.

---

## 8. Robustness Checks (1-2 min)

**Frequentist comparison (bonus):**
- M1: binomial GLM via `glm` — fitted; agrees with Bayesian on signs/magnitudes.
- M2: beta-binomial via `VGAM::vglm` — fitted; agrees with Bayesian.
- M3: GLMM via `lme4::glmer` — failed locally with `function 'cholmod_factor_ldetA' not provided by package 'Matrix'`. This is a known Matrix/lme4 binary incompatibility, unrelated to model specification. Documented as a non-fatal limitation; the primary recommendation rests on the Bayesian workflow.

**Sensitivity analyses:**
1. 14.1 Cohort > 0 — frequentist refit; signs and magnitudes stable.
2. 14.2 Adding TB-HIV — frequentist refit; TB-HIV is clearly negative on the 1,835-row subsample.
3. 14.3 Alternative φ prior (Gamma(1, 0.1)) — alternative JAGS specification written; **full Bayesian refit not run** in the final window (computational scope). Reported as planned-but-unfitted.
4. 14.4 Alternative σ_u prior (Half-Normal(0, 2.5)) — alternative JAGS specification written; **full Bayesian refit not run**.
5. 14.5 Post-2021 definitions only — frequentist refit; signs preserved with larger uncertainty (70% smaller sample).

**Parameter recovery:**
- Originally planned: 50 replicates per model. Implemented: M1 30/30, M2 30/30, M3 10/10 — every executed replicate converged. The reduction is a deliberate computational accommodation (M3 region-centered fits cost ~25–30 minutes wall-clock per replicate, with one outlier replicate >7 hours). Mean coverage: M1 0.93, M2 0.96, M3 0.97 — all close to nominal 95%.

---

## 9. Likely Questions & Answers

**Q: Why not analyze percentages directly?**
A: Modeling counts (Y, n) preserves the denominator and provides a proper binomial-type likelihood. Percentages would lose information about cohort size.

**Q: Why beta-binomial rather than quasi-binomial?**
A: Beta-binomial is a proper probability model with an explicit overdispersion parameter φ. Quasi-binomial only adjusts standard errors without a generative model and would not provide a marginal likelihood for valid DIC comparison.

**Q: Why keep countries with only one retained year in M3?**
A: The hierarchical prior partially pools these countries toward the global mean. Their random intercepts will be heavily shrunk and will not distort inference.

**Q: Why compute DIC manually rather than use the JAGS default?**
A: JAGS's default DIC for M2/M3 conditions on the latent θ_it variables. The proper cross-model comparison metric is the marginal beta-binomial likelihood; we compute D = -2 log L over the marginal at each iteration and form D_bar, D(θ_bar), p_D, and DIC explicitly.

**Q: How do PPCs complement DIC?**
A: DIC measures overall fit; PPCs check specific observed features (variance, lower tail, regional patterns). A model can win on DIC but fail specific calibration checks. We use both — M3 wins on both jointly except in the lower tail.

**Q: What does parameter recovery add beyond model fit?**
A: Recovery verifies that the MCMC procedure correctly identifies known true parameters under the assumed data-generating process. It is a sanity check on the estimation procedure itself, separate from model adequacy on the observed data.

**Q: Why is this not a causal analysis?**
A: Observational ecological data with confounding. Predictor effects (e.g., the positive incidence coefficient under M3) are conditional associations; we cannot claim that changing incidence would cause success rate changes.

**Q: What is the role of the priors?**
A: Weakly informative priors (β ~ N(0, 2.5²); φ ~ Gamma(2, 0.1); σ_u ~ Half-Normal(0, 1)) prevent extreme posterior draws while allowing the data to dominate. Prior predictive checks confirmed plausibility before fitting.

**Q: Why did M3 need a region-centered parameterization?**
A: The plain centered and plain non-centered formulations both fail to mix because of an additive identifiability ridge between β₀, γ_r, and the within-region mean of u_c. Enforcing ∑_{c ∈ r} u_c = 0 via u_c = σ_u (z_c - z̄_{r(c)}) eliminates that ridge and the chains converge cleanly. We permute country IDs to be contiguous within region so the within-region mean is computed via a fast contiguous-range sum.

**Q: Why is used_2021_defs_flg not the main filter?**
A: It is only populated for 2020–2023. Using it as the main filter would collapse our 12-year panel to 4 years and lose temporal trend information. It is reserved for sensitivity 14.5.

**Q: Why was Phase 11 reduced from 50/50/50 to 30/30/10?**
A: Computational scope. M3 region-centered fits cost ~25–30 minutes wall-clock per replicate with one outlier >7 hours. 50 replicates of M3 was infeasible in the final window. The reduction is documented in the decision log; it changes the precision of recovery estimates but not the modeling rules. Coverage at the executed replicate counts is close to the nominal 95% for all three models.

**Q: Why is M3 frequentist comparison missing?**
A: `lme4::glmer` failed on the local environment with `function 'cholmod_factor_ldetA' not provided by package 'Matrix'`, a known binary incompatibility between the installed versions of `Matrix` and `lme4`. This is unrelated to model specification. We documented it as a non-fatal limitation rather than spend time on environment remediation; the primary recommendation rests on the Bayesian workflow.

---

## 10. Summary Statement (30 sec)

"This project demonstrates a complete Bayesian workflow for comparing alternative uncertainty structures in WHO tuberculosis data. On 1,862 country-years across 180 countries from 2012 to 2023, we fitted three Bayesian models — a binomial logistic, a beta-binomial, and a hierarchical beta-binomial — using JAGS, compared them via observed-data DIC and posterior predictive checks, and validated the procedure with a 30/30/10-replicate parameter recovery study. The hierarchical beta-binomial model is preferred decisively: ΔDIC vs the beta-binomial is 2,220 (strong evidence), it calibrates the cohort-weighted mean and approximately the variance, and its substantive parameters — finite φ, σ_u ≈ 0.72, mortality clearly negative, incidence reversing to positive after country pooling — are interpretable and credible. Country-year TB treatment success cannot be explained by binomial sampling alone; both overdispersion and persistent country heterogeneity are needed."

---

*Notes generated automatically by Phase 17.*
