---
title: "Simulating Multilevel Data"
date: 2026-03-09
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which patients are nested within clinics and the outcome depends on both patient-level covariates and clinic-level heterogeneity. The goal is to make the logic of..."
excerpt: "Creating clustered outcomes with random intercepts"
---
This chapter creates a synthetic dataset in which patients are nested within clinics and the outcome depends on both patient-level covariates and clinic-level heterogeneity. The goal is to make the logic of multilevel data visible before fitting the matching mixed-effects model. The design follows the random-effects tradition formalized by Laird and Ware, where outcomes are shaped partly by individual characteristics and partly by shared group-level structure.

In health economics and health systems research, clustering is not optional detail. Patients are treated inside clinics, hospitals, insurers, regions, and provider networks. A simulation that ignores that nesting can easily understate uncertainty or misrepresent how outcomes vary across institutions.

## What variables will be created

The synthetic sample will represent patients enrolled in a chronic-care program across many clinics. `clinic` will identify the clinic. `age` will represent age in years. `severity` will be a continuous disease-severity score. `program` will indicate whether the patient receives an enhanced coaching intervention. `clinic_intercept` will be the latent clinic-specific deviation from the overall mean outcome. The continuous outcome `followup_hba1c` will represent a six-month glycated hemoglobin measure.

These variables give the data two layers: the patient layer and the clinic layer. That is the essence of multilevel simulation.

## The data-generating process

The outcome follows a random-intercept model:

$$
Y_{ij} =
\beta_0 +
\beta_1 (\text{age}_{ij} - 60) +
\beta_2 \text{severity}_{ij} +
\beta_3 \text{program}_{ij} +
b_j + \varepsilon_{ij},
$$

where

$$
b_j \sim N(0, \tau^2),
\qquad
\varepsilon_{ij} \sim N(0, \sigma^2).
$$

For this simulation, the true parameters are

$$
\beta_0 = 7.4,\;
\beta_1 = 0.015,\;
\beta_2 = 0.55,\;
\beta_3 = -0.40,\;
\tau = 0.60,\;
\sigma = 0.80.
$$

The random intercept $b_j$ makes patients from the same clinic more similar than patients from different clinics, even after adjusting for measured covariates.

## Step 1: Generate the clinic structure and patient-level data

```r
set.seed(2026)

n_clinics <- 80
clinic_size <- sample(45:75, size = n_clinics, replace = TRUE)
clinic <- rep(seq_len(n_clinics), times = clinic_size)
n <- length(clinic)

clinic_intercepts <- rnorm(n_clinics, mean = 0, sd = 0.60)
age <- pmax(round(rnorm(n, mean = 61, sd = 11)), 30)
severity <- rnorm(n, mean = 0, sd = 1)
program <- rbinom(
 n,
 size = 1,
 prob = plogis(-0.2 - 0.25 * severity + 0.15 * (age < 60))
)

epsilon <- rnorm(n, mean = 0, sd = 0.80)

followup_hba1c <- 7.4 +
 0.015 * (age - 60) +
 0.55 * severity -
 0.40 * program +
 clinic_intercepts[clinic] +
 epsilon

synthetic_multilevel <- data.frame(
 clinic = factor(clinic),
 age,
 severity,
 program,
 followup_hba1c,
 clinic_intercept = clinic_intercepts[clinic]
)

multilevel_summary <- data.frame(
 clinics = n_clinics,
 patients = nrow(synthetic_multilevel),
 mean_cluster_size = mean(table(synthetic_multilevel$clinic)),
 mean_hba1c = mean(synthetic_multilevel$followup_hba1c),
 sd_hba1c = sd(synthetic_multilevel$followup_hba1c)
)

multilevel_summary[, c("mean_cluster_size", "mean_hba1c", "sd_hba1c")] <-
 round(multilevel_summary[, c("mean_cluster_size", "mean_hba1c", "sd_hba1c")], 3)

knitr::kable(
 multilevel_summary,
 caption = "Summary of the synthetic multilevel dataset"
)
```

The key step is the clinic-specific intercept. That single latent term introduces within-clinic correlation across all patients from the same site.

