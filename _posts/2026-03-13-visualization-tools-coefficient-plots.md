---
title: "Coefficient Plots"
date: 2026-03-13
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a coefficient plot and shows how to turn a fitted regression model into a clear, publication-ready figure. Coefficient plots are useful because they put point estimates and confidence intervals..."
excerpt: "Visualizing regression estimates and uncertainty more clearly than a table"
---
This chapter creates a coefficient plot and shows how to turn a fitted regression model into a clear, publication-ready figure. Coefficient plots are useful because they put point estimates and confidence intervals at the center of the presentation rather than hiding them in a table of numbers. That is why they have become a standard way to report regression results in many applied fields.

The figure is especially helpful when a model has several predictors. A regression table forces the reader to move back and forth across rows and columns to understand sign, magnitude, and uncertainty. A coefficient plot makes those three features visible at once.

## What the visualization is showing

We will build a coefficient plot for a regression model. Each row will show:

1. a predictor label,
2. the estimated coefficient,
3. its confidence interval,
4. a vertical reference line at the null value.

When the coefficients are shown on the original model scale, the null value is usually 0. Values to the right of 0 indicate a positive association; values to the left indicate a negative association. Confidence intervals that cross 0 indicate that the data are still compatible with no association at the chosen confidence level.

## Step 1: Create and fit a synthetic regression model

We will start with a synthetic logistic regression for 30-day hospital readmission. The purpose is not to make a substantive claim. It is to create a realistic model object from which we can build a polished coefficient plot.

``` r
library(dplyr)
```

<div class="cell-output-stdout">
<pre>Attaching package: &#x27;dplyr&#x27;

The following objects are masked from &#x27;package:stats&#x27;:

filter, lag

The following objects are masked from &#x27;package:base&#x27;:

intersect, setdiff, setequal, union</pre>
</div>

``` r
library(ggplot2)
library(knitr)

set.seed(2026)

n_patients <- 800

synthetic_readmission <- data.frame(
 age10 = rnorm(n_patients, mean = 6.8, sd = 1.1),
 prior_admissions = rpois(n_patients, lambda = 1.3),
 comorbidity_score = rnorm(n_patients, mean = 0, sd = 1),
 social_risk = rnorm(n_patients, mean = 0, sd = 1),
 intervention = rbinom(n_patients, size = 1, prob = 0.5)
)

linear_predictor <- with(
 synthetic_readmission,
 -1.2 +
 0.22 * age10 +
 0.28 * prior_admissions +
 0.40 * comorbidity_score +
 0.31 * social_risk -
 0.45 * intervention
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

extract_glm_coefficients <- function(model, labels) {
 model_summary <- summary(model)

 out <- data.frame(
 term = rownames(model_summary$coefficients),
 estimate = model_summary$coefficients[, 1],
 std_error = model_summary$coefficients[, 2],
 row.names = NULL
 ) |>
 dplyr::filter(term != "(Intercept)") |>
 dplyr::mutate(
 conf_low = estimate - 1.96 * std_error,
 conf_high = estimate + 1.96 * std_error,
 term_label = labels[term],
 odds_ratio = exp(estimate),
 or_low = exp(conf_low),
 or_high = exp(conf_high)
 )

 out
}

synthetic_labels <- c(
 intervention = "Discharge intervention",
 age10 = "Age (per 10 years)",
 prior_admissions = "Prior admissions",
 comorbidity_score = "Comorbidity score",
 social_risk = "Social risk index"
)

synthetic_coef <- extract_glm_coefficients(synthetic_logit, synthetic_labels)

synthetic_table <- synthetic_coef |>
 dplyr::transmute(
 predictor = term_label,
 log_odds_coefficient = round(estimate, 3),
 lower_95_ci = round(conf_low, 3),
 upper_95_ci = round(conf_high, 3),
 odds_ratio = round(odds_ratio, 2)
 )

knitr::kable(
 synthetic_table,
 caption = "Synthetic logistic regression estimates used in the coefficient plot"
)
```

Table: Synthetic logistic regression estimates used in the coefficient plot

|predictor | log_odds_coefficient| lower_95_ci| upper_95_ci| odds_ratio|
|:----------------------|--------------------:|-----------:|-----------:|----------:|
|Discharge intervention | -0.439| -0.733| -0.145| 0.64|
|Age (per 10 years) | 0.351| 0.212| 0.490| 1.42|
|Prior admissions | 0.339| 0.204| 0.473| 1.40|
|Comorbidity score | 0.242| 0.087| 0.397| 1.27|
|Social risk index | 0.176| 0.027| 0.325| 1.19|

