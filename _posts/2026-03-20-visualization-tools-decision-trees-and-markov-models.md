---
title: "Decision Trees and Markov Models"
date: 2026-03-20
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter shows how to build a decision-analytic model schematic rather than a statistical results plot. The figure we will create is a two-panel diagram: a short-term decision tree on the left and a long-run..."
excerpt: "Drawing a decision-analytic model schematic for short-term branches and long-run state transitions"
---
This chapter shows how to build a decision-analytic model schematic rather than a statistical results plot. The figure we will create is a two-panel diagram: a short-term decision tree on the left and a long-run Markov state-transition diagram on the right. This is a useful visualization because many health-economic models have exactly that architecture. An acute treatment choice is represented with a decision tree, and downstream recurring outcomes are represented with a Markov process. Sonnenberg and Beck explain why state-transition models became central in medical decision making, while Briggs and Sculpher show why Markov structures are so common in health economic evaluation.

The point of the figure is not to present parameter estimates. It is to make model structure legible. A reader who cannot see the branching logic, health states, and transition pathways will struggle to understand the economic model no matter how polished the cost-effectiveness tables look.

## What the visualization is showing

The visualization has two linked panels.

1. The left panel is a decision tree. It shows a one-off choice among strategies and the immediate short-run pathways that follow.
2. The right panel is a Markov state diagram. It shows the health states entered after the initial decision and the transitions that can repeat over cycles.

This type of figure is useful when:

1. the model combines an acute decision with longer-run disease progression,
2. the analyst needs to communicate structure before presenting results,
3. the audience includes readers who may not infer the model architecture from equations or code alone.

The key reading rule is simple. Follow the tree from left to right for initial branching decisions. Then read the Markov panel as a state diagram in which arrows show which transitions are allowed from one cycle to the next.

## Step 1: Build the synthetic decision tree data

We begin with a synthetic hospital-discharge decision problem. The acute decision is whether to use usual discharge planning or an enhanced follow-up pathway. Short-run outcomes are readmission or no readmission, and the enhanced pathway then feeds into a simple long-run recovery model.

```r
library(dplyr)
library(ggplot2)
library(knitr)
library(patchwork)

format_numeric_table <- function(df, digits = 3) {
 numeric_cols <- vapply(df, is.numeric, logical(1))
 df[numeric_cols] <- lapply(df[numeric_cols], round, digits = digits)
 df
}

draw_decision_tree <- function(nodes, edges, title, subtitle = NULL) {
 ggplot +
 geom_segment(
 data = edges,
 aes(x = x, y = y, xend = xend, yend = yend),
 linewidth = 0.9,
 color = "#5b6770",
 arrow = arrow(length = grid::unit(0.08, "inches"), type = "closed")
 ) +
 geom_text(
 data = edges,
 aes(x = label_x, y = label_y, label = label),
 size = 3.1,
 color = "#4d4d4d"
 ) +
 geom_label(
 data = nodes,
 aes(x = x, y = y, label = label, fill = fill, color = text_color),
 linewidth = 0.25,
 label.r = grid::unit(0.15, "lines"),
 label.padding = grid::unit(0.22, "lines"),
 size = 3.3,
 fontface = "bold",
 show.legend = FALSE
 ) +
 scale_fill_identity +
 scale_color_identity +
 coord_cartesian(xlim = c(-0.2, 5.2), ylim = c(-0.5, 5.8), clip = "off") +
 labs(
 title = title,
 subtitle = subtitle
 ) +
 theme_void(base_size = 12) +
 theme(
 plot.title = element_text(face = "bold", size = 13),
 plot.subtitle = element_text(size = 10, color = "#4d4d4d"),
 plot.margin = margin(10, 10, 10, 10)
 )
}

draw_markov_diagram <- function(states, transitions, title, subtitle = NULL) {
 ggplot +
 geom_curve(
 data = subset(transitions, curvature > 0),
 aes(x = x, y = y, xend = xend, yend = yend),
 curvature = 0.35,
 linewidth = 0.9,
 color = "#5b6770",
 arrow = arrow(length = grid::unit(0.08, "inches"), type = "closed")
 ) +
 geom_curve(
 data = subset(transitions, curvature < 0),
 aes(x = x, y = y, xend = xend, yend = yend),
 curvature = -0.15,
 linewidth = 0.9,
 color = "#5b6770",
 arrow = arrow(length = grid::unit(0.08, "inches"), type = "closed")
 ) +
 geom_segment(
 data = subset(transitions, curvature == 0),
 aes(x = x, y = y, xend = xend, yend = yend),
 linewidth = 0.9,
 color = "#5b6770",
 arrow = arrow(length = grid::unit(0.08, "inches"), type = "closed")
 ) +
 geom_text(
 data = transitions,
 aes(x = label_x, y = label_y, label = label),
 size = 3.0,
 color = "#4d4d4d"
 ) +
 geom_label(
 data = states,
 aes(x = x, y = y, label = label, fill = fill, color = text_color),
 linewidth = 0.25,
 label.r = grid::unit(0.15, "lines"),
 label.padding = grid::unit(0.24, "lines"),
 size = 3.4,
 fontface = "bold",
 show.legend = FALSE
 ) +
 scale_fill_identity +
 scale_color_identity +
 coord_cartesian(xlim = c(-0.2, 4.8), ylim = c(-0.3, 4.3), clip = "off") +
 labs(
 title = title,
 subtitle = subtitle
 ) +
 theme_void(base_size = 12) +
 theme(
 plot.title = element_text(face = "bold", size = 13),
 plot.subtitle = element_text(size = 10, color = "#4d4d4d"),
 plot.margin = margin(10, 10, 10, 10)
 )
}
```

