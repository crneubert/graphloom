find_graphloom_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)

  repeat {
    if (file.exists(file.path(current, "README.md")) &&
        dir.exists(file.path(current, ".git"))) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the graphloom project root.", call. = FALSE)
    }
    current <- parent
  }
}

brca_paths <- function(project_root = find_graphloom_root()) {
  list(
    project_root = project_root,
    local_library = file.path(project_root, ".Rlib"),
    input = file.path(project_root, "data", "brca", "covdepge_brca_example.rds"),
    raw = file.path(project_root, "data", "brca", "BRCA.RPPA.rda"),
    result = file.path(project_root, "results", "dasgupta_covdepge", "brca_covdepge_fit.rds"),
    summary = file.path(project_root, "results", "dasgupta_covdepge", "fit-summary.txt")
  )
}

brca_fit_settings <- function() {
  list(
    seed = 20261007L,
    parallel = FALSE,
    function_call = "covdepGE::covdepGE(X, z, parallel = FALSE)",
    expected_covdepGE_version = "1.0.1"
  )
}

audit_brca_inputs <- function(input_path, raw_path) {
  expected_names <- c("sample_id", "X", "z", "provenance")
  expected_variables <- c(
    "STAT3_pY705",
    "E-Cadherin",
    "N-Cadherin",
    "NF-kB-p65_pS536"
  )

  prepared <- readRDS(input_path)
  source_environment <- new.env(parent = emptyenv())
  loaded_names <- load(raw_path, envir = source_environment)

  checks <- c(
    prepared_fields = identical(names(prepared), expected_names),
    numeric_matrix = is.matrix(prepared[["X"]]) && is.numeric(prepared[["X"]]),
    expected_dimensions = identical(dim(prepared[["X"]]), c(410L, 4L)),
    expected_variables = identical(colnames(prepared[["X"]]), expected_variables),
    covariate_length = is.numeric(prepared[["z"]]) && length(prepared[["z"]]) == 410L,
    sample_id_length = is.character(prepared[["sample_id"]]) && length(prepared[["sample_id"]]) == 410L,
    finite_measurements = all(is.finite(prepared[["X"]])) && all(is.finite(prepared[["z"]])),
    no_missing_values = !anyNA(prepared[["X"]]) && !anyNA(prepared[["z"]]) && !anyNA(prepared[["sample_id"]]),
    unique_sample_ids = !anyDuplicated(prepared[["sample_id"]]),
    raw_object = identical(loaded_names, "BRCA.RPPA")
  )

  if (isTRUE(checks[["raw_object"]])) {
    raw <- source_environment[["BRCA.RPPA"]]
    required_columns <- c("bcr_patient_barcode", expected_variables, "FOXO3a")
    checks <- c(
      checks,
      raw_dimensions = identical(dim(raw), c(410L, 143L)),
      raw_columns = all(required_columns %in% names(raw)),
      sample_order = identical(as.character(raw[["bcr_patient_barcode"]]), prepared[["sample_id"]]),
      measurements_match_raw = identical(
        unname(as.matrix(raw[, expected_variables, drop = FALSE])),
        unname(prepared[["X"]])
      ),
      covariate_matches_raw = identical(unname(raw[["FOXO3a"]]), unname(prepared[["z"]]))
    )
  }

  if (!all(checks)) {
    failed <- paste(names(checks)[!checks], collapse = ", ")
    stop("BRCA input audit failed: ", failed, call. = FALSE)
  }

  X <- prepared[["X"]]
  rownames(X) <- prepared[["sample_id"]]

  audit_table <- data.frame(
    Check = c(
      "Samples",
      "Network variables",
      "Node labels",
      "FOXO3a alignment",
      "Finite values",
      "Missing values",
      "Duplicate sample IDs",
      "Public source match"
    ),
    Result = c(
      nrow(X),
      ncol(X),
      paste(colnames(X), collapse = "; "),
      "410 values in source sample order",
      "All X and FOXO3a values finite",
      "None",
      "None",
      "Prepared values and IDs exactly match BRCA.RPPA.rda"
    ),
    Status = rep("Pass", 8L),
    check.names = FALSE
  )

  list(
    X = X,
    z = prepared[["z"]],
    sample_id = prepared[["sample_id"]],
    provenance = prepared[["provenance"]],
    audit = audit_table,
    input_md5 = unname(tools::md5sum(input_path)),
    raw_md5 = unname(tools::md5sum(raw_path))
  )
}

brca_result_is_current <- function(bundle, inputs, settings) {
  is.list(bundle) &&
    inherits(bundle[["fit"]], "covdepGE") &&
    identical(bundle[["metadata"]][["input_md5"]], inputs[["input_md5"]]) &&
    identical(bundle[["metadata"]][["raw_md5"]], inputs[["raw_md5"]]) &&
    identical(bundle[["settings"]], settings) &&
    identical(
      bundle[["metadata"]][["covdepGE_version"]],
      as.character(utils::packageVersion("covdepGE"))
    )
}
