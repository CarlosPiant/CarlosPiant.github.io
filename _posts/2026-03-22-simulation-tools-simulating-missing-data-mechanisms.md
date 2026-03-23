---
title: "Simulating Missing Data Mechanisms"
date: 2026-03-22
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which missingness is generated explicitly through response indicators. The goal is to simulate not only incomplete values, but the missingness mechanism itself. That is the..."
excerpt: "Creating MCAR, MAR, and MNAR response indicators from a known complete dataset"
---
This chapter creates a synthetic dataset in which missingness is generated explicitly through response indicators. The goal is to simulate not only incomplete values, but the missingness mechanism itself. That is the most important distinction in applied missing-data work. Analysts do not merely observe blanks. They observe the result of a stochastic selection process that determines which values become unavailable.

The design follows Rubin's classic distinction between missing completely at random, missing at random, and missing not at random, with additional practical framing from Little and Rubin's broader treatment of missing-data mechanisms. The setting is a simplified health-services example in which patient severity may be missing from a follow-up dataset used to study annual health-care costs.

This chapter complements the existing missing-data simulation chapter by focusing on the mechanism itself. Instead of asking only how regression estimates change after missingness is imposed, it asks a more basic design question: how do we generate MCAR, MAR, and MNAR patterns transparently, and how do we verify that the simulated response indicators behave the way we intended?

## What data will be created and what method it is meant to test

We will create a complete synthetic health-services dataset and then generate three missingness indicators for the variable `severity`.

The complete data will contain:

- `age`: patient age in years
- `severity`: a latent clinical-severity score
- `income`: annual income in dollars
- `annual_cost`: annual health-care cost

The missing-data mechanisms will create:

- `missing_mcar`: indicator that `severity` is missing completely at random
- `missing_mar`: indicator that `severity` is missing at random conditional on observed variables
- `missing_mnar`: indicator that `severity` is missing not at random because it depends on the underlying severity value itself

The chapter is meant to test logistic missingness models. At the end, we will fit the same missingness models used to generate the response indicators and compare the estimated coefficients with the true parameters.

## The data-generating process

First generate the complete outcome data using

$$
\text{annual\_cost}_i =
1200 +
18 \text{age}_i +
380 \text{severity}_i -
0.004 \text{income}_i +
\varepsilon_i,
$$

where

$$
\varepsilon_i \sim N(0, 650^2).
$$

Next define the missingness indicator $M_i$ for `severity`, where $M_i = 1$ means the value is missing.

Under MCAR, missingness is Bernoulli with constant probability:

$$
M_i^{MCAR} \sim \text{Bernoulli}(0.22).
$$

Under MAR, missingness depends only on observed variables:

$$
\Pr(M_i^{MAR} = 1) =
\text{logit}^{-1}
\left(
-2.5 + 0.022 \text{age}_i - 0.60 \mathbb{1}(\text{severity}_i > 0) + 0.00002 \text{income}_i
\right).
$$

To keep the MAR mechanism formally valid, we will not use the continuous latent severity value itself. Instead, the indicator $\mathbb{1}(\text{severity}_i > 0)$ is created before missingness is imposed and treated as an observed baseline-risk marker.

Under MNAR, missingness depends directly on the unobserved value:

$$
\Pr(M_i^{MNAR} = 1) =
\text{logit}^{-1}
\left(
-1.05 + 1.00 \text{severity}_i
\right).
$$

The practical distinction is then clear:

- MCAR ignores the data entirely
- MAR depends only on observed information
- MNAR depends on the value that later becomes missing

## Step 1: Generate the complete dataset

```r
set.seed(2035)

n <- 4500

age <- pmin(pmax(round(rnorm(n, mean = 59, sd = 13)), 18), 90)
severity <- rnorm(n, mean = 0, sd = 1)
income <- pmax(rnorm(n, mean = 52000, sd = 12000), 12000)
severity_flag <- as.integer(severity > 0)

annual_cost <- 1200 +
 18 * age +
 380 * severity -
 0.004 * income +
 rnorm(n, mean = 0, sd = 650)

complete_data <- data.frame(
 age = age,
 severity = severity,
 severity_flag = severity_flag,
 income = income,
 annual_cost = annual_cost
)

complete_summary <- data.frame(
 sample_size = nrow(complete_data),
 mean_age = mean(complete_data$age),
 mean_severity = mean(complete_data$severity),
 high_severity_share = mean(complete_data$severity_flag),
 mean_income = mean(complete_data$income),
 mean_cost = mean(complete_data$annual_cost)
)

complete_summary[, c("mean_age", "mean_severity", "high_severity_share", "mean_income", "mean_cost")] <-
 round(complete_summary[, c("mean_age", "mean_severity", "high_severity_share", "mean_income", "mean_cost")], 3)

knitr::kable(
 complete_summary,
 caption = "Summary of the complete synthetic dataset before missingness is imposed",
 row.names = FALSE
)
```

