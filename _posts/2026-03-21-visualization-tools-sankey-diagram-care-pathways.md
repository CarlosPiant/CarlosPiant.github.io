---
title: "Sankey Diagram for Care Pathways"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a Sankey-style care-pathway diagram, a figure used to show how patients or episodes flow from one stage to the next. In applied health research, many decisions depend not only on endpoint outcomes..."
excerpt: "Building a flow diagram that shows how patients move through sequential stages of care"
---
This chapter builds a Sankey-style care-pathway diagram, a figure used to show how patients or episodes flow from one stage to the next. In applied health research, many decisions depend not only on endpoint outcomes but also on how people move through the system: admission source, discharge destination, treatment assignment, recurrence, recovery, readmission, and death. A Sankey diagram turns those sequential transitions into a single visual object. Instead of reading a set of disconnected cross-tabulations, the reader can see how large each stream is and where the main losses, bottlenecks, or unfavorable pathways occur. Wickham's grammar-of-graphics perspective is useful here because the figure can be built from layered polygons, labels, and rectangles rather than as a black-box chart type. Brunson's work on alluvial graphics also clarifies why these flow diagrams are so effective for categorical transitions across stages.

The point of the figure is not merely to show counts. It is to show structure. A care pathway often contains several stages, and the substantive question is how patients redistribute as they move through them. A Sankey diagram is useful when the flow itself is the message.

## What the visualization is showing

We will build a three-stage Sankey diagram in which:

1. each column is a stage in the pathway,
2. each block is a category within that stage,
3. each ribbon links one category to the next,
4. ribbon width is proportional to the number of patients following that path.

The key reading rule is straightforward. Read the figure from left to right. Thick ribbons indicate common pathways. Thin ribbons indicate uncommon ones. When many ribbons converge into one block, that block is receiving patients from multiple upstream routes. When a block sends flow into several downstream destinations, it indicates branching after that stage.

## Step 1: Create a synthetic care-pathway flow table

We begin with a synthetic hospital pathway for a transitional-care program. The stages are:

1. admission source,
2. discharge destination,
3. 30-day outcome.

This is a good use case for a Sankey diagram because the policy question is inherently sequential. The analyst wants to know not only how many patients are readmitted, but which upstream routes are most associated with those downstream outcomes.

