library(rjags)
library(coda)

set.seed(2026)

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

jd <- readRDS("src/outputs/model_objects/jags_data_hier.rds")
log_step("M3 non-centered EXTENDED (4ch, adapt=1000, burnin=4000, iter=6000, no Y_rep)")

t3 <- system.time({
  log_step("Stage 1/4: compiling + adapting (n.adapt=1000, 4 chains)")
  m3 <- jags.model(
    "src/models/model3_noncentered.jags",
    data = jd,
    n.chains = 4,
    n.adapt = 1000,
    quiet = TRUE
  )
  log_step("Stage 1/4: adapt complete")

  log_step("Stage 2/4: burn-in 4000 iterations")
  update(m3, 4000, progress.bar = "none")
  log_step("Stage 2/4: burn-in complete")

  log_step("Stage 3/4: sampling 6000 iterations (beta0, beta, gamma, phi, sigma_u)")
  s3_nc <- coda.samples(m3, c("beta0", "beta", "gamma", "phi", "sigma_u"), 6000, progress.bar = "none")
  log_step("Stage 3/4: sampling complete")

  log_step("Stage 4/4: saving posterior to posterior_m3_noncentered_extended.rds")
  saveRDS(s3_nc, "src/outputs/model_objects/posterior_m3_noncentered_extended.rds")
  log_step("Stage 4/4: save complete")
})

writeLines(
  c(
    paste("timestamp:", as.character(Sys.time())),
    "model: M3 non-centered-extended",
    "stage: Y_rep sampling",
    "status: skipped",
    "note: parameter diagnostics prioritized; Y_rep retained from earlier centered fit"
  ),
  "src/outputs/diagnostics/m3_noncentered_extended_yrep_status.txt"
)

log_step(sprintf("M3 non-centered-extended done in %.1f sec", t3[3]))

s <- readRDS("src/outputs/model_objects/posterior_m3_noncentered_extended.rds")
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

write.csv(tab, "src/outputs/diagnostics/m3_noncentered_extended_diagnostics_summary.csv", row.names = FALSE)

core <- intersect(c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]", "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]", "phi", "sigma_u"), colnames(as.matrix(s)))

png("src/outputs/figures/m3_noncentered_extended_trace_density_core.png", width = 1400, height = 900, res = 140)
plot(s[, core])
dev.off()

png("src/outputs/figures/m3_noncentered_extended_autocorr_core.png", width = 1400, height = 900, res = 140)
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
  metric = c("old_min_ess", "ext_min_ess", "old_max_rhat", "ext_max_rhat", "ext_all_pass"),
  value = c(old_min, nc_min, old_rmax, nc_rmax, nc_all)
)
write.csv(comparison, "src/outputs/diagnostics/m3_noncentered_extended_comparison.csv", row.names = FALSE)

log_step(sprintf("M3 extended summary: min ESS=%.1f  max Rhat=%.4f  all_pass=%s", nc_min, nc_rmax, nc_all))

if (nc_all && (nc_min > old_min || nc_rmax <= old_rmax)) {
  file.copy(
    "src/outputs/model_objects/posterior_m3_noncentered_extended.rds",
    "src/outputs/model_objects/posterior_m3.rds",
    overwrite = TRUE
  )

  file.copy(
    "src/outputs/diagnostics/m3_noncentered_extended_diagnostics_summary.csv",
    "src/outputs/diagnostics/m3_diagnostics_summary.csv",
    overwrite = TRUE
  )

  if (file.exists("src/outputs/figures/m3_noncentered_extended_trace_density_core.png")) {
    file.copy(
      "src/outputs/figures/m3_noncentered_extended_trace_density_core.png",
      "src/outputs/figures/m3_trace_density_core.png",
      overwrite = TRUE
    )
  }

  if (file.exists("src/outputs/figures/m3_noncentered_extended_autocorr_core.png")) {
    file.copy(
      "src/outputs/figures/m3_noncentered_extended_autocorr_core.png",
      "src/outputs/figures/m3_autocorr_core.png",
      overwrite = TRUE
    )
  }

  log_step("M3 standard files PROMOTED from non-centered-extended run")
} else {
  log_step("M3 non-centered-extended kept as comparison only (NOT promoted)")
}
