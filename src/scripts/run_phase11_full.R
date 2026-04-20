suppressPackageStartupMessages({
  library(rjags)
  library(coda)
  library(parallel)
})

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

# ------------------------------------------------------------------------------
# Phase 11 FULL recovery study.
# Uses posterior means from accepted M1/M2/M3 fits as true parameter values.
# M3 is the accepted region-centered non-centered parameterization.
# Design (cohort sizes, predictors, country/region IDs) is held fixed.
# Only response counts Y are regenerated from the model.
# ------------------------------------------------------------------------------

PROJECT_ROOT <- "/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project"
setwd(PROJECT_ROOT)

MODEL_OBJ_DIR <- "src/outputs/model_objects"
MODELS_DIR    <- "src/models"
SIMS_DIR      <- "src/outputs/simulations"
dir.create(SIMS_DIR, recursive = TRUE, showWarnings = FALSE)

# ---- Recovery design --------------------------------------------------------
# Target: 30 datasets per model. M3 is reduced to 10 datasets because a single
# refit of the accepted region-centered M3 takes ~15 minutes at moderate
# chain length, so 30 M3 reps would require >7 hours of wall time on the
# 4-physical-core laptop used for this project. The reduction is documented
# in notes/decision_log.md.
N_REPS_M1 <- 30L
N_REPS_M2 <- 30L
N_REPS_M3 <- 10L   # justified reduction; see decision_log.md

# Moderate MCMC settings (longer than pilot, short enough for 30 reps)
MCMC_FLAT <- list(n_chains = 2L, n_adapt = 500L, n_burnin = 1500L, n_iter = 2000L)
MCMC_M3   <- list(n_chains = 2L, n_adapt = 500L, n_burnin = 2000L, n_iter = 2500L)

RHAT_TARGET <- 1.10
ESS_TARGET  <- 100

SEED_FULL <- 2026L * 11L + 99L
set.seed(SEED_FULL)

# ---- Load design and JAGS data ----------------------------------------------
log_step("loading locked design + JAGS data")
jd_base <- readRDS(file.path(MODEL_OBJ_DIR, "jags_data_base.rds"))
jd_hier <- readRDS(file.path(MODEL_OBJ_DIR, "jags_data_hier.rds"))
jd_rc   <- readRDS(file.path(MODEL_OBJ_DIR, "jags_data_hier_regioncentered.rds"))
N <- jd_base$N; C <- jd_hier$C; R <- jd_hier$R; n_pred <- jd_base$n_pred
log_step(sprintf("N=%d, C=%d, R=%d, n_pred=%d", N, C, R, n_pred))

# ---- Extract posterior means (true values) ----------------------------------
log_step("extracting posterior means from accepted fits")
posterior_means <- function(path, cols) {
  s <- readRDS(path)
  m <- do.call(rbind, lapply(s, as.matrix))
  if (is.null(cols)) cols <- colnames(m)
  stopifnot(all(cols %in% colnames(m)))
  setNames(colMeans(m[, cols, drop = FALSE]), cols)
}

beta_cols  <- paste0("beta[",  seq_len(n_pred), "]")
u_cols_C   <- paste0("u[",     seq_len(C),      "]")

pm_m1 <- posterior_means(file.path(MODEL_OBJ_DIR, "posterior_m1.rds"),
                         c("beta0", beta_cols, paste0("gamma[", 2:R, "]")))
pm_m2 <- posterior_means(file.path(MODEL_OBJ_DIR, "posterior_m2.rds"),
                         c("beta0", beta_cols, paste0("gamma[", 2:R, "]"), "phi"))
pm_m3_glob <- posterior_means(file.path(MODEL_OBJ_DIR, "posterior_m3.rds"),
                              c("beta0", beta_cols, paste0("gamma[", 2:R, "]"), "phi", "sigma_u"))
pm_m3_u <- posterior_means(file.path(MODEL_OBJ_DIR, "posterior_m3_u.rds"), u_cols_C)

make_gamma <- function(pm) {
  g <- c(0, as.numeric(pm[paste0("gamma[", 2:R, "]")]))
  names(g) <- paste0("gamma[", 1:R, "]")
  g
}

