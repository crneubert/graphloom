helper_candidates <- c(
  file.path(getwd(), "experiments", "dasgupta_covdepge", "brca_helpers.R"),
  file.path(getwd(), "brca_helpers.R")
)
helper_path <- helper_candidates[file.exists(helper_candidates)][1]
if (is.na(helper_path)) stop("Could not locate brca_helpers.R.", call. = FALSE)
source(helper_path)

paths <- brca_paths()
.libPaths(c(paths[["local_library"]], .libPaths()))

if (!requireNamespace("covdepGE", quietly = TRUE)) {
  stop("covdepGE is not installed. Run install_dependencies.R first.", call. = FALSE)
}

inputs <- audit_brca_inputs(paths[["input"]], paths[["raw"]])
settings <- brca_fit_settings()

if (file.exists(paths[["result"]])) {
  existing <- readRDS(paths[["result"]])
  if (brca_result_is_current(existing, inputs, settings)) {
    cat("Current fit already exists at", paths[["result"]], "\n")
    quit(save = "no", status = 0L)
  }
}

X <- inputs[["X"]]
z <- inputs[["z"]]
set.seed(settings[["seed"]])
fit_warnings <- character()

timing <- system.time({
  fit <- withCallingHandlers(
    covdepGE::covdepGE(X, z, parallel = FALSE),
    warning = function(warning) {
      fit_warnings <<- c(fit_warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )
})

fit_warnings <- unique(fit_warnings)
metadata <- list(
  input_md5 = inputs[["input_md5"]],
  raw_md5 = inputs[["raw_md5"]],
  covdepGE_version = as.character(packageVersion("covdepGE")),
  RcppArmadillo_version = as.character(packageVersion("RcppArmadillo")),
  R_version = R.version.string,
  elapsed_seconds = unname(timing[["elapsed"]]),
  completed_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
  warnings = fit_warnings,
  session_info = capture.output(sessionInfo())
)

bundle <- list(
  fit = fit,
  inputs = inputs[c("X", "z", "sample_id", "provenance", "audit")],
  settings = settings,
  metadata = metadata
)

dir.create(dirname(paths[["result"]]), recursive = TRUE, showWarnings = FALSE)
saveRDS(bundle, paths[["result"]], version = 3)

warning_summary <- if (length(fit_warnings)) paste(fit_warnings, collapse = " | ") else "None"
summary_lines <- c(
  "Public TCGA/BRCA covdepGE package example",
  paste("Completed:", metadata[["completed_at"]]),
  paste("Call:", settings[["function_call"]]),
  paste("Seed:", settings[["seed"]]),
  paste("Elapsed seconds:", format(metadata[["elapsed_seconds"]], digits = 6)),
  paste("covdepGE version:", metadata[["covdepGE_version"]]),
  paste("RcppArmadillo version:", metadata[["RcppArmadillo_version"]]),
  paste("Warnings:", warning_summary),
  paste("Input MD5:", metadata[["input_md5"]]),
  paste("Raw data MD5:", metadata[["raw_md5"]])
)
writeLines(summary_lines, paths[["summary"]])

reloaded <- readRDS(paths[["result"]])
stopifnot(
  brca_result_is_current(reloaded, inputs, settings),
  identical(reloaded[["inputs"]][["sample_id"]], inputs[["sample_id"]]),
  identical(dim(reloaded[["inputs"]][["X"]]), c(410L, 4L))
)

print(fit)
cat("\nSaved and verified:", paths[["result"]], "\n")
cat("Elapsed seconds:", format(metadata[["elapsed_seconds"]], digits = 6), "\n")
cat("Warnings:", warning_summary, "\n")
