log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
  flush.console()
}

log_step("dispatcher: running Phases 9, 10, 12 of src/main.R against promoted M3 posteriors")

main_path <- "src/main.R"
stopifnot(file.exists(main_path))
main_lines <- readLines(main_path, warn = FALSE)

PHASE0_END <- 489L
PHASE_9_START <- 5529L
PHASE_9_END <- 6338L
PHASE_10_START <- 6339L
PHASE_10_END <- 7226L
PHASE_12_START <- 7227L
PHASE_12_END <- 7943L

setup_lines <- main_lines[1:PHASE0_END]
p9_lines <- main_lines[PHASE_9_START:PHASE_9_END]
p10_lines <- main_lines[PHASE_10_START:PHASE_10_END]
p12_lines <- main_lines[PHASE_12_START:PHASE_12_END]

log_step(sprintf("Phase 0 setup: %d lines", length(setup_lines)))
log_step(sprintf("Phase 9: %d lines | Phase 10: %d lines | Phase 12: %d lines",
  length(p9_lines), length(p10_lines), length(p12_lines)))

log_step("=== running Phase 0 setup ===")
eval(parse(text = paste(setup_lines, collapse = "\n")), envir = globalenv())

cat("\n\n")
log_step("=== running PHASE 9 ===")
eval(parse(text = paste(p9_lines, collapse = "\n")), envir = globalenv())

cat("\n\n")
log_step("=== running PHASE 10 ===")
eval(parse(text = paste(p10_lines, collapse = "\n")), envir = globalenv())

cat("\n\n")
log_step("=== running PHASE 12 ===")
eval(parse(text = paste(p12_lines, collapse = "\n")), envir = globalenv())

cat("\n\n")
log_step("dispatcher complete")
cat(sprintf("\n=== FINAL PHASE STATUSES ===\n"))
cat(sprintf("Phase 9  : %s\n", if (exists("PHASE_9_STATUS"))  PHASE_9_STATUS else "UNKNOWN"))
cat(sprintf("Phase 10 : %s\n", if (exists("PHASE_10_STATUS")) PHASE_10_STATUS else "UNKNOWN"))
cat(sprintf("Phase 12 : %s\n", if (exists("PHASE_12_STATUS")) PHASE_12_STATUS else "UNKNOWN"))
