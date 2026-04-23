* ============================================================================
* Lecture 2 Lab: DiD — The Good, the Bad, and the Ugly
* PhD Causal Inference — University of Ferrara, 6 May 2026
* Author: Francesco Rentocchini
* ----------------------------------------------------------------------------
* Exercise 1 — Rizzo, Rentocchini, Seeber & Ramaciotti (OEP, 2026)
*   "Beyond the Badge of Honour: The Effect of the Italian Academic
*    Excellence Initiative on Staff Recruitment"
*
* Exercise 2 — Rentocchini et al. (2025), Superstar M&A (working paper)
*   "M&As, Innovation and Superstar Firms"
* ============================================================================

clear all
set more off
set seed 12345


* ============================================================================
* EXERCISE 1: DEPARTMENTS OF EXCELLENCE (DoE) — Single-Cohort DiD
* ============================================================================
* Question : Did the Italian Academic Excellence Initiative raise faculty
*            recruitment in awarded departments?
* Data     : 290 university departments, balanced panel 2013–2020
* Treatment: 145 departments awarded DoE prize, treated from 2018 onward
* Outcome  : new_position (new academic hires per department-year)
* ============================================================================

* ----------------------------------------------------------------------------
* 1.1 Load, label, and trim to used variables
* ----------------------------------------------------------------------------
use "${data_path}/dpt_excel.dta", clear

keep id year treated post2 new_position lagi dep_transfer_horizontal ///
     tot_premiale VA_percap unemp_rate uni_name_enc w_ipw_pre

label var id                      "Department identifier"
label var year                    "Year"
label var treated                 "DoE award indicator (=1 if awarded)"
label var post2                   "Post-2018 indicator"
label var new_position            "New academic hires (per department-year)"
label var lagi                    "Lagged number of researchers"
label var dep_transfer_horizontal "Horizontal transfers (inter-department)"
label var tot_premiale            "Total research funding (premiale grant)"
label var VA_percap               "Value added per capita (province)"
label var unemp_rate              "Unemployment rate (province)"
label var uni_name_enc            "University name (encoded)"
label var w_ipw_pre               "IPW weight (pre-treatment propensity score)"

xtset id year
des
tab year treated

* ----------------------------------------------------------------------------
* 1.2 Raw outcome trends by treatment status
* ----------------------------------------------------------------------------
preserve
    collapse (mean) new_position, by(year treated)
    label define treatlbl 0 "Control" 1 "Treated (DoE)"
    label values treated treatlbl
    twoway (scatter new_position year if treated==0, ///
                lcolor(gs8) lwidth(medium)) ///
           (scatter new_position year if treated==1, ///
                lcolor(navy) lwidth(medium) lpattern(solid)), ///
        xline(2017.5, lpattern(dash) lcolor(ecred%70)) ///
        legend(order(1 "Control departments" 2 "Awarded departments") ///
               size(small) position(11) ring(0)) ///
        xtitle("Year", size(small)) ///
        ytitle("Mean new positions", size(small)) ///
        title("New Academic Positions by Treatment Status", size(medsmall)) ///
        subtitle("Vertical line = treatment start (2018)", size(small)) ///
        scheme(plotplainblind)
    graph export "$output_figures/L2_doe_trends.png", replace width(3000)
restore

* ----------------------------------------------------------------------------
* 1.3 TWFE static regression (three specifications)
* ----------------------------------------------------------------------------
* Follows Rizzo et al. (2026): Table 2
global covar lagi dep_transfer_horizontal tot_premiale VA_percap unemp_rate

di as text _n "=== DoE: TWFE STATIC REGRESSIONS ==="

* Spec 1: department FE + covariates only
reghdfe new_position ib0.treated##i.post2 $covar, a(id) cluster(id)
est store doe_twfe1
estadd local univ_x_year "No"

