---
title: "Simulating Poisson Data"
date: 2026-03-09
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which the outcome is the number of outpatient doctor visits observed over a follow-up period. The aim is to build a count variable whose true generating process is known in..."
excerpt: "Creating synthetic count outcomes from a log-linear mean model"
---
This chapter creates a synthetic dataset in which the outcome is the number of outpatient doctor visits observed over a follow-up period. The aim is to build a count variable whose true generating process is known in advance, so that a fitted Poisson regression can be checked against the truth. The design is inspired by the count-data applications discussed by Cameron and Trivedi, where outcomes such as doctor visits, hospital use, or service contacts are modeled as non-negative integers rather than as continuous variables.

The practical reason to simulate Poisson data is simple. Count outcomes appear everywhere in health economics and health systems research: number of primary-care visits, emergency department contacts, admissions, prescriptions, missed appointments, or claims. If the underlying mean structure is log-linear, then Poisson regression is the natural first model to test. Simulation makes that structure visible.

## What variables will be created

The synthetic sample will represent patients followed for outpatient utilization after discharge. `age` will represent age in years. `chronic` will count the number of chronic conditions. `female` will be a binary indicator. `poor_health` will indicate a high self-reported burden of illness. `months_observed` will record the amount of follow-up time available for each patient. The outcome `doctor_visits` will count how many outpatient visits occur during that period.

These variables are chosen because they reproduce the basic ingredients of a count-data application: baseline risk factors, a follow-up window, and an event count whose expected value changes systematically across patients.

## The data-generating process

The Poisson model assumes that conditional on the covariates, the count outcome follows

$$
Y_i \sim \text{Poisson}(\mu_i),
$$

with mean

$$
\mu_i = t_i \exp(\eta_i),
$$

where $t_i$ is the exposure time and

$$
\eta_i =
\beta_0 +
\beta_1 \text{age}_i +
\beta_2 \text{chronic}_i +
\beta_3 \text{female}_i +
\beta_4 \text{poor\_health}_i.
$$

For this simulation, the true coefficients are set to

$$
\beta_0 = -1.55,\;
\beta_1 = 0.012,\;
\beta_2 = 0.22,\;
\beta_3 = 0.10,\;
\beta_4 = 0.55.
$$

The quantity $t_i$ is important. If one patient is observed for 12 months and another for only 6 months, the longer-observed patient has more time to accumulate visits. That is why Poisson models for utilization often include an offset term such as $\log(t_i)$.

## Step 1: Generate the synthetic sample

``` r
set.seed(2026)

n <- 7000

age <- pmax(round(rnorm(n, mean = 59, sd = 13)), 18)
chronic <- pmin(rpois(n, lambda = 1.7), 6)
female <- rbinom(n, size = 1, prob = 0.56)
poor_health <- rbinom(
 n,
 size = 1,
 prob = plogis(-1.2 + 0.45 * chronic + 0.015 * (age - 60))
)
months_observed <- sample(6:12, size = n, replace = TRUE)

eta <- -1.55 +
 0.012 * age +
 0.22 * chronic +
 0.10 * female +
 0.55 * poor_health

true_rate <- exp(eta)
true_mean <- months_observed * true_rate

doctor_visits <- rpois(n, lambda = true_mean)

synthetic_visits <- data.frame(
 doctor_visits,
 age,
 chronic,
 female,
 poor_health,
 months_observed,
 true_rate,
 true_mean
)

simulation_summary <- data.frame(
 sample_size = nrow(synthetic_visits),
 mean_visits = mean(synthetic_visits$doctor_visits),
 mean_age = mean(synthetic_visits$age),
 mean_chronic = mean(synthetic_visits$chronic),
 mean_followup_months = mean(synthetic_visits$months_observed)
)

simulation_summary[, c("mean_visits", "mean_age", "mean_chronic", "mean_followup_months")] <-
 round(simulation_summary[, c("mean_visits", "mean_age", "mean_chronic", "mean_followup_months")], 3)

knitr::kable(
 simulation_summary,
 caption = "Summary of the synthetic Poisson dataset"
)
```

Table: Summary of the synthetic Poisson dataset

| sample_size| mean_visits| mean_age| mean_chronic| mean_followup_months|
|-----------:|-----------:|--------:|------------:|--------------------:|
| 7000| 8.403| 59.046| 1.699| 8.987|

This code builds the covariates first, then transforms them into a conditional mean through the exponential link, and finally draws counts from a Poisson distribution. The model therefore has a deterministic part, $\mu_i$, and a stochastic part, the Poisson draw around that mean.

## Step 2: Fit the Poisson model that matches the truth

Now fit the same log-linear model used to generate the data:

