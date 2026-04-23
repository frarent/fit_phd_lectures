* ============================================================================
* Lecture 3 Lab: Sharp RDD and Synthetic Difference-in-Differences
* PhD Causal Inference — University of Ferrara, 7 May 2026
* Author: Francesco Rentocchini
* ----------------------------------------------------------------------------
* Exercise 1 — Sharp RDD: Department of Excellence programme (Italy)
*   Running variable: Centered score from the national DoE competition (c=0)
*   Outcome       : Post-treatment academic staff (post_personale)
*   Source        : Rizzo, Rentocchini, Seeber & Ramaciotti (2026, OEP)
*                   data_ps.dta from deptexc replication package
*
* Exercise 2 — Synthetic Difference-in-Differences (SDiD)
*   Treatment: DoE award from 2018 onward
*   Outcomes : New academic positions (new_position, new_entry, ...)
*   Source   : Arkhangelsky et al. (2021, AER); Clarke et al. (2024, SJ)
*              data_for_analysis.dta from dpt_of_excellence replication package
* ============================================================================

clear all
set more off
set seed 12345

* Paths (relative to fit_phd_lectures/Lab/L3/)
global data_rdd "../../material/lab/deptexc/data/data_for_analysis"
global data_sdid "../../material/lab/dpt_of_excellence-main/dpt_of_excellence-main/data/raw_data"
global output_figures "../../Figures"

* Required packages (install once):
* ssc install rdrobust,  replace
* ssc install rddensity, replace
* ssc install reghdfe,   replace
* ssc install sdid,      replace
* ssc install coefplot,  replace


* ============================================================================
* EXERCISE 1: SHARP RDD — DEPARTMENT OF EXCELLENCE (DoE)
* ============================================================================
* Question : Did receiving DoE funding increase academic staff recruitment?
* Context  : Italian Ministry awards ~180 "excellent" departments every 5 yrs.
*            Selection based on a composite quality score (VQR-based).
*            Departments above the area-specific threshold receive large grants.
* Data     : ~350 Italian university departments (2016 wave)
* Running  : running_var = centered score (threshold = 0 by construction)
* Outcome  : post_personale = academic staff count post-award
* Ref      : Rizzo, Rentocchini, Seeber & Ramaciotti (2026, Oxford Econ Papers)
* ============================================================================

* ----------------------------------------------------------------------------
* 1.1 Load and inspect
* ----------------------------------------------------------------------------
use "${data_rdd}/data_ps.dta", clear

label var running_var  "Centered DoE score (running variable, c=0)"
label var treat        "DoE funded (=1 if above threshold)"

des running_var treat personale post_personale area_cun
sum running_var treat personale post_personale

* Quick compliance plot: is assignment actually sharp?
scatter treat running_var, xline(0, lcolor(red)) ///
    ylabel(0 "Not funded" 1 "Funded") ytitle("") ///
    xtitle("Centered DoE score") ///
    title("Sharp RDD: compliance at threshold", size(medsmall)) ///
    scheme(plotplainblind) jitter(1) jitterseed(42) legend(off)
graph export "${output_figures}/L3_doe_compliance.png", replace width(3000)
* Expected: all departments with running_var >= 0 receive treatment (sharp)

* ----------------------------------------------------------------------------
* 1.2 Distribution of the running variable (density test)
* ----------------------------------------------------------------------------
di as text _n "=== RDD: DENSITY TEST ==="

hist running_var, xline(0, lcolor(red)) xtitle("Centered DoE score") ///
    title("Distribution of running variable", size(medsmall)) ///
    scheme(plotplainblind)
graph export "${output_figures}/L3_doe_hist.png", replace width(3000)

rddensity running_var, c(0)
* H0: no density discontinuity at threshold
* p > 0.05 supports absence of score manipulation

rddensity running_var, c(0) plot ///
    graph_opt(scheme(plotplainblind) ///
        title("Density test: DoE centered score", size(medsmall)) ///
        xtitle("Centered DoE score") legend(off))
