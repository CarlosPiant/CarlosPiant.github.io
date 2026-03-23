---
title: "Love Plot for Covariate Balance"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a Love plot, a figure designed to show covariate balance before and after an adjustment step such as matching or weighting. In observational health research, one of the first questions after..."
excerpt: "Building a balance figure that shows whether adjustment made treated and control groups more comparable"
---
This chapter builds a Love plot, a figure designed to show covariate balance before and after an adjustment step such as matching or weighting. In observational health research, one of the first questions after estimating a propensity score is whether the treated and control groups actually became more comparable on the observed covariates. A Love plot answers that question quickly because it places the absolute standardized mean difference for each covariate on one horizontal axis and then overlays the values before and after adjustment. Stuart and Austin both emphasize that balance diagnostics are central to credible propensity-score work, not optional decoration.

The figure is useful because a propensity-score model can look sophisticated while still leaving important imbalance behind. A regression table or a list of mean comparisons is too fragmented to show the whole pattern. A Love plot lets the reader see which variables were initially far apart, which ones improved after adjustment, and whether the post-adjustment imbalance is small enough to support a more credible causal comparison.

## What the visualization is showing

We will build a Love plot with:

1. one row per covariate,
2. an absolute standardized mean difference before adjustment,
3. an absolute standardized mean difference after adjustment,
4. vertical reference lines that mark common balance thresholds.

The standardized mean difference for a continuous covariate is

$$
\text{SMD}(X) = \frac{\bar{X}_1 - \bar{X}_0}{\sqrt{\frac{s_1^2 + s_0^2}{2}}},
$$

where group 1 is the treated group and group 0 is the control group. For a binary covariate, the same formula applies if the means are interpreted as proportions and the variances as Bernoulli variances. The Love plot usually displays the absolute value, because the practical question is the size of the imbalance rather than its direction.

Values below about 0.1 are often treated as acceptable in applied work, although that threshold is a rule of thumb rather than a theorem. The plot is therefore a diagnostic figure: it helps the analyst judge whether the design stage has made the groups similar enough on the observed covariates.

## Step 1: Create a synthetic observational dataset with confounding

We begin with a synthetic care-management example. Treatment assignment is deliberately confounded: older, sicker, and lower-income patients are more likely to receive the intervention. That makes the initial covariate imbalance visible and gives the Love plot something meaningful to diagnose.

```r
library(dplyr)
library(ggplot2)
library(knitr)
library(MatchIt)

format_numeric_table <- function(df, digits = 3) {
 numeric_cols <- vapply(df, is.numeric, logical(1))
 df[numeric_cols] <- lapply(df[numeric_cols], round, digits = digits)
 df
}

weighted_mean <- function(x, w) {
 sum(w * x) / sum(w)
}

weighted_var <- function(x, w) {
 mu <- weighted_mean(x, w)
 sum(w * (x - mu)^2) / sum(w)
}

smd_numeric <- function(x, z, w = NULL) {
 if (is.null(w)) {
 w <- rep(1, length(x))
 }

 xt <- x[z == 1]
 xc <- x[z == 0]
 wt <- w[z == 1]
 wc <- w[z == 0]

 vt <- weighted_var(xt, wt)
 vc <- weighted_var(xc, wc)

 if ((vt + vc) == 0) {
 return(0)
 }

 (weighted_mean(xt, wt) - weighted_mean(xc, wc)) / sqrt((vt + vc) / 2)
}

compute_balance <- function(data, covariates, treat_var, weight_list, labels) {
 z <- data[[treat_var]]

 balance_rows <- lapply(names(weight_list), function(sample_label) {
 w <- weight_list[[sample_label]]

 data.frame(
 covariate = covariates,
 sample = sample_label,
 smd = vapply(covariates, function(v) smd_numeric(data[[v]], z, w), numeric(1)),
 row.names = NULL
 )
 })

 bind_rows(balance_rows) |>
 mutate(
 abs_smd = abs(smd),
 covariate_label = unname(labels[covariate])
 )
}

build_love_plot <- function(balance_df, title, subtitle) {
 segment_df <- balance_df |>
 group_by(covariate_label) |>
 summarize(
 min_abs_smd = min(abs_smd),
 max_abs_smd = max(abs_smd),
.groups = "drop"
 ) |>
 arrange(min_abs_smd)

 plot_df <- balance_df |>
 mutate(
 covariate_label = factor(covariate_label, levels = segment_df$covariate_label)
 )

 ggplot(plot_df, aes(x = abs_smd, y = covariate_label, color = sample, shape = sample)) +
 geom_segment(
 data = segment_df,
 aes(
 x = min_abs_smd,
 xend = max_abs_smd,
 y = covariate_label,
 yend = covariate_label
 ),
 inherit.aes = FALSE,
 linewidth = 0.8,
 color = "#d9d9d9"
 ) +
 geom_vline(xintercept = 0.1, linetype = "dashed", linewidth = 0.7, color = "#7f2704") +
 geom_vline(xintercept = 0.2, linetype = "dotted", linewidth = 0.7, color = "#7f7f7f") +
 geom_point(size = 3.1) +
 scale_color_manual(values = c("Before adjustment" = "#8c2d04", "After adjustment" = "#2171b5")) +
 scale_shape_manual(values = c("Before adjustment" = 16, "After adjustment" = 17)) +
 labs(
 title = title,
 subtitle = subtitle,
 x = "Absolute standardized mean difference",
 y = NULL,
 color = NULL,
 shape = NULL
 ) +
 theme_minimal(base_size = 12) +
 theme(
 panel.grid.major.y = element_blank,
 panel.grid.minor = element_blank,
 legend.position = "bottom"
 )
}
```

