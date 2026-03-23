---
title: "Forest Plot"
date: 2026-03-13
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a forest plot and shows how to present point estimates with confidence intervals in a way that is visually compact and statistically honest. Forest plots are one of the most common reporting..."
excerpt: "Building a clear effect-estimate figure for subgroup and meta-analytic results"
---
This chapter creates a forest plot and shows how to present point estimates with confidence intervals in a way that is visually compact and statistically honest. Forest plots are one of the most common reporting figures in clinical trials, subgroup analyses, and meta-analyses because they let readers compare many effect estimates at once while keeping uncertainty visible.

The figure is especially useful in health research because it solves a practical communication problem. Tables of odds ratios, hazard ratios, or mean differences are hard to scan when there are many subgroups or studies. A forest plot lets the reader see the direction, magnitude, and precision of each estimate immediately.

## What the visualization is showing

We will build a forest plot for effect estimates expressed as ratios. Each row will show:

1. the subgroup or study label,
2. a point estimate,
3. a confidence interval,
4. a vertical line marking the null value.

When the estimate is a hazard ratio or odds ratio, the null value is 1. Confidence intervals entirely to the left of 1 suggest lower risk under the intervention. Intervals that cross 1 indicate that sampling uncertainty still includes no difference.

## Step 1: Create a subgroup-results table

We will begin with a synthetic subgroup analysis for a hospital discharge intervention. The values are made up, but they mimic the structure of a typical trial appendix.

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

synthetic_forest <- data.frame(
 subgroup = c(
 "Overall",
 "Age < 65",
 "Age >= 65",
 "Women",
 "Men",
 "No prior admission",
 "Prior admission"
 ),
 estimate = c(0.82, 0.78, 0.87, 0.91, 0.74, 0.80, 0.86),
 conf_low = c(0.72, 0.63, 0.71, 0.73, 0.60, 0.66, 0.70),
 conf_high = c(0.93, 0.97, 1.07, 1.14, 0.92, 0.98, 1.05),
 weight = c(1.00, 0.68, 0.59, 0.54, 0.63, 0.71, 0.57),
 row_type = c("Overall", rep("Subgroup", 6)),
 row.names = NULL
)

synthetic_forest$estimate_label <- sprintf(
 "%.2f (%.2f to %.2f)",
 synthetic_forest$estimate,
 synthetic_forest$conf_low,
 synthetic_forest$conf_high
)

synthetic_table <- synthetic_forest |>
 dplyr::transmute(
 subgroup,
 hazard_ratio = round(estimate, 2),
 lower_95_ci = round(conf_low, 2),
 upper_95_ci = round(conf_high, 2)
 )

knitr::kable(
 synthetic_table,
 caption = "Synthetic subgroup estimates that will be plotted in the forest plot"
)
```

Table: Synthetic subgroup estimates that will be plotted in the forest plot

|subgroup | hazard_ratio| lower_95_ci| upper_95_ci|
|:------------------|------------:|-----------:|-----------:|
|Overall | 0.82| 0.72| 0.93|
|Age < 65 | 0.78| 0.63| 0.97|
|Age >= 65 | 0.87| 0.71| 1.07|
|Women | 0.91| 0.73| 1.14|
|Men | 0.74| 0.60| 0.92|
|No prior admission | 0.80| 0.66| 0.98|
|Prior admission | 0.86| 0.70| 1.05|

The table is the raw material for the figure. Each row is an effect estimate with its confidence interval. The only extra variables we add are a relative weight used to size the plotting symbols and a row type that tells the plot which estimate should be shown as the overall summary.

## Step 2: Build a reusable forest-plot function

The plotting function below is designed for ratio measures such as odds ratios or hazard ratios, so it uses a log-scaled x-axis. That makes confidence intervals visually symmetric around the point estimate on the multiplicative scale.

``` r
build_forest_plot <- function(data, title, subtitle) {
 plot_data <- data |>
 dplyr::mutate(
 subgroup = factor(subgroup, levels = rev(subgroup)),
 point_size = 2.8 + 3.8 * weight,
 label_x = 2.55
 )

 ggplot(plot_data, aes(y = subgroup, x = estimate)) +
 geom_vline(xintercept = 1, color = "#7f7f7f", linetype = "dashed", linewidth = 0.6) +
 geom_segment(
 aes(x = conf_low, xend = conf_high, yend = subgroup),
 linewidth = 0.9,
 color = "#365c8d"
 ) +
 geom_point(
 data = subset(plot_data, row_type == "Subgroup"),
 aes(size = point_size),
 shape = 15,
 color = "#365c8d",
 show.legend = FALSE
 ) +
 geom_point(
 data = subset(plot_data, row_type == "Overall"),
 aes(size = point_size),
 shape = 18,
 color = "#8c2d04",
 show.legend = FALSE
 ) +
 geom_text(
 aes(x = label_x, label = estimate_label),
 hjust = 0,
 size = 3.5,
 color = "#1f1f1f"
 ) +
 scale_x_log10(
 breaks = c(0.4, 0.5, 0.75, 1, 1.5, 2),
 labels = c("0.40", "0.50", "0.75", "1.00", "1.50", "2.00"),
 limits = c(0.35, 2.85)
 ) +
 scale_size_identity +
 coord_cartesian(clip = "off") +
 labs(
 title = title,
 subtitle = subtitle,
 x = "Hazard ratio",
 y = NULL
 ) +
 theme_minimal(base_size = 12) +
 theme(
 panel.grid.major.y = element_blank,
 panel.grid.minor = element_blank,
 plot.margin = margin(10, 90, 10, 10)
 )
}
```

This function deliberately keeps the design simple:

- a dashed vertical line marks the null effect,
- horizontal segments show 95% confidence intervals,
- squares show subgroup estimates,
- a diamond marks the overall estimate,
- the formatted estimate text is printed to the right.

That is the standard grammar of a forest plot. Readers familiar with trials and meta-analyses will recognize it immediately.

## Step 3: Draw the synthetic forest plot

``` r
synthetic_forest_plot <- build_forest_plot(
 synthetic_forest,
 title = "Forest plot for a synthetic readmission subgroup analysis",
 subtitle = "Squares show subgroup estimates; the diamond shows the overall hazard ratio"
)

