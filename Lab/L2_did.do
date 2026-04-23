* ============================================================================
* Lecture 2 Lab: DiD — The Good, the Bad, and the Ugly
* PhD Causal Inference — University of Ferrara, 6 May 2026
* Author: Francesco Rentocchini
* ----------------------------------------------------------------------------
* Based on:
*   Exercise 1 — Rizzo, Rentocchini, Seeber & Ramaciotti (2025),
*       "Beyond the Badge of Honour: The Effect of the Italian
*        Academic Excellence Initiative on Staff Recruitment"
*       Oxford Economic Papers, forthcoming
*   Exercise 2 — Rentocchini (2025), Superstar M&A (working paper)
* ----------------------------------------------------------------------------
* OUTPUTS
*   Figures/L2_doe_trends.png          — DoE: raw outcome trends by group
*   Figures/L2_doe_event_twfe.png      — DoE: event study (TWFE)
*   Figures/L2_doe_event_cs.png        — DoE: event study (CS)
*   Figures/L2_doe_honestdid.png       — DoE: HonestDiD sensitivity plot
*   Figures/L2_ma_event_combined.png   — M&A: combined event study (TWFE+CS+SA)
*   Figures/L2_ma_bacon.png            — M&A: Bacon decomposition scatter
*   Figures/L2_ma_honestdid.png        — M&A: HonestDiD sensitivity plot
* ----------------------------------------------------------------------------
* PACKAGES NEEDED (run once):
*   ssc install reghdfe, replace
*   ssc install ftools, replace
*   ssc install csdid, replace
*   ssc install drdid, replace
*   ssc install eventstudyinteract, replace
*   ssc install bacondecomp, replace
*   ssc install event_plot, replace
*   ssc install honestdid, replace
*   ssc install boottest, replace
* ============================================================================

clear all
set more off
set seed 12345

set scheme plotplainblind

* ============================================================================
* EXERCISE 1: DEPARTMENTS OF EXCELLENCE (DoE) — Single Cohort DiD
* ============================================================================
* Question: Did the Italian Academic Excellence Initiative raise faculty
*           recruitment in awarded departments?
* Data:     290 university departments, balanced panel 2013–2020
* Treatment: 145 departments awarded the DoE prize, treated from 2018 onward
* Outcome:  new_position (new academic hires per department per year)
* Confounders: lag researchers, transfers, research funding, VA per capita,
*              unemployment rate; university×year FE
* Source: Rizzo, Rentocchini, Seeber & Ramaciotti (OEP, forthcoming)
* ============================================================================

* ---- Path to DoE data -------------------------------------------------------
global doe_data "data/dtp_excel.dta"

* ----------------------------------------------------------------------------
* 1.1 Load and inspect
* ----------------------------------------------------------------------------
use "${doe_data}", clear

* Check panel structure
xtset id year
des id year treated post2 new_position lagi dep_transfer_horizontal ///
    tot_premiale VA_percap unemp_rate uni_name_enc

* Treatment timing: single cohort (2018)
tab year treated

* ----------------------------------------------------------------------------
* 1.2 Graphical descriptives: raw outcome trends by treatment status
* ----------------------------------------------------------------------------
preserve
    collapse (mean) new_position, by(year treated)
    label define treatlbl 0 "Control" 1 "Treated (DoE)"
    label values treated treatlbl
    twoway (line new_position year if treated==0, lcolor(gs8) lwidth(medium)) ///
           (line new_position year if treated==1, lcolor(navy) lwidth(medium) ///
            lpattern(solid)), ///
        xline(2017.5, lpattern(dash) lcolor(ecred%70)) ///
        legend(order(1 "Control departments" 2 "Awarded departments") ///
               size(small) position(11) ring(0)) ///
        xtitle("Year", size(small)) ytitle("Mean new positions", size(small)) ///
        title("New Academic Positions by Treatment Status", size(medsmall)) ///
        subtitle("Vertical line = treatment start (2018)", size(small)) ///
        scheme(plotplainblind)
    graph export "${proj_path}/Figures/L2_doe_trends.png", replace width(3000)
