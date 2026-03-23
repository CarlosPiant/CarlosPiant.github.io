---
title: "Calibration Belt Plot"
date: 2026-03-19
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a calibration belt plot for a binary risk-prediction model. The purpose of the figure is to show not only whether predicted probabilities line up with observed outcomes, but also where along the..."
excerpt: "Visualizing probability calibration with a confidence band rather than bins alone"
---
This chapter creates a calibration belt plot for a binary risk-prediction model. The purpose of the figure is to show not only whether predicted probabilities line up with observed outcomes, but also where along the risk range the model appears to be miscalibrated. A standard calibration plot often combines grouped observed-versus-predicted points with a smooth curve. A calibration belt goes one step further by placing a confidence band around the estimated calibration curve so the reader can see where the ideal 45-degree line falls inside or outside the plausible range of calibration functions.

This makes the figure especially useful in applied health research. A prediction model may be well calibrated on average yet still overpredict high-risk patients or underpredict low-risk patients. A single intercept or slope cannot show where that happens. A calibration belt can.

## What the visualization is showing

We will build a calibration belt plot for predicted probabilities from a binary-outcome model. The figure will show:

1. the ideal 45-degree line,
2. an estimated smooth calibration curve,
3. nested confidence belts around that curve,
4. optionally, grouped calibration points for reference.

When the calibration curve lies on the 45-degree line, the model is perfectly calibrated. When the belt excludes the 45-degree line over a range of predicted probabilities, that part of the risk range is where calibration problems are most evident.

## Step 1: Create a synthetic external-validation setting

To make the purpose of the figure clear, we will start with a synthetic example in which a logistic model is fit in a development sample and then applied to a shifted validation sample. The validation data are generated from a slightly different risk structure, so some miscalibration should appear.

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

n_dev <- 2500
n_val <- 2500

generate_risk_data <- function(n, intercept_shift = 0) {
 age10 <- rnorm(n, mean = 6.5, sd = 1.0)
 biomarker <- rnorm(n, mean = 0, sd = 1)
 comorbidity <- rpois(n, lambda = 1.5)
 smoker <- rbinom(n, size = 1, prob = 0.3)

 true_eta <- -1.2 + intercept_shift +
 0.35 * age10 +
 0.75 * biomarker +
 0.18 * comorbidity +
 0.40 * smoker +
 0.35 * biomarker * smoker -
 0.25 * biomarker^2

 event <- rbinom(n, size = 1, prob = plogis(true_eta))

 data.frame(
 age10,
 biomarker,
 comorbidity,
 smoker,
 event
 )
}

development_data <- generate_risk_data(n_dev, intercept_shift = 0)
validation_data <- generate_risk_data(n_val, intercept_shift = 0.25)

calibration_fit <- glm(
 event ~ age10 + biomarker + comorbidity + smoker,
 data = development_data,
 family = binomial
)

validation_data$predicted_risk <- predict(
 calibration_fit,
 newdata = validation_data,
 type = "response"
)

synthetic_summary <- data.frame(
 development_n = nrow(development_data),
 validation_n = nrow(validation_data),
 validation_event_rate = mean(validation_data$event),
 mean_predicted_risk = mean(validation_data$predicted_risk),
 brier_score = mean((validation_data$predicted_risk - validation_data$event)^2)
)

synthetic_summary[, c("validation_event_rate", "mean_predicted_risk", "brier_score")] <-
 round(synthetic_summary[, c("validation_event_rate", "mean_predicted_risk", "brier_score")], 3)

