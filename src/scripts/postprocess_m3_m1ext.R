library(coda)

diag_make <- function(s_path, csv_path, fig_td, fig_ac, core) {
  s <- readRDS(s_path)
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

  write.csv(tab, csv_path, row.names = FALSE)

  core2 <- intersect(core, colnames(as.matrix(s)))
  png(fig_td, width = 1400, height = 900, res = 140)
  plot(s[, core2])
  dev.off()

  png(fig_ac, width = 1400, height = 900, res = 140)
  autocorr.plot(s[, core2])
  dev.off()

  tab
}

required <- c(
  "src/outputs/model_objects/posterior_m3.rds",
  "src/outputs/model_objects/posterior_m1_extended.rds",
  "src/outputs/diagnostics/m1_diagnostics_summary.csv"
)

missing_files <- required[!file.exists(required)]
if (length(missing_files) > 0) {
  stop(paste("Missing required files:", paste(missing_files, collapse = ", ")))
}

m3tab <- diag_make(
  "src/outputs/model_objects/posterior_m3.rds",
  "src/outputs/diagnostics/m3_diagnostics_summary.csv",
  "src/outputs/figures/m3_trace_density_core.png",
  "src/outputs/figures/m3_autocorr_core.png",
  c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]", "phi", "sigma_u")
)

m1ext <- diag_make(
  "src/outputs/model_objects/posterior_m1_extended.rds",
  "src/outputs/diagnostics/m1_extended_diagnostics_summary.csv",
  "src/outputs/figures/m1_extended_trace_density_core.png",
  "src/outputs/figures/m1_extended_autocorr_core.png",
  c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]", "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]")
)

old <- read.csv("src/outputs/diagnostics/m1_diagnostics_summary.csv", stringsAsFactors = FALSE)
key <- c("beta0", "beta[1]", "beta[2]", "beta[3]", "beta[4]", "gamma[2]", "gamma[3]", "gamma[4]", "gamma[5]", "gamma[6]")
oldk <- old[old$parameter %in% key, ]
extk <- m1ext[m1ext$parameter %in% key, ]

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
write.csv(comparison, "src/outputs/diagnostics/m1_extension_comparison.csv", row.names = FALSE)

if (ext_all && (ext_min > old_min || ext_rmax <= old_rmax)) {
  file.copy(
    "src/outputs/model_objects/posterior_m1_extended.rds",
    "src/outputs/model_objects/posterior_m1.rds",
    overwrite = TRUE
  )

  if (file.exists("src/outputs/model_objects/posterior_m1_extended_yrep.rds")) {
    file.copy(
      "src/outputs/model_objects/posterior_m1_extended_yrep.rds",
      "src/outputs/model_objects/posterior_m1_yrep.rds",
      overwrite = TRUE
    )
  }

  file.copy(
    "src/outputs/diagnostics/m1_extended_diagnostics_summary.csv",
    "src/outputs/diagnostics/m1_diagnostics_summary.csv",
    overwrite = TRUE
  )

  if (file.exists("src/outputs/figures/m1_extended_trace_density_core.png")) {
    file.copy(
      "src/outputs/figures/m1_extended_trace_density_core.png",
      "src/outputs/figures/m1_trace_density_core.png",
      overwrite = TRUE
    )
  }

  if (file.exists("src/outputs/figures/m1_extended_autocorr_core.png")) {
    file.copy(
      "src/outputs/figures/m1_extended_autocorr_core.png",
      "src/outputs/figures/m1_autocorr_core.png",
      overwrite = TRUE
    )
  }

  message("M1 standard files promoted from extended run")
} else {
  message("M1 extended kept as comparison only (not promoted)")
}

message("M3 min ESS: ", min(m3tab$ess[!m3tab$nonvarying], na.rm = TRUE),
        " | M3 max Rhat: ", max(m3tab$rhat[!m3tab$nonvarying], na.rm = TRUE))
message("M1ext min ESS: ", min(m1ext$ess[!m1ext$nonvarying], na.rm = TRUE),
        " | M1ext max Rhat: ", max(m1ext$rhat[!m1ext$nonvarying], na.rm = TRUE))
