---
title: "Simulating Difference-in-Differences Data"
date: 2026-03-19
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic panel dataset in which a subset of hospitals adopts a policy after a known implementation date, so the natural estimator is difference-in-differences. The design is inspired by..."
excerpt: "Creating a synthetic panel dataset with a known policy effect under parallel trends"
---
This chapter creates a synthetic panel dataset in which a subset of hospitals adopts a policy after a known implementation date, so the natural estimator is difference-in-differences. The design is inspired by policy-evaluation settings such as Card and Krueger's minimum-wage comparison and the large DiD literature that followed. The synthetic version here is not a replication of labor-market data. Instead, it creates a hospital-panel setting in which a care-coordination reform is introduced in treated hospitals after year 4, while untreated hospitals provide the comparison trend. That makes it useful for checking whether a fitted DiD model can recover the true treatment effect when the parallel-trends assumption is built into the data-generating process.

The practical reason to simulate DiD data is that policy analysis is often about changes over time, not only differences in levels. Simulation lets the analyst write down the untreated trend, the treatment timing, the adoption group, and the policy effect explicitly before fitting the estimator.

## What variables will be created

The synthetic sample will represent hospitals observed annually over an eight-year period. `hospital` will index the hospitals. `year` will index calendar time. `treated_hospital` will indicate whether the hospital eventually adopts the policy. `post` will indicate whether the observation occurs after policy introduction. `did_treatment` will equal one only for treated hospitals in post-policy years. The outcome `avoidable_ed` will measure avoidable emergency department visits per 1,000 discharges.

These variables reproduce the essential structure of a two-group panel DiD design: group membership, time, treatment timing, and an outcome that evolves over time.

## The data-generating process

The untreated outcome follows

$$
Y_{it}(0) = \alpha_i + \lambda_t + \varepsilon_{it},
$$

where $\alpha_i$ is a hospital fixed effect and $\lambda_t$ is a common time trend. The treatment effect enters only for treated hospitals after the policy begins:

$$
Y_{it}(1) = Y_{it}(0) + \tau.
$$

The observed outcome is

$$
Y_{it} = Y_{it}(0) + \tau D_{it},
$$

where

$$
D_{it} = \mathbb{1}(\text{treated hospital}) \times \mathbb{1}(\text{post period}).
$$

For this simulation, the policy effect is

$$
\tau = -4,
$$

meaning the reform lowers avoidable emergency department visits by 4 visits per 1,000 discharges.

The key identifying assumption is built into the DGP by construction: in the absence of treatment, the treated and untreated hospitals follow parallel trends over time. Baseline levels are allowed to differ through hospital fixed effects, but untreated time trends are common.

## Step 1: Generate the synthetic panel

``` r
set.seed(2026)

n_hospitals <- 80
n_years <- 8

hospital_id <- rep(seq_len(n_hospitals), each = n_years)
year_num <- rep(seq_len(n_years), times = n_hospitals)

treated_hospital <- ifelse(hospital_id <= n_hospitals / 2, 1, 0)
post <- ifelse(year_num >= 5, 1, 0)
did_treatment <- treated_hospital * post

hospital_fe <- rep(rnorm(n_hospitals, mean = 0, sd = 5.5), each = n_years)
time_trend <- rep(seq(0, -6.5, length.out = n_years), times = n_hospitals)

true_effect <- -4
avoidable_ed <- 46 +
 hospital_fe +
 time_trend +
 true_effect * did_treatment +
 rnorm(n_hospitals * n_years, mean = 0, sd = 2.6)

synthetic_did <- data.frame(
 hospital = factor(hospital_id),
 year = factor(year_num),
 year_num,
 treated_hospital,
 post,
 did_treatment,
 avoidable_ed
)

simulation_summary <- data.frame(
 hospitals = n_hospitals,
 years = n_years,
 treated_share = mean(unique(treated_hospital)),
 mean_outcome = mean(synthetic_did$avoidable_ed),
 sd_outcome = stats::sd(synthetic_did$avoidable_ed)
)

simulation_summary[, c("treated_share", "mean_outcome", "sd_outcome")] <-
 round(simulation_summary[, c("treated_share", "mean_outcome", "sd_outcome")], 3)

knitr::kable(
 simulation_summary,
 caption = "Summary of the synthetic difference-in-differences panel"
)
```

Table: Summary of the synthetic difference-in-differences panel

| hospitals| years| treated_share| mean_outcome| sd_outcome|
|---------:|-----:|-------------:|------------:|----------:|
| 80| 8| 0.5| 41.391| 6.665|

