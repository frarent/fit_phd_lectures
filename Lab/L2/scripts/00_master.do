*=============================================================================*
* Project title: Walking the Green Line: Government Sponsored R&D
*                and Clean Technologies in the US
* Created by: Francesco Rentocchini and Gianluca Orsatti
* Date: 16/04/2026
*=============================================================================*

// Clear Memory
*=============================================================================*
clear all
macro drop _all


// Create file paths
*=============================================================================*

cap mkdir "temp"
cap mkdir "figures"
cap mkdir "logs"
cap mkdir "stata_packages"


// Set your file paths (relative to project root)
*=============================================================================*

global data_path         "data"
global temp_path         "temp"
global output_figures    "figures"
global log_path          "logs"
global script_path		 "scripts"
global aux				 "scripts/auxiliary"
global rootdir `"`c(pwd)'"'


// Use included packages (local stata_packages folder)
*=============================================================================*

cap adopath - PERSONAL
cap adopath - SITE
cap adopath - OLDPLACE
cap adopath - PLUS
adopath + "stata_packages"
net set ado "stata_packages"


// Set options (0 = skip; 1 = run)
*=============================================================================*

// Install required packages
global install_packages  0

global housekeep 0

// Initialize log and record system parameters
*=============================================================================*

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

// Set date
global date = subinstr("$S_DATE", " ", "-", .)

// Stata version
version 19

// Screen width for log files
set linesize 255

// Allow screen to move without clicking more
set more off

// Drop everything in mata
matrix drop _all


// Run do-files
*=============================================================================*

// Install required packages
if $install_packages == 1 {
	include "${script_path}/00a_packages_install.do"
}


// Housekeeping (clear temp folder)
*=============================================================================*
if $housekeep == 1 {
	local temp: dir "${temp_path}" files "*"
	dis `temp'

	foreach file of local temp {
		cap erase "${temp_path}/`file'"
	}
}


// End log
*=============================================================================*
di "End date and time: $S_DATE $S_TIME"
log close