``` r
poisson_fit <- glm(
 doctor_visits ~ age + chronic + female + poor_health + offset(log(months_observed)),
 data = synthetic_visits,
 family = poisson
)

truth <- c(
 "(Intercept)" = -1.55,
 age = 0.012,
 chronic = 0.22,
 female = 0.10,
 poor_health = 0.55
)

comparison_table <- data.frame(
 term = names(coef(poisson_fit)),
 true_value = truth[names(coef(poisson_fit))],
 estimated_value = coef(poisson_fit)
)

comparison_table$bias <- comparison_table$estimated_value - comparison_table$true_value
comparison_table[, c("true_value", "estimated_value", "bias")] <-
 round(comparison_table[, c("true_value", "estimated_value", "bias")], 3)

knitr::kable(
 comparison_table,
 caption = "True and estimated coefficients under the correctly specified Poisson model"
)
```

Table: True and estimated coefficients under the correctly specified Poisson model

| |term | true_value| estimated_value| bias|
|:-----------|:-----------|----------:|---------------:|------:|
|(Intercept) |(Intercept) | -1.550| -1.552| -0.002|
|age |age | 0.012| 0.012| 0.000|
|chronic |chronic | 0.220| 0.221| 0.001|
|female |female | 0.100| 0.100| 0.000|
|poor_health |poor_health | 0.550| 0.547| -0.003|

As in the earlier simulation chapters, the key question is whether the fitted model recovers the parameters we used to create the data. Because the model is correctly specified and the sample is fairly large, the answer should be approximately yes.

## Step 3: Compare expected counts across patient profiles

Coefficients on the log scale are useful, but expected counts are easier to interpret. The next block compares the true and fitted mean number of visits for a sequence of chronic-condition counts under two health-status profiles.

``` r
profiles <- expand.grid(
 chronic = 0:6,
 poor_health = c(0, 1)
)

profiles$age <- 60
profiles$female <- 1
profiles$months_observed <- 12

profiles$true_mean <- profiles$months_observed * exp(
 -1.55 +
 0.012 * profiles$age +
 0.22 * profiles$chronic +
 0.10 * profiles$female +
 0.55 * profiles$poor_health
)

profiles$fitted_mean <- predict(poisson_fit, newdata = profiles, type = "response")
profiles$health_status <- ifelse(profiles$poor_health == 1, "Poor health", "Better health")

ggplot2::ggplot(
 profiles,
 ggplot2::aes(x = chronic, color = health_status)
) +
 ggplot2::geom_line(
 ggplot2::aes(y = true_mean),
 linewidth = 1.1
 ) +
 ggplot2::geom_line(
 ggplot2::aes(y = fitted_mean),
 linetype = 2,
 linewidth = 0.9
 ) +
 ggplot2::labs(
 title = "True and fitted mean visit counts in the synthetic Poisson dataset",
 subtitle = "Solid lines show the generating means; dashed lines show the fitted model",
 x = "Number of chronic conditions",
 y = "Expected doctor visits over 12 months",
 color = "Profile"
 ) +
 ggplot2::scale_color_manual(values = c("#3d5a80", "#bc6c25")) +
 ggplot2::theme_minimal(base_size = 12)
```

![plot of chunk unnamed-chunk-3](/tutorials/rendered-assets/simulation-tools-simulating-poisson-data/unnamed-chunk-3-1.png)

When the dashed lines remain close to the solid lines, the fitted model is reproducing the conditional mean structure correctly. That is exactly what we want in a well-behaved Poisson simulation.

## Step 4: Check the rate ratios

Poisson regression is often interpreted through rate ratios, which are obtained by exponentiating the coefficients.

``` r
rate_ratio_table <- data.frame(
 term = comparison_table$term,
 true_rate_ratio = exp(comparison_table$true_value),
 estimated_rate_ratio = exp(comparison_table$estimated_value)
)

rate_ratio_table[, c("true_rate_ratio", "estimated_rate_ratio")] <-
 round(rate_ratio_table[, c("true_rate_ratio", "estimated_rate_ratio")], 3)

knitr::kable(
 rate_ratio_table,
 caption = "True and estimated rate ratios in the synthetic Poisson dataset"
)
```

Table: True and estimated rate ratios in the synthetic Poisson dataset

|term | true_rate_ratio| estimated_rate_ratio|
|:-----------|---------------:|--------------------:|
|(Intercept) | 0.212| 0.212|
|age | 1.012| 1.012|
|chronic | 1.246| 1.247|
|female | 1.105| 1.105|
|poor_health | 1.733| 1.728|

For example, the true coefficient on `poor_health` is $0.55$, which corresponds to a rate ratio of about $\exp(0.55) = 1.73$. That means patients in poor health are designed to have about 73% more visits per unit of follow-up time than otherwise similar patients who are not in poor health.

