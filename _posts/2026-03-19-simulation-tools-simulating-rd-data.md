---
title: "Simulating Regression Discontinuity Data"
date: 2026-03-19
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which treatment is assigned by a cutoff rule, so the natural estimand is a local treatment effect at the threshold. The design is inspired by regression discontinuity..."
excerpt: "Creating a synthetic threshold-based dataset with a known local treatment effect"
---
This chapter creates a synthetic dataset in which treatment is assigned by a cutoff rule, so the natural estimand is a local treatment effect at the threshold. The design is inspired by regression discontinuity applications such as Lee's close-election study, where a running variable determines treatment assignment through an observed threshold. The synthetic version here is not a replication of electoral data. Instead, it creates a health-system risk-score rule under which patients just above a cutoff are automatically enrolled into an intensive follow-up program. That makes it useful for testing whether a fitted regression discontinuity analysis can recover the true treatment effect at the threshold.

The practical reason to simulate regression discontinuity data is that threshold policies are everywhere in health systems. Eligibility for intensive care management, outreach, subsidies, or enhanced monitoring is often determined by scores, age thresholds, or risk cutoffs. Simulation makes the logic of that assignment rule fully explicit.

## What variables will be created

The synthetic sample will represent patients evaluated for a post-discharge follow-up program. `risk_score` will be the running variable used for eligibility. `eligible` will indicate whether the score crosses the policy threshold. `baseline_risk` will represent latent baseline complexity that evolves smoothly through the cutoff. The outcome `hospital_days` will measure future inpatient days over the next year.

These variables are chosen to reproduce the core elements of a sharp regression discontinuity design: a continuous running variable, deterministic treatment assignment at a cutoff, and an outcome whose untreated mean is smooth in the running variable.

## The data-generating process

The treatment rule is sharp:

$$
D_i = \mathbb{1}(X_i \ge c),
$$

where $X_i$ is the running variable and the cutoff is

$$
c = 0.
$$

The untreated potential outcome is generated as a smooth function of the running variable:

$$
Y_i(0) = \alpha_0 + \alpha_1 X_i + \alpha_2 X_i^2 + \varepsilon_i,
$$

with

$$
\varepsilon_i \sim \mathcal{N}(0, \sigma^2).
$$

Treatment creates a discontinuous jump at the threshold:

$$
Y_i(1) = Y_i(0) + \tau,
$$

and the observed outcome is

$$
Y_i = Y_i(0) + \tau D_i.
$$

For this simulation, the true parameters are

$$
\alpha_0 = 6,\;
\alpha_1 = 0.18,\;
\alpha_2 = 0.012,\;
\tau = -1.5,
$$

with

$$
\sigma = 1.2.
$$

The negative treatment effect means that eligibility for the intensive follow-up program lowers future hospital days by 1.5 days on average at the cutoff.

## Step 1: Generate the synthetic sample

```r
set.seed(2026)

n <- 3500
risk_score <- runif(n, min = -20, max = 20)
eligible <- as.integer(risk_score >= 0)

true_effect <- -1.5
untreated_mean <- 6 + 0.18 * risk_score + 0.012 * risk_score^2
hospital_days <- untreated_mean + true_effect * eligible + rnorm(n, mean = 0, sd = 1.2)

synthetic_rd <- data.frame(
 risk_score,
 eligible,
 untreated_mean,
 hospital_days
)

simulation_summary <- data.frame(
 sample_size = nrow(synthetic_rd),
 treated_share = mean(synthetic_rd$eligible),
 mean_outcome = mean(synthetic_rd$hospital_days),
 sd_outcome = stats::sd(synthetic_rd$hospital_days),
 score_min = min(synthetic_rd$risk_score),
 score_max = max(synthetic_rd$risk_score)
)

simulation_summary[, -1] <- round(simulation_summary[, -1], 3)

knitr::kable(
 simulation_summary,
 caption = "Summary of the synthetic regression discontinuity dataset"
)
```

This code creates a clean sharp RD design. The only discontinuity in the generating process is the treatment effect at the cutoff. Everything else evolves smoothly with the running variable.

## Step 2: Fit the model that matches the true generating process

The most direct recovery check is to estimate the local treatment effect with a local linear RD procedure. To give that estimate context, it is also useful to compare it with a naive treated-versus-untreated comparison and a global regression with score controls.

