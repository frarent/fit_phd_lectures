* ============================================================================
* Lab 3 — Exercise 3: Shift-Share IV (Bartik instrument)
* Paper : Autor, Dorn & Hanson (2013), "The China Syndrome:
*          Local Labor Market Effects of Import Competition in the US"
* Data  : workfile_china.dta  (ADH replication package)
* ----------------------------------------------------------------------------
* Research question:
*   What is the causal effect of Chinese import competition on US
*   manufacturing employment at the commuting-zone level?
*
* Design (two-level shift-share):
*   Level 1 — Shares (s_ln): manufacturing industry employment shares
*              in each commuting zone (CZ), measured with a 10-year lag
*   Level 2 — Shocks (g_n): growth of China's exports to 8 other
*              high-income countries (not the US) by industry
*   Instrument (z_l): z_l = Σ_n  s_ln · g_n
*
* Why this IV works:
*   CZs with a larger share of import-competing industries are more
*   exposed when China's exports surge globally. The other-country
*   exports (g_n) are exogenous to US local conditions.
*
* Identification strategy: GPSS (share exogeneity) — the lagged shares
* are pre-determined and uncorrelated with current shocks to local labour markets.
* ============================================================================

clear all
set more off
set seed 12345

* ----------------------------------------------------------------------------
* 3.1  Load data and describe structure
* ----------------------------------------------------------------------------
use "${data}/db_adh.dta", clear

* Panel: commuting zone (czone) × time period (yr: 1990=1990s, 2000=2000s)
di _n "=== DATA STRUCTURE ==="
di "Unit of observation: commuting zone × decade"
xtset czone yr
des, short
tab yr
di "N commuting zones: " _N / 2

* Key variables:
*   d_tradeusch_pw   : Δ Chinese imports per US worker (endogenous)
*   d_tradeotch_pw_lag: Δ Chinese imports per worker to 8 other countries,
*                       using lagged CZ industry shares (the IV)
*   d_sh_empl_mfg    : Δ manufacturing employment share (main outcome)
*   l_shind_manuf_cbp: lagged manufacturing employment share (control)
*   timepwt48        : population weight
*   statefip         : state FIPS (for clustering)
*   t2               : indicator for second decade (yr=2000)

label var d_tradeusch_pw    "Δ Chinese imports per US worker (endogenous)"
label var d_tradeotch_pw_lag "Shift-share IV: Δ China exports to other countries (lagged shares)"
label var d_sh_empl_mfg     "Δ manufacturing employment share (outcome)"
label var l_shind_manuf_cbp "Lagged manufacturing share (control)"

* ----------------------------------------------------------------------------
* 3.2  Descriptive: the shift-share instrument
* ----------------------------------------------------------------------------
* Lecture: 'The shift-share instrument'
*   z_l = Σ_n s_ln · g_n
*   d_tradeotch_pw_lag is the pre-constructed Bartik instrument:
*   it aggregates, for each CZ, the growth in China's exports to
*   other countries weighted by the CZ's lagged industry shares.

di _n "=== SHIFT-SHARE INSTRUMENT ==="
di "The instrument d_tradeotch_pw_lag is already constructed:"
di "  z_l = Σ_n  s_ln(t-10) · g_n(other countries)"
di ""
di "Descriptive statistics by decade:"
bysort yr: sum d_tradeusch_pw d_tradeotch_pw_lag d_sh_empl_mfg ///
    [aw=timepwt48]

* Scatter: instrument vs endogenous variable (relevance check)
twoway (scatter d_tradeusch_pw d_tradeotch_pw_lag if yr==1990 ///
        [w=timepwt48], msymbol(circle_hollow) mcolor(gs8)) ///
       (lfit   d_tradeusch_pw d_tradeotch_pw_lag if yr==1990 ///
        [aw=timepwt48], lcolor(black)), ///
    xtitle("Shift-share IV (other-country exposure)") ///
    ytitle("Δ Chinese imports per US worker") ///
    title("Instrument vs endogenous variable, 1990s") ///
    legend(off)

