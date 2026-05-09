# Bayesian Modeling of Cross-Country TB Treatment Success

Live report (GitHub Pages): https://armanfeili.github.io/FSL_2_Final_Project/

This project analyzes WHO tuberculosis country-year data (2012-2023) with fully Bayesian MCMC models in JAGS.

The main question is simple: which model explains treatment success best?

- M1: Binomial logistic
- M2: Beta-binomial
- M3: Hierarchical beta-binomial

## Main Result

The preferred model is **M3 (hierarchical beta-binomial)**.

From the final report:
- DIC: **M3 = 24,940**, **M2 = 27,160**, **M1 = 2,666,301**
- M3 captures both:
  - overdispersion (**phi = 42.9**)
  - persistent country-level heterogeneity (**sigma_u = 0.72**)

In short, binomial sampling variability alone is not enough for these data.

## Final Report

Open the final HTML report here:

- [src/report/Arman_Feili_FSL2_Final_Report.html](src/report/Arman_Feili_FSL2_Final_Report.html)

## How to Run

Run the full analysis from the project root:

```bash
Rscript src/main.R
```

Regenerate the final report directly from R Markdown:

```r
rmarkdown::render(
  "src/report/report.Rmd",
  output_format = "html_document",
  output_file = "Arman_Feili_FSL2_Final_Report.html",
  output_dir = "src/report"
)
```

## Data

Put the raw WHO CSV files in:

- `data/data_raw/`

The locked modeling table used for model comparison is in:

- `data/data_processed/main_analysis_table_locked.csv`

## Author

Arman Feili  
Matricola: 2101835  
Email: feili.2101835@studenti.uniroma1.it
