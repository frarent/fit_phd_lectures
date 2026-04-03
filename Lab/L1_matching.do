* ============================================================================
* Lecture 1 Lab: Counterfactual Framework and Selection on Observables
* PhD Causal Inference — University of Ferrara, 5 May 2026
* Author: Francesco Rentocchini
* ----------------------------------------------------------------------------
* Based on: Scott Cunningham, Causal Inference: The Mixtape (2021)
*           Lab/Titanic and Lab/Lalonde — github.com/scunning1975/mixtape
* ----------------------------------------------------------------------------
* OUTPUTS
*   Figures/L1_pscore_overlap.png   — propensity score distribution before trimming
*   Figures/L1_pscore_trimmed.png   — propensity score distribution after trimming
*   Figures/L1_estimates.png        — coefficient comparison plot
* ----------------------------------------------------------------------------
* PACKAGES NEEDED (run once):
*   ssc install cem, replace
*   ssc install estout, replace
*   ssc install coefplot, replace
*   ssc install blindschemes, replace   // provides plotplainblind scheme
* ============================================================================

clear all
set more off
set seed 12345

global proj_path ".."   // set to repo root when running from Lab/ subfolder

set scheme plotplainblind

* ============================================================================
* EXERCISE 1: TITANIC — Subclassification and Selection Bias
* ============================================================================
* Question: does first-class travel raise survival probability?
* Dataset:  titanic.dta — one obs per passenger
* Treatment: first_class (1 = first class, 0 = second/third/crew)
* Outcome:  survived (1 = survived, 0 = died)
* Confounders: sex (1 = male, 0 = female), age (1 = adult, 0 = child)
* ============================================================================

* ----------------------------------------------------------------------------
* 1.1 Load data
* ----------------------------------------------------------------------------
use "https://github.com/scunning1975/mixtape/raw/master/titanic.dta", clear

* ----------------------------------------------------------------------------
* 1.2 Create treatment and stratum indicators
* ----------------------------------------------------------------------------
gen first_class = (class == 1)
label variable first_class "First-class passenger (treatment)"

gen adult_male   = (sex == 1 & age == 1)
gen adult_female = (sex == 0 & age == 1)
gen child_male   = (sex == 1 & age == 0)
gen child_female = (sex == 0 & age == 0)

* ----------------------------------------------------------------------------
* 1.3 Naive (unadjusted) estimate — ignores confounding
* ----------------------------------------------------------------------------
reg survived i.first_class, r
* Q: Why is this estimate likely to be confounded?
* A: First-class passengers are disproportionately female and adult,
*    and women/children had priority in lifeboats — selection bias.

* ----------------------------------------------------------------------------
* 1.4 Within-stratum treatment effects (survival rate differences)
* ----------------------------------------------------------------------------
foreach stratum in adult_male adult_female child_male child_female {
    qui su survived if `stratum'==1 & first_class==1
    local ey1_`stratum' = r(mean)
    qui su survived if `stratum'==1 & first_class==0
    local ey0_`stratum' = r(mean)
    local diff_`stratum' = `ey1_`stratum'' - `ey0_`stratum''
    di as text "`stratum': E[Y|D=1] = " %5.3f `ey1_`stratum'' ///
               "  E[Y|D=0] = " %5.3f `ey0_`stratum'' ///
               "  diff = " %5.3f `diff_`stratum''
}
* Note: the within-stratum differences can go in different directions!

* ----------------------------------------------------------------------------
* 1.5 Stratification-weighted ATE, ATT, ATU
* ----------------------------------------------------------------------------
* Step 1: compute stratum sizes for weighting
foreach stratum in adult_male adult_female child_male child_female {
    count if `stratum'==1
    local N_`stratum'     = r(N)
    count if `stratum'==1 & first_class==1
    local N1_`stratum'    = r(N)
    count if `stratum'==1 & first_class==0
    local N0_`stratum'    = r(N)
}
count
local N     = r(N)
count if first_class==1
local N1    = r(N)
count if first_class==0
local N0    = r(N)

