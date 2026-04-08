# Instructor Notes — Lecture 1: Counterfactual Framework and Selection on Observables

These notes record content discussed in session that extends or clarifies the slides but is not written on them. Intended as teaching aide and preparation notes.

---

## On the OLS+controls diagnostic: why a sign flip is a red flag for CIA

**Source:** `Slides/L1_counterfactual.tex`, line 372 — frame "A first attempt: just add controls to OLS", overlay 3 (sign flip case)

### The logic

A sign flip tells you the confounder X was so powerful that it was masking the true *direction* of the relationship. That has two implications:

**1. The observed controls may not be the right ones.**
You included X and the sign flipped — good, X mattered. But if a confounder that large was lurking in your error term all along, what else is? A sign flip is evidence that the selection process is more complex than your control set captures. CIA requires that *all* confounders are in X. A sign flip is circumstantial evidence that they probably were not all there to begin with.

**2. Even the controls you have may be mismeasured or too coarse.**
Even if you have the right variable, a crude proxy leaves residual selection within cells of that variable — and CIA can still fail.

### Concrete example: hospital mortality

- **Naive OLS:** hospitals are associated with *higher* mortality. Hospitals kill people?
- **Add controls for baseline health:** estimate flips negative — hospitals are now beneficial.

The flip happened because sicker people select into hospitals (negative selection: X→D positive, X→Y negative — case 2 in the same frame). Once you control for pre-admission health, the estimate corrects direction.

**But here is the problem:** how well did you measure baseline health? If your health variable is a crude proxy (e.g. one diagnosis code rather than a full severity score), there is residual selection *within* each "health group." CIA requires that conditional on X, treatment is as-good-as-random. With a noisy proxy, it is not — sicker patients are still systematically more likely to be hospitalised even within cells of your control variable.

The sign flip revealed that the selection pressure is enormous. Enormous selection pressure makes it very unlikely that a few observed controls fully absorb it.

### Practical implication for students

When you see a sign flip, you face a choice:
- Build a much richer X (more granular controls, better measured)
- Or switch to a design-based strategy (IV, DiD, RDD) that does not rely on CIA at all

The sign flip is not just a curiosity — it is diagnostic information about how hard the identification problem really is.

---

## On the DAG structure for the three coefficient/sign cases

**Source:** `Slides/L1_counterfactual.tex`, line 372 — frame "A first attempt: just add controls to OLS", overlays 1–3

The DAGs use:
- Red dashed arrows for backdoor paths (X→D, X→Y) — the "problem" paths
- Navy solid arrow for D→Y — the causal effect we want to identify

| Case | Overlay | X→D | X→Y | Effect on naive estimate |
|------|---------|-----|-----|--------------------------|
| Coef falls (positive selection) | 1 | + | + | upward bias |
| Coef rises (negative selection) | 2 | + | − | downward bias (attenuation) |
| Sign flip | 3 | ++ | −− | backdoor overwhelms β, reverses sign |

The sign flip is a quantitative extreme of the negative selection case: the backdoor path is so large in magnitude that it not only attenuates but reverses the estimated coefficient. This connects directly to the SDO decomposition two frames earlier (`Slides/L1_counterfactual.tex`, line 280 — frame "Selection bias: what goes wrong with naive comparisons", overlay 4): when the heterogeneity bias term is large, even ATT identification fails unless selection bias is exactly zero.

---

## On doubly robust estimation: formal mechanics of the two extreme cases

**Source:** `Slides/L1_counterfactual.tex`, line 741 — frame "Doubly robust estimation"

### The estimator

$$\hat\tau^{DR} = \frac{1}{N}\sum_i \underbrace{\left[\hat\mu_1(X_i) - \hat\mu_0(X_i)\right]}_{\text{(A) outcome model}} + \underbrace{\frac{D_i(Y_i - \hat\mu_1(X_i))}{\hat p(X_i)} - \frac{(1-D_i)(Y_i - \hat\mu_0(X_i))}{1-\hat p(X_i)}}_{\text{(B) IPW correction}}$$