```r
synthetic_tree_nodes <- data.frame(
 x = c(0, 2, 2, 4.2, 4.2, 4.2, 4.2),
 y = c(2.5, 4.3, 0.9, 5.2, 3.4, 1.8, 0.0),
 label = c(
 "Choose\npathway",
 "Usual\ncare",
 "Enhanced\nfollow-up",
 "Readmit",
 "No\nreadmit",
 "Readmit",
 "No\nreadmit"
 ),
 fill = c("#08519c", "#6baed6", "#6baed6", "#fdd0a2", "#fdd0a2", "#fdd0a2", "#fdd0a2"),
 text_color = c("white", "black", "black", "black", "black", "black", "black")
)

synthetic_tree_edges <- data.frame(
 x = c(0.35, 0.35, 2.35, 2.35, 2.35, 2.35),
 y = c(2.7, 2.3, 4.45, 4.10, 1.05, 0.75),
 xend = c(1.65, 1.65, 3.8, 3.8, 3.8, 3.8),
 yend = c(4.1, 1.1, 5.1, 3.5, 1.9, 0.1),
 label = c("55%", "45%", "p = 0.22", "p = 0.78", "p = 0.12", "p = 0.88"),
 label_x = c(0.95, 0.95, 3.05, 3.05, 3.05, 3.05),
 label_y = c(4.55, 1.55, 5.35, 3.85, 2.25, 0.45)
)

synthetic_tree_table <- data.frame(
 branch = c(
 "Usual care -> Readmit",
 "Usual care -> No readmit",
 "Enhanced follow-up -> Readmit",
 "Enhanced follow-up -> No readmit"
 ),
 probability = c(0.22, 0.78, 0.12, 0.88),
 short_run_cost = c(14000, 4200, 13500, 5100)
)

knitr::kable(
 format_numeric_table(synthetic_tree_table, digits = 2),
 caption = "Short-run branches used in the synthetic decision tree"
)
```

## Step 2: Draw the synthetic decision tree panel

```r
synthetic_tree_plot <- draw_decision_tree(
 synthetic_tree_nodes,
 synthetic_tree_edges,
 title = "Synthetic decision tree",
 subtitle = "Short-run hospital-discharge pathways"
)

synthetic_tree_plot
```

This is the first half of the figure. The reader can already see the initial decision, the branching structure, and the immediate outcomes. But if the model also includes recurring long-run outcomes, a tree alone is not enough.

## Step 3: Build the synthetic Markov state diagram

Now we add a simple Markov state diagram for long-run follow-up after discharge. The states are stable recovery, post-readmission, and death.

