* ============================================================================
* Lab 1 Master Script: Counterfactual Framework and Selection on Observables
* PhD programme: Economics, Management and Methods for the
*                Sustainable Transition — University of Ferrara, 5 May 2026
* Author: Francesco Rentocchini
* ----------------------------------------------------------------------------
* Exercises:
*   01 — Titanic: subclassification and selection bias
*   01 — LaLonde (1986): matching, IPW, doubly robust
*        (both exercises are in 01_L1_matching.do)
* ============================================================================

* Clear memory
* ============================================================================
clear all
macro drop _all


* Create output folders if missing
* ============================================================================
cap mkdir "Figures"
cap mkdir "logs"
cap mkdir "stata_packages"
cap mkdir "temp"


* File paths (relative to Lab/L1/)
* ============================================================================
global script_path   "scripts"
global figures_path  "Figures"
global log_path      "logs"
global rootdir       `"`c(pwd)'"'


* Use local stata_packages folder
* ============================================================================
cap adopath - PERSONAL
cap adopath - SITE
cap adopath - OLDPLACE
cap adopath - PLUS
adopath + "stata_packages"
net set ado "stata_packages"


* Run flags (0 = skip; 1 = run)
* ============================================================================
global install_packages  0
global run_01_matching   1


* Open log
* ============================================================================
cap log close
local datetime : di %tcCCYY.NN.DD!-HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
local logfile "$log_path/`datetime'.log.txt"
log using "`logfile'", text

di "Begin date and time: $S_DATE $S_TIME"
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant:       `=cond( c(MP),"MP",cond(c(SE),"SE",c(flavor)) )'"
di "Processors:    `c(processors)'"
di "OS:            `c(os)' `c(osdtl)'"
di "Machine type:  `c(machine_type)'"

global date = subinstr("$S_DATE", " ", "-", .)
version 19
set linesize 255
set more off
matrix drop _all


* Graph scheme
* ============================================================================
cap set scheme plotplainblind, perm
if _rc == 111 {
    ssc install blindschemes
    cap set scheme plotplainblind, perm
}


* Install packages
* ============================================================================
if $install_packages == 1 {
    include "${script_path}/00a_packages_install.do"
}


* Housekeeping
* ============================================================================
* cap local temp: dir "temp" files "*"
* foreach file of local temp { cap erase "temp/`file'" }


* Run analysis script
* ============================================================================
if $run_01_matching == 1  include "${script_path}/01_L1_matching.do"


* Close log
* ============================================================================
di "End date and time: $S_DATE $S_TIME"
log close