```r
set.seed(2027)

n_patients <- 1200

synthetic_balance_data <- data.frame(
 age = rnorm(n_patients, mean = 67, sd = 10),
 prior_admissions = rpois(n_patients, lambda = 1.4),
 comorbidity_score = rnorm(n_patients, mean = 0, sd = 1),
 female = rbinom(n_patients, size = 1, prob = 0.55),
 low_income = rbinom(n_patients, size = 1, prob = 0.32),
 baseline_cost_k = rgamma(n_patients, shape = 4, scale = 1.6)
)

synthetic_treat_lp <- with(
 synthetic_balance_data,
 -0.8 +
 0.035 * age +
 0.40 * prior_admissions +
 0.85 * comorbidity_score +
 0.55 * low_income -
 0.18 * female +
 0.20 * baseline_cost_k
)

synthetic_balance_data$treat <- rbinom(
 n_patients,
 size = 1,
 prob = plogis(synthetic_treat_lp)
)

synthetic_ps_model <- glm(
 treat ~ age + prior_admissions + comorbidity_score + female + low_income + baseline_cost_k,
 data = synthetic_balance_data,
 family = binomial
)

synthetic_ps <- pmin(
 pmax(predict(synthetic_ps_model, type = "response"), 0.025),
 0.975
)

treat_rate <- mean(synthetic_balance_data$treat)

synthetic_weights <- ifelse(
 synthetic_balance_data$treat == 1,
 treat_rate / synthetic_ps,
 (1 - treat_rate) / (1 - synthetic_ps)
)

synthetic_covariates <- c(
 "age",
 "prior_admissions",
 "comorbidity_score",
 "female",
 "low_income",
 "baseline_cost_k"
)

synthetic_labels <- c(
 age = "Age",
 prior_admissions = "Prior admissions",
 comorbidity_score = "Comorbidity score",
 female = "Female",
 low_income = "Low income",
 baseline_cost_k = "Baseline cost (thousand USD)"
)

synthetic_balance <- compute_balance(
 data = synthetic_balance_data,
 covariates = synthetic_covariates,
 treat_var = "treat",
 weight_list = list(
 "Before adjustment" = rep(1, nrow(synthetic_balance_data)),
 "After adjustment" = synthetic_weights
 ),
 labels = synthetic_labels
)

synthetic_summary <- data.frame(
 sample_size = nrow(synthetic_balance_data),
 treatment_rate = mean(synthetic_balance_data$treat),
 mean_propensity_score = mean(synthetic_ps),
 max_weight = max(synthetic_weights),
 mean_weight = mean(synthetic_weights)
)

synthetic_balance_table <- merge(
 subset(
 synthetic_balance,
 sample == "Before adjustment",
 select = c("covariate_label", "abs_smd")
 ),
 subset(
 synthetic_balance,
 sample == "After adjustment",
 select = c("covariate_label", "abs_smd")
 ),
 by = "covariate_label",
 suffixes = c("_before", "_after")
)

synthetic_balance_table <- synthetic_balance_table |>
 arrange(desc(abs_smd_before))

knitr::kable(
 format_numeric_table(synthetic_summary, digits = 3),
 caption = "Synthetic propensity-score weighting setup for the Love plot"
)

knitr::kable(
 format_numeric_table(synthetic_balance_table, digits = 3),
 caption = "Absolute standardized mean differences before and after weighting in the synthetic example"
)
```

