//-----------------------------------------------------------------
//EXTERNAL PACKAGES
//-----------------------------------------------------------------

*packages
foreach name in  ///
	event_plot coefplot /// coeff graph plots
	honestdid /// honest did by Roth
	reghdfe ftools require /// high dimensional FE regressions
	csdid drdid estout /// Callaway and Sant'Anna
	grc1leg2 /// graph combine with common label
	eventstudyinteract avar /// Sun and Abraham
	did_multiplegt_dyn gtools /// Frenchies estimator
	regsave egenmore ///
		{
		cap which `name'
		if _rc==111 {
			ssc install `name'
			}
		else {
			dis in red "`name' package already installed"
			}
	}

*graph scheme pack
foreach name in plotplainblind {
cap	set scheme `name' ,perm
		if _rc==111 {
			ssc install blindschemes
			cap	set scheme `name' ,perm
			}
		else {
			dis in red "blindschemes graph scheme already installed"
			}
	}