```r
naive_model <- lm(hospital_days ~ eligible, data = synthetic_rd)
global_model <- lm(
 hospital_days ~ eligible * risk_score + I(risk_score^2),
 data = synthetic_rd
)

rd_fit <- rdrobust::rdrobust(
 y = synthetic_rd$hospital_days,
 x = synthetic_rd$risk_score,
 c = 0
)

extract_hc1_effect <- function(model, term, model_name) {
 robust_vcov <- sandwich::vcovHC(model, type = "HC1")
 estimate <- coef(model)[term]
 se <- sqrt(robust_vcov[term, term])

 data.frame(
 model = model_name,
 estimate = estimate,
 lower = estimate - 1.96 * se,
 upper = estimate + 1.96 * se
 )
}

extract_rd_effect <- function(fit, model_name) {
 data.frame(
 model = model_name,
 estimate = fit$coef["Robust", "Coeff"],
 lower = fit$ci["Robust", "CI Lower"],
 upper = fit$ci["Robust", "CI Upper"]
 )
}

effect_table <- rbind(
 data.frame(
 model = "True effect at the cutoff",
 estimate = true_effect,
 lower = NA_real_,
 upper = NA_real_
 ),
 extract_hc1_effect(naive_model, "eligible", "Naive treated vs untreated comparison"),
 extract_hc1_effect(global_model, "eligible", "Global regression with score controls"),
 extract_rd_effect(rd_fit, "Local linear RD (robust)")
)

effect_table[, c("estimate", "lower", "upper")] <-
 round(effect_table[, c("estimate", "lower", "upper")], 3)

knitr::kable(
 effect_table,
 caption = "Estimated treatment effects in the synthetic RD example"
)
```

The local linear RD estimate should be close to the true effect because the data were generated exactly to satisfy the RD assumptions. The naive comparison is usually far less informative because treated and untreated units differ across the full support of the running variable.

## Step 3: Check the bandwidth and local sample

One of the most important features of regression discontinuity is locality. The estimator should focus on observations near the cutoff rather than trying to compare the entire treated and untreated samples.

```r
bandwidth_table <- data.frame(
 side = c("Left of cutoff", "Right of cutoff"),
 bandwidth = c(rd_fit$bws["h", "left"], rd_fit$bws["h", "right"]),
 effective_n = c(rd_fit$N_h[1], rd_fit$N_h[2])
)

bandwidth_table[, c("bandwidth", "effective_n")] <-
 round(bandwidth_table[, c("bandwidth", "effective_n")], 3)

knitr::kable(
 bandwidth_table,
 caption = "Bandwidth and effective sample size used by the local RD estimator"
)
```

This table shows that the RD fit is not trying to learn from the whole sample. It is learning from a neighborhood around the threshold, which is exactly the point of the design.

## Step 4: Build the visual discontinuity plot

A simulation chapter on RD should always make the jump visible. The code below creates binned averages and overlays local linear fits within the selected bandwidth.

