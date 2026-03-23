---
title: "ROC and Precision-Recall Curves"
date: 2026-03-09
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds two closely related prediction-performance figures: the ROC curve and the precision-recall curve. Both are designed to show how a binary prediction model behaves as the classification threshold..."
excerpt: "Visualizing discrimination for binary prediction models"
---
This chapter builds two closely related prediction-performance figures: the ROC curve and the precision-recall curve. Both are designed to show how a binary prediction model behaves as the classification threshold changes, but they emphasize different aspects of performance. The ROC curve focuses on sensitivity and false-positive tradeoffs, while the precision-recall curve focuses on the relationship between recall and positive predictive value. In applied health prediction, both are useful, but they answer slightly different questions. The example again uses the Pima diabetes data from Smith and coauthors.

The main idea is simple. A model that outputs probabilities can be turned into many different classifiers depending on where the threshold is set. ROC and precision-recall plots summarize that whole threshold range instead of committing to a single cutpoint.

## What the visualizations are showing

The ROC curve plots true positive rate against false positive rate. The precision-recall curve plots precision against recall. Both curves are built from the same predicted probabilities, but they emphasize different failure modes. The precision-recall curve often becomes more informative when events are relatively uncommon.

## Step 1: Fit the prediction model and create test-set probabilities

```r
data("Pima.tr", package = "MASS")
data("Pima.te", package = "MASS")

roc_fit <- glm(
 type ~ npreg + glu + bp + skin + bmi + ped + age,
 data = Pima.tr,
 family = binomial
)

predicted_risk <- predict(roc_fit, newdata = Pima.te, type = "response")
observed_outcome <- as.integer(Pima.te$type == "Yes")

performance_data <- data.frame(
 predicted_risk = predicted_risk,
 observed_outcome = observed_outcome
)
```

## Step 2: Compute performance across thresholds

```r
thresholds <- sort(unique(c(1, performance_data$predicted_risk, 0)), decreasing = TRUE)

curve_points <- lapply(thresholds, function(threshold) {
 predicted_class <- as.integer(performance_data$predicted_risk >= threshold)

 tp <- sum(predicted_class == 1 & performance_data$observed_outcome == 1)
 fp <- sum(predicted_class == 1 & performance_data$observed_outcome == 0)
 tn <- sum(predicted_class == 0 & performance_data$observed_outcome == 0)
 fn <- sum(predicted_class == 0 & performance_data$observed_outcome == 1)

 tpr <- ifelse(tp + fn == 0, 0, tp / (tp + fn))
 fpr <- ifelse(fp + tn == 0, 0, fp / (fp + tn))
 precision <- ifelse(tp + fp == 0, 1, tp / (tp + fp))
 recall <- tpr

 data.frame(
 threshold = threshold,
 tpr = tpr,
 fpr = fpr,
 precision = precision,
 recall = recall
 )
})

curve_data <- do.call(rbind, curve_points)

roc_data <- curve_data[order(curve_data$fpr, curve_data$tpr), ]
pr_data <- curve_data[order(curve_data$recall, curve_data$precision), ]

roc_auc <- sum(diff(roc_data$fpr) * (head(roc_data$tpr, -1) + tail(roc_data$tpr, -1)) / 2)

pr_data_unique <- pr_data[!duplicated(pr_data$recall), ]
average_precision <- sum(diff(pr_data_unique$recall) * tail(pr_data_unique$precision, -1))

summary_table <- data.frame(
 metric = c("Event prevalence", "ROC AUC", "Average precision"),
 value = c(
 mean(performance_data$observed_outcome),
 roc_auc,
 average_precision
 )
)

summary_table$value <- round(summary_table$value, 3)

knitr::kable(
 summary_table,
 caption = "Summary performance metrics for the diabetes prediction model"
)
```

The AUC summarizes the ROC curve in one number, while average precision summarizes the precision-recall curve. Neither replaces the plot, but both are useful anchors.

## Step 3: Build the ROC curve

```r
ggplot2::ggplot(roc_data, ggplot2::aes(x = fpr, y = tpr)) +
 ggplot2::geom_line(color = "#3d5a80", linewidth = 1) +
 ggplot2::geom_abline(
 intercept = 0,
 slope = 1,
 linetype = 2,
 color = "#8b5e34",
 linewidth = 0.8
 ) +
 ggplot2::labs(
 title = "ROC curve for diabetes prediction",
 subtitle = sprintf("Area under the curve = %.3f", roc_auc),
 x = "False positive rate",
 y = "True positive rate"
 ) +
 ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
 ggplot2::theme_minimal(base_size = 12)
```

The diagonal line represents random guessing. The further the curve bows toward the upper-left corner, the better the model discriminates between cases and non-cases.

## Step 4: Build the precision-recall curve

```r
baseline_precision <- mean(performance_data$observed_outcome)

ggplot2::ggplot(pr_data_unique, ggplot2::aes(x = recall, y = precision)) +
 ggplot2::geom_line(color = "#bc6c25", linewidth = 1) +
 ggplot2::geom_hline(
 yintercept = baseline_precision,
 linetype = 2,
 color = "#8b5e34",
 linewidth = 0.8
 ) +
 ggplot2::labs(
 title = "Precision-recall curve for diabetes prediction",
 subtitle = sprintf("Average precision = %.3f; dashed line marks event prevalence", average_precision),
 x = "Recall",
 y = "Precision"
 ) +
 ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
 ggplot2::theme_minimal(base_size = 12)
```

The dashed horizontal line marks the event prevalence. A good precision-recall curve should stay well above that baseline across a meaningful range of recall values.

## Step 5: Compare threshold-specific operating points

Sometimes readers also need a few concrete threshold examples rather than a full curve alone.

```r
selected_thresholds <- c(0.20, 0.40, 0.60)

operating_points <- do.call(
 rbind,
 lapply(selected_thresholds, function(threshold) {
 predicted_class <- as.integer(performance_data$predicted_risk >= threshold)

 tp <- sum(predicted_class == 1 & performance_data$observed_outcome == 1)
 fp <- sum(predicted_class == 1 & performance_data$observed_outcome == 0)
 tn <- sum(predicted_class == 0 & performance_data$observed_outcome == 0)
 fn <- sum(predicted_class == 0 & performance_data$observed_outcome == 1)

 data.frame(
 threshold = threshold,
 sensitivity = tp / (tp + fn),
 specificity = tn / (tn + fp),
 precision = ifelse(tp + fp == 0, 1, tp / (tp + fp))
 )
 })
)

operating_points[, c("sensitivity", "specificity", "precision")] <-
 round(operating_points[, c("sensitivity", "specificity", "precision")], 3)

knitr::kable(
 operating_points,
 caption = "Selected threshold-specific operating characteristics"
)
```

## How to read the figures carefully

The ROC curve is threshold-agnostic and prevalence-invariant, which makes it useful for general discrimination summaries. But that same property can make it less sensitive to the practical consequences of false positives in low-prevalence settings. That is one reason precision-recall curves are often a better companion when the positive class is relatively rare or when precision matters directly.

Neither curve says whether the predicted probabilities are well calibrated. A model can discriminate well and still produce misleading absolute risks. That is why ROC and precision-recall plots work best when read alongside a calibration plot rather than instead of one.

## Further reading

Fawcett gives a clear introduction to the logic and interpretation of ROC analysis. Saito and Rehmsmeier explain why precision-recall curves deserve more attention in imbalanced settings. Smith and coauthors provide the original applied context for the diabetes dataset used in this example.
