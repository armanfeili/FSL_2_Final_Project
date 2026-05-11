# Kaggle public notebook

This folder holds the public summary code for the Kaggle dataset
"Processed WHO TB Treatment Success Dataset, 2012-2023". It is **not**
the full university report — the full report (with all derivations,
prior choices, sensitivity tables, and posterior plots) lives in the
original project environment and is too heavy to rerun on Kaggle.

## Files

- `kaggle_analysis_outline.R` — **preferred uploadable Kaggle code file**.
  Plain R script suitable for Kaggle Code (script kernel) and for the
  Kaggle CLI (`kaggle kernels push`).
- `kaggle_analysis_outline.Rmd` — same logic, kept for local /
  RStudio-style editing. Not the file pushed to Kaggle.
- `kernel-metadata.json` — Kaggle CLI metadata that points to the `.R`
  script and to the dataset slug
  `armanfeili7/processed-who-tb-treatment-success-2012-2023`.
- `README.md` — this file.

## Which file should I push to Kaggle?

Push **`kaggle_analysis_outline.R`**. The `.Rmd` is for editing locally;
the `.R` script is what Kaggle's script-kernel runner expects, and it is
what `kernel-metadata.json` already points at via `code_file`.

## What the script does

- Loads `processed_who_tb_treatment_success_country_year_2012_2023.csv` (Kaggle mounted path first,
  then local fallbacks).
- Prints sample summary: rows, columns, year range, country count, and
  number of WHO regions, plus a `summary()` of `success / cohort`.
- Draws three EDA views:
  - distribution of `prop_success`,
  - boxplot of `prop_success` by `g_whoregion`,
  - median + IQR of `prop_success` per year.
- Looks for `bayesian_result_tables.zip` next to the main CSV in the
  Kaggle dataset; if found, automatically unzips it into a temporary
  directory and prints the published result tables:
  - `bayesian_result_tables/dic_comparison_table.csv`,
  - `bayesian_result_tables/ppc_summary_table.csv`,
  - `bayesian_result_tables/posterior_summary_m3.csv`.
  If the ZIP is missing, the script prints a clean note and continues
  with EDA only (it does not fail).

## What the script does *not* do

- It does **not** rerun the full MCMC. The published M1 / M2 / M3 fits
  use R + JAGS and a multi-thousand-iteration chain with discarded
  warm-up; reproducing that inside Kaggle is computationally expensive
  and slow to set up. The bundled result tables are the source of truth for
  the published numbers.
- It does **not** reproduce model selection or sensitivity analyses
  end-to-end. Those are summarized through the bundled tables only.

## Dataset layout this notebook assumes

The attached Kaggle dataset has only one standalone tabular file at the
root, plus two grouped ZIP archives:

- `processed_who_tb_treatment_success_country_year_2012_2023.csv` —
  main analysis table, kept standalone in the dataset root so Kaggle's
  Data Explorer focuses on its 17 columns.
- `documentation_tables.zip` — supporting documentation tables
  (attrition, provenance, sample snapshot, variable dictionary,
  standardization metadata).
- `bayesian_result_tables.zip` — compact Bayesian result tables (DIC
  comparison, PPC summary, M3 posterior summary). The R script unzips
  this automatically when it is present.

## How to run

The script expects the dataset to be attached at
`/kaggle/input/processed-who-tb-treatment-success-2012-2023/` on Kaggle
(the actual mount path may include a `datasets/<owner>/` segment; the
script also does a recursive fallback search). Local fallbacks:
`../dataset/processed_who_tb_treatment_success_country_year_2012_2023.csv`
and `processed_who_tb_treatment_success_country_year_2012_2023.csv` in
the working directory.
