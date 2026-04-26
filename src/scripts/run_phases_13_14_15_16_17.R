# =============================================================================
# Dispatcher — Phases 13, 14 (frequentist arms only), 15, 16, 17
# =============================================================================
# Why this script exists:
#   Modeled on the existing src/scripts/run_phases_9_10_12.R dispatcher: it
#   sources Phase 0 setup from src/main.R, then evaluates the targeted phase
#   blocks against the locked dataset and existing posteriors.
#
#   Phases 13/14/15/16/17 are CPU-light (no MCMC except 14.3/14.4, which are
#   handled by run_phase14_bayesian_sensitivity.R). This dispatcher does NOT
#   refit M1/M2/M3 — it reads cached posterior_m{1,2,3}.rds.
#
#   Phase 14 in main.R only writes the alt JAGS files for 14.3/14.4 and does
#   not actually fit them. The Bayesian arms are handled separately by
#   run_phase14_bayesian_sensitivity.R; this dispatcher only produces the
#   frequentist arms (14.1, 14.2, 14.5) plus the summary tables.
#
#   Phase 16 in main.R writes a generic report.Rmd template with placeholder
#   sections. We *intentionally* let it run (so the abstract numbers and
#   discussion/conclusion content templates are produced), then we overwrite
#   report.Rmd separately with the version that contains the actual posterior
#   numbers — that is done outside this dispatcher.
# =============================================================================

log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

PROJECT_ROOT <- "/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project"
setwd(PROJECT_ROOT)

main_path <- "src/main.R"
stopifnot(file.exists(main_path))
main_lines <- readLines(main_path, warn = FALSE)

# Line ranges (matching the existing dispatcher's conventions)
PHASE0_END     <- 489L
PHASE_13_START <- 9293L
PHASE_13_END   <- 10108L
PHASE_14_START <- 10109L
PHASE_14_END   <- 10918L
PHASE_15_START <- 10919L
PHASE_15_END   <- 11675L
PHASE_16_START <- 11676L
PHASE_16_END   <- 12631L
PHASE_17_START <- 12632L
PHASE_17_END   <- 13476L

setup_lines <- main_lines[1:PHASE0_END]
p13_lines <- main_lines[PHASE_13_START:PHASE_13_END]
p14_lines <- main_lines[PHASE_14_START:PHASE_14_END]
p15_lines <- main_lines[PHASE_15_START:PHASE_15_END]
p16_lines <- main_lines[PHASE_16_START:PHASE_16_END]
p17_lines <- main_lines[PHASE_17_START:PHASE_17_END]

log_step(sprintf("Phase 0 setup: %d lines", length(setup_lines)))
log_step(sprintf("Phase 13: %d | Phase 14: %d | Phase 15: %d | Phase 16: %d | Phase 17: %d lines",
  length(p13_lines), length(p14_lines), length(p15_lines),
  length(p16_lines), length(p17_lines)))

log_step("=== running Phase 0 setup ===")
eval(parse(text = paste(setup_lines, collapse = "\n")), envir = globalenv())

cat("\n\n"); log_step("=== running PHASE 13 (frequentist comparison) ===")
eval(parse(text = paste(p13_lines, collapse = "\n")), envir = globalenv())

cat("\n\n"); log_step("=== running PHASE 14 (frequentist sensitivity arms 14.1/14.2/14.5; also writes alt JAGS files for 14.3/14.4) ===")
eval(parse(text = paste(p14_lines, collapse = "\n")), envir = globalenv())

cat("\n\n"); log_step("=== running PHASE 15 (manifests, appendix materials) ===")
eval(parse(text = paste(p15_lines, collapse = "\n")), envir = globalenv())

cat("\n\n"); log_step("=== running PHASE 16 (template report.Rmd, abstract numbers, content templates) ===")
eval(parse(text = paste(p16_lines, collapse = "\n")), envir = globalenv())

cat("\n\n"); log_step("=== running PHASE 17 (consistency checks, submission package) ===")
eval(parse(text = paste(p17_lines, collapse = "\n")), envir = globalenv())

cat("\n\n"); log_step("dispatcher complete")
cat(sprintf("\n=== FINAL PHASE STATUSES ===\n"))
for (ph in c(13, 14, 15, 16, 17)) {
  vname <- paste0("PHASE_", ph, "_STATUS")
  cat(sprintf("Phase %d : %s\n", ph,
              if (exists(vname)) get(vname) else "UNKNOWN"))
}
