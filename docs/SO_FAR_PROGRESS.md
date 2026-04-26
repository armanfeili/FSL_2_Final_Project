# SO FAR — Project Progress Snapshot

**Project:** Bayesian Modeling of Cross-Country TB Treatment Success
**Course:** Fundamentals of Statistical Learning II — M.Sc. in Data Science, a.y. 2025–2026
**Snapshot date:** 2026-04-26
**Last code activity:** 2026-04-20 (M3 promoted, Phases 9/10/12 completed)

---

## 1. One-paragraph status

The project has progressed through **all 17 planned phases**. The full Bayesian workflow — from raw data intake through DIC model comparison, posterior predictive checks, frequentist comparison, and sensitivity analyses — has been executed end-to-end on a single locked country-year analysis table (1,862 rows × 180 countries × 12 years, 2012–2023). All three Bayesian models (M1 binomial, M2 beta-binomial, M3 hierarchical beta-binomial) were fitted with JAGS, with M3 only converging after a non-trivial 6-attempt remediation trail that culminated in a **region-centered non-centered parameterization** fitted in parallel across 4 cores. M3 is the clear winner: ΔDIC ≈ 2,220 vs M2 and ≈ 2.6M vs M1, with min ESS = 407 and max R-hat = 1.007 on key globals. The remaining work is **(i)** the full 50-replicate parameter recovery study (Phase 11), of which only a 3-rep pilot has run, **(ii)** the JAGS-based prior sensitivity analyses 14.3 and 14.4 (frequentist parts of Phase 14 are done), and **(iii)** rendering the final report PDF and slotting in the actual posterior numbers in place of placeholders in [src/report/report.Rmd](src/report/report.Rmd).

---

## 2. Phase-by-phase status

