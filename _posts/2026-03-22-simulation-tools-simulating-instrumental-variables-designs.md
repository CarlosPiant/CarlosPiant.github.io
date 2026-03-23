---
title: "Simulating Instrumental Variables Designs"
date: 2026-03-22
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset for instrumental-variables designs in which treatment is endogenous and identification depends on the quality of the instrument. The goal is not just to generate one..."
excerpt: "Creating strong, weak, and invalid instruments from a known endogenous-treatment process"
---
This chapter creates a synthetic dataset for instrumental-variables designs in which treatment is endogenous and identification depends on the quality of the instrument. The goal is not just to generate one successful IV example. It is to simulate several different IV designs side by side and make clear how the first stage and the exclusion restriction determine whether two-stage least squares succeeds or fails.

The setup follows the encouragement-style logic that underlies much of the modern IV literature, including the local average treatment effect framework of Imbens and Angrist and the weak-instrument concerns emphasized by Staiger and Stock. The substantive example is a stylized care-management program in which an outreach assignment shifts treatment take-up, while latent severity affects both enrollment and annual cost.

This chapter complements the existing introductory IV simulation chapter by focusing on design variation. The earlier chapter shows a single valid instrument working as intended. This one asks a harder and more useful question: what changes when the instrument is strong, weak, or invalid?

## What data will be created and what method it is meant to test

We will create a synthetic dataset with a binary endogenous treatment and three alternative instrument designs.

The variables will be:

- `age`: patient age in years
- `chronic`: number of chronic conditions
- `severity_latent`: unobserved severity factor
- `instrument`: exogenous encouragement variable
- `treatment`: endogenous care-management enrollment
- `annual_cost`: continuous outcome
- `design`: the IV design being simulated

The chapter is meant to test two-stage least squares under three cases:

1. a strong valid instrument
2. a weak valid instrument
3. a strong but invalid instrument that violates exclusion

The final step will be to fit the same 2SLS model in each case and compare the estimates with the true treatment effect.

## The data-generating process

Treatment is determined by a latent-index first stage:

$$
D_i = \mathbb{1}(D_i^* > 0),
$$

where

$$
D_i^* =
-1 +
\pi_1 Z_i +
0.015 \text{age}_i +
0.22 \text{chronic}_i +
0.9 U_i +
v_i.
$$

The outcome equation is

$$
Y_i =
9000 -
1600 D_i +
55 \text{age}_i +
900 \text{chronic}_i +
1700 U_i +
\gamma Z_i +
\varepsilon_i.
$$

The latent severity term $U_i$ enters both equations, which creates endogeneity. The true treatment effect is

$$
\beta_1 = -1600.
$$

We will simulate three designs by changing only two parameters:

- $\pi_1$, which controls instrument strength
- $\gamma$, which controls exclusion failure

The designs are:

1. **Strong valid instrument**: $\pi_1 = 1.2$, $\gamma = 0$
2. **Weak valid instrument**: $\pi_1 = 0.25$, $\gamma = 0$
3. **Strong invalid instrument**: $\pi_1 = 1.2$, $\gamma = 700$

The first two satisfy exclusion by construction. The third violates exclusion because the instrument enters the outcome equation directly.

## Step 1: Generate the common patient-level covariates

```r
set.seed(2036)

n <- 6000

age <- pmax(round(rnorm(n, mean = 66, sd = 10)), 40)
chronic <- pmin(rpois(n, lambda = 2.2), 6)
severity_latent <- rnorm(n)

base_covariates <- data.frame(
 age = age,
 chronic = chronic,
 severity_latent = severity_latent
)

covariate_summary <- data.frame(
 sample_size = nrow(base_covariates),
 mean_age = mean(base_covariates$age),
 mean_chronic = mean(base_covariates$chronic),
 sd_severity = sd(base_covariates$severity_latent)
)

covariate_summary[, c("mean_age", "mean_chronic", "sd_severity")] <-
 round(covariate_summary[, c("mean_age", "mean_chronic", "sd_severity")], 3)

knitr::kable(
 covariate_summary,
 caption = "Common covariates used across all simulated IV designs",
 row.names = FALSE
)
```