The tables already show the logic of the figure. Several covariates are meaningfully imbalanced before weighting, especially comorbidity, prior admissions, and low income. The weighted sample is much closer on those same variables.

## Step 2: Draw the synthetic Love plot

```r
synthetic_love_plot <- build_love_plot(
 synthetic_balance,
 title = "A Love plot makes covariate balance visible before and after weighting",
 subtitle = "Synthetic care-management example using stabilized inverse-probability weights"
)

synthetic_love_plot
```

This plot is easier to read than the table because it compresses the design-stage diagnostic into one visual pattern. The most important features are:

1. the red points, which show the initial imbalance,
2. the blue points, which show the post-weighting imbalance,
3. the distance between the two points on each row, which shows how much the adjustment helped,
4. the 0.1 reference line, which gives a rough target for acceptable balance.

If the blue points were still mostly to the right of 0.1, the weighting model would need more work. That might mean adding nonlinear terms, interactions, trimming poor-overlap regions, or changing the adjustment method entirely.

## Step 3: Build a real-world Love plot from the public LaLonde benchmark

For a real-world example, we use the public LaLonde job-training benchmark distributed with `MatchIt`, linked to LaLonde's experimental evaluation and the influential reanalysis by Dehejia and Wahba. The `MatchIt` framework developed by Ho, Imai, King, and Stuart is a natural teaching setting because it turns the design problem into an explicit preprocessing step.

The goal here is not to reproduce the full treatment-effect literature on the National Supported Work data. Instead, this is a transparent partial application focused on the figure itself: we estimate a nearest-neighbor propensity-score match and then ask whether the matched sample is more balanced on the observed covariates than the original one.

```r
data("lalonde", package = "MatchIt")

lalonde_plot_data <- lalonde |>
 mutate(
 black = as.integer(race == "black"),
 hispan = as.integer(race == "hispan"),
 re74_k = re74 / 1000,
 re75_k = re75 / 1000
 )

lalonde_match <- MatchIt::matchit(
 treat ~ age + educ + black + hispan + married + nodegree + re74_k + re75_k,
 data = lalonde_plot_data,
 method = "nearest",
 ratio = 1
)

lalonde_covariates <- c(
 "age",
 "educ",
 "black",
 "hispan",
 "married",
 "nodegree",
 "re74_k",
 "re75_k"
)

lalonde_labels <- c(
 age = "Age",
 educ = "Years of education",
 black = "Black",
 hispan = "Hispanic",
 married = "Married",
 nodegree = "No high-school degree",
 re74_k = "Earnings in 1974 (thousand USD)",
 re75_k = "Earnings in 1975 (thousand USD)"
)

lalonde_balance <- compute_balance(
 data = lalonde_plot_data,
 covariates = lalonde_covariates,
 treat_var = "treat",
 weight_list = list(
 "Before adjustment" = rep(1, nrow(lalonde_plot_data)),
 "After adjustment" = lalonde_match$weights
 ),
 labels = lalonde_labels
)

lalonde_summary <- data.frame(
 sample_size = nrow(lalonde_plot_data),
 treated_share = mean(lalonde_plot_data$treat),
 matched_units = sum(lalonde_match$weights > 0),
 treated_matched = sum(lalonde_plot_data$treat == 1 & lalonde_match$weights > 0),
 control_matched = sum(lalonde_plot_data$treat == 0 & lalonde_match$weights > 0)
)

lalonde_balance_table <- merge(
 subset(
 lalonde_balance,
 sample == "Before adjustment",
 select = c("covariate_label", "abs_smd")
 ),
 subset(
 lalonde_balance,
 sample == "After adjustment",
 select = c("covariate_label", "abs_smd")
 ),
 by = "covariate_label",
 suffixes = c("_before", "_after")
)

lalonde_balance_table <- lalonde_balance_table |>
 arrange(desc(abs_smd_before))

knitr::kable(
 format_numeric_table(lalonde_summary, digits = 1),
 caption = "Public LaLonde benchmark setup for the Love plot example"
)

knitr::kable(
 format_numeric_table(lalonde_balance_table, digits = 3),
 caption = "Absolute standardized mean differences before and after nearest-neighbor matching in the LaLonde benchmark"
)
```

