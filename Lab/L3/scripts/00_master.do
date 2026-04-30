* ============================================================================
* Lab 3 Master Script: Synthetic Control, RDD and Shift-Share IV
* PhD programme: Economics, Management and Methods for the
*                Sustainable Transition — University of Ferrara, 7 May 2026
* Author: Francesco Rentocchini
* ----------------------------------------------------------------------------
* Exercises:
*   01 — Meyersson (2014): Sharp RDD, Turkish elections and female education
*   02 — Pinotti (2015): Synthetic Control, mafia and GDP per capita
*   03 — Autor, Dorn & Hanson (2013): Shift-Share IV, the China Shock
* ============================================================================

* Clear memory
* ============================================================================
clear all
macro drop _all


* Create output folders if missing
* ============================================================================
cap mkdir "temp"
cap mkdir "Figures"
cap mkdir "logs"
cap mkdir "stata_packages"


* File paths (relative to Lab/L3/)
* ============================================================================
global script_path      "scripts"
global aux              "scripts/auxiliary"
global temp_path        "temp"
global figures_path     "Figures"
global log_path         "logs"
global rootdir          `"`c(pwd)'"'
global data             "data"



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
global housekeep         0
global run_01_rdd        1
global run_02_synth      1
global run_03_ssiv       1


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


* Install packages
* ============================================================================
if $install_packages == 1 {
    include "${script_path}/00a_packages_install.do"
}


* Housekeeping
* ============================================================================
if $housekeep == 1 {
    local temp: dir "${temp_path}" files "*"
    foreach file of local temp {
        cap erase "${temp_path}/`file'"
    }
}


* Run analysis scripts
* ============================================================================
if $run_01_rdd   == 1  include "${script_path}/01_L3_rdd_meyersson.do"
if $run_02_synth == 1  include "${script_path}/02_L3_synth_pinotti.do"
if $run_03_ssiv  == 1  include "${script_path}/03_L3_ssiv_adh.do"


* Close log
* ============================================================================
di "End date and time: $S_DATE $S_TIME"
log close
