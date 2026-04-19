library(rjags)
library(coda)

set.seed(2026)

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

log_step("Smoke test: region-centered M3, contiguous-region country indexing")

jd <- readRDS("src/outputs/model_objects/jags_data_hier.rds")

df_cr <- unique(data.frame(country = jd$country, region = jd$region))
df_cr <- df_cr[order(df_cr$country), ]
stopifnot(nrow(df_cr) == jd$C)
stopifnot(all(df_cr$country == seq_len(jd$C)))

old_country_region <- as.integer(df_cr$region)

perm <- order(old_country_region, seq_len(jd$C))
new_of_old <- integer(jd$C)
new_of_old[perm] <- seq_len(jd$C)

country_region <- old_country_region[perm]
stopifnot(!is.unsorted(country_region))

n_country_region <- as.integer(tabulate(country_region, nbins = jd$R))
stopifnot(all(n_country_region > 0))
region_end <- as.integer(cumsum(n_country_region))
region_start <- as.integer(c(1L, head(region_end, -1) + 1L))
stopifnot(all(region_end - region_start + 1L == n_country_region))

row_country_new <- as.integer(new_of_old[jd$country])

jd_rc <- list(
  N = jd$N,
  Y = jd$Y,
  n = jd$n,
  X = jd$X,
  n_pred = jd$n_pred,
  region = jd$region,
  R = jd$R,
  country = row_country_new,
  C = jd$C,
  country_region = country_region,
  n_country_region = n_country_region,
  region_start = region_start,
  region_end = region_end
)

saveRDS(jd_rc, "src/outputs/model_objects/jags_data_hier_regioncentered.rds")
log_step(sprintf("extended data saved: R=%d C=%d, region_start=(%s), region_end=(%s), n_country_region=(%s)",
  jd$R, jd$C,
  paste(region_start, collapse = ","),
  paste(region_end, collapse = ","),
  paste(n_country_region, collapse = ",")))

log_step("Smoke: 1 chain, adapt=50, burn=50, sample=50, monitor globals only")
t_compile <- system.time({
  m <- jags.model(
    "src/models/model3_noncentered_regioncentered.jags",
    data = jd_rc,
    n.chains = 1,
    n.adapt = 50,
    quiet = TRUE
  )
})
log_step(sprintf("compile+adapt(50) done in %.2f sec", t_compile[3]))

t_burn <- system.time(update(m, 50, progress.bar = "none"))
log_step(sprintf("burn-in(50) done in %.2f sec", t_burn[3]))

t_samp <- system.time({
  s <- coda.samples(m, c("beta0", "beta", "gamma", "phi", "sigma_u"), 50, progress.bar = "none")
})
log_step(sprintf("sample(50) done in %.2f sec", t_samp[3]))

mat <- as.matrix(s)
all_finite <- all(is.finite(mat))
param_names <- colnames(mat)

cat("\n=== SMOKE RESULTS ===\n")
cat(sprintf("compile+adapt time: %.2f sec\n", t_compile[3]))
cat(sprintf("burn-in time:       %.2f sec\n", t_burn[3]))
cat(sprintf("sampling time:      %.2f sec\n", t_samp[3]))
cat(sprintf("all draws finite:   %s\n", all_finite))
cat(sprintf("n params monitored: %d\n", length(param_names)))
cat(sprintf("param names:        %s\n", paste(param_names, collapse = ", ")))
cat(sprintf("expected globals:   beta0, beta[1..4], gamma[1..6], phi, sigma_u = 13 names\n"))
cat("\n=== SMOKE END ===\n")
