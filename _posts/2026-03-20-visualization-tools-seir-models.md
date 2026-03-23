---
title: "SEIR Models"
date: 2026-03-20
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a compartment-trajectory figure for an SEIR model. The goal is to show how to visualize the flow of a population through the susceptible, exposed, infectious, and recovered states in a way that is..."
excerpt: "Visualizing latent infection dynamics with a compartment-trajectory plot"
---
This chapter builds a compartment-trajectory figure for an SEIR model. The goal is to show how to visualize the flow of a population through the susceptible, exposed, infectious, and recovered states in a way that is both epidemiologically interpretable and visually clear. SEIR figures are useful because they reveal something that a simple epidemic curve cannot: the latent build-up of exposed individuals before infectious prevalence peaks. Kermack and McKendrick established the broader compartmental logic, while Hethcote and Anderson and May explain why latent-state extensions matter in infectious-disease modeling;.

The figure we will build here is especially useful when the analyst wants to communicate timing. The exposed compartment peaks before the infectious compartment, the susceptible stock declines over the outbreak, and recovery accumulates only after transmission has already accelerated. A good SEIR plot turns those relationships into a readable visual narrative.

## What the visualization is showing

An SEIR trajectory plot is a multi-line figure in which each line represents the size of one compartment over time:

1. susceptible ($S$),
2. exposed but not yet infectious ($E$),
3. infectious ($I$),
4. recovered or removed ($R$).

The figure is most useful when:

1. latent infection is substantively important,
2. the timing of peaks matters,
3. the analyst wants to distinguish observed illness from unobserved transmission stages.

The reading rule is simple. Follow the lines from left to right and compare their turning points. The exposed line should typically rise before the infectious line, and the recovered line should accumulate later. That sequence is the main message of the visualization.

## Step 1: Create a synthetic SEIR epidemic

We begin with a synthetic outbreak in a closed population of 10,000 people. The model is deterministic and solved with ordinary differential equations. The purpose is not to estimate a full transmission model, but to create a smooth trajectory figure that makes the latent compartment visible.

```r
library(dplyr)
library(ggplot2)
library(knitr)
library(deSolve)

format_numeric_table <- function(df, digits = 3) {
 numeric_cols <- vapply(df, is.numeric, logical(1))
 df[numeric_cols] <- lapply(df[numeric_cols], round, digits = digits)
 df
}

seir_ode <- function(t, state, parms) {
 with(as.list(c(state, parms)), {
 N <- S + E + I + R
 dS <- -beta * S * I / N
 dE <- beta * S * I / N - sigma * E
 dI <- sigma * E - gamma * I
 dR <- gamma * I
 list(c(dS, dE, dI, dR))
 })
}

solve_seir <- function(times, init, parms) {
 as.data.frame(
 deSolve::ode(y = init, times = times, func = seir_ode, parms = parms)
 )
}

make_seir_long <- function(sol, scale_denominator = NULL) {
 if (is.null(scale_denominator)) {
 scale_denominator <- sol$S[1] + sol$E[1] + sol$I[1] + sol$R[1]
 }

 bind_rows(
 data.frame(time = sol$time, compartment = "Susceptible", value = sol$S / scale_denominator),
 data.frame(time = sol$time, compartment = "Exposed", value = sol$E / scale_denominator),
 data.frame(time = sol$time, compartment = "Infectious", value = sol$I / scale_denominator),
 data.frame(time = sol$time, compartment = "Recovered", value = sol$R / scale_denominator)
 )
}

plot_seir_trajectories <- function(data, title, subtitle, y_label, palette) {
 ggplot(data, aes(x = time, y = value, color = compartment)) +
 geom_line(linewidth = 1.15) +
 scale_color_manual(values = palette) +
 labs(
 title = title,
 subtitle = subtitle,
 x = "Time",
 y = y_label,
 color = NULL
 ) +
 theme_minimal(base_size = 12) +
 theme(
 legend.position = "top",
 panel.grid.minor = element_blank
 )
}
```