```r
make_rd_bins <- function(x, y, cutoff = 0, bins_per_side = 15) {
 left_breaks <- seq(min(x), cutoff, length.out = bins_per_side + 1)
 right_breaks <- seq(cutoff, max(x), length.out = bins_per_side + 1)

 left_data <- data.frame(
 x = x[x < cutoff],
 y = y[x < cutoff],
 bin = cut(
 x[x < cutoff],
 breaks = left_breaks,
 include.lowest = TRUE,
 labels = FALSE
 )
 )

 right_data <- data.frame(
 x = x[x >= cutoff],
 y = y[x >= cutoff],
 bin = cut(
 x[x >= cutoff],
 breaks = right_breaks,
 include.lowest = TRUE,
 labels = FALSE
 )
 )

 left_bins <- aggregate(cbind(x, y) ~ bin, data = left_data, FUN = mean)
 right_bins <- aggregate(cbind(x, y) ~ bin, data = right_data, FUN = mean)

 rbind(left_bins[, c("x", "y")], right_bins[, c("x", "y")])
}

make_local_rd_lines <- function(
 data,
 x_var,
 y_var,
 left_bandwidth,
 right_bandwidth = left_bandwidth,
 cutoff = 0
) {
 running <- data[[x_var]]

 left_sample <- data[running < cutoff & abs(running - cutoff) <= left_bandwidth, ]
 right_sample <- data[running >= cutoff & abs(running - cutoff) <= right_bandwidth, ]

 left_model <- lm(stats::reformulate(x_var, response = y_var), data = left_sample)
 right_model <- lm(stats::reformulate(x_var, response = y_var), data = right_sample)

 left_grid <- data.frame(seq(cutoff - left_bandwidth, cutoff, length.out = 100))
 names(left_grid) <- x_var
 left_grid$fit <- predict(left_model, newdata = left_grid)
 left_grid$side <- "Left of cutoff"

 right_grid <- data.frame(seq(cutoff, cutoff + right_bandwidth, length.out = 100))
 names(right_grid) <- x_var
 right_grid$fit <- predict(right_model, newdata = right_grid)
 right_grid$side <- "Right of cutoff"

 plot_data <- rbind(left_grid, right_grid)
 names(plot_data)[names(plot_data) == x_var] <- "x"

 plot_data
}

binned_rd <- make_rd_bins(
 x = synthetic_rd$risk_score,
 y = synthetic_rd$hospital_days,
 cutoff = 0,
 bins_per_side = 18
)

local_lines <- make_local_rd_lines(
 data = synthetic_rd,
 x_var = "risk_score",
 y_var = "hospital_days",
 left_bandwidth = rd_fit$bws["h", "left"],
 right_bandwidth = rd_fit$bws["h", "right"],
 cutoff = 0
)

ggplot2::ggplot(synthetic_rd, ggplot2::aes(x = risk_score, y = hospital_days)) +
 ggplot2::geom_point(alpha = 0.08, color = "#8c8c8c", size = 1) +
 ggplot2::geom_point(
 data = binned_rd,
 ggplot2::aes(x = x, y = y),
 color = "#0b5d4b",
 size = 2.2
 ) +
 ggplot2::geom_line(
 data = local_lines,
 ggplot2::aes(x = x, y = fit, color = side),
 linewidth = 1.1
 ) +
 ggplot2::geom_vline(xintercept = 0, linetype = 2, color = "#b54708") +
 ggplot2::scale_color_manual(values = c("Left of cutoff" = "#3d5a80", "Right of cutoff" = "#bc6c25")) +
 ggplot2::labs(
 title = "Synthetic regression discontinuity design",
 subtitle = "Binned averages and local linear fits reveal the treatment jump at the cutoff",
 x = "Risk score running variable",
 y = "Hospital days in the next year",
 color = NULL
 ) +
 ggplot2::theme_minimal(base_size = 12)
```

This is the key figure in the chapter. It shows both the smooth evolution of the outcome away from the threshold and the discrete jump exactly at the cutoff.

## Step 5: Compare the local fitted means just below and just above the cutoff

The final recovery check is to compare the fitted left and right limits implied by the local RD regression.

```r
left_limit <- local_lines$fit[local_lines$side == "Left of cutoff"][length(local_lines$fit[local_lines$side == "Left of cutoff"])]
right_limit <- local_lines$fit[local_lines$side == "Right of cutoff"][1]

limit_table <- data.frame(
 quantity = c(
 "Estimated left limit at the cutoff",
 "Estimated right limit at the cutoff",
 "Estimated discontinuity",
 "True discontinuity"
 ),
 value = c(
 left_limit,
 right_limit,
 right_limit - left_limit,
 true_effect
 )
)

limit_table$value <- round(limit_table$value, 3)

knitr::kable(
 limit_table,
 caption = "Local fitted means and discontinuity at the threshold"
)
```

This table translates the geometry of the RD graph back into the estimand: the treatment effect is the jump between the left and right limits at the cutoff.

## Main assumptions behind this simulation

The first assumption is continuity of untreated potential outcomes at the threshold. In this synthetic design, that is true by construction because the untreated mean is a smooth quadratic function of the running variable.

The second is sharp treatment assignment:

$$
D_i = \mathbb{1}(X_i \ge 0).
$$

The third is that individuals do not manipulate the running variable around the threshold. That is also built into the simulation because the score is drawn continuously and independently of the treatment rule.

These assumptions are useful for learning because they create the cleanest possible RD benchmark. Real data may violate them through sorting, heaping, measurement error in the running variable, or misspecified functional form.

## How to adapt this template

Once the basic structure is clear, the same template can be modified in many useful ways. You can weaken the design by introducing manipulation near the cutoff. You can simulate a fuzzy RD in which crossing the threshold only raises treatment probability. You can change the untreated regression function to be more curved and then study bandwidth sensitivity. You can add covariates, clustered assignment, or heterogeneous treatment effects that vary with the score.

This is often the best way to build intuition for RD. The method is usually taught through continuity arguments and local-polynomial estimators, but simulation lets you see exactly how those ingredients behave when the truth is known.

## Further reading

Lee's close-election design remains one of the clearest motivating examples of RD logic in practice. Imbens and Lemieux provide a widely used guide to implementation and interpretation. Calonico, Cattaneo, and Titiunik explain why robust bias-corrected inference became standard in modern RD work.
