---
title: "DAGs"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a directed acyclic graph, or DAG, as a publication-quality figure. The goal is not to estimate a treatment effect directly, but to make causal assumptions visible in a way that readers can inspect..."
excerpt: "Building a polished directed acyclic graph to communicate causal structure"
---
This chapter builds a directed acyclic graph, or DAG, as a publication-quality figure. The goal is not to estimate a treatment effect directly, but to make causal assumptions visible in a way that readers can inspect quickly. A good DAG is useful because it separates different roles that variables can play in a study design: exposure, outcome, confounders, mediators, colliders, and other background causes. Greenland, Pearl, and Robins explain why that distinction matters in epidemiology, while `dagitty` and `ggdag` make it practical to compute adjustment sets and turn the graph into a clean, readable figure;;.

The specific figure we will build is a role-highlighted DAG. Instead of drawing all nodes in the same style, we will color the exposure, outcome, adjustment variables, and variables that should not be conditioned on. That makes the figure more useful in teaching, methods appendices, and applied empirical papers where the reader needs to understand the identification strategy before looking at any regression table.

## What the visualization is showing

A DAG figure uses nodes to represent variables and arrows to represent assumed direct causal relationships. The graph is acyclic, which means no path can follow arrow directions and return to the same node.

This figure is useful when:

1. the analyst needs to communicate a causal design clearly,
2. the adjustment strategy is part of the substantive argument,
3. the audience needs to distinguish confounders from mediators or colliders.

The main reading rule is simple. Follow the arrows as statements about causal direction, not as statements about statistical significance. Then use the node colors to see which variables belong to the exposure, the outcome, the intended adjustment set, or variables that should be left out of a causal adjustment model.

## Step 1: Create a synthetic DAG with clearly labeled node roles

We begin with a synthetic hospital readmission example. The research question is whether a post-discharge program reduces 30-day readmission. Age, chronic burden, and neighborhood deprivation are confounders that should be adjusted for. Medication adherence lies on the causal pathway, so it is a mediator. Observed follow-up is a collider because it is affected both by the program and by unmeasured clinician concern. This is a good teaching example because the figure needs to show not only the causal arrows, but also which variables belong to different analytic roles.

