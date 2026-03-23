---
title: "Dot-and-Whisker Marginal Effects Plot"
date: 2026-03-19
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a dot-and-whisker marginal effects plot and shows how to display model results on an outcome scale that readers can often interpret more directly than raw coefficients. Coefficient plots are..."
excerpt: "Visualizing average marginal effects rather than raw model coefficients"
---
This chapter creates a dot-and-whisker marginal effects plot and shows how to display model results on an outcome scale that readers can often interpret more directly than raw coefficients. Coefficient plots are useful, but they can be hard to read when the model uses a nonlinear link such as logistic regression. A coefficient in log-odds units is mathematically correct, yet it is not always the quantity a policy reader wants to see. A marginal effects plot solves that problem by plotting changes in predicted probability, expected count, or expected outcome rather than changes in the model's linear predictor.

The figure is especially useful in health economics and decision sciences because many substantive questions are naturally framed in terms of probability or expected outcome differences. How much does a discharge intervention change the probability of readmission? How much does poor adherence change the predicted risk of death? How much does treatment change an expected outcome for a typical patient profile? Those are marginal-effects questions.

## What the visualization is showing

We will build a dot-and-whisker plot for average marginal effects from a regression model. Each row will show:

1. a predictor label,
2. an estimated marginal effect,
3. a confidence interval,
4. a vertical reference line at the null value.

For average marginal effects on a probability scale, the null value is 0. Values to the right of 0 indicate an increase in predicted probability. Values to the left indicate a decrease. Confidence intervals that cross 0 indicate that the data remain compatible with no average marginal effect at the chosen confidence level.

The main conceptual difference from a coefficient plot is that the x-axis now represents an outcome-scale effect rather than a model-parameter scale.

## Step 1: Create and fit a synthetic regression model

We will start with a synthetic logistic regression for 30-day hospital readmission. The goal is to build a fitted model from which we can compute average marginal effects and then visualize them.

``` r
library(dplyr)
```

```
## 
## Attaching package: 'dplyr'
```

```
## The following objects are masked from 'package:stats':
## 
## filter, lag
```

```
## The following objects are masked from 'package:base':
## 
## intersect, setdiff, setequal, union
```

``` r
library(ggplot2)
library(knitr)

set.seed(2026)

n_patients <- 900

synthetic_readmission <- data.frame(
 age10 = rnorm(n_patients, mean = 6.9, sd = 1.0),
 prior_admissions = rpois(n_patients, lambda = 1.4),
 comorbidity_score = rnorm(n_patients, mean = 0, sd = 1),
 social_risk = rnorm(n_patients, mean = 0, sd = 1),
 intervention = rbinom(n_patients, size = 1, prob = 0.5)
)

linear_predictor <- with(
 synthetic_readmission,
 -1.15 +
 0.20 * age10 +
 0.30 * prior_admissions +
 0.42 * comorbidity_score +
 0.28 * social_risk -
 0.48 * intervention
)

synthetic_readmission$readmission <- rbinom(
 n_patients,
 size = 1,
 prob = plogis(linear_predictor)
)

synthetic_logit <- glm(
 readmission ~ intervention + age10 + prior_admissions + comorbidity_score + social_risk,
 data = synthetic_readmission,
 family = binomial
)

synthetic_summary <- data.frame(
 sample_size = nrow(synthetic_readmission),
 readmission_rate = mean(synthetic_readmission$readmission),
 mean_age10 = mean(synthetic_readmission$age10),
 mean_prior_admissions = mean(synthetic_readmission$prior_admissions)
)

synthetic_summary[, -1] <- round(synthetic_summary[, -1], 3)

knitr::kable(
 synthetic_summary,
 caption = "Summary of the synthetic readmission dataset used for the marginal effects plot"
)
```

Table: Summary of the synthetic readmission dataset used for the marginal effects plot

| sample_size| readmission_rate| mean_age10| mean_prior_admissions|
|-----------:|----------------:|----------:|---------------------:|
| 900| 0.606| 6.923| 1.424|

This model is similar to the one used in the coefficient-plot chapter, but the quantity we will report is different. We want changes in predicted readmission probability, not just changes in log-odds.

## Step 2: Compute average marginal effects manually