* Spec 2: department FE + university×post2 FE + covariates
reghdfe new_position ib0.treated##i.post2 $covar, ///
    a(id i.uni_name_enc#i.post2) cluster(id)
est store doe_twfe2
estadd local univ_x_year "Yes"

* Spec 3: Spec 2 + IPW weights (pre-treatment propensity score)
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
* 1.4 Conditional parallel trends test (pre-2018 only)
* ----------------------------------------------------------------------------
di as text _n "=== DoE: CONDITIONAL PARALLEL TRENDS TEST ==="

preserve
    keep if year <= 2017
    reghdfe new_position ib0.treated##b2017.year $covar ///
        [pweight=w_ipw_pre], a(id i.uni_name_enc#i.year) cluster(id)
    * Joint F-test on pre-treatment interaction terms; H0 = no differential pre-trends
    test 1.treated#2014.year 1.treated#2015.year 1.treated#2016.year
    di as result "Joint F-test p-value (pre-trends) = " %6.4f r(p)
restore

* ----------------------------------------------------------------------------
* 1.5 Dynamic TWFE event study
* ----------------------------------------------------------------------------
di as text _n "=== DoE: DYNAMIC TWFE EVENT STUDY ==="

* Relative-time variable (treatment cohort 2018; controls anchored at 2018)
gen treat_year   = 2018 if treated == 1
gen time_to_treat = year - treat_year if treated == 1
replace time_to_treat = year - 2018   if treated == 0

* Relative-time dummies: window −5 to +2; t = −1 is baseline (dropped)
cap drop F*event L*event
forvalues l = 0/2 {
    gen L`l'event = (time_to_treat ==  `l') & treated == 1
}
forvalues l = 2/5 {
    gen F`l'event = (time_to_treat == -`l') & treated == 1
}

reghdfe new_position F*event L*event, a(id year) cluster(id)
est store doe_es_twfe

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
graph export "$output_figures/L2_doe_event_twfe.png", replace width(3000)

* ----------------------------------------------------------------------------
* 1.6 Callaway & Sant'Anna (2021) — csdid
* ----------------------------------------------------------------------------
di as text _n "=== DoE: CALLAWAY & SANT'ANNA ESTIMATOR ==="

* Single cohort: gvar = 2018 for treated, 0 for never-treated
gen gvar = cond(treated == 1, 2018, 0)

* Without covariates
csdid new_position, ivar(id) time(year) gvar(gvar) long2
estat simple
estat event

* With covariates (doubly-robust)
csdid new_position $covar, ivar(id) time(year) gvar(gvar) long2
estat simple
estat event

csdid_plot, ///
    title("DoE: Event Study (Callaway & Sant'Anna)", size(medsmall)) ///
    ytitle("New positions (ATT)") xtitle("Year relative to DoE award") ///
    ylabel(, format(%3.2f)) ///
    note("Not-yet-treated comparison group. Doubly robust estimator.", size(vsmall))
graph export "$output_figures/L2_doe_event_cs.png", replace width(3000)


* ============================================================================
* EXERCISE 2: SUPERSTAR M&A — Staggered DiD
* ============================================================================
* Question : Do technology-related M&As raise firm-level markups?
* Data     : Firm-level panel, staggered by M&A year
* Treatment: ma_t_tech (=1 post first tech M&A)
* Outcome  : markupmattl_trim (De Loecker-Warzynski markup, trimmed)
* ============================================================================

* ----------------------------------------------------------------------------
* 2.1 Load, label, and trim to used variables
* ----------------------------------------------------------------------------
use "${data_path}/superstar.dta", clear

keep id bvdid year markupmattl_trim ma_t_tech ma_d_tech ma_tech_first_y ut_strict1

label var id               "Firm identifier (numeric)"
label var bvdid            "BvD firm identifier"
label var year             "Year"
label var markupmattl_trim "De Loecker-Warzynski markup (trimmed)"
label var ma_t_tech        "Post first tech M&A indicator"
label var ma_d_tech        "Tech M&A event indicator (=1 in deal year)"
label var ma_tech_first_y  "Year of first tech M&A"
label var ut_strict1       "not yet + controls post treatment"

global y markupmattl_trim
global x ma_t_tech

xtset id year

* ----------------------------------------------------------------------------
* 2.2 Descriptives
* ----------------------------------------------------------------------------
hist $y
include "$aux/aux01_descriptives.do"

* ----------------------------------------------------------------------------
* 2.3 TWFE static regressions
* ----------------------------------------------------------------------------
di as text _n "=== M&A: TWFE STATIC REGRESSIONS ==="

cap est drop _all

* Baseline: all non-treated as control
reghdfe $y i.${x}, a(bvdid year) vce(cluster bvdid)
est store ma_twfe_base
estadd local ctrl_group "All non-treated"

* Restrict to not-yet-treated + controls after general M&A treatement
reghdfe $y i.${x} if ut_strict1 == 1, a(bvdid year) vce(cluster bvdid)
est store ma_twfe_nyt
estadd local ctrl_group "Not-yet-treated"

esttab ma_twfe_base ma_twfe_nyt, ///
    keep(1.ma_t_tech) ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    starlevels(+ 0.1 * 0.05 ** 0.01) ///
    stats(ctrl_group N, labels("Control group" "N")) ///
    title("M&A: TWFE static (outcome: markup)")

* ----------------------------------------------------------------------------
* 2.4 Dynamic TWFE event study
* ----------------------------------------------------------------------------
di as text _n "=== M&A: DYNAMIC TWFE EVENT STUDY ==="

local lag     5
local forward 7

global graph_opts1 trimlead(`forward') trimlag(`lag') together plottype(scatter)
global graph_opts2 yline(0, lpattern(dash)) ///
    ylabel(-.05(.02).05) xlabel(-`forward'(1)`lag') ///
    xtitle("Year to/from Tech M&A") ytitle("ATT (markup)")

gen time_to_treat = year - ma_tech_first_y
replace time_to_treat = -`forward' if time_to_treat <= -`forward' & !missing(time_to_treat)
replace time_to_treat =  `lag'     if time_to_treat >   `lag'     & !missing(time_to_treat)

cap drop F*event L*event
forvalues l = 0/`lag' {
    gen L`l'event = (time_to_treat ==  `l') & !missing(ma_tech_first_y)
}
forvalues l = 2/`forward' {
    gen F`l'event = (time_to_treat == -`l') & !missing(ma_tech_first_y)
}