TRUE_M1 <- list(beta0 = as.numeric(pm_m1["beta0"]),
                beta  = as.numeric(pm_m1[beta_cols]),
                gamma = make_gamma(pm_m1))
TRUE_M2 <- list(beta0 = as.numeric(pm_m2["beta0"]),
                beta  = as.numeric(pm_m2[beta_cols]),
                gamma = make_gamma(pm_m2),
                phi   = as.numeric(pm_m2["phi"]))

# M3 truth: re-center u per region, absorb within-region means into gamma, re-anchor gamma[1]=0 into beta0.
u_vec <- as.numeric(pm_m3_u)
region_of_country <- integer(C)
for (c_i in seq_len(C)) {
  rows_ci <- which(jd_hier$country == c_i)
  region_of_country[c_i] <- jd_hier$region[rows_ci[1]]
}
u_mean_per_region <- tapply(u_vec, region_of_country, mean)
u_centered <- u_vec - u_mean_per_region[region_of_country]
gamma_raw <- make_gamma(pm_m3_glob)
gamma_adj <- gamma_raw + as.numeric(u_mean_per_region[seq_len(R)])
beta0_adj <- as.numeric(pm_m3_glob["beta0"]) + gamma_adj[1]
gamma_adj <- gamma_adj - gamma_adj[1]
names(gamma_adj) <- paste0("gamma[", 1:R, "]")

TRUE_M3 <- list(beta0   = beta0_adj,
                beta    = as.numeric(pm_m3_glob[beta_cols]),
                gamma   = gamma_adj,
                phi     = as.numeric(pm_m3_glob["phi"]),
                sigma_u = as.numeric(pm_m3_glob["sigma_u"]),
                u       = u_centered)

saveRDS(list(m1 = TRUE_M1, m2 = TRUE_M2, m3 = TRUE_M3,
             region_of_country = region_of_country),
        file.path(SIMS_DIR, "true_params_full.rds"))

# ---- Simulation + refit helpers (identical to pilot) ------------------------
sim_m1 <- function(pars, jd, seed) { set.seed(seed)
  eta <- pars$beta0 + as.numeric(jd$X %*% pars$beta) + pars$gamma[jd$region]
  rbinom(jd$N, size = jd$n, prob = plogis(eta))
}
sim_m2 <- function(pars, jd, seed) { set.seed(seed)
  eta <- pars$beta0 + as.numeric(jd$X %*% pars$beta) + pars$gamma[jd$region]
  mu  <- plogis(eta)
  theta <- rbeta(jd$N, mu * pars$phi, (1 - mu) * pars$phi)
  theta <- pmin(pmax(theta, 1e-12), 1 - 1e-12)
  rbinom(jd$N, size = jd$n, prob = theta)
}
sim_m3 <- function(pars, jd_hier, seed) { set.seed(seed)
  eta <- pars$beta0 + as.numeric(jd_hier$X %*% pars$beta) +
         pars$gamma[jd_hier$region] + pars$u[jd_hier$country]
  mu  <- plogis(eta)
  theta <- rbeta(jd_hier$N, mu * pars$phi, (1 - mu) * pars$phi)
  theta <- pmin(pmax(theta, 1e-12), 1 - 1e-12)
  rbinom(jd_hier$N, size = jd_hier$n, prob = theta)
}

fit_sequential <- function(model_file, jd, monitors, cfg, seed_base) {
  inits_list <- lapply(seq_len(cfg$n_chains), function(i) {
    list(.RNG.name = c("base::Wichmann-Hill", "base::Marsaglia-Multicarry",
                       "base::Super-Duper", "base::Mersenne-Twister")[((i - 1) %% 4) + 1],
         .RNG.seed = seed_base + i)
  })
  m <- jags.model(model_file, data = jd, inits = inits_list,
                  n.chains = cfg$n_chains, n.adapt = cfg$n_adapt, quiet = TRUE)
  update(m, cfg$n_burnin, progress.bar = "none")
  coda.samples(m, monitors, cfg$n_iter, progress.bar = "none")
}