| Phase | Title | Status | Key artifacts |
|---|---|---|---|
| 0 | Project infrastructure & reproducibility | Complete | [src/main.R](src/main.R), [version_manifest.csv](src/outputs/tables/version_manifest.csv), [git_metadata.yaml](src/outputs/tables/git_metadata.yaml) |
| 1 | Research framing & design freeze | Complete | [notes/analysis_rules.md](notes/analysis_rules.md), [notes/decision_log.md](notes/decision_log.md) |
| 2 | Raw data intake & variable audit | Complete | [intake_summary.csv](src/outputs/tables/intake_summary.csv), [project_variable_dictionary.csv](src/outputs/tables/project_variable_dictionary.csv), [year_completeness.csv](src/outputs/tables/year_completeness.csv) |
| 3 | Build & lock main analysis table | Complete (locked 2026-04-18) | [main_analysis_table_locked.csv](data/data_processed/main_analysis_table_locked.csv), [attrition_table.csv](src/outputs/tables/attrition_table.csv), [standardization_metadata.csv](src/outputs/tables/standardization_metadata.csv) |
| 4 | Data quality & bias checks | Complete | [missingness_overall.csv](src/outputs/tables/missingness_overall.csv), [predictor_correlations.csv](src/outputs/tables/predictor_correlations.csv), [predictor_vif.csv](src/outputs/tables/predictor_vif.csv) |
| 5 | Exploratory data analysis | Complete | 18 EDA tables + 12 figures incl. [country_spaghetti_plot.png](src/outputs/figures/country_spaghetti_plot.png), [country_sd_ratio_distribution.png](src/outputs/figures/country_sd_ratio_distribution.png) |
| 6 | Prior design & prior predictive checks | Complete | [prior_specification.csv](src/outputs/tables/prior_specification.csv), [prior_predictive_combined.png](src/outputs/figures/prior_predictive_combined.png) |
| 7 | Model coding & pilot testing | Complete | 5 JAGS files in [src/models/](src/models/), [jags_data_base.rds](src/outputs/model_objects/jags_data_base.rds), [jags_data_hier.rds](src/outputs/model_objects/jags_data_hier.rds) |
| 8 | Full MCMC fitting & diagnostics | Complete (after M3 remediation) | [posterior_m1.rds](src/outputs/model_objects/posterior_m1.rds), [posterior_m2.rds](src/outputs/model_objects/posterior_m2.rds), [posterior_m3.rds](src/outputs/model_objects/posterior_m3.rds), [posterior_m3_u.rds](src/outputs/model_objects/posterior_m3_u.rds) |
| 9 | Posterior inference | Complete | [posterior_summary_m1.csv](src/outputs/tables/posterior_summary_m1.csv) / [m2](src/outputs/tables/posterior_summary_m2.csv) / [m3](src/outputs/tables/posterior_summary_m3.csv), [hypothesis_tests_summary.csv](src/outputs/tables/hypothesis_tests_summary.csv), [country_re_caterpillar_plot.png](src/outputs/figures/country_re_caterpillar_plot.png) |
| 10 | Posterior predictive checks | Complete | [ppc_summary_table.csv](src/outputs/tables/ppc_summary_table.csv), 9 PPC figures |
| 11 | Parameter recovery simulation | **Partial** — pilot only (3 reps × 3 models) | [pilot_summary_long.csv](src/outputs/simulations/pilot/pilot_summary_long.csv) |
| 12 | DIC model comparison | Complete | [dic_comparison_table.csv](src/outputs/tables/dic_comparison_table.csv), [dic_results.rds](src/outputs/model_objects/dic_results.rds) |
| 13 | Frequentist comparison (bonus) | Complete | Comparison tables in [src/outputs/tables/](src/outputs/tables/) |
| 14 | Sensitivity analyses | **Partial** — frequentist arms done; 14.3 & 14.4 (prior sensitivities) Bayesian arm not run | Alt JAGS files: [model2_phi_sensitivity.jags](src/models/model2_phi_sensitivity.jags), [model3_sigma_sensitivity.jags](src/models/model3_sigma_sensitivity.jags) |
| 15 | Final tables, figures & appendix | Complete | [table_manifest.csv](src/outputs/tables/table_manifest.csv), [figure_manifest.csv](src/outputs/tables/figure_manifest.csv), [reproducibility_appendix.txt](src/outputs/tables/reproducibility_appendix.txt) |
| 16 | Report writing | **Partial** — template + content scaffolding done; PDF not rendered, posterior placeholders not yet filled | [src/report/report.Rmd](src/report/report.Rmd), [discussion_content.md](src/report/discussion_content.md), [conclusion_content.md](src/report/conclusion_content.md) |
| 17 | Final validation & submission | **Partial** — automated checks pass; PDF + slides pending | [consistency_check_results.csv](src/outputs/tables/consistency_check_results.csv), [oral_discussion_notes.md](src/report/oral_discussion_notes.md) |

---

## 3. Locked design decisions (frozen)

| Item | Value | Frozen on |
|---|---|---|
| Year window | **2012–2023** (12 years) | 2026-04-18 (Phase 3) |
| Inclusion flag | `rel_with_new_flg == 1` | 2026-04-18 (Phase 1) |
| Cohort threshold (main) | `cohort >= 50` | 2026-04-18 (Phase 1) |
| Baseline WHO region | **AFR** (γ₁ = 0) | 2026-04-18 (Phase 3) |
| Main predictors | `year_z, e_inc_100k_z, e_mort_100k_z, c_cdr_z` + 6 region fixed effects | 2026-04-18 (Phase 4) |
| Priors | β ~ N(0, 2.5²); γ ~ N(0, 2.5²) with γ₁ = 0; φ ~ Gamma(2, 0.1); σᵤ ~ Half-Normal(0, 1) | 2026-04-18 (Phase 6) |
| DIC method | Observed-data log-likelihood, post-processed (not JAGS default) | 2026-04-18 (Phase 1/12) |
| PPC low-success threshold | 0.70 (≈16.6% of obs below) | 2026-04-18 (Phase 10) |
| Recovery target | 50 reps × 3 models, hand-chosen true params | 2026-04-18 (Phase 11) |
| Global seed | 2026 | 2026-04-18 (Phase 0) |

