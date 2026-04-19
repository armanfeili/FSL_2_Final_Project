# Project Progress Report — In Plain Language

## What This Project Is

This is an individual final project for the **Fundamentals of Statistical Learning II** course (M.Sc. Data Science, Sapienza, 2025–2026). The assignment is simple: pick a real dataset, build a **fully Bayesian model using MCMC**, fit at least two competing models, check parameter recovery, compare with DIC, and write it up as a report.

**The chosen topic:** tuberculosis (TB) treatment success across countries and years, using public WHO data for 2012–2023.

**The central question:** Given how much TB treatment success rates vary between countries and over time, which Bayesian model explains this variation best?

- A simple **binomial model** (assume every country-year is just a coin flip with sampling noise)?
- A **beta-binomial model** (allow extra variability beyond plain sampling noise)?
- A **hierarchical beta-binomial model** (on top of the extra variability, give each country its own persistent "country effect")?

The unit of analysis is one **country-year**: how many patients finished treatment successfully (`newrel_succ`) out of how many were in the cohort (`newrel_coh`). The models use year, WHO region, TB incidence, mortality, and case detection ratio as predictors.

---

## What Has Been Done So Far

The plan is organized as **Phases 0–17**. Here is the real state:

### Phases 0–7 — Fully complete

- **Infrastructure (Phase 0):** Clean folder tree, single execution entry point (`src/main.R`), raw WHO CSVs locked in `data/data_raw/`, decision log in `notes/decision_log.md`, reproducibility metadata (R/JAGS/package versions, git SHA, seed = 2026).
- **Research framing (Phase 1):** Research question, model ladder (M1 → M2 → M3), and analysis rules were frozen before any data work.
- **Data intake and audit (Phases 2–3):** The three WHO CSVs were merged on `(iso3, year)`, filtered through a documented 6-step pipeline, and **locked** as `main_analysis_table_locked.csv`. Final sample: **1,862 country-years, 180 countries, 2012–2023, 6 WHO regions**, with AFR as the baseline region.
- **Quality checks (Phase 4):** Missingness audited, cohort filter impact (26 countries lost, mostly small islands), predictor collinearity checked (max |r| = 0.844 — below the 0.85 threshold, so all four predictors retained).
- **EDA (Phase 5):** Produced a large set of figures and tables. Key finding: observed success-rate spread is wider than a pure binomial would predict — this is exactly the motivation for M2 and M3.
- **Priors and prior predictive checks (Phase 6):** Weakly informative Normal(0, 2.5²) for coefficients, Gamma(2, 0.1) for φ, Half-Normal(0, 1) for σ_u. Prior predictive simulations look plausible for all three models.
- **JAGS model files (Phase 7):** All three models plus a **non-centered backup** for M3 are coded in `src/models/`, pilot-tested, and JAGS data lists are saved.

### Phase 8 — In progress (this is the current bottleneck)

Full MCMC fitting on the real data.

- **M1 (binomial):** Initial run had weak effective sample sizes. A rerun with longer burn-in and more iterations pushed R-hat ≤ 1.05 and ESS ≥ 400 → **acceptable, promoted**.
- **M2 (beta-binomial):** Same story — an extended-fast rerun achieved the diagnostic thresholds → **acceptable, promoted**.
- **M3 (hierarchical):** The standard centered parameterization mixed very poorly (min ESS ≈ 12, max R-hat ≈ 1.16). The planned fallback — a **non-centered** parameterization — improved things (min ESS ≈ 20, max R-hat ≈ 1.10) but still did not fully pass the thresholds. A longer extended non-centered run is currently set up in `src/scripts/run_m3_noncentered_extended.R`. **M3 is not yet converged**, which blocks Phases 9, 10, and 12.

### Phases 9–12 — Code written, execution blocked on M3

- **Posterior inference (Phase 9):** All summary code (means, 95% CIs, HPD, directional probabilities like `P(β_cdr > 0 | y)`, country caterpillar plot) is implemented and has run on M1/M2 posteriors but awaits a valid M3.
- **Posterior predictive checks (Phase 10):** Four test quantities are frozen (mean success, variance, count below 0.70, within-region variance). Threshold 0.70 was chosen and locked. Code ready.
- **Parameter recovery (Phase 11):** True parameter values are frozen; 50 simulated datasets per model planned. Code ready, waiting for JAGS time.
- **DIC (Phase 12):** Observed-data log-likelihood functions are implemented (not JAGS's default DIC, which would be invalid for M2/M3). Awaiting final posteriors.

### Phases 13–17 — Done where possible without Bayesian posteriors

- **Frequentist comparison (Phase 13):** GLM (M1), `VGAM::vglm` beta-binomial (M2), `lme4::glmer` GLMM (M3) all fitted successfully.
- **Sensitivity analyses (Phase 14):** 14.1 (cohort threshold), 14.2 (TB-HIV predictor), 14.5 (post-2021 definitions) done via the frequentist analogues. 14.3 and 14.4 (prior sensitivities) have alternative JAGS files ready but need a working M3.
- **Polish, report scaffolding, final validation (Phases 15–17):** Table and figure manifests, reproducibility appendix, R Markdown report template with all 21 sections, discussion + conclusion + oral defense notes are all drafted. Bayesian results subsections currently contain placeholders like *"to be completed when posteriors are available."*

---

## What Is Left To Do

The remaining work is gated almost entirely by **one problem: getting M3 to converge.**

1. **Finish M3 MCMC (Phase 8).** Run the extended non-centered version long enough (or tune further) until all key parameters reach R-hat ≤ 1.05 and ESS ≥ 400. If non-centered still doesn't reach the threshold, the decision log anticipates documenting this transparently and possibly relaxing the criterion for a few parameters.
2. **Unblock Phases 9, 10, 12.** Once M3 is good: re-run posterior summaries, posterior predictive checks, and compute DIC across all three models on the locked dataset using the observed-data log-likelihood.
3. **Run the full parameter recovery study (Phase 11).** 50 simulated datasets per model, refit each, report bias, RMSE, and 95% CI coverage — with particular attention to φ (M2/M3) and σ_u (M3).
4. **Fill in the Bayesian vs. frequentist comparison table (Phase 13 finalization).**
5. **Fill in the prior sensitivity analyses 14.3 and 14.4.**
6. **Compile the final PDF report** from `src/report/report.Rmd`, replacing all placeholder text with the real numbers, figures, and interpretation.
7. **Oral defense preparation.** Notes and Q&A quick-reference already exist; just needs real results pasted in.

In one sentence: **the data, EDA, priors, model code, frequentist side, sensitivity scaffolding, and the entire written scaffold are done; the project is now essentially waiting on getting clean convergence for Model 3 so that the downstream Bayesian results, DIC comparison, and final PDF can be produced.**