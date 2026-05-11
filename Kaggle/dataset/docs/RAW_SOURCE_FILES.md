# Raw WHO source files

This document lists, by exact filename, the raw WHO Global Tuberculosis
Programme files that were downloaded for the underlying project. The
files themselves are **not** redistributed in this Kaggle package — only
their names are documented here for reproducibility and provenance.

## A. Raw WHO files downloaded

The following files were downloaded from the WHO Global Tuberculosis
Programme public data portal:

- `TB_burden_countries_2026-04-04.csv`
- `TB_data_dictionary_2026-04-04.csv`
- `TB_notifications_2026-04-04.csv`
- `TB_outcomes_2026-04-04.csv`
- `TB_provisional_notifications_2026-04-04.csv`

The date suffix `2026-04-04` records the download date used by the
project; the same files are available at the WHO portal under stable
filenames (without the date stamp).

## B. Primary inputs used for the locked analysis table

The processed analysis table (`processed_who_tb_treatment_success_country_year_2012_2023.csv`) was built
by joining and filtering the following primary inputs:

- `TB_outcomes_2026-04-04.csv` — provides the response columns
  (`newrel_succ`, `newrel_coh`) and the comparability flags
  (`rel_with_new_flg`, `used_2021_defs_flg`).
- `TB_burden_countries_2026-04-04.csv` — provides `g_whoregion`,
  `e_inc_100k`, `e_mort_100k`, `c_cdr`, and `e_tbhiv_prct`.
- `TB_data_dictionary_2026-04-04.csv` — used as a reference for
  variable definitions; not joined into the analysis table itself.

## C. Downloaded for background / inventory only

The following files were downloaded for context and inventory but are
**not** used to build the primary M1 / M2 / M3 modeling table:

- `TB_notifications_2026-04-04.csv`
- `TB_provisional_notifications_2026-04-04.csv`

These notification files are kept in the original project for cross-
checking but they do not contribute any column to the locked analysis
CSV in this package.

## D. Redistribution note

The raw WHO CSV files are not included in this Kaggle package. Users
who need the raw inputs should download them directly from the WHO
Global Tuberculosis Programme data portal. This Kaggle package
distributes only the processed derivative analysis table and
documentation.
