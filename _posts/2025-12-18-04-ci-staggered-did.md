---
title: "Modern Difference-in-Differences with Staggered Adoption"
date: 2025-12-18
link: /tutorials/04-ci-staggered-did.html
categories: [tutorials, codes]
---

# 1. Introduction: when policies don't start on the same day

In the clean story of classic DiD, life is simple:

- One treated group,
- One comparison group,
- One magical time when the policy appears.

Reality, of course, says: **"lol, no."**

In real-world health policy:

- Some regions adopt a policy in 2015,
- Others in 2017,
- Others in 2020,
- Some never adopt it at all.

This is **staggered adoption** (or staggered rollout), and for many years the
standard fix was to just:

> Throw everything into a two-way fixed effects (TWFE) regression and call it DiD.

Something like:

$$
Y_{it} = \alpha_i + \lambda_t + \beta D_{it} + \varepsilon_{it},
$$

where:

- $\alpha_i$ are unit fixed effects,
- $\lambda_t$ are time fixed effects,
- $D_{it}$ is an indicator that unit $i$ is treated at time $t$ (regardless of when it started).

For a long time, $\hat{\beta}$ was reported as *"the DiD estimate"* in staggered designs.

Then the econometrics community showed up with a giant yellow warning sign:

- With staggered timing and **heterogeneous treatment effects over time**, TWFE
  can mix different comparisons in odd ways,
- Some comparisons get **negative weights**,
- $\hat{\beta}$ can be a strange average of very different effects, and may
  even have the opposite sign to the effect in all groups.

So: we need **modern DiD estimators** that respect staggered timing.

In this tutorial we will:

- Explain why staggered adoption is tricky for classic TWFE,
- Simulate a simple staggered policy adoption setting,
- Fit a naive TWFE model and a modern DiD estimator,
- Show how to summarize and plot group-time ATT estimates,
- Reflect on why this matters in HEOR and health policy,
- Provide references to key modern DiD papers and tools.

---

# 2. Why staggered adoption is tricky

## 2.1. The staggered setup

Imagine units $i$ (regions, hospitals, insurers) and time $t$ (years).
Different groups get treated at different times:

- Group A: treated starting in 2015,
- Group B: treated starting in 2017,
- Group C: never treated.

Once treated, they stay treated.

Let $G_i$ be the **cohort time** when unit $i$ first gets treated
(or $\infty$ if never treated).

In period $t$, the treatment indicator is:

- $D_{it} = 1$ if $t \ge G_i$ and $G_i$ is finite,
- $D_{it} = 0$ otherwise.

We may be interested in:

- **Group-time average treatment effects** $ATT(g, t)$ for units treated at time $g$ in period $t$,
- And various **aggregates** of those (e.g., overall average, dynamic effects by event time).

## 2.2. The TWFE problem

The classic TWFE regression:

$$
Y_{it} = \alpha_i + \lambda_t + \beta D_{it} + \varepsilon_{it}
$$

implicitly uses:

- **Already treated units** as controls for **newly treated units**,
- Under a parallel trends story that is hard to justify when treatment effects differ by:
  - when you were treated (cohort),
  - how long you've been treated (event time).

Recent work has shown:

