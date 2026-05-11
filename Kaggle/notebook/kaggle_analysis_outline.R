# =============================================================================
# Processed WHO TB Treatment Success — public Kaggle analysis outline
# =============================================================================
# Public summary script for the Kaggle dataset
#   "Processed WHO TB Treatment Success Dataset, 2012-2023".
#
# This script intentionally does NOT rerun the full Markov chain Monte Carlo
# (MCMC) workflow. The published M1 (pooled binomial), M2 (beta-binomial),
# and M3 (hierarchical beta-binomial with country and region effects) fits
# were run in the original project environment using R + JAGS, which is
# computationally expensive and not always practical to set up on Kaggle.
# Here we only:
#   - load the locked CSV,
#   - print sample summary statistics,
#   - draw three standard EDA plots,
#   - read and print small published result tables if they are bundled.
# =============================================================================

# --- Packages ----------------------------------------------------------------
library(readr)
library(dplyr)
library(ggplot2)

# --- Locate the dataset ------------------------------------------------------
# Try Kaggle-style mounted paths first, then local fallbacks. As a final
# resort, recursively search common dataset roots for the main CSV by name.
csv_basename <- "processed_who_tb_treatment_success_country_year_2012_2023.csv"
candidate_paths <- c(
  file.path("/kaggle/input/processed-who-tb-treatment-success-2012-2023", csv_basename),
  file.path("../input/processed-who-tb-treatment-success-2012-2023", csv_basename),
  file.path("../dataset", csv_basename),
  csv_basename
)

main_csv <- NULL
for (p in candidate_paths) {
  if (file.exists(p)) {
    main_csv <- p
    break
  }
}

# Last-resort search: scan all attached Kaggle dataset roots and any
# parent-input folder for the CSV by exact filename.
if (is.null(main_csv)) {
  search_roots <- c("/kaggle/input", "../input", "../dataset", ".")
  search_roots <- search_roots[dir.exists(search_roots)]
  for (root in search_roots) {
    hits <- list.files(root, pattern = paste0("^", csv_basename, "$"),
                       recursive = TRUE, full.names = TRUE)
    if (length(hits) > 0) {
      main_csv <- hits[[1]]
      break
    }
  }
}

if (is.null(main_csv)) {
  cat("Listing /kaggle/input for diagnostics:\n")
  if (dir.exists("/kaggle/input")) print(list.files("/kaggle/input", recursive = TRUE))
  stop(
    "Could not find ", csv_basename, ". Tried: ",
    paste(candidate_paths, collapse = ", ")
  )
}

# Bayesian result tables (DIC / PPC / M3 posterior) ship inside
# `bayesian_result_tables.zip`. Kaggle auto-extracts ZIPs in datasets so
# the files usually appear in a sibling folder named
# `bayesian_result_tables/`. Locally the ZIP itself may be present and we
# unzip it on the fly. If neither is available we continue with EDA only.
results_dir <- NULL

# 1) Already-extracted folder (Kaggle path or local sibling folder).
folder_candidates <- c(
  file.path(dirname(main_csv), "bayesian_result_tables"),
  "/kaggle/input/processed-who-tb-treatment-success-2012-2023/bayesian_result_tables"
)
folder_candidates <- folder_candidates[dir.exists(folder_candidates)]
if (length(folder_candidates) == 0) {
  hits <- c()
  for (root in c("/kaggle/input", "../input", ".")) {
    if (dir.exists(root)) {
      hits <- c(hits, list.dirs(root, recursive = TRUE, full.names = TRUE))
    }
  }
  hits <- hits[basename(hits) == "bayesian_result_tables"]
  folder_candidates <- hits
}
if (length(folder_candidates) > 0) {
  results_dir <- folder_candidates[[1]]
  cat("Using extracted result tables at:", results_dir, "\n")
}

# 2) Fall back to the ZIP file and unpack it into tempdir.
if (is.null(results_dir)) {
  zip_candidates <- c(
    file.path(dirname(main_csv), "bayesian_result_tables.zip"),
    "/kaggle/input/processed-who-tb-treatment-success-2012-2023/bayesian_result_tables.zip"
  )
  zip_candidates <- zip_candidates[file.exists(zip_candidates)]
  if (length(zip_candidates) == 0) {
    hits <- c()
    for (root in c("/kaggle/input", "../input", ".")) {
      if (dir.exists(root)) {
        hits <- c(hits, list.files(root, pattern = "^bayesian_result_tables\\.zip$",
                                   recursive = TRUE, full.names = TRUE))
      }
    }
    zip_candidates <- hits
  }
  if (length(zip_candidates) > 0) {
    results_zip <- zip_candidates[[1]]
    results_dir <- file.path(tempdir(), "bayesian_result_tables_unpacked")
    dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
    utils::unzip(results_zip, exdir = results_dir)
    cat("Unpacked", results_zip, "to", results_dir, "\n")
  } else {
    cat("[note] bayesian_result_tables.zip / folder not found; skipping result tables.\n")
  }
}