The main substantive point is that the figure is evaluating the design stage rather than the outcome model. That is why Love plots are so useful in causal work. They separate the question "Did the design create comparable groups?" from the later question "What treatment effect do we estimate once the design is acceptable?"

## Step 4: Draw the real-world Love plot

```r
lalonde_love_plot <- build_love_plot(
 lalonde_balance,
 title = "Love plot for covariate balance in the public LaLonde benchmark",
 subtitle = "Absolute standardized mean differences before and after nearest-neighbor propensity-score matching"
)

lalonde_love_plot
```

This is a transparent partial replication rather than a literal reproduction of a figure from the original papers. LaLonde and Dehejia-Wahba were not published as Love-plot tutorials. The contribution here is different: it uses the public benchmark data and a standard matching design to show how a balance figure helps diagnose whether observational adjustment has moved the analysis closer to an experimental comparison.

## How to read the figure carefully

A Love plot is easy to misread if the analyst treats it as a causal estimate rather than a diagnostic. The figure does not prove that confounding has been solved. It shows only whether the observed covariates included in the balance check are more similar across treated and control groups.

Three reading rules matter most:

1. focus first on the post-adjustment points, because those determine whether the design is acceptable;
2. compare the whole pattern rather than one covariate in isolation, because one stubbornly imbalanced variable can still matter even if most others improved;
3. remember that excellent balance on observed covariates does not eliminate the possibility of unmeasured confounding.

In practice, the Love plot is strongest when paired with overlap checks, sample-size accounting, and a clear explanation of the propensity-score or matching specification.

## Further reading

For broader guidance on causal design with propensity scores, Stuart's review remains a strong conceptual reference. Austin gives a practical discussion of propensity-score implementation and diagnostics, including standardized differences and the role of balance assessment in applied work. For the preprocessing perspective on matching, Ho and colleagues provide the foundational `MatchIt` reference.

## References

- Stuart, Elizabeth A. (2010). "Matching Methods for Causal Inference: A Review and a Look Forward." *Statistical Science*, 25(1), 1--21. DOI: <https://doi.org/10.1214/09-STS313>.
- Austin, Peter C. (2009). "Balance Diagnostics for Comparing the Distribution of Baseline Covariates between Treatment Groups in Propensity-Score Matched Samples." *Statistics in Medicine*, 28(25), 3083--3107. DOI: <https://doi.org/10.1002/sim.3697>.
- LaLonde, Robert J. (1986). "Evaluating the Econometric Evaluations of Training Programs with Experimental Data." *The American Economic Review*, 76(4), 604--620. <https://www.jstor.org/stable/1806062>.
- Dehejia, Rajeev H.; Wahba, Sadek (1999). "Causal Effects in Nonexperimental Studies: Reevaluating the Evaluation of Training Programs." *Journal of the American Statistical Association*, 94(448), 1053--1062. DOI: <https://doi.org/10.1080/01621459.1999.10473858>.
- Ho, Daniel E.; Imai, Kosuke; King, Gary; Stuart, Elizabeth A. (2011). "MatchIt: Nonparametric Preprocessing for Parametric Causal Inference." *Journal of Statistical Software*, 42(8), 1--28. DOI: <https://doi.org/10.18637/jss.v042.i08>.
- Austin, Peter C. (2011). "An Introduction to Propensity Score Methods for Reducing the Effects of Confounding in Observational Studies." *Multivariate Behavioral Research*, 46(3), 399--424. DOI: <https://doi.org/10.1080/00273171.2011.568786>.
