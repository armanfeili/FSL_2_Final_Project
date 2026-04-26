# Discussion Section Content

## Generated: 2026-04-26 15:36:23.758668

This document provides structured content for the Discussion section of the report.
The Discussion addresses the research question, explains model preference, and
acknowledges five pre-planned limitations.

---

## Research Question Answer

**Research Question:**
"Which Bayesian model best explains and predicts country-year TB treatment success
in 2012-2023: a binomial logistic model, a beta-binomial model, or a hierarchical
beta-binomial model?"

**Answer Framework:**
[To be completed when Bayesian posteriors are available from Phase 8]

Based on the DIC comparison and posterior predictive checks:
- M1 (Binomial): [DIC value, PPC adequacy assessment]
- M2 (Beta-Binomial): [DIC value, PPC adequacy assessment]
- M3 (Hierarchical Beta-Binomial): [DIC value, PPC adequacy assessment]

**Preferred Model:** [Model name]

**Rationale for Preference:**
[Evidence from DIC, evidence from PPC, substantive interpretation]

---

## Why the Preferred Model is Preferred

### Statistical Evidence
1. **DIC Comparison:** [Delta-DIC values and interpretation]
2. **Posterior Predictive Checks:** [Which test quantities are well-recovered]
3. **Variance Calibration:** [How well each model captures observed variance]

### Substantive Interpretation
1. **Overdispersion Evidence:** [phi posterior summary, interpretation]
2. **Country Heterogeneity Evidence:** [sigma_u posterior summary, interpretation]
3. **Covariate Effects:** [Key predictor effects and their credible intervals]

---

## Five Planned Limitations (from TODO_PLAN.md)

### 1. Ecological Fallacy
Country-level aggregated data cannot support individual-level causal claims.
Treatment success rates are computed at the national level, aggregating across
potentially millions of individual patients. Associations observed at the country
level (e.g., between incidence and success rate) may not hold at the individual
level. Any policy implications must acknowledge this aggregation.

### 2. Reporting Heterogeneity
Countries differ substantially in data quality, surveillance capacity, and
reporting conventions. High-income countries typically have more complete and
accurate TB surveillance systems than low-income countries. This heterogeneity
introduces measurement error that is not explicitly modeled but partially captured
by country random effects in M3.

### 3. Outcome-Definition Changes Over Time
The shift from `new_sp_*` to `newrel_*` reporting framework introduces potential
discontinuities. While the `rel_with_new_flg` filter ensures rows use compatible
definitions, subtle definitional differences may persist across the 2012-2023
window. The sensitivity analysis using `used_2021_defs_flg` (2020-2023 only)
partially addresses this concern.

### 4. Missingness and Selective Retention
The filtering pipeline (cohort >= 50, rel_with_new_flg == 1) creates a selected
sample that may not be representative of all country-years. Twenty-six countries
were entirely excluded due to small cohorts. The attrition table documents this
selection, but residual selection bias cannot be ruled out. Countries with missing
data may differ systematically from those retained.

### 5. Non-Causal Interpretation
This is an observational analysis with ecological data. The model estimates
covariate-conditional associations, not causal effects. For example, the negative
association between incidence and success rate does not imply that reducing
incidence would directly improve success rates — confounding factors (resources,
health system capacity, HIV prevalence) may drive both. Causal inference would
require experimental or quasi-experimental designs.

---

## Future Work Suggestions

1. **Individual-level data:** If individual patient records become available,
   hierarchical models with patient-level covariates could address the ecological
   fallacy.

2. **Time-varying random effects:** Allow country effects to evolve over time,
   capturing improving or deteriorating national programs.

3. **Spatial correlation:** Model spatial dependencies between neighboring
   countries that may share resources, policies, or disease transmission.

4. **Causal frameworks:** Apply difference-in-differences or instrumental
   variables to exploit policy changes for causal identification.

5. **Additional predictors:** Incorporate health system indicators (e.g., health
   expenditure per capita, physician density) when available.

---

## Frequentist Comparison Context

The frequentist comparison (Phase 13) serves to:
1. Validate Bayesian coefficient signs and magnitudes
2. Provide familiar confidence intervals alongside credible intervals
3. Confirm that results are not artifacts of the prior specification

Agreement between Bayesian and frequentist results strengthens confidence in the
findings. Any disagreements warrant investigation of prior sensitivity.