The variable `severity` is the one that will become incomplete. Everything else is generated first so that the missingness indicators can depend on a known complete-data structure.

## Step 2: Generate MCAR, MAR, and MNAR response indicators

```r
missing_mcar <- rbinom(n, size = 1, prob = 0.22)

prob_mar <- plogis(
 -2.5 +
 0.022 * age -
 0.60 * severity_flag +
 0.00002 * income
)

prob_mnar <- plogis(
 -1.05 +
 1.00 * severity
)

missing_mar <- rbinom(n, size = 1, prob = prob_mar)
missing_mnar <- rbinom(n, size = 1, prob = prob_mnar)

mechanism_data <- complete_data
mechanism_data$missing_mcar <- missing_mcar
mechanism_data$missing_mar <- missing_mar
mechanism_data$missing_mnar <- missing_mnar

missingness_summary <- data.frame(
 mechanism = c("MCAR", "MAR", "MNAR"),
 missing_rate = c(
 mean(mechanism_data$missing_mcar),
 mean(mechanism_data$missing_mar),
 mean(mechanism_data$missing_mnar)
 )
)

missingness_summary$missing_rate <- round(missingness_summary$missing_rate, 3)

knitr::kable(
 missingness_summary,
 caption = "Realized missingness rates under the three simulated mechanisms",
 row.names = FALSE
)
```

This is the central simulation step. The response indicators are generated before any values are replaced with `NA`. That is good practice because it keeps the mechanism logic explicit.

## Step 3: Create incomplete datasets from the response indicators

```r
data_mcar <- complete_data
data_mar <- complete_data
data_mnar <- complete_data

data_mcar$severity[mechanism_data$missing_mcar == 1] <- NA
data_mar$severity[mechanism_data$missing_mar == 1] <- NA
data_mnar$severity[mechanism_data$missing_mnar == 1] <- NA

observed_summary <- data.frame(
 dataset = c("Complete", "MCAR observed", "MAR observed", "MNAR observed"),
 mean_observed_severity = c(
 mean(complete_data$severity),
 mean(data_mcar$severity, na.rm = TRUE),
 mean(data_mar$severity, na.rm = TRUE),
 mean(data_mnar$severity, na.rm = TRUE)
 ),
 observed_sample_size = c(
 nrow(complete_data),
 sum(!is.na(data_mcar$severity)),
 sum(!is.na(data_mar$severity)),
 sum(!is.na(data_mnar$severity))
 )
)

observed_summary[, c("mean_observed_severity", "observed_sample_size")] <-
 round(observed_summary[, c("mean_observed_severity", "observed_sample_size")], 3)

knitr::kable(
 observed_summary,
 caption = "Observed severity distribution after imposing each mechanism",
 row.names = FALSE
)
```

The difference between the complete mean and the observed mean shows how the mechanism reshapes the visible data. Under MCAR the observed severity distribution should stay close to the complete one. Under MNAR it should move more substantially because the chance of missingness depends directly on severity itself.

## Step 4: Visualize how the missingness rate changes with risk

```r
mechanism_plot_data <- data.frame(
 age = age,
 severity = severity,
 mechanism = rep(c("MCAR", "MAR", "MNAR"), each = n),
 missing = c(missing_mcar, missing_mar, missing_mnar)
)

mechanism_plot_data$severity_band <- cut(
 mechanism_plot_data$severity,
 breaks = quantile(mechanism_plot_data$severity, probs = seq(0, 1, by = 0.2)),
 include.lowest = TRUE
)

plot_table <- aggregate(
 missing ~ mechanism + severity_band,
 data = mechanism_plot_data,
 FUN = mean
)

ggplot2::ggplot(
 plot_table,
 ggplot2::aes(x = severity_band, y = missing, group = mechanism, color = mechanism)
) +
 ggplot2::geom_line(linewidth = 1) +
 ggplot2::geom_point(size = 2) +
 ggplot2::labs(
 title = "Missingness changes differently across severity bands under each mechanism",
 subtitle = "MCAR stays flat, while MAR and MNAR vary systematically with risk",
 x = "Severity band",
 y = "Missingness rate",
 color = "Mechanism"
 ) +
 ggplot2::scale_color_manual(
 values = c("MCAR" = "#457b9d", "MAR" = "#2a9d8f", "MNAR" = "#d62828")
 ) +
 ggplot2::theme_minimal(base_size = 12) +
 ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
```