```r
library(dplyr)
library(ggplot2)
library(knitr)

format_numeric_table <- function(df, digits = 2) {
 numeric_cols <- vapply(df, is.numeric, logical(1))
 df[numeric_cols] <- lapply(df[numeric_cols], round, digits = digits)
 df
}

allocate_nodes <- function(totals, order, gap) {
 totals <- totals |>
 mutate(node = factor(node, levels = order)) |>
 arrange(node)

 total_height <- sum(totals$value) + gap * (nrow(totals) - 1)
 current_top <- total_height

 totals$ymax <- NA_real_
 totals$ymin <- NA_real_

 for (i in seq_len(nrow(totals))) {
 totals$ymax[i] <- current_top
 totals$ymin[i] <- current_top - totals$value[i]
 current_top <- totals$ymin[i] - gap
 }

 totals$y <- (totals$ymin + totals$ymax) / 2
 totals
}

make_ribbon_polygon <- function(x0, x1, y0_min, y0_max, y1_min, y1_max, fill_group, flow_id, n_points = 60) {
 t <- seq(0, 1, length.out = n_points)
 s <- 3 * t^2 - 2 * t^3
 x <- x0 + (x1 - x0) * t
 y_upper <- y0_max + (y1_max - y0_max) * s
 y_lower <- y0_min + (y1_min - y0_min) * s

 data.frame(
 x = c(x, rev(x)),
 y = c(y_upper, rev(y_lower)),
 flow_fill = fill_group,
 flow_id = flow_id
 )
}

prepare_sankey_components <- function(flows, stage_vars, stage_orders, stage_titles, middle_stage, gap = 18, node_width = 0.52) {
 x_positions <- seq(0, by = 3, length.out = length(stage_vars))

 node_data <- bind_rows(lapply(seq_along(stage_vars), function(i) {
 stage <- stage_vars[i]

 totals <- flows |>
 group_by(node =.data[[stage]]) |>
 summarise(value = sum(n),.groups = "drop")

 layout <- allocate_nodes(totals, order = stage_orders[[stage]], gap = gap)

 layout |>
 mutate(
 stage = stage,
 x = x_positions[i],
 xmin = x - node_width / 2,
 xmax = x + node_width / 2
 )
 }))

 ribbon_list <- lapply(seq_len(length(stage_vars) - 1), function(i) {
 source_stage <- stage_vars[i]
 target_stage <- stage_vars[i + 1]

 pair_flows <- flows |>
 group_by(
 source =.data[[source_stage]],
 target =.data[[target_stage]],
 flow_fill =.data[[middle_stage]]
 ) |>
 summarise(n = sum(n),.groups = "drop")

 source_bounds <- node_data |>
 filter(stage == source_stage) |>
 select(source = node, source_x = x, source_ymin = ymin, source_ymax = ymax)

 target_bounds <- node_data |>
 filter(stage == target_stage) |>
 select(target = node, target_x = x, target_ymin = ymin, target_ymax = ymax)

 source_segments <- pair_flows |>
 mutate(
 source = factor(source, levels = stage_orders[[source_stage]]),
 target = factor(target, levels = stage_orders[[target_stage]])
 ) |>
 arrange(source, target) |>
 left_join(source_bounds, by = "source") |>
 group_by(source) |>
 mutate(
 seg_source_ymax = source_ymax - lag(cumsum(n), default = 0),
 seg_source_ymin = seg_source_ymax - n
 ) |>
 ungroup

 target_segments <- pair_flows |>
 mutate(
 source = factor(source, levels = stage_orders[[source_stage]]),
 target = factor(target, levels = stage_orders[[target_stage]])
 ) |>
 arrange(target, source) |>
 left_join(target_bounds, by = "target") |>
 group_by(target) |>
 mutate(
 seg_target_ymax = target_ymax - lag(cumsum(n), default = 0),
 seg_target_ymin = seg_target_ymax - n
 ) |>
 ungroup

 segment_data <- source_segments |>
 select(source, target, flow_fill, n, source_x, seg_source_ymin, seg_source_ymax) |>
 left_join(
 target_segments |>
 select(source, target, flow_fill, n, target_x, seg_target_ymin, seg_target_ymax),
 by = c("source", "target", "flow_fill", "n")
 )

 bind_rows(lapply(seq_len(nrow(segment_data)), function(j) {
 make_ribbon_polygon(
 x0 = segment_data$source_x[j] + node_width / 2,
 x1 = segment_data$target_x[j] - node_width / 2,
 y0_min = segment_data$seg_source_ymin[j],
 y0_max = segment_data$seg_source_ymax[j],
 y1_min = segment_data$seg_target_ymin[j],
 y1_max = segment_data$seg_target_ymax[j],
 fill_group = as.character(segment_data$flow_fill[j]),
 flow_id = paste(source_stage, target_stage, j, sep = "_")
 )
 }))
 })

 stage_labels <- data.frame(
 x = x_positions,
 y = max(node_data$ymax) + gap * 0.9,
 label = stage_titles
 )

 list(
 nodes = node_data,
 ribbons = bind_rows(ribbon_list),
 stage_labels = stage_labels,
 plot_ymax = stage_labels$y[1] + gap * 0.6
 )
}

draw_sankey_plot <- function(components, fill_palette, title, subtitle) {
 ggplot +
 geom_polygon(
 data = components$ribbons,
 aes(x = x, y = y, group = flow_id, fill = flow_fill),
 alpha = 0.78,
 color = NA
 ) +
 geom_rect(
 data = components$nodes,
 aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
 inherit.aes = FALSE,
 fill = "#f7f7f7",
 color = "#4d4d4d",
 linewidth = 0.35
 ) +
 geom_text(
 data = components$nodes,
 aes(x = x, y = y, label = node),
 size = 3.0,
 lineheight = 0.92
 ) +
 geom_text(
 data = components$stage_labels,
 aes(x = x, y = y, label = label),
 size = 3.8,
 fontface = "bold"
 ) +
 scale_fill_manual(values = fill_palette, name = NULL) +
 coord_cartesian(
 xlim = c(min(components$stage_labels$x) - 1.0, max(components$stage_labels$x) + 1.0),
 ylim = c(0, components$plot_ymax),
 clip = "off"
 ) +
 labs(
 title = title,
 subtitle = subtitle
 ) +
 theme_void(base_size = 12) +
 theme(
 legend.position = "bottom",
 plot.title = element_text(face = "bold", size = 13),
 plot.subtitle = element_text(size = 10, color = "#4d4d4d"),
 plot.margin = margin(10, 10, 12, 10)
 )
}
```

