# Applied Causal Inference: A Gentle Stroll Down the Rabbit Hole

**PhD Programme in Economics, Management and Methods for the Sustainable Transition**  
University of Ferrara · 5–7 May 2026 · Instructor: Francesco Rentocchini (JRC-Seville / DEMM, University of Milan)

---

## Course overview

Three lectures on quasi-experimental methods with theory and hands-on Stata replication labs. Each lecture pairs a methodological framework with one or more published applications.

| # | Title | Date | Hours |
|---|-------|------|-------|
| L1 | *Counterfactual Framework and Methods Based on Selection on Observables: 'Cause We Are Living in a Counterfactual World* | 5 May AM | 3.5h |
| L2 | *Difference-in-Differences: the Good, the Bad and the Ugly* | 5 May PM + 6 May | 8h |
| L3 | *Of Synthetic Realms, Discontinuities and Shift-Shares or: How I Learned to Stop Worrying and Love the Process* | 7 May AM | 4h |

Full syllabus: [`syllabus.pdf`](syllabus.pdf)

---

## Repository structure

```
Lab/
 ├── L1/  01_L1_matching.do            — matching & IPW (Titanic, LaLonde 1986)
 ├── L2/  00_master.do                 — run all L2 exercises
 │        01_L2_did_clean.do           — DiD (Rizzo et al. 2025, Dpt of Excellence + Rentocchini, M&A)
 │        02_L2_SA_by_hand.do          — Sun & Abraham by hand
 │        03_HonestDID.do              — HonestDiD sensitivity bounds
 └── L3/  00_master.do                 — run all L3 exercises
          01_L3_rdd_meyersson.do       — sharp RDD (Meyersson 2014)
          02_L3_synth_pinotti.do       — synthetic control (Pinotti 2015)
          03_L3_ssiv_adh.do            — shift-share IV (Autor, Dorn & Hanson 2013)
```

Each lab folder follows the same layout: `scripts/`, `data/`, `Figures/`, `logs/`, `stata_packages/`.

---

## Getting started

All lab sessions use **Stata 19** (should work on previous versions as well). Open the corresponding Stata project file (e.g. `lab2.stpr`) within each lecture's `Lab/LN/` directory; required packages are bundled in the repository — no need to install packages separately.

---

## Applications covered

| Exercise | Paper / dataset | Method | Key finding |
|---|---|---|---|
| L1-1 | Titanic passengers | Potential outcomes / selection bias | Why raw survival rates mislead: selection on observables |
| L1-2 | LaLonde (1986) | Matching / IPW | Experimental vs. observational gap in training returns |
| L2-1 | Rizzo et al. (2025) | DiD event study + CS estimator | Italian Excellence Initiative → faculty recruitment |
| L2-2 | Rentocchini et al. (2025) | TWFE + dCdH | Tech M&A → firm-level markups |
| L3-1 | Meyersson (2014) | Sharp RDD | Islamic mayors → +4.4 pp female HS completion |
| L3-2 | Pinotti (2015) | Synthetic control | Mafia expansion → −16% GDP per capita |
| L3-3 | Autor, Dorn & Hanson (2013) | Shift-share IV | China shock → −0.6 pp manufacturing employment |

---

## Slides & notes

Slides (`Slides/`) and instructor notes (`notes/`) are excluded from version control and will be made available after the 7th of May.

---

## License

Code released under MIT. Replication data belong to the original authors — see each paper for terms.