Because the local environment does not rely on a dedicated marginal-effects package, we will compute the effects directly from the fitted model. For a binary predictor such as `intervention`, the average marginal effect is the average difference in predicted probability when the variable is set to 1 versus 0 for every observation. For a continuous predictor, we can approximate the derivative by taking a small finite difference.

``` r
compute_binary_ame <- function(model, data, var) {
 data_lo <- data
 data_hi <- data

 data_lo[[var]] <- 0
 data_hi[[var]] <- 1

 p_lo <- predict(model, newdata = data_lo, type = "response")
 p_hi <- predict(model, newdata = data_hi, type = "response")

 diffs <- p_hi - p_lo

 data.frame(
 term = var,
 estimate = mean(diffs),
 std_error = sd(diffs) / sqrt(length(diffs))
 )
}

compute_continuous_ame <- function(model, data, var, step = 0.1) {
 data_lo <- data
 data_hi <- data

 data_lo[[var]] <- data_lo[[var]] - step / 2
 data_hi[[var]] <- data_hi[[var]] + step / 2

 p_lo <- predict(model, newdata = data_lo, type = "response")
 p_hi <- predict(model, newdata = data_hi, type = "response")

 diffs <- (p_hi - p_lo) / step

 data.frame(
 term = var,
 estimate = mean(diffs),
 std_error = sd(diffs) / sqrt(length(diffs))
 )
}

synthetic_ame <- dplyr::bind_rows(
 compute_binary_ame(synthetic_logit, synthetic_readmission, "intervention"),
 compute_continuous_ame(synthetic_logit, synthetic_readmission, "age10"),
 compute_continuous_ame(synthetic_logit, synthetic_readmission, "prior_admissions", step = 1),
 compute_continuous_ame(synthetic_logit, synthetic_readmission, "comorbidity_score"),
 compute_continuous_ame(synthetic_logit, synthetic_readmission, "social_risk")
) |>
 dplyr::mutate(
 conf_low = estimate - 1.96 * std_error,
 conf_high = estimate + 1.96 * std_error,
 term_label = c(
 "Discharge intervention",
 "Age (per 10 years)",
 "Prior admissions",
 "Comorbidity score",
 "Social risk index"
 )
 )

synthetic_table <- synthetic_ame |>
 dplyr::transmute(
 predictor = term_label,
 average_marginal_effect = round(estimate, 3),
 lower_95_ci = round(conf_low, 3),
 upper_95_ci = round(conf_high, 3)
 )

knitr::kable(
 synthetic_table,
 caption = "Synthetic average marginal effects on the readmission probability scale"
)
```

Table: Synthetic average marginal effects on the readmission probability scale

|predictor | average_marginal_effect| lower_95_ci| upper_95_ci|
|:----------------------|-----------------------:|-----------:|-----------:|
|Discharge intervention | -0.080| -0.081| -0.079|
|Age (per 10 years) | 0.049| 0.049| 0.050|
|Prior admissions | 0.053| 0.053| 0.054|
|Comorbidity score | 0.088| 0.087| 0.089|
|Social risk index | 0.068| 0.067| 0.068|

This table contains the information that the plot will encode. A coefficient plot would show effects in log-odds units; this plot will show changes in predicted readmission probability.

## Step 3: Build a reusable dot-and-whisker plotting function

The function below is designed for marginal effects with confidence intervals centered around a null value of 0. The aesthetic grammar is similar to a coefficient plot, but the x-axis label now refers to marginal effects rather than model coefficients.