```r
library(dplyr)
library(ggplot2)
library(knitr)
library(dagitty)
library(ggdag)
library(MASS)
library(grid)

format_numeric_table <- function(df, digits = 3) {
 numeric_cols <- vapply(df, is.numeric, logical(1))
 df[numeric_cols] <- lapply(df[numeric_cols], round, digits = digits)
 df
}

flatten_label <- function(x) {
 gsub("\n", " ", x, fixed = TRUE)
}

build_adjustment_table <- function(dag, label_map = NULL) {
 adjustment_sets <- dagitty::adjustmentSets(dag)

 if (length(adjustment_sets) == 0) {
 return(
 data.frame(
 set = "None",
 variables = "No valid measured adjustment set identified"
 )
 )
 }

 pretty_label <- function(nodes) {
 if (is.null(label_map)) {
 return(nodes)
 }

 flatten_label(unname(label_map[nodes]))
 }

 data.frame(
 set = paste("Set", seq_along(adjustment_sets)),
 variables = vapply(
 adjustment_sets,
 function(x) paste(pretty_label(x), collapse = ", "),
 character(1)
 )
 )
}

build_role_table <- function(role_map, label_map) {
 data.frame(
 node = flatten_label(unname(label_map[names(role_map)])),
 role = unname(role_map),
 stringsAsFactors = FALSE
 )
}

prepare_dag_plot_data <- function(dag, role_map, label_map) {
 tidy_dag <- ggdag::tidy_dagitty(dag)$data

 nodes <- tidy_dag |>
 distinct(name, x, y) |>
 mutate(
 role = unname(role_map[name]),
 label = unname(label_map[name])
 )

 edges <- tidy_dag |>
 filter(!is.na(to)) |>
 mutate(
 dx = xend - x,
 dy = yend - y,
 distance = sqrt(dx^2 + dy^2),
 x = x + dx / distance * 0.10,
 y = y + dy / distance * 0.10,
 xend = xend - dx / distance * 0.20,
 yend = yend - dy / distance * 0.20
 )

 list(nodes = nodes, edges = edges)
}

plot_dag <- function(plot_data, title, subtitle) {
 role_levels <- c(
 "Exposure",
 "Outcome",
 "Adjust for confounding",
 "Mediator",
 "Collider / avoid adjustment",
 "Other observed cause",
 "Unmeasured cause"
 )

 role_palette <- c(
 "Exposure" = "#7fc97f",
 "Outcome" = "#fdc086",
 "Adjust for confounding" = "#8da0cb",
 "Mediator" = "#66c2a5",
 "Collider / avoid adjustment" = "#f4a3c4",
 "Other observed cause" = "#ffd92f",
 "Unmeasured cause" = "#bdbdbd"
 )

 plot_data$nodes$role <- factor(plot_data$nodes$role, levels = role_levels)

 ggplot +
 geom_segment(
 data = plot_data$edges,
 aes(x = x, y = y, xend = xend, yend = yend),
 linewidth = 0.7,
 color = "#4d4d4d",
 lineend = "round",
 arrow = arrow(length = unit(0.16, "cm"), type = "closed")
 ) +
 geom_label(
 data = plot_data$nodes,
 aes(x = x, y = y, label = label, fill = role),
 size = 3.1,
 fontface = "bold",
 linewidth = 0.28,
 label.padding = unit(0.18, "lines"),
 label.r = unit(0.12, "lines"),
 color = "#1f1f1f"
 ) +
 scale_fill_manual(values = role_palette, drop = TRUE) +
 coord_equal(clip = "off") +
 labs(
 title = title,
 subtitle = subtitle,
 fill = NULL
 ) +
 theme_void(base_size = 12) +
 theme(
 legend.position = "bottom",
 legend.text = element_text(size = 10),
 plot.title = element_text(face = "bold", size = 14, hjust = 0),
 plot.subtitle = element_text(size = 11, hjust = 0, margin = margin(b = 12)),
 plot.margin = margin(10, 20, 10, 10)
 ) +
 guides(
 fill = guide_legend(
 nrow = 2,
 byrow = TRUE,
 override.aes = list(label = "", size = 5)
 )
 )
}
```

```r
synthetic_dag <- dagitty::dagitty(
 "dag {
 Age -> Program
 Age -> Readmit
 ChronicBurden -> Program
 ChronicBurden -> Readmit
 NeighborhoodDeprivation -> Program
 NeighborhoodDeprivation -> Readmit
 Program -> Adherence
 Adherence -> Readmit
 Program -> ObservedFollowup
 ClinicianConcern -> ObservedFollowup
 ClinicianConcern -> Readmit
 }"
)

dagitty::coordinates(synthetic_dag) <- list(
 x = c(
 Age = 0.0,
 ChronicBurden = 0.0,
 NeighborhoodDeprivation = 0.0,
 Program = 1.2,
 Adherence = 2.2,
 ObservedFollowup = 2.2,
 ClinicianConcern = 1.2,
 Readmit = 3.4
 ),
 y = c(
 Age = 1.3,
 ChronicBurden = 0.3,
 NeighborhoodDeprivation = -0.7,
 Program = 0.3,
 Adherence = 1.3,
 ObservedFollowup = -0.7,
 ClinicianConcern = -1.6,
 Readmit = 0.3
 )
)

dagitty::exposures(synthetic_dag) <- "Program"
dagitty::outcomes(synthetic_dag) <- "Readmit"

synthetic_labels <- c(
 Age = "Age",
 ChronicBurden = "Chronic\nburden",
 NeighborhoodDeprivation = "Neighborhood\ndeprivation",
 Program = "Post-discharge\nprogram",
 Adherence = "Medication\nadherence",
 ObservedFollowup = "Observed\nfollow-up",
 ClinicianConcern = "Clinician\nconcern\n(unmeasured)",
 Readmit = "30-day\nreadmission"
)

synthetic_roles <- c(
 Age = "Adjust for confounding",
 ChronicBurden = "Adjust for confounding",
 NeighborhoodDeprivation = "Adjust for confounding",
 Program = "Exposure",
 Adherence = "Mediator",
 ObservedFollowup = "Collider / avoid adjustment",
 ClinicianConcern = "Unmeasured cause",
 Readmit = "Outcome"
)

synthetic_role_table <- build_role_table(synthetic_roles, synthetic_labels)
synthetic_adjustment_table <- build_adjustment_table(synthetic_dag, synthetic_labels)

knitr::kable(
 synthetic_role_table,
 caption = "Node roles highlighted in the synthetic DAG figure"
)

knitr::kable(
 synthetic_adjustment_table,
 caption = "Minimal measured adjustment set implied by the synthetic DAG"
)
```