These covariates are held fixed across the three designs. That way, differences in IV performance come from the instrument design itself rather than from different underlying patient samples.

## Step 2: Generate three alternative IV designs

```r
simulate_iv_design <- function(design_name, pi1, gamma_direct) {
 instrument <- rbinom(n, size = 1, prob = 0.5)

 treatment_index <- -1 +
 pi1 * instrument +
 0.015 * age +
 0.22 * chronic +
 0.9 * severity_latent +
 rnorm(n)

 treatment <- as.integer(treatment_index > 0)

 annual_cost <- 9000 -
 1600 * treatment +
 55 * age +
 900 * chronic +
 1700 * severity_latent +
 gamma_direct * instrument +
 rnorm(n, mean = 0, sd = 1700)

 data.frame(
 design = design_name,
 annual_cost = annual_cost,
 treatment = treatment,
 instrument = instrument,
 age = age,
 chronic = chronic
 )
}

iv_design_data <- rbind(
 simulate_iv_design("Strong valid instrument", pi1 = 1.2, gamma_direct = 0),
 simulate_iv_design("Weak valid instrument", pi1 = 0.25, gamma_direct = 0),
 simulate_iv_design("Strong invalid instrument", pi1 = 1.2, gamma_direct = 700)
)

design_summary <- aggregate(
 cbind(treatment, annual_cost) ~ design,
 data = iv_design_data,
 FUN = mean
)

design_summary$treatment <- round(design_summary$treatment, 3)
design_summary$annual_cost <- round(design_summary$annual_cost, 3)

knitr::kable(
 design_summary,
 caption = "Observed treatment and outcome means across the simulated IV designs",
 row.names = FALSE
)
```

The underlying patient covariates are the same in all three designs, but the instrument behaves differently. That allows a clean comparison of design quality.

## Step 3: Fit OLS and 2SLS within each design

```r
estimate_iv_design <- function(df) {
 ols_fit <- lm(
 annual_cost ~ treatment + age + chronic,
 data = df
 )

 iv_fit <- AER::ivreg(
 annual_cost ~ treatment + age + chronic |
 instrument + age + chronic,
 data = df
 )

 first_stage <- lm(
 treatment ~ instrument + age + chronic,
 data = df
 )

 data.frame(
 design = unique(df$design),
 first_stage_f = summary(first_stage)$coefficients["instrument", "t value"]^2,
 ols_estimate = coef(ols_fit)["treatment"],
 iv_estimate = coef(iv_fit)["treatment"],
 true_effect = -1600
 )
}

results_table <- do.call(
 rbind,
 lapply(split(iv_design_data, iv_design_data$design), estimate_iv_design)
)

results_table$ols_bias <- results_table$ols_estimate - results_table$true_effect
results_table$iv_bias <- results_table$iv_estimate - results_table$true_effect

results_table[, c("first_stage_f", "ols_estimate", "iv_estimate", "true_effect", "ols_bias", "iv_bias")] <-
 round(results_table[, c("first_stage_f", "ols_estimate", "iv_estimate", "true_effect", "ols_bias", "iv_bias")], 3)

knitr::kable(
 results_table,
 caption = "Estimator recovery under strong, weak, and invalid IV designs",
 row.names = FALSE
)
```

This table is the center of the chapter. It shows three different reasons IV designs can succeed or fail:

- OLS is biased in all three designs because treatment is endogenous
- 2SLS works well when the instrument is strong and valid
- 2SLS becomes unstable when the instrument is weak
- 2SLS becomes badly biased when exclusion fails, even if the first stage is strong

## Step 4: Visualize first-stage strength across designs

