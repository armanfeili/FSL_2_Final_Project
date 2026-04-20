library(coda)

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

set.seed(2026)

log_step("loading promoted M3 posteriors + region-centered data")
jd <- readRDS("src/outputs/model_objects/jags_data_hier_regioncentered.rds")
s_glob <- readRDS("src/outputs/model_objects/posterior_m3.rds")
s_u <- readRDS("src/outputs/model_objects/posterior_m3_u.rds")

stopifnot(length(s_glob) == length(s_u))
stopifnot(nrow(s_glob[[1]]) == nrow(s_u[[1]]))
N <- jd$N
C <- jd$C
R <- jd$R
n_pred <- jd$n_pred
n_chains <- length(s_glob)
n_iter <- nrow(s_glob[[1]])
log_step(sprintf("N=%d C=%d R=%d n_pred=%d chains=%d iter/chain=%d",
  N, C, R, n_pred, n_chains, n_iter))

THIN <- 10L
keep_idx <- seq(from = THIN, to = n_iter, by = THIN)
n_keep_per_chain <- length(keep_idx)
log_step(sprintf("thin=%d -> %d draws/chain -> %d total", THIN, n_keep_per_chain, n_keep_per_chain * n_chains))

gnames <- colnames(s_glob[[1]])
beta_cols <- paste0("beta[", 1:n_pred, "]")
gamma_cols <- paste0("gamma[", 1:R, "]")
stopifnot("beta0" %in% gnames, all(beta_cols %in% gnames), all(gamma_cols %in% gnames),
          "phi" %in% gnames, "sigma_u" %in% gnames)

u_cols <- paste0("u[", 1:C, "]")
stopifnot(all(u_cols %in% colnames(s_u[[1]])))

X <- jd$X
n_trials <- jd$n
region_row <- jd$region
country_row <- jd$country

yrep_chains <- vector("list", n_chains)

for (ch in seq_len(n_chains)) {
  log_step(sprintf("chain %d/%d: simulating %d Y_rep draws", ch, n_chains, n_keep_per_chain))
  Gmat <- as.matrix(s_glob[[ch]])[keep_idx, , drop = FALSE]
  Umat <- as.matrix(s_u[[ch]])[keep_idx, u_cols, drop = FALSE]
  beta0_v <- Gmat[, "beta0"]
  beta_m <- Gmat[, beta_cols, drop = FALSE]
  gamma_m <- Gmat[, gamma_cols, drop = FALSE]
  phi_v <- Gmat[, "phi"]

  XB_all <- X %*% t(beta_m)
  Yrep_mat <- matrix(0L, nrow = n_keep_per_chain, ncol = N)

  for (b in seq_len(n_keep_per_chain)) {
    eta <- beta0_v[b] + XB_all[, b] + gamma_m[b, region_row] + Umat[b, country_row]
    mu <- plogis(eta)
    phi_b <- phi_v[b]
    alpha <- mu * phi_b
    betp <- (1 - mu) * phi_b
    theta_rep <- rbeta(N, alpha, betp)
    theta_rep[!is.finite(theta_rep)] <- mu[!is.finite(theta_rep)]
    theta_rep <- pmin(pmax(theta_rep, 1e-12), 1 - 1e-12)
    Yrep_mat[b, ] <- rbinom(N, size = n_trials, prob = theta_rep)
  }

  colnames(Yrep_mat) <- paste0("Y_rep[", 1:N, "]")
  yrep_chains[[ch]] <- mcmc(Yrep_mat, start = 1, end = n_keep_per_chain, thin = 1)
}

yrep_list <- as.mcmc.list(yrep_chains)
out_path <- "src/outputs/model_objects/posterior_m3_yrep.rds"
saveRDS(yrep_list, out_path)
log_step(sprintf("saved %s: %d chains x %d draws x %d obs",
  out_path, length(yrep_list), nrow(yrep_list[[1]]), ncol(yrep_list[[1]])))

Y_obs <- jd$Y
y_rep_all <- do.call(rbind, lapply(yrep_list, as.matrix))
pmean <- colMeans(y_rep_all)
psd <- apply(y_rep_all, 2, sd)
Tobs_mean <- mean(Y_obs)
Trep_means <- rowMeans(y_rep_all)
p_mean <- mean(Trep_means >= Tobs_mean)
cat(sprintf("\n=== Y_rep sanity ===\nobserved mean Y = %.2f; posterior mean of Y_rep column-mean = %.2f\n",
  Tobs_mean, mean(Trep_means)))
cat(sprintf("Bayesian p-value on T=mean(Y): %.3f (near 0.5 indicates no overall bias)\n", p_mean))
cat(sprintf("first 5 obs: Y=%s  E[Y_rep]=%s\n",
  paste(Y_obs[1:5], collapse=","),
  paste(sprintf("%.1f", pmean[1:5]), collapse=",")))
log_step("Y_rep regeneration complete")