synthetic_forest_plot
```

![plot of chunk unnamed-chunk-3](/tutorials/rendered-assets/visualization-tools-forest-plot/unnamed-chunk-3-1.png)

This figure works because it lets the reader answer three questions quickly:

1. Are most estimates on the same side of the null?
2. Which subgroups are imprecise?
3. Does the overall effect look consistent with the subgroup pattern?

The plot should not be used to claim subgroup heterogeneity just because some intervals cross 1 and others do not. It is a visual summary, not a formal interaction test.

## Step 4: Build a real-world forest plot from a public trial dataset

To move from a synthetic example to a real one, we can use the public `colon` dataset distributed with the `survival` package. These data come from the adjuvant colon cancer trials reported by Laurie and colleagues and Moertel and colleagues.

The original trial publications did not include exactly this modern subgroup forest plot. The figure below is therefore a transparent partial replication: it uses the public paper-linked dataset to estimate subgroup treatment hazard ratios for overall survival and then presents them in forest-plot form.

``` r
library(survival)

colon_os <- survival::colon |>
 dplyr::filter(etype == 2, rx %in% c("Obs", "Lev+5FU")) |>
 dplyr::mutate(
 treatment = ifelse(rx == "Lev+5FU", 1, 0)
 )

extract_cox_row <- function(data, label, row_type = "Subgroup") {
 fit <- survival::coxph(survival::Surv(time, status) ~ treatment, data = data)
 fit_summary <- summary(fit)

 data.frame(
 subgroup = label,
 n = nrow(data),
 events = sum(data$status),
 estimate = fit_summary$coefficients[, "exp(coef)"][1],
 conf_low = fit_summary$conf.int[, "lower.95"][1],
 conf_high = fit_summary$conf.int[, "upper.95"][1],
 weight = min(1, sqrt(nrow(data) / nrow(colon_os))),
 row_type = row_type,
 row.names = NULL
 )
}

colon_forest <- dplyr::bind_rows(
 extract_cox_row(colon_os, "Overall", row_type = "Overall"),
 extract_cox_row(dplyr::filter(colon_os, age < 65), "Age < 65"),
 extract_cox_row(dplyr::filter(colon_os, age >= 65), "Age >= 65"),
 extract_cox_row(dplyr::filter(colon_os, sex == 0), "Female"),
 extract_cox_row(dplyr::filter(colon_os, sex == 1), "Male"),
 extract_cox_row(dplyr::filter(colon_os, obstruct == 0), "No obstruction"),
 extract_cox_row(dplyr::filter(colon_os, obstruct == 1), "Obstruction"),
 extract_cox_row(dplyr::filter(colon_os, adhere == 1), "Adherent"),
 extract_cox_row(dplyr::filter(colon_os, adhere == 0), "Non-adherent")
)