fit_m3_parallel <- function(jd_rc_sim, monitors, cfg, seed_base) {
  rng_names <- c("base::Wichmann-Hill", "base::Marsaglia-Multicarry",
                 "base::Super-Duper", "base::Mersenne-Twister")
  model_file <- file.path(MODELS_DIR, "model3_noncentered_regioncentered.jags")
  run_one <- function(chain_id) {
    suppressPackageStartupMessages({ library(rjags); library(coda) })
    inits <- list(.RNG.name = rng_names[((chain_id - 1) %% 4) + 1],
                  .RNG.seed = seed_base + chain_id)
    m <- jags.model(model_file, data = jd_rc_sim, inits = inits,
                    n.chains = 1, n.adapt = cfg$n_adapt, quiet = TRUE)
    update(m, cfg$n_burnin, progress.bar = "none")
    coda.samples(m, monitors, cfg$n_iter, progress.bar = "none")[[1]]
  }
  chains <- mclapply(seq_len(cfg$n_chains), run_one,
                     mc.cores = min(cfg$n_chains, parallel::detectCores()),
                     mc.preschedule = FALSE)
  if (any(vapply(chains, inherits, logical(1), "try-error"))) return(NULL)
  as.mcmc.list(chains)
}

summarize_fit <- function(samples, monitors, true_pack) {
  mat_list <- lapply(samples, as.matrix)
  full <- do.call(rbind, mat_list)
  out <- data.frame(parameter = monitors, true_value = NA_real_,
                    post_mean = NA_real_, post_sd = NA_real_,
                    ci_lo = NA_real_, ci_hi = NA_real_,
                    rhat = NA_real_, ess = NA_real_,
                    covered_95 = NA, stringsAsFactors = FALSE)
  for (i in seq_along(monitors)) {
    p <- monitors[i]
    if (!(p %in% colnames(full))) next
    v <- full[, p]
    out$post_mean[i] <- mean(v); out$post_sd[i] <- sd(v)
    out$ci_lo[i] <- as.numeric(quantile(v, 0.025))
    out$ci_hi[i] <- as.numeric(quantile(v, 0.975))
    out$ess[i]   <- as.numeric(effectiveSize(v))
    rh <- tryCatch({
      pm <- as.mcmc.list(lapply(mat_list, function(ch) mcmc(ch[, p, drop = FALSE])))
      gelman.diag(pm, autoburnin = FALSE)$psrf[1]
    }, error = function(e) NA_real_)
    out$rhat[i] <- rh
    tv <- NA_real_
    if (p == "beta0") tv <- true_pack$beta0
    else if (grepl("^beta\\[", p)) { idx <- as.integer(gsub("beta\\[|\\]", "", p)); tv <- true_pack$beta[idx] }
    else if (grepl("^gamma\\[", p)) { idx <- as.integer(gsub("gamma\\[|\\]", "", p)); tv <- true_pack$gamma[idx] }
    else if (p == "phi")     tv <- true_pack$phi
    else if (p == "sigma_u") tv <- true_pack$sigma_u
    out$true_value[i] <- tv
    out$covered_95[i] <- (tv >= out$ci_lo[i]) && (tv <= out$ci_hi[i])
  }
  out
}

MON_M1 <- c("beta0", beta_cols, paste0("gamma[", 2:R, "]"))
MON_M2 <- c("beta0", beta_cols, paste0("gamma[", 2:R, "]"), "phi")
MON_M3 <- c("beta0", beta_cols, paste0("gamma[", 2:R, "]"), "phi", "sigma_u")

