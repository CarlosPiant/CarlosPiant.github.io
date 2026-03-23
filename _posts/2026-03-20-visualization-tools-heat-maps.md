---
title: "Heat Maps"
date: 2026-03-20
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a general heat map rather than a correlation-matrix heat map. The goal is to show how to display the intensity of an outcome across two dimensions such as time of day by day of week, age group by..."
excerpt: "Visualizing intensity, risk, and concentration across two dimensions"
---
This chapter builds a general heat map rather than a correlation-matrix heat map. The goal is to show how to display the intensity of an outcome across two dimensions such as time of day by day of week, age group by deprivation group, or glucose level by body mass index. Heat maps are useful because they turn a large table of values into a visual surface that the eye can scan quickly for gradients, clusters, and peaks. Wilkinson and Friendly trace the broader history of the heat map as a shaded matrix display and show why it became such a flexible graphical tool across scientific fields.

The figure we will build here is especially useful in applied health research when the analyst wants to show how a rate, count, or predicted probability changes over two interacting dimensions. Unlike a line plot, a heat map does not force one dimension to play the privileged role of the horizontal axis while the other is split into many small series. That makes it a natural choice when the interaction itself is the main message.

## What the visualization is showing

A heat map is a matrix of tiles. Each tile corresponds to a cell defined by one category or interval on the x-axis and another on the y-axis. The fill color represents the value in that cell.

The figure is most useful when:

1. the outcome is measured over a two-dimensional grid,
2. the reader needs to see high and low regions quickly,
3. interactions matter more than individual marginal trends.

The key reading rule is simple: darker or more saturated tiles represent larger values, lighter tiles represent smaller values, and neighboring tiles should be interpreted as part of a surface rather than as isolated bars.

## Step 1: Create a synthetic health-services intensity example

We begin with a synthetic example showing average hourly urgent-care demand by day of week. This is a good use case for a heat map because the analyst cares about joint timing structure, not only daily totals or hourly averages in isolation.

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

format_numeric_table <- function(df, digits = 2) {
 numeric_cols <- vapply(df, is.numeric, logical(1))
 df[numeric_cols] <- lapply(df[numeric_cols], round, digits = digits)
 df
}
```

``` r
set.seed(2026)

days <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
hours <- 0:23

synthetic_heat <- expand.grid(
 day = factor(days, levels = days),
 hour = hours
)

day_effect <- c(Mon = 1.05, Tue = 1.00, Wed = 1.02, Thu = 1.08, Fri = 1.18, Sat = 0.88, Sun = 0.80)

synthetic_heat$baseline_pattern <-
 7 +
 14 * exp(-((synthetic_heat$hour - 10) / 4.2)^2) +
 18 * exp(-((synthetic_heat$hour - 18) / 3.3)^2)

synthetic_heat$expected_visits <-
 synthetic_heat$baseline_pattern * day_effect[as.character(synthetic_heat$day)] +
 ifelse(synthetic_heat$day %in% c("Sat", "Sun") & synthetic_heat$hour %in% 12:16, -3, 0) +
 ifelse(synthetic_heat$day == "Mon" & synthetic_heat$hour %in% 7:10, 4, 0)

synthetic_heat$mean_visits <- pmax(
 round(synthetic_heat$expected_visits + rnorm(nrow(synthetic_heat), sd = 1.2), 1),
 0
)

synthetic_summary <- synthetic_heat |>
 group_by(day) |>
 summarise(
 mean_daily_hourly_visits = mean(mean_visits),
 peak_hour = hour[which.max(mean_visits)],
 peak_visits = max(mean_visits),
.groups = "drop"
 )

