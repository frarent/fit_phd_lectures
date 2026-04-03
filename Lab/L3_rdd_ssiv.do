* ============================================================================
* Lecture 3 Lab: Synthetic Control, RDD, and Shift-Share IV
* PhD Causal Inference — University of Ferrara, 7 May 2026
* Author: Francesco Rentocchini
* ----------------------------------------------------------------------------
* Topics: Sharp RDD (rdrobust), Bartik shift-share IV
* ----------------------------------------------------------------------------
* Inputs:  data from material/ or replication package
* Outputs: figures → ../Figures/L3_*.png
* ============================================================================

* ----------------------------------------------------------------------------
* 0. Setup
* ----------------------------------------------------------------------------
clear all
set more off
set seed 12345

global proj_path "."

* Required packages (install once):
* ssc install rdrobust, replace
* ssc install rddensity, replace

* ----------------------------------------------------------------------------
* 1. Load data — RDD application
* ----------------------------------------------------------------------------
* TODO: load dataset with running variable (score) and outcome
* use "${proj_path}/data/rdd_data.dta", clear

* ----------------------------------------------------------------------------
* 2. Visual inspection
* ----------------------------------------------------------------------------
* TODO: rdplot outcome score, c(0)
* graph export "${proj_path}/Figures/L3_rdplot.png", replace width(3000)

* ----------------------------------------------------------------------------
* 3. Density test (McCrary / rddensity)
* ----------------------------------------------------------------------------
* TODO: rddensity score, c(0)

* ----------------------------------------------------------------------------
* 4. Main RDD estimate — rdrobust
* ----------------------------------------------------------------------------
* TODO: rdrobust outcome score, c(0) kernel(triangular) bwselect(mserd)

* ----------------------------------------------------------------------------
* 5. Bandwidth sensitivity
* ----------------------------------------------------------------------------
* TODO: loop over bandwidths; plot coefficients

* ----------------------------------------------------------------------------
* 6. Load data — shift-share application
* ----------------------------------------------------------------------------
* TODO: load dataset with industry shares and national employment growth
* use "${proj_path}/data/ssiv_data.dta", clear

* ----------------------------------------------------------------------------
* 7. Construct Bartik instrument
* ----------------------------------------------------------------------------
* TODO: gen bartik = sum over industries of (share_ij * growth_national_j)

* ----------------------------------------------------------------------------
* 8. IV estimation
* ----------------------------------------------------------------------------
* TODO: ivregress 2sls outcome (endogenous = bartik) controls, ///
*     vce(cluster geo_unit)
* TODO: estat firststage

* ----------------------------------------------------------------------------
* 9. Rotemberg weights
* ----------------------------------------------------------------------------
* TODO: compute Rotemberg alpha weights to assess which industries drive the IV

* ----------------------------------------------------------------------------
* 10. Export results
* ----------------------------------------------------------------------------
* TODO: graph export / esttab