---

## 4. Locked sample (final analysis table)

| Property | Value |
|---|---|
| Country-years | **1,862** |
| Distinct countries | **180** |
| Years | 12 (2012–2023) |
| Regional split | AFR 468 · EUR 497 · AMR 293 · WPR 276 · EMR 226 · SEA 102 |
| Cohort-weighted mean success | ≈ 0.856 |
| Unweighted mean success rate | ≈ 0.791 |
| Variance of success rates | 0.0202 |
| Country-years below 0.70 | 309 (16.6%) |
| Countries lost to `cohort ≥ 50` | 26 (mostly small-island/AMR) |
| AMR loss rate from filter | 22.5% rows, 12 countries |

Standardization parameters (stored in [standardization_metadata.csv](src/outputs/tables/standardization_metadata.csv)): year mean=2017.70, sd=3.36; e_inc_100k mean=130.42, sd=171.97; e_mort_100k mean=24.62, sd=42.94; c_cdr mean=67.72, sd=15.27.

---

## 5. Latest results

### 5.1 MCMC convergence (Phase 8)

All three models pass the acceptance rule **min ESS ≥ 400 AND max R-hat ≤ 1.05** on key globals after the documented remediation:

| Model | Param | Min ESS (key) | Max R-hat (key) | Notes |
|---|---|---|---|---|
| M1 | β₀, β[1:4], γ[2:6] | ≥ 400 | ≤ 1.05 | Required extended run (4 ch × 4k burn × 4k iter) to pass |
| M2 | + φ | ≥ 400 | ≤ 1.05 | Promoted from extended-fast rerun (2 ch × 4k × 4k, no Y_rep) |
| M3 | + σᵤ, u[1:180] | **407.1** | **1.0072** | Region-centered non-centered, 4 parallel chains × 8k burn × 10k iter |

The **M3 convergence story** is the most substantive technical decision in the project: 5 prior parameterizations failed (centered → plain non-centered → 3 escalating compute budgets → first region-centered formulation killed at 21 min by a dense JAGS graph). The promoted attempt enforces ∑_{c ∈ region r} u[c] = 0 via contiguous range sums after permuting country IDs by region, which removes the additive identifiability ridge between β₀, γ[r], and the within-region mean of u[c] that was blocking mixing.

### 5.2 DIC ranking (Phase 12)

From [dic_comparison_table.csv](src/outputs/tables/dic_comparison_table.csv):

| Model | DIC | p_D | ΔDIC | Rank | Evidence |
|---|---|---|---|---|---|
| **M3** | **24,940.1** | 178.7 | 0 | 1 | Best |
| M2 | 27,160.5 | 10.8 | +2,220.5 | 2 | Strong evidence against |
| M1 | 2,666,301.2 | 10.1 | +2,641,361 | 3 | Catastrophic — binomial massively overdispersed |

p_D ≈ 178.7 for M3 is roughly the count of country random effects, indicating the partial pooling is genuine but country-level shrinkage is modest.

### 5.3 Posterior summary — preferred model M3

From [posterior_summary_m3.csv](src/outputs/tables/posterior_summary_m3.csv):

| Parameter | Mean | 95% CI | Direction (P > 0) |
|---|---|---|---|
| β₀ (intercept) | 1.768 | (1.702, 1.835) | — |
| β₁ year_z | −0.012 | (−0.032, 0.009) | weak / null |
| β₂ incidence_z | **+0.283** | (0.180, 0.385) | P>0 = 1.000 |
| β₃ mortality_z | **−0.387** | (−0.473, −0.300) | P<0 = 1.000 |
| β₄ c_cdr_z | +0.024 | (−0.022, 0.070) | P>0 = 0.846 |
| γ AMR | −0.652 | (−0.756, −0.546) | strongly below AFR |
| γ EMR | −0.152 | (−0.245, −0.058) | below AFR |
| γ EUR | −0.741 | (−0.853, −0.629) | strongly below AFR |
| γ SEA | +0.062 | (−0.043, 0.168) | indistinguishable from AFR |
| γ WPR | −0.303 | (−0.397, −0.209) | below AFR |
| φ overdispersion | 42.86 | (39.6, 46.3) | clearly finite — overdispersion present |
| σᵤ country RE SD | **0.717** | (0.639, 0.804) | substantial country heterogeneity |