```r
synthetic_init <- c(S = 9990, E = 5, I = 5, R = 0)
synthetic_parms <- c(beta = 1.15, sigma = 0.35, gamma = 0.22)
synthetic_times <- 0:160

synthetic_sol <- solve_seir(
 times = synthetic_times,
 init = synthetic_init,
 parms = synthetic_parms
)

synthetic_long <- make_seir_long(synthetic_sol, scale_denominator = 10000)

synthetic_summary <- data.frame(
 quantity = c(
 "Peak exposed share",
 "Peak infectious share",
 "Day of exposed peak",
 "Day of infectious peak",
 "Final recovered share"
 ),
 value = c(
 max(synthetic_sol$E / 10000),
 max(synthetic_sol$I / 10000),
 synthetic_sol$time[which.max(synthetic_sol$E)],
 synthetic_sol$time[which.max(synthetic_sol$I)],
 tail(synthetic_sol$R / 10000, 1)
 )
)

knitr::kable(
 format_numeric_table(synthetic_summary, digits = 3),
 caption = "Key features of the synthetic SEIR trajectory"
)
```

## Step 2: Draw the synthetic SEIR trajectory plot

```r
synthetic_palette <- c(
 "Susceptible" = "#3182bd",
 "Exposed" = "#fd8d3c",
 "Infectious" = "#cb181d",
 "Recovered" = "#31a354"
)

synthetic_plot <- plot_seir_trajectories(
 synthetic_long,
 title = "A compartment-trajectory plot makes the latent stage visible",
 subtitle = "Synthetic SEIR epidemic in a closed population of 10,000",
 y_label = "Share of population",
 palette = synthetic_palette
)

synthetic_plot
```

This figure works because the exposed compartment is visually separated from the infectious compartment. A simple case curve would not show that hidden build-up at all. The timing gap between the exposed and infectious peaks is exactly the kind of structure that motivates an SEIR visualization instead of an SIR one.

## Step 3: Pair the figure with a compact summary table

The trajectory plot is more informative when paired with a short table of turning points and endpoint quantities.

```r
synthetic_turning_points <- data.frame(
 compartment = c("Exposed", "Infectious", "Recovered"),
 peak_or_final_day = c(
 synthetic_sol$time[which.max(synthetic_sol$E)],
 synthetic_sol$time[which.max(synthetic_sol$I)],
 max(synthetic_sol$time)
 ),
 peak_or_final_share = c(
 max(synthetic_sol$E / 10000),
 max(synthetic_sol$I / 10000),
 tail(synthetic_sol$R / 10000, 1)
 )
)

knitr::kable(
 format_numeric_table(synthetic_turning_points, digits = 3),
 caption = "Turning points highlighted by the synthetic SEIR figure"
)
```

The plot communicates the whole shape. The table names the peak values and peak days explicitly.

## Step 4: Create a real-world SEIR figure from a published outbreak

For a real-world example, we use the famous 1978 English boarding-school influenza outbreak published in the *British Medical Journal* and revisited by Avilov and colleagues. The outbreak is valuable for teaching because it occurred in a relatively closed population and generated a compact daily epidemic curve. It is also a natural SEIR example because a latent period is epidemiologically plausible for influenza and affects the timing of visible illness.

This is a transparent partial replication rather than a full epidemiological re-estimation. We use the published daily counts of boys ill in bed as the observed series, fit a simple deterministic SEIR model by minimizing squared error in the infectious curve, and then use the fitted trajectory as the basis for a visualization. The goal is to build the figure, not to claim a definitive transmission estimate.