reghdfe $y F*event L*event, a(bvdid year) vce(cluster bvdid)
est store est_OLS

testparm F2event-F7event
local f_twfe  = r(F)
local fp_twfe = r(p)
local N_obs   = e(N)

* Simple ATT for annotation
reghdfe $y ma_t_tech, a(bvdid year) vce(cluster bvdid)
local b_twfe  = _b[ma_t_tech]
local se_twfe = _se[ma_t_tech]

* ----------------------------------------------------------------------------
* 2.5 Sun & Abraham (2021) — interaction-weighted estimator
* ----------------------------------------------------------------------------
di as text _n "=== M&A: SUN & ABRAHAM ESTIMATOR ==="

* Clear stale mata objects from previous eventstudyinteract runs
capture mata: mata drop m_calckw()
capture mata: mata drop m_omega()
capture mata: mata drop ms_vcvorthog()
capture mata: mata drop s_vkernel()
mata: mata mlib index

gen never = (ma_tech_first_y == .)

qui eventstudyinteract $y L*event F*event, vce(cluster bvdid) ///
    absorb(id year) cohort(ma_tech_first_y) control_cohort(never)
est store est_SA
matrix sa_b = e(b_iw)
matrix sa_v = e(V_iw)

* Average post-treatment ATT and joint pre-trend test
ereturn post sa_b sa_v
testparm F2event-F7event
local f_sa  = r(chi2)
local fp_sa = r(p)
lincom (L0event + L1event + L2event + L3event + L4event + L5event)/6
local b_sa  = r(estimate)
local se_sa = r(se)

* Re-post stored estimates for event_plot
qui eventstudyinteract $y L*event F*event, vce(cluster bvdid) ///
    absorb(id year) cohort(ma_tech_first_y) control_cohort(never)
est store est_SA
matrix sa_b = e(b_iw)
matrix sa_v = e(V_iw)

* ----------------------------------------------------------------------------
* 2.6 Callaway & Sant'Anna (2021) — csdid
* ----------------------------------------------------------------------------
di as text _n "=== M&A: CALLAWAY & SANT'ANNA ESTIMATOR ==="

gen gvar_ma = cond(!missing(ma_tech_first_y), ma_tech_first_y, 0)

csdid $y, ivar(id) time(year) gvar(gvar_ma) long2
estat simple
matrix Bmat = r(b)
matrix Vmat = r(V)
local b_ca  = Bmat[1,1]
local se_ca = sqrt(Vmat[1,1])

csdid $y, ivar(id) time(year) gvar(gvar_ma) agg(event) long2
est store est_CA
matrix ca_b = e(b)
matrix ca_v = e(V)

