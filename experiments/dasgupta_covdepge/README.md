# Public BRCA covdepGE example

This experiment reproduces the authors' public TCGA/BRCA package example for `covdepGE` 1.0.1. It is not the exact Dasgupta et al. (2023) application dataset: the paper used eight proteins with FOXC2, while this example uses four RPPA nodes with FOXO3a.

## Files

- `01_brca_example.qmd`: plot-focused report that validates and reuses the saved fit.
- `brca_helpers.R`: shared path resolution, strict input audit, and cache validation.
- `install_dependencies.R`: project-local package installation, including the CRAN-archive compatibility pin.
- `run_brca_fit.R`: sequential fit, warning capture, saved bundle, and read-back verification.
- `../../data/brca/`: prepared inputs and copied public source data.
- `../../results/dasgupta_covdepge/`: saved fit bundle, text summary, and report-derived CSV/PNG artifacts.

## Run from the project root

PowerShell commands for the toolchain detected on this machine:

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' --vanilla experiments/dasgupta_covdepge/install_dependencies.R
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' --vanilla experiments/dasgupta_covdepge/run_brca_fit.R
& 'C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe' render experiments/dasgupta_covdepge/01_brca_example.qmd --to html
```

The rendered report is `01_brca_example.html` beside the QMD. The fit script skips computation only when the saved result matches both input checksums, all settings, and the installed `covdepGE` version.

The report reuses the saved fit to show all six edge-inclusion probabilities against the actual FOXO3a covariate and each sample's estimated graph ID against FOXO3a. Rendering writes tidy probability and graph-assignment CSVs plus PNG copies of both plots under `../../results/dasgupta_covdepge/`. The original unique-graph heatmaps remain in the report; their FOXO3a ranges are minimum/maximum summaries of assigned samples, not continuous interval boundaries.

`covdepGE` is no longer available as a current CRAN binary for R 4.5. The installer therefore uses the unmodified CRAN-archive `covdepGE` 1.0.1 source and pins `RcppArmadillo` 0.11.2.4.0, its September 2022-era C++11-compatible dependency. Rtools is required to rebuild these two archived sources.
