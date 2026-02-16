---
title: "Specification Bias Lab"
collection: apps
permalink: /apps/specification-bias-lab/
subtitle: "Synthetic data, model choice, bias diagnostics, and coefficient interpretation"
description: "Interactive Shiny app to compare statistical model specifications against known true data-generating processes."
app_url: ""
hide_author_avatar: true
---

This app generates synthetic data from a known true process and lets you evaluate how model choice affects prediction bias and interpretation of coefficients.

## Live App

{% if page.app_url and page.app_url != "" %}
<p><a class="btn btn--primary" href="{{ page.app_url }}" target="_blank" rel="noopener">Open the app</a></p>
<iframe src="{{ page.app_url }}" style="width: 100%; height: 900px; border: 1px solid #e5e7eb; border-radius: 8px;" loading="lazy"></iframe>
{% else %}
<p><strong>Deploy URL not set yet.</strong> Add a deployed Shiny URL to <code>app_url</code> in this file to embed the app here.</p>
{% endif %}

## Core Features

- Select from multiple true data-generating processes (DGPs).
- Control the number of generated covariates and optional interaction terms in the true process.
- View the true equation, assumptions, and coefficient interpretation.
- Inspect the exact true parameter values used for each covariate and interaction in the selected process.
- View a DAG visualization that follows the displayed structural equations.
- Fit one model from a full list covering epidemiology, health economics, causal inference, and machine learning.
- Compare your selected model with the benchmark model implied by the true DGP.
- Review prediction-bias metrics and treatment-effect bias.
- Download generated synthetic datasets as CSV.

## Run Locally

1. Install core packages:

```r
install.packages(c("shiny", "ggplot2", "dplyr"))
```

2. Run the app:

```r
shiny::runApp("apps/specification-bias-lab")
```

## User Manual

- `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/apps/specification-bias-lab/USER_MANUAL.md`

## Source Code

- `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/apps/specification-bias-lab/app.R`