knitr::kable(
 synthetic_summary,
 caption = "Summary of the synthetic development and validation samples"
)
```

Table: Summary of the synthetic development and validation samples

| development_n| validation_n| validation_event_rate| mean_predicted_risk| brier_score|
|-------------:|------------:|---------------------:|-------------------:|-----------:|
| 2500| 2500| 0.768| 0.738| 0.151|

The development model is intentionally misspecified because it omits the interaction and nonlinear term used in the true data-generating process. The validation sample also has a shifted intercept, which introduces additional miscalibration.

## Step 2: Build a calibration-belt function

The calibration belt models the relationship between the logit of predicted probability and the logit of observed outcome probability with a polynomial logistic regression. The code below uses AIC to choose the polynomial degree from 1 to 3, then computes fitted calibration probabilities and nested confidence belts across a grid of predicted risks.

``` r
build_calibration_belt <- function(predicted_risk, observed_outcome, max_degree = 3) {
 clipped_risk <- pmin(pmax(predicted_risk, 1e-6), 1 - 1e-6)
 logit_risk <- qlogis(clipped_risk)

 fits <- lapply(seq_len(max_degree), function(degree) {
 glm(
 observed_outcome ~ poly(logit_risk, degree = degree, raw = TRUE),
 family = binomial
 )
 })

 aic_values <- sapply(fits, AIC)
 best_degree <- which.min(aic_values)
 best_fit <- fits[[best_degree]]

 grid <- data.frame(
 predicted_risk = seq(min(clipped_risk), max(clipped_risk), length.out = 250)
 )
 grid$logit_risk <- qlogis(grid$predicted_risk)

 predicted_link <- predict(best_fit, newdata = grid, type = "link", se.fit = TRUE)
 eta_hat <- as.numeric(predicted_link$fit)
 eta_se <- as.numeric(predicted_link$se.fit)

 z80 <- qnorm(0.90)
 z95 <- qnorm(0.975)

 grid$calibrated_risk <- plogis(eta_hat)
 grid$lower80 <- plogis(eta_hat - z80 * eta_se)
 grid$upper80 <- plogis(eta_hat + z80 * eta_se)
 grid$lower95 <- plogis(eta_hat - z95 * eta_se)
 grid$upper95 <- plogis(eta_hat + z95 * eta_se)
 grid$ideal <- grid$predicted_risk

 rank_id <- rank(clipped_risk, ties.method = "first")
 decile_breaks <- quantile(rank_id, probs = seq(0, 1, 0.1))
 decile_breaks <- unique(decile_breaks)

 decile <- cut(
 rank_id,
 breaks = decile_breaks,
 include.lowest = TRUE
 )

 grouped <- data.frame(
 decile = decile,
 predicted_risk = clipped_risk,
 observed_outcome = observed_outcome
 ) |>
 dplyr::group_by(decile) |>
 dplyr::summarise(
 predicted_risk = mean(predicted_risk),
 observed_outcome = mean(observed_outcome),
 count = dplyr::n,
.groups = "drop"
 )

 list(
 fit = best_fit,
 degree = best_degree,
 aic_values = aic_values,
 grid = grid,
 grouped = grouped
 )
}
```

This is a simplified pedagogic implementation rather than a full reproduction of the formal calibration-belt testing algorithm in the original papers. But it captures the main visual logic: an estimated calibration curve plus nested confidence belts that can be compared with the ideal line.

## Step 3: Draw the synthetic calibration belt plot

``` r
synthetic_belt <- build_calibration_belt(
 predicted_risk = validation_data$predicted_risk,
 observed_outcome = validation_data$event
)

synthetic_belt_table <- data.frame(
 selected_polynomial_degree = synthetic_belt$degree,
 aic_degree_1 = synthetic_belt$aic_values[1],
 aic_degree_2 = synthetic_belt$aic_values[2],
 aic_degree_3 = synthetic_belt$aic_values[3]
)

synthetic_belt_table[,] <- round(synthetic_belt_table, 3)