* ============================================================================
* Lab 3 — Exercise 3: Shift-Share IV (Bartik instrument)
* Paper : Autor, Dorn & Hanson (2013), "The China Syndrome:
*          Local Labor Market Effects of Import Competition in the US"
* Data  : workfile_china.dta  (ADH replication package)
* ----------------------------------------------------------------------------
* Research question:
*   What is the causal effect of Chinese import competition on US
*   manufacturing employment at the commuting-zone level?
*
* Design (two-level shift-share):
*   Level 1 — Shares (s_ln): manufacturing industry employment shares
*              in each commuting zone (CZ), measured with a 10-year lag
*   Level 2 — Shocks (g_n): growth of China's exports to 8 other
*              high-income countries (not the US) by industry
*   Instrument (z_l): z_l = Σ_n  s_ln · g_n
*
* Why this IV works:
*   CZs with a larger share of import-competing industries are more
*   exposed when China's exports surge globally. The other-country
*   exports (g_n) are exogenous to US local conditions.
*
* Identification strategy: GPSS (share exogeneity) — the lagged shares
* are pre-determined and uncorrelated with current shocks to local labour markets.
* ============================================================================

clear all
set more off
set seed 12345

* ----------------------------------------------------------------------------
* 3.1  Load data and describe structure
* ----------------------------------------------------------------------------
use "${data}/db_adh.dta", clear

* Panel: commuting zone (czone) × time period (yr: 1990=1990s, 2000=2000s)
di _n "=== DATA STRUCTURE ==="
di "Unit of observation: commuting zone × decade"
xtset czone yr
des, short
tab yr
di "N commuting zones: " _N / 2

* Key variables:
*   d_tradeusch_pw   : Δ Chinese imports per US worker (endogenous)
*   d_tradeotch_pw_lag: Δ Chinese imports per worker to 8 other countries,
*                       using lagged CZ industry shares (the IV)
*   d_sh_empl_mfg    : Δ manufacturing employment share (main outcome)
*   l_shind_manuf_cbp: lagged manufacturing employment share (control)
*   timepwt48        : population weight
*   statefip         : state FIPS (for clustering)
*   t2               : indicator for second decade (yr=2000)

label var d_tradeusch_pw    "Δ Chinese imports per US worker (endogenous)"
label var d_tradeotch_pw_lag "Shift-share IV: Δ China exports to other countries (lagged shares)"
label var d_sh_empl_mfg     "Δ manufacturing employment share (outcome)"
label var l_shind_manuf_cbp "Lagged manufacturing share (control)"

* ----------------------------------------------------------------------------
* 3.2  Descriptive: the shift-share instrument
* ----------------------------------------------------------------------------
* Lecture: 'The shift-share instrument'
*   z_l = Σ_n s_ln · g_n
*   d_tradeotch_pw_lag is the pre-constructed Bartik instrument:
*   it aggregates, for each CZ, the growth in China's exports to
*   other countries weighted by the CZ's lagged industry shares.

di _n "=== SHIFT-SHARE INSTRUMENT ==="
di "The instrument d_tradeotch_pw_lag is already constructed:"
di "  z_l = Σ_n  s_ln(t-10) · g_n(other countries)"
di ""
di "Descriptive statistics by decade:"
bysort yr: sum d_tradeusch_pw d_tradeotch_pw_lag d_sh_empl_mfg ///
    [aw=timepwt48]

* Scatter: instrument vs endogenous variable (relevance check dropping few outliers)
twoway (scatter d_tradeusch_pw d_tradeotch_pw_lag if yr==1990 ///
            & d_tradeusch_pw<20 & d_tradeotch_pw_lag<8 ///
        [w=timepwt48], msymbol(circle_hollow) mcolor(gs8)) ///
       (lfit   d_tradeusch_pw d_tradeotch_pw_lag if yr==1990 ///
            & d_tradeusch_pw<20 & d_tradeotch_pw_lag<8 ///
        [aw=timepwt48], lcolor(black)), ///
    xtitle("Shift-share IV (other-country exposure)") ///
    ytitle("Δ Chinese imports per US worker") ///
    title("Instrument vs endogenous variable, 1990s") ///
    legend(off)
