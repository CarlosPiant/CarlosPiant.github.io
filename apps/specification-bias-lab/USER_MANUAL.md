# Specification Bias Lab - User Manual

## Purpose
This Shiny app helps users understand how choosing the correct model specification affects prediction bias and coefficient interpretation when the true data-generating process (DGP) is known.

## What the app does
- Generates synthetic data from a user-selected true process.
- Displays the true equation and explanation of its coefficients.
- Fits one user-selected model from a broad list across epidemiology, health economics, causal inference, and machine learning.
- Reports model coefficients, prediction diagnostics, and bias metrics.
- Optionally compares your selected model to the benchmark model that matches the true DGP.

## Getting started
1. Select a **True Data-Generating Process**.
2. Set **Sample size** and **Number of covariates**.
3. Optional: activate **Add interaction terms to TRUE DGP** and select exact interaction pairs (for example, `A:X1`, `X1:X3`).
4. Set **Random seed**.
5. Select an **Estimation model**.
6. Optional: keep **Compare with correct benchmark model** checked.
7. Click **Generate data and fit model**.

## Tabs and outputs
### 1. True Process
- Shows the true equation used to generate data.
- Explains assumptions and interpretation of key coefficients.
- Updates equation terms to reflect selected covariate count and selected interactions.
- Indicates the benchmark model expected to have lowest bias under this DGP.
- Shows a table with the exact true coefficient values used in simulation, so you can compare expected vs fitted estimates.

### 2. Model Fit
- Shows model status (fit, fallback, or failure).
- Displays coefficient table for the selected model.
- Provides scale-aware interpretation guidance:
  - additive effects for linear models,
  - odds/hazard/rate ratios for log-scale models,
  - ATE interpretation for causal estimators.

### 3. Bias and Prediction
- Reports:
  - Mean Bias
  - MAE
  - RMSE
  - Estimated vs true treatment effect (and bias)
- Plot compares predicted vs true signal/mean with a 45-degree reference line.

### 4. Data Preview
- Displays a compact preview of the data structure used by the selected model.

### 5. User Manual
- In-app summary of workflow and interpretation recommendations.

### 6. DAG
- Displays a Directed Acyclic Graph (DAG) aligned with the structural equations.
- Includes interaction nodes when interactions are selected.

## Download generated data
- In the left panel, choose a dataset in **Dataset to download**:
  - Cross-sectional synthetic data
  - High-dimensional data
  - Longitudinal panel data
  - DiD policy panel data
- Click **Download generated data (CSV)** to export the latest generated dataset.

## Recommended teaching workflow
1. Pick a DGP and run the benchmark model first.
2. Switch to intentionally misspecified models.
3. Compare prediction bias and treatment-effect bias.
4. Explain why link function, outcome type, or design assumptions matter.
5. Repeat across seeds and sample sizes to show finite-sample variability.

## Required R packages
### Core
- shiny
- ggplot2
- dplyr

### Optional (for full feature coverage)
- survival
- MASS
- mgcv
- AER
- geepack
- nlme
- tmle
- lavaan
- glmnet
- randomForest
- nnet
- rpart
- DiagrammeR

If an optional package is unavailable, the app uses fallbacks when possible and reports this in the model status.

## Run locally
```r
shiny::runApp("apps/specification-bias-lab")
```