``` r
build_marginal_effects_plot <- function(data, title, subtitle, x_label) {
 plot_data <- data |>
 dplyr::mutate(
 term_label = factor(term_label, levels = rev(term_label)),
 direction = ifelse(estimate >= 0, "Increase", "Decrease"),
 label_text = sprintf("%.3f (%.3f to %.3f)", estimate, conf_low, conf_high)
 )

 label_position <- max(plot_data$conf_high) + 0.15 * diff(range(c(plot_data$conf_low, plot_data$conf_high)))

 ggplot(plot_data, aes(x = estimate, y = term_label, color = direction)) +
 geom_vline(xintercept = 0, color = "#7f7f7f", linetype = "dashed", linewidth = 0.6) +
 geom_segment(
 aes(x = conf_low, xend = conf_high, yend = term_label),
 linewidth = 0.95,
 show.legend = FALSE
 ) +
 geom_point(size = 3.2, show.legend = FALSE) +
 geom_text(
 aes(x = label_position, label = label_text),
 hjust = 0,
 color = "#1f1f1f",
 size = 3.4
 ) +
 scale_color_manual(values = c("Decrease" = "#2b8cbe", "Increase" = "#8c2d04")) +
 coord_cartesian(
 xlim = c(
 min(plot_data$conf_low) - 0.18 * diff(range(c(plot_data$conf_low, plot_data$conf_high))),
 label_position + 0.05
 ),
 clip = "off"
 ) +
 labs(
 title = title,
 subtitle = subtitle,
 x = x_label,
 y = NULL
 ) +
 theme_minimal(base_size = 12) +
 theme(
 panel.grid.major.y = element_blank,
 panel.grid.minor = element_blank,
 plot.margin = margin(10, 110, 10, 10)
 )
}
```

The figure is intentionally restrained. The point is to show estimated magnitude and uncertainty on a scale that is closer to the substantive question being asked.

## Step 4: Draw the synthetic marginal effects plot

``` r
synthetic_marginal_plot <- build_marginal_effects_plot(
 synthetic_ame,
 title = "Dot-and-whisker plot of synthetic average marginal effects",
 subtitle = "Points show average changes in readmission probability; bars show 95% confidence intervals",
 x_label = "Average marginal effect on readmission probability"
)

synthetic_marginal_plot
```

![plot of chunk unnamed-chunk-4](/tutorials/rendered-assets/visualization-tools-dot-and-whisker-marginal-effects-plot/unnamed-chunk-4-1.png)

This figure is often easier to explain than the corresponding coefficient plot. The intervention's marginal effect can now be read as an average percentage-point change in readmission probability rather than as a change in log-odds.

## Step 5: Create a real-world marginal effects plot from a public trial dataset

For a real-world example, we can use the public `colon` dataset from the `survival` package. These data come from the adjuvant colon cancer trials reported by Laurie and colleagues and Moertel and colleagues. Instead of plotting raw logistic or Cox coefficients, we will fit a logistic model for 1-year mortality and then plot average marginal effects on the probability scale.

This is a transparent partial replication. The original trial publications did not report exactly this plot, and the 1-year mortality model below is a modern teaching adaptation rather than a reconstruction of the original printed analyses.

``` r
library(survival)

colon_1y <- survival::colon |>
 dplyr::filter(etype == 2, rx %in% c("Obs", "Lev+5FU")) |>
 dplyr::mutate(
 treatment = ifelse(rx == "Lev+5FU", 1, 0),
 age10 = age / 10,
 male = ifelse(sex == 1, 1, 0),
 nodes4 = ifelse(nodes > 4, 1, 0),
 obstruction = ifelse(obstruct == 1, 1, 0),
 adherence = ifelse(adhere == 1, 1, 0),
 death_1y = ifelse(status == 1 & time <= 365, 1, 0)
 ) |>
 dplyr::filter(
 !is.na(treatment),
 !is.na(age10),
 !is.na(male),
 !is.na(nodes4),
 !is.na(obstruction),
 !is.na(adherence),
 !is.na(death_1y)
 )

colon_logit <- glm(
 death_1y ~ treatment + age10 + male + nodes4 + obstruction + adherence,
 data = colon_1y,
 family = binomial
)

colon_ame <- dplyr::bind_rows(
 compute_binary_ame(colon_logit, colon_1y, "treatment"),
 compute_continuous_ame(colon_logit, colon_1y, "age10"),
 compute_binary_ame(colon_logit, colon_1y, "male"),
 compute_binary_ame(colon_logit, colon_1y, "nodes4"),
 compute_binary_ame(colon_logit, colon_1y, "obstruction"),
 compute_binary_ame(colon_logit, colon_1y, "adherence")
) |>
 dplyr::mutate(
 conf_low = estimate - 1.96 * std_error,
 conf_high = estimate + 1.96 * std_error,
 term_label = c(
 "Levamisole + 5FU treatment",
 "Age (per 10 years)",
 "Male sex",
 "More than 4 positive nodes",
 "Obstruction present",
 "Adherent to protocol"
 )
 )

colon_table <- colon_ame |>
 dplyr::transmute(
 predictor = term_label,
 average_marginal_effect = round(estimate, 3),
 lower_95_ci = round(conf_low, 3),
 upper_95_ci = round(conf_high, 3)
 )

knitr::kable(
 colon_table,
 caption = "Average marginal effects from a logistic model for 1-year mortality in the public colon trial data"
)
```