The panel now contains two ingredients that matter for DiD. First, treated and untreated hospitals have different baseline levels because of hospital fixed effects. Second, untreated trends move in parallel over time because the same calendar trend applies to both groups before the policy begins.

## Step 2: Fit the model that matches the true generating process

The natural recovery check is a two-way fixed-effects DiD regression. For context, it is also useful to compare that estimate with a naive post-period comparison.

``` r
extract_clustered_effect <- function(model, term, cluster, model_name) {
 robust_vcov <- sandwich::vcovCL(model, cluster = cluster, type = "HC1")
 estimate <- coef(model)[term]
 se <- sqrt(robust_vcov[term, term])

 data.frame(
 model = model_name,
 estimate = estimate,
 lower = estimate - 1.96 * se,
 upper = estimate + 1.96 * se
 )
}

naive_post_model <- lm(
 avoidable_ed ~ treated_hospital,
 data = subset(synthetic_did, post == 1)
)

did_model <- lm(
 avoidable_ed ~ did_treatment + hospital + year,
 data = synthetic_did
)

effect_table <- rbind(
 data.frame(
 model = "True effect",
 estimate = true_effect,
 lower = NA_real_,
 upper = NA_real_
 ),
 extract_clustered_effect(
 naive_post_model,
 "treated_hospital",
 cluster = ~ hospital,
 model_name = "Naive post-period comparison"
 ),
 extract_clustered_effect(
 did_model,
 "did_treatment",
 cluster = ~ hospital,
 model_name = "Difference-in-differences"
 )
)

effect_table[, c("estimate", "lower", "upper")] <-
 round(effect_table[, c("estimate", "lower", "upper")], 3)

knitr::kable(
 effect_table,
 caption = "Estimated treatment effects in the synthetic DiD panel"
)
```

Table: Estimated treatment effects in the synthetic DiD panel

| |model | estimate| lower| upper|
|:----------------|:----------------------------|--------:|------:|------:|
|1 |True effect | -4.000| NA| NA|
|treated_hospital |Naive post-period comparison | -3.824| -6.227| -1.421|
|did_treatment |Difference-in-differences | -4.551| -5.428| -3.675|

The DiD estimate should be close to the true effect because the data were generated exactly to satisfy the design assumptions. The naive post-period comparison is less informative because it compares hospitals with different baseline levels after the policy has already been implemented.

## Step 3: Check the pre-treatment trend structure

Difference-in-differences relies on changes over time, not just treated-versus-untreated level differences. The most important descriptive check is therefore the group trend plot.

``` r
trend_data <- aggregate(
 avoidable_ed ~ year_num + treated_hospital,
 data = synthetic_did,
 FUN = mean
)

trend_data$group <- ifelse(
 trend_data$treated_hospital == 1,
 "Treated hospitals",
 "Comparison hospitals"
)

ggplot2::ggplot(
 trend_data,
 ggplot2::aes(x = year_num, y = avoidable_ed, color = group)
) +
 ggplot2::geom_line(linewidth = 1) +
 ggplot2::geom_point(size = 2) +
 ggplot2::geom_vline(xintercept = 4.5, linetype = "dashed", color = "#4c566a") +
 ggplot2::scale_color_manual(
 values = c("Treated hospitals" = "#8a5a44", "Comparison hospitals" = "#2f6f4f")
 ) +
 ggplot2::labs(
 title = "Synthetic difference-in-differences design",
 subtitle = "The policy is introduced for treated hospitals after year 4",
 x = "Year",
 y = "Avoidable ED visits per 1,000 discharges",
 color = NULL
 ) +
 ggplot2::theme_minimal(base_size = 12)
```

![plot of chunk unnamed-chunk-3](/tutorials/rendered-assets/simulation-tools-simulating-did-data/unnamed-chunk-3-1.png)

The figure should show parallel movement before treatment and a post-policy divergence afterward. That is the visual signature of a well-behaved DiD design.

## Step 4: Recover the 2x2 DiD contrast directly from means

Because this is a classic two-group panel, it is useful to compute the DiD contrast directly from sample means as a second recovery check.

``` r
mean_table <- aggregate(
 avoidable_ed ~ treated_hospital + post,
 data = synthetic_did,
 mean
)

mean_table$group <- ifelse(mean_table$treated_hospital == 1, "Treated", "Comparison")
mean_table$period <- ifelse(mean_table$post == 1, "Post", "Pre")

mean_table$avoidable_ed <- round(mean_table$avoidable_ed, 3)

knitr::kable(
 mean_table[, c("group", "period", "avoidable_ed")],
 caption = "Mean outcome by group and period in the synthetic DiD panel"
)
```

