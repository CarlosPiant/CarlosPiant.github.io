---
title: "Simulating Cluster Randomized Trials"
date: 2026-03-22
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset for a cluster randomized trial in which clinics, rather than patients, are randomized to treatment. The aim is to make visible the design logic that separates cluster trials..."
excerpt: "Creating patient-level outcomes when treatment is randomized at the clinic level"
---
This chapter creates a synthetic dataset for a cluster randomized trial in which clinics, rather than patients, are randomized to treatment. The aim is to make visible the design logic that separates cluster trials from ordinary individual randomized experiments. In many health-policy and health-services settings, the intervention is delivered to a provider organization, a hospital ward, or a primary care practice. Randomizing patients individually would either be infeasible or would create contamination, because patients and clinicians inside the same organization influence one another.

The design is motivated by diabetes-management trials in which hospitals or primary care practices were randomized to care-delivery strategies rather than randomizing patients one by one. The chapter also follows the standard methodological logic of cluster trials developed by Donner and Klar, especially the role of the intracluster correlation coefficient and the resulting design effect.

The practical point is simple. Cluster randomization creates two levels of variation at once. Treatment is assigned at the cluster level, but outcomes are observed at the patient level. A useful simulation therefore has to generate both patient heterogeneity and cluster-level dependence.

## What data will be created and what method it is meant to test

We will simulate a cluster randomized trial of a diabetes-care intervention delivered at the clinic level. The trial is meant to test a random-intercept mixed model for a continuous patient outcome under cluster-level treatment assignment.

The synthetic data will contain:

- `clinic`: clinic identifier
- `treatment`: clinic-level treatment assignment
- `age`: patient age in years
- `baseline_hba1c`: pretreatment glycated hemoglobin
- `clinic_intercept`: latent clinic-specific deviation from the grand mean
- `followup_hba1c`: the patient outcome measured after follow-up

The final step will be to fit the mixed model that matches the true generating process and compare the estimated fixed effects, variance components, and intracluster correlation with the true values used in the simulation.

## The data-generating process

Suppose patient $i$ in clinic $j$ has outcome

$$
Y_{ij} =
\beta_0 +
\beta_1 \text{treatment}_j +
\beta_2 \text{age}_{ij} +
\beta_3 \text{baseline\_hba1c}_{ij} +
b_j + \varepsilon_{ij},
$$

where the cluster-specific random intercept is

$$
b_j \sim N(0, \tau^2),
$$

and the patient-level error is

$$
\varepsilon_{ij} \sim N(0, \sigma^2).
$$

For this chapter, the true parameters are

$$
\beta_0 = 1.8,\;
\beta_1 = -0.35,\;
\beta_2 = 0.010,\;
\beta_3 = 0.65,\;
\tau = 0.28,\;
\sigma = 0.72.
$$

The treatment effect is therefore a clinic-level reduction of 0.35 percentage points in follow-up HbA1c.

The intracluster correlation coefficient is

$$
\rho = \frac{\tau^2}{\tau^2 + \sigma^2}.
$$

This quantity matters because it tells us how similar two patients from the same clinic are, even after conditioning on observed covariates.

If the average cluster size is $\bar m$, the classical design effect is

$$
\text{DE} = 1 + (\bar m - 1)\rho.
$$

That is the inflation factor that explains why cluster randomized trials often require more patients than individually randomized trials with the same target precision.

## Step 1: Generate the clinic structure and randomization

```r
set.seed(2034)

n_clinics <- 24
clinic_size <- sample(25:45, size = n_clinics, replace = TRUE)
clinic <- rep(seq_len(n_clinics), times = clinic_size)
n <- length(clinic)

treatment_by_clinic <- sample(rep(c(0, 1), each = n_clinics / 2))
treatment <- treatment_by_clinic[clinic]

true_tau <- 0.28
true_sigma <- 0.72
true_icc <- true_tau^2 / (true_tau^2 + true_sigma^2)
design_effect <- 1 + (mean(clinic_size) - 1) * true_icc

design_summary <- data.frame(
 clinics = n_clinics,
 patients = n,
 mean_cluster_size = mean(clinic_size),
 true_icc = true_icc,
 design_effect = design_effect
)

design_summary[, c("mean_cluster_size", "true_icc", "design_effect")] <-
 round(design_summary[, c("mean_cluster_size", "true_icc", "design_effect")], 3)

knitr::kable(
 design_summary,
 caption = "Design summary for the synthetic cluster randomized trial"
)

randomization_table <- data.frame(
 arm = c("Control clinics", "Intervention clinics"),
 number_of_clusters = c(
 sum(treatment_by_clinic == 0),
 sum(treatment_by_clinic == 1)
 ),
 mean_cluster_size = c(
 mean(clinic_size[treatment_by_clinic == 0]),
 mean(clinic_size[treatment_by_clinic == 1])
 )
)

randomization_table$mean_cluster_size <- round(randomization_table$mean_cluster_size, 3)

knitr::kable(
 randomization_table,
 caption = "Cluster allocation across treatment arms",
 row.names = FALSE
)
```

