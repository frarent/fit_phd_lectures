* ============================================================================
* https://github.com/mcaceresb/stata-honestdid
* ============================================================================


* ----------------------------------------------------------------------------
* 1. Load data
* ----------------------------------------------------------------------------
local mixtape https://raw.githubusercontent.com/Mixtape-Sessions
use `mixtape'/Advanced-DID/main/Exercises/Data/ehec_data.dta, clear
l in 1/5

* ----------------------------------------------------------------------------
* 2. sample selection and treatement definition
* ----------------------------------------------------------------------------
* Keep years before 2016. Drop the 2016 cohort
keep if (year < 2016) & (missing(yexp2) | (yexp2 != 2015))

* Create a treatment dummy
gen byte D = (yexp2 == 2014)
gen `:type year' Dyear = cond(D, year, 2013)


* ----------------------------------------------------------------------------
* 3. TWFE
* ----------------------------------------------------------------------------
* Run the TWFE spec
reghdfe dins b2013.Dyear, absorb(stfips year) cluster(stfips) noconstant

local plotopts ytitle("Estimate and 95% Conf. Int.") title("Effect on dins")
coefplot, vertical yline(0) ciopts(recast(rcap)) xlabel(,angle(45)) `plotopts'

* ============================================================================
* First year post treatement (DEFAULT)
* ============================================================================

* ----------------------------------------------------------------------------
* 3 Relative magnitude
* ----------------------------------------------------------------------------
/*
Bounds on relative magnitudes. One way of formalizing this idea is to say that the violations of parallel trends in the post-treatment period cannot be much bigger than those in the pre-treatment period. This can be formalized by imposing that the post-treatment violation of parallel trends is no more than some constant 
M
¯
 larger than the maximum violation of parallel trends in the pre-treatment period. The value of 
M
¯
=
1
, for instance, imposes that the post-treatment violation of parallel trends is no longer than the worst pre-treatment violation of parallel trends (between consecutive periods). Likewise, setting 
M
¯
=
2
 implies that the post-treatment violation of parallel trends is no more than twice that in the pre-treatment period.
 */
honestdid, pre(1 2 3 4 5) post(7 8) mvec(0.5(0.5)2)
local plotopts xtitle(Mbar) ytitle(95% Robust CI)
honestdid, cached coefplot `plotopts'

* ----------------------------------------------------------------------------
* 4 Smoothness restrictions
* ----------------------------------------------------------------------------

/*
Smoothness restrictions. A second way of formalizing this is to say that the post-treatment violations of parallel trends cannot deviate too much from a linear extrapolation of the pre-trend. In particular, we can impose that the slope of the pre-trend can change by no more than M across consecutive periods, as shown in the figure below for an example with three periods.
*/

local plotopts xtitle(M) ytitle(95% Robust CI)
honestdid, pre(1/5) post(6/7) mvec(0(0.01)0.05) delta(sd) omit coefplot `plotopts'


* ============================================================================
* Average post treatement
* ============================================================================


* ----------------------------------------------------------------------------
* 5 Smoothness restrictions
* ----------------------------------------------------------------------------

matrix l_vec = 0.5 \ 0.5 // two periods
local plotopts xtitle(Mbar) ytitle(95% Robust CI)
honestdid, l_vec(l_vec) pre(1/5) post(6/7) mvec(0(0.5)2) omit coefplot `plotopts'