# =============================================================================
# Phase 14 — Bayesian prior sensitivity arms (14.3 phi, 14.4 sigma_u)
# =============================================================================
# Why this script exists:
#   src/main.R Phase 14 only writes the alt JAGS files; it never actually fits
#   them (see comment "TODO: Full MCMC fitting with alternative phi prior").
#   This helper performs the missing fits and writes the comparison tables.
#
# Decisions:
#   14.3 phi:     phi ~ Gamma(1, 0.1) (alt-1, mean=10) vs main Gamma(2,0.1) mean=20.
#                 Fit with 4 chains × 1000 adapt × 2000 burn × 4000 iter.
#   14.4 sigma_u: sigma_u ~ HN(0, 2.5) vs main HN(0, 1).
#                 Uses the region-centered non-centered parameterization that
#                 was the only converging M3 form. Fit with parallel chains.
#                 Reduced budget (4 ch × 500 adapt × 4000 burn × 6000 iter)
#                 vs main M3 fit (4 ch × 1000 adapt × 8000 burn × 10000 iter)
#                 — justified in notes/decision_log.md as "sensitivity-fit
#                 budget; main M3 fit unchanged".
# =============================================================================

suppressPackageStartupMessages({
  library(rjags)
  library(coda)
  library(parallel)
})

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

PROJECT_ROOT <- "/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project"
setwd(PROJECT_ROOT)

