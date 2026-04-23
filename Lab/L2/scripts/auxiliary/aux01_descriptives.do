* ----------------------------------------------------------------------------
* Author: Francesco Rentocchini
* Date: July 4, 2025
* Project Name: Superstar M&A
* Code Description:
*   Purpose: Conduct descriptive regressions on firms' performance measures
*            around tech and general M&A events, and generate plots.
*   Data Inputs: ${data_path}/db_estimates.dta
*   Outputs: Graphs exported to ${temp_path} and ${output} directories
* ----------------------------------------------------------------------------

* ----------------------------------------------------------------------------
* SECTION 1: Load Data
*   Loading the main dataset into memory
* ----------------------------------------------------------------------------
use "${data_path}/superstar.dta", clear

* ----------------------------------------------------------------------------
* SECTION 2: Global Settings and Macros
*   Define graph options, variable macros, and graph styles
* ----------------------------------------------------------------------------
global graph_opts1 trimlead(7) trimlag(5) together plottype(scatter)
global graph_opts2 yline(0, lpattern(dash)) ///
    ylabel(-.05(.02).05) xlabel(-7(1)5) ///do "//delta/jrc/B/B.6/scidata/users/FR/superstar_MA/scripts/stata_all_in_one_temp.do"
    ytitle("Average Treatment on the Treated")
global x ma_t_tech
global z
global y markupmattl_trim

local plot_labels "Markup" "Productivity" "Profit" "Capital Stock" ///
        "Size" "Patent Stock" "Age"

* Convert and generate variables
destring prodtl_trim, force replace
gen k_l_ratio = k/l

* Panel setup
xtset id year

* ----------------------------------------------------------------------------
* SECTION 3: Descriptives – Markup Only
*   Compare markup around tech vs general M&A events
* ----------------------------------------------------------------------------
* Using within variation + between firm variation within sector and region

	** comparing firm-year of tech M&A with other firm-years - NON ABSORBED
	reghdfe $y ma_d_tech, a(nace region_enc year) vce(robust)
	** comparing firm-year of tech M&A for treated group
	reghdfe $y ma_d_tech if ma_tech_first_y!=., a(nace region_enc year) vce(robust)
	** comparing firm-year of general M&A for untreated group
	reghdfe $y ma_d_all if ma_tech_first_y==., a(nace region_enc year) vce(robust)



	** comparing firm-year of tech M&A with other firm-years - ABSORBED
	reghdfe $y ma_t_tech, a(nace region_enc year) vce(robust)
	** comparing firm-year of tech M&A for treated group
	reghdfe $y ma_t_tech if ma_tech_first_y!=., a(nace region_enc year) vce(robust)
	** comparing firm-year of general M&A for untreated group
	reghdfe $y ma_t_all if ma_tech_first_y==., a(nace region_enc year) vce(robust)


* Using within variation only
	** non absorbed
	reghdfe $y ma_d_tech, a(id year) vce(cluster id)
	reghdfe $y ma_d_tech if ma_tech_first_y!=., a(id year) vce(cluster id)
	reghdfe $y ma_d_all if ma_tech_first_y==., a(id year) vce(cluster id)

	** absorbed
	reghdfe $y ma_t_tech, a(id year) vce(cluster id)
	reghdfe $y ma_t_tech if ma_tech_first_y!=., a(id year) vce(cluster id)
	reghdfe $y ma_t_all if ma_tech_first_y==., a(id year) vce(cluster id)
* ----------------------------------------------------------------------------
* SECTION 4: Descriptives – All Outcomes
*   Standardize variables and estimate across outcomes
* ----------------------------------------------------------------------------
* Standardize to common scale
foreach var of varlist markupmattl_trim prodtl_trim ebta cap_inv_PIM opre pat_stock_PIM age {
    egen `var'_std = std(`var')
}



* Label M&A indicators
label var ma_d_tech "Tech M&A"
label var ma_d_all  "General M&A"

global y_des markupmattl_trim_std prodtl_trim_std ebta_std cap_inv_PIM_std opre_std ///
    pat_stock_PIM_std age_std

* Overall group
local models ""
foreach var of global y_des {
    reghdfe `var' ma_d_tech, absorb(nace region_enc year) vce(robust)
    estimates store m_`var'
    local models "`models' m_`var'"
}
coefplot `models', keep(ma_d_tech) drop(_cons) ///
    vertical plotlabels("`plot_labels'") ///
    ciopts(recast(rcap)) legend(pos(6) col(7) size(vsmall)) yline(0) ///
    title("Overall")