knitr::kable(
 synthetic_belt_table,
 caption = "Polynomial degree selection for the synthetic calibration belt"
)
```

Table: Polynomial degree selection for the synthetic calibration belt

| selected_polynomial_degree| aic_degree_1| aic_degree_2| aic_degree_3|
|--------------------------:|------------:|------------:|------------:|
| 2| 2347.565| 2323.227| 2324.408|

``` r
ggplot +
 geom_ribbon(
 data = synthetic_belt$grid,
 aes(x = predicted_risk, ymin = lower95, ymax = upper95),
 fill = "#cfe1f2",
 alpha = 0.8
 ) +
 geom_ribbon(
 data = synthetic_belt$grid,
 aes(x = predicted_risk, ymin = lower80, ymax = upper80),
 fill = "#7fb3d5",
 alpha = 0.75
 ) +
 geom_abline(
 intercept = 0,
 slope = 1,
 linetype = 2,
 color = "#8b5e34",
 linewidth = 0.8
 ) +
 geom_line(
 data = synthetic_belt$grid,
 aes(x = predicted_risk, y = calibrated_risk),
 color = "#1f4e79",
 linewidth = 1
 ) +
 geom_point(
 data = synthetic_belt$grouped,
 aes(x = predicted_risk, y = observed_outcome, size = count),
 color = "#2a9d8f",
 alpha = 0.8
 ) +
 labs(
 title = "Calibration belt plot for a synthetic external-validation sample",
 subtitle = "The inner and outer shaded regions show 80% and 95% calibration belts",
 x = "Predicted probability",
 y = "Observed event probability",
 size = "Bin size"
 ) +
 coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
 theme_minimal(base_size = 12)
```

![plot of chunk unnamed-chunk-4](/tutorials/rendered-assets/visualization-tools-calibration-belt-plot/unnamed-chunk-4-1.png)

This figure can be read in a way that grouped calibration points alone cannot. The curve shows the estimated calibration relationship, while the belt makes uncertainty visible across the whole probability range. Where the ideal line falls well outside the belt, miscalibration is most evident.

## Step 4: Create a real-world calibration belt from a public clinical prediction dataset

For a real-world example, we can use the public `Pima.tr` and `Pima.te` datasets distributed with `MASS`. These data come from the diabetes-prediction application described by Smith and coauthors. The model below is fit in the training sample and evaluated in the test sample, which gives a natural external-validation setting for a calibration belt.

This is a transparent partial application. The original Smith paper did not publish a calibration belt, and the calibration-belt methodology itself was proposed much later by Finazzi and colleagues and further refined by Nattino and colleagues. The figure below therefore combines a public clinical dataset with the later calibration-belt methodology rather than reproducing a single published plot verbatim.

``` r
data("Pima.tr", package = "MASS")
data("Pima.te", package = "MASS")

pima_fit <- glm(
 type ~ npreg + glu + bp + skin + bmi + ped + age,
 data = Pima.tr,
 family = binomial
)

pima_predicted <- predict(pima_fit, newdata = Pima.te, type = "response")
pima_observed <- as.integer(Pima.te$type == "Yes")

pima_belt <- build_calibration_belt(
 predicted_risk = pima_predicted,
 observed_outcome = pima_observed
)

pima_summary <- data.frame(
 sample_size = length(pima_observed),
 event_rate = mean(pima_observed),
 mean_predicted_risk = mean(pima_predicted),
 brier_score = mean((pima_predicted - pima_observed)^2),
 selected_polynomial_degree = pima_belt$degree
)

pima_summary[, c("event_rate", "mean_predicted_risk", "brier_score")] <-
 round(pima_summary[, c("event_rate", "mean_predicted_risk", "brier_score")], 3)