The two tables make the figure easier to read. The role table tells the reader what the colors mean. The adjustment table makes the design implication explicit: if the target is the total effect of the program on readmission, the graph suggests adjusting for the confounders but not for the mediator or the collider.

## Step 2: Build the synthetic DAG figure

```r
synthetic_plot_data <- prepare_dag_plot_data(
 dag = synthetic_dag,
 role_map = synthetic_roles,
 label_map = synthetic_labels
)

plot_dag(
 synthetic_plot_data,
 title = "A role-highlighted DAG separates confounders, mediators, and colliders",
 subtitle = "Synthetic post-discharge program example"
)
```

This is the core figure of the chapter. A good DAG figure should communicate three things at once:

1. the assumed causal direction of the arrows,
2. the relative location of the exposure and outcome,
3. the different analytic roles of the remaining variables.

The main improvement over a generic black-and-white DAG is that the reader can see immediately which nodes are intended for adjustment and which nodes should be left out of a causal adjustment model. That is the main reason to build a polished figure instead of a quick sketch.

## Step 3: Create a real-world DAG for maternal smoking and low birth weight

For a real-world example, we use the public `birthwt` data distributed with `MASS`. The application is the familiar question of whether maternal smoking contributes to low birth weight. This is not a literal reproduction of a published figure. It is a transparent teaching diagram built around a real epidemiologic setting and a public dataset, with the graph structure motivated by standard DAG reasoning in observational health research.

The public data give us observed variables such as maternal age, maternal weight, race, prior premature labor, hypertension, uterine irritability, smoking status, and low birth weight. The DAG will emphasize the variables most relevant for communication: smoking as the exposure, low birth weight as the outcome, three background confounders, and several additional observed causes of the outcome.

```r
data("birthwt", package = "MASS")

birthwt <- birthwt |>
 mutate(
 smoke = factor(smoke, levels = c(0, 1), labels = c("No", "Yes")),
 low = factor(low, levels = c(0, 1), labels = c("No", "Yes")),
 race = factor(race, levels = c(1, 2, 3), labels = c("White", "Black", "Other")),
 ht = factor(ht, levels = c(0, 1), labels = c("No", "Yes")),
 ui = factor(ui, levels = c(0, 1), labels = c("No", "Yes"))
 )

birthwt_profile <- birthwt |>
 group_by(smoke) |>
 summarise(
 n = n,
 mean_age = mean(age),
 mean_maternal_weight = mean(lwt),
 low_birthweight_rate = mean(low == "Yes"),
.groups = "drop"
 )

knitr::kable(
 format_numeric_table(birthwt_profile, digits = 2),
 caption = "Observed profile of the public birthwt data by maternal smoking status"
)
```

The table is descriptive, not causal. Its role is to anchor the example in a real dataset before we draw the DAG. The graph itself will summarize the assumed relationships that an analyst might want to communicate in an appendix or methods section.