knitr::kable(
 format_numeric_table(synthetic_summary, digits = 2),
 caption = "Summary of the synthetic urgent-care demand surface"
)
```

Table: Summary of the synthetic urgent-care demand surface

|day | mean_daily_hourly_visits| peak_hour| peak_visits|
|:---|------------------------:|---------:|-----------:|
|Mon | 16.99| 10| 26.7|
|Tue | 15.69| 17| 26.6|
|Wed | 16.31| 17| 27.3|
|Thu | 16.41| 18| 28.6|
|Fri | 18.75| 18| 29.9|
|Sat | 13.08| 18| 25.5|
|Sun | 12.10| 18| 21.0|

The table is readable, but it loses the interaction structure. To see when demand concentrates jointly by day and hour, we need the heat map itself.

## Step 2: Build the synthetic heat map

``` r
ggplot(synthetic_heat, aes(x = day, y = factor(hour), fill = mean_visits)) +
 geom_tile(color = "white", linewidth = 0.5) +
 scale_fill_gradient(
 low = "#f7fbff",
 high = "#08306b"
 ) +
 labs(
 title = "Synthetic urgent-care demand varies jointly by day and hour",
 subtitle = "Heat maps are useful when the interaction structure is the main message",
 x = NULL,
 y = "Hour of day",
 fill = "Mean visits"
 ) +
 theme_minimal(base_size = 12) +
 theme(
 panel.grid = element_blank
 )
```

![plot of chunk unnamed-chunk-3](/tutorials/rendered-assets/visualization-tools-heat-maps/unnamed-chunk-3-1.png)

This figure makes the demand surface immediately visible. The Monday morning intensity and Friday evening peak are easy to spot, and the weekend lull is clear without reading dozens of separate numbers. That is exactly what a heat map should do well.

## Step 3: Identify the most intense cells

It is often helpful to pair a heat map with a short ranked table of the most important cells.

``` r
top_synthetic_cells <- synthetic_heat |>
 arrange(desc(mean_visits)) |>
 slice_head(n = 8) |>
 select(day, hour, mean_visits)

knitr::kable(
 format_numeric_table(top_synthetic_cells, digits = 1),
 caption = "Highest-intensity cells in the synthetic heat map"
)
```

Table: Highest-intensity cells in the synthetic heat map

|day | hour| mean_visits|
|:---|----:|-----------:|
|Fri | 18| 29.9|
|Fri | 17| 29.7|
|Thu | 18| 28.6|
|Fri | 19| 28.4|
|Wed | 17| 27.3|
|Mon | 10| 26.7|
|Tue | 17| 26.6|
|Thu | 17| 26.5|

This combination works well in teaching and reporting. The figure gives the global pattern, and the small table names the local peaks precisely.

## Step 4: Create a real-world risk heat map from a public scientific dataset

For a real-world example, we use the public Pima diabetes data distributed with `MASS`, linked to the classification problem studied by Smith and colleagues. The figure will show observed diabetes prevalence across bins of plasma glucose and body mass index. This is a transparent partial application rather than a literal recreation of a figure in the original paper. The paper is the scientific source of the dataset and prediction problem, while the heat map is a teaching visualization built on the public data.

The point of the figure is to show how diabetes prevalence changes jointly over two clinically meaningful dimensions. A table could report prevalence in each bin, but a heat map makes the risk surface much easier to interpret.

``` r
data("Pima.tr", package = "MASS")
data("Pima.te", package = "MASS")

pima_all <- rbind(Pima.tr, Pima.te)
pima_all$diabetes <- as.integer(pima_all$type == "Yes")

glu_breaks <- c(80, 100, 120, 140, 160, 200)
bmi_breaks <- c(18, 25, 30, 35, 40, 50)

pima_all$glu_group <- cut(
 pima_all$glu,
 breaks = glu_breaks,
 include.lowest = TRUE,
 right = FALSE
)

pima_all$bmi_group <- cut(
 pima_all$bmi,
 breaks = bmi_breaks,
 include.lowest = TRUE,
 right = FALSE
)

risk_heat <- pima_all |>
 filter(!is.na(glu_group), !is.na(bmi_group)) |>
 group_by(glu_group, bmi_group) |>
 summarise(
 n = n,
 diabetes_prevalence = mean(diabetes),
.groups = "drop"
 )

risk_heat$glu_group <- factor(risk_heat$glu_group, levels = levels(pima_all$glu_group))
risk_heat$bmi_group <- factor(risk_heat$bmi_group, levels = rev(levels(pima_all$bmi_group)))
risk_heat$prevalence_display <- ifelse(risk_heat$n >= 5, risk_heat$diabetes_prevalence, NA_real_)
risk_heat$prevalence_label <- ifelse(is.na(risk_heat$prevalence_display), "", sprintf("%.2f", risk_heat$prevalence_display))

risk_summary <- risk_heat |>
 filter(n >= 5) |>
 arrange(desc(diabetes_prevalence), desc(n)) |>
 slice_head(n = 8)