The randomization happens only once per clinic. Every patient inside the same clinic inherits that treatment assignment. That is the feature that distinguishes this design from ordinary patient-level randomization.

## Step 2: Generate patient-level covariates and outcomes

```r
clinic_intercepts <- rnorm(n_clinics, mean = 0, sd = true_tau)

age <- pmin(pmax(round(rnorm(n, mean = 62, sd = 10)), 30), 85)
baseline_hba1c <- pmax(rnorm(n, mean = 8.0, sd = 1.05), 5.5)
epsilon <- rnorm(n, mean = 0, sd = true_sigma)

followup_hba1c <- 1.8 +
 (-0.35) * treatment +
 0.010 * age +
 0.65 * baseline_hba1c +
 clinic_intercepts[clinic] +
 epsilon

synthetic_crt <- data.frame(
 clinic = factor(clinic),
 treatment = treatment,
 age = age,
 baseline_hba1c = baseline_hba1c,
 followup_hba1c = followup_hba1c,
 clinic_intercept = clinic_intercepts[clinic]
)

outcome_summary <- data.frame(
 quantity = c(
 "Mean age",
 "Mean baseline HbA1c",
 "Mean follow-up HbA1c",
 "Treatment share"
 ),
 value = c(
 mean(synthetic_crt$age),
 mean(synthetic_crt$baseline_hba1c),
 mean(synthetic_crt$followup_hba1c),
 mean(synthetic_crt$treatment)
 )
)

outcome_summary$value <- round(outcome_summary$value, 3)

knitr::kable(
 outcome_summary,
 caption = "Patient-level summary of the simulated cluster trial",
 row.names = FALSE
)
```

This code generates two distinct sources of variation. The patient-level covariates create ordinary within-clinic heterogeneity, while the clinic intercept creates dependence between patients from the same site.

## Step 3: Visualize the cluster-level outcome distribution by treatment arm

```r
cluster_means <- aggregate(
 cbind(followup_hba1c, baseline_hba1c) ~ clinic + treatment,
 data = synthetic_crt,
 FUN = mean
)

cluster_means$cluster_size <- as.numeric(table(synthetic_crt$clinic))
cluster_means$arm <- ifelse(cluster_means$treatment == 1, "Intervention", "Control")

ggplot2::ggplot(
 cluster_means,
 ggplot2::aes(x = arm, y = followup_hba1c, size = cluster_size, color = arm)
) +
 ggplot2::geom_jitter(width = 0.12, alpha = 0.75) +
 ggplot2::stat_summary(
 data = cluster_means,
 ggplot2::aes(x = arm, y = followup_hba1c),
 fun = mean,
 geom = "crossbar",
 width = 0.35,
 color = "#264653",
 linewidth = 0.7,
 inherit.aes = FALSE
 ) +
 ggplot2::scale_color_manual(values = c("Control" = "#8d6e63", "Intervention" = "#2a9d8f")) +
 ggplot2::labs(
 title = "Clinic mean outcomes in the simulated cluster randomized trial",
 subtitle = "Points represent clinics; bar markers show the mean cluster outcome in each arm",
 x = "Trial arm",
 y = "Mean follow-up HbA1c",
 size = "Clinic size",
 color = NULL
 ) +
 ggplot2::theme_minimal(base_size = 12)
```

This figure makes the unit of randomization visible. The real trial comparison is not just patient versus patient. It is intervention clinic versus control clinic, with many patients nested inside each cluster.

## Step 4: Compare a naive patient-level regression with the mixed model