```r
birthwt_dag <- dagitty::dagitty(
 "dag {
 Age -> Smoking
 Age -> LowBirthweight
 MaternalWeight -> Smoking
 MaternalWeight -> LowBirthweight
 Race -> Smoking
 Race -> LowBirthweight
 Smoking -> LowBirthweight
 Hypertension -> LowBirthweight
 PriorPrematurity -> LowBirthweight
 UterineIrritability -> LowBirthweight
 }"
)

dagitty::coordinates(birthwt_dag) <- list(
 x = c(
 Age = 0.0,
 MaternalWeight = 0.0,
 Race = 0.0,
 Smoking = 1.3,
 Hypertension = 2.3,
 PriorPrematurity = 2.3,
 UterineIrritability = 2.3,
 LowBirthweight = 3.6
 ),
 y = c(
 Age = 1.2,
 MaternalWeight = 0.1,
 Race = -1.0,
 Smoking = 0.1,
 Hypertension = 1.2,
 PriorPrematurity = 0.1,
 UterineIrritability = -1.0,
 LowBirthweight = 0.1
 )
)

dagitty::exposures(birthwt_dag) <- "Smoking"
dagitty::outcomes(birthwt_dag) <- "LowBirthweight"

birthwt_labels <- c(
 Age = "Maternal\nage",
 MaternalWeight = "Maternal\nweight",
 Race = "Race",
 Smoking = "Maternal\nsmoking",
 Hypertension = "Chronic\nhypertension",
 PriorPrematurity = "Prior premature\nlabor",
 UterineIrritability = "Uterine\nirritability",
 LowBirthweight = "Low birth\nweight"
)

birthwt_roles <- c(
 Age = "Adjust for confounding",
 MaternalWeight = "Adjust for confounding",
 Race = "Adjust for confounding",
 Smoking = "Exposure",
 Hypertension = "Other observed cause",
 PriorPrematurity = "Other observed cause",
 UterineIrritability = "Other observed cause",
 LowBirthweight = "Outcome"
)

birthwt_adjustment_table <- build_adjustment_table(birthwt_dag, birthwt_labels)

knitr::kable(
 birthwt_adjustment_table,
 caption = "Minimal measured adjustment set implied by the smoking and low-birth-weight DAG"
)
```

## Step 4: Draw the real-world DAG figure

```r
birthwt_plot_data <- prepare_dag_plot_data(
 dag = birthwt_dag,
 role_map = birthwt_roles,
 label_map = birthwt_labels
)

plot_dag(
 birthwt_plot_data,
 title = "A DAG can communicate a birth-outcomes design more clearly than a variable list",
 subtitle = "Public birthwt data used as a real-world smoking and low-birth-weight application"
)
```

This real-world figure does two useful things. First, it places the exposure and outcome at the center of the design question. Second, it separates variables that mainly close back-door paths from variables that are additional predictors of the outcome. That distinction is often lost when all baseline variables are presented as one undifferentiated covariate list.

## How to read the figure carefully

The most important caution is that a DAG is a visual statement of assumptions, not proof that those assumptions are correct. A clean figure can still represent a wrong scientific story. The value of the DAG is that it makes the story explicit enough to debate.

It is also important to remember that node placement is communicative, not statistical. Putting confounders to the left of the exposure and extra outcome causes to the right helps readers interpret the figure, even though the coordinates themselves do not carry causal meaning. Good layout choices reduce cognitive effort.

Finally, a DAG figure should not try to encode every possible variable in a study. The best diagrams are selective. They include the variables needed to understand the identification strategy and omit unnecessary clutter. In practice, that usually means highlighting the exposure, the outcome, the intended adjustment set, and any variables whose role could easily be misunderstood.

## Further reading

For the theory behind DAGs, the classic starting points are Pearl and the epidemiologic synthesis by Greenland, Pearl, and Robins. For practical computation of adjustment sets and implied independencies, `dagitty` remains the most useful entry point. For readers who want a polished plotting workflow in R, `ggdag` provides a convenient bridge from causal diagrams to publication-ready graphics.
