---
title: "Visualizing a Correlation Matrix"
date: 2026-03-09
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a correlation-matrix heatmap for clinical predictors in the Pima Indian diabetes dataset distributed with `MASS`. The figure is designed to show which variables move together, which ones are..."
excerpt: "Building a clustered heatmap to inspect relationships among predictors"
---
This chapter creates a correlation-matrix heatmap for clinical predictors in the Pima Indian diabetes dataset distributed with `MASS`. The figure is designed to show which variables move together, which ones are nearly unrelated, and where clusters of overlap may create modeling challenges such as multicollinearity. In practice, this kind of figure is often one of the first visual checks before fitting regression models, regularized models, or risk-prediction systems. The underlying dataset comes from the diabetes-prediction application described by Smith and coauthors.

The figure we will build is a reordered correlation matrix shown as a heatmap. Each cell represents the correlation between two variables. The sign tells us the direction of the association, and the magnitude tells us how strong the linear relationship is. The clustering step is important because it places similar variables near each other, which makes the visual pattern much easier to read than a matrix left in arbitrary column order.

## What the visualization is showing

We will use the numeric predictors in the `Pima.tr` data:

`npreg` is the number of pregnancies. `glu` is plasma glucose concentration. `bp` is diastolic blood pressure. `skin` is triceps skin-fold thickness. `bmi` is body mass index. `ped` is the diabetes pedigree function. `age` is age in years.

The correlation matrix will summarize how these variables relate to each other pairwise. The diagonal will always be 1 because each variable is perfectly correlated with itself. Off-diagonal cells are the interesting part. A positive value near 1 indicates that two variables rise together strongly. A value near 0 indicates weak linear association. A negative value indicates that one variable tends to rise as the other falls.

## Step 1: Load the data and keep the numeric predictors

```r
data("Pima.tr", package = "MASS")

pima_numeric <- Pima.tr[, c("npreg", "glu", "bp", "skin", "bmi", "ped", "age")]

pima_summary <- data.frame(
 sample_size = nrow(pima_numeric),
 variables = ncol(pima_numeric),
 mean_glucose = mean(pima_numeric$glu),
 mean_bmi = mean(pima_numeric$bmi),
 mean_age = mean(pima_numeric$age)
)

pima_summary[, c("mean_glucose", "mean_bmi", "mean_age")] <-
 round(pima_summary[, c("mean_glucose", "mean_bmi", "mean_age")], 2)

knitr::kable(
 pima_summary,
 caption = "Summary of the variables used in the correlation heatmap"
)
```

This is a small step, but it matters. Correlation matrices require numeric variables, and it is good practice to be explicit about which variables are going into the figure.

## Step 2: Compute the correlation matrix

```r
cor_mat <- cor(pima_numeric, use = "pairwise.complete.obs")
cor_mat <- round(cor_mat, 2)

knitr::kable(
 cor_mat,
 caption = "Correlation matrix for the Pima diabetes predictors"
)
```

The table is useful, but a table becomes hard to scan once the number of variables grows. That is why the heatmap is valuable. It turns the matrix into a pattern that the eye can read quickly.

## Step 3: Reorder the variables by similarity

To make the heatmap easier to interpret, we reorder the variables using hierarchical clustering based on correlation similarity. Variables with similar correlation profiles will appear close to each other in the final plot.

```r
distance_mat <- as.dist(1 - abs(cor(pima_numeric, use = "pairwise.complete.obs")))
cluster_order <- hclust(distance_mat)$order
ordered_names <- colnames(pima_numeric)[cluster_order]

cor_ordered <- cor_mat[ordered_names, ordered_names]

cor_long <- as.data.frame(as.table(cor_ordered))
names(cor_long) <- c("var_x", "var_y", "correlation")

cor_long$var_x <- factor(cor_long$var_x, levels = ordered_names)
cor_long$var_y <- factor(cor_long$var_y, levels = rev(ordered_names))
```

This step does not change any correlation values. It only changes the order in which they appear. That distinction is important. Clustering is a display tool here, not a new statistical estimate.