graph save "${temp_path}/1.gph", replace

* Treated group only
local models ""
foreach var of global y_des {
    reghdfe `var' ma_d_tech if ma_tech_first_y!=., absorb(nace region_enc year) vce(robust)
    estimates store m_`var'
    local models "`models' m_`var'"
}
coefplot `models', keep(ma_d_tech) drop(_cons) ///
    vertical plotlabels("`plot_labels'") ///
    ciopts(recast(rcap)) legend(pos(6) col(7) size(vsmall)) yline(0) ///
    title("Treated Group")
graph save "${temp_path}/2.gph", replace

* Untreated group only
local models ""
foreach var of global y_des {
    reghdfe `var' ma_d_all if ma_tech_first_y==., absorb(nace region_enc year) vce(robust)
    estimates store m_`var'
    local models "`models' m_`var'"
}
coefplot `models', keep(ma_d_all) drop(_cons) ///
    vertical plotlabels("`plot_labels'") ///
    ciopts(recast(rcap)) legend(pos(6) col(7) size(vsmall)) yline(0) ///
    title("Untreated Group")
graph save "${temp_path}/3.gph", replace

* Combine graphs into one legend
grc1leg2 "${temp_path}/1.gph" "${temp_path}/2.gph" "${temp_path}/3.gph", ///
    cols(2) imargin(1 1 1) ycommon ring(1) position(6)
graph export "${output_figures}/des_all_outcomes_by_group.png", replace width(5000)

* ----------------------------------------------------------------------------
* SECTION 5: Pre-Treatment Comparisons
*   Compare pre-treatment performance between groups
* ----------------------------------------------------------------------------
* Flag: firms before first tech M&A vs non-tech M&A
gen flag  = 1 if ma_tech_first_y!=. & ma_d_tech==0
replace flag = 0 if ma_tech_first_y==.
label var flag "Tech M&A Group Not Yet Treated vs Non-Tech M&A"
local models ""
foreach var of global y_des {
    reghdfe `var' flag, absorb(nace region_enc year) vce(robust)
    estimates store m_`var'
    local models "`models' m_`var'"
}
coefplot `models', keep(flag) drop(_cons) ///
    vertical plotlabels("`plot_labels'") ///
	ciopts(recast(rcap)) legend(pos(6) col(7) size(vsmall)) yline(0)
graph save "${temp_path}/1.gph", replace

* Flag2: pre-first treatment period vs non-tech M&A
gen flag2 = 1 if ma_tech_first_y!=. & ma_t_tech==0
replace flag2 = 0 if ma_tech_first_y==.
label var flag2 "Tech M&A Pre-First Treatment vs Non-Tech M&A"
local models ""
foreach var of global y_des {
    reghdfe `var' flag2, absorb(nace region_enc year) vce(robust)
    estimates store m_`var'
    local models "`models' m_`var'"
}
coefplot `models', keep(flag2) drop(_cons) ///
    vertical plotlabels("`plot_labels'") ///
	ciopts(recast(rcap)) legend(pos(6) col(7) size(vsmall)) yline(0)
graph save "${temp_path}/2.gph", replace

* Flag3: both groups pre-first treatment
gen flag3 = 1 if ma_tech_first_y!=. & ma_t_tech==0
replace flag3 = 0 if ma_tech_first_y==. & ma_t_all==0
label var flag3 "Tech vs Non-Tech M&A in Pre-First Treatment"
local models ""
foreach var of global y_des {
    reghdfe `var' flag3, absorb(nace region_enc year) vce(robust)
    estimates store m_`var'
    local models "`models' m_`var'"
}
coefplot `models', keep(flag3) drop(_cons) ///
    vertical plotlabels("`plot_labels'") ///
	ciopts(recast(rcap)) legend(pos(6) col(7) size(vsmall)) yline(0)
graph save "${temp_path}/3.gph", replace

* Combine pre-treatment graphs
grc1leg2 "${temp_path}/1.gph" "${temp_path}/2.gph" "${temp_path}/3.gph", ///
    cols(2) imargin(1 1 1) ycommon ring(1) position(6)
graph export "${output_figures}/des_pretreat_comparisons.png", replace width(5000)
