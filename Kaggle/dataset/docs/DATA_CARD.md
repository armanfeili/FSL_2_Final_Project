# Data Card — Processed WHO TB Treatment Success Dataset, 2012-2023

## Dataset overview

A country-year panel describing tuberculosis treatment outcomes (success
counts and cohort sizes) together with epidemiological burden indicators,
WHO region, and a standardized version of the continuous predictors. The
sample is locked at 1,862 country-years across 180 countries and 12
calendar years (2012-2023), spanning all 6 WHO regions.

## Motivation

The dataset was assembled to study how treatment success rates vary across
countries and regions, while accounting for differences in TB burden,
mortality, and case detection. It is the analytic table behind a Bayesian
beta-binomial study that compared a pooled binomial model, a beta-binomial
model with overdispersion, and a hierarchical (region + country random
effect) beta-binomial model. The processed table is shared so that other
people can reproduce the EDA, fit alternative models, or use the country-
year structure as a teaching example for hierarchical / count-with-cohort
modeling.

## Source data

The raw inputs are public files published by the WHO Global Tuberculosis
Programme:

- TB outcomes (treatment success / cohort)
- TB burden estimates (incidence, mortality, case detection ratio)
- TB data dictionary (variable definitions)

The exact files and roles are recorded in `documentation_tables/data_provenance.csv`.
The Kaggle package does **not** include those raw WHO files; only the
processed derivative table is shipped here. Users who want the raw inputs
should download them directly from WHO at
<https://www.who.int/teams/global-tuberculosis-programme/data>.

### Raw WHO files

Raw WHO files used or downloaded:

- `TB_burden_countries_2026-04-04.csv`
- `TB_data_dictionary_2026-04-04.csv`
- `TB_notifications_2026-04-04.csv`
- `TB_outcomes_2026-04-04.csv`
- `TB_provisional_notifications_2026-04-04.csv`

The raw WHO files are not redistributed in this Kaggle package; only
the processed derivative table is included. See `RAW_SOURCE_FILES.md`.

## Processing pipeline

The pipeline goes from raw merged rows to the locked sample. The exact
counts at each step are in `documentation_tables/attrition_table.csv`. In short:

1. Start from raw merged WHO outcomes + burden rows.
2. Restrict to the year window 2012-2023.
3. Keep rows with `rel_with_new_flg == 1` (new + relapse reported together,
   the comparable definition used across all years).
4. Drop rows missing core identifiers (`iso3`, `year`).
5. Keep only rows with valid outcomes: `cohort > 0` and
   `0 <= success <= cohort`.
6. Drop rows missing core predictors (`g_whoregion`, `e_inc_100k`,
   `e_mort_100k`, `c_cdr`).
7. Apply the cohort-size filter `cohort >= 50` to obtain the locked sample
   used for all three published models.

After this pipeline, predictors are also standardized using the means /
sds in `documentation_tables/standardization_metadata.csv` to produce `year_z`,
`e_inc_100k_z`, `e_mort_100k_z`, `c_cdr_z`.

## Inclusion / exclusion criteria

- Year window: 2012-2023.
- Comparability flag: `rel_with_new_flg == 1` (main filter).
- Valid outcomes: `cohort > 0`, `0 <= success <= cohort`.
- Drop rows missing core predictors (`g_whoregion`, `e_inc_100k`,
  `e_mort_100k`, `c_cdr`).
- Cohort threshold: `cohort >= 50`.
- Final locked sample: 1,862 country-years, 180 countries, 12 years.
- `used_2021_defs_flg` was deliberately **not** used as a main inclusion
  filter (see `PROVENANCE_AND_FILTERING.md` for the reason).

## Variables

See `DATA_DICTIONARY.md` and `documentation_tables/project_variable_dictionary.csv`.
The headline columns are `iso3`, `year`, `g_whoregion`, `success`,
`cohort`, `prop_success`, `e_inc_100k`, `e_mort_100k`, `c_cdr`,
`e_tbhiv_prct`, `used_2021_defs_flg`, plus the standardized
`year_z`, `e_inc_100k_z`, `e_mort_100k_z`, `c_cdr_z`. Numeric internal
keys `country_id` and `region_id` are also provided.

## Intended use

- Reproducing or extending Bayesian / frequentist regressions with a
  count-out-of-cohort response.
- Hierarchical modeling exercises (country and / or region random effects).
- Teaching examples on overdispersion, posterior predictive checks, and
  model comparison.
- Country-year EDA and visualization.

## Limitations

- Treatment success counts are reported by national TB programmes and
  inherit any reporting noise, definition changes, or revisions from the
  underlying WHO files.
- Burden indicators (`e_inc_100k`, `e_mort_100k`, `c_cdr`) are *estimates*
  produced by WHO, not direct measurements; their uncertainty is not
  propagated into this table.
- The cohort threshold (`cohort >= 50`) preferentially drops smaller
  programmes; the AMR region is most affected.
- The post-2021 definition flag (`used_2021_defs_flg`) has heavy
  missingness and is included for sensitivity only; aggregating across
  years assumes definitions are comparable, which is approximately but not
  exactly true.
- The dataset is observational. Associations between predictors and
  treatment success do **not** imply causal effects.

## Ethical / public-health interpretation warnings

- Country-level treatment success rates are sensitive numbers. Please do
  not present them as endorsements, rankings, or "scorecards" of national
  TB programmes.
- Differences across countries reflect a mix of programme effort,
  reporting completeness, case mix, comorbidities (e.g. HIV), and many
  factors not captured here.
- This dataset is a teaching / research derivative; it should not be used
  to make operational public-health decisions or to issue country-specific
  recommendations.

## Attribution / disclaimer

Original data source: WHO Global Tuberculosis Programme. WHO and the
contributing national TB programmes must be acknowledged in any reuse.
This package is **not** an official WHO product and is **not** endorsed
by WHO. See `LICENSE_AND_ATTRIBUTION.md`.
