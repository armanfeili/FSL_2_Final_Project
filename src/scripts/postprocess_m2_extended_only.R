library(coda)

if (!file.exists("src/outputs/model_objects/posterior_m2_extended.rds")) {
  stop("Missing src/outputs/model_objects/posterior_m2_extended.rds")
}

s <- readRDS("src/outputs/model_objects/posterior_m2_extended.rds")
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

write.csv(tab, "src/outputs/diagnostics/m2_extended_diagnostics_summary.csv", row.names = FALSE)

core <- intersect(c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]", "phi"), colnames(as.matrix(s)))

png("src/outputs/figures/m2_extended_trace_density_core.png", width = 1400, height = 900, res = 140)
plot(s[, core])
dev.off()

png("src/outputs/figures/m2_extended_autocorr_core.png", width = 1400, height = 900, res = 140)
autocorr.plot(s[, core])
dev.off()

old <- read.csv("src/outputs/diagnostics/m2_diagnostics_summary.csv", stringsAsFactors = FALSE)
key <- c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]", "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]", "phi")
oldk <- old[old$parameter %in% key, ]
extk <- tab[tab$parameter %in% key, ]

old_nonvarying <- if ("nonvarying" %in% names(oldk)) oldk$nonvarying else rep(FALSE, nrow(oldk))
ext_nonvarying <- if ("nonvarying" %in% names(extk)) extk$nonvarying else rep(FALSE, nrow(extk))

old_min <- min(oldk$ess[!old_nonvarying], na.rm = TRUE)
ext_min <- min(extk$ess[!ext_nonvarying], na.rm = TRUE)
old_rmax <- max(oldk$rhat[!old_nonvarying], na.rm = TRUE)
ext_rmax <- max(extk$rhat[!ext_nonvarying], na.rm = TRUE)

ext_all <- all(extk$ess[!ext_nonvarying] >= 400, na.rm = TRUE) &&
  all(extk$rhat[!ext_nonvarying] <= 1.05, na.rm = TRUE)

comparison <- data.frame(
  metric = c("old_min_ess", "ext_min_ess", "old_max_rhat", "ext_max_rhat", "ext_all_pass"),
  value = c(old_min, ext_min, old_rmax, ext_rmax, ext_all)
)
write.csv(comparison, "src/outputs/diagnostics/m2_extension_comparison.csv", row.names = FALSE)

if (ext_all && (ext_min > old_min || ext_rmax <= old_rmax)) {
  file.copy(
    "src/outputs/model_objects/posterior_m2_extended.rds",
    "src/outputs/model_objects/posterior_m2.rds",
    overwrite = TRUE
  )

  if (file.exists("src/outputs/model_objects/posterior_m2_extended_yrep.rds")) {
    file.copy(
      "src/outputs/model_objects/posterior_m2_extended_yrep.rds",
      "src/outputs/model_objects/posterior_m2_yrep.rds",
      overwrite = TRUE
    )
  }

  file.copy(
    "src/outputs/diagnostics/m2_extended_diagnostics_summary.csv",
    "src/outputs/diagnostics/m2_diagnostics_summary.csv",
    overwrite = TRUE
  )

  if (file.exists("src/outputs/figures/m2_extended_trace_density_core.png")) {
    file.copy(
      "src/outputs/figures/m2_extended_trace_density_core.png",
      "src/outputs/figures/m2_trace_density_core.png",
      overwrite = TRUE
    )
  }

  if (file.exists("src/outputs/figures/m2_extended_autocorr_core.png")) {
    file.copy(
      "src/outputs/figures/m2_extended_autocorr_core.png",
      "src/outputs/figures/m2_autocorr_core.png",
      overwrite = TRUE
    )
  }

  message("M2 standard files promoted from extended run")
} else {
  message("M2 extended kept as comparison only (not promoted)")
}

message("M2ext min ESS: ", min(tab$ess[!tab$nonvarying], na.rm = TRUE),
        " | M2ext max Rhat: ", max(tab$rhat[!tab$nonvarying], na.rm = TRUE))