* Step 2: ATE weights = stratum share in full population
local ate = 0
foreach stratum in adult_male adult_female child_male child_female {
    local wt = `N_`stratum'' / `N'
    local ate = `ate' + `wt' * `diff_`stratum''
}
di as result "Stratification ATE  = " %6.4f `ate'

* Step 3: ATT weights = stratum share among first-class (treated)
local att = 0
foreach stratum in adult_male adult_female child_male child_female {
    local wt = `N1_`stratum'' / `N1'
    local att = `att' + `wt' * `diff_`stratum''
}
di as result "Stratification ATT  = " %6.4f `att'

* Step 4: ATU weights = stratum share among non-first-class (untreated)
local atu = 0
foreach stratum in adult_male adult_female child_male child_female {
    local wt = `N0_`stratum'' / `N0'
    local atu = `atu' + `wt' * `diff_`stratum''
}
di as result "Stratification ATU  = " %6.4f `atu'

di as text ""
di as text "Compare with naive SDO:"
reg survived i.first_class, r

* Teaching point: ATE, ATT, ATU differ because the composition of
* treated (first class) and untreated groups is very different.
* ATT asks: what is the effect for first-class passengers?
* ATE asks: what would the average effect be if we randomly assigned class?

* ============================================================================
* EXERCISE 2: LALONDE (1986) — Job Training and Earnings
* ============================================================================
* Question: did the NSW job-training programme raise 1978 earnings?
* Benchmark experimental ATT ≈ $1,794 (Lalonde 1986)
*
* Strategy:
*   Part A — establish experimental benchmark
*   Part B — use CPS observational controls; show naive OLS is biased
*   Part C — IPW, PS matching, CEM, doubly robust; recover benchmark
* ============================================================================

* ----------------------------------------------------------------------------
* 2.1 Part A: Experimental benchmark
* ----------------------------------------------------------------------------
use "https://raw.github.com/scunning1975/mixtape/master/nsw_mixtape.dta", clear

* Baseline covariate balance (treated vs control in RCT)
di as text _n "=== COVARIATE BALANCE: EXPERIMENTAL SAMPLE ==="
foreach y of varlist re74 re75 marr educ age black hisp {
    qui reg `y' i.treat, r
    est store bal_`y'
}
est tab bal_*, keep(1.treat) se
est drop _all

* Experimental ATT — the benchmark we want to recover
di as text _n "=== EXPERIMENTAL ATT (benchmark) ==="
reg re78 i.treat, r
* Store the benchmark estimate
qui reg re78 i.treat, r
local b_exp   = _b[1.treat]
local se_exp  = _se[1.treat]
di as result "Experimental ATT = " %7.1f `b_exp' " (SE = " %7.1f `se_exp' ")"

* ----------------------------------------------------------------------------
* 2.2 Part B: Observational sample — append CPS controls
* ----------------------------------------------------------------------------
drop if treat==0  // keep only NSW treated units
append using "https://github.com/scunning1975/mixtape/raw/master/cps_mixtape.dta"

* Create additional covariates
gen agesq    = age^2
gen agecube  = age^3
gen edusq    = educ^2
gen u74      = (re74 == 0)
gen u75      = (re75 == 0)

global covs "age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75"

* Naive difference in means (no adjustment)
di as text _n "=== NAIVE SDO: OBSERVATIONAL SAMPLE (CPS controls) ==="
reg re78 i.treat, r
* This will be very different from $1,794 — selection bias is enormous

* OLS with controls
di as text _n "=== OLS WITH CONTROLS ==="
reg re78 treat $covs, r
local b_ols  = _b[treat]
local se_ols = _se[treat]

* ----------------------------------------------------------------------------
* 2.3 Part C1: Propensity score — estimation and overlap check
* ----------------------------------------------------------------------------
di as text _n "=== PROPENSITY SCORE ESTIMATION ==="
logit treat $covs
predict pscore, pr

* Common support check — ALWAYS look at this before any PS method
twoway (histogram pscore if treat==1, color(navy%60) lcolor(navy) ///
        width(0.02) frequency) ///
       (histogram pscore if treat==0, fcolor(none) lcolor(orange) ///
        lwidth(medium) width(0.02) frequency), ///
    legend(order(1 "NSW treated" 2 "CPS controls") size(small)) ///
    title("Propensity Score Distribution", size(medsmall)) ///
    subtitle("Before trimming", size(small)) ///
    xtitle("Estimated propensity score") ytitle("Frequency") ///
    scheme(plotplainblind)
graph export "${proj_path}/Figures/L1_pscore_overlap.png", replace width(3000)

* Problem: CPS controls have very low propensity scores — poor overlap
su pscore, detail

* ----------------------------------------------------------------------------
* 2.4 Trim to common support — permanent for all subsequent estimators
* ----------------------------------------------------------------------------
* With the full CPS sample, complete separation causes teffects to fail.
* We trim on the already-estimated pscore before any matching/weighting step.
* This is standard practice (Dehejia & Wahba 2002) and makes the overlap
* visible in the earlier histogram meaningful.
di as text _n "=== TRIMMING TO COMMON SUPPORT (0.1 < pscore < 0.9) ==="
count
drop if pscore < 0.1 | pscore > 0.9
count
di as text "Observations retained after trimming."

