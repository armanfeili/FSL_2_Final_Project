# Bayesian Modeling of Cross-Country Tuberculosis Treatment Success

## A Fully Bayesian MCMC Analysis of WHO Data, 2012–2023

> **Course:** Fundamentals of Statistical Learning II — M.Sc. in Data Science, a.y. 2025–2026

> **Note on year window:** The title, subtitle, abstract, and all section headings currently reference 2012–2023. If the retained main window changes after filtering (e.g., to 2013–2023 due to sparse early years), update all references accordingly.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Research Gap & Motivation](#2-research-gap--motivation)
3. [Research Question](#3-research-question)
4. [Data Sources & Construction](#4-data-sources--construction)
5. [Response Variable & Predictors](#5-response-variable--predictors)
6. [Data Cleaning & Scope Restriction](#6-data-cleaning--scope-restriction)
7. [Exploratory Data Analysis](#7-exploratory-data-analysis)
8. [Statistical Models](#8-statistical-models)
9. [Prior Specification](#9-prior-specification)
10. [MCMC Implementation](#10-mcmc-implementation)
11. [MCMC Diagnostics](#11-mcmc-diagnostics)
12. [Parameter Recovery Simulation](#12-parameter-recovery-simulation)
13. [Posterior Inference](#13-posterior-inference)
14. [Posterior Predictive Checks](#14-posterior-predictive-checks)
15. [Model Comparison (DIC)](#15-model-comparison-dic)
16. [Frequentist Comparison (Bonus)](#16-frequentist-comparison-bonus)
17. [Sensitivity Analyses](#17-sensitivity-analyses)
18. [Planned Inferential Targets](#18-planned-inferential-targets)
19. [Report Structure](#19-report-structure)
20. [Project Abstract](#20-project-abstract)
21. [Implementation Roadmap](#21-implementation-roadmap)
22. [Title Options](#22-title-options)
23. [Reproducibility Appendix](#23-reproducibility-appendix)
24. [Appendix A: Final Sample Reporting](#appendix-a-final-sample-reporting)
25. [Appendix B: Value of this Project](#appendix-b-value-of-this-project)
26. [Appendix C: Limitations Known A Priori](#appendix-c-limitations-known-a-priori)

---

## 1. Project Overview

**Goal in one sentence:** Build a country-year WHO TB dataset for 2012–2023 and compare whether simple binomial variation, extra-binomial overdispersion, or hierarchical cross-country heterogeneity best explains and predicts TB treatment success.

This project proposes a formal Bayesian comparison of uncertainty structures and predictive behavior — not just a descriptive summary of WHO tables.

### Alignment with Course Guidelines

The course guideline requires:

| Guideline Requirement                                     | Plan Section(s) |
| --------------------------------------------------------- | ---------------- |
| Fully Bayesian analysis using MCMC                        | §8, §10          |
| Real data from public sources                             | §4               |
| At least two alternative statistical models               | §8 (three models)|
| Role of parameters and inferential goals                  | §8, §13          |
| Parameter recovery with simulated data                    | §12              |
| MCMC output illustration                                  | §11              |
| Bayesian estimation, hypothesis testing, predictions      | §13, §14         |
| Model comparison via DIC and/or marginal likelihood       | §15              |
| Model's ability to recover observed data features         | §14              |
| **Bonus:** Formal model checking diagnostics              | §11              |
| **Bonus:** Frequentist comparison                         | §16              |

---

## 2. Research Gap & Motivation

WHO provides descriptive indicators on TB burden and treatment outcomes across countries and years, but not a formal Bayesian comparison of alternative uncertainty structures for treatment success. The key inferential question remains unaddressed:

> **Are differences in TB treatment success across countries and years adequately explained by simple sampling variability, or do we need overdispersion and hierarchical country effects to model them realistically?**

### Why this gap is strong

- **Statistical:** It naturally motivates three competing Bayesian models of increasing complexity.
- **Public-health relevant:** It helps distinguish random fluctuation from structural underperformance across national TB programs.
- **Methodologically complete:** It supports DIC comparison, posterior predictive checking, and frequentist benchmarking — all within a coherent analytic framework.

---

## 3. Research Question

> **Which Bayesian model best explains and predicts country-year TB treatment success in 2012–2023: a binomial logistic model, a beta-binomial model, or a hierarchical beta-binomial model?**

This question is:
- **Sharp** — it targets a specific comparison among well-defined models.
- **Measurable** — it is directly answerable via DIC and posterior predictive checks.
- **Aligned** — all three models are fit to the **same cleaned country-year dataset** for the main comparison, which is a prerequisite for valid DIC comparison (as stated in the course slides).

---

## 4. Data Sources & Construction

### Source Files

| File                                 | Role                                |
| ------------------------------------ | ----------------------------------- |
| `TB_outcomes_2026-04-04.csv`         | Treatment outcomes (response)       |
| `TB_burden_countries_2026-04-04.csv` | Epidemiological burden (predictors) |
| `TB_data_dictionary_2026-04-04.csv`  | Variable definitions and metadata   |

> **Note:** `TB_notifications_2026-04-04.csv` is excluded from the main analysis to avoid unnecessary dimensionality and sparsity; it may be referenced only for context or future extension.

### Unit of Analysis

**One row = one country-year.** All three Bayesian models and all frequentist comparators must use the **same main-analysis table**. The final merged dataset is built using the composite key `(iso3, year)`.

### Analysis Window

**Proposed main window: 2012–2023**, subject to confirmation after applying the comparability flag and cohort filter.

> If the retained sample is too sparse in 2012–2013 (e.g., very few rows survive filtering), shift the main window to **2013–2023** and report the reason transparently in the data-cleaning section.

**Year-window freeze rule:** The final analysis window will be fixed **immediately after data cleaning and before any model fitting or comparison**. This prevents any appearance of choosing the window after seeing model results.

---

## 5. Response Variable & Predictors

### 5.1 Response Variable

From the treatment-outcome file:

$$Y_{it} = \texttt{newrel\_succ}_{it} \quad \text{(number of treatment successes)}$$

$$n_{it} = \texttt{newrel\_coh}_{it} \quad \text{(treatment cohort size)}$$

$$p_{it} = P(\text{treatment success in country } i, \text{ year } t) = \frac{Y_{it}}{n_{it}}$$

**Why this formulation?** Modeling the count pair $(Y_{it}, n_{it})$ rather than a reported percentage preserves the denominator and provides a natural likelihood for binomial-type models.

> **Important clarification:** The observed proportion `success / cohort` is used only for descriptive summaries and posterior predictive test quantities. The models are always fit on **counts** $(Y_{it}, n_{it})$, never on percentages.

### Justification for Outcome Choice

- The `newrel_*` variables correspond to the combined new-and-relapse outcome framework, which is the standard WHO reporting convention for modern comparable panels.
- **`newrel_succ`** and **`newrel_coh`** combine new and relapse cases under the post-2013 WHO reporting framework.
- This definition gives a coherent modern panel across 2012–2023, whereas the older `new_sp_*` structure is not suitable for the same scope.
- This makes the scope choice **deliberate rather than arbitrary**.

### 5.2 Main Inclusion Flag

For the **main analysis**, restrict to rows where:

$$\texttt{rel\_with\_new\_flg} = 1$$

This flag indicates that the country-year row uses the newer reporting framework in which new and relapse cases are reported together (i.e., the `newrel_*` variables are the appropriate outcome definition for that row). It is the relevant comparability condition across the full analysis window.

> ⚠️ **Do NOT use `used_2021_defs_flg` as the main filter.** That flag is only populated for 2020–2023. Using it as a hard inclusion rule would silently collapse the 12-year panel to 4 years. It is reserved for a **sensitivity analysis** (see §17).

**Required reporting after applying this flag:**
- Number of retained rows
- Number of retained countries
- Number of retained years

These counts must appear in both the data-cleaning output (§6) and the EDA section (§7).

### 5.3 Core Predictors (from burden data)

Merge by `iso3` and `year`, then retain:

| Variable        | Description                   | Role               |
| --------------- | ----------------------------- | -------------------|
| `year`          | Calendar year                 | Temporal trend      |
| `g_whoregion`   | WHO region                    | Categorical effect  |
| `e_inc_100k`    | Estimated incidence per 100k  | Burden covariate    |
| `e_mort_100k`   | Estimated mortality per 100k  | Burden covariate    |
| `c_cdr`         | Case detection ratio          | Program performance |

#### Collinearity Screening

Before finalizing the predictor set, perform:

1. **Pairwise correlation matrix** among `e_inc_100k`, `e_mort_100k`, and `c_cdr`.
2. **VIF-style screening** or a simple pairwise correlation threshold (e.g., |r| > 0.85).

> If two burden predictors are too strongly collinear, simplify the main model by retaining the more interpretable predictor and moving the dropped variable to a sensitivity analysis. This prevents unstable coefficients and makes the final interpretation cleaner.

### 5.4 Sensitivity-Only Predictor

| Variable        | Description                   | Used in             |
| --------------- | ----------------------------- | ------------------- |
| `e_tbhiv_prct`  | TB-HIV co-infection rate (%)  | Sensitivity only    |

**Reason for exclusion from main model:** It reduces usable sample size, changes the main sample definition unnecessarily, and is not essential to the central model-comparison question.

---

## 6. Data Cleaning & Scope Restriction

### Step-by-Step Pipeline

| Step | Action |
| ---- | ------ |
| 1    | Import the three CSV files |
| 2    | Keep only columns needed for outcomes, identifiers, and predictors |
| 3    | Construct: `success = newrel_succ`, `cohort = newrel_coh` |
| 4    | Restrict to years **2012–2023** |
| 5    | Apply main inclusion flag: `rel_with_new_flg == 1` |
| 6    | Drop rows where: `cohort` missing, `success` missing, `cohort ≤ 0`, `success < 0`, `success > cohort`, `iso3` missing, `year` missing, or core predictors missing |
| 7    | Standardize continuous predictors (center and scale): `year`, `e_inc_100k`, `e_mort_100k`, `c_cdr` |
| 8    | Encode `g_whoregion` as categorical with one baseline region |
| 9    | Save and lock the **main-analysis table** for all primary model comparisons; sensitivity analyses may use alternative filtered versions. The term **"main-analysis table"** refers to this locked dataset throughout the plan. |

### Sample Attrition Table

The report **must** include a sample attrition table showing row counts after each successive filter:

| Filter Stage                            | Rows Remaining | Countries | Years |
| --------------------------------------- | -------------- | --------- | ----- |
| Raw merged rows                         | —              | —         | —     |
| After year restriction (2012–2023)      | —              | —         | —     |
| After comparability flag (`rel_with_new_flg == 1`) | — | —         | —     |
| After missingness removal               | —              | —         | —     |
| After cohort filter (`cohort ≥ 50`)     | —              | —         | —     |

> Fill this table with actual counts during implementation. This is a critical transparency element.

### Cohort Size Rule

| Analysis     | Filter Condition   | Purpose                                            |
| ------------ | ------------------ | -------------------------------------------------- |
| **Main**     | `cohort ≥ 50`      | Reduce instability from very small cohorts          |
| **Sensitivity** | `cohort > 0`    | Show robustness to the minimum cohort threshold     |

**Additional required check:** Report how many countries and which WHO regions are disproportionately affected by the `cohort ≥ 50` rule. This ensures the filter does not introduce undetected regional selection bias.

---

## 7. Exploratory Data Analysis

Before modeling, produce a thorough descriptive section:

1. **Sample size:** Number of country-years retained after cleaning; number of distinct countries and years.
2. **Cohort distribution:** Histogram/summary of cohort sizes $n_{it}$.
3. **Success rate distribution:** Distribution of observed proportions $\hat{p}_{it} = Y_{it} / n_{it}$.
4. **Temporal trends:** Success rate trends over time, stratified by WHO region.
5. **Bivariate relationships:**
   - Success rate vs. incidence
   - Success rate vs. mortality
   - Success rate vs. case detection ratio
6. **Missingness:** Table of missingness rates per variable before filtering.
7. **Country-level spread:** Variability in observed success rates across countries.
8. **Small vs. large cohorts:** Compare distributional properties by cohort size.
9. **Filter attrition flow:** Attrition table or flow diagram showing row loss at each cleaning step (reproducing the §6 attrition table with actual values).
10. **Retained sample by region and year:** Cross-tabulation or heatmap of the number of retained country-years per WHO region and per year.
11. **Country-year missingness heatmap** (optional): Visualize which country-year cells are missing before filtering.

> **Purpose:** Justify why a simple binomial model may be too restrictive — if observed spread exceeds what binomial sampling alone would produce, this motivates the overdispersed and hierarchical alternatives.

---

## 8. Statistical Models

### 8.1 Model 1 — Binomial Logistic Regression (Baseline)

$$Y_{it} \sim \text{Binomial}(n_{it},\; p_{it})$$

$$\text{logit}(p_{it}) = \beta_0 + \beta_1 \widetilde{\text{year}}_{it} + \beta_2 \widetilde{e\_inc\_100k}_{it} + \beta_3 \widetilde{e\_mort\_100k}_{it} + \beta_4 \widetilde{c\_cdr}_{it} + \gamma_{r(i)}$$

where $\gamma_{r(i)}$ are **fixed effects** for WHO regions, with one baseline region omitted ($\gamma_1 = 0$).

**Purpose:** Tests whether ordinary binomial variability is sufficient to explain observed spread.

---

### 8.2 Model 2 — Beta-Binomial Regression

Same mean structure, but with extra-binomial dispersion:

$$Y_{it} \sim \text{Beta-Binomial}(n_{it},\; \mu_{it},\; \phi)$$

$$\text{logit}(\mu_{it}) = \beta_0 + \beta_1 \widetilde{\text{year}}_{it} + \beta_2 \widetilde{e\_inc\_100k}_{it} + \beta_3 \widetilde{e\_mort\_100k}_{it} + \beta_4 \widetilde{c\_cdr}_{it} + \gamma_{r(i)}$$

#### Exact Parameterization

Given mean $\mu_{it}$ (from the logit link) and precision $\phi > 0$:

$$\alpha_{it} = \mu_{it} \cdot \phi, \qquad \beta_{it} = (1 - \mu_{it}) \cdot \phi$$

$$Y_{it} \sim \text{Beta-Binomial}(n_{it},\; \alpha_{it},\; \beta_{it})$$

This is equivalent to the hierarchical construction:

$$\theta_{it} \sim \text{Beta}(\alpha_{it},\; \beta_{it})$$
$$Y_{it} \mid \theta_{it} \sim \text{Binomial}(n_{it},\; \theta_{it})$$

#### Interpretation

| Parameter | Meaning |
| --------- | ------- |
| $\mu_{it} = \frac{\alpha_{it}}{\alpha_{it} + \beta_{it}}$ | Mean success probability (covariate-driven) |
| $\phi = \alpha_{it} + \beta_{it}$ | Precision: larger $\phi$ → less overdispersion (closer to binomial); smaller $\phi$ → more overdispersion |
| $\phi \to \infty$ | Beta-binomial collapses to binomial |

#### JAGS Implementation

```r
model {
  for (i in 1:N) {
    # Logit link for mean
    logit(mu[i]) <- beta0 + inprod(X[i,], beta[]) + gamma[region[i]]

    # Beta-distributed latent probability
    alpha[i] <- mu[i] * phi
    betap[i] <- (1 - mu[i]) * phi
    theta[i] ~ dbeta(alpha[i], betap[i])

    # Observed successes
    Y[i] ~ dbin(theta[i], n[i])
  }

  # Priors
  beta0 ~ dnorm(0, 1/(2.5*2.5))
  for (j in 1:p) {
    beta[j] ~ dnorm(0, 1/(2.5*2.5))
  }
  for (r in 2:R) {
    gamma[r] ~ dnorm(0, 1/(2.5*2.5))
  }
  gamma[1] <- 0  # baseline region

  phi ~ dgamma(2, 0.1)
}
```

> This construction is exact: integrating out $\theta_{it}$ recovers the beta-binomial PMF. MCMC samples $\theta_{it}$ jointly, which is equivalent but allows JAGS to handle the model without custom distributions.

> ⚠️ **DIC note:** Because the latent $\theta_{it}$ variables are sampled explicitly, JAGS's default DIC is based on the conditional binomial likelihood $p(Y_{it} \mid \theta_{it})$, not the marginal beta-binomial likelihood $p(Y_{it} \mid \mu_{it}, \phi)$. For valid cross-model DIC comparison, compute the **observed-data log-likelihood** (i.e., the beta-binomial log-PMF) at each MCMC iteration via manual calculation, the zeros trick, or post-processing. See §15 for details.

**Purpose:** Tests whether country-year success varies more than a plain binomial model allows.

---

### 8.3 Model 3 — Hierarchical Beta-Binomial Regression

Adds a **country-level random intercept** $u_i$ to Model 2 (note: this is a country-level effect, not a country-year effect):

$$Y_{it} \sim \text{Beta-Binomial}(n_{it},\; \mu_{it},\; \phi)$$

$$\text{logit}(\mu_{it}) = \beta_0 + \boldsymbol{\beta}^\top \mathbf{x}_{it} + \gamma_{r(i)} + u_i$$

$$u_i \sim \mathcal{N}(0,\; \sigma_u^2)$$

With the same beta-binomial parameterization as Model 2:

$$\alpha_{it} = \mu_{it} \cdot \phi, \qquad \beta_{it} = (1 - \mu_{it}) \cdot \phi$$

#### JAGS Implementation

```r
model {
  for (i in 1:N) {
    logit(mu[i]) <- beta0 + inprod(X[i,], beta[]) + gamma[region[i]] + u[country[i]]

    alpha[i] <- mu[i] * phi
    betap[i] <- (1 - mu[i]) * phi
    theta[i] ~ dbeta(alpha[i], betap[i])

    Y[i] ~ dbin(theta[i], n[i])
  }

  # Country random effects
  for (c in 1:C) {
    u[c] ~ dnorm(0, tau_u)
  }
  tau_u <- 1 / (sigma_u * sigma_u)
  sigma_u ~ dnorm(0, 1) T(0, )  # Half-Normal(0,1)

  # Fixed-effect priors
  beta0 ~ dnorm(0, 1/(2.5*2.5))
  for (j in 1:p) {
    beta[j] ~ dnorm(0, 1/(2.5*2.5))
  }
  for (r in 2:R) {
    gamma[r] ~ dnorm(0, 1/(2.5*2.5))
  }
  gamma[1] <- 0

  phi ~ dgamma(2, 0.1)
}
```

> ⚠️ **Same DIC note as Model 2 applies.** Observed-data log-likelihood must be computed at the beta-binomial level for valid model comparison.

> 💡 **Mixing backup:** If MCMC mixing is poor for the country random effects, consider a non-centered reparameterization (e.g., $u_i = \sigma_u \cdot z_i$, $z_i \sim \mathcal{N}(0,1)$), even if JAGS remains the primary implementation tool.

**Purpose:** Tests whether persistent country-level heterogeneity remains after controlling for measured burden variables. This is the model most likely to perform best.

#### Countries with Only One Retained Year

Countries that have only a single retained year after filtering are **retained** in the analysis unless diagnostics suggest instability. The hierarchical prior on $u_i$ will automatically partially pool these countries toward the global mean, so their random intercepts will be shrunk and will not distort inference. If convergence issues arise specifically for these countries, they will be flagged and discussed.

---

### Model Summary

| Model | Likelihood      | Overdispersion | Country Effects | Parameters |
| ----- | --------------- | -------------- | --------------- | ---------- |
| M1    | Binomial        | ✗              | ✗               | $\beta_0, \boldsymbol{\beta}, \boldsymbol{\gamma}$ |
| M2    | Beta-Binomial   | ✓ ($\phi$)     | ✗               | $\beta_0, \boldsymbol{\beta}, \boldsymbol{\gamma}, \phi$ |
| M3    | Beta-Binomial   | ✓ ($\phi$)     | ✓ ($u_1, \dots, u_C$; hyperparameter $\sigma_u$) | $\beta_0, \boldsymbol{\beta}, \boldsymbol{\gamma}, \phi, \sigma_u, \mathbf{u}$ |

---

## 9. Prior Specification

All priors are **weakly informative** — they stabilize estimation without dominating the likelihood.

### Fixed Effects

$$\beta_j \sim \mathcal{N}(0,\; 2.5^2), \quad j = 0, 1, \dots, p$$

### Region Effects

Same weakly informative normal prior, with one baseline region set to $\gamma_1 = 0$.

### Country Random-Effect Standard Deviation (Model 3)

$$\sigma_u \sim \text{Half-Normal}(0,\; 1)$$

### Overdispersion / Precision Parameter (Models 2 & 3)

$$\phi \sim \text{Gamma}(2,\; 0.1)$$

| Property        | Value |
| --------------- | ----- |
| Prior mean      | 20    |
| Prior variance  | 200   |
| Interpretation  | Wide right tail; if the posterior pushes $\phi$ to large values → no overdispersion needed; if $\phi$ stays moderate/low → genuine extra-binomial variation |

### Prior Predictive Sanity Check

Before fitting the models to real data, conduct **prior predictive simulations**: draw parameter values from the priors, generate synthetic treatment success probabilities through the logit link, and verify that the implied distribution of success rates is plausible (e.g., not concentrated at 0 or 1, and covering a reasonable range). This confirms that the priors are compatible with the problem domain and do not encode implausible assumptions.

### Reporting Checklist for Priors

In the written report, explicitly state that:

- Predictor standardization makes the priors **interpretable** on a common scale.
- The priors **stabilize** estimation without dominating it.
- The priors are **weakly informative** rather than dominant — consistent with the course emphasis that prior choice should be compatible with the parameter space.
- Prior predictive checks confirm that the priors imply **plausible treatment success probabilities**.

---

## 10. MCMC Implementation

### Software

**JAGS** (via `rjags` in R) — the most straightforward route for DIC and course-aligned workflow. NIMBLE is an acceptable alternative.

### Recommended Settings

| Setting                      | Value                  |
| ---------------------------- | ---------------------- |
| Number of chains             | 4                      |
| Burn-in per chain            | 2,000–4,000 iterations |
| Post-burn-in draws per chain | 4,000–8,000 iterations |
| Thinning                     | Only if memory is an issue; not by default |

> Increase run length if effective sample sizes or convergence diagnostics are weak.

### Reproducibility Details

- **Random seed:** Set and record a fixed random seed before each MCMC run for full reproducibility.
- **Software/package versions:** Record and report exact versions of R, JAGS, `rjags`, `coda`, and any other packages used.
- **Initial values:** Use dispersed initial values across the 4 chains to facilitate convergence assessment.
- **Pilot runs:** Run short pilot chains first (e.g., 500 iterations) to calibrate the final chain length and identify potential convergence issues before committing to the full run.

---

## 11. MCMC Diagnostics

> ⚡ **Bonus item:** The guideline explicitly rewards formal model checking diagnostics.

### Visual Diagnostics (for each model)

1. Trace plots
2. Posterior density plots
3. Autocorrelation plots
4. Overlapped multi-chain trace plots

### Numerical Diagnostics (for each model)

| Diagnostic                | Description |
| ------------------------- | ----------- |
| $\hat{R}$ (Gelman-Rubin) | Convergence across chains; target $\hat{R} < 1.01$ for key parameters (acceptable: $< 1.05$) |
| Effective sample size (ESS) | Target: ESS $> 400$ per key parameter for reliable posterior summaries |
| Monte Carlo standard error  | Precision of posterior mean estimates |

### Formal Convergence Tests

Include at least some of:

- **Gelman-Rubin** — multi-chain convergence
- **Geweke** — compares early and late portions of a single chain
- **Heidelberger-Welch** — stationarity and half-width tests
- **Raftery-Lewis** — required run length estimation

### If Mixing Is Poor

Address honestly through:
- Longer runs
- Stronger standardization of predictors
- Reparameterization (e.g., non-centered parameterization for random effects)
- Simpler initial values
- More careful prior tuning

---

## 12. Parameter Recovery Simulation

> 📋 **Explicit guideline requirement:** "Check the ability of a fully Bayesian analysis to recover model parameters with data simulated from the model."

### Procedure (for each of the three models)

1. **Choose true parameter values** based on:
   - Fitted posterior means from the real data, or
   - Plausible hand-chosen values
2. **Simulate datasets** from the model under those true values.
   - **Target: 50 simulated datasets per model.** If computationally prohibitive, perform 30 with explicit justification. All simulation runs use a **fixed, recorded random seed** for reproducibility.
3. **Refit** the same model to each synthetic dataset via MCMC.
4. **Evaluate recovery:**

| Metric                                   | What it shows |
| ---------------------------------------- | ------------- |
| Bias of posterior means                   | Systematic over/under-estimation |
| Root Mean Squared Error (RMSE)           | Overall accuracy |
| 95% equal-tail credible interval coverage | Calibration of uncertainty |
| 95% HPD coverage (if feasible)           | Calibration with shortest intervals |
| Recovery of $\phi$                       | Can the model identify overdispersion? |
| Recovery of $\sigma_u$ (Model 3 only)    | Can the model identify country heterogeneity? |

### Design Structure Requirement

The simulated datasets **must use the same design structure** as the observed cleaned table — including the same cohort sizes $n_{it}$, predictor matrix $\mathbf{X}$, country assignments, and region assignments. Only the response counts $Y_{it}$ are regenerated from the model.

> **Why this matters:** It demonstrates that the Bayesian procedure is not merely fitting data, but that it can reliably recover true parameter values under the assumed data-generating mechanism.

---

## 13. Posterior Inference

For each model, report:

### Point Estimates & Intervals

1. Posterior means
2. Posterior medians
3. 95% equal-tail credible intervals
4. 95% HPD intervals (where feasible)

### Parameters to Summarize

Posterior summaries will be reported for the following parameter groups:

- **Fixed effects** ($\beta_0, \beta_1, \dots, \beta_p$)
- **Region effects** ($\gamma_2, \dots, \gamma_R$)
- **Overdispersion parameter** ($\phi$) — Models 2 and 3
- **Country-level variance** ($\sigma_u$) — Model 3

### Posterior Probabilities of Directional Effects

$$P(\beta_{\text{incidence}} < 0 \mid y) \qquad \text{(higher burden → lower success?)}$$

$$P(\beta_{\text{cdr}} > 0 \mid y) \qquad \text{(better detection → higher success?)}$$

### Substantive Interpretation

Interpret all effects in words, not only in coefficient tables. Possible interpretations to assess:

- Higher burden (incidence, mortality) will be evaluated for possible **negative** association with treatment success.
- Higher case detection will be evaluated for possible **positive** association with success.
- Region effects will be evaluated for whether they remain important after controlling for measured burden.
- Country random effects (Model 3) will be evaluated for whether they capture persistent residual heterogeneity not explained by covariates.

---

## 14. Posterior Predictive Checks

> 📋 **Guideline requirement:** "Discussion on the ability of the estimated model to recover some features of the observed data."

For each model, simulate replicated data $Y^{\text{rep}}_{it}$ and compare observed vs. replicated using **four concrete test quantities**:

### Test Quantity 1 — Mean Treatment Success Rate

$$T_1(y) = \frac{1}{N} \sum_{i,t} \frac{Y_{it}}{n_{it}}$$

This is an **unweighted** mean of country-year success rates, treating each country-year equally regardless of cohort size. An alternative **cohort-weighted** version, $T_1^{w}(y) = \sum_{i,t} Y_{it} / \sum_{i,t} n_{it}$, should also be computed and compared, since it reflects the overall population-weighted success rate.

Compute the **posterior predictive p-value**: the proportion of replicated datasets where $T_1(y^{\text{rep}}) \geq T_1(y^{\text{obs}})$. Values near 0.5 indicate good calibration; extreme values indicate systematic bias.

### Test Quantity 2 — Variance of Success Rates ⭐ Key Diagnostic

$$T_2(y) = \text{Var}_{i,t}\!\left(\frac{Y_{it}}{n_{it}}\right)$$

This is the **critical test** for overdispersion. If Model 1 is too restrictive, replicated variance will be systematically smaller than observed variance, yielding an extreme p-value.

### Test Quantity 3 — Count of Low-Success Country-Years

$$T_3(y) = \sum_{i,t} \mathbf{1}\!\left(\frac{Y_{it}}{n_{it}} < c\right)$$

where the threshold $c$ is chosen based on a **policy-relevant benchmark** (e.g., WHO targets) or the **lower empirical tail** of the observed success distribution (e.g., the 10th percentile). The chosen value must be **justified explicitly** in the report. A reasonable starting point is $c = 0.70$, which can be refined after inspecting the EDA.

Checks whether the model reproduces the **lower tail** — countries and years with genuinely poor treatment outcomes.

### Test Quantity 4 — Within-Region Variance

$$T_4(y) = \frac{1}{R} \sum_{r=1}^{R} \text{Var}_{i \in r,\, t}\!\left(\frac{Y_{it}}{n_{it}}\right)$$

This is an **equally-weighted** average of within-region variances (each region contributes equally regardless of the number of country-years it contains). If regions have very unequal sizes, an alternative weighted version — where each region's variance is weighted by its number of country-years — should also be considered and the choice justified.

Checks whether the model reproduces heterogeneity **within** WHO regions, not just across them.

### Additional Graphical Checks

5. Overlay of observed vs. replicated distributions of success proportions (histogram or density)
6. Observed vs. replicated dispersion scatter plot
7. Calibration across small vs. large cohorts

> **If overdispersion is present in the data,** Model 1 may produce overly tight predictive distributions, while Models 2 and 3 should look more realistic. The posterior predictive checks will determine whether this pattern holds.

---

## 15. Model Comparison (DIC)

Compute **DIC** (Deviance Information Criterion) for all three models.

### Metric Priority

| Priority    | Metric                          | Status |
| ----------- | ------------------------------- | ------ |
| **Primary** | DIC                             | Required — explicitly allowed by the course guideline |
| Optional    | WAIC / LOO-CV                   | Appendix only, if feasible |
| Optional    | Marginal likelihood / Bayes factors | Appendix only, if feasible |

> Do not let optional supplementary measures delay the main project. DIC is sufficient if computed correctly.

### Critical Implementation Note

DIC will be compared **only across models fitted on the identical main-analysis dataset**.

Because the latent-variable implementations of Models 2 and 3 (with explicit $\theta_{it}$) can complicate JAGS's default DIC calculation, the **observed-data log-likelihood** (beta-binomial log-PMF) will be used to compute deviance and ensure comparability across all three models.

**Chosen implementation route:** Observed-data log-likelihood will be computed in **post-processing** from saved posterior draws of $(\mu_{it}, \phi)$ (and $u_i$ for Model 3). At each saved MCMC iteration, the beta-binomial log-PMF is evaluated for every observation, and DIC is then calculated from these values outside of JAGS. This avoids complications with JAGS's internal DIC and ensures all three models are compared on the same likelihood level.

### Interpretation Rules

| DIC Difference ($\Delta$DIC) | Interpretation                      |
| ----------------------------- | ----------------------------------- |
| $> 10$                        | Strong evidence for lower-DIC model |
| $5 – 10$                      | Moderate evidence                   |
| $< 5$                         | Interpret cautiously                |

---

## 16. Frequentist Comparison (Bonus)

> ⚡ **Bonus item:** The guideline explicitly lists frequentist comparison for extra evaluation credit.

Fit frequentist analogues that **mirror the Bayesian model ladder**:

| Bayesian Model | Frequentist Analogue | R Implementation |
| -------------- | -------------------- | ---------------- |
| M1: Binomial logistic | Binomial GLM | `glm(cbind(success, cohort - success) ~ ..., family = binomial)` |
| M2: Beta-binomial     | Beta-binomial regression | See fallback order below |
| M3: Hierarchical      | Mixed-effects logistic | `lme4::glmer(cbind(success, cohort - success) ~ ... + (1|country), family = binomial)` |

> **Note:** For Models 1 and 3, the frequentist models should use the aggregated response form `cbind(success, cohort - success)` rather than raw proportions.

#### Frequentist Model 2 — Fallback Order

For the beta-binomial frequentist analogue, use this explicit priority:

1. **Preferred:** `VGAM::vglm(..., family = betabinomial)` — fits a proper beta-binomial model with explicit overdispersion.
2. **Alternative:** `aod::betabin(...)` — another proper beta-binomial implementation.
3. **Last resort:** `glm(..., family = quasibinomial)` — only adjusts standard errors without fitting an explicit overdispersion model; use only if both beta-binomial packages fail to converge or are incompatible with the data structure.

### Comparison Dimensions

- Sign and magnitude of main effects
- Width of intervals (frequentist CIs vs. Bayesian credible intervals)
- Handling of overdispersion
- Predictive behavior
- Whether Bayesian models yield more realistic uncertainty quantification

> This section should be **short but solid** — the three-way mirroring makes it clean and easy to explain.

---

## 17. Sensitivity Analyses

A dedicated sensitivity section demonstrates careful, mature analysis.

### Planned Sensitivity Checks

| # | Sensitivity Check | What It Tests |
| - | ----------------- | ------------- |
| 1 | `cohort ≥ 50` vs. `cohort > 0` | Robustness to minimum cohort threshold |
| 2 | Main predictors vs. main predictors + `e_tbhiv_prct` | Robustness to predictor set expansion |
| 3 | $\phi \sim \text{Gamma}(2, 0.1)$ vs. $\phi \sim \text{Gamma}(1, 0.1)$ or $\log\phi \sim \mathcal{N}(0, 2^2)$ | Prior sensitivity for overdispersion |
| 4 | $\sigma_u \sim \text{Half-Normal}(0,1)$ vs. $\sigma_u \sim \text{Half-Normal}(0, 2.5)$ or $\sigma_u \sim \text{Half-}t(3, 0, 1)$ | Prior sensitivity for country effects |
| 5 | **Post-2021 definitional check:** restrict to 2020–2023 with `used_2021_defs_flg == 1` | Robustness to stricter post-2021 outcome definitions |

### Note on Sensitivity Check 5

The `used_2021_defs_flg` flag is only populated for 2020–2023. Using it as a main filter would collapse the 12-year panel to 4 years. Instead, it is used as a **targeted robustness check**: if the preferred model's key conclusions hold on this definitionally stricter subset, it strengthens the credibility of the main 2012–2023 analysis.

> **Goal:** Show that the main scientific conclusions are not fragile artifacts of specific analytic choices.

---

## 18. Planned Inferential Targets

The empirical answers are unknown a priori. The analysis is *designed* around the following inferential targets; whether they are confirmed or contradicted will be determined by the data. The findings below represent **plausible interpretations, not predetermined conclusions**.

### Target 1 — Binomial Inadequacy

> If supported: the simple binomial model fails to reproduce the observed spread in treatment success across country-years.

### Target 2 — Overdispersion Matters

> If supported: the beta-binomial model improves fit, indicating extra-binomial heterogeneity not captured by simple binomial sampling.

### Target 3 — Country Effects Persist

> If supported: the hierarchical beta-binomial model further improves fit and prediction, showing persistent country-level differences beyond measured epidemiological covariates.

### Target 4 — Predictor Effects

- Incidence and mortality may be **negatively** associated with success.
- Case detection may be **positively** associated with success.
- Region effects may remain meaningful.

### Target 5 — Model Preference

> If supported: the hierarchical overdispersed model provides the best balance of fit, uncertainty quantification, and predictive realism.

### Plausible Concluding Interpretation

A plausible concluding interpretation, if supported by the results, is that:

> **Cross-country TB treatment success in 2012–2023 cannot be adequately described by a simple binomial model alone. Allowing for overdispersion and country-level heterogeneity yields more realistic uncertainty quantification, better predictive fit, and a more credible interpretation of differences in program performance across countries and over time.**

---

## 19. Report Structure

The final written report should follow this order:

| #  | Section                           | Maps to Plan Section |
| -- | --------------------------------- | -------------------- |
| 1  | Title                             | §22                  |
| 2  | Introduction and Gap              | §2                   |
| 3  | WHO Dataset and Analysis Goal     | §3, §4               |
| 4  | Data Construction and Cleaning    | §5, §6               |
| 5  | Exploratory Analysis              | §7                   |
| 6  | Model 1: Binomial Logistic        | §8.1                 |
| 7  | Model 2: Beta-Binomial            | §8.2                 |
| 8  | Model 3: Hierarchical Beta-Binomial | §8.3               |
| 9  | Prior Specification               | §9                   |
| 10 | MCMC Implementation               | §10                  |
| 11 | MCMC Diagnostics                  | §11                  |
| 12 | Parameter Recovery Simulation     | §12                  |
| 13 | Posterior Inference                | §13                  |
| 14 | Posterior Predictive Checks       | §14                  |
| 15 | DIC Model Comparison              | §15                  |
| 16 | Frequentist Comparison            | §16                  |
| 17 | Sensitivity Analyses              | §17                  |
| 18 | Discussion (including Limitations) | Synthesis of §13–§17 results; Appendix C (limitations) |
| 19 | Conclusion                        | Final synthesis of key findings and model recommendation |

> This structure mirrors the course requirements closely.

### Discussion vs. Conclusion

- **Discussion** should interpret results, relate them to the research question, acknowledge **limitations** (e.g., potential unmeasured confounders, outcome definition changes over time, ecological fallacy in country-level data), and suggest directions for future work.
- **Conclusion** should provide a concise summary of the key findings and the recommended model.

---

## 20. Project Abstract

> This project develops a fully Bayesian analysis of WHO tuberculosis country-year data to study treatment success in 2012–2023. The central question is whether observed variation in treatment success across countries and years is adequately explained by simple binomial sampling, or whether overdispersion and hierarchical country heterogeneity must be explicitly modeled. Using WHO treatment-outcome and burden data, I compare three models — a binomial logistic model, a beta-binomial model, and a hierarchical beta-binomial model — fitted by MCMC. I assess posterior inference, equal-tail and HPD credible intervals, formal and graphical MCMC diagnostics, parameter recovery under simulation, posterior predictive performance, and model comparison via DIC. I also include a frequentist comparison and sensitivity analyses. The goal is to identify which Bayesian model provides the most realistic uncertainty quantification and the best explanation of cross-country variation in TB treatment success.

> **Note:** If the final analysis window changes (e.g., to 2013–2023) or if supplementary measures like WAIC are included, update the following consistently: title, subtitle, abstract, §21 Implementation Roadmap, Appendix A summary table, and any figure captions or filenames that reference the year range.

---

## 21. Implementation Roadmap

### Phase 1 — Data Preparation

| Step | Task |
| ---- | ---- |
| 1    | Import the three CSV files |
| 2    | Define `success = newrel_succ`, `cohort = newrel_coh` |
| 3    | Apply main comparability flag: `rel_with_new_flg == 1` |
| 4    | Merge burden predictors by `iso3` and `year` |
| 5    | Restrict to 2012–2023 |
| 6    | Build the final analysis table with all core predictors |
| 7    | Apply `cohort ≥ 50` for main analysis |
| 7a   | **Validate the retained sample:** Confirm that the year window remains acceptable (check for sparse early years). If 2012–2013 collapse, shift to 2013–2023 and document the reason. |
| 7b   | **Create a locked export** of the main-analysis table used by all three primary models |

### Phase 2 — Exploratory Analysis

| Step | Task |
| ---- | ---- |
| 8    | Produce all EDA summaries and plots (see §7) |
| 8a   | Complete and report the sample attrition table |
| 8b   | Run collinearity screening among burden predictors |

### Phase 3 — Bayesian Modeling

| Step | Task |
| ---- | ---- |
| 9    | Run prior predictive checks to validate prior plausibility |
| 10   | Fit **Model 1** (binomial logistic) |
| 11   | Fit **Model 2** (beta-binomial) |
| 12   | Fit **Model 3** (hierarchical beta-binomial) |
| 13   | Run MCMC diagnostics for all three models |

### Phase 4 — Model Evaluation

| Step | Task |
| ---- | ---- |
| 14   | Compute DIC on the same cleaned dataset (using observed-data log-likelihood) |
| 15   | Run posterior predictive checks (four test quantities + graphs) |
| 16   | Run parameter recovery simulation (target: 50 datasets per model) |

### Phase 5 — Extensions & Robustness

| Step | Task |
| ---- | ---- |
| 17   | Fit frequentist comparators (mirroring all three Bayesian models) |
| 18   | Run all five sensitivity analyses |

### Phase 6 — Write-Up

| Step | Task |
| ---- | ---- |
| 19   | Draft report following the structure in §19 |
| 20   | Finalize figures, tables, and interpretation |
| 21   | Compile reproducibility appendix (§23) |

---

## 22. Title Options

| # | Title | Notes |
| - | ----- | ----- |
| 1 | **Bayesian Modeling of Cross-Country Tuberculosis Treatment Success: Binomial, Overdispersed, and Hierarchical Evidence from WHO Data** | ⭐ Strongest |
| 2 | **Modeling TB Treatment Success Across Countries and Years: A Fully Bayesian Comparison of Binomial and Hierarchical Beta-Binomial Models** | |
| 3 | **Overdispersion and Country Heterogeneity in WHO Tuberculosis Treatment Outcomes: A Bayesian MCMC Analysis** | ⭐ Strongest |
| 4 | **A Fully Bayesian Analysis of WHO Tuberculosis Treatment Success, 2012–2023** | Concise fallback; update year range if the final window changes |

---

## 23. Reproducibility Appendix

Include the following reproducibility details in the final report (as an appendix or dedicated section):

| Item                    | Details to Record |
| ----------------------- | ----------------- |
| **Software**            | R version, JAGS version |
| **R packages**          | `rjags`, `coda`, `VGAM`, `aod`, `lme4`, and all other packages with version numbers |
| **Random seeds**        | Exact seed used for each MCMC run and simulation study |
| **Folder/file structure** | Description of project directory layout and data file locations |
| **Script order**        | Ordered list of R scripts with brief descriptions of what each does |
| **Data provenance**     | Source URLs, download dates, and file checksums (if feasible) |

> This appendix is not formally required by the course, but it makes the project look complete and professional.

---

## Appendix A: Final Sample Reporting

Appendix A is a **compact final-sample snapshot**; §6 contains the **full step-by-step attrition table**. Together they provide complete transparency on data filtering.

| Item                                     | Value |
| ---------------------------------------- | ----- |
| Final number of countries                | —     |
| Final year range                         | —     |
| Final number of country-years (main-analysis table) | — |
| Countries/regions lost to `cohort ≥ 50` filter | — |

> Fill in actual values during implementation. This table should appear early in the report (e.g., alongside or immediately after the §6 attrition table).

---

## Appendix B: Value of this Project

### Statistical Value
Shows that naive pooled models can be overconfident and misleading in country-comparative health data.

### Public-Health Value
Helps distinguish random fluctuation, structural underperformance, and uncertainty due to cohort size and unobserved country-level heterogeneity.

### Practical Value
Provides posterior intervals, posterior probabilities, and predictive distributions — not just raw percentages. By explicitly incorporating cohort size and modeling uncertainty at multiple levels, the analysis delivers a real improvement over descriptive tables.

---

## Appendix C: Limitations Known A Priori

Before proceeding to implementation, the following limitations are acknowledged and should be addressed transparently in the Discussion section of the final report:

1. **Ecological fallacy:** Country-level data cannot support individual-level causal claims. All associations are at the country-year level.
2. **Reporting heterogeneity:** Countries differ in data quality, surveillance capacity, and reporting conventions, which may introduce systematic measurement error not captured by the models.
3. **Outcome-definition changes over time:** The shift from older `new_sp_*` definitions to the `newrel_*` framework introduces potential comparability breaks, partially mitigated by the `rel_with_new_flg` filter and the post-2021 sensitivity analysis.
4. **Missingness and selective retention:** The filtering pipeline removes country-years with missing data, which may not be missing at random. The attrition table (§6) and cohort-filter impact check help assess this, but residual selection bias cannot be fully ruled out.
5. **No causal identification:** The models estimate associations conditional on covariates, not causal effects of burden or program performance on treatment success.