Table: Mean outcome by group and period in the synthetic DiD panel

|group |period | avoidable_ed|
|:----------|:------|------------:|
|Comparison |Pre | 44.051|
|Treated |Pre | 44.778|
|Comparison |Post | 40.280|
|Treated |Post | 36.456|

``` r
treated_post <- mean_table$avoidable_ed[mean_table$treated_hospital == 1 & mean_table$post == 1]
treated_pre <- mean_table$avoidable_ed[mean_table$treated_hospital == 1 & mean_table$post == 0]
control_post <- mean_table$avoidable_ed[mean_table$treated_hospital == 0 & mean_table$post == 1]
control_pre <- mean_table$avoidable_ed[mean_table$treated_hospital == 0 & mean_table$post == 0]

did_from_means <- (treated_post - treated_pre) - (control_post - control_pre)

did_check <- data.frame(
 quantity = c(
 "Treated change",
 "Comparison change",
 "Difference-in-differences from sample means",
 "True effect"
 ),
 value = c(
 treated_post - treated_pre,
 control_post - control_pre,
 did_from_means,
 true_effect
 )
)

did_check$value <- round(did_check$value, 3)

knitr::kable(
 did_check,
 caption = "Direct two-by-two difference-in-differences recovery check"
)
```

Table: Direct two-by-two difference-in-differences recovery check

|quantity | value|
|:-------------------------------------------|------:|
|Treated change | -8.322|
|Comparison change | -3.771|
|Difference-in-differences from sample means | -4.551|
|True effect | -4.000|

This table is useful because it reminds the reader that the fixed-effects regression is just a structured way of computing the same underlying contrast.

## Step 5: Show what happens when the treated and untreated groups are compared only after the policy

Simulation is most useful when it reveals the failure mode of the naive estimator. The post-period-only comparison confounds the treatment effect with the pre-existing level difference between hospital groups.

``` r
post_group_means <- aggregate(
 avoidable_ed ~ treated_hospital,
 data = subset(synthetic_did, post == 1),
 mean
)

post_group_means$group <- ifelse(post_group_means$treated_hospital == 1, "Treated", "Comparison")
post_group_means$avoidable_ed <- round(post_group_means$avoidable_ed, 3)

knitr::kable(
 post_group_means[, c("group", "avoidable_ed")],
 caption = "Naive post-policy group means"
)
```

Table: Naive post-policy group means

|group | avoidable_ed|
|:----------|------------:|
|Comparison | 40.280|
|Treated | 36.456|

This is the comparison that DiD is designed to improve on. Looking only after treatment ignores baseline differences that were already present before the policy began.

## Main assumptions behind this simulation

The first assumption is parallel trends in untreated outcomes. In this synthetic design, that is true by construction because both groups share the same calendar trend before the policy.

The second is that treatment timing is well defined and begins only for the treated hospitals after year 4.

The third is that no other group-specific shock occurs exactly when the policy starts. The simulation omits such shocks so that the treatment effect is the only source of post-period divergence.

These assumptions are useful for learning because they create the cleanest DiD benchmark. Real applications may violate them through differential pretrends, compositional change, serial correlation, or concurrent policies.

## How to adapt this template

Once the basic structure is clear, the same DiD simulation can be modified in many useful ways. You can introduce violations of parallel trends, stagger treatment timing, dynamic treatment effects, serially correlated errors, or treatment-effect heterogeneity. You can also simulate repeated cross-sections instead of panels, or compare simple two-way fixed effects with more modern estimators under staggered adoption.

This is often the best way to build intuition for DiD. The method is simple in notation but highly sensitive to the assumptions built into the panel structure. Simulation makes those assumptions visible.

## Further reading

Card and Krueger remain a classic empirical example of policy-induced comparison over time. Bertrand, Duflo, and Mullainathan remain essential for understanding inference and serial correlation in DiD panels. Goodman-Bacon shows why treatment timing matters so much once adoption becomes staggered.

## References

- Bertrand, Marianne; Duflo, Esther; Mullainathan, Sendhil (2004). "How Much Should We Trust Differences-in-Differences Estimates?." *The Quarterly Journal of Economics*, 119(1), 249--275. DOI: <https://doi.org/10.1162/003355304772839588>.
- Goodman-Bacon, Andrew (2021). "Difference-in-Differences with Variation in Treatment Timing." *Journal of Econometrics*, 225(2), 254--277. DOI: <https://doi.org/10.1016/j.jeconom.2021.03.014>.