## Step 4: Create the heatmap

```r
ggplot2::ggplot(
 cor_long,
 ggplot2::aes(x = var_x, y = var_y, fill = correlation)
) +
 ggplot2::geom_tile(color = "white", linewidth = 0.6) +
 ggplot2::geom_text(
 ggplot2::aes(label = sprintf("%.2f", correlation)),
 size = 3.2,
 color = "black"
 ) +
 ggplot2::scale_fill_gradient2(
 low = "#6b7a8f",
 mid = "#f7f4ed",
 high = "#0b5d4b",
 midpoint = 0,
 limits = c(-1, 1)
 ) +
 ggplot2::labs(
 title = "Correlation matrix of diabetes risk predictors",
 subtitle = "Pima Indian diabetes data, reordered by hierarchical clustering",
 x = NULL,
 y = NULL,
 fill = "Correlation"
 ) +
 ggplot2::theme_minimal(base_size = 12) +
 ggplot2::theme(
 panel.grid = ggplot2::element_blank,
 axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
 aspect.ratio = 1
 )
```

This is the main figure of the chapter. It is academically useful because it combines exact values with visual structure. The color scale tells the reader whether a relationship is weak or strong, and the clustering helps reveal variable groups that share similar association patterns.

## Step 5: Highlight the strongest pairwise relationships

Sometimes the most useful written companion to a correlation heatmap is a short ranked table of the strongest off-diagonal relationships.

```r
upper_index <- upper.tri(cor_ordered, diag = FALSE)

strong_pairs <- data.frame(
 var_1 = rownames(cor_ordered)[row(cor_ordered)[upper_index]],
 var_2 = colnames(cor_ordered)[col(cor_ordered)[upper_index]],
 correlation = cor_ordered[upper_index]
)

strong_pairs$abs_correlation <- abs(strong_pairs$correlation)
strong_pairs <- strong_pairs[order(strong_pairs$abs_correlation, decreasing = TRUE), ]
strong_pairs$correlation <- round(strong_pairs$correlation, 2)

knitr::kable(
 head(strong_pairs[, c("var_1", "var_2", "correlation")], 6),
 caption = "Strongest pairwise correlations in the Pima data"
)
```

This table is especially helpful in methods sections or appendices where the reader may want a compact summary of the strongest dependencies without reading every tile in the matrix.

## How to read the figure carefully

A correlation heatmap is descriptive, not causal. If two variables are strongly correlated, that does not tell us that one causes the other. It only tells us that they move together linearly in the observed sample.

It is also important to remember that Pearson correlation measures linear association. If two variables are related in a strongly nonlinear but monotonic way, the heatmap may understate the real relationship. In those settings, a Spearman correlation matrix can be a useful alternative. Missing data handling matters too. In this example we used pairwise complete observations, which is convenient, but different missing-data strategies can produce slightly different matrices.

Finally, correlation is scale-free but sample-dependent. A pattern seen in one clinical sample may not carry over cleanly to another population. That is why a correlation matrix is best treated as an exploratory and reporting tool rather than as a final inferential result.

## How this figure helps the rest of the book

This kind of figure is useful almost everywhere in the tutorial collection. Before linear or logistic regression, it helps reveal overlapping predictors. Before lasso or ridge, it helps show why shrinkage may be needed. Before simulation work, it can suggest realistic dependence structures. In health economics and decision sciences, it is often one of the simplest ways to communicate the internal structure of a dataset before moving to a more formal model.

Once the template is clear, it can be adapted easily. You can switch from Pearson to Spearman correlation, display only the lower triangle, add clustering dendrograms, use significance masking, or apply the same visual logic to covariance matrices or similarity matrices.

## Further reading

For the real-world prediction problem underlying the dataset used here, Smith and coauthors provide the original diabetes application. A natural next step after this chapter is to compare Pearson and Spearman correlation heatmaps on the same data, or to build a clustered correlation matrix for one of the larger clinical or claims-based datasets used elsewhere in the book.