```r
synthetic_flow_table <- data.frame(
 admission_source = c(
 rep("Emergency\ndepartment", 9),
 rep("Primary care\nreferral", 6),
 rep("Post-surgical\nobservation", 9)
 ),
 discharge_destination = c(
 rep("Home", 3),
 rep("Home with\nnursing", 3),
 rep("Rehabilitation", 3),
 rep("Home", 3),
 rep("Home with\nnursing", 3),
 rep("Home", 3),
 rep("Home with\nnursing", 3),
 rep("Rehabilitation", 3)
 ),
 outcome_30d = rep(
 c("No\nreadmission", "Readmitted", "Died"),
 times = 8
 ),
 n = c(
 180, 55, 5,
 70, 35, 10,
 25, 22, 8,
 150, 18, 2,
 45, 10, 3,
 120, 20, 3,
 38, 12, 4,
 25, 8, 3
 )
)

synthetic_summary <- synthetic_flow_table |>
 mutate(
 admission_source = gsub("\n", " ", admission_source),
 discharge_destination = gsub("\n", " ", discharge_destination),
 outcome_30d = gsub("\n", " ", outcome_30d)
 ) |>
 arrange(desc(n)) |>
 slice_head(n = 10)

knitr::kable(
 format_numeric_table(synthetic_summary, digits = 0),
 caption = "Largest synthetic care pathways that will appear in the Sankey diagram"
)
```

The synthetic table already contains the full pathway information, but it is hard to see the structure by inspection alone. The Sankey diagram will make the dominant routes immediately visible.

## Step 2: Build a reusable static Sankey diagram

The functions above build the figure from two ingredients:

1. node rectangles, which define the categories at each stage,
2. ribbon polygons, which connect one stage to the next with widths proportional to counts.

This is useful because it keeps the figure entirely reproducible in static `ggplot2` code. The diagram is therefore suitable for Quarto output, PDF export, and academic documents that need a non-interactive figure.

## Step 3: Draw the synthetic Sankey diagram

```r
synthetic_stage_orders <- list(
 admission_source = c(
 "Emergency\ndepartment",
 "Primary care\nreferral",
 "Post-surgical\nobservation"
 ),
 discharge_destination = c(
 "Home",
 "Home with\nnursing",
 "Rehabilitation"
 ),
 outcome_30d = c(
 "No\nreadmission",
 "Readmitted",
 "Died"
 )
)

synthetic_components <- prepare_sankey_components(
 flows = synthetic_flow_table,
 stage_vars = c("admission_source", "discharge_destination", "outcome_30d"),
 stage_orders = synthetic_stage_orders,
 stage_titles = c("Admission source", "Discharge destination", "30-day outcome"),
 middle_stage = "discharge_destination",
 gap = 18
)

synthetic_palette <- c(
 "Home" = "#7fc97f",
 "Home with\nnursing" = "#fdc086",
 "Rehabilitation" = "#beaed4"
)

synthetic_sankey <- draw_sankey_plot(
 synthetic_components,
 fill_palette = synthetic_palette,
 title = "A Sankey diagram shows how patients redistribute across a care pathway",
 subtitle = "Synthetic hospital pathway from admission source to discharge destination to 30-day outcome"
)

synthetic_sankey
```

This figure is useful because it answers several questions at once:

1. which admission source contributes the most patients,
2. which discharge destination receives most of them,
3. where the main readmission and death streams originate.

The eye can follow the wide ribbons first. That is often enough to identify the dominant operational story before moving to precise counts.

## Step 4: Create a real-world pathway diagram from the public colon trial data

For a real-world example, we use the public `colon` dataset distributed with `survival`, linked to the adjuvant colon cancer trials reported by Laurie and colleagues and Moertel and colleagues. The original trial papers were not published as Sankey diagrams, so this is a transparent partial application. We use the public patient-level trial data to build a pathway figure with:

1. treatment arm,
2. recurrence status by 3 years,
3. survival status by 5 years.

To keep the pathway definition interpretable, we restrict attention to patients whose recurrence-by-3-years and survival-by-5-years status can be determined from the public follow-up information. That makes the application partial but transparent.

```r
library(survival)

colon_patient <- survival::colon |>
 group_by(id, rx) |>
 summarise(
 recurrence_time = time[etype == 1][1],
 recurrence_status = status[etype == 1][1],
 death_time = time[etype == 2][1],
 death_status = status[etype == 2][1],
.groups = "drop"
 ) |>
 mutate(
 recurrence_3y = ifelse(
 recurrence_status == 1 & recurrence_time <= 1095,
 "Recurrence\nby 3 years",
 ifelse(recurrence_time >= 1095, "No recurrence\nby 3 years", NA)
 ),
 survival_5y = ifelse(
 death_status == 1 & death_time <= 1825,
 "Died by\n5 years",
 ifelse(death_time >= 1825, "Alive at\n5 years", NA)
 ),
 treatment_arm = dplyr::recode(
 as.character(rx),
 "Obs" = "Observation",
 "Lev" = "Levamisole",
 "Lev+5FU" = "Levamisole\n+ 5FU"
 )
 ) |>
 filter(!is.na(recurrence_3y), !is.na(survival_5y))

colon_pathways <- colon_patient |>
 count(treatment_arm, recurrence_3y, survival_5y, name = "n")

colon_summary <- data.frame(
 sample_size = nrow(colon_patient),
 observation = sum(colon_patient$treatment_arm == "Observation"),
 levamisole = sum(colon_patient$treatment_arm == "Levamisole"),
 levamisole_5fu = sum(colon_patient$treatment_arm == "Levamisole\n+ 5FU")
)

colon_top_paths <- colon_pathways |>
 mutate(
 treatment_arm = gsub("\n", " ", treatment_arm),
 recurrence_3y = gsub("\n", " ", recurrence_3y),
 survival_5y = gsub("\n", " ", survival_5y)
 ) |>
 arrange(desc(n)) |>
 slice_head(n = 10)

knitr::kable(
 format_numeric_table(colon_summary, digits = 0),
 caption = "Public colon cancer trial sample used in the Sankey-diagram example"
)

knitr::kable(
 format_numeric_table(colon_top_paths, digits = 0),
 caption = "Largest treatment-to-recurrence-to-survival pathways in the public colon trial data"
)
```

