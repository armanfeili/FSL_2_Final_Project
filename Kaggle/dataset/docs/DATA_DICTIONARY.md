# Data Dictionary — `processed_who_tb_treatment_success_country_year_2012_2023.csv`

The processed analysis table has 1,862 rows (country-years) and 17 columns.
For each column, this dictionary lists its type, meaning, role in the
project, and whether it was used in the **primary** model fits or only in
**sensitivity / descriptive** analyses.

The "Source-file" column refers to the original WHO file group used to
build the variable, mirroring `documentation_tables/project_variable_dictionary.csv`.

| Column | Type | Source-file | Meaning | Role in project | Used in primary models? |
| --- | --- | --- | --- | --- | --- |
| `iso3` | string (3 letters) | both WHO outcomes + burden | ISO-3166 alpha-3 country code | Identifier (country key) | Yes — used to define country random effect index |
| `year` | integer | both | Calendar year, 2012-2023 | Identifier / time | Yes — also used to build `year_z` |
| `country_id` | integer | derived | Internal 1..N country index aligned with `iso3` | Identifier (numeric key for hierarchical models) | Yes — used by JAGS hierarchical model M3 |
| `region_id` | integer | derived | Internal 1..6 region index aligned with `g_whoregion` | Identifier (numeric key for region effect) | Yes — used by hierarchical model M3 |
| `g_whoregion` | string (3 letters) | WHO burden | WHO region code: AFR, AMR, EMR, EUR, SEA, WPR | Categorical predictor (baseline = AFR) | Yes — main predictor |
| `success` | integer | WHO outcomes (`newrel_succ`) | Number of treatment successes (new + relapse) for that country-year | Response numerator | Yes — main response |
| `cohort` | integer | WHO outcomes (`newrel_coh`) | Treatment cohort size (new + relapse) | Response denominator | Yes — main response (binomial / beta-binomial size) |
| `prop_success` | numeric in [0, 1] | derived | `success / cohort`, treatment success proportion | EDA / plotting | Descriptive only — never used as the likelihood input |
| `e_inc_100k` | numeric | WHO burden | Estimated TB incidence per 100,000 population | Continuous predictor (raw scale) | Sensitivity / EDA — main models use `e_inc_100k_z` |
| `e_mort_100k` | numeric | WHO burden | Estimated TB mortality per 100,000 population | Continuous predictor (raw scale) | Sensitivity / EDA — main models use `e_mort_100k_z` |
| `c_cdr` | numeric | WHO burden | Case detection ratio (%) | Continuous predictor (raw scale) | Sensitivity / EDA — main models use `c_cdr_z` |
| `year_z` | numeric | derived | `(year - mean) / sd` using the standardization metadata | Continuous predictor (standardized) | Yes — main predictor |
| `e_inc_100k_z` | numeric | derived | Standardized incidence | Continuous predictor (standardized) | Yes — main predictor |
| `e_mort_100k_z` | numeric | derived | Standardized mortality | Continuous predictor (standardized) | Yes — main predictor |
| `c_cdr_z` | numeric | derived | Standardized case detection ratio | Continuous predictor (standardized) | Yes — main predictor |
| `e_tbhiv_prct` | numeric | WHO burden | TB-HIV co-infection percentage | Continuous predictor | Sensitivity only (substantial missingness; not in primary M1/M2/M3) |
| `used_2021_defs_flg` | binary (0 / 1, NA) | WHO outcomes | Indicates rows reported under post-2021 definitions | Sensitivity flag | Sensitivity only — see `PROVENANCE_AND_FILTERING.md` for why this is not a main filter |

## Notes

- Means and standard deviations used to build the `_z` columns are stored
  in `documentation_tables/standardization_metadata.csv`. Re-standardize from the raw
  columns if you change the sample.
- `prop_success` should not be used as the sole response in a model; pass
  `(success, cohort)` to a binomial / beta-binomial likelihood instead.
- The country and region indices (`country_id`, `region_id`) are stable
  within this locked CSV but are arbitrary integer encodings — use `iso3`
  / `g_whoregion` if you re-export.
- All counts are non-negative integers. Predictor missingness has already
  been handled by the filtering pipeline, so the main predictors should
  be complete; `e_tbhiv_prct` may still contain `NA`, and
  `used_2021_defs_flg` is mostly `NA` by design.