graph export "${output_figures}/L3_doe_density.png", replace width(3000)

* Note: For a discrete running variable, also test with McCrary (2008):
* ssc install rddensity; DCdensity running_var, breakpoint(0)

* ----------------------------------------------------------------------------
* 1.3 Visual inspection: rdplot
* ----------------------------------------------------------------------------
di as text _n "=== RDD: RDPLOT ==="

rdplot post_personale running_var, c(0) ///
    graph_options(scheme(plotplainblind) ///
        title("RD plot: academic staff vs. DoE score", size(medsmall)) ///
        xtitle("Centered DoE score") ///
        ytitle("Post-treatment academic staff"))
graph export "${output_figures}/L3_doe_rdplot.png", replace width(3000)
* Look for a visible jump at zero — this is the raw visual evidence

* ----------------------------------------------------------------------------
* 1.4 Main estimate: rdrobust (MSE-optimal, triangular kernel)
* ----------------------------------------------------------------------------
di as text _n "=== RDD: MAIN ESTIMATE ==="

rdrobust post_personale running_var, c(0) kernel(triangular) bwselect(mserd)
* Bias-corrected estimate with robust CIs (Calonico, Cattaneo & Titiunik 2014)

local h_opt  = e(h_l)
local tau_bc = e(coef_bc)
local se_bc  = e(se_bc)
local pv     = e(pv_rb)