Term (B) is a residual correction. It is zero in expectation when either model is correct.

### Case 1 — Outcome model correct, PS wrong

If $\hat\mu_d(X_i) = E[Y_i \mid D_i=d, X_i]$ exactly, then $E[Y_i - \hat\mu_1(X_i) \mid X_i, D_i=1] = 0$ and similarly for controls. The residuals in (B) have conditional expectation zero regardless of $\hat p(X_i)$. Term (B) averages to zero and the estimator collapses to regression adjustment:

$$\hat\tau^{DR} \xrightarrow{p} \frac{1}{N}\sum_i [\mu_1(X_i) - \mu_0(X_i)] = \tau^{ATE}$$

### Case 2 — PS correct, outcome model wrong

If $\hat p(X_i) = P(D_i=1 \mid X_i)$ exactly, then $E[D_i / \hat p(X_i) \mid X_i] = 1$, so:

$$E\left[\hat\mu_1(X_i)\left(1 - \frac{D_i}{\hat p(X_i)}\right)\right] = 0$$

The outcome model bias cancels in the sum (A)+(B). The estimator collapses to IPW:

$$\hat\tau^{DR} \xrightarrow{p} \frac{1}{N}\sum_i\left[\frac{D_i Y_i}{\hat p(X_i)} - \frac{(1-D_i)Y_i}{1-\hat p(X_i)}\right] = \tau^{ATE}$$

### Concrete numerical example

**Setup.** Binary $X \in \{0,1\}$, $P(X=1)=0.5$.

| | True value |
|---|---|
| PS | $p(X=0)=0.3$, $p(X=1)=0.7$ |
| Outcome model | $\mu_1(X) = 2+3X$, $\mu_0(X) = 1+X$ |
| True ATE | $E[1+2X] = 2$ |

**Researcher A: correct outcome model, wrong PS** (uses $\hat p \equiv 0.5$)
- Term (A): $E[1+2X] = 2$
- Term (B): residuals $= 0$ in expectation → correction $= 0$
- **DR = 2** ✓ despite wrong PS

**Researcher B: correct PS, wrong outcome model** (uses $\hat\mu_1 \equiv 3$, $\hat\mu_0 \equiv 1.5$)
- Term (A): $3 - 1.5 = 1.5$ (biased on its own)
- Term (B) treated: $E[\mu_1(X)] - 3 = 3.5 - 3 = +0.5$
- Term (B) control: $-(E[\mu_0(X)] - 1.5) = -(1.5-1.5) = 0$
- **DR = 1.5 + 0.5 = 2** ✓ — IPW correction exactly offsets outcome model bias

### Intuition for the classroom

The IPW correction in (B) detects how far the outcome model prediction is from the actual data, and reweights that gap by the inverse propensity score to make it representative of the population. If the PS is right, that reweighting is unbiased and the correction is exact. If the outcome model is right, there is nothing to correct. You need at least one to be right — but practically, you should try hard on both, because near-misses on both simultaneously will still produce a bad estimate.

---

## On subclassification: why ATE and ATT use different weights

**Source:** `Slides/L1_counterfactual.tex`, line 566 — frame "Subclassification", bullet "Naturally handles ATE vs. ATT (different weights)"

### The mechanism

In subclassification you compute a stratum-specific effect in each cell $k$, then take a weighted average across strata. The weights determine which estimand you recover.

**ATE — weight by population share of each stratum:**

$$\hat\tau^{\text{ATE}} = \sum_k \frac{N_k}{N} \cdot (\bar Y_k^1 - \bar Y_k^0)$$

Each stratum contributes in proportion to how large it is in the *full sample*. This answers: what would happen to a randomly drawn person from the population if we assigned treatment?

**ATT — weight by share of treated units in each stratum:**

$$\hat\tau^{\text{ATT}} = \sum_k \frac{N_k^{D=1}}{N^{D=1}} \cdot (\bar Y_k^1 - \bar Y_k^0)$$