## Step 2: Fit the mixed-effects model that matches the truth

```r
multilevel_fit <- nlme::lme(
 fixed = followup_hba1c ~ age + severity + program,
 random = ~ 1 | clinic,
 data = synthetic_multilevel,
 method = "REML"
)

fixed_effects_table <- data.frame(
 term = names(nlme::fixed.effects(multilevel_fit)),
 true_value = c(
 "(Intercept)" = 6.5,
 age = 0.015,
 severity = 0.55,
 program = -0.40
 )[names(nlme::fixed.effects(multilevel_fit))],
 estimated_value = as.numeric(nlme::fixed.effects(multilevel_fit))
)

fixed_effects_table$bias <- fixed_effects_table$estimated_value - fixed_effects_table$true_value
fixed_effects_table[, c("true_value", "estimated_value", "bias")] <-
 round(fixed_effects_table[, c("true_value", "estimated_value", "bias")], 3)

knitr::kable(
 fixed_effects_table,
 caption = "True and estimated fixed effects in the random-intercept model"
)
```

The intercept is $6.5$ in the fitted model because the generating equation was written with centered age, $0.015(age - 60)$. Once age enters the fitted model in raw units, the implied intercept becomes $7.4 - 0.015 \times 60 = 6.5$.

## Step 3: Compare the variance components and the intraclass correlation

```r
variance_components <- nlme::VarCorr(multilevel_fit)

estimated_tau <- as.numeric(variance_components[1, "StdDev"])^2
estimated_sigma <- as.numeric(variance_components[2, "StdDev"])^2

variance_table <- data.frame(
 component = c("clinic_variance", "residual_variance", "ICC"),
 true_value = c(
 0.60^2,
 0.80^2,
 0.60^2 / (0.60^2 + 0.80^2)
 ),
 estimated_value = c(
 estimated_tau,
 estimated_sigma,
 estimated_tau / (estimated_tau + estimated_sigma)
 )
)

variance_table[, c("true_value", "estimated_value")] <-
 round(variance_table[, c("true_value", "estimated_value")], 3)

knitr::kable(
 variance_table,
 caption = "True and estimated variance components in the multilevel simulation"
)
```

The intraclass correlation coefficient, or ICC, is especially useful because it tells us what share of total variation is attributable to between-clinic differences.

## Step 4: Compare true and estimated clinic effects

```r
clinic_effects <- data.frame(
 clinic = rownames(nlme::ranef(multilevel_fit)),
 estimated_intercept = as.numeric(nlme::ranef(multilevel_fit)[, 1]),
 true_intercept = clinic_intercepts
)

ggplot2::ggplot(
 clinic_effects,
 ggplot2::aes(x = true_intercept, y = estimated_intercept)
) +
 ggplot2::geom_point(color = "#4d7c8a", alpha = 0.7) +
 ggplot2::geom_abline(intercept = 0, slope = 1, linetype = 2, color = "#8b5e34") +
 ggplot2::labs(
 title = "True and estimated clinic intercepts in the multilevel simulation",
 subtitle = "The dashed line marks perfect recovery of the clinic-level effects",
 x = "True clinic random intercept",
 y = "Estimated clinic random intercept"
 ) +
 ggplot2::theme_minimal(base_size = 12)
```

The points should cluster around the 45-degree line, although the estimated clinic effects will be shrunk toward zero. That shrinkage is part of the model, not a mistake.

## Main assumptions behind this simulation

The simulation assumes normally distributed random intercepts and normally distributed residual noise. It also assumes that the clinic-specific effects are independent of the patient-level covariates. Those assumptions are strong, but they are useful when learning because they make the interpretation of the mixed model clean.

This chapter includes only a random intercept. Real multilevel health data may also need random slopes, cross-level interactions, repeated measures over time, or non-Gaussian outcomes. Still, the random-intercept model is the right first step because it shows exactly how clustering changes the structure of the data.

## Further reading

Laird and Ware remain a classic entry point for the logic of random-effects models and repeated clustered data. Their framework still underpins a large share of modern multilevel modeling in applied biostatistics, outcomes research, and health-services analysis.
