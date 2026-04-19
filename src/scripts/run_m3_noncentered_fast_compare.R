library(rjags)
library(coda)

set.seed(2026)

jd <- readRDS("src/outputs/model_objects/jags_data_hier.rds")
cat("M3 non-centered-fast MCMC (2ch, burnin=4000, iter=4000, no Y_rep)...\n")

t3 <- system.time({
  m3 <- jags.model(
    "src/models/model3_noncentered.jags",
    data = jd,
    n.chains = 2,
    n.adapt = 1000,
    quiet = TRUE
  )

  update(m3, 4000, progress.bar = "text")

  s3_nc <- coda.samples(m3, c("beta0", "beta", "gamma", "phi", "sigma_u"), 4000)
  saveRDS(s3_nc, "src/outputs/model_objects/posterior_m3_noncentered_fast.rds")
})

writeLines(
  c(
    paste("timestamp:", as.character(Sys.time())),
    "model: M3 non-centered-fast",
    "stage: Y_rep sampling",
    "status: skipped",
    "note: intentionally skipped to prioritize parameter diagnostics; previous M3 Y_rep remains available"
  ),
  "src/outputs/diagnostics/m3_noncentered_fast_yrep_status.txt"
)

cat("M3 non-centered-fast done in", round(t3[3], 1), "sec\n")

s <- readRDS("src/outputs/model_objects/posterior_m3_noncentered_fast.rds")
sm <- summary(s)
params <- rownames(sm$statistics)
varv <- apply(as.matrix(s), 2, var)

calc_rhat <- function(p) {
  tryCatch(
    as.numeric(gelman.diag(
      s[, p, drop = FALSE],
      autoburnin = FALSE,
      multivariate = FALSE
    )$psrf[1, 1]),
    error = function(e) NA_real_
  )
}

rhat <- sapply(params, calc_rhat)
ess <- as.numeric(effectiveSize(s))
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

write.csv(tab, "src/outputs/diagnostics/m3_noncentered_fast_diagnostics_summary.csv", row.names = FALSE)

core <- intersect(c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]", "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]", "phi", "sigma_u"), colnames(as.matrix(s)))

png("src/outputs/figures/m3_noncentered_fast_trace_density_core.png", width = 1400, height = 900, res = 140)
plot(s[, core])
dev.off()

png("src/outputs/figures/m3_noncentered_fast_autocorr_core.png", width = 1400, height = 900, res = 140)
autocorr.plot(s[, core])
dev.off()

old <- read.csv("src/outputs/diagnostics/m3_diagnostics_summary.csv", stringsAsFactors = FALSE)
key <- c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]", "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]", "phi", "sigma_u")
oldk <- old[old$parameter %in% key, ]
nck <- tab[tab$parameter %in% key, ]

old_nonvarying <- if ("nonvarying" %in% names(oldk)) oldk$nonvarying else rep(FALSE, nrow(oldk))
nc_nonvarying <- if ("nonvarying" %in% names(nck)) nck$nonvarying else rep(FALSE, nrow(nck))

old_min <- min(oldk$ess[!old_nonvarying], na.rm = TRUE)
nc_min <- min(nck$ess[!nc_nonvarying], na.rm = TRUE)
old_rmax <- max(oldk$rhat[!old_nonvarying], na.rm = TRUE)
nc_rmax <- max(nck$rhat[!nc_nonvarying], na.rm = TRUE)

nc_all <- all(nck$ess[!nc_nonvarying] >= 400, na.rm = TRUE) &&
  all(nck$rhat[!nc_nonvarying] <= 1.05, na.rm = TRUE)

comparison <- data.frame(
  metric = c("old_min_ess", "nc_min_ess", "old_max_rhat", "nc_max_rhat", "nc_all_pass"),
  value = c(old_min, nc_min, old_rmax, nc_rmax, nc_all)
)
write.csv(comparison, "src/outputs/diagnostics/m3_noncentered_fast_comparison.csv", row.names = FALSE)

if (nc_all && (nc_min > old_min || nc_rmax <= old_rmax)) {
  file.copy(
    "src/outputs/model_objects/posterior_m3_noncentered_fast.rds",
    "src/outputs/model_objects/posterior_m3.rds",
    overwrite = TRUE
  )

  file.copy(
    "src/outputs/diagnostics/m3_noncentered_fast_diagnostics_summary.csv",
    "src/outputs/diagnostics/m3_diagnostics_summary.csv",
    overwrite = TRUE
  )

  if (file.exists("src/outputs/figures/m3_noncentered_fast_trace_density_core.png")) {
    file.copy(
      "src/outputs/figures/m3_noncentered_fast_trace_density_core.png",
      "src/outputs/figures/m3_trace_density_core.png",
      overwrite = TRUE
    )
  }

  if (file.exists("src/outputs/figures/m3_noncentered_fast_autocorr_core.png")) {
    file.copy(
      "src/outputs/figures/m3_noncentered_fast_autocorr_core.png",
      "src/outputs/figures/m3_autocorr_core.png",
      overwrite = TRUE
    )
  }

  message("M3 standard files promoted from non-centered-fast run")
} else {
  message("M3 non-centered-fast kept as comparison only (not promoted)")
}

message("M3nc_fast min ESS: ", min(tab$ess[!tab$nonvarying], na.rm = TRUE),
        " | M3nc max Rhat: ", max(tab$rhat[!tab$nonvarying], na.rm = TRUE))