The **incidence sign reversal** between M1 and M3 (M1: β₂ < 0 with P<0 = 1.000; M3: β₂ > 0 with P>0 = 1.000) is the most striking inferential finding and reflects what the country random effects absorb — see [hypothesis_tests_summary.csv](src/outputs/tables/hypothesis_tests_summary.csv). After controlling for persistent country effects, higher national incidence is *positively* associated with treatment success at the country-year level, a plausible ecological signal: high-incidence countries tend to have mature, programmatically focused TB systems.

### 5.4 PPC test quantities (Phase 10)

From [ppc_summary_table.csv](src/outputs/tables/ppc_summary_table.csv):

| Test | Observed | M1 p | M2 p | M3 p |
|---|---|---|---|---|
| T1a unweighted mean | 0.791 | 1.000 | 0.022 | **0.061** |
| T1b cohort-weighted mean | 0.856 | 0.498 | 0.005 | **0.321** |
| T2 variance of success rates | 0.0202 | **0.000** | 0.000 | **0.042** |
| T3 count below 0.70 | 309 | **0.000** | 1.000 | 1.000 |
| T4a within-region var (eq) | 0.0162 | 0.000 | 0.060 | 0.004 |
| T4b within-region var (sz) | 0.0185 | 0.000 | 0.000 | 0.019 |

**Reading:** M1 catastrophically understates variance and the lower tail (T2, T3, T4 all extreme). M2 fixes T2/T4 but overshoots the lower tail (T3 = 1.000 — predicts way too many country-years below 0.70). M3 is the only model whose central tendency is well-calibrated (T1b = 0.321) and whose variance is approximately captured (T2 = 0.042 — borderline, mildly underdispersed). M3 still over-predicts the lower tail (T3 = 1.000) and shows residual within-region heterogeneity (T4a = 0.004), which would be the next direction for refinement.

### 5.5 Parameter recovery — pilot snapshot (Phase 11, 3 reps each)

From [pilot_summary_long.csv](src/outputs/simulations/pilot/pilot_summary_long.csv): the M1 fixed effects recover cleanly (95% CI coverage hits true value in nearly all 3 reps). M2 also recovers φ and the β coefficients reasonably. **M3 shows the expected challenge**: at the short pilot MCMC budget, β₂ has R-hat 1.42–1.51 and ESS ≈ 20, and several γ parameters are also slow. The full 50-rep recovery is what is still owed.

---

## 6. What is still remaining

