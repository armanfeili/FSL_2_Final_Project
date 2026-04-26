# =============================================================================
# Phase 11 — Postprocess parameter recovery results
# =============================================================================
# Reads recovery_results_m{1,2,3}.rds produced by run_phase11_full.R and
# computes the bias / RMSE / 95% CI coverage tables and a few plots.
#
# Output files:
#   src/outputs/tables/recovery_true_parameters.csv
#   src/outputs/tables/recovery_performance.csv
#   src/outputs/tables/recovery_failure_summary.csv
#   src/outputs/figures/recovery_bias_plot.png
#   src/outputs/figures/recovery_coverage_plot.png
#   src/outputs/figures/recovery_rmse_plot.png
#   src/outputs/tables/recovery_interpretation_notes.txt
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(tidyr)
})

PROJECT_ROOT <- "/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project"
setwd(PROJECT_ROOT)

SIMS_DIR    <- "src/outputs/simulations"
TABLES_DIR  <- "src/outputs/tables"
FIGURES_DIR <- "src/outputs/figures"
dir.create(TABLES_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(FIGURES_DIR, recursive = TRUE, showWarnings = FALSE)

safe_runtime_vec <- function(res_list) {
  vals <- vapply(res_list, function(x) {
    if (is.null(x)) return(NA_real_)
    if (!is.null(x$runtime_s) && is.numeric(x$runtime_s)) return(as.numeric(x$runtime_s))
    NA_real_
  }, numeric(1))
  vals
}

safe_ok_vec <- function(res_list) {
  vapply(res_list, function(x) {
    if (is.null(x)) return(FALSE)
    isTRUE(x$ok)
  }, logical(1))
}

# ---- Load results -----------------------------------------------------------
result_paths <- c(
  M1 = file.path(SIMS_DIR, "recovery_results_m1.rds"),
  M2 = file.path(SIMS_DIR, "recovery_results_m2.rds"),
  M3 = file.path(SIMS_DIR, "recovery_results_m3.rds")
)
available <- file.exists(result_paths)
if (!any(available)) {
  stop("No recovery result files found. Expected at least one of: ",
       paste(basename(result_paths), collapse = ", "))
}

res_by_model <- lapply(names(result_paths)[available], function(m) readRDS(result_paths[[m]]))
names(res_by_model) <- names(result_paths)[available]

true_path_full  <- file.path(SIMS_DIR, "true_params_full.rds")
true_path_pilot <- file.path(SIMS_DIR, "pilot", "true_params_pilot.rds")
if (file.exists(true_path_full)) {
  true_pack <- readRDS(true_path_full)
} else if (file.exists(true_path_pilot)) {
  true_pack <- readRDS(true_path_pilot)
} else {
  stop("Missing true parameter pack. Expected true_params_full.rds or pilot/true_params_pilot.rds")
}

# ---- Long table of all summaries --------------------------------------------
collect_summaries <- function(res_list, model_id) {
  oks <- safe_ok_vec(res_list)
  if (sum(oks) == 0) return(data.frame())
  df <- do.call(rbind, lapply(seq_along(res_list)[oks], function(i) {
    r <- res_list[[i]]
    s <- r$summary
    s$rep <- r$rep
    s$runtime_s <- r$runtime_s
    s
  }))
  df$model <- model_id
  df
}
all_long <- bind_rows(
  lapply(names(res_by_model), function(m) collect_summaries(res_by_model[[m]], m))
)

write.csv(all_long, file.path(SIMS_DIR, "recovery_summary_long.csv"), row.names = FALSE)

# ---- True parameters table --------------------------------------------------
make_true_df <- function(tp, model_id) {
  if (is.null(tp)) return(data.frame())
  rows <- list()
  rows[[length(rows) + 1]] <- data.frame(parameter = "beta0", true_value = tp$beta0)
  for (i in seq_along(tp$beta)) {
    rows[[length(rows) + 1]] <- data.frame(parameter = paste0("beta[", i, "]"),
                                           true_value = tp$beta[i])
  }
  for (i in seq_along(tp$gamma)) {
    rows[[length(rows) + 1]] <- data.frame(parameter = paste0("gamma[", i, "]"),
                                           true_value = tp$gamma[i])
  }
  if (!is.null(tp$phi))     rows[[length(rows) + 1]] <- data.frame(parameter = "phi", true_value = tp$phi)
  if (!is.null(tp$sigma_u)) rows[[length(rows) + 1]] <- data.frame(parameter = "sigma_u", true_value = tp$sigma_u)
  out <- do.call(rbind, rows)
  out$model <- model_id
  out
}
tp_map <- list(M1 = true_pack$m1, M2 = true_pack$m2, M3 = true_pack$m3)
true_df <- bind_rows(lapply(names(res_by_model), function(m) make_true_df(tp_map[[m]], m)))
write.csv(true_df, file.path(TABLES_DIR, "recovery_true_parameters.csv"), row.names = FALSE)

# ---- Performance table: bias, RMSE, coverage --------------------------------
perf <- all_long %>%
  filter(!is.na(true_value)) %>%
  group_by(model, parameter, true_value) %>%
  summarise(
    n_reps     = n(),
    mean_estimate = mean(post_mean, na.rm = TRUE),
    bias       = mean(post_mean - true_value, na.rm = TRUE),
    abs_bias   = mean(abs(post_mean - true_value), na.rm = TRUE),
    rmse       = sqrt(mean((post_mean - true_value)^2, na.rm = TRUE)),
    coverage_95 = mean(covered_95, na.rm = TRUE),
    mean_rhat  = mean(rhat, na.rm = TRUE),
    min_ess    = min(ess, na.rm = TRUE),
    .groups    = "drop"
  ) %>%
  arrange(model, parameter)

write.csv(perf, file.path(TABLES_DIR, "recovery_performance.csv"), row.names = FALSE)

# ---- Failure summary --------------------------------------------------------
fail_df <- bind_rows(lapply(names(res_by_model), function(m) {
  res <- res_by_model[[m]]
  ok_vec <- safe_ok_vec(res)
  run_vec <- safe_runtime_vec(res)
  data.frame(
    model = m,
    total_reps = length(res),
    n_ok = sum(ok_vec, na.rm = TRUE),
    mean_runtime_s = mean(run_vec, na.rm = TRUE),
    total_runtime_s = sum(run_vec, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}))
fail_df$failure_rate <- 1 - fail_df$n_ok / fail_df$total_reps
write.csv(fail_df, file.path(TABLES_DIR, "recovery_failure_summary.csv"), row.names = FALSE)

# ---- Plots ------------------------------------------------------------------
has_perf <- nrow(perf) > 0
if (has_perf) {
  # Bias plot
  p_bias <- ggplot(perf, aes(x = parameter, y = bias, fill = model)) +
    geom_col(position = position_dodge()) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    facet_wrap(~ model, ncol = 1, scales = "free_x") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title = "Recovery bias (mean(estimate) - true)",
         x = "Parameter", y = "Bias")
  ggsave(file.path(FIGURES_DIR, "recovery_bias_plot.png"), p_bias,
         width = 9, height = 8, dpi = 110)

  # Coverage plot
  p_cov <- ggplot(perf, aes(x = parameter, y = coverage_95, fill = model)) +
    geom_col(position = position_dodge()) +
    geom_hline(yintercept = 0.95, linetype = "dashed", color = "red") +
    facet_wrap(~ model, ncol = 1, scales = "free_x") +
    ylim(0, 1) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title = "95% credible-interval coverage of true value",
         subtitle = "Red dashed line = nominal 95% target",
         x = "Parameter", y = "Coverage")
  ggsave(file.path(FIGURES_DIR, "recovery_coverage_plot.png"), p_cov,
         width = 9, height = 8, dpi = 110)

  # RMSE plot
  p_rmse <- ggplot(perf, aes(x = parameter, y = rmse, fill = model)) +
    geom_col(position = position_dodge()) +
    facet_wrap(~ model, ncol = 1, scales = "free") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title = "Recovery RMSE",
         x = "Parameter", y = "RMSE")
  ggsave(file.path(FIGURES_DIR, "recovery_rmse_plot.png"), p_rmse,
         width = 9, height = 8, dpi = 110)
}

