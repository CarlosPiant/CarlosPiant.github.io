---
title: "Cost-Effectiveness Planes"
date: 2026-03-09
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a cost-effectiveness plane from a trial-style economic evaluation and shows how to visualize uncertainty in incremental costs and incremental effects at the same time. The figure is one of the..."
excerpt: "Visualizing uncertainty in incremental costs and incremental effects"
---
This chapter creates a cost-effectiveness plane from a trial-style economic evaluation and shows how to visualize uncertainty in incremental costs and incremental effects at the same time. The figure is one of the central reporting tools in health economics because it displays not only the average result, but the direction and spread of the uncertainty around that result. The example here uses synthetic patient-level cost and QALY data, but the plotting logic follows the uncertainty framework widely used in applied economic evaluation.

The cost-effectiveness plane places incremental effect on the x-axis and incremental cost on the y-axis. Each point represents one bootstrap replicate. The four quadrants then summarize the practical meaning of the uncertainty: better and more costly, better and less costly, worse and less costly, or worse and more costly.

## What the visualization is showing

We will simulate two arms of a simple comparative study: usual care and an intervention. For each arm, we will generate one-year costs and one-year QALYs at the patient level. We will then bootstrap the mean incremental cost and mean incremental QALY many times and place those bootstrap replicates on the cost-effectiveness plane.

## Step 1: Create a trial-style dataset

``` r
set.seed(2026)

n_control <- 250
n_intervention <- 250

control_cost <- rlnorm(n_control, meanlog = log(11500), sdlog = 0.38)
intervention_cost <- rlnorm(n_intervention, meanlog = log(12350), sdlog = 0.36)

control_qaly <- pmin(pmax(rnorm(n_control, mean = 0.66, sd = 0.12), 0), 1)
intervention_qaly <- pmin(pmax(rnorm(n_intervention, mean = 0.71, sd = 0.11), 0), 1)

ce_trial_data <- rbind(
 data.frame(arm = "Usual care", cost = control_cost, qaly = control_qaly),
 data.frame(arm = "Intervention", cost = intervention_cost, qaly = intervention_qaly)
)

trial_summary <- aggregate(
 cbind(cost, qaly) ~ arm,
 data = ce_trial_data,
 FUN = mean
)

trial_summary[, c("cost", "qaly")] <- round(trial_summary[, c("cost", "qaly")], 3)

knitr::kable(
 trial_summary,
 caption = "Mean one-year costs and QALYs in the synthetic trial dataset"
)
```

Table: Mean one-year costs and QALYs in the synthetic trial dataset

|arm | cost| qaly|
|:------------|--------:|-----:|
|Intervention | 13494.76| 0.706|
|Usual care | 12469.19| 0.661|

The example is synthetic, but it reproduces the structure of a standard trial-based economic evaluation: patient-level outcomes in two study arms and uncertainty around the incremental comparison.

## Step 2: Bootstrap incremental cost and effect

``` r
set.seed(2026)

B <- 1000

bootstrap_results <- do.call(
 rbind,
 lapply(seq_len(B), function(i) {
 sample_control <- control_cost[sample.int(n_control, n_control, replace = TRUE)]
 sample_intervention <- intervention_cost[sample.int(n_intervention, n_intervention, replace = TRUE)]
 qaly_control <- control_qaly[sample.int(n_control, n_control, replace = TRUE)]
 qaly_intervention <- intervention_qaly[sample.int(n_intervention, n_intervention, replace = TRUE)]

 data.frame(
 incremental_cost = mean(sample_intervention) - mean(sample_control),
 incremental_qaly = mean(qaly_intervention) - mean(qaly_control)
 )
 })
)

mean_incremental_cost <- mean(bootstrap_results$incremental_cost)
mean_incremental_qaly <- mean(bootstrap_results$incremental_qaly)

summary_table <- data.frame(
 quantity = c("Mean incremental cost", "Mean incremental QALY", "ICER"),
 value = c(
 mean_incremental_cost,
 mean_incremental_qaly,
 mean_incremental_cost / mean_incremental_qaly
 )
)

summary_table$value <- round(summary_table$value, 3)

knitr::kable(
 summary_table,
 caption = "Summary of the bootstrap incremental results"
)
```

Table: Summary of the bootstrap incremental results

|quantity | value|
|:---------------------|---------:|
|Mean incremental cost | 1029.326|
|Mean incremental QALY | 0.045|
|ICER | 22807.750|

## Step 3: Build the cost-effectiveness plane

