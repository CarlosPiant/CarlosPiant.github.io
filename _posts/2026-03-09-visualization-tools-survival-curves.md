---
title: "Survival Curves"
date: 2026-03-09
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a Kaplan-Meier survival plot for a clinical time-to-event dataset and shows how to turn raw follow-up times into an interpretable curve. The figure is designed to answer a simple but important..."
excerpt: "Building Kaplan-Meier plots for time-to-event outcomes"
---
This chapter builds a Kaplan-Meier survival plot for a clinical time-to-event dataset and shows how to turn raw follow-up times into an interpretable curve. The figure is designed to answer a simple but important question: how quickly does an event accumulate over time, and how does that pattern differ across groups? In health economics, epidemiology, and outcomes research, survival curves are one of the most direct ways to display prognosis, treatment durability, readmission-free survival, or mortality. The example here uses the `lung` dataset archived in the `survival` package and is inspired by the core survival-modeling tradition established by Kaplan, Meier, and Cox;.

The visualization we will build is a pair of Kaplan-Meier curves comparing readout over time across two groups in the study sample. The step shape matters. It reminds the reader that survival does not decline continuously in the observed data. It drops when events occur and stays flat between events.

## What the visualization is showing

The `lung` dataset contains survival follow-up information for patients in a North Central Cancer Treatment Group lung-cancer study. We will use:

`time` as follow-up time in days, `status` as the event indicator, and `sex` as the grouping variable. In this dataset, $status = 2$ means the event occurred and $status = 1$ means the observation is censored. The Kaplan-Meier curve will show the estimated probability of remaining event-free over time.

## Step 1: Prepare the data

```r
lung_data <- survival::lung[, c("time", "status", "sex")]
lung_data <- na.omit(lung_data)

lung_data$event <- as.integer(lung_data$status == 2)
lung_data$sex_label <- factor(
 lung_data$sex,
 levels = c(1, 2),
 labels = c("Male", "Female")
)

summary_table <- data.frame(
 sample_size = nrow(lung_data),
 events = sum(lung_data$event),
 event_rate = mean(lung_data$event),
 median_followup = median(lung_data$time)
)

summary_table[, c("event_rate", "median_followup")] <-
 round(summary_table[, c("event_rate", "median_followup")], 3)

knitr::kable(
 summary_table,
 caption = "Summary of the lung-cancer survival dataset"
)
```

The most important preparation step is to make the event coding explicit. A survival curve depends on two things: the observed time and whether that time ended in an event or in censoring.

## Step 2: Fit the Kaplan-Meier curves

```r
km_fit <- survival::survfit(
 survival::Surv(time, event) ~ sex_label,
 data = lung_data
)

km_summary <- summary(km_fit)

km_plot_data <- data.frame(
 time = km_summary$time,
 surv = km_summary$surv,
 lower = km_summary$lower,
 upper = km_summary$upper,
 strata = sub("sex_label=", "", km_summary$strata)
)

landmark_table <- summary(km_fit, times = c(90, 180, 365))

landmark_df <- data.frame(
 group = sub("sex_label=", "", landmark_table$strata),
 time = landmark_table$time,
 survival = landmark_table$surv
)

landmark_df$survival <- round(landmark_df$survival, 3)

knitr::kable(
 landmark_df,
 caption = "Estimated survival probabilities at selected landmark times"
)
```

This table complements the plot. A figure gives the full trajectory, while landmark values make it easier to quote specific survival probabilities in the text.

## Step 3: Build the survival curve figure

```r
ggplot2::ggplot(km_plot_data, ggplot2::aes(x = time, y = surv, color = strata)) +
 ggplot2::geom_step(linewidth = 1) +
 ggplot2::geom_step(
 ggplot2::aes(y = lower),
 linetype = 3,
 linewidth = 0.6,
 alpha = 0.7
 ) +
 ggplot2::geom_step(
 ggplot2::aes(y = upper),
 linetype = 3,
 linewidth = 0.6,
 alpha = 0.7
 ) +
 ggplot2::labs(
 title = "Kaplan-Meier survival curves in the lung-cancer dataset",
 subtitle = "Dashed step lines show pointwise 95% confidence limits",
 x = "Days of follow-up",
 y = "Estimated survival probability",
 color = "Group"
 ) +
 ggplot2::scale_color_manual(values = c("#7f5539", "#386641")) +
 ggplot2::coord_cartesian(ylim = c(0, 1)) +
 ggplot2::theme_minimal(base_size = 12)
```

This figure works because it preserves the structure of survival data instead of smoothing it away. The steps show when events happen. The vertical distance between curves shows the separation in survival experience. The dashed confidence limits show the uncertainty around those estimates.

## Step 4: Add a cumulative-event view

Sometimes readers find it easier to interpret event accumulation directly. A simple transformation of the survival curve gives the cumulative incidence of the event:

$$
1 - \hat{S}(t).
$$

```r
km_plot_data$cumulative_event <- 1 - km_plot_data$surv

ggplot2::ggplot(km_plot_data, ggplot2::aes(x = time, y = cumulative_event, color = strata)) +
 ggplot2::geom_step(linewidth = 1) +
 ggplot2::labs(
 title = "Cumulative event curves derived from the Kaplan-Meier estimates",
 subtitle = "The same information can be viewed as event accumulation rather than survival",
 x = "Days of follow-up",
 y = "Cumulative event probability",
 color = "Group"
 ) +
 ggplot2::scale_color_manual(values = c("#7f5539", "#386641")) +
 ggplot2::coord_cartesian(ylim = c(0, 1)) +
 ggplot2::theme_minimal(base_size = 12)
```

This second view is often useful in policy or services settings where the event, such as readmission or treatment failure, is the quantity of direct interest.

## How to read the figure carefully

Kaplan-Meier curves are descriptive. They show the observed survival pattern in the sample after accounting for censoring, but they do not by themselves adjust for confounding or other prognostic differences across groups. They also assume non-informative censoring, which means the censoring mechanism should not be systematically tied to the unobserved future event process.

The curve also becomes less precise later in follow-up, especially when few patients remain under observation. That is why it is good practice to interpret the tail of a survival curve more cautiously than the early and middle portions.

## Further reading

Kaplan and Meier provide the classic foundation for this plot type. Cox is the natural next step when the goal shifts from descriptive curves to adjusted hazard modeling. The `survival` package documentation is also useful when moving from introductory figures to more complex survival displays.