```r
first_stage_plot <- aggregate(
 treatment ~ design + instrument,
 data = iv_design_data,
 FUN = mean
)

first_stage_plot$instrument <- factor(
 first_stage_plot$instrument,
 levels = c(0, 1),
 labels = c("No encouragement", "Encouragement")
)

ggplot2::ggplot(
 first_stage_plot,
 ggplot2::aes(x = instrument, y = treatment, fill = instrument)
) +
 ggplot2::geom_col(width = 0.65) +
 ggplot2::facet_wrap(~ design) +
 ggplot2::scale_fill_manual(values = c("No encouragement" = "#8d6e63", "Encouragement" = "#2a9d8f")) +
 ggplot2::labs(
 title = "Instrument relevance varies across the simulated designs",
 subtitle = "The weak valid design produces much less separation in treatment take-up",
 x = NULL,
 y = "Treatment take-up rate",
 fill = NULL
 ) +
 ggplot2::theme_minimal(base_size = 12) +
 ggplot2::theme(legend.position = "none")
```

This figure is the visual first stage. The weak valid design shows much smaller separation between instrument groups, which is exactly why 2SLS becomes less reliable there.

## Step 5: Compare the model that matches the true generating process with the truth

The matching model is 2SLS under the valid designs. To make that explicit, compare the valid-design estimates with the true treatment effect.

```r
valid_design_check <- subset(
 results_table,
 design %in% c("Strong valid instrument", "Weak valid instrument")
)

valid_design_check[, c("iv_estimate", "true_effect", "iv_bias")] <-
 round(valid_design_check[, c("iv_estimate", "true_effect", "iv_bias")], 3)

knitr::kable(
 valid_design_check[, c("design", "first_stage_f", "iv_estimate", "true_effect", "iv_bias")],
 caption = "Recovery check for the valid IV designs",
 row.names = FALSE
)
```

The strong valid design should come much closer to the true treatment effect than the weak valid design. That is the practical lesson of weak-instrument theory in a single table.

## Main assumptions behind this simulation

The simulation assumes a binary endogenous treatment generated by a latent-index first stage and a linear outcome equation with a constant treatment effect. It also assumes that the analyst can vary the instrument design directly by changing only relevance and exclusion parameters.

That simplification is deliberate. Real IV settings may involve heterogeneous treatment effects, multiple instruments, clustered assignment, nonlinear outcomes, or selection into samples as well as treatment. But the present setup isolates the three design questions that matter most at the start:

1. Does the instrument move treatment?
2. Does it do so strongly enough?
3. Does it affect the outcome only through treatment?

## Further reading

Imbens and Angrist remain the central reference for the local causal interpretation of IV estimates. Staiger and Stock are essential for understanding how weak instruments distort finite-sample IV performance, and Stock, Wright, and Yogo provide a broader weak-identification perspective that is useful when building simulation benchmarks. The empirical illustration by Angrist and Evans remains a classic example of instrument-based identification through quasi-random encouragement-like variation.

## References

- Imbens, Guido W.; Angrist, Joshua D. (1994). "Identification and Estimation of Local Average Treatment Effects." *Econometrica*, 62(2), 467--475. DOI: <https://doi.org/10.2307/2951620>.
- Staiger, Douglas; Stock, James H. (1997). "Instrumental Variables Regression with Weak Instruments." *Econometrica*, 65(3), 557--586. DOI: <https://doi.org/10.2307/2171753>.
- Stock, James H.; Wright, Jonathan H.; Yogo, Motohiro (2002). "A Survey of Weak Instruments and Weak Identification in Generalized Method of Moments." *Journal of Business \& Economic Statistics*, 20(4), 518--529. DOI: <https://doi.org/10.1198/073500102288618658>.
- Angrist, Joshua D.; Evans, William N. (1998). "Children and Their Parents' Labor Supply: Evidence from Exogenous Variation in Family Size." *The American Economic Review*, 88(3), 450--477. <https://www.jstor.org/stable/116844>.
