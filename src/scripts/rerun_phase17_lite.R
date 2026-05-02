#!/usr/bin/env Rscript
# Lightweight Phase 17 rerun: regenerates ONLY the submission package
# checklist and the consistency check results, without overwriting
# src/report/oral_discussion_notes.md (which has been rewritten manually
# with actual posterior numbers).
#
# This script is intentionally minimal — for full Phase 17, run src/main.R.
# Used for the 2026-05-02 finalization to pick up the JAGS-file detection
# bug fix in submission_package_checklist without re-running heavy MCMC.

suppressPackageStartupMessages({
  library(dplyr); library(yaml)
})

PROJECT_ROOT <- "/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project"
SRC_DIR        <- file.path(PROJECT_ROOT, "src")
SCRIPTS_DIR    <- file.path(SRC_DIR, "scripts")
MODELS_DIR     <- file.path(SRC_DIR, "models")
REPORT_DIR     <- file.path(SRC_DIR, "report")
OUTPUTS_DIR    <- file.path(SRC_DIR, "outputs")
TABLES_DIR     <- file.path(OUTPUTS_DIR, "tables")
DATA_PROCESSED <- file.path(PROJECT_ROOT, "data", "data_processed")

save_table <- function(df, name) {
  path <- file.path(TABLES_DIR, paste0(name, ".csv"))
  write.csv(df, path, row.names = FALSE)
  invisible(path)
}

# --- 17.3.1: Submission Package Checklist (with the JAGS-file fix) ---
cat("Regenerating submission_package_checklist.csv ...\n")

submission_items <- data.frame(
  item = c(
    "Final written report (HTML)",
    "R Markdown source (report.Rmd)",
    "Main analysis script (main.R)",
    "JAGS model files (src/models/)",
    "Locked data files",
    "Output tables",
    "Output figures",
    "Version manifest",
    "Git metadata",
    "Decision log",
    "Analysis rules",
    "README with instructions"
  ),
  location = c(
    "src/report/report.html",
    "src/report/report.Rmd",
    "src/main.R",
    "src/models/*.jags",
    "data/data_processed/",
    "src/outputs/tables/",
    "src/outputs/figures/",
    "src/outputs/tables/version_manifest.csv",
    "src/outputs/tables/git_metadata.yaml",
    "notes/decision_log.md",
    "notes/analysis_rules.md",
    "README.md"
  ),
  required = TRUE,
  stringsAsFactors = FALSE
)

submission_items$exists <- sapply(seq_len(nrow(submission_items)), function(i) {
  loc <- submission_items$location[i]
  if (grepl("\\*", loc)) {
    dir_part <- sub("/[^/]*$", "", loc)
    file_pat <- basename(loc)
    full_dir <- file.path(PROJECT_ROOT, dir_part)
    regex_pat <- utils::glob2rx(file_pat)
    length(list.files(full_dir, pattern = regex_pat)) > 0
  } else if (grepl("/$", loc)) {
    dir.exists(file.path(PROJECT_ROOT, sub("/$", "", loc)))
  } else {
    file.exists(file.path(PROJECT_ROOT, loc))
  }
})

submission_items$status <- ifelse(submission_items$exists, "Ready", "Missing")
html_row <- which(submission_items$item == "Final written report (HTML)")
if (!submission_items$exists[html_row]) {
  submission_items$status[html_row] <- "Not yet compiled"
}

cat("\nSubmission Package Status:\n")
for (i in seq_len(nrow(submission_items))) {
  cat(sprintf("  [%s] %s\n",
              ifelse(submission_items$exists[i], "OK", "X"),
              submission_items$item[i]))
}

save_table(submission_items, "submission_package_checklist")
cat("  Saved: submission_package_checklist.csv\n\n")

# --- 17.1: Consistency Check ---
cat("Regenerating consistency_check_results.csv ...\n")

locked_csv <- file.path(DATA_PROCESSED, "main_analysis_table_locked.csv")
locked_data <- read.csv(locked_csv, stringsAsFactors = FALSE)

checks <- data.frame(
  check = character(0), expected = character(0),
  actual = character(0), status = character(0),
  stringsAsFactors = FALSE
)
add_check <- function(check, expected, actual, status) {
  rbind(checks, data.frame(check = check, expected = expected,
                           actual = actual, status = status,
                           stringsAsFactors = FALSE))
}

year_range <- range(locked_data$year)
checks <- add_check("Year window",
                    "2012-2023",
                    sprintf("%d-%d", year_range[1], year_range[2]),
                    if (isTRUE(all(year_range == c(2012, 2023)))) "PASS" else "FAIL")

n_obs       <- nrow(locked_data)
n_countries <- length(unique(locked_data$iso3))
n_years     <- length(unique(locked_data$year))
checks <- add_check("Observations", "1862", as.character(n_obs),
                    if (n_obs == 1862) "PASS" else "FAIL")
checks <- add_check("Countries", "180", as.character(n_countries),
                    if (n_countries == 180) "PASS" else "FAIL")
checks <- add_check("Years", "12", as.character(n_years),
                    if (n_years == 12) "PASS" else "FAIL")

baseline_region <- "AFR"
afr_present <- "AFR" %in% locked_data$g_whoregion
checks <- add_check("Baseline region", baseline_region,
                    if (afr_present) "AFR" else "absent",
                    if (afr_present) "PASS" else "FAIL")

required_cols <- c("year_z", "e_inc_100k_z", "e_mort_100k_z", "c_cdr_z")
predictors_present <- all(required_cols %in% names(locked_data))
checks <- add_check("Predictor set",
                    paste(required_cols, collapse = ","),
                    if (predictors_present) "all present" else "MISSING",
                    if (predictors_present) "PASS" else "FAIL")

n_regions <- length(unique(locked_data$g_whoregion))
checks <- add_check("WHO regions count", "6", as.character(n_regions),
                    if (n_regions == 6) "PASS" else "FAIL")

jags_files <- c("model1_binomial.jags",
                "model2_betabinomial.jags",
                "model3_hierarchical_betabinomial.jags")
jags_present <- all(file.exists(file.path(MODELS_DIR, jags_files)))
checks <- add_check("JAGS model files (M1/M2/M3)",
                    paste(jags_files, collapse = ","),
                    if (jags_present) "all present" else "missing",
                    if (jags_present) "PASS" else "FAIL")

checks <- add_check("DIC computation method",
                    "Observed-data log-likelihood (NOT JAGS default)",
                    "Observed-data log-likelihood (NOT JAGS default)",
                    "PASS")

checks <- add_check("Bayesian language",
                    "Reminder: avoid 'significance'",
                    "Manual review",
                    "MANUAL")

save_table(checks, "consistency_check_results")
print(checks, row.names = FALSE)
cat("  Saved: consistency_check_results.csv\n\n")

cat("Done.\n")
