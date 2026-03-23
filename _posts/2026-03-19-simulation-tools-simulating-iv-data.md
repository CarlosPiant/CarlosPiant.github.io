---
title: "Simulating Data from an Instrumental Variables Model"
date: 2026-03-19
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which treatment is endogenous and must be identified through an instrumental variable. The design is inspired by the encouragement-style applications that run through the..."
excerpt: "Creating a synthetic dataset with endogenous treatment and exogenous encouragement"
---
This chapter creates a synthetic dataset in which treatment is endogenous and must be identified through an instrumental variable. The design is inspired by the encouragement-style applications that run through the instrumental-variables literature, including fertility and labor-supply examples such as Angrist and Evans. The synthetic version here is not a replication of any one empirical study. Instead, it creates a simplified care-management setting in which unobserved severity affects both treatment take-up and outcomes, while an exogenous encouragement variable shifts treatment without directly affecting the outcome. That makes it useful for checking whether two-stage least squares can recover the true treatment effect when ordinary least squares cannot.

The practical reason to simulate IV data is that endogeneity is one of the main reasons applied regression fails. Treatment is often selected for reasons the analyst does not fully observe. Simulation makes that selection mechanism explicit and therefore provides a controlled setting for understanding what the instrument is supposed to fix.

## What variables will be created

The synthetic sample will represent high-risk patients eligible for an intensive care-management program. `age` will represent age in years. `chronic` will count chronic conditions. `encouragement` will indicate whether the patient was assigned to a clinician with a more proactive outreach protocol. `severity_latent` will be an unobserved severity factor that affects both treatment take-up and cost. `program_enrollment` will indicate whether the patient actually enrolls in care management. The outcome `annual_cost` will record annual healthcare cost.

These variables are chosen to mimic the basic structure of an instrumental-variables problem: a treatment that is confounded, an instrument that affects treatment but not the outcome directly, and an unobserved factor that creates the endogeneity.

## The data-generating process

The simulation uses a triangular system. Treatment is determined first:

$$
D_i = \mathbb{1}(D_i^* > 0),
$$

where

$$
D_i^* =
\pi_0 +
\pi_1 Z_i +
\pi_2 \text{age}_i +
\pi_3 \text{chronic}_i +
\pi_4 U_i +
v_i.
$$

Here $Z_i$ is the instrument and $U_i$ is latent severity.

The outcome equation is

$$
Y_i =
\beta_0 +
\beta_1 D_i +
\beta_2 \text{age}_i +
\beta_3 \text{chronic}_i +
\beta_4 U_i +
\varepsilon_i.
$$

The key feature is that the latent severity term $U_i$ enters both equations. That creates endogeneity because treatment is correlated with the outcome error through a shared unobserved determinant.

For this simulation, the true parameters are set to

$$
\pi_0 = -1.1,\;
\pi_1 = 1.3,\;
\pi_2 = 0.015,\;
\pi_3 = 0.25,\;
\pi_4 = 0.9,
$$

and

$$
\beta_0 = 8500,\;
\beta_1 = -1800,\;
\beta_2 = 60,\;
\beta_3 = 950,\;
\beta_4 = 1600.
$$

The coefficient of interest is $\beta_1 = -1800$, which means that true program enrollment lowers annual cost by \$1,800 on average for the population generated here.

## Step 1: Generate the synthetic sample

```r
set.seed(2026)

n <- 7000

age <- pmax(round(rnorm(n, mean = 67, sd = 10)), 40)
chronic <- pmin(rpois(n, lambda = 2.4), 7)
encouragement <- rbinom(n, size = 1, prob = 0.5)
severity_latent <- rnorm(n)

treatment_index <- -1.1 +
 1.3 * encouragement +
 0.015 * age +
 0.25 * chronic +
 0.9 * severity_latent +
 rnorm(n, mean = 0, sd = 1)

program_enrollment <- as.integer(treatment_index > 0)

annual_cost <- 8500 -
 1800 * program_enrollment +
 60 * age +
 950 * chronic +
 1600 * severity_latent +
 rnorm(n, mean = 0, sd = 1800)

synthetic_iv <- data.frame(
 annual_cost,
 program_enrollment,
 encouragement,
 age,
 chronic,
 severity_latent
)

simulation_summary <- data.frame(
 sample_size = nrow(synthetic_iv),
 treatment_rate = mean(synthetic_iv$program_enrollment),
 encouragement_rate = mean(synthetic_iv$encouragement),
 mean_cost = mean(synthetic_iv$annual_cost),
 mean_age = mean(synthetic_iv$age),
 mean_chronic = mean(synthetic_iv$chronic)
)

simulation_summary[, -1] <- round(simulation_summary[, -1], 3)

knitr::kable(
 simulation_summary,
 caption = "Summary of the synthetic instrumental-variables dataset"
)
```

The data now contain the exact feature that makes IV necessary. Higher latent severity raises treatment take-up and also raises cost. If that latent severity were omitted from the fitted regression, ordinary least squares would treat part of that confounding as if it were a treatment effect.

## Step 2: Show why ordinary least squares is biased

First fit the naive linear regression that ignores the endogeneity problem.

```r
ols_fit <- lm(
 annual_cost ~ program_enrollment + age + chronic,
 data = synthetic_iv
)

ols_table <- data.frame(
 term = names(coef(ols_fit)),
 estimate = coef(ols_fit)
)

ols_table$estimate <- round(ols_table$estimate, 3)

knitr::kable(
 ols_table,
 caption = "Naive OLS estimates when treatment is endogenous"
)
```