graph export "${figures_path}/ssiv_adh_scatter_iv.png", replace

* ----------------------------------------------------------------------------
* 3.3  First stage: instrument relevance (F-statistic check)
* ----------------------------------------------------------------------------
* Rule: F > 10 for a non-weak instrument.
* Lecture: 'SSIV in practice' — first stage is the foundational check.

di _n "=== STEP 1: FIRST STAGE ==="

reg d_tradeusch_pw d_tradeotch_pw_lag ///
    [aw=timepwt48], cluster(statefip)
di _n "First stage F-statistic: " e(F)
di "Rule of thumb: F > 10 indicates a relevant instrument."

* With controls
reg d_tradeusch_pw d_tradeotch_pw_lag l_shind_manuf_cbp t2 reg* ///
    [aw=timepwt48], cluster(statefip)
di "First stage F (with region dummies): " e(F)

* ----------------------------------------------------------------------------
* 3.4  OLS benchmark — naive (biased) estimate
* ----------------------------------------------------------------------------
* OLS will be biased toward zero (attenuation) if import exposure is
* measured with error, or toward the wrong sign if regions with
* declining industries attracted more imports for unrelated reasons.

di _n "=== STEP 2: OLS BENCHMARK ==="

reg d_sh_empl_mfg d_tradeusch_pw ///
    [aw=timepwt48], cluster(statefip)
estimates store ols_base

reg d_sh_empl_mfg d_tradeusch_pw l_shind_manuf_cbp reg* t2 ///
    [aw=timepwt48], cluster(statefip)
estimates store ols_full

* ----------------------------------------------------------------------------
* 3.5  2SLS main estimate — causal effect of Chinese imports
* ----------------------------------------------------------------------------
* Identification: BHJ (Borusyak, Hull & Jaravel 2022) — shock exogeneity.
* Shocks g_n (China exports to 8 other high-income countries by industry)
* are quasi-randomly assigned across industries: the global surge in Chinese
* exports is driven by China's supply-side reforms, unrelated to US local
* labour market conditions. The shares s_ln are passive exposure weights —
* they need not be exogenous under BHJ.
* Validity requires: shocks uncorrelated with industry-level unobservables,
* and SEs clustered at the shock (industry) level.

di _n "=== STEP 3: 2SLS (SHIFT-SHARE IV, BHJ identification) ==="

* Baseline: no controls
ivregress 2sls d_sh_empl_mfg                          ///
    (d_tradeusch_pw = d_tradeotch_pw_lag)              ///
    t2  [aw=timepwt48], cluster(statefip) first
estimates store iv_base

* With region dummies (main specification in ADH Table 3, col 6)
ivregress 2sls d_sh_empl_mfg                          ///
    (d_tradeusch_pw = d_tradeotch_pw_lag)              ///
    l_shind_manuf_cbp reg* t2  [aw=timepwt48], cluster(statefip)
estimates store iv_full

* Display comparison table
esttab ols_base ols_full iv_base iv_full,       ///
    keep(d_tradeusch_pw)                               ///
    mtitles("OLS" "OLS+reg" "2SLS" "2SLS+full") ///
    title("Effect of Chinese imports on manufacturing employment share") ///
    b(%8.3f) se star(* 0.10 ** 0.05 *** 0.01) noobs

* ----------------------------------------------------------------------------
* 3.6  BHJ diagnostic 1 — cluster at the shock (industry) level
* ----------------------------------------------------------------------------
* Under BHJ, the unit of randomisation is the industry (shock).
* Adao, Kolesar & Morales (2019): CZs with similar industry shares have
* correlated residuals → SEs must be clustered at the INDUSTRY level.
* workfile_china.dta is aggregated to CZ level, so exact industry clustering
* is not possible here. State (statefip) is ADH's approximation since
* industries are geographically concentrated within states.
* For exact BHJ SEs: use ssaggregate + ivreg2 with sic87dd_trade_data.dta.