This table is exactly the type of result that often appears in appendices. The coefficient plot will present the same information more directly.

## Step 2: Build a reusable coefficient-plot function

The function below creates a coefficient plot on the original coefficient scale. It uses a vertical line at 0, horizontal intervals, and colored points that distinguish positive from negative associations.

``` r
build_coefficient_plot <- function(data, title, subtitle, x_label) {
 plot_data <- data |>
 dplyr::mutate(
 term_label = factor(term_label, levels = rev(term_label)),
 direction = ifelse(estimate >= 0, "Positive", "Negative"),
 label_text = sprintf("%.2f (%.2f to %.2f)", estimate, conf_low, conf_high)
 )

 label_position <- max(plot_data$conf_high) + 0.15 * diff(range(c(plot_data$conf_low, plot_data$conf_high)))

 ggplot(plot_data, aes(x = estimate, y = term_label, color = direction)) +
 geom_vline(xintercept = 0, color = "#7f7f7f", linetype = "dashed", linewidth = 0.6) +
 geom_segment(
 aes(x = conf_low, xend = conf_high, yend = term_label),
 linewidth = 0.9,
 show.legend = FALSE
 ) +
 geom_point(size = 3.2, show.legend = FALSE) +
 geom_text(
 aes(x = label_position, label = label_text),
 hjust = 0,
 color = "#1f1f1f",
 size = 3.5
 ) +
 scale_color_manual(values = c("Negative" = "#2b8cbe", "Positive" = "#8c2d04")) +
 coord_cartesian(
 xlim = c(
 min(plot_data$conf_low) - 0.15 * diff(range(c(plot_data$conf_low, plot_data$conf_high))),
 label_position + 0.35
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

The design is deliberately minimal. The figure needs only a few components to work well:

- a null line,
- point estimates,
- confidence intervals,
- readable term labels,
- numerical annotations when desired.

The moment extra decoration becomes dominant, the plot stops doing its job.

## Step 3: Draw the synthetic coefficient plot

``` r
synthetic_coefficient_plot <- build_coefficient_plot(
 synthetic_coef,
 title = "Coefficient plot for a synthetic readmission model",
 subtitle = "Points show logistic regression coefficients; bars show 95% confidence intervals",
 x_label = "Log-odds coefficient"
)

synthetic_coefficient_plot
```

![plot of chunk unnamed-chunk-3](/tutorials/rendered-assets/visualization-tools-coefficient-plots/unnamed-chunk-3-1.png)

This figure can be read much faster than the regression table. The discharge intervention is clearly protective because its coefficient is negative and its interval stays below 0. Age, prior admissions, comorbidity, and social risk all move in the opposite direction.

## Step 4: Create a real-world coefficient plot from a public clinical trial dataset

For a real-world example, we can use the public `colon` dataset from the `survival` package. These data come from adjuvant colon cancer trials reported by Laurie and colleagues and Moertel and colleagues. We will fit a multivariable Cox proportional hazards model for overall survival and then visualize the adjusted log hazard ratios with a coefficient plot.

This is a transparent partial replication. The original trial papers were not published with exactly this plot, and the covariate specification below is a modern teaching adaptation rather than a reconstruction of the original printed model table.

``` r
library(survival)

colon_os <- survival::colon |>
 dplyr::filter(etype == 2, rx %in% c("Obs", "Lev+5FU")) |>
 dplyr::mutate(
 treatment = ifelse(rx == "Lev+5FU", 1, 0),
 age10 = age / 10,
 male = ifelse(sex == 1, 1, 0),
 nodes4 = ifelse(nodes > 4, 1, 0),
 obstruction = ifelse(obstruct == 1, 1, 0),
 adherence = ifelse(adhere == 1, 1, 0)
 )

colon_cox <- survival::coxph(
 survival::Surv(time, status) ~ treatment + age10 + male + nodes4 + obstruction + adherence,
 data = colon_os
)

extract_cox_coefficients <- function(model, labels) {
 model_summary <- summary(model)

 out <- data.frame(
 term = rownames(model_summary$coefficients),
 estimate = model_summary$coefficients[, "coef"],
 std_error = model_summary$coefficients[, "se(coef)"],
 row.names = NULL
 ) |>
 dplyr::mutate(
 conf_low = estimate - 1.96 * std_error,
 conf_high = estimate + 1.96 * std_error,
 term_label = labels[term],
 hazard_ratio = exp(estimate),
 hr_low = exp(conf_low),
 hr_high = exp(conf_high)
 )

 out
}

colon_labels <- c(
 treatment = "Levamisole + 5FU treatment",
 age10 = "Age (per 10 years)",
 male = "Male sex",
 nodes4 = "More than 4 positive nodes",
 obstruction = "Obstruction present",
 adherence = "Adherent to protocol"
)

