library(rjags)
library(coda)
library(parallel)

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

jd_rc <- readRDS("src/outputs/model_objects/jags_data_hier_regioncentered.rds")
log_step(sprintf("loaded region-centered data: N=%d C=%d R=%d", jd_rc$N, jd_rc$C, jd_rc$R))

N_CHAINS <- 4L
N_ADAPT <- 500L
N_BURN <- 1500L
N_SAMPLE <- 2000L
PARAMS <- c("beta0", "beta", "gamma", "phi", "sigma_u")

rng_names <- c(
  "base::Wichmann-Hill",
  "base::Marsaglia-Multicarry",
  "base::Super-Duper",
  "base::Mersenne-Twister"
)
chain_seeds <- c(20261L, 20262L, 20263L, 20264L)

run_chain <- function(chain_id) {
  library(rjags)
  library(coda)
  inits <- list(
    .RNG.name = rng_names[chain_id],
    .RNG.seed = chain_seeds[chain_id]
  )
  t0 <- Sys.time()
  m <- jags.model(
    "src/models/model3_noncentered_regioncentered.jags",
    data = jd_rc,
    inits = inits,
    n.chains = 1,
    n.adapt = N_ADAPT,
    quiet = TRUE
  )
  update(m, N_BURN, progress.bar = "none")
  s <- coda.samples(m, PARAMS, N_SAMPLE, progress.bar = "none")
  t1 <- Sys.time()
  list(
    samples = s[[1]],
    seconds = as.numeric(difftime(t1, t0, units = "secs")),
    chain_id = chain_id
  )
}

log_step(sprintf("launching %d parallel chains via mclapply (adapt=%d, burn=%d, sample=%d, globals only)",
  N_CHAINS, N_ADAPT, N_BURN, N_SAMPLE))

t_total <- system.time({
  res <- mclapply(seq_len(N_CHAINS), run_chain, mc.cores = N_CHAINS, mc.preschedule = FALSE)
})

errs <- sapply(res, function(r) inherits(r, "try-error") || is.null(r$samples))
if (any(errs)) {
  log_step("ERROR: one or more chains failed. Dumping first error:")
  for (r in res) {
    if (inherits(r, "try-error")) {
      cat(attr(r, "condition")$message, "\n")
      break
    }
  }
  stop("parallel chains failed")
}

chain_times <- sapply(res, function(r) r$seconds)
log_step(sprintf("parallel runtime: wall=%.1fs, max per-chain=%.1fs, min per-chain=%.1fs",
  t_total[3], max(chain_times), min(chain_times)))

mcmc_list <- as.mcmc.list(lapply(res, function(r) r$samples))
saveRDS(mcmc_list, "src/outputs/model_objects/posterior_m3_regioncentered_midpilot.rds")
log_step("mid-pilot posterior saved")

sm <- summary(mcmc_list)
params <- rownames(sm$statistics)
varv <- apply(as.matrix(mcmc_list), 2, var)

calc_rhat <- function(p) {
  tryCatch(
    as.numeric(gelman.diag(
      mcmc_list[, p, drop = FALSE],
      autoburnin = FALSE,
      multivariate = FALSE
    )$psrf[1, 1]),
    error = function(e) NA_real_
  )
}

rhat <- sapply(params, calc_rhat)
ess <- as.numeric(effectiveSize(mcmc_list))
nonvarying <- is.na(varv[params]) | varv[params] == 0

tab <- data.frame(
  parameter = params,
  mean = sm$statistics[params, "Mean"],
  sd = sm$statistics[params, "SD"],
  q2.5 = sm$quantiles[params, "2.5%"],
  q50 = sm$quantiles[params, "50%"],
  q97.5 = sm$quantiles[params, "97.5%"],
  ess = ess,
  rhat = rhat,
  nonvarying = nonvarying,
  flag_ess_lt_400 = ifelse(nonvarying, FALSE, ess < 400),
  flag_rhat_gt_1.05 = ifelse(nonvarying, FALSE, rhat > 1.05)
)
write.csv(tab, "src/outputs/diagnostics/m3_regioncentered_midpilot_diagnostics_summary.csv", row.names = FALSE)

key <- c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]",
         "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]",
         "phi", "sigma_u")
key_tab <- tab[tab$parameter %in% key, ]
kv <- !key_tab$nonvarying
min_ess <- min(key_tab$ess[kv], na.rm = TRUE)
max_rhat <- max(key_tab$rhat[kv], na.rm = TRUE)
fail_ess <- key_tab$parameter[kv][key_tab$ess[kv] < 400]
fail_rhat <- key_tab$parameter[kv][key_tab$rhat[kv] > 1.05]
all_pass <- all(key_tab$ess[kv] >= 400, na.rm = TRUE) &&
  all(key_tab$rhat[kv] <= 1.05, na.rm = TRUE)

cat("\n=== MID-PILOT DIAGNOSTICS (KEY GLOBALS) ===\n")
print(key_tab[, c("parameter", "mean", "sd", "ess", "rhat",
                  "flag_ess_lt_400", "flag_rhat_gt_1.05")], row.names = FALSE)
cat(sprintf("\nwall runtime:   %.1f sec\n", t_total[3]))
cat(sprintf("min ESS (key):  %.1f\n", min_ess))
cat(sprintf("max Rhat (key): %.4f\n", max_rhat))
cat(sprintf("fail ESS<400:   %s\n", if (length(fail_ess)) paste(fail_ess, collapse = ", ") else "(none)"))
cat(sprintf("fail Rhat>1.05: %s\n", if (length(fail_rhat)) paste(fail_rhat, collapse = ", ") else "(none)"))
cat(sprintf("all key pass:   %s\n", all_pass))
cat("=== END MID-PILOT ===\n")

cmp <- data.frame(
  metric = c("strong_min_ess", "midpilot_min_ess",
             "strong_max_rhat", "midpilot_max_rhat",
             "midpilot_all_pass", "wall_seconds"),
  value = c(89.83, min_ess, 1.05374, max_rhat, as.numeric(all_pass), t_total[3])
)
write.csv(cmp, "src/outputs/diagnostics/m3_regioncentered_midpilot_comparison.csv", row.names = FALSE)
log_step("mid-pilot comparison saved; NOT promoting anything")
