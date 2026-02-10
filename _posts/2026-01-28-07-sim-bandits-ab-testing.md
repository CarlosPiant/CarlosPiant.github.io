---
title: "Bandits & A/B Testing: Teaching Your Model to Experiment"
date: 2026-01-28
categories: [tutorials, codes]
---

# 1. Introduction: when your model has commitment issues

In a lot of applications (including HEOR and health policy), we face a recurring question:

> "Which option is better - A, B, or maybe C - and how do we **learn** that while still doing right by people?"

Three related approaches show up a lot:

- **A/B testing** - the classic: randomize, wait, analyze, *then* pick a winner.
- **Multi-armed bandits (MAB)** - adapt as you go: explore a bit, exploit a bit, repeat.
- **Contextual bandits** - like bandits, but with memory of *who* you're treating (covariates/context).

You can think of it as:

- A/B testing: "Fair, clean experiment first; decisions later."
- Multi-armed bandit: "Learn while doing; gradually play favorites."
- Contextual bandit: "Learn while doing, but tailor choices to patient characteristics."

In this tutorial we'll:

- Introduce each method with intuition,
- Work through small synthetic examples in R,
- Highlight pros and cons,
- And briefly connect them to HEOR and health policy use cases.

This will be a bit longer than other tutorials because we're packing **three** methods into one.

## Successes, rewards, and regret: quick definitions

Before we dive too deep into algorithms, it helps to clarify three key quantities we keep tracking in bandit problems:

### Successes

In a bandit setup, a *success* is simply a "good" outcome for the chosen arm.  
Examples:

- A patient **attends** a screening appointment,
- A reminder **improves** adherence,
- A message **leads** to the desired action.

In code, we usually record successes as `1` and failures as `0`, and we keep a running count of how many successes each arm has accumulated over time.

### Rewards

The **reward** is the numerical payoff we assign to each outcome.

- In simple examples, the reward is just the success indicator: 1 for success, 0 for failure.
- In more general settings, the reward could be:
  - A continuous outcome (e.g., cost savings),
  - An improvement in a risk score,
  - QALYs gained.

Bandit algorithms are designed to **maximize total reward** (or its expectation) over time.

### Regret

**Regret** measures how much better we *could* have done if we had always chosen the best possible arm at each step.

- *Instantaneous regret* at time $t$:
  
  $$
  \text{regret}_t
  =
  \text{expected reward of the best arm}
  -
  \text{expected reward of the chosen arm}.
  $$

- *Cumulative regret* up to time $T$:

  $$
  \text{Cumulative regret}(T)
  =
  \sum_{t=1}^{T} \text{regret}_t.
  $$