MODELS_DIR    <- "src/models"
MODEL_OBJ_DIR <- "src/outputs/model_objects"
TABLES_DIR    <- "src/outputs/tables"
DIAG_DIR      <- "src/outputs/diagnostics"
dir.create(TABLES_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(DIAG_DIR,   recursive = TRUE, showWarnings = FALSE)

SEED_SENS_PHI   <- 2026L * 14L + 3L
SEED_SENS_SIGMA <- 2026L * 14L + 4L

# ---- Load JAGS data ---------------------------------------------------------
log_step("loading JAGS data lists")
jd_base <- readRDS(file.path(MODEL_OBJ_DIR, "jags_data_base.rds"))
jd_rc   <- readRDS(file.path(MODEL_OBJ_DIR, "jags_data_hier_regioncentered.rds"))

# ---- Helper: summarize key params -------------------------------------------
summarize_params <- function(samples, params) {
  mat_list <- lapply(samples, as.matrix)
  full <- do.call(rbind, mat_list)
  out <- data.frame(parameter = params, mean = NA_real_, sd = NA_real_,
                    ci_lower = NA_real_, ci_upper = NA_real_,
                    rhat = NA_real_, ess = NA_real_,
                    stringsAsFactors = FALSE)
  for (i in seq_along(params)) {
    p <- params[i]
    if (!(p %in% colnames(full))) next
    v <- full[, p]
    out$mean[i] <- mean(v)
    out$sd[i]   <- sd(v)
    out$ci_lower[i] <- as.numeric(quantile(v, 0.025))
    out$ci_upper[i] <- as.numeric(quantile(v, 0.975))
    out$ess[i]  <- as.numeric(coda::effectiveSize(v))
    out$rhat[i] <- tryCatch({
      pm <- as.mcmc.list(lapply(mat_list, function(ch) coda::mcmc(ch[, p, drop = FALSE])))
      coda::gelman.diag(pm, autoburnin = FALSE)$psrf[1]
    }, error = function(e) NA_real_)
  }
  out
}

# ---- 14.3 — fit M2 with alt phi prior (sequential, 4 chains) ----------------
log_step("=== Phase 14.3 — fitting M2 with phi ~ Gamma(1, 0.1) ===")

m2_alt_path <- file.path(MODELS_DIR, "model2_phi_sensitivity.jags")
stopifnot(file.exists(m2_alt_path))

set.seed(SEED_SENS_PHI)
inits_m2 <- lapply(1:4, function(i) {
  list(.RNG.name = c("base::Wichmann-Hill", "base::Marsaglia-Multicarry",
                     "base::Super-Duper",   "base::Mersenne-Twister")[i],
       .RNG.seed = SEED_SENS_PHI + i)
})

t0 <- Sys.time()
m2_alt <- jags.model(m2_alt_path, data = jd_base, inits = inits_m2,
                     n.chains = 4, n.adapt = 1000, quiet = TRUE)
update(m2_alt, 2000, progress.bar = "none")
m2_alt_post <- coda.samples(m2_alt,
                            c("beta0", paste0("beta[", 1:4, "]"),
                              paste0("gamma[", 1:6, "]"), "phi"),
                            n.iter = 4000, progress.bar = "none")
m2_runtime <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
log_step(sprintf("M2 alt fit done in %.1fs", m2_runtime))

saveRDS(m2_alt_post, file.path(MODEL_OBJ_DIR, "posterior_m2_phi_sensitivity.rds"))

m2_main_post <- readRDS(file.path(MODEL_OBJ_DIR, "posterior_m2.rds"))
m2_params <- c("beta0", paste0("beta[", 1:4, "]"),
               paste0("gamma[", 2:6, "]"), "phi")

m2_main_summ <- summarize_params(m2_main_post, m2_params)
m2_alt_summ  <- summarize_params(m2_alt_post,  m2_params)

m2_compare <- data.frame(
  parameter      = m2_params,
  main_mean      = m2_main_summ$mean,
  main_ci_lower  = m2_main_summ$ci_lower,
  main_ci_upper  = m2_main_summ$ci_upper,
  alt_mean       = m2_alt_summ$mean,
  alt_ci_lower   = m2_alt_summ$ci_lower,
  alt_ci_upper   = m2_alt_summ$ci_upper,
  diff_mean      = m2_alt_summ$mean - m2_main_summ$mean,
  alt_rhat       = m2_alt_summ$rhat,
  alt_ess        = m2_alt_summ$ess,
  stringsAsFactors = FALSE
)
m2_compare$sign_agree <- sign(m2_compare$main_mean) == sign(m2_compare$alt_mean)

write.csv(m2_compare,
          file.path(TABLES_DIR, "sensitivity_14_3_phi_bayesian_comparison.csv"),
          row.names = FALSE)
log_step("saved sensitivity_14_3_phi_bayesian_comparison.csv")

# ---- 14.4 — fit M3 with alt sigma_u prior (parallel, region-centered) -------
log_step("=== Phase 14.4 — fitting M3 with sigma_u ~ HN(0, 2.5) ===")

m3_alt_path <- file.path(MODELS_DIR, "model3_sigma_sensitivity_regioncentered.jags")
stopifnot(file.exists(m3_alt_path))

# Parallel single-chain fit, mclapply across cores
fit_one_chain <- function(chain_id) {
  suppressPackageStartupMessages({ library(rjags); library(coda) })
  rng_names <- c("base::Wichmann-Hill", "base::Marsaglia-Multicarry",
                 "base::Super-Duper",   "base::Mersenne-Twister")
  inits <- list(.RNG.name = rng_names[((chain_id - 1) %% 4) + 1],
                .RNG.seed = SEED_SENS_SIGMA + chain_id)
  m <- jags.model(m3_alt_path, data = jd_rc, inits = inits,
                  n.chains = 1, n.adapt = 500, quiet = TRUE)
  update(m, 4000, progress.bar = "none")
  coda.samples(m,
               c("beta0", paste0("beta[", 1:4, "]"),
                 paste0("gamma[", 1:6, "]"), "phi", "sigma_u"),
               n.iter = 6000, progress.bar = "none")[[1]]
}

t0 <- Sys.time()
n_chains <- 4
chain_list <- mclapply(seq_len(n_chains), fit_one_chain,
                       mc.cores = min(n_chains, parallel::detectCores()),
                       mc.preschedule = FALSE)
m3_runtime <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

ok_chains <- !vapply(chain_list, inherits, logical(1), "try-error")
log_step(sprintf("M3 alt fit done in %.1fs (%d/%d chains ok)",
                 m3_runtime, sum(ok_chains), n_chains))

if (!any(ok_chains)) stop("All M3 alt-sigma chains failed")

m3_alt_post <- as.mcmc.list(chain_list[ok_chains])
saveRDS(m3_alt_post, file.path(MODEL_OBJ_DIR, "posterior_m3_sigma_sensitivity.rds"))

m3_main_post <- readRDS(file.path(MODEL_OBJ_DIR, "posterior_m3.rds"))
m3_params <- c("beta0", paste0("beta[", 1:4, "]"),
               paste0("gamma[", 2:6, "]"), "phi", "sigma_u")

m3_main_summ <- summarize_params(m3_main_post, m3_params)
m3_alt_summ  <- summarize_params(m3_alt_post,  m3_params)

m3_compare <- data.frame(
  parameter      = m3_params,
  main_mean      = m3_main_summ$mean,
  main_ci_lower  = m3_main_summ$ci_lower,
  main_ci_upper  = m3_main_summ$ci_upper,
  alt_mean       = m3_alt_summ$mean,
  alt_ci_lower   = m3_alt_summ$ci_lower,
  alt_ci_upper   = m3_alt_summ$ci_upper,
  diff_mean      = m3_alt_summ$mean - m3_main_summ$mean,
  alt_rhat       = m3_alt_summ$rhat,
  alt_ess        = m3_alt_summ$ess,
  stringsAsFactors = FALSE
)
m3_compare$sign_agree <- sign(m3_compare$main_mean) == sign(m3_compare$alt_mean)

write.csv(m3_compare,
          file.path(TABLES_DIR, "sensitivity_14_4_sigma_bayesian_comparison.csv"),
          row.names = FALSE)
log_step("saved sensitivity_14_4_sigma_bayesian_comparison.csv")

# ---- Diagnostics summary for both alt fits ----------------------------------
diag_df <- rbind(
  data.frame(model = "M2_alt_phi",     m2_alt_summ),
  data.frame(model = "M3_alt_sigma_u", m3_alt_summ)
)
write.csv(diag_df, file.path(DIAG_DIR, "sensitivity_alt_diagnostics.csv"),
          row.names = FALSE)

# ---- Combined runtime/status note -------------------------------------------
status_lines <- c(
  "# Phase 14 Bayesian Sensitivity Arms — Status",
  sprintf("Run date: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## 14.3 phi prior sensitivity",
  sprintf("- Alt prior: phi ~ Gamma(1, 0.1)  (main: Gamma(2, 0.1))"),
  sprintf("- Fit settings: 4 chains x 1000 adapt x 2000 burn x 4000 iter"),
  sprintf("- Runtime: %.1f seconds", m2_runtime),
  sprintf("- Min ESS (alt): %.1f", min(m2_alt_summ$ess, na.rm = TRUE)),
  sprintf("- Max R-hat (alt): %.4f", max(m2_alt_summ$rhat, na.rm = TRUE)),
  sprintf("- Sign agreement vs main: %d / %d parameters",
          sum(m2_compare$sign_agree, na.rm = TRUE), sum(!is.na(m2_compare$sign_agree))),
  "",
  "## 14.4 sigma_u prior sensitivity",
  sprintf("- Alt prior: sigma_u ~ Half-Normal(0, 2.5)  (main: Half-Normal(0, 1))"),
  sprintf("- Parameterization: region-centered non-centered (same as accepted M3)"),
  sprintf("- Fit settings: 4 parallel chains x 500 adapt x 4000 burn x 6000 iter"),
  sprintf("- Runtime: %.1f seconds (%.1f minutes)", m3_runtime, m3_runtime / 60),
  sprintf("- Min ESS (alt): %.1f", min(m3_alt_summ$ess, na.rm = TRUE)),
  sprintf("- Max R-hat (alt): %.4f", max(m3_alt_summ$rhat, na.rm = TRUE)),
  sprintf("- Sign agreement vs main: %d / %d parameters",
          sum(m3_compare$sign_agree, na.rm = TRUE), sum(!is.na(m3_compare$sign_agree))),
  "",
  "Both alt fits use the same locked dataset (data/data_processed/main_analysis_table_locked.{csv,rds}).",
  "Main analysis fits are unchanged."
)
writeLines(status_lines,
           file.path(TABLES_DIR, "sensitivity_14_3_4_bayesian_status.txt"))

log_step("=== Phase 14.3 and 14.4 BAYESIAN ARMS DONE ===")