cat("Loading dataset from:", main_csv, "\n")
df <- readr::read_csv(main_csv, show_col_types = FALSE)

# --- Sample summary ----------------------------------------------------------
cat("\n=== Sample summary ===\n")
cat("Rows:           ", nrow(df), "\n")
cat("Columns:        ", ncol(df), "\n")
cat("Year range:     ", paste(range(df$year), collapse = " - "), "\n")
cat("Countries:      ", dplyr::n_distinct(df$iso3), "\n")
cat("WHO regions:    ", dplyr::n_distinct(df$g_whoregion), "\n")

df <- df %>% dplyr::mutate(prop = success / cohort)

cat("\n--- Summary of prop_success (success / cohort) ---\n")
print(summary(df$prop))

# --- EDA plots ---------------------------------------------------------------

# 1) Distribution of prop_success
p1 <- ggplot(df, aes(x = prop)) +
  geom_histogram(bins = 40) +
  labs(
    title = "Distribution of treatment success rate (success / cohort)",
    x = "Success rate",
    y = "Country-years"
  ) +
  theme_minimal()
print(p1)

# 2) Boxplot of prop_success by WHO region
p2 <- ggplot(df, aes(x = g_whoregion, y = prop)) +
  geom_boxplot() +
  labs(
    title = "Treatment success rate by WHO region",
    x = "WHO region",
    y = "Success rate"
  ) +
  theme_minimal()
print(p2)

# 3) Yearly median + IQR trend of prop_success
year_trend <- df %>%
  dplyr::group_by(year) %>%
  dplyr::summarise(
    median_prop = median(prop),
    q25 = quantile(prop, 0.25),
    q75 = quantile(prop, 0.75),
    .groups = "drop"
  )

p3 <- ggplot(year_trend, aes(x = year, y = median_prop)) +
  geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.2) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = seq(2012, 2023, 1)) +
  labs(
    title = "Median success rate per year (IQR shaded)",
    x = "Year",
    y = "Success rate"
  ) +
  theme_minimal()
print(p3)

# --- Published result tables (read-only) -------------------------------------
# These small tables ship inside `bayesian_result_tables.zip` so the dataset
# preview stays focused on the main CSV. The block above already unpacked
# the ZIP (if present) into `results_dir`. If the ZIP was missing we just
# skip the prints and keep the EDA output.
read_if_present <- function(label, path) {
  if (!is.null(path) && file.exists(path)) {
    cat("\n=== ", label, " (", path, ") ===\n", sep = "")
    tbl <- readr::read_csv(path, show_col_types = FALSE)
    print(tbl)
  } else {
    cat("\n[skip] ", label, " not available (path: ",
        if (is.null(path)) "<no zip>" else path, ")\n", sep = "")
  }
}

results_path <- function(name) {
  if (is.null(results_dir)) return(NULL)
  # Look for the file directly in results_dir (flat layout, current zip)
  # or one level deeper (legacy zip with container folder).
  flat <- file.path(results_dir, name)
  nested <- file.path(results_dir, "bayesian_result_tables", name)
  if (file.exists(flat)) flat
  else if (file.exists(nested)) nested
  else flat
}

read_if_present(
  "DIC model comparison",
  results_path("dic_comparison_table.csv")
)
read_if_present(
  "Posterior predictive check (PPC) summary",
  results_path("ppc_summary_table.csv")
)
read_if_present(
  "Posterior summary for hierarchical model M3",
  results_path("posterior_summary_m3.csv")
)

# --- Notes -------------------------------------------------------------------
# Full MCMC is not rerun in this Kaggle summary script. The three published
# models (M1 pooled binomial, M2 beta-binomial, M3 hierarchical beta-binomial
# with country and region effects) were fit using R + JAGS in the original
# project environment, which is computationally heavy and out of scope for a
# lightweight public notebook. The locked CSV plus the bundled result
# tables are enough to refit any of the three models locally if desired.
#
# This script is a public, portfolio-style summary; it does NOT contain any
# private or institution-specific information.