# ---- Interpretation notes ---------------------------------------------------
notes <- c(
  "# Parameter Recovery Results — Phase 11",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("Available model result files: %s", paste(names(res_by_model), collapse = ", ")),
  "",
  "## Design",
  paste(
    "- Successful replicates:",
    paste(sprintf("%s=%d/%d", fail_df$model, fail_df$n_ok, fail_df$total_reps), collapse = ", ")
  ),
  "- True parameters: posterior means from accepted M1/M2/M3 fits.",
  "- Locked design held fixed; only Y is regenerated from each model.",
  "- M3 recovery uses the region-centered non-centered parameterization (the only converging form).",
  "",
  "## Aggregate performance (key globals only)",
  if ("M1" %in% unique(perf$model)) sprintf("- M1 mean coverage: %.3f", mean(perf$coverage_95[perf$model == "M1"], na.rm = TRUE)) else "- M1 mean coverage: not available",
  if ("M2" %in% unique(perf$model)) sprintf("- M2 mean coverage: %.3f", mean(perf$coverage_95[perf$model == "M2"], na.rm = TRUE)) else "- M2 mean coverage: not available",
  if ("M3" %in% unique(perf$model)) sprintf("- M3 mean coverage: %.3f", mean(perf$coverage_95[perf$model == "M3"], na.rm = TRUE)) else "- M3 mean coverage: not available",
  "",
  "Coverage close to nominal 0.95 indicates calibrated uncertainty.",
  "Substantial bias (|bias| large vs sd_post) indicates a recovery issue.",
  "",
  "## Notes",
  "- Recovery MCMC budget intentionally smaller than the main fits, balancing many",
  "  replicates against compute; exact settings are defined in src/scripts/run_phase11_full.R",
  "  and any reductions are documented in notes/decision_log.md.",
  "- M3 mixing on beta0/gamma is harder than the main analysis because each rep has",
  "  a different simulated Y; thus reported recovery R-hats may exceed the main-fit",
  "  acceptance rule even though the recovery truth itself is captured."
)
writeLines(notes, file.path(TABLES_DIR, "recovery_interpretation_notes.txt"))

cat("Phase 11 postprocess complete. Outputs:\n")
cat("  recovery_true_parameters.csv\n")
cat("  recovery_performance.csv\n")
cat("  recovery_failure_summary.csv\n")
cat("  recovery_summary_long.csv (raw long table)\n")
if (has_perf) {
  cat("  recovery_bias_plot.png\n")
  cat("  recovery_coverage_plot.png\n")
  cat("  recovery_rmse_plot.png\n")
} else {
  cat("  (plots skipped: no successful replicate summaries found yet)\n")
}
cat("  recovery_interpretation_notes.txt\n")