di _n "=== STEP 4: CLUSTERING — BHJ SHOCK-LEVEL APPROXIMATION ==="

* Robust SEs — for comparison; ignores shock-level correlation, too small
ivregress 2sls d_sh_empl_mfg                          ///
    (d_tradeusch_pw = d_tradeotch_pw_lag)              ///
    l_shind_manuf_cbp t2  [aw=timepwt48], robust
di "SE robust (no clustering, for comparison): " %8.4f _se[d_tradeusch_pw]
di "SEs larger with state clustering → shock-level correlation is real."

* State clustering (ADH approximation for industry-level)
ivregress 2sls d_sh_empl_mfg                          ///
    (d_tradeusch_pw = d_tradeotch_pw_lag)              ///
    l_shind_manuf_cbp t2  [aw=timepwt48], cluster(statefip)
di "SE clustered at STATE (BHJ approx): " %8.4f _se[d_tradeusch_pw]
estimates store iv_state_cluster



* ----------------------------------------------------------------------------
* 3.7  BHJ diagnostic 2 — pre-trend balance test
* ----------------------------------------------------------------------------
* Under BHJ, shocks g_n must be uncorrelated with pre-determined industry
* characteristics. At the CZ level we test whether the instrument predicts
* pre-1990 outcomes — significant results indicate the shocks correlate
* with pre-existing trends, violating BHJ's quasi-random assignment assumption.

di _n "=== STEP 5: PRE-TREND BALANCE TEST (BHJ) ==="

* Regress the IV on lagged manufacturing share in the pre-period only.
* Under BHJ: coefficient should be small and insignificant.
preserve
    use "${data}/db_adh_pre.dta",clear
    reg d_tradeotch_pw_lag_future d_sh_empl_mfg [aw=timepwt48] ///
        if yr < 1990, cluster(statefip)
    di _n "Balance: pre-determined mfg share on shift-share IV (1990s only)."
    di "Significant β → shocks correlate with pre-existing industry structure"
    di "→ BHJ quasi-random assignment is questionable for those industries."
    
    * regress past emp share on future endogenous var instrumented via future IV
    eststo: ivregress 2sls d_sh_empl_mfg (d_tradeusch_pw_future=d_tradeotch_pw_lag_future) [aw=timepwt48] if yr==1970, cluster(statefip)
    eststo: ivregress 2sls d_sh_empl_mfg (d_tradeusch_pw_future=d_tradeotch_pw_lag_future) [aw=timepwt48] if yr==1980, cluster(statefip)
    eststo: ivregress 2sls d_sh_empl_mfg (d_tradeusch_pw_future=d_tradeotch_pw_lag_future) t1980 [aw=timepwt48] if yr>=1970 & yr<1990, cluster(statefip)
    esttab , b(%9.3f) se(%9.3f) nostar r2 drop(t*) replace
restore

* ----------------------------------------------------------------------------
* 3.8  Sensitivity: alternative outcomes
* ----------------------------------------------------------------------------
* The China shock affected multiple dimensions of local labour markets.

di _n "=== STEP 7: ALTERNATIVE OUTCOMES ==="

local outcomes "d_sh_empl_nmfg d_sh_empl_nmfg_edu_c d_sh_empl_mfg_edu_c"
local labels   `""Δ non manuf" "Δ non manuf college" "Δ manuf college""'

local i = 1
foreach out of local outcomes {
    local lbl: word `i' of `labels'
    ivregress 2sls `out'                              ///
        (d_tradeusch_pw=d_tradeotch_pw_lag) ///
        l_shind_manuf_cbp l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource reg* t2 ///
        [aw=timepwt48], cluster(statefip)
    di "Outcome: `lbl'  |  β = " %6.3f _b[d_tradeusch_pw] ///
        "  SE = " %6.3f _se[d_tradeusch_pw]
    local ++i
}





