---
title: "Temporal Series"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a temporal-series plot rather than a cross-sectional line chart. The goal is to show how an outcome evolves over time while preserving the two features that matter most in applied health data:..."
excerpt: "Building a polished time-series line plot with a trend overlay"
---
This chapter builds a temporal-series plot rather than a cross-sectional line chart. The goal is to show how an outcome evolves over time while preserving the two features that matter most in applied health data: short-run fluctuation and longer-run movement. A good temporal-series figure makes it possible to see seasonality, secular trend, abrupt level shifts, and unusual months without forcing the reader to inspect a dense table of dates and values. Diggle's biostatistical time-series text is a natural reference point for this kind of health application, while Wickham's grammar of graphics provides a practical framework for turning the series into a clear, publication-ready figure.

The specific figure we will build is a two-layer time-series display: a thin line for the raw monthly series and a thicker line for a 12-month moving average. This is a useful default in health economics, epidemiology, and outcomes research because the raw line shows the month-to-month data actually observed, while the smoother overlay helps the reader focus on the underlying direction of change.

## What the visualization is showing

A temporal-series plot places time on the horizontal axis and the observed outcome on the vertical axis. In this chapter, the figure contains two visual summaries of the same series:

1. a raw monthly line,
2. a 12-month moving-average line.

This figure is useful when:

1. the analyst needs to show how an outcome changes over time,
2. seasonal noise should remain visible but not dominate the message,
3. the audience needs to distinguish temporary variation from sustained movement.

The key reading rule is simple. The thin line shows the actual observed pattern, including spikes and dips. The thicker moving-average line should be read as the medium-run trajectory. When the two lines diverge temporarily, that usually indicates short-run volatility or seasonality rather than a structural change in the whole series.

## Step 1: Create a synthetic health-services time series

We begin with a synthetic monthly series for preventable emergency admissions. This is a good teaching example because the data contain several common features at once: winter seasonality, a slow upward baseline trend, and a policy change that reduces admissions after a transitional date.

```r
library(dplyr)
library(ggplot2)
library(knitr)

format_numeric_table <- function(df, digits = 2) {
 numeric_cols <- vapply(df, is.numeric, logical(1))
 df[numeric_cols] <- lapply(df[numeric_cols], round, digits = digits)
 df
}

moving_average <- function(x, k = 12) {
 as.numeric(stats::filter(x, rep(1 / k, k), sides = 2))
}
```

```r
set.seed(2026)

n_months <- 72
synthetic_dates <- seq.Date(as.Date("2019-01-01"), by = "month", length.out = n_months)
t <- seq_len(n_months)

seasonal_pattern <-
 16 * sin(2 * pi * t / 12) +
 10 * cos(2 * pi * t / 12)

baseline_trend <- 185 + 0.75 * t
policy_effect <- ifelse(synthetic_dates >= as.Date("2022-07-01"), -22, 0)
noise <- rnorm(n_months, mean = 0, sd = 6.5)

synthetic_series <- data.frame(
 date = synthetic_dates,
 admissions = baseline_trend + seasonal_pattern + policy_effect + noise
) |>
 mutate(
 admissions = round(admissions, 1),
 ma12 = moving_average(admissions, k = 12),
 year = format(date, "%Y"),
 month = format(date, "%m")
 )

synthetic_summary <- synthetic_series |>
 group_by(year) |>
 summarise(
 mean_monthly_admissions = mean(admissions),
 winter_peak = max(admissions[month %in% c("12", "01", "02")]),
 annual_minimum = min(admissions),
.groups = "drop"
 )

knitr::kable(
 format_numeric_table(synthetic_summary, digits = 1),
 caption = "Yearly summary of the synthetic preventable-admissions series"
)
```

The table is informative, but it cannot show the continuity of the series. A temporal-series plot is useful precisely because it connects adjacent months and makes the timing of peaks, troughs, and regime changes visible.

## Step 2: Build the synthetic temporal-series figure

```r
ggplot(synthetic_series, aes(x = date, y = admissions)) +
 annotate(
 "rect",
 xmin = as.Date("2022-07-01"),
 xmax = max(synthetic_series$date),
 ymin = -Inf,
 ymax = Inf,
 alpha = 0.06,
 fill = "#74a57f"
 ) +
 geom_line(linewidth = 0.55, color = "#7f8c8d") +
 geom_line(aes(y = ma12), linewidth = 1.15, color = "#0b4f6c", na.rm = TRUE) +
 geom_vline(
 xintercept = as.Date("2022-07-01"),
 linetype = 2,
 linewidth = 0.7,
 color = "#4d4d4d"
 ) +
 labs(
 title = "A temporal-series plot separates monthly noise from the underlying trajectory",
 subtitle = "Synthetic preventable emergency admissions with a 12-month moving average",
 x = NULL,
 y = "Monthly admissions"
 ) +
 theme_minimal(base_size = 12) +
 theme(
 panel.grid.minor = element_blank
 )
```

