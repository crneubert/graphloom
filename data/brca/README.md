# BRCA data provenance

These files support the authors' public `covdepGE` TCGA/BRCA package example. They are not the exact application dataset from Dasgupta et al. (2023).

- `BRCA.RPPA.rda` is a local copy of the public [`RTCGA.RPPA::BRCA.RPPA` data object](https://github.com/RTCGA/RTCGA.RPPA/blob/master/data/BRCA.RPPA.rda): 410 samples by 143 columns.
- `covdepge_brca_example.rds` contains the source-order sample IDs, the four example network variables, FOXO3a as a separate covariate, and a provenance note.

The four network nodes are `STAT3_pY705`, `E-Cadherin`, `N-Cadherin`, and `NF-kB-p65_pS536`. FOXO3a is the extraneous covariate and is not a fifth node.

The fit script checks dimensions, labels, order, finite values, missingness, duplicate IDs, and exact equality of every prepared value and sample ID against the copied public RDA. It stops on any discrepancy; no rows or variables are silently substituted or dropped.