knitr::kable(
 pima_summary,
 caption = "Summary of the public diabetes prediction sample used for the calibration belt"
)
```

Table: Summary of the public diabetes prediction sample used for the calibration belt

| sample_size| event_rate| mean_predicted_risk| brier_score| selected_polynomial_degree|
|-----------:|----------:|-------------------:|-----------:|--------------------------:|
| 332| 0.328| 0.337| 0.139| 2|

``` r
ggplot +
 geom_ribbon(
 data = pima_belt$grid,
 aes(x = predicted_risk, ymin = lower95, ymax = upper95),
 fill = "#e6eef5",
 alpha = 0.85
 ) +
 geom_ribbon(
 data = pima_belt$grid,
 aes(x = predicted_risk, ymin = lower80, ymax = upper80),
 fill = "#9ecae1",
 alpha = 0.8
 ) +
 geom_abline(
 intercept = 0,
 slope = 1,
 linetype = 2,
 color = "#8b5e34",
 linewidth = 0.8
 ) +
 geom_line(
 data = pima_belt$grid,
 aes(x = predicted_risk, y = calibrated_risk),
 color = "#264653",
 linewidth = 1
 ) +
 geom_point(
 data = pima_belt$grouped,
 aes(x = predicted_risk, y = observed_outcome, size = count),
 color = "#2a9d8f",
 alpha = 0.8
 ) +
 labs(
 title = "Calibration belt plot for diabetes risk predictions",
 subtitle = "Public Pima test data with nested 80% and 95% calibration belts",
 x = "Predicted probability",
 y = "Observed event probability",
 size = "Bin size"
 ) +
 coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
 theme_minimal(base_size = 12)
```

![plot of chunk unnamed-chunk-6](/tutorials/rendered-assets/visualization-tools-calibration-belt-plot/unnamed-chunk-6-1.png)

This real-world example highlights the added value of the belt. The grouped points are still useful, but the belt clarifies whether apparent deviations from perfect calibration are large relative to sampling uncertainty and where in the risk range those deviations are concentrated.

## How to read the figure carefully

A calibration belt should not be read as a mechanical pass-fail device. The width of the belt depends on sample size and information density across the risk range. Belts naturally widen in sparse high-risk or low-risk regions, which means the same apparent deviation from the ideal line can be more consequential in one part of the graph than another.

The figure is also sensitive to how the calibration curve is modeled. The original methodology uses a polynomial relation on the logit scale and a formal testing framework to choose its complexity. The simplified implementation in this chapter uses AIC-based degree selection for teaching and reproducibility. That is useful pedagogically, but it is not a drop-in replacement for every formal calibration-belt procedure used in applied validation studies.

Finally, a calibration belt complements rather than replaces other calibration summaries. Intercept, slope, Brier score, and decision-relevant performance still matter.

## Further reading

Finazzi and colleagues introduced the calibration belt as a confidence-band approach to calibration assessment for dichotomous outcomes. Nattino and colleagues refined the associated testing framework and clarified the role of polynomial degree selection. Van Calster and colleagues provide a broader modern discussion of why calibration deserves more attention in prediction research.

## References

- Finazzi, Stefano; Poole, Daniele; Luciani, Davide; Cogo, Paola E.; Bertolini, Guido (2011). "Calibration Belt for Quality-of-Care Assessment Based on Dichotomous Outcomes." *PLOS ONE*, 6(2), e16110. DOI: <https://doi.org/10.1371/journal.pone.0016110>.
- Nattino, Giovanni; Finazzi, Stefano; Bertolini, Guido (2014). "A New Calibration Test and a Reappraisal of the Calibration Belt for the Assessment of Prediction Models Based on Dichotomous Outcomes." *Statistics in Medicine*, 33(14), 2390--2407. DOI: <https://doi.org/10.1002/sim.6100>.
- Smith, J. W.; Everhart, J. E.; Dickson, W. C.; Knowler, W. C.; Johannes, R. S. (1988). "Using the ADAP Learning Algorithm to Forecast the Onset of Diabetes Mellitus." *Proceedings of the Symposium on Computer Applications in Medical Care*, 261--265.
- Van Calster, Ben; McLernon, David J.; van Smeden, Maarten; Wynants, Laure; Steyerberg, Ewout W. (2019). "Calibration: The Achilles Heel of Predictive Analytics." *BMC Medicine*, 17(1), 230. DOI: <https://doi.org/10.1186/s12916-019-1466-7>.