This figure is useful because it converts the abstract taxonomy into something visual. MCAR produces a flat relation between missingness and severity. MAR and MNAR produce slope, though for different reasons.

## Step 5: Fit the missingness models that match the true generating process

Because this is a simulation, we still have access to the complete data. That means we can fit the true response models and compare the estimated missingness coefficients with the values used to generate them.

```r
fit_mcar <- glm(missing_mcar ~ 1, family = binomial, data = mechanism_data)
fit_mar <- glm(
 missing_mar ~ age + severity_flag + income,
 family = binomial,
 data = mechanism_data
)
fit_mnar <- glm(
 missing_mnar ~ severity,
 family = binomial,
 data = mechanism_data
)

mechanism_comparison <- rbind(
 data.frame(
 mechanism = "MCAR",
 term = names(coef(fit_mcar)),
 true_value = c("(Intercept)" = qlogis(0.22))[names(coef(fit_mcar))],
 estimated_value = coef(fit_mcar)
 ),
 data.frame(
 mechanism = "MAR",
 term = names(coef(fit_mar)),
 true_value = c(
 "(Intercept)" = -2.5,
 age = 0.022,
 severity_flag = -0.60,
 income = 0.00002
 )[names(coef(fit_mar))],
 estimated_value = coef(fit_mar)
 ),
 data.frame(
 mechanism = "MNAR",
 term = names(coef(fit_mnar)),
 true_value = c(
 "(Intercept)" = -1.05,
 severity = 1.00
 )[names(coef(fit_mnar))],
 estimated_value = coef(fit_mnar)
 )
)

mechanism_comparison$bias <- mechanism_comparison$estimated_value - mechanism_comparison$true_value

mechanism_comparison[, c("true_value", "estimated_value", "bias")] <-
 round(mechanism_comparison[, c("true_value", "estimated_value", "bias")], 3)

knitr::kable(
 mechanism_comparison,
 caption = "Recovery of the true missingness-mechanism parameters",
 row.names = FALSE
)
```

This table is the main verification exercise. It checks whether the realized response indicators look like draws from the mechanism we intended to simulate.

## Step 6: Fit the complete-data outcome model and compare with the truth

To close the loop, fit the outcome model that generated the complete data.

```r
outcome_fit <- lm(
 annual_cost ~ age + severity + income,
 data = complete_data
)

outcome_truth <- c(
 "(Intercept)" = 1200,
 age = 18,
 severity = 380,
 income = -0.004
)

outcome_comparison <- data.frame(
 term = names(coef(outcome_fit)),
 true_value = outcome_truth[names(coef(outcome_fit))],
 estimated_value = coef(outcome_fit)
)

outcome_comparison$bias <- outcome_comparison$estimated_value - outcome_comparison$true_value

outcome_comparison[, c("true_value", "estimated_value", "bias")] <-
 round(outcome_comparison[, c("true_value", "estimated_value", "bias")], 3)

knitr::kable(
 outcome_comparison,
 caption = "Recovery of the complete-data outcome model",
 row.names = FALSE
)
```

This final table confirms that the complete-data model itself is behaving as intended before missingness is layered on top of it.

## Main assumptions behind this simulation

The simulation assumes a complete-data linear model with Gaussian noise and then overlays Bernoulli response indicators generated from specified missingness equations. It also assumes that the analyst knows the full data while designing and testing the simulation, which is true in a synthetic setting but not in real applications.

The MAR mechanism here uses only observed variables by construction, while the MNAR mechanism uses the latent severity value directly. That distinction is artificial in the useful sense of the word: it is simplified so the taxonomy is visible. Real missingness processes can be mixtures, can vary over time, or can depend on several partly observed quantities at once.

## Further reading

Rubin's original paper remains the foundational conceptual statement of MCAR, MAR, and MNAR. Little and Rubin provide the standard book-length treatment that connects those ideas to modeling and inference in practical data analysis.
