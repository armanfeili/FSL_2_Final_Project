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
# Phase 11 PILOT — 3 simulated datasets per model, short chains.
# Verifies the full recovery pipeline end-to-end using:
#   * posterior means from the accepted fits as true parameter values
#   * the accepted region-centered M3 (model3_noncentered_regioncentered.jags)
#   * the locked design (cohort sizes, predictors, country and region IDs)
# ------------------------------------------------------------------------------

PROJECT_ROOT <- "/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project"
setwd(PROJECT_ROOT)

MODEL_OBJ_DIR <- "src/outputs/model_objects"
MODELS_DIR    <- "src/models"
SIMS_DIR      <- "src/outputs/simulations/pilot"
dir.create(SIMS_DIR, recursive = TRUE, showWarnings = FALSE)

# ---- Pilot MCMC settings (intentionally short) -------------------------------
N_REPS_PILOT <- 3L
MCMC_PILOT_FLAT <- list(n_chains = 2L, n_adapt = 200L, n_burnin = 400L, n_iter = 600L)
MCMC_PILOT_M3   <- list(n_chains = 2L, n_adapt = 300L, n_burnin = 800L, n_iter = 1000L)

RHAT_TARGET <- 1.10
ESS_TARGET  <- 100

SEED_PILOT <- 2026L * 11L + 1L
set.seed(SEED_PILOT)

# ---- Load design and JAGS data ----------------------------------------------
log_step("loading locked design + JAGS data")
jd_base <- readRDS(file.path(MODEL_OBJ_DIR, "jags_data_base.rds"))
jd_hier <- readRDS(file.path(MODEL_OBJ_DIR, "jags_data_hier.rds"))
jd_rc   <- readRDS(file.path(MODEL_OBJ_DIR, "jags_data_hier_regioncentered.rds"))
stopifnot(jd_base$N == jd_hier$N, jd_hier$N == jd_rc$N)
N <- jd_base$N
C <- jd_hier$C
R <- jd_hier$R
n_pred <- jd_base$n_pred
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
gamma_cols <- paste0("gamma[", seq_len(R),      "]")  # gamma[1]=0 deterministic
u_cols_C   <- paste0("u[",     seq_len(C),      "]")

pm_m1 <- posterior_means(file.path(MODEL_OBJ_DIR, "posterior_m1.rds"),
                         c("beta0", beta_cols, paste0("gamma[", 2:R, "]")))
pm_m2 <- posterior_means(file.path(MODEL_OBJ_DIR, "posterior_m2.rds"),
                         c("beta0", beta_cols, paste0("gamma[", 2:R, "]"), "phi"))
pm_m3_glob <- posterior_means(file.path(MODEL_OBJ_DIR, "posterior_m3.rds"),
                              c("beta0", beta_cols, paste0("gamma[", 2:R, "]"), "phi", "sigma_u"))
pm_m3_u <- posterior_means(file.path(MODEL_OBJ_DIR, "posterior_m3_u.rds"), u_cols_C)

# Build TRUE parameter packs (gamma[1]=0 by convention)
make_gamma <- function(pm) {
  g <- c(0, as.numeric(pm[paste0("gamma[", 2:R, "]")]))
  names(g) <- paste0("gamma[", 1:R, "]")
  g
}

TRUE_M1 <- list(
  beta0 = as.numeric(pm_m1["beta0"]),
  beta  = as.numeric(pm_m1[beta_cols]),
  gamma = make_gamma(pm_m1)
)
TRUE_M2 <- list(
  beta0 = as.numeric(pm_m2["beta0"]),
  beta  = as.numeric(pm_m2[beta_cols]),
  gamma = make_gamma(pm_m2),
  phi   = as.numeric(pm_m2["phi"])
)