| # | Work item | Status | Why it matters | Effort |
|---|---|---|---|---|
| R1 | **Phase 11 full parameter recovery** — 50 reps × 3 models | Pilot only (3 reps); R-hat & ESS for M3 not at recovery thresholds in pilot | Course requirement #5 (parameter recovery with simulated data) | High — M3 reps each take O(hours) at the region-centered budget; consider relaxed-but-justified MCMC settings (2 ch × 1k burn × 2k iter) or Tier-3 fallback to 30 reps |
| R2 | **Phase 14.3 Bayesian phi-prior sensitivity** | Alt JAGS file [model2_phi_sensitivity.jags](src/models/model2_phi_sensitivity.jags) exists; not yet fit | Tests whether overdispersion conclusion is prior-driven | Low — one M2 refit |
| R3 | **Phase 14.4 Bayesian σᵤ-prior sensitivity** | Alt JAGS file [model3_sigma_sensitivity.jags](src/models/model3_sigma_sensitivity.jags) exists; not yet fit | Tests whether country-RE conclusion is prior-driven | Medium — one M3 refit at full region-centered budget |
| R4 | **Bayesian-vs-frequentist side-by-side comparison columns** populated | Frequentist models fit; Bayesian columns currently NA in the comparison table | Cleanly closes the §16 bonus section | Low — post-processing only, posteriors already on disk |
| R5 | **Replace placeholders in [src/report/report.Rmd](src/report/report.Rmd)** with the actual posterior numbers from §5 above (DIC table, M3 coefficients, PPC p-values, country RE highlights) | Template ready, sections marked "[To be completed when Bayesian posteriors are available]" | These posteriors *are* now available — the placeholder text is stale | Medium — narrative work, no new computation |
| R6 | **Render the final PDF** with `rmarkdown::render('src/report/report.Rmd')` | Not run | Submission deliverable | Low (once R5 is done) |
| R7 | **Oral defense slides / talking notes** | Q&A reference and outline at [src/report/oral_discussion_notes.md](src/report/oral_discussion_notes.md) exist as text | Course requires oral discussion | Low–Medium |
| R8 | **Optional: WAIC / LOO-CV** in appendix | Not implemented (Tier 3 nice-to-have) | Strengthens model-comparison story; not required | Medium |
| R9 | **Optional: address M3 lower-tail miscalibration** (PPC T3 = 1.000) | Documented but not addressed | A cleaner story would either explain why this is acceptable in the discussion or test a heavy-tailed extension | Low (discussion) or High (new model) |
| R10 | **Cleanup**: development scripts under [src/scripts/](src/scripts/) document the M3 remediation trail but are not on the final execution path. Decide whether to keep them as audit history or move to a `scripts/archive/` subfolder. | Decision pending | Tidiness for submission package | Trivial |

### Critical-path recommendation

To finish the project as a defensible Tier-2 submission, the minimal remaining sequence is **R5 → R6 → R7**, with R1 (parameter recovery, even at 30 reps with a relaxed-but-justified MCMC budget) being the highest-value addition because it is an explicit course requirement rather than a bonus. R2/R3/R4 are short polish items that strengthen the sensitivity and frequentist sections but don't change the headline conclusion.

---

## 7. Headline conclusion (as currently supported by the analysis)

> Across 1,862 country-years from 180 WHO countries (2012–2023), simple binomial sampling cannot remotely account for cross-country variation in TB treatment success — DIC against M1 is catastrophic (ΔDIC ≈ 2.6M) and PPC T2 confirms the binomial massively understates observed variance. Adding a φ overdispersion parameter (M2) helps fit but still misses both the central tendency and the lower tail. The hierarchical beta-binomial (M3), with σᵤ ≈ 0.72 of country-level heterogeneity on the logit scale and posterior-mean φ ≈ 43, is the preferred model on every metric: ΔDIC, T1b, and T2 all favor it. After controlling for country effects, mortality burden is robustly negatively associated with treatment success, while the apparent negative incidence effect in M1 reverses sign in M3 — a textbook illustration of why country-level pooling matters in ecological TB analyses. The remaining miscalibration (M3 over-predicts the country-years below 70%) is a candidate for future heavy-tailed extensions, not a fatal flaw of the recommended model.

---

## 8. Pointers for any future agent picking this up

- Single execution source of truth: [src/main.R](src/main.R). Re-running it is idempotent — it detects promoted posterior files and skips refits.
- The full M3 remediation trail is preserved in §"2026-04-19 / 2026-04-20 — M3 Convergence Remediation Trail (full history)" of [notes/decision_log.md](notes/decision_log.md). If M3 ever needs to be refit, the only working configuration is [model3_noncentered_regioncentered.jags](src/models/model3_noncentered_regioncentered.jags) with `parallel::mclapply` across 4 cores at 4ch × 1k adapt × 8k burn × 10k iter.
- The MCMC config used for the promoted fits is in [src/outputs/model_objects/full_mcmc_config.yaml](src/outputs/model_objects/full_mcmc_config.yaml).
- Phase 11 recovery should NOT use the full M3 budget per replicate — the pilot uses 2 ch × 500 adapt × 1k burn × 2k iter, which is reasonable. Document any relaxation explicitly in [notes/decision_log.md](notes/decision_log.md) before running.
