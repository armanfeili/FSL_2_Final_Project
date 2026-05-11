# Bayesian Modeling of WHO TB Treatment Success, 2012-2023
# Public Kaggle script. The full JAGS MCMC fitting was performed in the
# original project environment. This script does not refit the models;
# it uses the compact result tables shipped in the Kaggle dataset to
# reproduce the public model-comparison and interpretation layer.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(forcats)
  library(scales)
  library(knitr)
})

# ---- Helpers ----------------------------------------------------------------

find_file_by_name <- function(rel_or_name) {
  bn <- basename(rel_or_name)
  search_roots <- c(
    "/kaggle/input/datasets/armanfeili7/processed-who-tb-treatment-success-2012-2023",
    "/kaggle/input/processed-who-tb-treatment-success-2012-2023",
    "/kaggle/input",
    "../dataset",
    "../../Kaggle/dataset",
    "Kaggle/dataset",
    "."
  )
  for (root in search_roots) {
    if (dir.exists(root)) {
      cand <- file.path(root, rel_or_name)
      if (file.exists(cand)) return(cand)
    }
  }
  for (root in search_roots) {
    if (dir.exists(root)) {
      hits <- list.files(root, pattern = paste0("^", bn, "$"),
                         recursive = TRUE, full.names = TRUE)
      if (length(hits)) return(hits[[1]])
    }
  }
  NULL
}

read_csv_safe <- function(rel_or_name) {
  p <- find_file_by_name(rel_or_name)
  if (is.null(p)) {
    cat(sprintf("Skipped: %s (not found)\n", basename(rel_or_name)))
    return(NULL)
  }
  cat(sprintf("Loaded: %s\n", basename(rel_or_name)))
  readr::read_csv(p, show_col_types = FALSE)
}

show_table <- function(df, caption = NULL, digits = 3) {
  if (is.null(df)) return(invisible(NULL))
  print(knitr::kable(df, caption = caption, digits = digits))
  invisible(df)
}

base_theme <- function() {
  theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(color = "grey30"))
}

model_palette <- c(M1 = "#C44E52", M2 = "#DD8452", M3 = "#55A868")

# ---- Load main analysis table ----------------------------------------------

cat("\n# Dataset overview\n\n")

df <- read_csv_safe("processed_who_tb_treatment_success_country_year_2012_2023.csv")
if (is.null(df)) {
  stop("Main analysis CSV not found. The Kaggle dataset must be attached.")
}

stopifnot(
  nrow(df) == 1862L, ncol(df) == 17L,
  length(unique(df$iso3)) == 180L,
  min(df$year) == 2012L, max(df$year) == 2023L,
  all(df$success <= df$cohort),
  all(df$cohort >= 50),
  all(abs(df$prop_success - df$success / df$cohort) < 1e-9)
)
cat("Quality checks passed: 1,862 rows / 17 cols / 180 countries / 2012-2023.\n\n")

overall_cw_success <- sum(df$success) / sum(df$cohort)
overview_tbl <- tibble::tibble(
  Statistic = c(
    "Rows (country-years)", "Columns", "Distinct countries (iso3)",
    "Year range", "WHO regions",
    "Total successes", "Total cohort", "Cohort-weighted success rate"
  ),
  Value = c(
    format(nrow(df), big.mark = ","),
    as.character(ncol(df)),
    as.character(length(unique(df$iso3))),
    paste(min(df$year), max(df$year), sep = "-"),
    paste(sort(unique(df$g_whoregion)), collapse = ", "),
    format(sum(df$success), big.mark = ","),
    format(sum(df$cohort), big.mark = ","),
    sprintf("%.2f%%", 100 * overall_cw_success)
  )
)
show_table(overview_tbl, "Dataset overview")

# ---- Provenance, attrition, final sample ------------------------------------

cat("\n# Provenance and filtering\n\n")

prov <- read_csv_safe("documentation_tables/data_provenance.csv")
show_table(prov, "Raw WHO inputs used to build the processed analysis table")

attrition <- read_csv_safe("documentation_tables/attrition_table.csv")
show_table(attrition, "Sample attrition pipeline (raw -> locked)")

snapshot <- read_csv_safe("documentation_tables/final_sample_snapshot.csv")
show_table(snapshot, "Final sample snapshot")

if (!is.null(attrition)) {
  attr_plot <- attrition %>%
    mutate(filter = fct_inorder(filter)) %>%
    ggplot(aes(x = fct_rev(filter), y = rows)) +
    geom_col(fill = "#4C72B0") +
    geom_text(aes(label = comma(rows)), hjust = -0.05, size = 3.4) +
    coord_flip() +
    scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
    labs(title = "Sample attrition",
         subtitle = "Each row shows how many country-years remain after one filter",
         x = NULL, y = "Country-years remaining") +
    base_theme()
  print(attr_plot)
}

