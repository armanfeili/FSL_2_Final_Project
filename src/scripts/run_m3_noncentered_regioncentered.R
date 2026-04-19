library(rjags)
library(coda)

set.seed(2026)

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

jd <- readRDS("src/outputs/model_objects/jags_data_hier.rds")

df_cr <- unique(data.frame(country = jd$country, region = jd$region))
df_cr <- df_cr[order(df_cr$country), ]
stopifnot(nrow(df_cr) == jd$C)
stopifnot(all(df_cr$country == seq_len(jd$C)))

country_region <- as.integer(df_cr$region)
n_country_region <- as.integer(tabulate(country_region, nbins = jd$R))
stopifnot(all(n_country_region > 0))

region_mat <- matrix(0L, nrow = jd$R, ncol = jd$C)
for (c in seq_len(jd$C)) region_mat[country_region[c], c] <- 1L
stopifnot(all(rowSums(region_mat) == n_country_region))

jd2 <- c(
  jd,
  list(
    country_region = country_region,
    n_country_region = n_country_region,
    region_mat = region_mat
  )
)

log_step(sprintf("region-centered M3 data extended: C=%d R=%d n_country_region=(%s)",
  jd$C, jd$R, paste(n_country_region, collapse = ",")))

log_step("Stage 0/5: pilot compile (4ch, adapt=200, burn=200, iter=200)")
m_pilot <- jags.model(
  "src/models/model3_noncentered_regioncentered.jags",
  data = jd2,
  n.chains = 4,
  n.adapt = 200,
  quiet = TRUE
)
update(m_pilot, 200, progress.bar = "none")
s_pilot <- coda.samples(m_pilot, c("beta0", "sigma_u"), 200, progress.bar = "none")
stopifnot(all(is.finite(as.matrix(s_pilot))))
log_step("Stage 0/5: pilot OK (samples finite)")
rm(m_pilot, s_pilot)

log_step("Stage 1/5: compiling + adapting (n.adapt=1000, 4 chains)")
t3 <- system.time({
  m3 <- jags.model(
    "src/models/model3_noncentered_regioncentered.jags",
    data = jd2,
    n.chains = 4,
    n.adapt = 1000,
    quiet = TRUE
  )
  log_step("Stage 1/5: adapt complete")

  log_step("Stage 2/5: burn-in 8000 iterations")
  update(m3, 8000, progress.bar = "none")
  log_step("Stage 2/5: burn-in complete")

  log_step("Stage 3/5: sampling 10000 iterations (globals)")
  s3_glob <- coda.samples(m3, c("beta0", "beta", "gamma", "phi", "sigma_u"), 10000, progress.bar = "none")
  log_step("Stage 3/5: globals sampled")

  log_step("Stage 4/5: saving globals posterior (region-centered)")
  saveRDS(s3_glob, "src/outputs/model_objects/posterior_m3_noncentered_regioncentered.rds")
  log_step("Stage 4/5: globals saved")

  log_step("Stage 5/5: sampling u (country random effects)")
  s3_u <- coda.samples(m3, c("u"), 10000, progress.bar = "none")
  saveRDS(s3_u, "src/outputs/model_objects/posterior_m3_noncentered_regioncentered_u.rds")
  log_step("Stage 5/5: u saved")
})

log_step(sprintf("M3 region-centered fit complete in %.1f sec", t3[3]))

s <- readRDS("src/outputs/model_objects/posterior_m3_noncentered_regioncentered.rds")
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

write.csv(tab, "src/outputs/diagnostics/m3_noncentered_regioncentered_diagnostics_summary.csv", row.names = FALSE)

core <- intersect(
  c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]",
    "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]",
    "phi", "sigma_u"),
  colnames(as.matrix(s))
)

png("src/outputs/figures/m3_noncentered_regioncentered_trace_density_core.png", width = 1400, height = 900, res = 140)
plot(s[, core])
dev.off()

png("src/outputs/figures/m3_noncentered_regioncentered_autocorr_core.png", width = 1400, height = 900, res = 140)
autocorr.plot(s[, core])
dev.off()

old <- read.csv("src/outputs/diagnostics/m3_diagnostics_summary.csv", stringsAsFactors = FALSE)
key <- c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]",
         "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]",
         "phi", "sigma_u")
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
  metric = c("old_min_ess", "regioncentered_min_ess",
             "old_max_rhat", "regioncentered_max_rhat",
             "regioncentered_all_pass"),
  value = c(old_min, nc_min, old_rmax, nc_rmax, nc_all)
)
write.csv(comparison, "src/outputs/diagnostics/m3_noncentered_regioncentered_comparison.csv", row.names = FALSE)

log_step(sprintf("M3 region-centered summary: min ESS=%.1f  max Rhat=%.4f  all_pass=%s",
  nc_min, nc_rmax, nc_all))

rds_glob <- "src/outputs/model_objects/posterior_m3_noncentered_regioncentered.rds"
rds_u <- "src/outputs/model_objects/posterior_m3_noncentered_regioncentered_u.rds"

if (nc_all && file.exists(rds_glob) && file.exists(rds_u)) {
  file.copy(rds_glob, "src/outputs/model_objects/posterior_m3.rds", overwrite = TRUE)
  file.copy(rds_u, "src/outputs/model_objects/posterior_m3_u.rds", overwrite = TRUE)
  file.copy(
    "src/outputs/diagnostics/m3_noncentered_regioncentered_diagnostics_summary.csv",
    "src/outputs/diagnostics/m3_diagnostics_summary.csv", overwrite = TRUE
  )
  file.copy(
    "src/outputs/figures/m3_noncentered_regioncentered_trace_density_core.png",
    "src/outputs/figures/m3_trace_density_core.png", overwrite = TRUE
  )
  file.copy(
    "src/outputs/figures/m3_noncentered_regioncentered_autocorr_core.png",
    "src/outputs/figures/m3_autocorr_core.png", overwrite = TRUE
  )
  log_step("M3 standard files PROMOTED from region-centered run (posterior, u, diagnostics, figures)")

  if (file.exists("src/outputs/model_objects/posterior_m3_yrep.rds")) {
    file.remove("src/outputs/model_objects/posterior_m3_yrep.rds")
    log_step("Removed stale posterior_m3_yrep.rds — regenerate from promoted fit before Phase 10")
  }
} else {
  log_step("M3 region-centered NOT promoted (diagnostics did not pass or files missing). posterior_m3.rds UNCHANGED.")
}
