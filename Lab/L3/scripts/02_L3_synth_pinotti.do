* ============================================================================
* Lab 3 — Exercise 2: Synthetic Control
* Paper : Pinotti (2015), "The Economic Costs of Organised Crime:
*          Evidence from Southern Italy"
* Data  : dataset.dta  (Pinotti replication package)
* ----------------------------------------------------------------------------
* Research question:
*   What is the causal economic cost of organised crime on regional GDP?
*
* Design:
*   Treated unit:  Apulia + Basilicata (reg=21, pooled), free of mafia
*                  until rapid expansion driven by two exogenous shocks:
*                  (1) Tangier port closure → Adriatic smuggling route
*                  (2) Government confino relocated convicted mafia members
*   Treatment onset: 1975 (first visible spike in homicide rates)
*   Donor pool:    Northern and Central Italian regions (reg 1–14, 20)
*   Outcome:       GDP per capita (constant 1990 euros)
*   Key finding:   Mafia ⟹ −16% GDP per capita
*
* Why synth and not DiD?
*   N_treated = 2 — too small for DiD inference.
*   Synth builds a data-driven counterfactual without requiring
*   parallel trends in the traditional sense.
* ============================================================================

clear all
set more off
set seed 12345

* ----------------------------------------------------------------------------
* 2.1  Load data and explore structure
* ----------------------------------------------------------------------------
use "${data}/db_pinotti.dta", clear

* Restrict to clean period (1983+ for descriptive consistency with paper)
* Full time series needed for synth — keep all years
sum year

* Panel structure: reg (region code) × year
xtset reg year
des

tab region reg
* Region coding in this dataset:
*   reg 1–14 : Northern and Central regions (clean, donor pool)
*   reg 15–19: Southern regions with historical mafia (excluded from donor pool)
*   reg 20   : Additional clean donor region
*   reg 21   : NEW — composite treated unit (Apulia + Basilicata pooled)

di _n "=== DESIGN SUMMARY ==="
di "Treated unit: reg=21 (Apulia + Basilicata combined)"
di "Donor pool: reg 1-14 and reg 20 (15 donors)"
di "Treatment onset: 1975 (mafia expansion)"
di "Outcome: gdppercap (GDP per capita, constant 1990 euros)"

* Brief descriptive: GDP per capita pre/post 1975 for treated vs donors
tabstat gdppercap if (reg < 15 | reg == 20 | reg == 21) & year<1975, ///
    by(reg) statistics(mean) columns(statistics)



* ----------------------------------------------------------------------------
* 2.2  Pre-treatment trend: treated vs donor average
* ----------------------------------------------------------------------------
* Before running synth, visualise whether the treated unit looks like
* a reasonable convex combination of donors (convex hull inclusion check).

preserve
    keep if reg < 15 | reg == 20 | reg == 21
    collapse (mean) gdppercap if (reg < 15 | reg == 20), by(year)
    rename gdppercap gdp_donor_avg
    tempfile donors
    save `donors'
restore

preserve
    keep if reg == 21
    keep year gdppercap
    rename gdppercap gdp_treated
    merge 1:1 year using `donors', nogen

    twoway ///
        (line gdp_treated  year, lcolor(black)    lwidth(medthick)) ///
        (line gdp_donor_avg year, lcolor(gs8) lpattern(dash)), ///
        xline(1975, lcolor(red) lpattern(shortdash)) ///
        legend(order(1 "Apulia + Basilicata" 2 "Donor average") ///
               region(lcolor(none))) ///
        xtitle("") ytitle("GDP per capita (1990 euros)") ///
        title("Pre-treatment trends: treated vs donor average") ///
        note("Red line = treatment onset (1975)")
    graph export "${figures_path}/synth_pinotti_pretrend.png", replace
restore

* ----------------------------------------------------------------------------
* 2.3  Run Synthetic Control — main result (composite treated unit)
* ----------------------------------------------------------------------------
* Lecture: 'Synthetic Control: building the counterfactual'
*   W* = argmin_W || X1 - X0*W ||_V
*   Constraints: w_j >= 0, sum(w_j) = 1  [convex combination, no extrapolation]
*
* Predictor variables: GDP per capita lags + structural covariates
* Matching period: 1951–1960 (clean pre-mafia period)

di _n "=== STEP 1: MAIN SYNTHETIC CONTROL (trunit=21) ==="