restore

* ----------------------------------------------------------------------------
* 1.3 TWFE static regression
* ----------------------------------------------------------------------------
* Three specifications following Rizzo et al. (2025): Table 2
global covar lagi dep_transfer_horizontal tot_premiale VA_percap unemp_rate

di as text _n "=== DoE: TWFE STATIC REGRESSIONS ==="

* Spec 1: department FE + covariates
reghdfe new_position ib0.treated##i.post2 $covar, a(id) cluster(id)
est store doe_twfe1
estadd local univ_x_year "No"

* Spec 2: department FE + university×post2 FE + covariates
reghdfe new_position ib0.treated##i.post2 $covar, ///
    a(id i.uni_name_enc#i.post2) cluster(id)
est store doe_twfe2
estadd local univ_x_year "Yes"

* Spec 3: add IPW weights (pre-treatment propensity score)
reghdfe new_position ib0.treated##i.post2 $covar ///
    [pweight=w_ipw_pre], a(id i.uni_name_enc#i.post2) cluster(id)
est store doe_twfe3
estadd local univ_x_year "Yes"

esttab doe_twfe1 doe_twfe2 doe_twfe3, ///
    keep(1.treated#1.post2) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(+ 0.1 * 0.05 ** 0.01) ///
    stats(univ_x_year N, labels("Univ × Post FE" "N")) ///
    title("DoE: TWFE estimates (outcome: new positions)")

* ----------------------------------------------------------------------------
* 1.4 Conditional parallel trends test (event-study pre-trend test)
* ----------------------------------------------------------------------------
* Use years up to 2017 only; baseline = 2017; interact treatment × year
di as text _n "=== DoE: CONDITIONAL PARALLEL TRENDS TEST ==="

preserve
    keep if year <= 2017

    reghdfe new_position ib0.treated##b2017.year $covar ///
        [pweight=w_ipw_pre], a(id i.uni_name_enc#i.year) cluster(id)

    * Joint F-test on pre-treatment interaction terms
    test 1.treated#2014.year 1.treated#2015.year 1.treated#2016.year
    di as result "Joint F-test p-value (pre-trends) = " %6.4f r(p)
    * H0: no differential pre-trends; p > 0.05 supports parallel trends
restore

* ----------------------------------------------------------------------------
* 1.5 Dynamic TWFE (event study)
* ----------------------------------------------------------------------------
di as text _n "=== DoE: DYNAMIC TWFE EVENT STUDY ==="

* Time-to-treatment variable (treatment starts 2018)
gen treat_year = 2018 if treated == 1
gen time_to_treat = year - treat_year if treated == 1
replace time_to_treat = year - 2018 if treated == 0   // anchor controls at 2018

* Relative time dummies: window -5 to +3 (panel 2013–2020, treated 2018)
* Drop t = -1 as baseline
cap drop F*event L*event

forvalues l = 0/2 {
    gen L`l'event = (time_to_treat == `l') & treated == 1
}
forvalues l = 2/5 {
    gen F`l'event = (time_to_treat == -`l') & treated == 1
}
drop F1event   // baseline = -1

reghdfe new_position F*event L*event $covar ///
    [pweight=w_ipw_pre], a(id i.uni_name_enc#i.year) cluster(id)
est store doe_es_twfe

* Plot event study
event_plot doe_es_twfe, stub_lag(L#event) stub_lead(F#event) ///
    together plottype(scatter) trimlead(5) trimlag(2) ///
    graph_opt(yline(0, lpattern(dash)) ///
    ylabel(, format(%3.2f)) xlabel(-5(1)2) ///
    xtitle("Year relative to DoE award") ///
    ytitle("New positions (ATT)") ///
    title("DoE: Event Study (TWFE)", size(medsmall)) ///
    note("Baseline = t{subscript:-1}. 95% CIs. Clustered SEs by department.", ///
         size(vsmall))) ///
    lag_opt1(msymbol(circle) mcolor(navy)) lag_ci_opt1(color(navy%60))
graph export "${proj_path}/Figures/L2_doe_event_twfe.png", replace width(3000)

* ----------------------------------------------------------------------------
* 1.6 Callaway & Sant'Anna estimator (csdid)
* ----------------------------------------------------------------------------
* Single cohort (2018): gvar = 2018 for treated, 0 for never-treated
di as text _n "=== DoE: CALLAWAY & SANT'ANNA ESTIMATOR ==="

gen gvar = 2018 if treated == 1
replace gvar = 0 if treated == 0

csdid new_position $covar [iweight=w_ipw_pre], ///
    ivar(id) time(year) gvar(gvar) long2

* Summary aggregations
estat simple
estat event

* Event-study plot
csdid_plot, title("DoE: Event Study (Callaway & Sant'Anna)", size(medsmall)) ///
    ytitle("New positions (ATT)") xtitle("Year relative to DoE award") ///
    ylabel(, format(%3.2f)) ///
    note("Not-yet-treated comparison group. Doubly robust estimator.", size(vsmall))
graph export "${proj_path}/Figures/L2_doe_event_cs.png", replace width(3000)

* ----------------------------------------------------------------------------
* 1.7 HonestDiD sensitivity analysis
* ----------------------------------------------------------------------------
di as text _n "=== DoE: HonestDiD SENSITIVITY ANALYSIS ==="

* Use the TWFE event-study estimates as input
* First re-run the event study without IPW for the HonestDiD format
reghdfe new_position F*event L*event $covar, ///
    a(id i.uni_name_enc#i.year) cluster(id)

* Store coefficients and variance matrix
* Pre-periods: F2event–F5event (leads); post-periods: L0event–L2event (lags)
local npre  4   // pre-treatment relative periods used (t=-5 to t=-2)
local npost 3   // post-treatment relative periods (t=0 to t=2)

* Extract b and V from estimation
matrix b_es = e(b)
matrix V_es = e(V)

* Run HonestDiD: smoothness restriction (M = 0, 0.02, 0.04, 0.06, 0.08, 0.1)
* Requires honestdid package
honestdid, pre(`npre') post(`npost') mvec(0(0.02)0.1) ///
    coefplot ///
    xlabel(0(0.02)0.1) xtitle("Smoothness restriction M") ///
    ytitle("ATT estimate (new positions)") ///
    title("DoE: HonestDiD Sensitivity", size(medsmall)) ///
    note("Grey band = robust 95% CI under smoothness restriction M.", size(vsmall))
graph export "${proj_path}/Figures/L2_doe_honestdid.png", replace width(3000)

* ============================================================================
* EXERCISE 2: SUPERSTAR M&A — Staggered DiD with Heterogeneous Treatment Effects
* ============================================================================
* Question: Do technology-related M&As raise firm-level markups?
* Data:     Firm-level panel, staggered by M&A year
* Treatment: ma_t_tech (=1 post first tech M&A)
* Outcome:  markupmattl_trim (De Loecker-Warzynski markup)
* Source: Rentocchini (2025), Superstar M&A working paper
* ============================================================================

* ---- Path to M&A data -------------------------------------------------------
global ma_data "../material/lab/superstar_MA-main/superstar_MA-main/scripts"
* Data is loaded from within the scripts via data_path globals.
* For the lab we use the pre-built analysis dataset directly:
global ma_db "\\delta\jrc\B\B.6\scidata\users\FR\superstar_MA\data\data_for_analysis\db_estimates_extra.dta"

* ----------------------------------------------------------------------------
* 2.1 Load and inspect
* ----------------------------------------------------------------------------
use "${ma_db}", clear

* Global macros for outcome and treatment
global y     markupmattl_trim
global x     ma_t_tech
global covs              // no time-varying covariates for simplicity

* Set panel
xtset id year

* Treatment cohort distribution
bys id: egen ma_tech_first_y = min(year) if ma_t_tech == 1
bys id: replace ma_tech_first_y = . if !missing(ma_tech_first_y[_n-1])
bys id: carryforward ma_tech_first_y, replace

di as text _n "=== M&A: TREATMENT COHORT DISTRIBUTION ==="
tab ma_tech_first_y if ma_t_tech == 1, miss

* ----------------------------------------------------------------------------
* 2.2 TWFE static regressions
* ----------------------------------------------------------------------------
di as text _n "=== M&A: TWFE STATIC REGRESSIONS ==="

cap est drop _all

* Baseline: firm + year FE + industry×year FE
reghdfe $y i.${x}, a(bvdid year nace##year) vce(cluster bvdid)
est store ma_twfe_base
estadd local firm_fe "Yes"
estadd local year_fe "Yes"
estadd local ind_yr  "Yes"
estadd local ctrl_group "All non-treated"

* Restrict to never-treated + not-yet-treated
reghdfe $y i.${x} if ut_strict1==1, a(bvdid year nace##year) vce(cluster bvdid)
est store ma_twfe_nyt
estadd local firm_fe "Yes"
estadd local year_fe "Yes"
estadd local ind_yr  "Yes"
estadd local ctrl_group "Not-yet-treated"

esttab ma_twfe_base ma_twfe_nyt, ///
    keep(1.ma_t_tech) ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    starlevels(+ 0.1 * 0.05 ** 0.01) ///
    stats(ctrl_group firm_fe year_fe ind_yr N, ///
          labels("Control group" "Firm FE" "Year FE" "Ind×Year FE" "N")) ///
    title("M&A: TWFE static (outcome: markup)")

* ----------------------------------------------------------------------------
* 2.3 Dynamic TWFE event study
* ----------------------------------------------------------------------------
di as text _n "=== M&A: DYNAMIC TWFE EVENT STUDY ==="

global graph_opts1 trimlead(7) trimlag(5) together plottype(scatter)
global graph_opts2 yline(0, lpattern(dash)) ///
    ylabel(-.05(.02).05) xlabel(-7(1)5) ///
    xtitle("Year to/from Tech M&A") ytitle("ATT (markup)")

gen time_to_treat = year - ma_tech_first_y
gen no_treat = (ma_tech_first_y == .)

cap drop F*event L*event

local lag     5
local forward 7

replace time_to_treat = -`forward' if time_to_treat <= -`forward'
replace time_to_treat =  `lag'    if time_to_treat > `lag' & !missing(time_to_treat)

forvalues l = 0/`lag' {
    gen L`l'event = (time_to_treat == `l') & !missing(ma_tech_first_y)
}
forvalues l = 1/`forward' {
    gen F`l'event = (time_to_treat == -`l') & !missing(ma_tech_first_y)
}
drop F1event   // baseline = t-1

reghdfe $y F*event L*event, a(bvdid year nace##year) vce(cluster bvdid)
est store est_OLS

* Pre-trend test
testparm F2event-F7event
local f_twfe  = r(F)
local fp_twfe = r(p)
local N_obs   = e(N)

* Simple ATT from static TWFE for annotation
reghdfe $y ma_t_tech, a(bvdid year) vce(cluster bvdid)
local b_twfe  = _b[ma_t_tech]
local se_twfe = _se[ma_t_tech]

* ----------------------------------------------------------------------------
* 2.4 Bacon decomposition
* ----------------------------------------------------------------------------
di as text _n "=== M&A: BACON DECOMPOSITION ==="

bacondecomp $y ma_t_tech, robust ///
    gropt(title("M&A: Bacon Decomposition", size(medsmall)) ///
          xtitle("Weight") ytitle("2×2 DD estimate") ///
          note("Each point is one 2×2 DiD. Size = weight in TWFE.", size(vsmall)))
graph export "${proj_path}/Figures/L2_ma_bacon.png", replace width(3000)

* Save decomposition results
matrix bacon_table = r(table)
di as text "TWFE weighted sum from decomposition:"
di as result "  Early vs. Late (clean): " %6.3f r(dd_early_late)
di as result "  Late vs. Early (dirty): " %6.3f r(dd_late_early)

* ----------------------------------------------------------------------------
* 2.5 Sun & Abraham (2021) — interaction-weighted estimator
* ----------------------------------------------------------------------------
di as text _n "=== M&A: SUN & ABRAHAM ESTIMATOR ==="

sum ma_tech_first_y
gen lastcohort = (ma_tech_first_y == r(max))

qui eventstudyinteract $y L*event F*event, vce(cluster bvdid) ///
    absorb(bvdid year) cohort(ma_tech_first_y) control_cohort(lastcohort)
est store est_SA
matrix sa_b = e(b_iw)
matrix sa_v = e(V_iw)

* Average post-treatment ATT (L0–L5)
ereturn post sa_b sa_v
lincom (L0event + L1event + L2event + L3event + L4event + L5event) / 6
local b_sa  = r(estimate)
local se_sa = r(se)

* Re-run to recover estimates for event_plot
qui eventstudyinteract $y L*event F*event, vce(cluster bvdid) ///
    absorb(bvdid year) cohort(ma_tech_first_y) control_cohort(lastcohort)
est store est_SA
matrix sa_b = e(b_iw)
matrix sa_v = e(V_iw)

* Pre-trend test
ereturn post sa_b sa_v
testparm F2event-F7event
local f_sa   = r(chi2)
local fp_sa  = r(p)

qui eventstudyinteract $y L*event F*event, vce(cluster bvdid) ///
    absorb(bvdid year) cohort(ma_tech_first_y) control_cohort(lastcohort)
est store est_SA

* ----------------------------------------------------------------------------
* 2.6 Callaway & Sant'Anna (2021) — csdid
* ----------------------------------------------------------------------------
di as text _n "=== M&A: CALLAWAY & SANT'ANNA ESTIMATOR ==="

gen gvar_ma = cond(!missing(ma_tech_first_y), ma_tech_first_y, 0)

* Pre-residualise by industry×year on never-treated (absorbs sectoral trends)
bys nace year: egen _iy_nt = mean($y) if gvar_ma == 0
bys nace year: egen iy_nt  = mean(_iy_nt)
drop _iy_nt
sum $y if gvar_ma == 0
local grand_mean = r(mean)
gen y_dem = $y - iy_nt + `grand_mean'

csdid y_dem, ivar(bvdid) time(year) gvar(gvar_ma) long2
estat simple
matrix Bmat = r(b)
matrix Vmat = r(V)
local b_ca  = Bmat[1,1]
local se_ca = sqrt(Vmat[1,1])

csdid y_dem, ivar(bvdid) time(year) gvar(gvar_ma) agg(event) long2
est store est_CA
matrix ca_b = e(b)
matrix ca_v = e(V)

* Pre-trend Wald test (Tm2–Tm7)
local colnames : colnames ca_b
local ncols = colsof(ca_b)
local idx ""
forvalues i = 1/`ncols' {
    local cname : word `i' of `colnames'
    if inlist("`cname'", "Tm2","Tm3","Tm4","Tm5","Tm6","Tm7") local idx "`idx' `i'"
}
local ntest : word count `idx'
matrix R = J(`ntest', `ncols', 0)
local row 0
foreach col of local idx {
    local row = `row' + 1
    matrix R[`row', `col'] = 1
}
matrix b_pre = R * ca_b'
matrix V_pre = R * ca_v * R'
matrix W     = b_pre' * invsym(V_pre) * b_pre
scalar wald_ca = W[1,1]
scalar wald_p  = chi2tail(`ntest', wald_ca)
local wald_ca  = wald_ca
local wp_ca    = wald_p

* ----------------------------------------------------------------------------
* 2.7 Combined event-study plot (TWFE + CS + SA)
* ----------------------------------------------------------------------------
di as text _n "=== M&A: COMBINED EVENT STUDY PLOT ==="

sum $y if time_to_treat < 0 & e(sample)
local pret = r(mean)

event_plot est_OLS sa_b#sa_v est_CA, ///
    stub_lag(L#event L#event Tp#) stub_lead(F#event F#event Tm#) ///
    ${graph_opts1} perturb(-0.15(0.15)0.15) noautolegend ///
    graph_opt(${graph_opts2} ///
    title("M&A: Estimator Comparison", size(medsmall)) ///
    legend(order(1 "TWFE" 3 "Sun & Abraham (2021)" 5 "Callaway & Sant'Anna (2021)") ///
           rows(1) position(6) size(vsmall)) ///
    text(-.04 -7 ///
         "ATT — TWFE=`=string(`b_twfe',"%5.3f")' (`=string(`se_twfe',"%5.3f")')" ///
         "ATT — S&A=`=string(`b_sa',"%5.3f")' (`=string(`se_sa',"%5.3f")')" ///
         "ATT — C&S=`=string(`b_ca',"%5.3f")' (`=string(`se_ca',"%5.3f")')" ///
         "Pre-trend test: TWFE F=`=string(`f_twfe',"%5.3f")' (p=`=string(`fp_twfe',"%4.3f")')" ///
         "Pre-mean=`=string(`pret',"%5.3f")'" ///
         "N=`N_obs'" ///
         , place(ll) size(tiny) just(left))) ///
    lag_opt1(msymbol(circle_hollow) mcolor(black))  lag_ci_opt1(color(black)) ///
    lag_opt2(msymbol(square_hollow) mcolor(gs10))   lag_ci_opt2(color(gs10)) ///
    lag_opt3(msymbol(diamond_hollow) mcolor(ecblue)) lag_ci_opt3(color(ecblue))
graph export "${proj_path}/Figures/L2_ma_event_combined.png", replace width(5000)

* ----------------------------------------------------------------------------
* 2.8 HonestDiD sensitivity analysis
* ----------------------------------------------------------------------------
di as text _n "=== M&A: HonestDiD SENSITIVITY ANALYSIS ==="

* Re-run TWFE event study on clean sample (never-treated comparison)
reghdfe $y F*event L*event if ut_strict1==1, ///
    a(bvdid year nace##year) vce(cluster bvdid)
est store est_es_clean

local npre_ma  6   // F2event–F7event
local npost_ma 6   // L0event–L5event

honestdid, pre(`npre_ma') post(`npost_ma') mvec(0(0.005)0.05) ///
    coefplot ///
    xlabel(0(0.005)0.05) xtitle("Smoothness restriction M") ///
    ytitle("ATT estimate (markup)") ///
    title("M&A: HonestDiD Sensitivity", size(medsmall)) ///
    note("Grey band = robust 95% CI under smoothness restriction M.", size(vsmall))
graph export "${proj_path}/Figures/L2_ma_honestdid.png", replace width(3000)

* ----------------------------------------------------------------------------
* 2.9 Summary table: all estimates
* ----------------------------------------------------------------------------
di as text _n "=== M&A: SUMMARY — TWFE vs. CS vs. SA ==="
di as text "Method                        |   ATT Estimate |   SE"
di as text "------------------------------|----------------|----------"
di as text "TWFE (static)                 | " %14.4f `b_twfe' " | " %8.4f `se_twfe'
di as text "Sun & Abraham (2021)          | " %14.4f `b_sa'   " | " %8.4f `se_sa'
di as text "Callaway & Sant'Anna (2021)   | " %14.4f `b_ca'   " | " %8.4f `se_ca'

di as text _n "Pre-trend tests (H0: no differential pre-trends):"
di as text "  TWFE: F = " %6.3f `f_twfe'  " (p = " %5.3f `fp_twfe' ")"
di as text "  S&A:  chi2 = " %6.3f `f_sa' " (p = " %5.3f `fp_sa'   ")"
di as text "  C&S:  Wald = " %6.3f `wald_ca' " (p = " %5.3f `wp_ca' ")"

* ============================================================================
* End of lab script
* ============================================================================
