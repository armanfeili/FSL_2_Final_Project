# Kaggle public notebook — Bayesian Modeling of WHO TB Treatment Success

A public companion to the Kaggle dataset
[`armanfeili7/processed-who-tb-treatment-success-2012-2023`](https://www.kaggle.com/datasets/armanfeili7/processed-who-tb-treatment-success-2012-2023).

The notebook reproduces, on the Kaggle dataset alone:

- the exploratory data analysis,
- the Bayesian model-comparison summaries (DIC and posterior predictive checks),
- the posterior summary for the preferred hierarchical beta-binomial model (M3),
- the public interpretation layer.

**The full JAGS MCMC fitting was performed in the original project environment.
This notebook does not refit the models.** It uses the exported compact result
tables that ship inside the Kaggle dataset
(`bayesian_result_tables/dic_comparison_table.csv`,
`bayesian_result_tables/ppc_summary_table.csv`,
`bayesian_result_tables/posterior_summary_m3.csv`).

## Files

- `who_tb_bayesian_analysis_kaggle.R` — the uploadable Kaggle Code file (script
  kernel). Referenced by `kernel-metadata.json`.
- `who_tb_bayesian_analysis_kaggle.Rmd` — the narrative version, written in
  report style with interpretation paragraphs after each main plot and table.
  Intended for local rendering / RStudio editing. Not pushed to Kaggle.
- `kernel-metadata.json` — Kaggle CLI metadata that points the script kernel at
  the `.R` file and attaches the dataset slug above.
- `README.md` — this file.

Both the `.R` and `.Rmd` consume only files inside the Kaggle dataset (main
CSV plus the `documentation_tables/` and `bayesian_result_tables/` folders).
They do not require raw WHO files, `.rds` objects, JAGS posterior draws, or
any local project artifacts.

## Reproduced content

- Dataset overview, provenance, attrition pipeline, final-sample snapshot.
- Variable dictionary and standardization metadata.
- EDA: success-rate distribution, cohort distribution, region boxplots, yearly
  trend (median + IQR vs cohort-weighted), region temporal trend, region-year
  heatmap, top/bottom 15 countries, bivariate predictor panels, year scatter,
  predictor correlation matrix, missingness summary.
- Bayesian model ladder narrative (M1 / M2 / M3).
- DIC table and DIC / ΔDIC bar charts.
- M3 posterior summary table and credible-interval caterpillar plot.
- PPC summary table, Bayesian-p plot, and observed-vs-replicated plot.
- Interpretation, limitations, reuse and citation note, and conclusion.

## Not reproduced (and why)

Some figures from the original full report require artifacts that are not
part of the Kaggle dataset and are summarized through exported tables only:

- Per-country random-effect caterpillar plots and top / bottom country tables.
- Posterior predictive density overlays (need the full PPC draws).
- MCMC diagnostics tables (R-hat, ESS per parameter).
- Prior predictive simulations and parameter-recovery figures.
- Robustness / sensitivity tables that were not exported into the Kaggle
  dataset.

## Pushing to Kaggle

`kernel-metadata.json` is configured for a private script kernel by default:

```text
id              armanfeili7/bayesian-modeling-of-who-tb-treatment-success
code_file       who_tb_bayesian_analysis_kaggle.R
language        r
kernel_type     script
is_private      true
enable_internet false
dataset_sources [armanfeili7/processed-who-tb-treatment-success-2012-2023]
```

When you want to push (privately):

```bash
cd Kaggle/notebook
kaggle kernels push -p .
kaggle kernels status armanfeili7/bayesian-modeling-of-who-tb-treatment-success
```

To make it public later, flip the visibility from the Kaggle UI, or change
`"is_private": false` and push another version.