Each stratum contributes in proportion to how many *treated* units are in it. This answers: what is the effect for those who actually received treatment?

### Why the difference matters in practice

**Titanic example:** suppose first-class passengers survive much better than third-class ones after controlling for sex and age, but third class is 55% of the ship. The ATE weights that stratum heavily. The ATT — effect on first-class passengers specifically — barely touches it. ATE and ATT will diverge.

**NSW/LaLonde example:** the training programme targeted a specific disadvantaged subpopulation. ATT asks what training did for *them* — the policy-relevant question when the programme is voluntary and self-selected. ATE asks what it would do for a randomly chosen person, including people who would never have been eligible. These are completely different policy questions.

### Why subclassification makes this explicit

Unlike OLS (which implicitly weights by variance in treatment within cells, with no transparent connection to any estimand), subclassification forces you to state the weights before computing the estimate. This transparency is one of its main virtues, and a useful pedagogical bridge to the propensity score literature where the ATE/ATT distinction reappears in the choice of IPW weights.

---

## On sections 1.4–1.5: what the calculation does and why

**Source:** `Lab/L1_matching.do`, sections 1.4–1.5

### What 1.4 does

The naive comparison (first class vs. rest) is confounded: first-class passengers are disproportionately female and adult, and women/children received lifeboat priority. To compare like with like, we split the data into four strata defined by sex × age:

| Stratum | Who |
|---|---|
| `adult_male` | Adult men |
| `adult_female` | Adult women |
| `child_male` | Male children |
| `child_female` | Female children |

Within each stratum, every passenger has the same sex and age, so those variables no longer confound the comparison. We compute:

```
diff = (survival rate, first class) − (survival rate, non-first-class)
```

separately in each group. The key result: within-stratum differences can be small or even negative even though the raw gap is large — that is the confounding at work.

### What 1.5 does

We now have four local treatment effects and need a single summary. The choice of weights determines the estimand:

- **ATE:** weight each stratum by its share in the full population. Answers: what would happen to a randomly assigned passenger?
- **ATT:** weight by share among first-class (treated). Answers: what was the effect for those who actually travelled first class?
- **ATU:** weight by share among non-first-class (untreated). Answers: what would have been the effect for those who did not travel first class?

ATE, ATT and ATU diverge because first-class passengers were compositionally different (more women, more adults). This is the core demonstration that the estimand is a real choice with real consequences.

---

## On the CIA in the Titanic exercise: remaining confounders after stratifying on sex and age

**Source:** `Lab/L1_matching.do`, sections 1.4–1.5 — discussion prompted by student question

The stratification controls for sex and age, but CIA requires that *all* confounders are accounted for. The ATE/ATT/ATU estimates are still likely biased. Plausible remaining confounders:

**Physical location on the ship.** Third-class cabins were deep in the stern, farthest from the boat deck. Within any sex × age stratum, non-first-class passengers had a longer, more obstructed path to lifeboats.

**Nationality and language.** Third-class passengers were disproportionately non-English-speaking immigrants. Crew evacuation instructions were in English; language barriers slowed response time independently of sex and age.

**Travelling alone vs. with family.** Families may have been treated differently during boarding, and group coordination affects survival. Family size correlates with class (immigrant groups often travelled together).

**Time of awareness.** First-class cabins were closer to the bridge. First-class passengers were alerted earlier, giving a better lifeboat boarding position — a mechanism separate from any preferential crew treatment.

**Physical fitness within "adult."** The binary adult/child split is coarse. A 25-year-old and a 70-year-old are coded identically, but fitness affects survival capacity and age-within-adult correlates with class.

### The broader teaching point

The CIA is fundamentally untestable. This is why researchers prefer quasi-experimental designs (DiD, RDD, IV) when available: they impose restrictions on the assignment mechanism rather than relying on the researcher's ability to observe and control all confounders. The Titanic exercise illustrates this limitation in a concrete, intuitive setting — even a careful stratification on the most obvious confounders leaves many plausible back-door paths open.
