---
title: "Choropleth Maps for Regional Health Variation"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a choropleth map, a figure in which geographic areas are shaded according to a rate, proportion, or other area-level summary. Choropleth maps are useful in health research because many policy and..."
excerpt: "Building a geographic rate map that shows where health outcomes are higher or lower"
---
This chapter builds a choropleth map, a figure in which geographic areas are shaded according to a rate, proportion, or other area-level summary. Choropleth maps are useful in health research because many policy and epidemiologic questions are fundamentally regional. Analysts often want to show how mortality, access, screening uptake, or disease burden varies across counties, districts, or states. Bivand, Pebesma, and Gomez-Rubio emphasize that mapped areal data are most informative when the quantity being mapped is chosen carefully and the geography is treated as part of the analysis rather than as decoration. Pebesma's `sf` framework also made this type of spatial graphic much easier to build reproducibly in R.

The key design principle is simple but important: choropleth maps should usually display rates rather than raw counts. Large regions often have large counts simply because they contain more people. If the purpose is to show regional health variation, the mapped quantity should usually normalize for population at risk or event exposure.

## What the visualization is showing

We will build a choropleth map in which:

1. each polygon is a region,
2. fill color represents a health rate,
3. darker colors indicate higher values,
4. region boundaries remain visible enough to preserve geographic structure.

The figure is most useful when the outcome is naturally defined at an areal level, such as a county mortality rate, a district vaccination rate, or a state-level screening prevalence. The main reading rule is that the map should be interpreted as a regional surface: adjacent high-value regions suggest clustering, while isolated dark or light polygons may indicate local outliers or unstable small-area rates.

## Step 1: Create a synthetic regional health-rate surface

We begin with a synthetic map. The purpose is to show the mechanics of a choropleth without relying on real administrative boundaries. We will create a small grid of rectangular regions and assign each one a synthetic preventable-hospitalization rate.

```r
library(dplyr)
library(ggplot2)
library(knitr)
library(sf)
library(viridisLite)

format_numeric_table <- function(df, digits = 2) {
 numeric_cols <- vapply(df, is.numeric, logical(1))
 df[numeric_cols] <- lapply(df[numeric_cols], round, digits = digits)
 df
}
```

```r
set.seed(2027)

synthetic_bbox <- st_as_sfc(
 st_bbox(c(xmin = 0, ymin = 0, xmax = 6, ymax = 5), crs = st_crs(3857))
)

synthetic_grid <- st_make_grid(synthetic_bbox, n = c(6, 5))

synthetic_map <- st_sf(
 region_id = seq_along(synthetic_grid),
 geometry = synthetic_grid
)

centroids <- st_coordinates(st_point_on_surface(st_geometry(synthetic_map)))

synthetic_map <- synthetic_map |>
 mutate(
 col_id = round(centroids[, "X"] - 0.5),
 row_id = round(centroids[, "Y"] - 0.5),
 deprivation = 0.7 * col_id + 0.4 * row_id + rnorm(n, sd = 0.35),
 primary_care_access = 3.2 - 0.45 * col_id + 0.15 * row_id + rnorm(n, sd = 0.20),
 preventable_admission_rate = pmax(
 55 + 9 * deprivation - 6 * primary_care_access + rnorm(n, sd = 3),
 15
 ),
 region = paste0("Region ", sprintf("%02d", region_id))
 )

synthetic_summary <- synthetic_map |>
 st_drop_geometry |>
 arrange(desc(preventable_admission_rate)) |>
 select(region, preventable_admission_rate, deprivation, primary_care_access) |>
 slice_head(n = 8)

knitr::kable(
 format_numeric_table(synthetic_summary, digits = 2),
 caption = "Highest-rate regions in the synthetic choropleth example"
)
```

The synthetic data have a clear spatial logic. Regions farther to the upper right tend to have higher deprivation and weaker primary-care access, which translates into higher preventable-admission rates. That gives the map a meaningful pattern rather than random color noise.

## Step 2: Build the synthetic choropleth map

```r
ggplot(synthetic_map) +
 geom_sf(aes(fill = preventable_admission_rate), color = "white", linewidth = 0.5) +
 scale_fill_gradientn(
 colors = viridisLite::magma(7),
 name = "Rate per 1,000"
 ) +
 labs(
 title = "A choropleth map shows regional variation in a health rate",
 subtitle = "Synthetic preventable-admission rates across a grid of regions",
 caption = "Darker shading indicates higher rates"
 ) +
 theme_minimal(base_size = 12) +
 theme(
 axis.text = element_blank,
 axis.title = element_blank,
 panel.grid = element_blank
 )
```

This figure works because it uses geography only for the job geography can do well. The map lets the reader see where high-rate regions cluster, whether there is a gradient across space, and whether a few polygons stand out from their neighbors.

## Step 3: Pair the map with a compact regional summary

Maps are strongest when paired with a short table that names the most extreme regions directly. A reader can see the spatial pattern in the figure and then use the table to identify the regions precisely.