The coefficient on `program_enrollment` should be biased toward zero or even in the wrong direction relative to the true treatment effect because sicker patients are more likely to enroll.

## Step 3: Fit the model that matches the true generating process

Now fit the correct IV specification using two-stage least squares, with `encouragement` as the instrument.

```r
iv_fit <- AER::ivreg(
 annual_cost ~ program_enrollment + age + chronic |
 encouragement + age + chronic,
 data = synthetic_iv
)

truth_table <- data.frame(
 model = c("Naive OLS", "Two-stage least squares"),
 estimated_treatment_effect = c(
 coef(ols_fit)["program_enrollment"],
 coef(iv_fit)["program_enrollment"]
 ),
 true_treatment_effect = -1800
)

truth_table$bias <- truth_table$estimated_treatment_effect - truth_table$true_treatment_effect
truth_table[, c("estimated_treatment_effect", "true_treatment_effect", "bias")] <-
 round(truth_table[, c("estimated_treatment_effect", "true_treatment_effect", "bias")], 3)

knitr::kable(
 truth_table,
 caption = "Naive and IV treatment-effect estimates compared with the known truth"
)
```

This is the main point of the exercise. The IV estimate should move much closer to the true treatment effect because the instrument isolates exogenous variation in treatment take-up.

## Step 4: Check the first stage

An IV design only works if the instrument actually shifts treatment. The first-stage regression is therefore part of the generating process that must be checked explicitly.

```r
first_stage <- lm(
 program_enrollment ~ encouragement + age + chronic,
 data = synthetic_iv
)

first_stage_table <- data.frame(
 quantity = c(
 "First-stage coefficient on encouragement",
 "First-stage F statistic"
 ),
 value = c(
 coef(first_stage)["encouragement"],
 summary(first_stage)$fstatistic[1]
 )
)

first_stage_table$value <- round(first_stage_table$value, 3)

knitr::kable(
 first_stage_table,
 caption = "First-stage diagnostics in the synthetic IV design"
)
```

```r
first_stage_plot <- aggregate(
 program_enrollment ~ encouragement,
 data = synthetic_iv,
 mean
)

first_stage_plot$encouragement <- factor(
 first_stage_plot$encouragement,
 levels = c(0, 1),
 labels = c("No encouragement", "Encouragement")
)

ggplot2::ggplot(
 first_stage_plot,
 ggplot2::aes(x = encouragement, y = program_enrollment, fill = encouragement)
) +
 ggplot2::geom_col(width = 0.65) +
 ggplot2::scale_fill_manual(values = c("No encouragement" = "#8a5a44", "Encouragement" = "#2f6f4f")) +
 ggplot2::labs(
 title = "The instrument must shift treatment take-up",
 subtitle = "Enrollment rates by randomized encouragement status",
 x = NULL,
 y = "Share enrolled in care management",
 fill = NULL
 ) +
 ggplot2::theme_minimal(base_size = 12) +
 ggplot2::theme(legend.position = "none")
```

The bar plot is the visual version of the first stage. If the bars were nearly identical, the instrument would be weak and the simulation would not be very informative.

## Step 5: Compare predicted treatment by observed risk groups

One more useful check is to compare how enrollment changes across chronic-condition groups and instrument status.

```r
synthetic_iv$risk_group <- cut(
 synthetic_iv$chronic,
 breaks = c(-Inf, 1, 3, 5, Inf),
 labels = c("0-1", "2-3", "4-5", "6+")
)

risk_first_stage <- aggregate(
 program_enrollment ~ risk_group + encouragement,
 data = synthetic_iv,
 mean
)

risk_first_stage$encouragement <- ifelse(
 risk_first_stage$encouragement == 1,
 "Encouragement",
 "No encouragement"
)

risk_first_stage$program_enrollment <- round(risk_first_stage$program_enrollment, 3)

knitr::kable(
 risk_first_stage,
 caption = "Treatment take-up by chronic-condition group and instrument status"
)
```

This table shows how the same instrument can operate in a population with different underlying risk. It also reinforces the basic logic of the DGP: treatment is more likely among sicker patients, but encouragement shifts take-up within those risk strata as well.

## Main assumptions behind this simulation

The first assumption is instrument relevance:

$$
\mathrm{Cov}(Z_i, D_i) \neq 0.
$$

The second is exclusion: the instrument affects the outcome only through treatment. In this synthetic design, that is true by construction because `encouragement` does not appear in the outcome equation.

The third is independence: the instrument is independent of the latent severity factor. That is also true by construction because `encouragement` is randomized.

The fourth is that the structural treatment effect is constant in the outcome equation. Real IV applications often involve treatment-effect heterogeneity, in which case 2SLS should be interpreted more locally.

## How to adapt this template

Once the basic structure is clear, the same IV simulation can be modified in many useful ways. You can weaken the instrument and study weak-instrument bias. You can allow the treatment effect to vary with severity and then compare the IV estimate with the average treatment effect. You can add direct violations of exclusion and see how quickly the estimate breaks down. You can simulate multiple instruments, clustered assignment, or binary outcomes with latent-index treatment selection.

In practice, these are some of the best ways to build intuition for IV. The method is often taught through assumptions alone, but simulation lets you see exactly what those assumptions mean in a known data-generating process.

## Further reading

Angrist and Evans provide one of the classic empirical examples of encouragement-type IV logic in applied economics. Imbens and Angrist explain the local causal interpretation that made modern IV reasoning more precise. Staiger and Stock remain essential for understanding why first-stage strength matters so much for IV performance.