colon_coef <- extract_cox_coefficients(colon_cox, colon_labels)

colon_table <- colon_coef |>
 dplyr::transmute(
 predictor = term_label,
 log_hazard_ratio = round(estimate, 3),
 lower_95_ci = round(conf_low, 3),
 upper_95_ci = round(conf_high, 3),
 hazard_ratio = round(hazard_ratio, 2)
 )

knitr::kable(
 colon_table,
 caption = "Adjusted Cox model estimates from the public colon cancer trial data"
)
```

Table: Adjusted Cox model estimates from the public colon cancer trial data

|predictor | log_hazard_ratio| lower_95_ci| upper_95_ci| hazard_ratio|
|:--------------------------|----------------:|-----------:|-----------:|------------:|
|Levamisole + 5FU treatment | -0.388| -0.625| -0.151| 0.68|
|Age (per 10 years) | 0.023| -0.074| 0.121| 1.02|
|Male sex | -0.114| -0.347| 0.119| 0.89|
|More than 4 positive nodes | 0.962| 0.718| 1.205| 2.62|
|Obstruction present | 0.153| -0.139| 0.446| 1.17|
|Adherent to protocol | 0.289| -0.023| 0.601| 1.34|

The coefficient table is now built from a real fitted model. The plot uses exactly the same visual grammar as the synthetic example, but the estimates come from an applied clinical dataset.

``` r
colon_coefficient_plot <- build_coefficient_plot(
 colon_coef,
 title = "Coefficient plot for an adjusted Cox model in the colon trial data",
 subtitle = "Points show log hazard ratios; bars show 95% confidence intervals",
 x_label = "Log hazard ratio"
)

colon_coefficient_plot
```

![plot of chunk unnamed-chunk-5](/tutorials/rendered-assets/visualization-tools-coefficient-plots/unnamed-chunk-5-1.png)

This figure highlights the strongest associations immediately. The treatment term is clearly protective, with a negative adjusted log hazard ratio. Having more than 4 positive nodes is strongly associated with worse survival. Other terms, such as age or obstruction, are more uncertain in this particular specification.

## How to read the figure carefully

A coefficient plot is a summary of model output, not a substitute for modeling judgment. The plotted intervals reflect sampling uncertainty conditional on the fitted model. They do not tell the reader whether the model specification is correct, whether confounding has been handled adequately, or whether the effect scale is the most relevant one.

The figure is also easiest to interpret when the coefficient scale is meaningful. For logistic and Cox models, many readers ultimately think in odds ratios or hazard ratios, even if the plot is drawn on the log scale. That is why it is often helpful to include numerical labels or a companion table.

Finally, coefficient plots are most useful when they are selective. If a model has dozens of fixed effects, interactions, and transformed terms, plotting everything can make the figure unreadable. In those cases, the analyst should decide which parameters are substantively important enough to show.

## Further reading

Kastellec and Leoni provide a clear argument for replacing dense regression tables with figures that foreground estimates and uncertainty. The colon cancer trial papers by Laurie and colleagues and Moertel and colleagues provide a real clinical setting in which multivariable treatment-effect reporting is useful.

## References

- Kastellec, Jonathan P.; Leoni, Eduardo L. (2007). "Using Graphs Instead of Tables in Political Science." *Perspectives on Politics*, 5(4), 755--771. DOI: <https://doi.org/10.1017/S1537592707072209>.
- Laurie, John A.; Moertel, Charles G.; Fleming, Thomas R.; Wieand, H. S.; Leigh, James E.; Rubin, Joseph; McCormack, G. W.; Gerstner, J. B.; Krook, J. E.; Mailliard, James A. (1989). "Surgical Adjuvant Therapy of Large-Bowel Carcinoma: An Evaluation of Levamisole and the Combination of Levamisole and Fluorouracil." *Journal of Clinical Oncology*, 7(10), 1447--1456. DOI: <https://doi.org/10.1200/JCO.1989.7.10.1447>.
- Moertel, Charles G.; Fleming, Thomas R.; Macdonald, John S.; Haller, Daniel G.; Laurie, John A.; Goodman, Phyllis J.; Ungerleider, James S.; Emerson, William A.; Tormey, Douglas C.; Glick, John H.; Veeder, Michael H.; Mailliard, James A. (1990). "Levamisole and Fluorouracil for Adjuvant Therapy of Resected Colon Carcinoma." *New England Journal of Medicine*, 322(6), 352--358. DOI: <https://doi.org/10.1056/NEJM199002083220602>.