Because the treatment is assigned at the clinic level, it is informative to see what happens if the analyst ignores the clustering.

```r
naive_fit <- lm(
 followup_hba1c ~ treatment + age + baseline_hba1c,
 data = synthetic_crt
)

mixed_fit <- nlme::lme(
 fixed = followup_hba1c ~ treatment + age + baseline_hba1c,
 random = ~ 1 | clinic,
 data = synthetic_crt,
 method = "REML"
)

treatment_comparison <- data.frame(
 model = c("True treatment effect", "Naive OLS", "Random-intercept model"),
 estimate = c(
 -0.35,
 coef(summary(naive_fit))["treatment", "Estimate"],
 summary(mixed_fit)$tTable["treatment", "Value"]
 ),
 standard_error = c(
 NA_real_,
 coef(summary(naive_fit))["treatment", "Std. Error"],
 summary(mixed_fit)$tTable["treatment", "Std.Error"]
 )
)

treatment_comparison[, c("estimate", "standard_error")] <-
 round(treatment_comparison[, c("estimate", "standard_error")], 3)

knitr::kable(
 treatment_comparison,
 caption = "Treatment-effect comparison with and without accounting for clustering",
 row.names = FALSE
)
```

The naive regression can still estimate the treatment contrast itself reasonably well in a randomized design, but it treats patients as more independent than they really are. The mixed model is the one that matches the generating process.

## Step 5: Fit the model that matches the true generating process and compare estimates with truth

```r
true_fixed_effects <- c(
 "(Intercept)" = 1.8,
 treatment = -0.35,
 age = 0.010,
 baseline_hba1c = 0.65
)

fixed_effects_table <- data.frame(
 term = names(nlme::fixed.effects(mixed_fit)),
 true_value = true_fixed_effects[names(nlme::fixed.effects(mixed_fit))],
 estimated_value = as.numeric(nlme::fixed.effects(mixed_fit))
)

fixed_effects_table$bias <- fixed_effects_table$estimated_value - fixed_effects_table$true_value

fixed_effects_table[, c("true_value", "estimated_value", "bias")] <-
 round(fixed_effects_table[, c("true_value", "estimated_value", "bias")], 3)

knitr::kable(
 fixed_effects_table,
 caption = "True and estimated fixed effects in the cluster randomized trial simulation",
 row.names = FALSE
)

variance_components <- nlme::VarCorr(mixed_fit)

estimated_tau <- as.numeric(variance_components[1, "StdDev"])^2
estimated_sigma <- as.numeric(variance_components[2, "StdDev"])^2
estimated_icc <- estimated_tau / (estimated_tau + estimated_sigma)

variance_table <- data.frame(
 component = c("clinic_variance", "residual_variance", "ICC"),
 true_value = c(
 true_tau^2,
 true_sigma^2,
 true_icc
 ),
 estimated_value = c(
 estimated_tau,
 estimated_sigma,
 estimated_icc
 )
)

variance_table[, c("true_value", "estimated_value")] <-
 round(variance_table[, c("true_value", "estimated_value")], 3)

knitr::kable(
 variance_table,
 caption = "True and estimated variance structure in the simulated cluster trial",
 row.names = FALSE
)
```

These two tables are the main recovery check. The first confirms whether the mixed model recovers the fixed effects used in the data-generating process. The second checks whether the same model recovers the cluster-level variance, the patient-level variance, and the resulting intracluster correlation.

## Main assumptions behind this simulation

The simulation assumes that treatment is randomized perfectly at the clinic level, that the cluster effect enters through a random intercept, and that both the cluster effects and residual errors are Gaussian. It also assumes no treatment-effect heterogeneity across clinics and no cluster-level covariate imbalance beyond what randomization creates by chance.

Real cluster trials can be more complex. They may use stratified or blocked randomization, unequal cluster sizes known in advance, binary or count outcomes, repeated measurements, stepped-wedge designs, or informative loss of clusters. Still, the present design is the right starting point because it captures the central feature of cluster trials: treatment is assigned to groups, but inference is needed at the patient level with within-group dependence.

## Further reading

Donner and Klar remain a central reference for the design and analysis of cluster randomized trials in health research. For a concrete diabetes-related example of cluster-level randomization in provider settings, see Slingerland and colleagues' cluster-randomized trial of patient-centered diabetes care across hospitals.