# ---- Variable dictionary and standardization -------------------------------

cat("\n# Variables and modeling roles\n\n")

vd <- read_csv_safe("documentation_tables/project_variable_dictionary.csv")
show_table(vd, "Variable dictionary: roles and primary-vs-sensitivity usage")

stdmeta <- read_csv_safe("documentation_tables/standardization_metadata.csv")
show_table(stdmeta, "Standardization metadata used to build the _z predictors")

# ---- Exploratory data analysis ---------------------------------------------

cat("\n# Exploratory data analysis\n\n")

print(
  ggplot(df, aes(x = prop_success)) +
    geom_histogram(bins = 40, fill = "#4C72B0", color = "white") +
    scale_x_continuous(labels = percent_format(accuracy = 1)) +
    labs(title = "Distribution of treatment success rate",
         subtitle = "success / cohort, locked analysis sample (n = 1,862)",
         x = "Success rate", y = "Country-years") +
    base_theme()
)

print(
  ggplot(df, aes(x = cohort)) +
    geom_histogram(bins = 50, fill = "#55A868", color = "white") +
    scale_x_log10(labels = comma) +
    labs(title = "Cohort size distribution (log10 x-axis)",
         x = "Cohort size", y = "Country-years") +
    base_theme()
)

print(
  ggplot(df, aes(x = g_whoregion, y = prop_success, fill = g_whoregion)) +
    geom_boxplot(alpha = 0.85, outlier.alpha = 0.4) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    scale_fill_brewer(palette = "Set2", guide = "none") +
    labs(title = "Success rate by WHO region",
         x = "WHO region (AFR = reference)", y = "Success rate") +
    base_theme()
)

yearly <- df %>%
  group_by(year) %>%
  summarise(median_prop = median(prop_success),
            q25 = quantile(prop_success, 0.25),
            q75 = quantile(prop_success, 0.75),
            cohort_weighted = sum(success) / sum(cohort),
            .groups = "drop")

print(
  ggplot(yearly, aes(x = year)) +
    geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.2, fill = "#4C72B0") +
    geom_line(aes(y = median_prop), color = "#4C72B0", linewidth = 1) +
    geom_point(aes(y = median_prop), color = "#4C72B0", size = 2) +
    geom_line(aes(y = cohort_weighted), color = "#C44E52",
              linewidth = 1, linetype = "dashed") +
    scale_x_continuous(breaks = seq(2012, 2023)) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    labs(title = "Yearly success rate: country-year median (blue) vs cohort-weighted global (red dashed)",
         subtitle = "Shaded band: 25th-75th percentile of country-year rates",
         x = "Year", y = "Success rate") +
    base_theme()
)

trend_region <- df %>%
  group_by(g_whoregion, year) %>%
  summarise(mean_prop = sum(success) / sum(cohort), .groups = "drop")

print(
  ggplot(trend_region, aes(x = year, y = mean_prop, color = g_whoregion)) +
    geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
    scale_color_brewer(palette = "Set2", name = "WHO region") +
    scale_x_continuous(breaks = seq(2012, 2023)) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    labs(title = "Temporal trend by WHO region",
         subtitle = "Cohort-weighted regional success rate per year",
         x = "Year", y = "Success rate") +
    base_theme()
)

print(
  ggplot(trend_region, aes(x = year, y = g_whoregion, fill = mean_prop)) +
    geom_tile(color = "white") +
    scale_fill_gradient(low = "#FDDBC7", high = "#1A9850",
                        labels = percent_format(accuracy = 1),
                        name = "Success rate") +
    scale_x_continuous(breaks = seq(2012, 2023)) +
    labs(title = "Region-year mean success rate",
         x = "Year", y = "WHO region") +
    base_theme()
)

country_summary <- df %>%
  group_by(iso3, g_whoregion) %>%
  summarise(mean_prop = sum(success) / sum(cohort), .groups = "drop")

top_bot <- bind_rows(
  country_summary %>% slice_max(mean_prop, n = 15) %>%
    mutate(panel = "Top 15 (highest mean success)"),
  country_summary %>% slice_min(mean_prop, n = 15) %>%
    mutate(panel = "Bottom 15 (lowest mean success)")
)