* Joint pre-trend Wald test (Tm2–Tm7)
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
matrix b_pre  = R * ca_b'
matrix V_pre  = R * ca_v * R'
matrix W_ca   = b_pre' * invsym(V_pre) * b_pre
scalar wald_ca = W_ca[1,1]
scalar wald_p  = chi2tail(`ntest', wald_ca)
local wald_ca  = wald_ca
local wp_ca    = wald_p

* ----------------------------------------------------------------------------
* 2.7 Combined event-study plot (TWFE + SA + CS)
* ----------------------------------------------------------------------------
di as text _n "=== M&A: COMBINED EVENT STUDY PLOT ==="

sum $y if time_to_treat < 0 & e(sample)
local pret = r(mean)

event_plot est_OLS sa_b#sa_v est_CA, ///
    stub_lag(L#event L#event Tp#) stub_lead(F#event F#event Tm#) ///
    ${graph_opts1} perturb(-0.15(0.15)0.15) noautolegend ///
    graph_opt(${graph_opts2} ///
        title("M&A: Estimator Comparison", size(medsmall)) ///
        legend(order(1 "TWFE" 3 "Sun & Abraham (2021)" ///
                     5 "Callaway & Sant'Anna (2021)") ///
               rows(1) position(6) size(vsmall)) ///
        text(-.04 -7 ///
            "ATT: TWFE=`=string(`b_twfe',"%5.3f")' (`=string(`se_twfe',"%5.3f")')" ///
            "     S&A =`=string(`b_sa',"%5.3f")' (`=string(`se_sa',"%5.3f")')" ///
            "     C&S =`=string(`b_ca',"%5.3f")' (`=string(`se_ca',"%5.3f")')" ///
            "Pre-trend: TWFE F=`=string(`f_twfe',"%5.3f")' (p=`=string(`fp_twfe',"%4.3f")')" ///
            "           S&A chi2=`=string(`f_sa',"%5.3f")' (p=`=string(`fp_sa',"%4.3f")')" ///
            "           C&S W=`=string(`wald_ca',"%5.3f")' (p=`=string(`wp_ca',"%4.3f")')" ///
            "Pre-mean=`=string(`pret',"%5.3f")'  N=`N_obs'" ///
            , place(ll) size(vsmall) just(left))) ///
    lag_opt1(msymbol(circle_hollow)  mcolor(black))   lag_ci_opt1(color(black)) ///
    lag_opt2(msymbol(square_hollow)  mcolor(gs10))    lag_ci_opt2(color(gs10)) ///
    lag_opt3(msymbol(diamond_hollow) mcolor(ecblue))  lag_ci_opt3(color(ecblue))

graph export "${output_figures}/L2_ma_event_combined.png", replace width(5000)

* ----------------------------------------------------------------------------
* 2.8 De Chaisemartin & D'Haultfœuille (2024) — did_multiplegt_dyn
* ----------------------------------------------------------------------------
di as text _n "=== M&A: DID_MULTIPLEGT_DYN (DCDH 2024) ==="

* Diagnostic: share of firms with multiple tech M&As
preserve
    bys id: egen t_multi  = total(ma_d_tech)
    egen unique_id = tag(id)
    tab t_multi if unique_id
    tab t_multi if unique_id & t_multi > 0
restore

did_multiplegt_dyn $y id year ma_d_tech, ///
    effects(6) placebo(5) cluster(id)
estimates store dyn_dcdh

matrix b_dyn = e(b)
matrix V_dyn = e(V)
count if e(sample)
local N_obs = r(N)

* Average ATT (Effect_1..Effect_6) via delta method
matrix v_w   = J(1, 6, 1/6)
matrix V_eff = V_dyn[1..6, 1..6]
matrix v_avg = v_w * V_eff * v_w'
local b_frenchies  = (b_dyn[1,1] + b_dyn[1,2] + b_dyn[1,3] + ///
                      b_dyn[1,4] + b_dyn[1,5] + b_dyn[1,6]) / 6
local se_frenchies = sqrt(v_avg[1,1])

* Joint pre-trend Wald test (Placebo_1–Placebo_5, columns 7–11)
matrix b_plac  = b_dyn[1, 7..11]'
matrix V_plac  = V_dyn[7..11, 7..11]
matrix W_dcdh  = b_plac' * invsym(V_plac) * b_plac
scalar wald_dcdh = W_dcdh[1,1]
scalar wp_dcdh   = chi2tail(5, wald_dcdh)
local wald_fr    = wald_dcdh
local wp_fr      = wp_dcdh

di _newline "-----------------------------------------------------------"
di "Joint pre-trend test  (Placebo_1–Placebo_5, H0: all zero)"
di "  Wald chi2(5) = " %8.3f wald_dcdh
di "  Prob > chi2  = " %8.4f wp_dcdh
di "-----------------------------------------------------------"

sum $y if time_to_treat < 0
local pret = r(mean)

event_plot dyn_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
    shift(+1) trimlead(5) trimlag(6) together plottype(scatter) ///
    graph_opt(yline(0, lpattern(dash)) ///
        ylabel(-.05(.02).05) xlabel(-6(1)5) ///
        xtitle("Year to/from Tech M&A") ///
        ytitle("Average Treatment on the Treated") ///
        text(-.04 -6 ///
            "dCdH ATT = `=string(`b_frenchies',"%9.3f")' (`=string(`se_frenchies',"%9.3f")')" ///
            "Pre-mean  = `=string(`pret',"%9.3f")'" ///
            "Pre-trend Wald = `=string(`wald_fr',"%6.3f")' (p=`=string(`wp_fr',"%5.3f")')" ///
            "N = `N_obs'" ///
            , place(ll) size(vsmall) just(left))) ///
    lag_opt1(msymbol(circle_hollow) color(black)) lag_ci_opt1(color(black))

graph export "${output_figures}/L2_ma_frenchies.png", replace width(5000)

* ============================================================================
* End of lab script
* ============================================================================
