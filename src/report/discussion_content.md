# Discussion Section Content

This document provides structured content for the Discussion section of the report.
The Discussion addresses the research question, explains model preference, and
acknowledges five pre-planned limitations.

---

## Research Question Answer

**Research Question:**
"Which Bayesian model best explains and predicts country-year TB treatment success
in 2012-2023: a binomial logistic model, a beta-binomial model, or a hierarchical
beta-binomial model?"

**Answer:**
The hierarchical beta-binomial model (M3) is preferred. The DIC ranking and the
posterior predictive checks both point to M3, and the parameter estimates are
substantively interpretable.

- **M1 (Binomial):** DIC = 2,666,301 (rank 3). PPC variance and lower-tail tests
  fail catastrophically (Bayesian p ≈ 0). Binomial sampling cannot account for
  the observed cross-country dispersion.
- **M2 (Beta-Binomial):** DIC = 27,160 (rank 2, ΔDIC vs M3 = 2,220). Adding the
  overdispersion parameter φ resolves the variance failure but the cohort-weighted
  mean is mis-calibrated (p = 0.005) and the lower tail is over-predicted.
- **M3 (Hierarchical Beta-Binomial):** DIC = 24,940 (rank 1). The cohort-weighted
  mean test is well calibrated (p = 0.32), the variance test is approximately
  calibrated (p = 0.04), and the within-region heterogeneity is reduced.
  Effective parameters p_D ≈ 178.7 reflect genuine partial pooling across the
  180 country random intercepts.

**Preferred Model:** M3 — the hierarchical beta-binomial model with country
random effects.

**Rationale for Preference:**

- **DIC:** ΔDIC vs M2 = 2,220 (strong evidence by the standard ΔDIC > 10
  convention).
- **PPC:** M3 is the only model whose central tendency, variance, and within-region
  variance test quantities are all approximately consistent with the observed
  features.
- **Substantive interpretation:** φ ≈ 42.9 (95% CI 39.6–46.3) is finite —
  overdispersion is real but moderate. σ_u ≈ 0.72 (95% CI 0.64–0.80) on the
  logit scale corresponds to substantial between-country spread. Mortality
  retains a clear negative posterior effect (P<0 = 1.000); the incidence
  coefficient reverses sign between M1 (negative) and M3 (positive, P>0 = 1.000),
  a textbook illustration of why pooling matters in country-level ecological data.

---

## Why the Preferred Model is Preferred

### Statistical Evidence

1. **DIC Comparison:** ΔDIC(M3 vs M2) = 2,220 (strong). ΔDIC(M3 vs M1) ≈ 2.6
   million (overwhelming). Computed from the observed-data beta-binomial
   log-likelihood, not the JAGS-default conditional DIC.
2. **Posterior Predictive Checks:** Six test quantities computed across M1/M2/M3.
   M1 fails T2 (variance) and T3 (lower-tail count) catastrophically. M2 fixes
   T2 but mis-predicts T1b (mean) and T3. M3 is the only model that calibrates
   T1b (p = 0.32) and approximately T2 (p = 0.04). Residual misfit is in the
   lower tail (T3 p = 1.0) — the natural target for a future heavy-tailed
   extension.
3. **Variance Calibration:** Observed variance of success rates = 0.0202;
   posterior predictive means are 0.006 (M1, far too small), 0.017 (M2, close
   but biased low), 0.019 (M3, approximately correct).

### Substantive Interpretation

1. **Overdispersion (φ):** Posterior mean φ = 42.9 (95% CI 39.6–46.3) — finite
   and well bounded, confirming beta-binomial structure rather than collapsing
   toward the binomial limit (φ → ∞).
2. **Country heterogeneity (σ_u):** Posterior mean σ_u = 0.72 (95% CI 0.64–0.80).
   On the logit scale, this implies a non-trivial spread of country-specific
   intercepts even after controlling for incidence, mortality, case detection,
   year, and region.
3. **Covariate effects (M3):**
   - Year_z: posterior mean -0.01 (95% CI -0.03, 0.01) — posteriorly indistinguishable
     from zero.
   - Incidence_z: +0.28 (95% CI 0.18, 0.39), P>0 = 1.000.
   - Mortality_z: -0.39 (95% CI -0.47, -0.30), P<0 = 1.000.
   - Case-detection_z: +0.02 (95% CI -0.02, 0.07), P>0 ≈ 0.85 — weak.
   - Region effects: AMR, EUR, WPR posteriorly below the AFR baseline; SEA
     indistinguishable from AFR; EMR slightly below.

---

## Five Planned Limitations

### 1. Ecological Fallacy
Country-level aggregated data cannot support individual-level causal claims.
Treatment success rates are computed at the national level, aggregating across
potentially millions of individual patients. Country-level associations need
not hold within any single patient cohort. Policy implications must respect this.

### 2. Reporting Heterogeneity
Countries differ substantially in surveillance capacity, data completeness, and
reporting conventions. The country random effects in M3 absorb persistent
country-level differences, but transient reporting changes within a country
are not modeled.

### 3. Outcome-Definition Changes Over Time
The shift from `new_sp_*` to `newrel_*` reporting introduces potential
discontinuities. The `rel_with_new_flg` filter ensures all retained rows use
compatible definitions; the post-2021 sensitivity analysis (14.5) shows the
main coefficient signs survive on the stricter modern subset, though with
larger uncertainty due to a 70% smaller sample.

### 4. Missingness and Selective Retention
The cohort ≥ 50 filter excludes 26 small countries entirely. The cohort > 0
sensitivity (14.1) shows coefficient signs and magnitudes are stable, so the
filter does not appear to drive the conclusions, but residual selection bias
cannot be ruled out for the very smallest countries.

### 5. Non-Causal Interpretation
This is an observational, ecological analysis. Predictor effects (e.g., the
positive incidence coefficient under M3) are conditional associations, not
causal estimates. Causal inference would require experimental or
quasi-experimental designs. The Bayesian framework provides correct uncertainty
quantification under the assumed model, not under interventions.

---

## Future Work

1. **Heavy-tailed extensions:** Address M3's residual lower-tail miscalibration
   (T3 p = 1.0) with a mixture or Student-t country effect, or with explicit
   modeling of crisis-affected country-years.
2. **Time-varying random effects:** Allow country effects to evolve over time;
   the current u_c assumes a single country-level shift across all 12 years.
3. **Spatial correlation:** Introduce dependencies between neighboring countries
   that may share resources, policies, or transmission dynamics.
4. **Causal frameworks:** Apply difference-in-differences or instrumental
   variable designs to exploit policy changes for causal identification.
5. **Additional predictors:** Incorporate health system indicators (health
   expenditure per capita, physician density) and TB-HIV co-infection as a main
   predictor (sensitivity 14.2 already shows it has a clear negative effect).

---

## Frequentist Comparison Context

The frequentist comparison (Phase 13, bonus) was completed for M1 (binomial GLM
via `glm`) and M2 (beta-binomial via `VGAM::vglm`). Coefficient signs and
magnitudes agree closely with the Bayesian counterparts; Bayesian credible
intervals are slightly wider than frequentist confidence intervals on average
(width ratio ≈ 0.997). The M3 frequentist analogue (`lme4::glmer` with country
random intercepts) failed to fit on the local environment with the error
`function 'cholmod_factor_ldetA' not provided by package 'Matrix'`, a known
binary incompatibility between the installed versions of `Matrix` and `lme4`.
This is unrelated to model specification and is documented as a non-fatal
limitation of the bonus comparison; the primary recommendation rests on the
Bayesian workflow.