print(
  ggplot(top_bot, aes(x = mean_prop, y = fct_reorder(iso3, mean_prop),
                     fill = g_whoregion)) +
    geom_col(alpha = 0.9) +
    facet_wrap(~ panel, scales = "free_y") +
    scale_x_continuous(labels = percent_format(accuracy = 1)) +
    scale_fill_brewer(palette = "Set2", name = "WHO region") +
    labs(title = "Top and bottom 15 countries by mean success rate (2012-2023)",
         x = "Mean success rate", y = NULL) +
    base_theme() +
    theme(legend.position = "bottom")
)

pretty_pred <- c(e_inc_100k = "Incidence per 100k",
                 e_mort_100k = "Mortality per 100k",
                 c_cdr = "Case detection ratio")
bivariate_long <- df %>%
  select(prop_success, g_whoregion, year, e_inc_100k, e_mort_100k, c_cdr) %>%
  pivot_longer(c(e_inc_100k, e_mort_100k, c_cdr),
               names_to = "predictor", values_to = "value") %>%
  mutate(predictor = factor(pretty_pred[predictor], levels = pretty_pred))

print(
  ggplot(bivariate_long, aes(x = value, y = prop_success)) +
    geom_point(aes(color = g_whoregion), alpha = 0.45, size = 1.1) +
    geom_smooth(method = "loess", se = FALSE, color = "black", linewidth = 0.7) +
    facet_wrap(~ predictor, scales = "free_x", nrow = 1) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    scale_color_brewer(palette = "Set2", name = "WHO region") +
    labs(title = "Burden predictors vs treatment success",
         subtitle = "Each point is one country-year; black line is a loess trend",
         x = NULL, y = "Success rate") +
    base_theme() +
    theme(legend.position = "bottom")
)

print(
  ggplot(df, aes(x = year, y = prop_success)) +
    geom_jitter(aes(color = g_whoregion), width = 0.2, alpha = 0.35, size = 1) +
    geom_smooth(method = "loess", se = FALSE, color = "black", linewidth = 0.7) +
    scale_x_continuous(breaks = seq(2012, 2023)) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    scale_color_brewer(palette = "Set2", name = "WHO region") +
    labs(title = "Treatment success across years",
         subtitle = "Country-year points with overall loess trend",
         x = "Year", y = "Success rate") +
    base_theme() +
    theme(legend.position = "bottom")
)

corr_vars <- intersect(
  c("year", "e_inc_100k", "e_mort_100k", "c_cdr", "e_tbhiv_prct"),
  names(df)
)
corr_long <- as.data.frame(as.table(
  cor(df[corr_vars], use = "pairwise.complete.obs")
)) %>%
  rename(var1 = Var1, var2 = Var2, r = Freq)

print(
  ggplot(corr_long, aes(x = var1, y = var2, fill = r)) +
    geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", r)), size = 3.2) +
    scale_fill_gradient2(low = "#C44E52", mid = "white", high = "#4C72B0",
                         midpoint = 0, limits = c(-1, 1), name = "Pearson r") +
    labs(title = "Predictor correlation matrix",
         x = NULL, y = NULL) +
    base_theme() +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
)

miss_tbl <- df %>%
  summarise(across(everything(), ~ sum(is.na(.)) / n())) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_frac") %>%
  arrange(desc(missing_frac))
show_table(miss_tbl, "Missing-value fraction per column", digits = 4)

# ---- Model ladder narrative ------------------------------------------------

cat("\n# Bayesian model ladder\n\n")
cat("M1: Binomial logistic regression. Tests whether ordinary binomial sampling variance is sufficient.\n")
cat("M2: Beta-binomial model. Adds an overdispersion parameter (phi).\n")
cat("M3: Hierarchical beta-binomial. Adds country random effects (sigma_u) on top of M2.\n\n")

# ---- DIC -------------------------------------------------------------------

cat("\n# Model comparison (DIC)\n\n")

dic <- read_csv_safe("bayesian_result_tables/dic_comparison_table.csv")
show_table(dic, "DIC model comparison (lower is better)")

if (!is.null(dic)) {
  dic_plot_data <- dic %>% mutate(Model = factor(Model, levels = c("M1", "M2", "M3")))

  print(
    ggplot(dic_plot_data, aes(x = Model, y = DIC, fill = Model)) +
      geom_col(width = 0.6, alpha = 0.9) +
      geom_text(aes(label = comma(round(DIC))), vjust = -0.4, size = 3.6) +
      scale_y_continuous(labels = comma, trans = "log10",
                         expand = expansion(mult = c(0, 0.15))) +
      scale_fill_manual(values = model_palette, guide = "none") +
      labs(title = "DIC across models (log10 scale)",
           subtitle = "M1 is severely inadequate; M3 has the lowest DIC",
           x = NULL, y = "DIC") +
      base_theme()
  )

  print(
    ggplot(dic_plot_data, aes(x = Model, y = Delta_DIC, fill = Model)) +
      geom_col(width = 0.6, alpha = 0.9) +
      geom_text(aes(label = comma(round(Delta_DIC))), vjust = -0.4, size = 3.6) +
      scale_fill_manual(values = model_palette, guide = "none") +
      scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
      labs(title = "Delta DIC relative to the preferred model (M3)",
           x = NULL, y = "Delta DIC") +
      base_theme()
  )
}

