# Oral Discussion Preparation Notes

## Bayesian Modeling of Cross-Country TB Treatment Success
### A Fully Bayesian MCMC Analysis of WHO Data, 2012–2023

---

## 1. Research Question & Motivation (2-3 min)

**Research Question:**
"Which Bayesian model best explains and predicts country-year TB treatment success in 2012–2023: a binomial logistic model, a beta-binomial model, or a hierarchical beta-binomial model?"

**Why this question matters:**
- WHO provides descriptive TB statistics, but no formal comparison of uncertainty structures
- Key inference: Is variation across countries/years explained by sampling noise, overdispersion, or persistent country effects?
- Public health relevance: Distinguishes random fluctuation from structural underperformance

**Why three models:**
- M1 (Binomial): Baseline — tests if ordinary sampling variability is sufficient
- M2 (Beta-Binomial): Tests if extra-binomial overdispersion improves fit
- M3 (Hierarchical): Tests if persistent country heterogeneity remains after overdispersion

---

## 2. Data Construction (2-3 min)

**Source:** WHO Global TB Programme public data (2024 release)

**Analysis unit:** Country-year (iso3 × year)

**Sample:**
- 1,862 country-years
- 180 countries
- 12 years (2012–2023)
- 6 WHO regions

**Key filtering decisions:**
- Main inclusion: rel_with_new_flg == 1 (new+relapse combined reporting)
- Cohort threshold: cohort >= 50 (reduces small-sample instability)
- NOT used_2021_defs_flg (only covers 2020–2023)

**Response:** Treatment success count (Y) out of cohort (n), never percentages

**Predictors:**
- Year (temporal trend)
- Incidence per 100k
- Mortality per 100k
- Case detection rate
- WHO region (fixed effects with AFR as baseline)

---

## 3. Why DIC Requires Same Locked Dataset (1 min)

**Core principle:** DIC comparison is only valid when all models are fitted on the same data

**Implementation:**
- Single locked dataset created in Phase 3
- All three models (M1, M2, M3) use identical N=1,862 observations
- No model-specific filtering or exclusion

**DIC computation:**
- NOT default JAGS DIC for M2/M3 (that is conditional on latent variables)
- Use observed-data log-likelihood (beta-binomial PMF) for valid comparison

---

## 4. Main Posterior Findings (3-4 min)

[To be completed with actual posterior results when available]

**Expected findings to discuss:**
- Intercept interpretation (baseline success rate on logit scale)
- Effect directions: year (+?), incidence (-?), mortality (-?), CDR (+?)
- Regional differences relative to AFR baseline
- Overdispersion parameter phi (M2, M3)
- Country RE SD sigma_u (M3)

**Key posterior probabilities:**
- P(beta_incidence < 0): Evidence for negative incidence effect
- P(sigma_u > 0.1): Evidence for meaningful country heterogeneity

---

## 5. PPC Findings (2-3 min)

**Test quantities used:**
- T1: Mean success rate (unweighted and cohort-weighted)
- T2: Variance of success rates
- T3: Count of low-success country-years (< 70%)
- T4: Within-region variance

**Interpretation:**
- If M1 fails variance tests → binomial insufficient
- If M2 captures variance but M3 better for regional patterns → country effects matter
- Bayesian p-values near 0 or 1 indicate poor calibration

---

## 6. Preferred Model & Why (2 min)

[To be completed with actual DIC results when available]

**Decision framework:**
- DIC difference > 10: Strong evidence
- DIC difference 5-10: Moderate evidence
- DIC difference < 5: Interpret cautiously

**Expected recommendation:**
- If M3 has lowest DIC → "Hierarchical beta-binomial preferred; both overdispersion and country effects improve fit"
- Also consider: posterior predictive performance, parameter interpretability

---

## 7. Key Limitations (2 min)

1. **Ecological fallacy:** Country-level data cannot inform individual patient outcomes

2. **Reporting heterogeneity:** Quality and completeness vary across countries; some patterns may reflect reporting rather than true performance

3. **Outcome definition changes:** WHO reporting frameworks evolved during 2012–2023; rel_with_new_flg mitigates but does not eliminate this

4. **Missingness and selective retention:** Cohort >= 50 filter excludes 26 small countries; results may not generalize to smallest populations

5. **Non-causal interpretation:** Observational data; predictor effects are associations, not causal estimates

---

## 8. Robustness Checks (1-2 min)

**Sensitivity analyses performed:**
1. Cohort > 0 (no minimum threshold)
2. Adding TB-HIV predictor
3. Alternative phi prior (Gamma(1, 0.1))
4. Alternative sigma_u prior (Half-Normal(0, 2.5))
5. Post-2021 definitions only (2020–2023 subset)

**Frequentist comparison:**
- GLM for M1
- VGAM beta-binomial for M2
- lme4 GLMM for M3
- Check coefficient sign agreement

---

## 9. Likely Questions & Answers

**Q: Why not analyze percentages directly?**
A: Modeling counts (Y, n) preserves the denominator and provides proper binomial-type likelihood. Percentages would lose information about cohort size.

**Q: Why beta-binomial rather than quasi-binomial?**
A: Beta-binomial provides a proper probability model with explicit overdispersion parameter. Quasi-binomial only adjusts standard errors without a generative model.

**Q: Why keep countries with only one year in M3?**
A: The hierarchical prior partially pools these toward the global mean. Their random intercepts will be heavily shrunk, not distorting inference.

**Q: Why compute DIC manually rather than use JAGS default?**
A: JAGS default DIC for M2/M3 conditions on latent theta variables. The proper comparison metric is the marginal beta-binomial likelihood.

**Q: How do PPCs complement DIC?**
A: DIC measures overall fit; PPCs check specific observed features (variance, lower tail, regional patterns). A model can win on DIC but fail specific calibration checks.

**Q: What does parameter recovery add beyond model fit?**
A: Parameter recovery verifies that our MCMC correctly identifies known true parameters. This is a sanity check on the estimation procedure itself.

**Q: Why is this not a causal analysis?**
A: Observational data with confounding. Predictor effects (e.g., incidence) are associations; we cannot claim changing incidence would cause success rate changes.

**Q: What is the role of the priors?**
A: Weakly informative priors (N(0, 2.5^2) for coefficients) prevent extreme posterior values while allowing data to dominate. Prior predictive checks confirmed plausibility.

**Q: Why is used_2021_defs_flg not the main filter?**
A: It is only populated for 2020–2023. Using it as the main filter would collapse our 12-year panel to 4 years, losing temporal trend information.

---

## 10. Summary Statement (30 sec)

"This project demonstrates a complete Bayesian workflow for comparing alternative uncertainty structures in WHO tuberculosis data. Using DIC comparison and posterior predictive checks on a locked country-year dataset, we evaluate whether binomial sampling variability, overdispersion, or hierarchical country effects best explain treatment success variation. The methodology provides a template for rigorous model comparison in public health surveillance data."

---

*Notes generated automatically by Phase 17.*

