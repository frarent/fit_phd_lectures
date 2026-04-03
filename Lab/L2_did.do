* ============================================================================
* Lecture 2 Lab: Difference-in-Differences — the Good, the Bad, and the Ugly
* PhD Causal Inference — University of Ferrara, 6 May 2026
* Author: Francesco Rentocchini
* ----------------------------------------------------------------------------
* Topics: TWFE, event study, Callaway-Sant'Anna, Sun-Abraham,
*         Bacon decomposition, HonestDiD
* ----------------------------------------------------------------------------
* Inputs:  data from material/ or replication package
* Outputs: figures → ../Figures/L2_*.png
* ============================================================================

* ----------------------------------------------------------------------------
* 0. Setup
* ----------------------------------------------------------------------------
clear all
set more off
set seed 12345

global proj_path "."

* Required packages (install once):
* ssc install reghdfe, replace
* ssc install csdid, replace
* ssc install eventstudyinteract, replace
* ssc install bacondecomp, replace
* ssc install honestdid, replace
* ssc install event_plot, replace

* ----------------------------------------------------------------------------
* 1. Load data
* ----------------------------------------------------------------------------
* TODO: load panel dataset with treatment indicator and outcome
* use "${proj_path}/data/did_data.dta", clear

* ----------------------------------------------------------------------------
* 2. TWFE static regression
* ----------------------------------------------------------------------------
* TODO: reghdfe outcome i.treated, absorb(id year) vce(cluster id)

* ----------------------------------------------------------------------------
* 3. Event study (dynamic TWFE)
* ----------------------------------------------------------------------------
* TODO: construct time_to_treat dummies; reghdfe event study
* TODO: event_plot to visualise

* ----------------------------------------------------------------------------
* 4. Bacon decomposition
* ----------------------------------------------------------------------------
* TODO: bacondecomp outcome treated, robust

* ----------------------------------------------------------------------------
* 5. Callaway & Sant'Anna (2021) — csdid with notyet
* ----------------------------------------------------------------------------
* TODO: csdid outcome covars, ivar(id) time(year) gvar(gvar) notyet long2
* TODO: estat simple; estat event

* ----------------------------------------------------------------------------
* 6. Sun & Abraham (2020) — eventstudyinteract
* ----------------------------------------------------------------------------
* TODO: eventstudyinteract outcome L*event F*event, vce(cluster id) ///
*     absorb(id year) cohort(treat_year) control_cohort(lastcohort)

* ----------------------------------------------------------------------------
* 7. Combined event-study plot (TWFE + CS + SA)
* ----------------------------------------------------------------------------
* TODO: event_plot est_OLS sa_b#sa_v est_CA, stub_lag(...) stub_lead(...)
* graph export "${proj_path}/Figures/L2_event_study.png", replace width(5000)

* ----------------------------------------------------------------------------
* 8. HonestDiD sensitivity analysis
* ----------------------------------------------------------------------------
* TODO: honestdid, pre(1/5) post(1/5) mvec(0(0.5)2)
* TODO: export sensitivity plots