- $\hat{\beta}$ is a **weighted average** of many $ATT(g, t)$ values,
- Some weights can be **negative**,
- If treatment effects grow over time, TWFE can produce misleading estimates
  (including signs that do not match any group's true effect).

This is not just a theoretical curiosity; it matters for applied work and policy conclusions.

## 2.3. Modern approach: group-time ATTs and clean aggregation

Modern DiD estimators for staggered adoption focus on:

- Estimating $ATT(g, t)$: the average treatment effect for cohort $g$ at time $t$,
  using appropriate comparison groups (e.g., never-treated and not-yet-treated units),
- Aggregating these $ATT(g, t)$'s under transparent weighting schemes
  (e.g., averaging over $(g, t)$ pairs where treatment is active).

Packages like `did` in R implement these ideas and provide:

- Group-time ATTs,
- Overall ATT,
- Event-study style dynamic effects,
- Tools for plotting and inference.

---

# 3. Example in R: synthetic staggered adoption data

We will simulate a simple panel dataset with:

- 300 units (e.g., hospitals),
- 10 time periods (e.g., years 1 to 10),
- Three cohorts:
  - Cohort 3: treated starting at time 4,
  - Cohort 5: treated starting at time 6,
  - Never-treated group,
- Treatment effects that **grow over event time** (time since adoption).

Think of $Y_{it}$ as something like:

- Average cost per patient,
- Readmission rate (in percentage points),
- A quality score.

```r

set.seed(123)

# Units and time periods
n_units   <- 300
time_vec  <- 1:10
T         <- length(time_vec)

id <- 1:n_units

# Assign cohorts:
# - First 100 units: treated starting at time 4
# - Next 100: treated starting at time 6
# - Last 100: never treated
G <- rep(Inf, n_units)          # G_i = treatment adoption time (Inf = never)
G[1:100]       <- 4
G[101:200]     <- 6
# 201:300 remain never treated

# Build panel structure
dat <- expand.grid(
  id   = id,
  time = time_vec
)

# Add cohort (G_i) and never-treated indicator
cohort_vec <- G
dat$G <- cohort_vec[dat$id]

dat$never_treated <- ifelse(is.infinite(dat$G), 1, 0)

# Treatment indicator: D_it = 1 if time >= G_i and G_i < Inf
dat$D <- ifelse(!is.infinite(dat$G) & dat$time >= dat$G, 1, 0)

# Unit fixed effects and time fixed effects
unit_fe <- rnorm(n_units, mean = 0, sd = 5)
time_fe <- rnorm(T, mean = 0, sd = 2)
names(time_fe) <- as.character(time_vec)

# Define dynamic treatment effect by event time k = t - G_i
# For k < 0: no effect
# For k >= 0: grows, then plateaus
true_effect_by_k <- function(k) {
  if (k < 0) return(0)
  if (k == 0) return(2)
  if (k == 1) return(4)
  if (k == 2) return(6)
  return(7)  # plateau
}

baseline <- 50

dat$Y <- NA_real_

for (i in seq_len(nrow(dat))) {
  this_id   <- dat$id[i]
  this_time <- dat$time[i]
  Gi        <- dat$G[i]
  
  mu_unit <- unit_fe[this_id]
  mu_time <- time_fe[as.character(this_time)]
  
  effect <- 0
  if (!is.infinite(Gi) && this_time >= Gi) {
    k <- this_time - Gi
    effect <- true_effect_by_k(k)
  }
  
  dat$Y[i] <- baseline + mu_unit + mu_time + effect + rnorm(1, 0, 5)
}

head(dat)
```

---

## 3.1. Naive TWFE DiD for comparison

Let us first fit the classic two-way fixed-effects model (the "old way"):

$$
Y_{it} = \alpha_i + \lambda_t + \beta D_{it} + \varepsilon_{it}.
$$

```r

twfe_fit <- lm(
  Y ~ D + factor(id) + factor(time),
  data = dat
)

summary(twfe_fit)$coefficients["D", ]
```

This $\hat{\beta}$ is the naive TWFE DiD estimate.

- It mixes effects from both treated cohorts at all post periods,
- Uses already-treated units as controls for later-treated units,
- With potentially weird weights if effects vary over time and across cohorts.

We will compare this to a modern estimator next.

---

## 3.2. Modern staggered-adoption DiD with `did`

We now use the `did` package, which implements the Callaway & Sant'Anna
(2021) estimator for staggered adoption.

You will need to install it once via:

```r
install.packages("did")
```

Then, in the tutorial:

```r

library(did)

# did expects:
# - yname: outcome variable
# - tname: time variable
# - idname: unit id
# - gname: first treatment period (G_i), Inf or NA for never-treated
# Here G_i is already in dat$G (Inf for never).
# We'll convert Inf to NA to indicate never-treated.

dat$G_cs <- ifelse(is.infinite(dat$G), NA, dat$G)

cs_att <- att_gt(
  yname  = "Y",
  tname  = "time",
  idname = "id",
  gname  = "G_cs",
  data   = dat,
  panel  = TRUE
)

cs_att
```

`cs_att` contains **group-time average treatment effects**:

- One estimate of $ATT(g, t)$ for each treated cohort $g$ and time $t \ge g$,
- With appropriate comparison groups (never-treated and not-yet-treated).

We can then aggregate these in several ways.

---

## 3.3. Aggregating and plotting effects

### 3.3.1. Overall average treatment effect on the treated (ATT)

```r

agg_simple <- aggte(cs_att, type = "simple")
agg_simple

summary(agg_simple)
```

This provides an overall ATT, which we can compare conceptually with the TWFE estimate.

### 3.3.2. Dynamic (event-study style) effects

We can also aggregate by **event time** (time since adoption), similar to the
event-study chapter:

```r

agg_event <- aggte(cs_att, type = "event")
summary(agg_event)
```

`agg_event` includes:

- `egt`: event times (e.g., 0, 1, 2, 3, ...),
- `att.egt`: estimated effects at each event time,
- standard errors and confidence intervals.

We can plot these using base `plot()` or `ggplot2`. Here is a simple base R example:

```r

plot(
  agg_event,
  xlab = "Event time (years since adoption)",
  ylab = "Estimated ATT",
  main = "Event-Study Aggregation of Staggered DiD (Callaway & Sant'Anna)"
)
```

The shape should resemble the **true dynamic effect pattern** we built into the simulation:

- A modest effect at event time 0,
- Growing effect over the next few periods,
- A plateau at later event times.

---

# 4. Interpreting and communicating staggered DiD results

With modern staggered-adoption DiD, we can clearly separate:

1. **Group-time ATTs**: $ATT(g, t)$  
   "For the cohort treated in year 4, what was the effect in year 7?"

2. **Overall ATT**:  
   "On average, across all treated cohorts and post-treatment periods, what is the treatment effect?"

3. **Dynamic (event-time) effects**:  
   "How does the effect evolve as time since adoption increases?"

This structure is powerful for HEOR and health policy because it allows us to:

- Explore **heterogeneity by cohort** (e.g., early vs late adopters),
- Describe **implementation dynamics** (e.g., first year vs third year after reform),
- Provide **transparent summaries** for decision-makers ("here's the overall average effect, and here's how it builds over time").

At the same time, it avoids the pitfalls of:

- Negative weights and opaque mixtures of effects,
- Comparisons where already-treated units act as controls for newly-treated units in problematic ways.

---

# 5. Why modern staggered DiD matters for HEOR and health policy

## 5.1. Many real policies are rolled out gradually

In HEOR and health policy, staggered adoption is everywhere:

- Regional rollouts of insurance expansions (e.g., different states, different years),
- Gradual adoption of new payment models,
- Phased implementation of clinical guidelines or quality programs,
- Hospital systems adopting programs at different times.

Using outdated methods in these settings can:

- Lead to biased estimates,
- Under- or over-state policy effects,
- Mislead budgeting and coverage decisions.

Modern DiD provides more credible and interpretable estimates.

## 5.2. Dynamic impacts are often the main story

For a policymaker, it often matters **when** and **how** effects appear:

- Is there a big startup cost or learning curve?
- Do benefits phase in over several years?
- Do effects persist or fade out?

Staggered adoption + dynamic aggregation lets us answer:

- "By the third year after adoption, what is the average impact on utilization/cost/outcomes?"

These answers can inform:

- Long-term planning and sustainability,
- Decisions about scaling up or modifying the policy,
- Equity analyses (e.g., early vs late adopters, rural vs urban).

## 5.3. Aligning practice with current methodological standards

HEOR work is increasingly scrutinized by:

- HTA bodies,
- Journals,
- Peer reviewers familiar with modern causal inference.

Using modern DiD methods in staggered designs:

- Shows that you are **aligned with current best practice**,
- Reduces the risk that a reviewer points out negative-weight issues post-hoc,
- Makes your estimates more robust and defensible for policy use.

---

# 6. Further reading

To go deeper into modern staggered-adoption DiD (concepts + implementation), these are excellent starting points:

1. **Callaway & Sant'Anna (2021). _Difference-in-Differences with Multiple Time Periods._ Journal of Econometrics.**  
   Introduces a general framework and estimators for DiD with multiple periods and staggered treatment timing. Basis for the `did` package.

2. **Goodman-Bacon (2021). _Difference-in-Differences with Variation in Treatment Timing._ Journal of Econometrics.**  
   Decomposes the TWFE DiD estimator into weighted comparisons and shows where the problems come from in staggered settings.

3. **de Chaisemartin & D'Haultfoeuille (2020, 2022). _Two-Way Fixed Effects Estimators with Heterogeneous Treatment Effects._**  
   Proposes alternative estimators and diagnostics when using TWFE in the presence of heterogeneous effects.

4. **Roth et al. (2023). _What's Trending in Difference-in-Differences? A Synthesis of the Recent Econometrics Literature._**  
   A very helpful big-picture overview of recent advances in DiD, including staggered adoption and event-study designs.

Armed with these methods, you are well-equipped to analyze **real-world, messy policy rollouts** in a way that is both cutting-edge and understandable to HEOR and policy audiences. 😄
