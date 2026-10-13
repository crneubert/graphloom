find_graphloom_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(current, "README.md")) && dir.exists(file.path(current, ".git"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) stop("Could not locate project root.", call. = FALSE)
    current <- parent
  }
}

project_root <- find_graphloom_root()
local_library <- file.path(project_root, ".Rlib")
dir.create(local_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(local_library, .libPaths()))

repository <- "https://cloud.r-project.org"
binary_packages <- c(
  "doParallel", "foreach", "ggplot2", "glmnet", "iterators", "knitr", "latex2exp",
  "Rcpp", "reshape2", "rmarkdown"
)
missing_packages <- binary_packages[!vapply(binary_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages)) {
  install.packages(
    missing_packages,
    lib = local_library,
    repos = repository,
    dependencies = c("Depends", "Imports")
  )
}

armadillo_version <- if (requireNamespace("RcppArmadillo", quietly = TRUE)) {
  as.character(packageVersion("RcppArmadillo"))
} else {
  NA_character_
}

if (!identical(armadillo_version, "0.11.2.4.0")) {
  install.packages(
    paste0(
      repository,
      "/src/contrib/Archive/RcppArmadillo/RcppArmadillo_0.11.2.4.0.tar.gz"
    ),
    lib = local_library,
    repos = NULL,
    type = "source"
  )
}

covdepge_version <- if (requireNamespace("covdepGE", quietly = TRUE)) {
  as.character(packageVersion("covdepGE"))
} else {
  NA_character_
}

if (!identical(covdepge_version, "1.0.1")) {
  install.packages(
    paste0(
      repository,
      "/src/contrib/Archive/covdepGE/covdepGE_1.0.1.tar.gz"
    ),
    lib = local_library,
    repos = NULL,
    type = "source"
  )
}

stopifnot(
  identical(as.character(packageVersion("RcppArmadillo")), "0.11.2.4.0"),
  identical(as.character(packageVersion("covdepGE")), "1.0.1")
)

cat("Installed covdepGE", as.character(packageVersion("covdepGE")), "in", local_library, "\n")