* Propensity score distribution after trimming
twoway (histogram pscore if treat==1, color(navy%60) lcolor(navy) ///
        width(0.02) frequency) ///
       (histogram pscore if treat==0, fcolor(none) lcolor(orange) ///
        lwidth(medium) width(0.02) frequency), ///
    legend(order(1 "NSW treated" 2 "CPS controls") size(small)) ///
    title("Propensity Score Distribution", size(medsmall)) ///
    subtitle("After trimming (0.1 < p-score < 0.9)", size(small)) ///
    xtitle("Estimated propensity score") ytitle("Frequency") ///
    scheme(plotplainblind)
graph export "${proj_path}/Figures/L1_pscore_trimmed.png", replace width(3000)

* ----------------------------------------------------------------------------
* 2.5 Part C2: IPW for ATT (manual, trimmed sample)
* ----------------------------------------------------------------------------
di as text _n "=== IPW ATT (manual, trimmed sample) ==="
* ATT weights: treated obs get weight 1; controls upweighted by p/(1-p)
gen ipw_wt = treat + (1-treat) * pscore/(1-pscore)
reg re78 i.treat [aw=ipw_wt], r
local b_ipw  = _b[1.treat]
local se_ipw = _se[1.treat]

* Stata's teffects ipw re-estimates pscore internally on the trimmed sample
teffects ipw (re78) (treat $covs, logit), atet
local b_tipw  = e(b)[1,1]
local se_tipw = sqrt(e(V)[1,1])

* ----------------------------------------------------------------------------
* 2.6 Part C3: Nearest-neighbour propensity score matching
* ----------------------------------------------------------------------------
di as text _n "=== PS MATCHING (1:1 nearest neighbour) ==="
teffects psmatch (re78) (treat $covs, logit), atet nn(1)
local b_psm  = e(b)[1,1]
local se_psm = sqrt(e(V)[1,1])

* Mahalanobis distance matching with bias adjustment
di as text _n "=== MAHALANOBIS MATCHING + BIAS ADJUSTMENT ==="
teffects nnmatch (re78 $covs) (treat), atet nn(1) metric(maha) ///
    biasadj($covs)
local b_maha  = e(b)[1,1]
local se_maha = sqrt(e(V)[1,1])

* ----------------------------------------------------------------------------
* 2.7 Part C4: Regression adjustment (outcome model only)
* ----------------------------------------------------------------------------
di as text _n "=== REGRESSION ADJUSTMENT ==="
teffects ra (re78 $covs) (treat), atet
local b_ra  = e(b)[1,1]
local se_ra = sqrt(e(V)[1,1])

* ----------------------------------------------------------------------------
* 2.8 Part C5: Coarsened Exact Matching (CEM)
* ----------------------------------------------------------------------------
di as text _n "=== COARSENED EXACT MATCHING (CEM) ==="
* Coarsen age into decadal bins; other binary vars matched exactly
cem age (10 20 30 40 60) agesq agecube educ edusq marr nodegree black hisp ///
    re74 re75 u74 u75, treatment(treat)
* cem_weights = 0 for unmatched units; > 0 for matched
reg re78 treat [iweight=cem_weights], r
local b_cem  = _b[treat]
local se_cem = _se[treat]

* How many units matched?
count if cem_weights > 0 & treat==1
di as text "Treated units matched: " r(N)
count if cem_weights > 0 & treat==0
di as text "Control units matched: " r(N)

* ----------------------------------------------------------------------------
* 2.9 Part C6: Doubly robust — manual point estimate (no SE)
* ----------------------------------------------------------------------------
* DR-ATT formula:
*
*   ATT_DR = E[Y - mu0(X) | D=1]
*          - (1/N1) * sum_{D=0} [ p(X)/(1-p(X)) * (Y - mu0(X)) ]
*
* where mu0(X) = E[Y|D=0,X] from OLS, and p(X) is the trimmed pscore.
* Doubly robust: consistent if either the outcome model OR the PS model
* is correctly specified.

di as text _n "=== DOUBLY ROBUST (manual point estimate) ==="

* Outcome model: OLS on untreated units
reg re78 $covs if treat==0
predict mu0, xb

* Part 1: mean residual for treated units
gen resid     = re78 - mu0
sum resid if treat==1
local part1 = r(mean)

* Part 2: IPW-reweighted control residuals, scaled by N_treated
count if treat==1
local n1 = r(N)
gen ipw_resid = pscore/(1-pscore) * resid
sum ipw_resid if treat==0
local part2 = r(sum) / `n1'

local b_dr  = `part1' - `part2'
local se_dr = .   // no analytic SE implemented; omit CI from plot