Low cumulative regret means the algorithm quickly learns to choose near-optimal actions. High cumulative regret means it spent a lot of time pulling suboptimal arms (for example, sticking too long with a weak intervention or over-exploring ones that don't work very well).


---

# 2. Multi-Armed Bandit (MAB): slot machines for statisticians

## 2.1. What is a multi-armed bandit?

The classic mental picture:

- You walk into a casino with several slot machines ("arms"),
- Each arm pays out with an unknown probability,
- You want to **maximize total reward** over time.

At each time $t$:

- You choose an arm $A_t$,
- You observe a reward $R_t$ (e.g., 1 for success, 0 for failure),
- You update your beliefs/policy and move on.

The **exploration-exploitation tradeoff**:

- **Explore**: try different arms to learn their payoffs,
- **Exploit**: choose the arm that currently looks best.

If you only exploit:

- You may get stuck on a suboptimal arm because early random luck favored it.

If you only explore:

- You waste time pulling obviously bad arms.

Multi-armed bandit algorithms are strategies to balance exploration and exploitation.

We'll illustrate with a simple **ε-greedy** algorithm.

---

## 2.2. Synthetic example: 3-arm Bernoulli bandit with ε-greedy

Imagine three treatments (arms):

- Arm 1: true success probability $p_1 = 0.30$,
- Arm 2: true success probability $p_2 = 0.50$,
- Arm 3: true success probability $p_3 = 0.60$ (the best).

We don't know these probabilities. We just see successes/failures.

The **ε-greedy** policy:

- With probability $\epsilon$ (e.g., 0.1): **explore** (choose a random arm),
- With probability $1 - \epsilon$: **exploit** (choose the arm with highest estimated success rate so far).

```r

set.seed(123)

# True success probabilities for the 3 arms
true_p <- c(0.30, 0.50, 0.60)
k <- length(true_p)
n_rounds <- 1000
epsilon <- 0.1

# Storage
arm_counts   <- rep(0, k)   # how many times each arm was pulled
arm_success  <- rep(0, k)   # how many successes for each arm
chosen_arm   <- integer(n_rounds)
reward       <- numeric(n_rounds)
optimal_arm  <- which.max(true_p)
regret       <- numeric(n_rounds) # instantaneous regret
```

Now we simulate:

```r

for (t in 1:n_rounds) {
  # Decide whether to explore or exploit
  if (runif(1) < epsilon || sum(arm_counts) == 0) {
    # Explore: choose an arm at random
    a_t <- sample(1:k, 1)
  } else {
    # Exploit: choose arm with highest empirical success rate
    emp_rate <- ifelse(arm_counts > 0, arm_success / arm_counts, 0)
    a_t <- which.max(emp_rate)
  }

  # Generate reward from the true Bernoulli distribution
  r_t <- rbinom(1, size = 1, prob = true_p[a_t])

  # Update
  arm_counts[a_t]  <- arm_counts[a_t] + 1
  arm_success[a_t] <- arm_success[a_t] + r_t

  chosen_arm[t] <- a_t
  reward[t]     <- r_t

  # Regret: difference between best possible expected reward and chosen arm's expected reward
  regret[t] <- max(true_p) - true_p[a_t]
}

# Cumulative reward and regret
cum_reward <- cumsum(reward)
cum_regret <- cumsum(regret)
```

### 2.3. Visualizing learning and regret

```r

library(ggplot2)
library(tidyr)
library(dplyr)

df_bandit <- data.frame(
  round = 1:n_rounds,
  cum_reward = cum_reward,
  cum_regret = cum_regret
)

df_bandit_long <- df_bandit %>%
  pivot_longer(cols = c("cum_reward", "cum_regret"),
               names_to = "metric", values_to = "value")

ggplot(df_bandit_long, aes(x = round, y = value, color = metric)) +
  geom_line() +
  labs(
    title = "Epsilon-Greedy Bandit Performance",
    x = "Round",
    y = "Value",
    color = "Metric"
  )
```

We can also see how often each arm was chosen:

```r

table(chosen_arm)
arm_counts
```

Over time, the algorithm should:

- Pull the best arm (Arm 3) more often,
- Accumulate relatively low regret,
- Still occasionally explore other arms.

---

## 2.4. Multi-armed bandit: pros and cons

**Pros**

1. **Adaptive learning**  
   Learns while acting: arms with better observed performance get more weight, potentially improving average outcomes during the learning phase.

2. **Efficient use of data**  
   Observations are concentrated on better-performing arms over time, which can be more efficient than fixed designs in some settings.

3. **Natural framework for online decision-making**  
   Ideal when decisions are sequential and you can update as new data arrive.

4. **Multiple algorithms available**  
   ε-greedy, UCB, Thompson sampling, etc., with different theoretical guarantees and practical behavior.

**Cons**

1. **Complexity vs classic trials**  
   More complex to design, analyze, and explain compared to simple A/B tests or RCTs.

2. **Bias in estimation**  
   Because assignment probabilities depend on past outcomes, naive estimators for treatment effects can be biased.

3. **Ethical / operational constraints**  
   In healthcare, continuously changing assignment probabilities may raise ethical, operational, or regulatory questions.

4. **Context ignored (in basic MAB)**  
   Standard multi-armed bandits treat all users/patients as exchangeable, ignoring covariates - which can be a big limitation in health settings.

---

# 3. Contextual Bandit: personalization meets bandits

## 3.1. What is a contextual bandit?

A **contextual bandit** extends multi-armed bandits by including **features of the current situation** (context):

- Patient-level covariates (age, comorbidities, risk scores),
- Time-varying characteristics (season, clinic, etc.).

At each step:

1. Observe context $x_t$,
2. Choose an action (arm) $A_t$,
3. Observe reward $R_t$,
4. Update a **context-dependent** policy (e.g., a model for reward given context and arm).

The goal is still to maximize cumulative reward, but:

- The best arm **depends on the context**.

This is like "personalized bandits" or "online contextual policy learning."

---

## 3.2. Synthetic example: simple contextual ε-greedy with two patient types

To keep things simple, suppose:

- 2 arms: Treatment A and Treatment B,
- Patients have a binary context: `high_risk` vs `low_risk`,
- True success probabilities:

  - For low-risk patients:
    - A: 0.8
    - B: 0.6
  - For high-risk patients:
    - A: 0.4
    - B: 0.7

So:

- Low-risk patients do better with A,
- High-risk patients do better with B.

We'll use a very simple contextual policy:

- For each arm and context, estimate success rate separately,
- Use ε-greedy **within context**.

```r

set.seed(123)

n_rounds <- 2000
epsilon  <- 0.1

# Context: high_risk (1) or low_risk (0)
# We'll simulate a mix of 60% low-risk, 40% high-risk
context <- rbinom(n_rounds, size = 1, prob = 0.4)  # 1 = high risk

# True success probabilities as a function of context and arm
true_p_context <- function(ctx, arm) {
  if (ctx == 0) { # low-risk
    if (arm == 1) return(0.8) else return(0.6)
  } else {        # high-risk
    if (arm == 1) return(0.4) else return(0.7)
  }
}

k <- 2  # two arms

# Track counts and successes by context and arm
# rows: context (0,1), cols: arm (1,2)
counts <- matrix(0, nrow = 2, ncol = k)
success <- matrix(0, nrow = 2, ncol = k)

chosen_arm <- integer(n_rounds)
reward     <- numeric(n_rounds)
optimal    <- integer(n_rounds)
regret     <- numeric(n_rounds)
```

Simulation:

```r

for (t in 1:n_rounds) {
  ctx <- context[t]       # 0 or 1
  row_idx <- ctx + 1      # map 0->1, 1->2 for matrix indexing

  # Epsilon-greedy within context
  if (runif(1) < epsilon || sum(counts[row_idx, ]) == 0) {
    a_t <- sample(1:k, 1)
  } else {
    emp_rate <- ifelse(counts[row_idx, ] > 0,
                       success[row_idx, ] / counts[row_idx, ],
                       0)
    a_t <- which.max(emp_rate)
  }

  # Generate reward
  p_true <- true_p_context(ctx, a_t)
  r_t <- rbinom(1, size = 1, prob = p_true)

  # Update
  counts[row_idx, a_t]  <- counts[row_idx, a_t] + 1
  success[row_idx, a_t] <- success[row_idx, a_t] + r_t

  chosen_arm[t] <- a_t
  reward[t]     <- r_t

  # Optimal arm for this context
  p_arm1 <- true_p_context(ctx, 1)
  p_arm2 <- true_p_context(ctx, 2)
  best_p <- max(p_arm1, p_arm2)
  regret[t] <- best_p - p_true
}

cum_reward_cb <- cumsum(reward)
cum_regret_cb <- cumsum(regret)
```

### 3.3. Comparing contextual vs non-contextual policies (sketch)

For brevity, we won't fully simulate a non-contextual bandit here, but conceptually:

- A **non-contextual** bandit would try to find one best arm for **everyone**,
- But in our setup, the best arm **depends on patient type**,
- A contextual bandit can adapt treatment choices to context and achieve higher overall reward (success rate) and lower regret.

You could implement a non-contextual ε-greedy policy on the same data and compare cumulative regret across the two policies.

### 3.4. Pros and cons of contextual bandits

**Pros**

1. **Personalization**  
   Can tailor treatment/decisions to patient covariates, potentially improving overall outcomes compared to one-size-fits-all policies.

2. **More realistic for health applications**  
   In HEOR and policy, context (risk profile, comorbidities, clinic, time) is almost always important.

3. **Bridges to supervised learning**  
   Many contextual bandit algorithms (e.g., linear models, generalized linear models, neural networks) look like supervised learning with an exploration component.

4. **Data efficiency**  
   Can share information across similar contexts, improving learning speed in rich covariate spaces.

**Cons**

1. **More complex modeling**  
   Requires modeling reward as a function of context and action, which can be statistically and computationally more demanding.

2. **Risk of model misspecification**  
   If the reward model is wrong or too rigid, the policy may learn suboptimal treatment rules.

3. **Fairness and subgroup issues**  
   If not designed carefully, contextual bandits can reinforce disparities by under-exploring certain subgroups.

4. **Implementation burden**  
   Requires infrastructure to collect covariates in real time, run the policy, and log data - non-trivial in many health systems.

---

# 4. A/B Testing: the old but reliable workhorse

## 4.1. What is A/B testing?

**A/B testing** (or controlled trials with two arms) is the classic:

1. Randomize individuals to A or B,
2. Collect outcomes,
3. Run a statistical test (e.g., difference in means/proportions),
4. Decide which arm is better (if any).

Key features:

- Assignment probabilities are usually fixed (e.g., 50/50),
- No adaptation over time,
- Analysis is usually done **after** data collection stops.

This is conceptually simple and aligns well with:

- Classical statistics,
- Regulatory standards,
- Many HEOR and clinical trial practices.

---

## 4.2. Synthetic example: simple A/B test on binary outcomes

We'll use a very similar setup as the bandit example:

- Treatment A: true success probability 0.5,
- Treatment B: true success probability 0.6.

We'll:

- Randomize 1,000 patients 50/50 A vs B,
- Observe outcomes,
- Perform a simple proportion test.

```r

set.seed(123)

n_total <- 1000
p_A <- 0.5
p_B <- 0.6

# Randomize 50/50
treatment <- sample(c("A", "B"), size = n_total, replace = TRUE)

# Generate outcomes
outcome <- ifelse(
  treatment == "A",
  rbinom(n_total, size = 1, prob = p_A),
  rbinom(n_total, size = 1, prob = p_B)
)

table(treatment, outcome)
```

We can estimate success rates and run a simple test:

```r

prop_A <- mean(outcome[treatment == "A"])
prop_B <- mean(outcome[treatment == "B"])

c(
  prop_A = prop_A,
  prop_B = prop_B,
  diff  = prop_B - prop_A
)

# 2-sample proportion test (approximate)
tab <- table(treatment, outcome)
prop.test(x = c(tab["A", "1"], tab["B", "1"]),
          n = c(sum(treatment == "A"), sum(treatment == "B")))
```

The test tells us whether the difference is statistically significant at some alpha level.

---

## 4.3. Pros and cons of A/B testing

**Pros**

1. **Simple and well-understood**  
   Easy to explain, design, and analyze. Aligns with classical statistics and clinical trial paradigms.

2. **Unbiased estimation**  
   Fixed randomization and no adaptation make standard estimators for treatment effects unbiased under usual assumptions.

3. **Regulatory familiarity**  
   Regulators and ethics boards are very familiar with RCT-style A/B designs.

4. **Clear stopping rule**  
   Pre-defined sample size and analysis plan simplify interpretation and avoid multiple-testing pitfalls (if adhered to).

**Cons**

1. **No adaptation during the trial**  
   Potentially many people receive suboptimal treatment while the trial continues.

2. **Inefficient for long-running online settings**  
   In ongoing systems (e.g., continuous patient inflows), repeated static A/B tests may be suboptimal compared to more adaptive learning strategies.

3. **Does not naturally use covariates for decision-making**  
   Although you can stratify and adjust, standard A/B tests don't adapt treatment by context during the experiment.

4. **Wasteful if one arm is clearly inferior early on**  
   The design doesn't automatically reduce assignment to inferior arms as evidence accumulates.

---

# 5. Bandits vs A/B Testing: who does what better?

Here's a high-level comparison:

- **Objective**:
  - A/B testing: estimate treatment effects accurately and test hypotheses.
  - Bandits: maximize cumulative reward (or minimize regret) while learning.

- **Ethical stance**:
  - A/B: fixed randomization, may treat many with inferior option.
  - Bandits: shift probability toward better arm(s) over time, potentially improving average outcomes.

- **Inference**:
  - A/B: standard tools (t-tests, regression, etc.) apply directly.
  - Bandits: more complex; need specialized methods to get unbiased effect estimates.

- **Context**:
  - A/B: typically not adaptive to context during the trial.
  - Contextual bandits: explicitly leverage covariates for personalization.

In HEOR and policy settings:

- A/B testing is still the default for **formal evaluation** and causal claims.
- Bandits (especially contextual) are more attractive for **ongoing operational decisions** (e.g., which outreach message, which reminder, which low-risk intervention) where we care about performance during learning.

---

# 6. Why these methods matter for HEOR and health policy

## 6.1. Multi-armed bandits

Use cases:

1. **Adaptive outreach strategies**  
   Choosing among multiple outreach methods (SMS, call, letter) to maximize screening uptake or adherence.

2. **Choosing among "good enough" options**  
   When all options are acceptable and we want to learn which works best in practice (e.g., behavioral nudges).

3. **Resource allocation in pilots**  
   Allocating limited resources among several interventions while learning which yields higher returns.

## 6.2. Contextual bandits

Use cases:

1. **Personalized adherence interventions**  
   Tailoring reminders or support intensity based on risk profile and past behavior.

2. **Targeted case management**  
   Choosing which patients receive high-touch vs low-touch care management.

3. **Adaptive clinical decision support (within constraints)**  
   Suggesting different options for low vs high-risk patients, updating over time as more data accumulate.

## 6.3. A/B testing

Use cases:

1. **Formal evaluation of interventions**  
   Classic RCT-style questions: "Does this policy or program improve outcomes compared to usual care?"

2. **Pricing, benefit design, or informational changes**  
   Evaluating different copay levels, benefit designs, or communications in controlled pilots.

3. **Baseline evidence before scaling**  
   Running a clean A/B test before adopting a new program system-wide.

A realistic HEOR toolkit will include **all three**:

- A/B tests for clear causal evidence,
- Multi-armed bandits for online optimization without context,
- Contextual bandits for personalization when context matters.

---

# 7. Further reading

1. **Lattimore & Szepesvári - _Bandit Algorithms_.**  
   Comprehensive, theory-heavy but excellent modern reference on multi-armed and contextual bandits.

2. **Scott - _A Modern Bayesian Look at the Multi-Armed Bandit_.**  
   A shorter, accessible introduction to bandits with a Bayesian flavor.

3. **Dimakopoulou et al. - _Estimation Considerations in Contextual Bandits_.**  
   Discusses how to estimate treatment effects and policies in contextual bandit settings.

4. **Kohavi et al. - _Online Controlled Experiments at Large Scale_.**  
   Focuses on A/B testing in industry; useful for thinking about how experiments are run in complex systems and what bandit-like alternatives exist.

Together, these give you enough intuition and code to start playing with bandits and A/B tests - and to think about how they might help answer HEOR and health policy questions in adaptive, data-driven ways. 😄
