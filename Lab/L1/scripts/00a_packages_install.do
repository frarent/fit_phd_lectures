* ============================================================================
* Lab 1 — Package Installation
* ============================================================================

foreach name in cem estout coefplot {
    cap which `name'
    if _rc == 111 {
        ssc install `name', replace
    }
    else {
        dis in green "`name' already installed"
    }
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