di as result "DR-ATT = " %7.1f `b_dr'

* ----------------------------------------------------------------------------
* 2.10 Summary table — all estimates vs. experimental benchmark
* ----------------------------------------------------------------------------
di as text _n "=== SUMMARY: All Estimates vs. Experimental Benchmark ==="
di as text "Method                     |   ATT Estimate |   SE"
di as text "---------------------------|----------------|--------"
di as text "Experimental (benchmark)   | " %14.1f `b_exp'  " | " %6.1f `se_exp'
di as text "OLS with controls          | " %14.1f `b_ols'  " | " %6.1f `se_ols'
di as text "IPW (trimmed, manual)      | " %14.1f `b_ipw'  " | " %6.1f `se_ipw'
di as text "IPW (teffects)             | " %14.1f `b_tipw' " | " %6.1f `se_tipw'
di as text "PS matching (1:1)          | " %14.1f `b_psm'  " | " %6.1f `se_psm'
di as text "Mahalanobis + bias adj.    | " %14.1f `b_maha' " | " %6.1f `se_maha'
di as text "Regression adjustment      | " %14.1f `b_ra'   " | " %6.1f `se_ra'
di as text "CEM                        | " %14.1f `b_cem'  " | " %6.1f `se_cem'
di as text "Doubly robust (manual)     | " %14.1f `b_dr'   " |    n/a  "

* ----------------------------------------------------------------------------
* 2.11 Coefficient comparison plot
* ----------------------------------------------------------------------------
* Build a small dataset from the stored locals and plot with twoway.
* This avoids coefplot's teffects naming quirks entirely.

preserve
    clear
    * row = estimator; variables: b, lo, hi, label, order
    local methods `" "RCT benchmark" "OLS" "IPW (manual)" "IPW (teffects)" "PS match" "Maha match" "Reg. adj." "CEM" "Doubly robust" "'
    local bvals   "`b_exp'  `b_ols'  `b_ipw'  `b_tipw'  `b_psm'  `b_maha'  `b_ra'  `b_cem'  `b_dr'"
    local sevals  "`se_exp' `se_ols' `se_ipw' `se_tipw' `se_psm' `se_maha' `se_ra' `se_cem' `se_dr'"

    local n : word count `bvals'
    set obs `n'
    gen order = _n
    gen b  = .
    gen lo = .
    gen hi = .

    local i 1
    foreach v of local bvals {
        replace b = `v' in `i'
        local i = `i' + 1
    }
    local i 1
    foreach s of local sevals {
        replace lo = b - 1.96*`s' in `i'
        replace hi = b + 1.96*`s' in `i'
        local i = `i' + 1
    }

    * y-axis labels: reverse order so RCT benchmark is on top
    gen ypos = `n' + 1 - order
    label define ylbl ///
        9 "RCT benchmark" 8 "OLS" 7 "IPW (manual)" 6 "IPW (teffects)" ///
        5 "PS match" 4 "Maha match" 3 "Reg. adj." 2 "CEM" 1 "DR (manual)"
    label values ypos ylbl

    * Highlight RCT benchmark in a different colour
    gen is_exp = (order == 1)

    twoway ///
        (rcap lo hi ypos if is_exp==0, horizontal lcolor(gs8) lwidth(thin)) ///
        (rcap lo hi ypos if is_exp==1, horizontal lcolor(navy) lwidth(medthick)) ///
        (scatter ypos b if is_exp==0, msymbol(circle) mcolor(gs6) msize(medsmall)) ///
        (scatter ypos b if is_exp==1, msymbol(diamond) mcolor(navy) msize(medium)), ///
        xline(0, lpattern(dash) lcolor(gs12)) ///
        xline(`b_exp', lpattern(shortdash) lcolor(navy) lwidth(thin)) ///
        xlabel(, format(%7.0f)) ///
        ylabel(1/9, valuelabel angle(0) labsize(small)) ///
        ytitle("") ///
        xtitle("ATT estimate (1978 earnings, USD)") ///
        title("LaLonde: Estimators vs. Experimental Benchmark", size(medsmall)) ///
        note("Blue line = experimental benchmark (~{c S$}1,794). 95% CIs shown." ///
             "All PS-based estimators use trimmed sample (0.1 < p-score < 0.9).") ///
        legend(off) scheme(plotplainblind)

    graph export "${proj_path}/Figures/L1_estimates.png", replace width(4000)
restore

* ============================================================================
* End of lab script
* ============================================================================