# For M3, re-center posterior-mean u per region (sum-to-zero within region)
# and absorb within-region means into gamma. This makes the truth consistent
# with the accepted region-centered parameterization.
u_vec <- as.numeric(pm_m3_u)
region_of_country <- integer(C)
for (c_i in seq_len(C)) {
  rows_ci <- which(jd_hier$country == c_i)
  stopifnot(length(rows_ci) > 0)
  region_of_country[c_i] <- jd_hier$region[rows_ci[1]]
}
u_mean_per_region <- tapply(u_vec, region_of_country, mean)
u_centered <- u_vec - u_mean_per_region[region_of_country]
gamma_raw <- make_gamma(pm_m3_glob)
gamma_adj <- gamma_raw + as.numeric(u_mean_per_region[seq_len(R)])
# Re-anchor baseline region to gamma[1]=0 (shift into beta0)
beta0_adj <- as.numeric(pm_m3_glob["beta0"]) + gamma_adj[1]
gamma_adj <- gamma_adj - gamma_adj[1]
names(gamma_adj) <- paste0("gamma[", 1:R, "]")

TRUE_M3 <- list(
  beta0   = beta0_adj,
  beta    = as.numeric(pm_m3_glob[beta_cols]),
  gamma   = gamma_adj,
  phi     = as.numeric(pm_m3_glob["phi"]),
  sigma_u = as.numeric(pm_m3_glob["sigma_u"]),
  u       = u_centered
)

log_step(sprintf("TRUE_M1: beta0=%.3f", TRUE_M1$beta0))
log_step(sprintf("TRUE_M2: beta0=%.3f phi=%.2f", TRUE_M2$beta0, TRUE_M2$phi))
log_step(sprintf("TRUE_M3: beta0=%.3f phi=%.2f sigma_u=%.3f  (u re-centered per region)",
  TRUE_M3$beta0, TRUE_M3$phi, TRUE_M3$sigma_u))
log_step(sprintf("  per-region mean of re-centered u: [%s]",
  paste(sprintf("%.1e", tapply(TRUE_M3$u, region_of_country, mean)), collapse = " ")))

saveRDS(list(
  m1 = TRUE_M1, m2 = TRUE_M2, m3 = TRUE_M3,
  region_of_country = region_of_country,
  note = "posterior means from accepted fits; M3 u re-centered per region, gamma/beta0 adjusted"
), file.path(SIMS_DIR, "true_params_pilot.rds"))

# ---- Simulation functions ---------------------------------------------------
sim_m1 <- function(pars, jd, seed) {
  set.seed(seed)
  eta <- pars$beta0 + as.numeric(jd$X %*% pars$beta) + pars$gamma[jd$region]
  p   <- plogis(eta)
  rbinom(jd$N, size = jd$n, prob = p)
}
sim_m2 <- function(pars, jd, seed) {
  set.seed(seed)
  eta <- pars$beta0 + as.numeric(jd$X %*% pars$beta) + pars$gamma[jd$region]
  mu  <- plogis(eta)
  theta <- rbeta(jd$N, mu * pars$phi, (1 - mu) * pars$phi)
  theta <- pmin(pmax(theta, 1e-12), 1 - 1e-12)
  rbinom(jd$N, size = jd$n, prob = theta)
}
sim_m3 <- function(pars, jd_hier, seed) {
  set.seed(seed)
  eta <- pars$beta0 + as.numeric(jd_hier$X %*% pars$beta) +
         pars$gamma[jd_hier$region] + pars$u[jd_hier$country]
  mu  <- plogis(eta)
  theta <- rbeta(jd_hier$N, mu * pars$phi, (1 - mu) * pars$phi)
  theta <- pmin(pmax(theta, 1e-12), 1 - 1e-12)
  rbinom(jd_hier$N, size = jd_hier$n, prob = theta)
}

# ---- Refit helpers ----------------------------------------------------------
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
  if (any(vapply(chains, inherits, logical(1), "try-error"))) {
    return(NULL)
  }
  as.mcmc.list(chains)
}