Table: Average marginal effects from a logistic model for 1-year mortality in the public colon trial data

|predictor | average_marginal_effect| lower_95_ci| upper_95_ci|
|:--------------------------|-----------------------:|-----------:|-----------:|
|Levamisole + 5FU treatment | 0.014| 0.013| 0.015|
|Age (per 10 years) | 0.033| 0.031| 0.035|
|Male sex | -0.018| -0.019| -0.016|
|More than 4 positive nodes | 0.101| 0.097| 0.105|
|Obstruction present | 0.067| 0.063| 0.070|
|Adherent to protocol | 0.056| 0.053| 0.058|

``` r
colon_marginal_plot <- build_marginal_effects_plot(
 colon_ame,
 title = "Dot-and-whisker plot of marginal effects in the public colon trial data",
 subtitle = "Points show average effects on the 1-year mortality probability; bars show 95% confidence intervals",
 x_label = "Average marginal effect on 1-year mortality probability"
)

colon_marginal_plot
```

![plot of chunk unnamed-chunk-6](/tutorials/rendered-assets/visualization-tools-dot-and-whisker-marginal-effects-plot/unnamed-chunk-6-1.png)

This figure highlights something coefficient tables often hide: some predictors may have modest-looking model coefficients but practically meaningful effects on predicted risk once translated onto the probability scale.

## How to read the figure carefully

A marginal effects plot is usually easier to interpret than a coefficient plot, but it is not assumption free. The displayed uncertainty still depends on the fitted model. The plotted effects are summaries of predicted differences under that model, not model-free causal quantities.

The plot is also sensitive to how marginal effects are defined. For binary variables, the average discrete change from 0 to 1 is often the most natural choice. For continuous variables, the derivative or finite-difference approximation depends on scaling. A change per 10 years of age will look different from a change per single year. That is why labels and units matter.

Finally, the plot is only as informative as the model and outcome scale. If the fitted model is badly misspecified, a well-designed figure will still summarize the wrong quantity very clearly.

## Further reading

Kastellec and Leoni make the general case for estimate-focused graphics rather than dense regression tables. The colon cancer trial papers by Laurie and colleagues and Moertel and colleagues provide the public clinical setting used for the partial real-world example. A natural next step after this chapter is to compare coefficient plots and marginal-effects plots directly for the same nonlinear model so readers can see why the distinction matters.

## References

- Laurie, John A.; Moertel, Charles G.; Fleming, Thomas R.; Wieand, H. S.; Leigh, James E.; Rubin, Joseph; McCormack, G. W.; Gerstner, J. B.; Krook, J. E.; Mailliard, James A. (1989). "Surgical Adjuvant Therapy of Large-Bowel Carcinoma: An Evaluation of Levamisole and the Combination of Levamisole and Fluorouracil." *Journal of Clinical Oncology*, 7(10), 1447--1456. DOI: <https://doi.org/10.1200/JCO.1989.7.10.1447>.
- Moertel, Charles G.; Fleming, Thomas R.; Macdonald, John S.; Haller, Daniel G.; Laurie, John A.; Goodman, Phyllis J.; Ungerleider, James S.; Emerson, William A.; Tormey, Douglas C.; Glick, John H.; Veeder, Michael H.; Mailliard, James A. (1990). "Levamisole and Fluorouracil for Adjuvant Therapy of Resected Colon Carcinoma." *New England Journal of Medicine*, 322(6), 352--358. DOI: <https://doi.org/10.1056/NEJM199002083220602>.
- Kastellec, Jonathan P.; Leoni, Eduardo L. (2007). "Using Graphs Instead of Tables in Political Science." *Perspectives on Politics*, 5(4), 755--771. DOI: <https://doi.org/10.1017/S1537592707072209>.