The real-world table shows the pathway counts explicitly, but the visual structure is still hard to absorb from rows alone. That is exactly the problem the Sankey diagram solves.

## Step 5: Draw the real-world Sankey diagram

```r
colon_stage_orders <- list(
 treatment_arm = c("Observation", "Levamisole", "Levamisole\n+ 5FU"),
 recurrence_3y = c("No recurrence\nby 3 years", "Recurrence\nby 3 years"),
 survival_5y = c("Alive at\n5 years", "Died by\n5 years")
)

colon_components <- prepare_sankey_components(
 flows = colon_pathways,
 stage_vars = c("treatment_arm", "recurrence_3y", "survival_5y"),
 stage_orders = colon_stage_orders,
 stage_titles = c("Treatment arm", "Recurrence status", "5-year survival"),
 middle_stage = "recurrence_3y",
 gap = 18
)

colon_palette <- c(
 "No recurrence\nby 3 years" = "#80b1d3",
 "Recurrence\nby 3 years" = "#fb8072"
)

colon_sankey <- draw_sankey_plot(
 colon_components,
 fill_palette = colon_palette,
 title = "A Sankey diagram summarizes patient pathways in the public colon trial data",
 subtitle = "Treatment arm to recurrence by 3 years to survival by 5 years"
)

colon_sankey
```

This is a transparent partial replication rather than a reproduction of a published trial figure. The contribution here is methodological: the public trial data are recast as a pathway diagram so the reader can see how treatment arm, recurrence, and survival relate as sequential categories rather than as separate endpoint tables.

## How to read the figure carefully

Sankey diagrams are visually intuitive, but they can also be misleading if used carelessly. First, they show flows of observed counts, not causal mechanisms. A thick ribbon does not prove that the upstream category caused the downstream outcome. Second, category order matters. Reordering the blocks can make the same data look more or less tangled, so the ordering should reflect a clear substantive logic.

Third, the figure is strongest when the stages are genuinely sequential. A Sankey diagram is much less informative if the columns are only loosely related cross-sections. Finally, pathway diagrams should usually be paired with a table, because readers often want to identify the exact largest pathways after they have seen the overall structure.

## Further reading

For the general layered-graphics logic behind static figures of this kind, Wickham remains the core reference. For alluvial and Sankey-style categorical flow graphics in R, Brunson's formulation is a useful conceptual reference even when the figure is built manually rather than through a dedicated package. For the underlying colon trial data used in the real-world example, see Laurie and colleagues and Moertel and colleagues.

## References

- Wickham, Hadley (2016). "ggplot2: Elegant Graphics for Data Analysis." Springer, New York.
- Brunson, Jason Cory (2020). "ggalluvial: Layered Grammar for Alluvial Plots." *Journal of Open Source Software*, 5(49), 2017. DOI: <https://doi.org/10.21105/joss.02017>.
- Laurie, John A.; Moertel, Charles G.; Fleming, Thomas R.; Wieand, H. S.; Leigh, James E.; Rubin, Joseph; McCormack, G. W.; Gerstner, J. B.; Krook, J. E.; Mailliard, James A. (1989). "Surgical Adjuvant Therapy of Large-Bowel Carcinoma: An Evaluation of Levamisole and the Combination of Levamisole and Fluorouracil." *Journal of Clinical Oncology*, 7(10), 1447--1456. DOI: <https://doi.org/10.1200/JCO.1989.7.10.1447>.
- Moertel, Charles G.; Fleming, Thomas R.; Macdonald, John S.; Haller, Daniel G.; Laurie, John A.; Goodman, Phyllis J.; Ungerleider, James S.; Emerson, William A.; Tormey, Douglas C.; Glick, John H.; Veeder, Michael H.; Mailliard, James A. (1990). "Levamisole and Fluorouracil for Adjuvant Therapy of Resected Colon Carcinoma." *New England Journal of Medicine*, 322(6), 352--358. DOI: <https://doi.org/10.1056/NEJM199002083220602>.