## Step 5: Compare observed and theoretical count frequencies

One of the simplest diagnostics is to compare the observed distribution of counts for a reference subgroup with the Poisson probabilities implied by that subgroup's mean.

``` r
reference_group <- subset(
 synthetic_visits,
 chronic == 1 & poor_health == 0 & female == 1 & months_observed == 12
)

max_count <- min(12, max(reference_group$doctor_visits))
count_support <- 0:max_count

observed_counts <- table(factor(reference_group$doctor_visits, levels = count_support))
observed_prob <- as.numeric(observed_counts) / sum(observed_counts)

lambda_reference <- 12 * exp(-1.55 + 0.012 * 60 + 0.22 * 1 + 0.10 * 1 + 0.55 * 0)
theoretical_prob <- dpois(count_support, lambda = lambda_reference)

distribution_check <- data.frame(
 count = count_support,
 observed_probability = observed_prob,
 theoretical_probability = theoretical_prob
)

distribution_check[, c("observed_probability", "theoretical_probability")] <-
 round(distribution_check[, c("observed_probability", "theoretical_probability")], 3)

knitr::kable(
 distribution_check,
 caption = "Observed and theoretical count probabilities for a reference subgroup"
)
```

Table: Observed and theoretical count probabilities for a reference subgroup

| count| observed_probability| theoretical_probability|
|-----:|--------------------:|-----------------------:|
| 0| 0.000| 0.001|
| 1| 0.000| 0.005|
| 2| 0.034| 0.019|
| 3| 0.042| 0.046|
| 4| 0.102| 0.083|
| 5| 0.144| 0.120|
| 6| 0.136| 0.144|
| 7| 0.102| 0.149|
| 8| 0.127| 0.134|
| 9| 0.127| 0.107|
| 10| 0.068| 0.077|
| 11| 0.085| 0.051|
| 12| 0.034| 0.030|

``` r
distribution_plot <- rbind(
 data.frame(
 count = count_support,
 probability = observed_prob,
 source = "Observed"
 ),
 data.frame(
 count = count_support,
 probability = theoretical_prob,
 source = "Theoretical Poisson"
 )
)

ggplot2::ggplot(distribution_plot, ggplot2::aes(x = count, y = probability, fill = source)) +
 ggplot2::geom_col(position = "dodge") +
 ggplot2::labs(
 title = "Observed and theoretical count frequencies for a reference subgroup",
 subtitle = "A well-generated Poisson sample should roughly match the theoretical count probabilities",
 x = "Doctor visits",
 y = "Probability",
 fill = "Source"
 ) +
 ggplot2::scale_fill_manual(values = c("#6c9bd2", "#d08c42")) +
 ggplot2::theme_minimal(base_size = 12)
```

![plot of chunk unnamed-chunk-6](/tutorials/rendered-assets/simulation-tools-simulating-poisson-data/unnamed-chunk-6-1.png)

This comparison is not meant to be exact in a finite subgroup. It is meant to show that the simulated frequencies align reasonably well with the shape implied by the Poisson model.

## Main assumptions behind this simulation

The most important assumption is that the count outcome is conditionally Poisson, which means that the conditional mean and conditional variance are equal:

$$
\mathbb{E}(Y_i \mid X_i) = \text{Var}(Y_i \mid X_i) = \mu_i.
$$

That assumption is often too strict in real utilization data, where overdispersion is common. But it is exactly the right place to start when learning how count models work.

The chapter also assumes that the log-linear mean model is correctly specified and that the offset enters with coefficient one through $\log(t_i)$. Those assumptions make the exercise transparent. Later simulations can relax them by introducing overdispersion, zero inflation, clustering, or serial dependence.

## Further reading

Cameron and Trivedi remain a foundational applied reference for count-data econometrics and are especially helpful for connecting Poisson models to real utilization outcomes. Nelder and Wedderburn are the classic reference for the generalized linear model framework that makes Poisson regression natural in the first place. Together, they provide a strong bridge between the mechanics of simulation and the broader modeling tradition used in applied health economics.

## References

- Cameron, A. Colin; Trivedi, Pravin K. (1986). "Econometric Models Based on Count Data: Comparisons and Applications of Some Estimators and Tests." *Journal of Applied Econometrics*, 1(1), 29--53. DOI: <https://doi.org/10.1002/jae.3950010104>.
- Nelder, J. A.; Wedderburn, R. W. M. (1972). "Generalized Linear Models." *Journal of the Royal Statistical Society. Series A (General)*, 135(3), 370--384. DOI: <https://doi.org/10.2307/2344614>.