```r
synthetic_markov_states <- data.frame(
 x = c(1.1, 3.2, 3.2),
 y = c(2.0, 3.2, 0.8),
 label = c("Stable\nrecovery", "Post-\nreadmission", "Death"),
 fill = c("#74c476", "#9ecae1", "#d7301f"),
 text_color = c("black", "black", "white")
)

synthetic_markov_transitions <- data.frame(
 x = c(1.55, 2.55, 1.55, 2.75, 2.75, 3.55, 1.1),
 y = c(2.15, 2.95, 1.85, 2.75, 2.95, 0.95, 1.55),
 xend = c(2.75, 1.55, 2.75, 1.55, 3.05, 3.05, 1.1),
 yend = c(2.95, 2.15, 0.95, 1.85, 1.00, 3.05, 2.45),
 curvature = c(0.12, 0.12, -0.12, -0.12, 0.00, 0.35, 0.45),
 label = c("p_SR", "p_RS", "p_SD", "p_RS2", "p_RD", "stay", "stay"),
 label_x = c(2.15, 2.10, 2.20, 2.15, 3.05, 3.70, 0.55),
 label_y = c(3.25, 2.55, 1.10, 1.40, 1.95, 3.55, 2.85)
)

synthetic_markov_table <- data.frame(
 from = c("Stable recovery", "Stable recovery", "Post-readmission", "Post-readmission", "Death"),
 to = c("Post-readmission", "Death", "Stable recovery", "Death", "Death"),
 example_transition_probability = c(0.15, 0.03, 0.55, 0.08, 1.00)
)

knitr::kable(
 format_numeric_table(synthetic_markov_table, digits = 2),
 caption = "Illustrative transition structure for the synthetic Markov panel"
)
```

## Step 4: Draw the full synthetic decision-analytic schematic

```r
synthetic_markov_plot <- draw_markov_diagram(
 synthetic_markov_states,
 synthetic_markov_transitions,
 title = "Synthetic Markov model",
 subtitle = "Long-run state transitions after the acute decision"
)

synthetic_schematic <- synthetic_tree_plot + synthetic_markov_plot +
 plot_layout(widths = c(1.2, 1)) +
 plot_annotation(
 title = "A decision-analytic schematic can show short-run branching and long-run recurrence in one figure",
 subtitle = "Decision tree on the left, Markov state diagram on the right"
 )

synthetic_schematic
```

This is the core visualization pattern. The left panel clarifies the one-time branching logic. The right panel clarifies what happens afterward over repeated cycles. Together they tell the reader much more than either panel could alone.

## Step 5: Create a real-world decision-analytic schematic from a published health-economic application

For a real-world example, we build a partial published-inspired schematic based on the hip-replacement modeling literature by Briggs and colleagues and the broader Markov-modeling framework described by Briggs and Sculpher and by Sonnenberg and Beck. The goal is not to reproduce the authors' exact final diagram pixel for pixel. The goal is to recreate the model architecture transparently from the published health-economic problem: an initial prosthesis choice followed by longer-run revision and mortality states.

This replication is therefore partial. It reconstructs the decision-model structure from the published problem description rather than reproducing the full original analysis or all underlying parameters.

```r
hip_tree_nodes <- data.frame(
 x = c(0, 2, 2, 4.2, 4.2, 4.2, 4.2),
 y = c(2.5, 4.3, 0.9, 5.2, 3.4, 1.8, 0.0),
 label = c(
 "Select\nprosthesis",
 "Charnley",
 "Spectron",
 "Enter\nMarkov\ncohort",
 "Perioperative\ndeath",
 "Enter\nMarkov\ncohort",
 "Perioperative\ndeath"
 ),
 fill = c("#08519c", "#6baed6", "#6baed6", "#74c476", "#d7301f", "#74c476", "#d7301f"),
 text_color = c("white", "black", "black", "black", "white", "black", "white")
)

hip_tree_edges <- data.frame(
 x = c(0.35, 0.35, 2.35, 2.35, 2.35, 2.35),
 y = c(2.7, 2.3, 4.45, 4.10, 1.05, 0.75),
 xend = c(1.65, 1.65, 3.8, 3.8, 3.8, 3.8),
 yend = c(4.1, 1.1, 5.1, 3.5, 1.9, 0.1),
 label = c("Option A", "Option B", "survive surgery", "peri-op death", "survive surgery", "peri-op death"),
 label_x = c(0.95, 0.95, 3.05, 3.05, 3.05, 3.05),
 label_y = c(4.55, 1.55, 5.35, 3.85, 2.25, 0.45)
)

hip_markov_states <- data.frame(
 x = c(1.0, 3.1, 3.1, 1.0),
 y = c(3.1, 3.1, 1.0, 1.0),
 label = c("Primary\nTHR", "Revision", "Post-\nrevision", "Death"),
 fill = c("#74c476", "#9ecae1", "#c6dbef", "#d7301f"),
 text_color = c("black", "black", "black", "white")
)

hip_markov_transitions <- data.frame(
 x = c(1.45, 2.65, 3.10, 2.70, 2.65, 1.45, 0.95, 1.05),
 y = c(3.10, 3.10, 2.70, 1.35, 2.95, 2.65, 1.35, 3.45),
 xend = c(2.65, 1.45, 3.10, 2.70, 0.95, 0.95, 1.95, 1.90),
 yend = c(3.10, 3.10, 1.40, 2.75, 1.10, 1.10, 1.00, 3.45),
 curvature = c(0.10, 0.10, 0.35, -0.15, 0.00, -0.10, 0.45, 0.45),
 label = c("revision", "back", "stay", "re-revision", "mortality", "mortality", "stay", "stay"),
 label_x = c(2.05, 2.05, 3.60, 2.85, 1.80, 1.20, 0.35, 1.55),
 label_y = c(3.45, 2.75, 2.05, 2.10, 1.85, 1.75, 0.55, 3.85)
)

hip_model_table <- data.frame(
 component = c(
 "Initial decision",
 "Short-run terminal branch",
 "Long-run Markov states",
 "Recurring event of interest"
 ),
 published_inspired_structure = c(
 "Choice between prosthesis strategies",
 "Perioperative death versus entry to follow-up cohort",
 "Primary THR, Revision, Post-revision, Death",
 "Revision surgery and subsequent survival states"
 )
)

knitr::kable(
 hip_model_table,
 caption = "Published-inspired model components in the hip-replacement schematic"
)
```