colon_forest$estimate_label <- sprintf(
 "%.2f (%.2f to %.2f)",
 colon_forest$estimate,
 colon_forest$conf_low,
 colon_forest$conf_high
)

colon_table <- colon_forest |>
 dplyr::transmute(
 subgroup,
 sample_size = n,
 events,
 hazard_ratio = round(estimate, 2),
 lower_95_ci = round(conf_low, 2),
 upper_95_ci = round(conf_high, 2)
 )

knitr::kable(
 colon_table,
 caption = "Subgroup hazard ratios estimated from the public colon cancer trial dataset"
)
```

Table: Subgroup hazard ratios estimated from the public colon cancer trial dataset

|subgroup | sample_size| events| hazard_ratio| lower_95_ci| upper_95_ci|
|:--------------|-----------:|------:|------------:|-----------:|-----------:|
|Overall | 619| 291| 0.69| 0.55| 0.87|
|Age < 65 | 376| 173| 0.70| 0.52| 0.95|
|Age >= 65 | 243| 118| 0.66| 0.46| 0.95|
|Female | 312| 152| 0.86| 0.63| 1.19|
|Male | 307| 139| 0.52| 0.37| 0.74|
|No obstruction | 502| 231| 0.69| 0.53| 0.90|
|Obstruction | 117| 60| 0.71| 0.42| 1.19|
|Adherent | 86| 49| 0.76| 0.43| 1.35|
|Non-adherent | 533| 242| 0.68| 0.53| 0.88|

This table now contains real model outputs rather than hand-entered values. The next step is simply to hand that results table to the same plotting function.

``` r
colon_forest_plot <- build_forest_plot(
 colon_forest,
 title = "Forest plot of subgroup treatment effects in the public colon trial data",
 subtitle = "Hazard ratios for Levamisole + 5FU versus observation for overall survival"
)

colon_forest_plot
```

![plot of chunk unnamed-chunk-5](/tutorials/rendered-assets/visualization-tools-forest-plot/unnamed-chunk-5-1.png)

The real-world figure follows the same design rules as the synthetic one, but now the rows come from a fitted Cox model in each subgroup. That is a common workflow in applied papers: estimate the model first, then construct a clean forest plot for reporting.

## How to read the figure carefully

Forest plots are powerful precisely because they compress a lot of information. That also makes them easy to overinterpret.

The most common mistake is to read every apparent subgroup difference as real effect modification. Overlapping and non-overlapping intervals can be suggestive, but the correct statistical question is usually whether a treatment-by-subgroup interaction is supported.

A second issue is scale. Ratio measures should usually be plotted on a log scale so that equal distances correspond to equal multiplicative changes.

A third issue is visual hierarchy. The forest plot should make the main signal easy to see without exaggerating certainty. Heavy colors, overly large symbols, or crowded labels can turn a useful figure into a misleading one.

## Further reading

Lewis and Clarke give one of the clearest short explanations of what forest plots are trying to accomplish and why they became so central in evidence synthesis. The colon cancer trial papers by Laurie and colleagues and Moertel and colleagues provide a practical clinical context for subgroup reporting and effect-estimate visualization.

## References

- Lewis, Steff; Clarke, Mike (2001). "Forest Plots: Trying to See the Wood and the Trees." *BMJ*, 322(7300), 1479--1480. DOI: <https://doi.org/10.1136/bmj.322.7300.1479>.
- Laurie, John A.; Moertel, Charles G.; Fleming, Thomas R.; Wieand, H. S.; Leigh, James E.; Rubin, Joseph; McCormack, G. W.; Gerstner, J. B.; Krook, J. E.; Mailliard, James A. (1989). "Surgical Adjuvant Therapy of Large-Bowel Carcinoma: An Evaluation of Levamisole and the Combination of Levamisole and Fluorouracil." *Journal of Clinical Oncology*, 7(10), 1447--1456. DOI: <https://doi.org/10.1200/JCO.1989.7.10.1447>.
- Moertel, Charles G.; Fleming, Thomas R.; Macdonald, John S.; Haller, Daniel G.; Laurie, John A.; Goodman, Phyllis J.; Ungerleider, James S.; Emerson, William A.; Tormey, Douglas C.; Glick, John H.; Veeder, Michael H.; Mailliard, James A. (1990). "Levamisole and Fluorouracil for Adjuvant Therapy of Resected Colon Carcinoma." *New England Journal of Medicine*, 322(6), 352--358. DOI: <https://doi.org/10.1056/NEJM199002083220602>.