* emptymat(n) must write a n×0 Stata matrix called "emat" via st_matrix().
* synth does: mat Xtr = emat, newcol  (column-bind to grow X matrix)
* A 0-column initialiser makes the first ,newcol give just newcol.
cap mata: mata drop emptymat()
mata:
real matrix emptymat(| real scalar n)
{
    if (args() == 0) n = 0
    st_matrix("emat", J(n, 0, .))
    return(J(n, 0, .))
}
end
mata: mata mlib create lsynth_compat, dir("stata_packages") replace
mata: mata mlib add lsynth_compat emptymat()
mata: mata mlib index

synth gdppercap                                          ///
    gdppercap invrate shvain shvaag shvams shvanms       ///
    shskill density,                                     ///
    trunit(21)                                           ///
    trperiod(1975)                                       ///
    xperiod(1951(1)1960)                                 ///
    mspeperiod(1951(1)1960)                              ///
    counit(1 2 3 4 5 6 7 8 9 10 11 12 13 14 20)         ///
    nested fig


* Save donor weights
mat weights_main = e(W_weights)
mat list weights_main
* Interpret: which regions receive positive weight? Sparse weights expected.

graph export "${figures_path}/synth_pinotti_main.png", replace

* ----------------------------------------------------------------------------
* 2.4  Compute and plot the treatment effect gap
* ----------------------------------------------------------------------------
* Gap = actual GDP − synthetic GDP
* Lecture: 'Application: the economic cost of organised crime'

preserve
    keep if reg < 15 | reg == 20 | reg == 21
    sort reg year
    keep gdppercap reg year
    reshape wide gdppercap, i(year) j(reg)

    * Apply weights to donors to construct synthetic control path
    mat w = weights_main[1..15, 2]
    mkmat gdppercap1-gdppercap14 gdppercap20, matrix(donors_mat)
    matrix synth_gdp = donors_mat * w
    svmat synth_gdp, name(synth_gdp)

    rename gdppercap21 actual_gdp
    gen gap_pct = (actual_gdp - synth_gdp1) / synth_gdp1 * 100

    * Plot gap
    twoway (bar gap_pct year, bcolor(gs12)) ///
        (line gap_pct year, lcolor(black) lwidth(medthick)), ///
        xline(1975, lcolor(red) lpattern(shortdash)) ///
        yline(0, lcolor(black)) ///
        legend(off) xtitle("") ytitle("GDP per capita gap (%)") ///
        title("Treatment effect: Apulia+Basilicata vs synthetic") ///
        note("Red line = treatment onset (1975). Key result: approx −16% by late 1980s.")
    graph export "${figures_path}/synth_pinotti_gap.png", replace

    * Report gap at key dates
    di _n "=== TREATMENT EFFECT (% gap) ==="
    list year gap_pct if inlist(year, 1974, 1979, 1989, 2007)
restore

* ----------------------------------------------------------------------------
* 2.5  Placebo test (permutation inference)
* ----------------------------------------------------------------------------
* Lecture: 'Inference: the placebo (permutation) test'
*   Apply synth to each donor as if it were treated in 1975.
*   p-value = share of donors with post/pre RMSPE ratio ≥ CA's ratio.
*
* Compute post/pre RMSPE ratio for each unit:
*   r_j = RMSPE_post / RMSPE_pre
*   This controls for poor pre-fit units (see lecture notes).

di _n "=== STEP 2: PLACEBO TEST (permutation inference, synth_runner) ==="

* synth_runner (Galiani & Quistorff 2017) runs synth on every donor unit,
* computes post/pre RMSPE ratios, and reports the permutation p-value.
* It requires that only valid units (treated + donors) are in the dataset.

preserve
    keep if reg < 15 | reg == 20 | reg == 21
    synth_runner gdppercap                               ///
        gdppercap invrate shvain shvaag shvams shvanms   ///
        shskill density,                                 ///
        trunit(21) trperiod(1975)                        ///
        gen_vars

    * Plot: treated vs synthetic + all placebo paths
    effect_graphs
    graph export "${figures_path}/synth_pinotti_placebo.png", replace
    pval_graphs
    graph export "${figures_path}/synth_pinotti_pval.png", replace
* effect takes time to compound -> from 1984 (1975+9) the effect is strong and stable
* In the first 5 years many donor placebos produce gaps as large as Apulia+Basilicata
restore