knitr::kable(
 format_numeric_table(
 risk_summary[, c("glu_group", "bmi_group", "n", "diabetes_prevalence")],
 digits = 3
 ),
 caption = "Highest-prevalence cells in the public Pima diabetes heat map"
)
```

Table: Highest-prevalence cells in the public Pima diabetes heat map

|glu_group |bmi_group | n| diabetes_prevalence|
|:---------|:---------|--:|-------------------:|
|[160,200] |[35,40) | 17| 0.941|
|[160,200] |[40,50] | 15| 0.867|
|[160,200] |[30,35) | 29| 0.828|
|[160,200] |[25,30) | 7| 0.714|
|[140,160) |[35,40) | 14| 0.643|
|[120,140) |[40,50] | 13| 0.615|
|[140,160) |[30,35) | 24| 0.542|
|[140,160) |[40,50] | 14| 0.500|

## Step 5: Draw the real-world heat map

``` r
ggplot(risk_heat, aes(x = glu_group, y = bmi_group, fill = prevalence_display)) +
 geom_tile(color = "white", linewidth = 0.6) +
 geom_text(aes(label = prevalence_label), size = 3.1) +
 scale_fill_gradient(
 low = "#fff5f0",
 high = "#99000d"
 ) +
 labs(
 title = "Observed diabetes prevalence rises across glucose and BMI categories",
 subtitle = "Public Pima diabetes data linked to Smith et al. (1988)",
 x = "Plasma glucose category",
 y = "Body mass index category",
 fill = "Prevalence"
 ) +
 theme_minimal(base_size = 12) +
 theme(
 panel.grid = element_blank,
 axis.text.x = element_text(angle = 20, hjust = 1)
 )
```

![plot of chunk unnamed-chunk-6](/tutorials/rendered-assets/visualization-tools-heat-maps/unnamed-chunk-6-1.png)

The real-world figure shows why heat maps are valuable for risk communication. The reader can see immediately that high glucose and high BMI cells concentrate much larger diabetes prevalence than the low-glucose, lower-BMI cells. A line plot would force one of those variables into the background. The heat map keeps both dimensions central.

## How to read the figure carefully

Heat maps are powerful because they compress a lot of information, but they also require care. First, the choice of bin boundaries matters. Different glucose or BMI intervals would change the appearance of the surface, especially in small datasets. Second, some cells may contain few observations, so visually striking tiles should be checked against their sample size before being overinterpreted.

It is also important to remember that a heat map is usually descriptive. In the Pima example, a dark cell does not mean glucose and BMI jointly cause diabetes in a simple deterministic way. It means that, in the observed sample, prevalence is high in that part of the two-dimensional predictor space.

Finally, color scales matter. Sequential palettes work well when the value goes from low to high. Diverging palettes are better when zero or another midpoint is substantively important. Choosing the wrong palette can make the figure harder to interpret than the underlying table.

## How this figure complements the rest of the book

Heat maps are useful across many parts of the tutorial collection. In epidemiology they can show age-by-time incidence intensity. In health economics they can show uptake or spending by risk group and insurance type. In machine learning they can display predicted risk surfaces, confusion structures, or hyperparameter grids. In decision sciences they can show threshold-dependent policy recommendations over two varying parameters.

The key lesson is that heat maps are not just attractive graphics. They are compact two-dimensional summaries that help the reader see where outcomes, risks, or counts concentrate.

## Further reading

Wilkinson and Friendly provide a concise historical discussion of the heat map as a scientific display and explain how clustered heat maps emerged from older matrix-shading traditions. For the real-world prediction setting used here, Smith and colleagues provide the original diabetes-classification application behind the public Pima data. A natural next step after this chapter is to compare a simple descriptive heat map like this one with a model-based prediction surface built from logistic regression or another flexible model.

## References

- Wilkinson, Leland; Friendly, Michael (2009). "The History of the Cluster Heat Map." *The American Statistician*, 63(2), 179--184. DOI: <https://doi.org/10.1198/tas.2009.0033>.
- Smith, J. W.; Everhart, J. E.; Dickson, W. C.; Knowler, W. C.; Johannes, R. S. (1988). "Using the ADAP Learning Algorithm to Forecast the Onset of Diabetes Mellitus." *Proceedings of the Symposium on Computer Applications in Medical Care*, 261--265.