```r
synthetic_distribution <- synthetic_map |>
 st_drop_geometry |>
 summarize(
 min_rate = min(preventable_admission_rate),
 median_rate = median(preventable_admission_rate),
 mean_rate = mean(preventable_admission_rate),
 max_rate = max(preventable_admission_rate)
 )

knitr::kable(
 format_numeric_table(synthetic_distribution, digits = 2),
 caption = "Distribution of rates in the synthetic choropleth example"
)
```

This is also a good point to emphasize the main methodological caution: if these were event counts rather than rates, the map would mostly reflect where large populations happen to live. Choropleths are most defensible when the shading encodes a quantity that is comparable across areas.

## Step 4: Create a real-world choropleth map from public health data

For a real-world example, we use the public North Carolina county dataset bundled with `sf`. These polygons include counts of births and sudden infant death cases in 1974 and 1979 and have long served as a teaching example in spatial epidemiology and disease mapping. The figure below maps the 1979 sudden infant death syndrome rate per 1,000 births across counties.

This is a transparent partial application rather than a reconstruction of one published figure. The underlying public data are real, the health outcome is real, and the map is built for teaching the choropleth itself.

```r
nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE) |>
 mutate(
 sid_rate_79 = 1000 * SID79 / BIR79,
 nonwhite_birth_share_79 = NWBIR79 / BIR79
 )

nc_summary <- nc |>
 st_drop_geometry |>
 summarize(
 counties = n,
 total_births_1979 = sum(BIR79),
 total_sid_1979 = sum(SID79),
 mean_sid_rate_79 = mean(sid_rate_79),
 median_sid_rate_79 = median(sid_rate_79)
 )

nc_extremes <- nc |>
 st_drop_geometry |>
 select(NAME, BIR79, SID79, sid_rate_79) |>
 arrange(desc(sid_rate_79)) |>
 slice_head(n = 8)

knitr::kable(
 format_numeric_table(nc_summary, digits = 2),
 caption = "Summary of the public North Carolina county health-variation dataset"
)

knitr::kable(
 format_numeric_table(nc_extremes, digits = 3),
 caption = "Highest county SIDS rates per 1,000 births in the 1979 North Carolina data"
)
```

The rate is the right mapped quantity here because births vary substantially across counties. A map of raw SIDS counts would mostly show where there were more births, not where the rate of infant death was unusually high.

## Step 5: Draw the real-world choropleth map

```r
ggplot(nc) +
 geom_sf(aes(fill = sid_rate_79), color = "grey95", linewidth = 0.15) +
 scale_fill_gradientn(
 colors = viridisLite::viridis(7),
 name = "SIDS rate\nper 1,000 births"
 ) +
 labs(
 title = "Choropleth map of county-level infant mortality variation",
 subtitle = "Public North Carolina county SIDS rates in 1979 from the sf sample dataset",
 caption = "Mapped quantity is the rate, not the raw count of cases"
 ) +
 theme_minimal(base_size = 12) +
 theme(
 axis.text = element_blank,
 axis.title = element_blank,
 panel.grid = element_blank
 )
```

This real-world figure shows why choropleth maps are so useful for regional health variation. The map makes it possible to see geographic heterogeneity immediately, rather than forcing the reader to parse a county-by-county table. It also makes clear why the analyst should think carefully about regional interpretation: some dark counties are contiguous, while others are isolated and may reflect small-area volatility as much as true underlying risk.

## How to read the figure carefully

Choropleth maps are persuasive, which is exactly why they need discipline. First, area does not equal population. Large rural polygons can dominate the image even when they contain relatively few births or people. Second, mapped rates can be unstable in small regions. A county with few births can have a very high rate after only a small number of events. In applied work, that is one reason analysts often consider smoothing or empirical Bayes shrinkage before mapping.

Third, the choice of color scale matters. Sequential palettes work well for strictly ordered quantities like rates. Diverging palettes are better when there is a meaningful midpoint such as zero change or national average deviation. Finally, maps should usually be read together with a table or contextual note so that high-value regions can be identified precisely and not just visually.

## Further reading

For a broad treatment of areal data and mapping practice in R, Bivand, Pebesma, and Gomez-Rubio remain the core reference. Pebesma's article on simple features is the key reference for modern spatial workflows in R. For readers who want to move from descriptive maps to formal spatial analysis, the spatial-association and areal-data references already used elsewhere in the book are natural next steps.

## References

- Bivand, Roger; Pebesma, Edzer; G\'omez-Rubio, Virgilio (2013). "Applied Spatial Data Analysis with R." Springer, New York. <https://asdar-book.org/>.
- Pebesma, Edzer (2018). "Simple Features for R: Standardized Support for Spatial Vector Data." *The R Journal*, 10(1), 439--446. DOI: <https://doi.org/10.32614/RJ-2018-009>.
- Bivand, Roger; Wong, David (2018). "Comparing Implementations of Global and Local Indicators of Spatial Association." *TEST*, 27(3), 716--748. DOI: <https://doi.org/10.1007/s11749-018-0599-x>.
- Bivand, Roger (2022). "R Packages for Analyzing Spatial Data: A Comparative Case Study with Areal Data." *Geographical Analysis*, 54(3), 488--518. DOI: <https://doi.org/10.1111/gean.12319>.