# ---- Run full recovery ------------------------------------------------------
run_rep <- function(model_id, rep_idx, seed) {
  if (model_id == "M1") {
    Y_sim <- sim_m1(TRUE_M1, jd_base, seed); jd_sim <- jd_base; jd_sim$Y <- Y_sim
    t0 <- Sys.time()
    fit <- tryCatch(fit_sequential(file.path(MODELS_DIR, "model1_binomial.jags"),
                                   jd_sim, MON_M1, MCMC_FLAT, seed + 1e5),
                    error = function(e) NULL)
    dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (is.null(fit)) return(list(rep = rep_idx, ok = FALSE, runtime_s = dt))
    list(rep = rep_idx, ok = TRUE, runtime_s = dt,
         summary = summarize_fit(fit, MON_M1, TRUE_M1), seed = seed)
  } else if (model_id == "M2") {
    Y_sim <- sim_m2(TRUE_M2, jd_base, seed); jd_sim <- jd_base; jd_sim$Y <- Y_sim
    t0 <- Sys.time()
    fit <- tryCatch(fit_sequential(file.path(MODELS_DIR, "model2_betabinomial.jags"),
                                   jd_sim, MON_M2, MCMC_FLAT, seed + 1e5),
                    error = function(e) NULL)
    dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (is.null(fit)) return(list(rep = rep_idx, ok = FALSE, runtime_s = dt))
    list(rep = rep_idx, ok = TRUE, runtime_s = dt,
         summary = summarize_fit(fit, MON_M2, TRUE_M2), seed = seed)
  } else {
    Y_sim <- sim_m3(TRUE_M3, jd_hier, seed)
    jd_rc_sim <- jd_rc; jd_rc_sim$Y <- Y_sim
    t0 <- Sys.time()
    fit <- tryCatch(fit_m3_parallel(jd_rc_sim, MON_M3, MCMC_M3, seed + 1e5),
                    error = function(e) NULL)
    dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (is.null(fit)) return(list(rep = rep_idx, ok = FALSE, runtime_s = dt))
    list(rep = rep_idx, ok = TRUE, runtime_s = dt,
         summary = summarize_fit(fit, MON_M3, TRUE_M3), seed = seed)
  }
}

seeds_m1 <- sample.int(1e6, N_REPS_M1)
seeds_m2 <- sample.int(1e6, N_REPS_M2)
seeds_m3 <- sample.int(1e6, N_REPS_M3)

results <- list(M1 = vector("list", N_REPS_M1),
                M2 = vector("list", N_REPS_M2),
                M3 = vector("list", N_REPS_M3))

log_step(sprintf("=== FULL: M1 (%d reps) ===", N_REPS_M1))
for (r in seq_len(N_REPS_M1)) {
  res <- run_rep("M1", r, seeds_m1[r])
  log_step(sprintf("M1 rep %d/%d ok=%s runtime=%.1fs", r, N_REPS_M1, res$ok, res$runtime_s))
  results$M1[[r]] <- res
  if (r %% 5 == 0) saveRDS(results$M1, file.path(SIMS_DIR, "recovery_results_m1.rds"))
}
saveRDS(results$M1, file.path(SIMS_DIR, "recovery_results_m1.rds"))

log_step(sprintf("=== FULL: M2 (%d reps) ===", N_REPS_M2))
for (r in seq_len(N_REPS_M2)) {
  res <- run_rep("M2", r, seeds_m2[r])
  log_step(sprintf("M2 rep %d/%d ok=%s runtime=%.1fs", r, N_REPS_M2, res$ok, res$runtime_s))
  results$M2[[r]] <- res
  if (r %% 5 == 0) saveRDS(results$M2, file.path(SIMS_DIR, "recovery_results_m2.rds"))
}
saveRDS(results$M2, file.path(SIMS_DIR, "recovery_results_m2.rds"))

log_step(sprintf("=== FULL: M3 (%d reps, region-centered, parallel chains) ===", N_REPS_M3))
for (r in seq_len(N_REPS_M3)) {
  res <- run_rep("M3", r, seeds_m3[r])
  log_step(sprintf("M3 rep %d/%d ok=%s runtime=%.1fs", r, N_REPS_M3, res$ok, res$runtime_s))
  results$M3[[r]] <- res
  saveRDS(results$M3, file.path(SIMS_DIR, "recovery_results_m3.rds"))
}

log_step("=== FULL RECOVERY COMPLETE ===")
saveRDS(results, file.path(SIMS_DIR, "recovery_results_all.rds"))
