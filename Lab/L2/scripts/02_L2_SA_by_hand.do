ssc install eventstudyinteract
ssc install avar
ssc install reghdfe
ssc install ftools
ssc install require

* Load the dataset
webuse nlswork, clear
 
* Work with smaller dataset 
keep if mod(idcode,5)==0
 
* Create union cohort variable based on first union membership
gen union_year = year if union == 1
bysort idcode: egen first_union = min(union_year)
drop union_year
 
* Create relative time variable
gen ry = year - first_union
 
* Create never union indicator
gen never_union = (first_union == .)
 
* Generate relative time indicators for leads
forvalues k = 3(-1)2 {
    gen g_`k' = ry == -`k'
}
 
* Generate relative time indicators for contemporaneous and lags
forvalues k = 0/1 {
    gen g`k' = ry == `k'
}
 
* Set larger matrix size for estimation
set matsize 800
levelsof first_union, local(yearlist)
 
qui eventstudyinteract ln_wage g_* g0-g1, ///
    cohort(first_union) ///
    control_cohort(never_union) ///
    covariates(south) ///
    absorb(i.idcode i.year) ///
    vce(cluster idcode)
 
*--- Show how to replicate the weights calculation
 
* This matrix contains the weights from <eventstudyinteract>
matrix list e(ff_w)
 
* Show that I can get the same weights by 
* counting the share of (e.g.) event_time = 2
* observations that come from the 1970 cohort
count if g_2==1 & e(sample)==1
local denom = r(N)
count if g_2==1 & first_union==70 & e(sample)==1
display r(N)/`denom' // same as what's in e(ff_w)
 
* save weights to add to reghdfe implementation below 
matrix WEIGHTS = e(ff_w)
local myvarlist = ""
foreach var of varlist g_* g0-g1 {
    local myvarlist "`myvarlist' `var'"
    foreach yr of local yearlist {
        di "Year: `yr' var: `var'"
        local col = colnumb(WEIGHTS,"`var'")
        local row = rownumb(WEIGHTS,"`yr'")
        di WEIGHTS[`row',`col']
        local weight_`var'_`yr' = WEIGHTS[`row',`col']
    }
}
 
preserve 
 
* Handcode the interacted event time interactions
foreach yr of local yearlist {
    foreach var of varlist g_* g0-g1 {
        gen int_yr`yr'X`var' = (first_union==`yr')*`var'
    }
}
* Estimate the regression
regress ln_wage int_* i.south i.year, absorb(idcode)
 
* Save the results 
regsave 
split var, p("X")
drop if coef == 0
rename var2 et_name
egen year = sieve(var1), char(0123456789)
destring year, replace
gen weight = .
 
* Add in the weights 
foreach var in `myvarlist' {
    foreach yr of local yearlist {
        replace weight =  `weight_`var'_`yr'' if year==`yr' & et_name=="`var'"
    }
}
 
collapse (mean) coef [aw=weight], by(et_name)
list
restore 
 
* Run the official interaction-weighted estimator
eventstudyinteract ln_wage g_* g0-g1, ///
    cohort(first_union) ///
    control_cohort(never_union) ///
    covariates(south) ///
    absorb(i.idcode i.year) ///
    vce(cluster idcode)