This figure works because the raw line and the smoother line serve different purposes. The grey series shows the monthly data actually observed. The blue line strips away much of the seasonal oscillation and makes the post-policy decline easier to see. The shaded post-intervention period is not itself an estimator of effect, but it helps the reader orient the timing of the series.

## Step 3: Identify key turning points

As in several other chapters in this section, it is often useful to pair the figure with a short table naming the most important periods.

```r
synthetic_turning_points <- synthetic_series |>
 arrange(desc(admissions)) |>
 slice_head(n = 6) |>
 transmute(
 date = format(date, "%Y-%m"),
 admissions = admissions
 )

knitr::kable(
 format_numeric_table(synthetic_turning_points, digits = 1),
 caption = "Highest monthly observations in the synthetic temporal series"
)
```

The figure gives the shape of the whole process. The table names the local extremes precisely. Together they make the series easier to describe in text and easier to inspect critically.

## Step 4: Create a real-world temporal series from a public health dataset

For a real-world example, we use the monthly UK lung-disease deaths series distributed with the `datasets` package in R. The help file cites Diggle's biostatistical time-series text as the source for these monthly deaths from bronchitis, emphysema, and asthma in the UK from 1974 through 1979. This is therefore a transparent public-data application rather than a literal reconstruction of one published figure.

The point of the example is to show how the same figure design works in a real health time series with strong seasonality. Winter peaks are visually obvious in the raw line, while the 12-month moving average helps the reader see whether the underlying level is drifting up or down over the sample.

```r
lung_deaths <- get("ldeaths", envir = asNamespace("datasets"))

time_index <- time(lung_deaths)
years <- floor(time_index)
months <- cycle(lung_deaths)

real_series <- data.frame(
 date = as.Date(sprintf("%d-%02d-01", years, months)),
 deaths = as.numeric(lung_deaths)
) |>
 mutate(
 ma12 = moving_average(deaths, k = 12),
 year = format(date, "%Y"),
 month = format(date, "%m")
 )

real_summary <- real_series |>
 group_by(year) |>
 summarise(
 mean_monthly_deaths = mean(deaths),
 annual_peak = max(deaths),
 annual_minimum = min(deaths),
.groups = "drop"
 )

knitr::kable(
 format_numeric_table(real_summary, digits = 1),
 caption = "Yearly summary of the public UK lung-disease deaths series"
)
```

## Step 5: Draw the real-world temporal-series figure

```r
ggplot(real_series, aes(x = date, y = deaths)) +
 geom_line(linewidth = 0.55, color = "#8c8c8c") +
 geom_line(aes(y = ma12), linewidth = 1.15, color = "#8c2d04", na.rm = TRUE) +
 labs(
 title = "The temporal-series plot shows both seasonality and medium-run movement",
 subtitle = "Monthly UK deaths from bronchitis, emphysema, and asthma, 1974-1979",
 x = NULL,
 y = "Deaths per month"
 ) +
 theme_minimal(base_size = 12) +
 theme(
 panel.grid.minor = element_blank
 )
```

This real-world figure shows why the layered temporal-series display is so useful. The raw line makes the winter peaks unmistakable. The moving average shows that the series has a broader level pattern beyond those seasonal swings. A table of annual means would partially capture that, but it would hide the month-to-month structure entirely.

## How to read the figure carefully

Temporal-series plots are descriptive before they are causal. A visible level shift after a policy date does not by itself prove that the policy caused the change. Other concurrent shocks, seasonal composition, and mean reversion can all create patterns that look persuasive in a line chart. The figure is therefore a communication tool, not a substitute for interrupted time-series estimation or other formal design-based analysis.

It is also important to interpret the moving average correctly. Smoothing is useful because it suppresses noise, but it also delays and dilutes abrupt changes. A 12-month moving average is helpful for medium-run interpretation, especially in seasonal monthly data, but it should not be used to claim precise turning points.

Finally, the graph should preserve enough of the raw series for the reader to see what has been smoothed away. That is why the thin monthly line matters. Without it, the reader cannot tell whether the smoother reflects a genuinely stable trajectory or only a noisy series averaged into apparent stability.

## Further reading

Diggle provides a concise health-oriented introduction to time-series data and is a natural reference for the UK lung-deaths series used here. Wickham's treatment of layered graphics is useful for readers who want to extend this figure design with annotations, faceting, or additional model-based overlays.

## References

- Diggle, Peter J. (1990). "Time Series: A Biostatistical Introduction." Oxford University Press, Oxford.
- Wickham, Hadley (2016). "ggplot2: Elegant Graphics for Data Analysis." Springer, New York.
