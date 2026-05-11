# Processed WHO TB Treatment Success Dataset, 2012-2023

## Short description

This is a cleaned, joined, and filtered country-year analysis table derived
from public WHO Global Tuberculosis Programme data. It is intended to support
modeling of treatment success rates with country and region structure, and is
the same locked sample used for the underlying Bayesian beta-binomial study.

## Dataset size

- 1,862 country-years
- 180 countries
- Years: 2012-2023 (12 years)
- 6 WHO regions (AFR, AMR, EMR, EUR, SEA, WPR)

## Unit of analysis

One row = one country-year.

## Main response

The treatment outcome is given as counts:

- `success` out of `cohort`

Models should use these two integer columns directly (e.g. binomial /
beta-binomial likelihood). The column `prop_success = success / cohort` is
provided for convenience and visualization only; it should not be the sole
quantity passed to a likelihood, because it discards the cohort size and
hides heteroskedasticity.

## Main predictors

- `year_z` (standardized year)
- `e_inc_100k_z` (standardized estimated TB incidence per 100k)
- `e_mort_100k_z` (standardized estimated TB mortality per 100k)
- `c_cdr_z` (standardized case detection ratio)
- `g_whoregion` (categorical, baseline = AFR)

`e_tbhiv_prct` and `used_2021_defs_flg` are included for sensitivity / EDA
only, not for the main model.

## Files

Dataset root:

- `processed_who_tb_treatment_success_country_year_2012_2023.csv` — main country-year analysis table, one row per country-year. (Note: the original project called this file `main_analysis_table_locked.csv`; in the public Kaggle package it is renamed to `processed_who_tb_treatment_success_country_year_2012_2023.csv` for clarity.)
- `dataset-metadata.json` — Kaggle dataset metadata (id, description, schema).

`docs/` folder (this folder):

- Markdown documentation: `DATA_CARD.md`, `DATA_DICTIONARY.md`, `PROVENANCE_AND_FILTERING.md`, `LICENSE_AND_ATTRIBUTION.md`, `RAW_SOURCE_FILES.md`, and this `README.md`.
- `CITATION.cff` — machine-readable citation entry for this processed derivative.
- `checksums.txt` — SHA256 checksums for the main CSV, helper CSVs, and documentation files.

`documentation_tables/` folder — supporting documentation tables:

- `attrition_table.csv` — exact filtering pipeline from raw merged rows to the locked sample.
- `data_provenance.csv` — which raw WHO files were used and their roles.
- `final_sample_snapshot.csv` — quick numeric summary of the locked sample.
- `project_variable_dictionary.csv` — original project-level variable dictionary.
- `standardization_metadata.csv` — means / sds used to build the `_z` columns.

`bayesian_result_tables/` folder — compact result tables:

- `dic_comparison_table.csv` — DIC model-comparison table.
- `posterior_summary_m3.csv` — posterior summary for the preferred hierarchical model M3.
- `ppc_summary_table.csv` — posterior predictive check summary.

## Source attribution

Original data source: World Health Organization Global Tuberculosis Programme
(<https://www.who.int/teams/global-tuberculosis-programme/data>).

## Raw WHO files

Raw WHO files used or downloaded:

- `TB_burden_countries_2026-04-04.csv`
- `TB_data_dictionary_2026-04-04.csv`
- `TB_notifications_2026-04-04.csv`
- `TB_outcomes_2026-04-04.csv`
- `TB_provisional_notifications_2026-04-04.csv`

The raw WHO files are not redistributed in this Kaggle package; only
the processed derivative table is included. See `RAW_SOURCE_FILES.md`.

## Disclaimer

This is a processed derivative dataset created for academic / statistical
learning purposes. It is **not** an official WHO dataset and is **not**
endorsed by WHO. Any errors introduced during cleaning, joining, or
filtering are the responsibility of the dataset author, not WHO.

## Suggested citation

Arman Feili, *Processed WHO TB Treatment Success Dataset, 2012-2023*,
derived from WHO Global Tuberculosis Programme public data.

## License note

Do **not** redistribute this package as CC0. The original source rights and
the requirement to credit WHO and contributing countries belong to WHO.
This package is provided as a processed derivative. See
`LICENSE_AND_ATTRIBUTION.md` for the full attribution requirements before
reusing or redistributing the data.