di as result "Optimal bandwidth (MSE): " %5.3f `h_opt'
di as result "Bias-corrected ATT:      " %6.4f `tau_bc' " (" %5.4f `se_bc' ")"
di as result "Robust p-value:          " %5.3f `pv'

* With area_cun fixed effects (recommended for heterogeneous areas):
xi: rdrobust post_personale running_var, c(0) kernel(triangular) ///
    bwselect(mserd) covs(i.area_cun)
di as result "ATT (with area FE):      " %6.4f e(coef_bc) " (" %5.4f e(se_bc) ")"

* ----------------------------------------------------------------------------
* 1.5 Bandwidth sensitivity
* ----------------------------------------------------------------------------
di as text _n "=== RDD: BANDWIDTH SENSITIVITY ==="

tempname bw_mat
foreach h in 2 4 6 8 10 12 14 {
    quietly rdrobust post_personale running_var, c(0) h(`h') kernel(triangular)
    matrix `bw_mat' = (nullmat(`bw_mat') \ ///
        (`h', e(coef_bc), e(se_bc), e(ci_l_rb), e(ci_r_rb)))
}
matrix colnames `bw_mat' = h coef se ci_low ci_high

preserve
    svmat `bw_mat', names(col)
    keep if !missing(h)
    twoway (rcap ci_low ci_high h, lcolor(gs8) lwidth(thin)) ///
           (scatter coef h, mcolor(navy) msymbol(circle)), ///
        yline(0, lcolor(red) lpattern(dash)) ///
        xtitle("Bandwidth (score points)") ///
        ytitle("RD estimate (bias-corrected)") ///
        title("RDD: bandwidth sensitivity", size(medsmall)) ///
        legend(off) scheme(plotplainblind)
    graph export "${output_figures}/L3_doe_bw_sensitivity.png", replace width(3000)
restore

* ----------------------------------------------------------------------------
* 1.6 Covariate balance (pre-determined variables should show no jump)
* ----------------------------------------------------------------------------
di as text _n "=== RDD: COVARIATE BALANCE ==="

foreach cov in personale mean_ric mean_ass mean_ord {
    di as text "  Balance check: `cov'"
    quietly rdrobust `cov' running_var, c(0) kernel(triangular) bwselect(mserd)
    di as result "    Bias-corrected coef = " %7.4f e(coef_bc) ///
                 "  p-value = " %5.3f e(pv_rb)
}
* All p-values should exceed 0.05 (no pre-determined covariate jumps)

* ----------------------------------------------------------------------------
* 1.7 Placebo cutoffs
* ----------------------------------------------------------------------------
di as text _n "=== RDD: PLACEBO CUTOFFS ==="

foreach c_fake in -8 -4 4 8 {
    di as text "  Placebo cutoff c = `c_fake'"
    quietly rdrobust post_personale running_var, c(`c_fake') kernel(triangular) ///
        bwselect(mserd)
    di as result "    Bias-corrected coef = " %6.4f e(coef_bc) ///
                 "  p-value = " %5.3f e(pv_rb)
}
* Expect: no significant effects at false cutoffs


* ============================================================================
* EXERCISE 2: SYNTHETIC DIFFERENCE-IN-DIFFERENCES (SDiD)
* ============================================================================
* Question : Did DoE funding increase new academic staff hiring?
* Design   : Treated = departments funded from 2018 onward (treat_from2018)
*            Panel: ~350 departments × 7 years (2014–2020)
* Estimator: SDID (Arkhangelsky et al. 2021)
*   - Unit weights ω_j: re-weight untreated departments to match pre-trends
*   - Time weights λ_t: up-weight pre-treatment periods closest to treatment
*   - τ̂ = arg min Σ ω_i λ_t (Y_it - α_i - β_t - τ D_it)²
* Reference: Clarke, Pailañir, Athey & Imbens (2024, Stata Journal)
*            Rizzo, Rentocchini et al. (2026, Oxford Econ Papers)
* ============================================================================

* ----------------------------------------------------------------------------
* 2.1 Load data
* ----------------------------------------------------------------------------
use "${data_sdid}/data_for_analysis.dta", clear

* Generate binary treatment indicator: treated from 2018 onward
gen treat_from2018 = treated
replace treat_from2018 = 0 if treated == 1 & year < 2018

* Keep relevant variables and years
global y    new_position new_entry new_endogamia new_rtda new_rtdb new_ten_uni_all
global covar lagi dep_transfer_horizontal tot_premiale VA_percap unemp_rate

keep id year treat_from2018 $y $covar LOWdep
keep if year > 2013      // balanced window: 2014–2020

* Drop departments with any missing variable (require balanced panel)
egen flag_miss = rowmiss($y $covar treat_from2018 LOWdep)
bysort id: egen flag_miss2 = total(flag_miss)
drop if flag_miss2 >= 1
drop flag_miss*

label var new_position    "New positions (all types)"
label var new_entry       "New positions (excl. promotions)"
label var new_endogamia   "Internal promotions"
label var new_rtda        "Temporary contracts"
label var new_rtdb        "Tenure-track contracts"
label var new_ten_uni_all "Tenured positions"

xtset id year
di "Panel dimensions:"
qui distinct id
di "  Units: " r(ndistinct)
qui distinct year
di "  Periods: " r(ndistinct)
tab year treat_from2018

* ----------------------------------------------------------------------------
* 2.2 OLS benchmark (biased: omits unobservable department quality)
* ----------------------------------------------------------------------------
di as text _n "=== SDID: OLS BENCHMARK ==="

reghdfe new_position treat_from2018 $covar, absorb(id year) vce(cluster id)
di as result "OLS ATT = " %6.4f _b[treat_from2018]
* OLS likely upward biased: treated departments are inherently stronger

* ----------------------------------------------------------------------------
* 2.3 SDID main estimate (outcome: new_position)
* ----------------------------------------------------------------------------
di as text _n "=== SDID: MAIN ESTIMATE — NEW POSITIONS ==="

global reps 200   // bootstrap replications (use 500 for final results)

sdid new_position id year treat_from2018, ///
    vce(bootstrap) covariates($covar) ///
    reps(${reps}) seed(12345) ///
    graph

* Extract SDID graph components (ATT series + lambda weights)
matrix A  = e(series)
matrix w  = e(lambda)
matrix w2 = w[1..4, 1]
matrix rownames A  = 2014 2015 2016 2017 2018 2019 2020
matrix rownames w2 = 2014 2015 2016 2017

coefplot (matrix(A[,2]), lpattern("dash") label("Control (re-weighted)")) ///
         (matrix(A[,3]), label("Treated")) ///
         (matrix(w2[,1]), recast(bar) color(%30) label("Lambda weights")), ///
    vertical nooffsets recast(line) xline(4.5) ///
    ytitle("New positions (all types)", size(small)) ///
    legend(rows(1) pos(6)) ///
    note("ATT = `: display %-5.3f e(ATT)'" ///
         "SE = [`: display %-5.3f e(se)']", span size(.2cm)) ///
    scheme(plotplainblind)
graph export "${output_figures}/L3_sdid_newposition.png", replace width(3000)

di as result "SDID ATT:  " %6.4f e(ATT)
di as result "Bootstrap SE: " %6.4f e(se)
local z = e(ATT) / e(se)
di as result "z-stat:    " %5.3f `z'

* ----------------------------------------------------------------------------
* 2.4 Multi-outcome SDID table (DDD: high vs. low quality departments)
* ----------------------------------------------------------------------------
di as text _n "=== SDID: DDD ESTIMATES — HIGH vs LOW QUALITY DEPARTMENTS ==="

* LOWdep = 1 for lower-quality departments (heterogeneous treatment effects)

matrix ATT_ddd = J(3, 6, .)   // rows: ATT, SE, p; cols: 6 outcomes

local i 0
foreach var of global y {
    local ++i
    if `i' > 6 continue   // only first 6 outcomes

    * ATT for LOWdep == 1
    quietly sdid `var' id year treat_from2018 if LOWdep == 1, ///
        vce(bootstrap) covariates($covar) reps(${reps}) seed(12345)
    local att_low = e(ATT)
    local se_low  = e(se)

    * ATT for LOWdep == 0
    quietly sdid `var' id year treat_from2018 if LOWdep == 0, ///
        vce(bootstrap) covariates($covar) reps(${reps}) seed(12345)
    local att_high = e(ATT)
    local se_high  = e(se)

    * DDD contrast
    local att_ddd = `att_low' - `att_high'
    local se_ddd  = sqrt(`se_low'^2 + `se_high'^2)
    local p_ddd   = 2 * (1 - normal(abs(`att_ddd' / `se_ddd')))

    matrix ATT_ddd[1,`i'] = `att_ddd'
    matrix ATT_ddd[2,`i'] = `se_ddd'
    matrix ATT_ddd[3,`i'] = `p_ddd'
}

matrix colnames ATT_ddd = "New pos." "Excl. promot." "Promotions" ///
    "Temporary" "Tenure-track" "Tenured"
matrix rownames ATT_ddd = "ATT (DDD)" "Std.Err." "p-value"
matlist ATT_ddd, format(%6.3f) title("SDID DDD: lower vs higher quality departments")

* Interpretation:
*   Positive ATT_ddd: DoE programme helps lower-quality departments more
*   DDD compares within-group SDiD estimates; valid if SUTVA holds within each group

* ----------------------------------------------------------------------------
* 2.5 Comparison: DiD vs. SC vs. SDID for new_position
* ----------------------------------------------------------------------------
di as text _n "=== SDID: METHOD COMPARISON (DiD / SC / SDID) ==="

foreach method in did sc sdid {
    quietly sdid new_position id year treat_from2018, ///
        method(`method') vce(bootstrap) covariates($covar) ///
        reps(${reps}) seed(12345)
    di as result "  `method': ATT = " %6.4f e(ATT) "  SE = " %6.4f e(se)
}
* SDID should be closest to the true causal effect;
* DiD may underestimate if pre-trends diverge;
* SC estimate depends on convex-hull assumption

* ============================================================================
* End of lab script
* ============================================================================
