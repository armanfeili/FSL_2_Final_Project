# Conclusion Section Content

This document provides structured content for the Conclusion section of the report.

---

## Conclusion Framework

### Summary of Findings

This project addressed whether simple binomial sampling, extra-binomial
overdispersion, or hierarchical cross-country heterogeneity best explains and
predicts TB treatment success across 180 countries over 2012-2023.

**Key Findings:**

1. **Binomial Adequacy.** M1 (binomial logistic) is inadequate. DIC = 2,666,301
   (vs 24,940 for M3). The variance of success rates and the count of
   country-years below 70% success both fall outside its posterior predictive
   distribution (Bayesian p ≈ 0). Ordinary binomial sampling cannot account for
   the observed dispersion.

2. **Overdispersion Evidence.** M2 (beta-binomial) materially improves fit.
   Posterior mean φ ≈ 10.5 in M2 (and ≈ 42.9 once country random effects are
   included in M3) — finite, so overdispersion is genuinely present and not a
   degenerate limit. ΔDIC vs M1 ≈ 2.6 million. M2 still mis-predicts the
   cohort-weighted mean (p = 0.005) and over-predicts the lower tail.

3. **Country Heterogeneity Evidence.** M3 (hierarchical beta-binomial) is best.
   Posterior mean σ_u = 0.72 (95% CI 0.64–0.80) on the logit scale corresponds
   to substantial between-country spread even after controlling for incidence,
   mortality, case detection, year, and region. M3 calibrates the
   cohort-weighted mean (p = 0.32) and approximately the variance (p = 0.04).
   The country random-effect caterpillar plot identifies persistent low and
   high performers.

4. **Model Recommendation.** M3 — the hierarchical beta-binomial model with
   country random effects — is preferred. ΔDIC vs M2 = 2,220 (strong evidence),
   the PPC profile is the cleanest of the three, and the substantive parameter
   estimates (mortality clearly negative; incidence reverses to positive after
   country pooling; finite φ; substantial σ_u) are all interpretable.

---

### Practical Implications

1. **For WHO and national TB programs:** Persistent country-level differences
   are real and large. The country random-effect rankings identify candidate
   under- and over-performing programs after adjustment for epidemiological
   burden.

2. **For surveillance:** Year-on-year fluctuations within a country are
   plausibly larger than binomial sampling alone would imply but smaller than
   the cross-country differences. Investigate large changes against the
   country's own historical baseline rather than against the global mean.

3. **For resource allocation:** Country-years with persistently low success
   (negative u_c) flag candidate priorities; country-years with persistently
   high success (positive u_c) may offer transferable lessons. Both should be
   read as descriptive associations, not causal effects.

---

### Methodological Contributions

1. **Fully Bayesian workflow:** Demonstrated MCMC fitting, formal convergence
   diagnostics, posterior inference, posterior predictive checking, and
   parameter recovery for count data with country-level structure.

2. **Identifiability resolution.** The plain centered and plain non-centered M3
   parameterizations both fail to mix because of an additive identifiability
   ridge between β₀, γ_r, and the within-region mean of u_c. The accepted M3
   uses a region-centered non-centered parameterization that enforces
   ∑_{c ∈ r} u_c = 0 within every WHO region. The full remediation trail is
   preserved in the decision log.

3. **DIC method:** Provided valid cross-model comparison using the observed-data
   beta-binomial log-likelihood, not the JAGS-default conditional DIC for M2/M3.

4. **Recovery study:** A 30/30/10-replicate recovery study (every executed
   replicate converged) supports the inferential credibility of all three
   models. The reduction from the originally targeted 50/50/50 design to
   30/30/10 is a deliberate computational accommodation, documented in the
   decision log; it changes the precision of the recovery estimates but not
   the modeling rules.

5. **Frequentist benchmark:** The frequentist M1 (GLM) and M2 (VGAM
   beta-binomial) analogues agree with the Bayesian results on coefficient
   signs and magnitudes. The M3 GLMM analogue (`lme4::glmer`) failed locally
   due to a Matrix/lme4 binary incompatibility, an unresolvable environmental
   issue rather than a model problem; the main recommendation does not depend
   on it.

---

### Final Statement

Country-year TB treatment success in 2012–2023 cannot be modeled with simple
binomial variation. Both extra-binomial overdispersion and persistent
country-level heterogeneity are required, and the hierarchical beta-binomial
model (M3) is the recommended specification for this and similar WHO panel
data: it is the only model whose central tendency, variance, country-level
structure, and substantive coefficient estimates are jointly defensible. The
remaining lower-tail miscalibration is the natural target for a future
heavy-tailed extension.
