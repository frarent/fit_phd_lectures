* ============================================================================
* Lab 3 — Package Installation
* ============================================================================

* RDD packages (Cattaneo, Idrobo & Titiunik 2019)
foreach name in rdrobust rddensity lpdensity {
    cap which `name'
    if _rc == 111 {
        ssc install `name', replace
    }
    else {
        dis in green "`name' already installed"
    }
}

* Synthetic control
foreach name in synth  {
    cap which `name'
    if _rc == 111 {
        ssc install `name'
    }
    else {
        dis in green "`name' already installed"
    }
}

net install st0500.pkg // synth_runner for full set of placebo test

* IV and output packages
foreach name in ivreg2 ranktest estout coefplot {
    cap which `name'
    if _rc == 111 {
        ssc install `name'
    }
    else {
        dis in green "`name' already installed"
    }
}

* Shift-share aggregate (Borusyak, Hull, Jaravel)
cap which ssaggregate
if _rc == 111 {
    ssc install ssaggregate, replace
}
else {
    dis in green "ssaggregate already installed"
}

* Graph scheme
foreach name in plotplainblind {
    cap set scheme `name', perm
    if _rc == 111 {
        ssc install blindschemes
        cap set scheme `name', perm
    }
    else {
        dis in green "blindschemes already installed"
    }
}
