library(coda)

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

log_step("remapping posterior_m3_u.rds columns from permuted to original country IDs")

jd_orig <- readRDS("src/outputs/model_objects/jags_data_hier.rds")
df_cr <- unique(data.frame(country = jd_orig$country, region = jd_orig$region))
df_cr <- df_cr[order(df_cr$country), ]
stopifnot(nrow(df_cr) == jd_orig$C)
old_country_region <- as.integer(df_cr$region)

perm <- order(old_country_region, seq_len(jd_orig$C))
new_of_old <- integer(jd_orig$C)
new_of_old[perm] <- seq_len(jd_orig$C)

stopifnot(all(sort(new_of_old) == seq_len(jd_orig$C)))

s_u <- readRDS("src/outputs/model_objects/posterior_m3_u.rds")
C <- jd_orig$C
stopifnot(ncol(s_u[[1]]) == C)

cols_new <- paste0("u[", 1:C, "]")
stopifnot(all(cols_new %in% colnames(s_u[[1]])))

pick_cols <- new_of_old

s_u_orig <- lapply(s_u, function(mcm) {
  m <- as.matrix(mcm)[, cols_new, drop = FALSE][, pick_cols, drop = FALSE]
  colnames(m) <- paste0("u[", 1:C, "]")
  mcmc(m, start = start(mcm), end = end(mcm), thin = thin(mcm))
})
s_u_orig <- as.mcmc.list(s_u_orig)

backup <- "src/outputs/model_objects/posterior_m3_u_permuted_newIDs.rds"
if (!file.exists(backup)) {
  file.copy("src/outputs/model_objects/posterior_m3_u.rds", backup)
  log_step(sprintf("backed up permuted-IDs version -> %s", backup))
}

saveRDS(s_u_orig, "src/outputs/model_objects/posterior_m3_u.rds")
log_step("posterior_m3_u.rds: columns now indexed by ORIGINAL country_id (1..180)")

cat("\nsanity: compare mean u for first 5 original countries\n")
orig_means <- colMeans(do.call(rbind, lapply(s_u_orig, as.matrix)))[1:5]
cat(sprintf("  original c=1..5: %s\n", paste(round(orig_means, 4), collapse = ", ")))