```r
boarding_outbreak <- data.frame(
 day = 1:14,
 observed_cases = c(1, 3, 6, 25, 73, 222, 294, 258, 237, 191, 125, 69, 27, 11)
)

boarding_objective <- function(theta) {
 beta <- exp(theta[1])
 sigma <- exp(theta[2])
 gamma <- exp(theta[3])

 sol <- solve_seir(
 times = 0:14,
 init = c(S = 761, E = 1, I = 1, R = 0),
 parms = c(beta = beta, sigma = sigma, gamma = gamma)
 )

 fitted_cases <- approx(sol$time, sol$I, xout = boarding_outbreak$day)$y
 sum((fitted_cases - boarding_outbreak$observed_cases)^2)
}

boarding_fit <- optim(
 par = log(c(1.7, 0.8, 0.5)),
 fn = boarding_objective,
 method = "Nelder-Mead",
 control = list(maxit = 300)
)

boarding_parms <- c(
 beta = exp(boarding_fit$par[1]),
 sigma = exp(boarding_fit$par[2]),
 gamma = exp(boarding_fit$par[3])
)

boarding_sol <- solve_seir(
 times = 0:14,
 init = c(S = 761, E = 1, I = 1, R = 0),
 parms = boarding_parms
)

boarding_plot_df <- bind_rows(
 data.frame(time = boarding_sol$time, compartment = "Exposed", value = boarding_sol$E),
 data.frame(time = boarding_sol$time, compartment = "Infectious (model)", value = boarding_sol$I),
 data.frame(time = boarding_sol$time, compartment = "Recovered", value = boarding_sol$R)
) |>
 mutate(compartment = factor(compartment, levels = c("Exposed", "Infectious (model)", "Recovered")))

boarding_compare <- data.frame(
 day = boarding_outbreak$day,
 observed_cases = boarding_outbreak$observed_cases,
 fitted_infectious = approx(boarding_sol$time, boarding_sol$I, xout = boarding_outbreak$day)$y
)

boarding_summary <- data.frame(
 parameter = c("beta", "sigma", "gamma", "RMSE"),
 value = c(
 boarding_parms["beta"],
 boarding_parms["sigma"],
 boarding_parms["gamma"],
 sqrt(mean((boarding_compare$observed_cases - boarding_compare$fitted_infectious)^2))
 )
)

knitr::kable(
 format_numeric_table(boarding_summary, digits = 3),
 caption = "Fitted parameters for the partial boarding-school SEIR approximation"
)

knitr::kable(
 format_numeric_table(boarding_compare, digits = 2),
 caption = "Observed and fitted daily infectious counts in the boarding-school outbreak"
)
```

## Step 5: Draw the real-world SEIR figure

```r
boarding_palette <- c(
 "Exposed" = "#fd8d3c",
 "Infectious (model)" = "#cb181d",
 "Recovered" = "#31a354"
)

boarding_plot <- ggplot(boarding_plot_df, aes(x = time, y = value, color = compartment)) +
 geom_line(linewidth = 1.15) +
 geom_point(
 data = boarding_compare,
 aes(x = day, y = observed_cases),
 inherit.aes = FALSE,
 color = "#08519c",
 fill = "white",
 shape = 21,
 stroke = 0.9,
 size = 2.6
 ) +
 scale_color_manual(values = boarding_palette) +
 labs(
 title = "An SEIR trajectory plot can separate latent spread from observed illness",
 subtitle = "Partial boarding-school influenza reconstruction with observed daily cases overlaid as points",
 x = "Day of outbreak",
 y = "Number of individuals",
 color = NULL
 ) +
 theme_minimal(base_size = 12) +
 theme(
 legend.position = "top",
 panel.grid.minor = element_blank
 )

boarding_plot
```

This real-world figure adds a useful layer that the synthetic example does not have: observed points. The points show the visible epidemic curve, while the model lines show the latent and cumulative compartments that are not directly observed. That is why SEIR plots can be so informative in outbreak communication.

## How to read the figure carefully

SEIR figures are easy to overread if the audience forgets which compartments are observed and which are inferred. In the boarding-school example, the points are observed daily illness counts, but the exposed line is not directly observed. It is a model-implied latent trajectory.

The figure is also sensitive to model structure. Different assumptions about the latent period, infectious period, and initial conditions can shift the trajectories visibly even when the fit to observed cases is similar. That is one reason the plot should be read as a structural summary, not as proof that the fitted parameter values are uniquely correct.

Finally, these figures work best when they are not overloaded. Adding too many compartments, intervention scenarios, and uncertainty bands at once can make the figure harder to interpret than the model itself. The best SEIR visualization usually emphasizes timing and shape first, then adds complexity only when it serves a real interpretive purpose.

## Further reading

Kermack and McKendrick remain the foundational reference for compartmental epidemic thinking. Hethcote provides a broad mathematical overview of infectious-disease compartment models. Wearing, Rohani, and Keeling explain why latent periods and distributional assumptions matter in epidemic modeling, which is directly relevant to SEIR interpretation. For the real-world outbreak used here, see the original *British Medical Journal* report and the modern revisit by Avilov and colleagues.
