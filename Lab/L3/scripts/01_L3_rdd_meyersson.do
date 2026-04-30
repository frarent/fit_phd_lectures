* ============================================================================
* Lab 3 — Exercise 1: Sharp RDD
* Paper : Meyersson (2014), "Islamic Rule and the Empowerment of the Poor
*          and Pious"
* Data  : CIT_2019_Cambridge_polecon.dta  (Cattaneo, Idrobo & Titiunik 2019)
* ----------------------------------------------------------------------------
* Research question:
*   Does electing an Islamic mayor increase female high-school completion?
*   1994 Turkish municipal elections. N ≈ 2,629 municipalities.
*
* Design:
*   Running variable (X): Islamic party vote margin (positive = Islamic win)
*   Treatment (T):        Islamic mayor elected (X ≥ 0)
*   Outcome (Y):          Female HS completion rate in 2000
*   Cutoff (c):           0
*   Key finding:          +4.4 pp for women in Islamic-won municipalities
* ============================================================================

clear all
set more off
set seed 12345

* ----------------------------------------------------------------------------
* 1.1  Load data and label key variables
* ----------------------------------------------------------------------------
use "${data}/db_meyersson.dta", clear

label var Y   "Female HS completion rate (2000)"
label var X   "Islamic party vote margin (running variable)"
label var T   "Islamic mayor elected (treatment, X>=0)"

* Quick look at the design
di _n "=== DESIGN SUMMARY ==="
sum Y X T
tab T                      // 1,256 Islamic wins vs 1,373 non-Islamic
di "Cutoff = 0 (positive margin = Islamic win)"

* ----------------------------------------------------------------------------
* 1.2  RD Plots — visual evidence (Lecture: 'RD plots: key decisions')
* ----------------------------------------------------------------------------
* Rule: always plot before estimating. Two views:
*   (a) Full bandwidth — global picture, no discontinuity visible
*   (b) Local bandwidth — zoom in near c=0, jump becomes clear

di _n "=== STEP 1: RD PLOTS ==="

* (a) Full bandwidth: raw scatter + 0th-order polynomial
rdplot Y X, nbins(2500 500) p(0)              ///
    graph_options(                             ///
        xtitle("Islamic margin of victory")   ///
        ytitle("Female HS completion rate")   ///
        title("(a) Full bandwidth")           ///
        ylabel(0(10)70))
graph export "${figures_path}/rdd_meyersson_fullbw.png", replace

* (b) Local bandwidth: restrict to |X| ≤ 50, add 4th-order polynomial
rdplot Y X if abs(X) <= 50, nbins(2500 500) p(4)  ///
    graph_options(                                   ///
        xtitle("Islamic margin of victory")          ///
        ytitle("Female HS completion rate")          ///
        title("(b) Local bandwidth — discontinuity visible") ///
        ylabel(0(10)70))
graph export "${figures_path}/rdd_meyersson_localbw.png", replace

* Key insight: the full-bandwidth plot looks flat because global trends dominate.
* The local plot reveals the sharp jump at c=0 — this is why bandwidth choice
* and local estimation matter (see Lecture: 'Estimation: key decisions').

* ----------------------------------------------------------------------------
* 1.3  Manipulation test — is the running variable continuous at the cutoff?
* ----------------------------------------------------------------------------
* If candidates (or election administrators) could precisely manipulate the
* margin, we'd see a density spike just above zero.
* Lecture: 'Validity: what you must always check'

di _n "=== STEP 2: MANIPULATION TEST (rddensity) ==="

rddensity X, c(0) plot
* H0: density is continuous at c=0. Rejection = manipulation concern.
* For Meyersson: p-value is large → no evidence of manipulation.

* ----------------------------------------------------------------------------
* 1.4  Covariate balance — pre-determined covariates should NOT jump at c=0
* ----------------------------------------------------------------------------
* Test whether baseline characteristics (1994 and earlier) jump at the cutoff.
* A significant jump would indicate the RD is not locally randomised.

di _n "=== STEP 3: COVARIATE BALANCE ==="

local covariates "vshr_islam1994 lpop1994 ageshr19 ageshr60 sexr shhs"

foreach var of local covariates {
    local lbl : variable label `var'
    dis _n in red "`var' — `lbl'"
    rdrobust `var' X, c(0)
    di "Estimate: " %6.3f e(tau_cl) "  |  p-value: " %5.3f e(pv_cl)
}
* Expected result: no significant jumps → the design is locally balanced.

* ----------------------------------------------------------------------------
* 1.5  Main RD estimate — optimal bandwidth, local linear regression
* ----------------------------------------------------------------------------
* rdrobust implements:
*   - CCT (2014) optimal bandwidth selection
*   - Local polynomial regression on each side
*   - Bias-corrected and robust confidence intervals
* Lecture: 'Estimation: key decisions (1-3)' — bandwidth, kernel, polynomial

di _n "=== STEP 4: MAIN RD ESTIMATE ==="

rdrobust Y X, c(0)
* Store key results
local tau    = e(tau_cl)
local bw_l   = e(h_l)
local bw_r   = e(h_r)

* Specification closer to original paper one with i) covariates and ii) clustering
rdrobust Y X, covs(vshr_islam1994 partycount lpop1994 merkezi merkezp subbuyuk buyuk) ///
    p(1) kernel(triangular) bwselect(mserd) scaleregul(1) vce(nncluster prov_num)


di _n "Main RD estimate (bias-corrected): " %6.3f `tau' " pp"
di "Optimal bandwidth (left/right): " %5.2f `bw_l' " / " %5.2f `bw_r'
di "Paper finding: +4.4 pp"

* ----------------------------------------------------------------------------
* 1.6  Sensitivity to bandwidth choice
* ----------------------------------------------------------------------------
* The CCT bandwidth is data-driven but we should verify the result is
* not knife-edge. Run for bandwidths = 0.5h, h, 1.5h, 2h.

di _n "=== STEP 5: BANDWIDTH SENSITIVITY ==="

foreach mult in 0.5 1 1.5 2 {
    local bw_sense = `bw_l' * `mult'
    rdrobust Y X, c(0) h(`bw_sense')
    di "Bandwidth = " %5.2f `bw_sense' " (x" `mult' ")  |  Estimate: " ///
        %6.3f e(tau_cl) "  |  p-value: " %5.3f e(pv_cl)
}
* Stable estimates across bandwidths support the validity of the design.