```r
hip_tree_plot <- draw_decision_tree(
 hip_tree_nodes,
 hip_tree_edges,
 title = "Published-inspired decision tree",
 subtitle = "Initial prosthesis choice and perioperative outcomes"
)

hip_markov_plot <- draw_markov_diagram(
 hip_markov_states,
 hip_markov_transitions,
 title = "Published-inspired Markov model",
 subtitle = "Long-run revision and survival states"
)

hip_schematic <- hip_tree_plot + hip_markov_plot +
 plot_layout(widths = c(1.2, 1)) +
 plot_annotation(
 title = "Decision tree plus Markov diagram for a published hip-replacement modeling problem",
 subtitle = "Partial schematic reconstruction based on Briggs and colleagues' decision-analytic setting"
 )

hip_schematic
```

The real-world figure demonstrates the practical point of this chapter. Decision-analytic models are often easier to trust when their architecture is visible. A reader can see where the initial one-off decision ends and where recurrent long-run states begin.

## How to read the figure carefully

These schematics are not parameter tables. Their purpose is structural clarity, not numerical completeness. The most important reading question is whether the figure helps the reader understand the model's logic: what happens once, what repeats, which health states exist, and which transitions are allowed.

A second point is that not every arrow should be interpreted as equally likely. The figure communicates allowable pathways, not necessarily their magnitude. Probabilities and costs usually belong in companion tables or in the model code itself.

A third point is that these figures should be honest about simplification. If a published model contains tunnel states, age-dependent transition risks, or subgroup-specific branches, a small chapter figure may reasonably omit some detail. But the omitted detail should not change the reader's understanding of the model's essential architecture.

## Further reading

Sonnenberg and Beck remain a foundational guide to why Markov models became important in medical decision making. Briggs and Sculpher provide a classic health-economic introduction to state-transition models. For a concrete applied setting, Briggs and colleagues' hip-replacement analysis is a useful reminder that decision-analytic diagrams are often the fastest way to explain a cost-effectiveness model before turning to its results.

## References

- Sonnenberg, Frank A.; Beck, J. Robert (1993). "Markov Models in Medical Decision Making: A Practical Guide." *Medical Decision Making*, 13(4), 322--338. DOI: <https://doi.org/10.1177/0272989X9301300409>.
- Briggs, Andrew; Sculpher, Mark (1998). "An Introduction to Markov Modelling for Economic Evaluation." *Pharmacoeconomics*, 13(4), 397--409. DOI: <https://doi.org/10.2165/00019053-199813040-00003>.
- Briggs, Andrew; Sculpher, Mark; Britton, Andrew; Murray, David; Fitzpatrick, Ray (1998). "The Costs and Benefits of Primary Total Hip Replacement: How Likely Are New Prostheses to Be Cost-Effective?." *International Journal of Technology Assessment in Health Care*, 14(4), 743--761. DOI: <https://doi.org/10.1017/S0266462300012058>.
- Hunink, M. G. Myriam; Weinstein, Milton C.; Wittenberg, Eve; Drummond, Michael F.; Pliskin, Joseph S.; Wong, John B.; Glasziou, Paul P. (2014). "Decision Making in Health and Medicine: Integrating Evidence and Values." Cambridge University Press, Cambridge.