``` r
wtp <- 50000

effect_limits <- range(bootstrap_results$incremental_qaly)
effect_grid <- seq(effect_limits[1] - 0.01, effect_limits[2] + 0.01, length.out = 200)

wtp_line <- data.frame(
 incremental_qaly = effect_grid,
 incremental_cost = wtp * effect_grid
)

ggplot2::ggplot(
 bootstrap_results,
 ggplot2::aes(x = incremental_qaly, y = incremental_cost)
) +
 ggplot2::geom_hline(yintercept = 0, color = "#5c5c5c", linewidth = 0.6) +
 ggplot2::geom_vline(xintercept = 0, color = "#5c5c5c", linewidth = 0.6) +
 ggplot2::geom_point(color = "#457b9d", alpha = 0.35, size = 1.5) +
 ggplot2::geom_line(
 data = wtp_line,
 ggplot2::aes(x = incremental_qaly, y = incremental_cost),
 inherit.aes = FALSE,
 color = "#d62828",
 linewidth = 0.9
 ) +
 ggplot2::geom_point(
 data = data.frame(
 incremental_qaly = mean_incremental_qaly,
 incremental_cost = mean_incremental_cost
 ),
 ggplot2::aes(x = incremental_qaly, y = incremental_cost),
 inherit.aes = FALSE,
 color = "#1d3557",
 size = 3
 ) +
 ggplot2::annotate("text", x = 0.08, y = max(bootstrap_results$incremental_cost), label = "More effective,\nmore costly", hjust = 1, size = 3.6) +
 ggplot2::annotate("text", x = 0.08, y = min(bootstrap_results$incremental_cost), label = "More effective,\nless costly", hjust = 1, vjust = 0, size = 3.6) +
 ggplot2::annotate("text", x = min(bootstrap_results$incremental_qaly), y = max(bootstrap_results$incremental_cost), label = "Less effective,\nmore costly", hjust = 0, size = 3.6) +
 ggplot2::annotate("text", x = min(bootstrap_results$incremental_qaly), y = min(bootstrap_results$incremental_cost), label = "Less effective,\nless costly", hjust = 0, vjust = 0, size = 3.6) +
 ggplot2::labs(
 title = "Cost-effectiveness plane for the synthetic economic evaluation",
 subtitle = "Each point is a bootstrap replicate; the red line shows a willingness-to-pay threshold of $50,000 per QALY",
 x = "Incremental QALYs",
 y = "Incremental costs ($)"
 ) +
 ggplot2::theme_minimal(base_size = 12)
```

![plot of chunk unnamed-chunk-3](/tutorials/rendered-assets/visualization-tools-cost-effectiveness-planes/unnamed-chunk-3-1.png)

This figure works because it compresses a large amount of uncertainty into one visual frame. The cloud of points shows variability. The quadrant location shows whether the intervention tends to improve outcomes, reduce costs, or both. The willingness-to-pay line adds a decision threshold.

## Step 4: Summarize the quadrant probabilities

``` r
quadrant_table <- data.frame(
 quadrant = c(
 "More effective and more costly",
 "More effective and less costly",
 "Less effective and more costly",
 "Less effective and less costly"
 ),
 probability = c(
 mean(bootstrap_results$incremental_qaly > 0 & bootstrap_results$incremental_cost > 0),
 mean(bootstrap_results$incremental_qaly > 0 & bootstrap_results$incremental_cost < 0),
 mean(bootstrap_results$incremental_qaly < 0 & bootstrap_results$incremental_cost > 0),
 mean(bootstrap_results$incremental_qaly < 0 & bootstrap_results$incremental_cost < 0)
 )
)

quadrant_table$probability <- round(quadrant_table$probability, 3)

knitr::kable(
 quadrant_table,
 caption = "Probability mass in each quadrant of the cost-effectiveness plane"
)
```

Table: Probability mass in each quadrant of the cost-effectiveness plane

|quadrant | probability|
|:------------------------------|-----------:|
|More effective and more costly | 0.988|
|More effective and less costly | 0.012|
|Less effective and more costly | 0.000|
|Less effective and less costly | 0.000|

## Step 5: Add simple cost-effectiveness probabilities at common thresholds

``` r
thresholds <- c(20000, 50000, 100000)

ce_probability_table <- data.frame(
 threshold = thresholds,
 probability_cost_effective = sapply(
 thresholds,
 function(lambda) {
 mean(lambda * bootstrap_results$incremental_qaly - bootstrap_results$incremental_cost > 0)
 }
 )
)

ce_probability_table$probability_cost_effective <-
 round(ce_probability_table$probability_cost_effective, 3)

knitr::kable(
 ce_probability_table,
 caption = "Probability the intervention is cost-effective at selected willingness-to-pay thresholds"
)
```

Table: Probability the intervention is cost-effective at selected willingness-to-pay thresholds

| threshold| probability_cost_effective|
|---------:|--------------------------:|
| 2e+04| 0.402|
| 5e+04| 0.967|
| 1e+05| 1.000|

## How to read the figure carefully

The cost-effectiveness plane is a visualization of uncertainty, not a decision rule by itself. A cloud centered in the northeast quadrant means the intervention tends to improve outcomes but also raises costs. Whether that is acceptable depends on the decision maker's willingness to pay for additional health gain.

The interpretation also depends on the outcome scale. Here the x-axis is QALYs, which makes the willingness-to-pay line easy to interpret. In other applications the effect scale could be cases averted, life-years gained, or some other endpoint, and the decision threshold would need to match that scale.

## Further reading

Fenwick, Claxton, and Sculpher provide one of the clearest discussions of how uncertainty should be represented in cost-effectiveness analysis and why visual tools such as the cost-effectiveness plane matter. A natural next step after this chapter is to extend the same bootstrap results into a cost-effectiveness acceptability curve.

## References

- Fenwick, Elisabeth; Claxton, Karl; Sculpher, Mark (2001). "Representing Uncertainty: The Role of Cost-Effectiveness Acceptability Curves." *Health Economics*, 10(8), 779--787. DOI: <https://doi.org/10.1002/hec.635>.