# ---- Diagnostic helper ------------------------------------------------------
summarize_fit <- function(samples, monitors, true_pack) {
  mat_list <- lapply(samples, as.matrix)
  full <- do.call(rbind, mat_list)
  # Per-parameter summaries
  out <- data.frame(parameter = monitors, true_value = NA_real_,
                    post_mean = NA_real_, post_sd = NA_real_,
                    ci_lo = NA_real_, ci_hi = NA_real_,
                    rhat = NA_real_, ess = NA_real_,
                    covered_95 = NA, stringsAsFactors = FALSE)
  for (i in seq_along(monitors)) {
    p <- monitors[i]
    if (!(p %in% colnames(full))) next
    v <- full[, p]
    out$post_mean[i] <- mean(v)
    out$post_sd[i]   <- sd(v)
    out$ci_lo[i]     <- as.numeric(quantile(v, 0.025))
    out$ci_hi[i]     <- as.numeric(quantile(v, 0.975))
    out$ess[i]       <- as.numeric(effectiveSize(v))
    rh <- tryCatch({
      pm <- as.mcmc.list(lapply(mat_list, function(ch) mcmc(ch[, p, drop = FALSE])))
      gelman.diag(pm, autoburnin = FALSE)$psrf[1]
    }, error = function(e) NA_real_)
    out$rhat[i] <- rh
    # True value lookup
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

build_jd_rc_from_sim <- function(jd_rc_template, Y_sim) {
  new_jd <- jd_rc_template
  new_jd$Y <- Y_sim
  new_jd
}

# ---- Monitor sets -----------------------------------------------------------
MON_M1 <- c("beta0", beta_cols, paste0("gamma[", 2:R, "]"))
MON_M2 <- c("beta0", beta_cols, paste0("gamma[", 2:R, "]"), "phi")
MON_M3 <- c("beta0", beta_cols, paste0("gamma[", 2:R, "]"), "phi", "sigma_u")

# ---- Run the pilot ----------------------------------------------------------
seeds_m1 <- sample.int(1e6, N_REPS_PILOT)
seeds_m2 <- sample.int(1e6, N_REPS_PILOT)
seeds_m3 <- sample.int(1e6, N_REPS_PILOT)

run_one_rep <- function(model_id, rep_idx, seed) {
  if (model_id == "M1") {
    Y_sim <- sim_m1(TRUE_M1, jd_base, seed)
    jd_sim <- jd_base; jd_sim$Y <- Y_sim
    t0 <- Sys.time()
    fit <- tryCatch(fit_sequential(file.path(MODELS_DIR, "model1_binomial.jags"),
                                   jd_sim, MON_M1, MCMC_PILOT_FLAT, seed + 1e5),
                    error = function(e) NULL)
    dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (is.null(fit)) return(list(rep = rep_idx, ok = FALSE, runtime_s = dt))
    summ <- summarize_fit(fit, MON_M1, TRUE_M1)
    list(rep = rep_idx, ok = TRUE, runtime_s = dt, summary = summ)
  } else if (model_id == "M2") {
    Y_sim <- sim_m2(TRUE_M2, jd_base, seed)
    jd_sim <- jd_base; jd_sim$Y <- Y_sim
    t0 <- Sys.time()
    fit <- tryCatch(fit_sequential(file.path(MODELS_DIR, "model2_betabinomial.jags"),
                                   jd_sim, MON_M2, MCMC_PILOT_FLAT, seed + 1e5),
                    error = function(e) NULL)
    dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (is.null(fit)) return(list(rep = rep_idx, ok = FALSE, runtime_s = dt))
    summ <- summarize_fit(fit, MON_M2, TRUE_M2)
    list(rep = rep_idx, ok = TRUE, runtime_s = dt, summary = summ)
  } else {
    Y_sim <- sim_m3(TRUE_M3, jd_hier, seed)
    jd_rc_sim <- build_jd_rc_from_sim(jd_rc, Y_sim)
    t0 <- Sys.time()
    fit <- tryCatch(fit_m3_parallel(jd_rc_sim, MON_M3, MCMC_PILOT_M3, seed + 1e5),
                    error = function(e) NULL)
    dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (is.null(fit)) return(list(rep = rep_idx, ok = FALSE, runtime_s = dt))
    summ <- summarize_fit(fit, MON_M3, TRUE_M3)
    list(rep = rep_idx, ok = TRUE, runtime_s = dt, summary = summ)
  }
}

pilot_results <- list(M1 = list(), M2 = list(), M3 = list())

log_step("=== PILOT: M1 ===")
for (r in seq_len(N_REPS_PILOT)) {
  log_step(sprintf("M1 rep %d/%d (seed=%d)", r, N_REPS_PILOT, seeds_m1[r]))
  res <- run_one_rep("M1", r, seeds_m1[r])
  log_step(sprintf("  ok=%s runtime=%.1fs", res$ok, res$runtime_s))
  pilot_results$M1[[r]] <- res
}

log_step("=== PILOT: M2 ===")
for (r in seq_len(N_REPS_PILOT)) {
  log_step(sprintf("M2 rep %d/%d (seed=%d)", r, N_REPS_PILOT, seeds_m2[r]))
  res <- run_one_rep("M2", r, seeds_m2[r])
  log_step(sprintf("  ok=%s runtime=%.1fs", res$ok, res$runtime_s))
  pilot_results$M2[[r]] <- res
}

log_step("=== PILOT: M3 (region-centered, parallel chains) ===")
for (r in seq_len(N_REPS_PILOT)) {
  log_step(sprintf("M3 rep %d/%d (seed=%d)", r, N_REPS_PILOT, seeds_m3[r]))
  res <- run_one_rep("M3", r, seeds_m3[r])
  log_step(sprintf("  ok=%s runtime=%.1fs", res$ok, res$runtime_s))
  pilot_results$M3[[r]] <- res
}

saveRDS(pilot_results, file.path(SIMS_DIR, "pilot_results.rds"))

# ---- Pilot summary ----------------------------------------------------------
agg <- function(res_list, model_id) {
  rts <- vapply(res_list, function(x) x$runtime_s, numeric(1))
  oks <- vapply(res_list, function(x) x$ok, logical(1))
  n_ok <- sum(oks)
  if (n_ok == 0) return(data.frame(model = model_id, n_ok = 0, stringsAsFactors = FALSE))
  df <- do.call(rbind, lapply(res_list[oks], function(x) x$summary))
  df$model <- model_id
  df
}
pilot_long <- do.call(rbind, lapply(names(pilot_results), function(m) agg(pilot_results[[m]], m)))
write.csv(pilot_long, file.path(SIMS_DIR, "pilot_summary_long.csv"), row.names = FALSE)

cat("\n=== PILOT SUMMARY ===\n")
for (m in c("M1", "M2", "M3")) {
  rl <- pilot_results[[m]]
  rts <- vapply(rl, function(x) x$runtime_s, numeric(1))
  oks <- vapply(rl, function(x) x$ok, logical(1))
  cat(sprintf("%s: %d/%d ok, mean runtime = %.1fs, total = %.1fs\n",
    m, sum(oks), length(oks), mean(rts[oks]), sum(rts)))
}

agg2 <- function(model_id) {
  df <- pilot_long[pilot_long$model == model_id, ]
  if (nrow(df) == 0) return(invisible())
  tapply_df <- aggregate(cbind(rhat, ess, covered_95, post_mean, true_value) ~ parameter,
                         data = df, FUN = function(x) mean(x, na.rm = TRUE))
  cat(sprintf("\n--- %s per-parameter means across %d ok reps ---\n", model_id,
              length(unique(df$parameter)) - nrow(df) %/% length(unique(df$parameter)) + 1))
  print(tapply_df, row.names = FALSE)
}
for (m in c("M1", "M2", "M3")) agg2(m)

log_step("=== PILOT COMPLETE ===")