# ---- M3 posterior summary --------------------------------------------------

cat("\n# M3 posterior summary\n\n")

posterior_m3 <- read_csv_safe("bayesian_result_tables/posterior_summary_m3.csv")
show_table(posterior_m3, "M3 posterior summary (mean, sd, 95% credible interval)")

if (!is.null(posterior_m3) &&
    all(c("mean", "ci_lower", "ci_upper", "label") %in% names(posterior_m3))) {
  print(
    posterior_m3 %>%
      mutate(label = fct_reorder(label, mean)) %>%
      ggplot(aes(x = mean, y = label)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
      geom_segment(aes(x = ci_lower, xend = ci_upper, y = label, yend = label),
                   color = "#4C72B0", linewidth = 0.8) +
      geom_point(color = "#4C72B0", size = 2.4) +
      labs(title = "M3 posterior means with 95% credible intervals",
           subtitle = "Hierarchical beta-binomial model (logit scale)",
           x = "Posterior mean (CrI = 95% credible interval)", y = NULL) +
      base_theme()
  )
}

# ---- PPC -------------------------------------------------------------------

cat("\n# Posterior predictive checks\n\n")

ppc <- read_csv_safe("bayesian_result_tables/ppc_summary_table.csv")
show_table(ppc, "Posterior predictive checks per model and test statistic")

if (!is.null(ppc) && all(c("model", "test_quantity", "p_value") %in% names(ppc))) {
  print(
    ggplot(ppc, aes(x = p_value, y = fct_rev(test_quantity), color = model)) +
      geom_vline(xintercept = 0.5, color = "grey50", linetype = "dashed") +
      geom_vline(xintercept = c(0.05, 0.95), color = "grey70", linetype = "dotted") +
      geom_point(size = 3, alpha = 0.85) +
      scale_x_continuous(limits = c(0, 1), breaks = c(0, 0.05, 0.5, 0.95, 1)) +
      scale_color_manual(values = model_palette, name = "Model") +
      labs(title = "Posterior predictive Bayesian p-values",
           subtitle = "Values near 0.5 = well calibrated; values near 0 or 1 = systematic mismatch",
           x = "Bayesian p-value", y = "Test quantity") +
      base_theme() +
      theme(legend.position = "bottom")
  )

  if (all(c("observed", "rep_mean") %in% names(ppc))) {
    print(
      ggplot(ppc, aes(x = observed, y = rep_mean, color = model)) +
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
        geom_point(size = 2.5, alpha = 0.85) +
        scale_color_manual(values = model_palette, name = "Model") +
        labs(title = "Observed vs posterior predictive mean per PPC statistic",
             x = "Observed", y = "Posterior predictive mean") +
        base_theme() +
        theme(legend.position = "bottom")
    )
  }
}

# ---- Conclusion ------------------------------------------------------------

cat("\n# Conclusion\n\n")
cat("TB treatment success varies by country, region, and burden context.\n")
cat("Ordinary binomial sampling variance alone is insufficient (M1 DIC ~ 2.7e6 vs M3 DIC ~ 24,940).\n")
cat("M2 closes most of the gap by allowing overdispersion; M3 closes the remainder by adding\n")
cat("persistent country-level heterogeneity through random effects, and is the preferred model.\n")
cat("M3 captures both overdispersion (phi ~ 42.9) and country heterogeneity (sigma_u ~ 0.72),\n")
cat("with the lowest DIC and the best posterior predictive calibration among the three models.\n\n")

cat("# Limitations\n\n")
cat("- Observational country-level data; findings are associative, not causal.\n")
cat("- National reporting practices differ; data quality is heterogeneous.\n")
cat("- WHO burden indicators are estimates, not direct measurements.\n")
cat("- Raw WHO files are not redistributed in this Kaggle dataset.\n")
cat("- The full JAGS MCMC is not rerun here; only the compact result tables are used.\n")
cat("- Per-country random effects and full posterior draws are not included in this compact dataset.\n\n")

cat("# Reuse and citation\n\n")
cat("Please cite the World Health Organization Global Tuberculosis Programme as the original\n")
cat("data source, together with this processed Kaggle derivative dataset. This is not an\n")
cat("official WHO dataset and should not be treated as an authoritative WHO publication.\n")
