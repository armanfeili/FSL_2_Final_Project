# Provenance and filtering

## Provenance

The raw inputs to this dataset are public files published by the WHO
Global Tuberculosis Programme at
<https://www.who.int/teams/global-tuberculosis-programme/data>.

The exact files used (with their roles) are listed in
`documentation_tables/data_provenance.csv`. Two files were the primary inputs:

- `TB_outcomes_*.csv` — treatment outcomes (provides the response columns
  via `newrel_succ` and `newrel_coh`, plus the comparability flag
  `rel_with_new_flg` and the post-2021 definition flag
  `used_2021_defs_flg`).
- `TB_burden_countries_*.csv` — TB burden estimates (provides
  `g_whoregion`, `e_inc_100k`, `e_mort_100k`, `c_cdr`, `e_tbhiv_prct`).

A WHO data dictionary file was used as the reference for variable
definitions. Notification and provisional notification files were also
downloaded but are **not** used by the main analysis.

### Raw WHO files

Raw WHO files used or downloaded:

- `TB_burden_countries_2026-04-04.csv`
- `TB_data_dictionary_2026-04-04.csv`
- `TB_notifications_2026-04-04.csv`
- `TB_outcomes_2026-04-04.csv`
- `TB_provisional_notifications_2026-04-04.csv`

The raw WHO files are not redistributed in this Kaggle package; only
the processed derivative table is included. See `RAW_SOURCE_FILES.md`.

The Kaggle package does **not** redistribute the raw WHO CSV files.
Anyone who wants the exact raw inputs should download them directly from
the WHO portal above. The CSV in this package is a processed derivative
created by joining the outcomes and burden files on `iso3` and `year`,
applying the filtering pipeline below, and deriving standardized
predictors.

## Filtering pipeline (attrition)

The exact step-by-step row counts are in `documentation_tables/attrition_table.csv`:

| Step | Filter | Rows | Countries | Years |
| --- | --- | --- | --- | --- |
| 0 | Raw merged rows | 5,130 | 217 | 24 |
| 1 | Restrict to years 2012-2023 | 2,580 | 215 | 12 |
| 2 | `rel_with_new_flg == 1` | 2,138 | 212 | 12 |
| 3 | Drop missing identifiers | 2,138 | 212 | 12 |
| 4 | Valid outcomes (`cohort > 0`, `0 <= success <= cohort`) | 2,094 | 207 | 12 |
| 5 | Drop missing core predictors | 2,071 | 206 | 12 |
| 6 | `cohort >= 50` | 1,862 | 180 | 12 |

Step 6 is the **locked sample** distributed in this Kaggle package.

## Why the locked dataset is used for all three models

The published study fits three models — a pooled binomial (M1), a
beta-binomial (M2), and a hierarchical beta-binomial with country and
region effects (M3). Using the same locked sample for all three models is
deliberate:

- It makes DIC and other model comparison statistics comparable across
  models — they are computed on the same likelihood evaluations.
- It eliminates one common source of confounding ("did the model improve
  or did the data change?").
- It makes the attrition story transparent and auditable: a single
  pipeline in, one CSV out, three models on top.

If you re-fit on a different sample (e.g. by relaxing the cohort filter),
you should also refit M1, M2, and M3 on the same new sample and recompute
DIC there.

## Why `used_2021_defs_flg` was *not* used as the main filter

`used_2021_defs_flg` indicates rows reported under WHO's post-2021
treatment-outcome definitions. Two reasons it is not used as a hard
filter:

1. **Missingness is severe.** In the raw outcomes file the flag is
   missing for the large majority of country-years
   (`missingness_pct ≈ 88%` in the project variable dictionary). Using it
   as a hard inclusion filter would collapse the sample to a tiny
   post-2021 subset and lose the country-year panel structure.
2. **It is not necessary for comparability.** The main filter
   `rel_with_new_flg == 1` already enforces the comparable
   "new + relapse" reporting convention that has been used consistently
   across 2012-2023. The post-2021 definition change is a refinement, not
   a redefinition of the response.

The flag is kept in the locked CSV so that anyone who wants to run a
*sensitivity* analysis (e.g. restrict to post-2021 rows, or interact a
post-2021 dummy with the predictors) can do so without re-deriving it.

## Why `cohort >= 50` was applied

The cohort threshold removes country-years where the reported cohort is
too small for the observed proportion `success / cohort` to be informative.
Specifically:

- With `cohort < 50`, even modest binomial sampling noise produces large
  swings in the empirical proportion, which destabilizes the
  beta-binomial overdispersion parameter and the hierarchical fit.
- Posterior predictive checks on M3 are much more stable above the
  threshold; below it, simulated cohorts mechanically dominate the tail
  diagnostics.
- It limits the effect of countries that report only a handful of cases
  per year, which are not representative of programme-level performance.

`documentation_tables/final_sample_snapshot.csv` records that 26 countries are entirely lost to
this filter, with AMR being the most affected region (~19% region loss).
This trade-off is accepted in exchange for stable estimates of region
effects and overdispersion. Sensitivity to the threshold is explored in
the original project's `sensitivity_14_1_cohort_threshold.csv`; the main
conclusions are robust to reasonable variations.
