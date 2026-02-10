---
title: "Time Series as a Machine Learning Tool: Let the Past Predict the Future"
date: 2025-12-18
link: /tutorials/03-ml-time-series.html
categories: [tutorials, codes]
---

# 1. Introduction: when your data has a memory (and an attitude)

Most of the models we use in machine learning are like goldfish:

- They look at a row of features,
- They predict an outcome,
- They completely forget everything that happened before.

But then you meet **time series data**, and it's more like that one colleague who
remembers every meeting, every deadline, and every mistake:

- Yesterday's hospital admissions look suspiciously like today's.
- Last quarter's drug spending predicts this quarter... a little too well.
- Flu seasons keep coming back like a Netflix series with too many seasons.

If you feed time series into a standard ML algorithm **without** telling it about
time, it will happily:

- Shuffle your data,
- Break all temporal structure,
- And then proudly overfit the past while being terrible at forecasting the future.

So we need models that **treat time as a first-class citizen**.

In this tutorial we'll treat **time series forecasting** as a kind of
supervised learning problem, but one where:

- The features are *lagged values* and other time-based transformations,
- We must respect the **order of observations**,
- Validation and testing must be done in a **time-aware** way.

We'll:

- Lay the conceptual foundations of time series as ML,
- Build a simple forecasting model in R with synthetic "hospital admissions" data,
- Discuss strengths and limitations,
- And wrap up with why this really matters for **HEOR and health policy**.

---

# 2. Foundations: time series as supervised learning

## 2.1. What is a time series?

A **time series** is a sequence of observations ordered in time:

$$
y_1, y_2, \dots, y_T
$$

Examples in HEOR:

- Monthly hospital admissions,
- Weekly ED visits,
- Quarterly drug spending,
- Annual mortality rates by region.

The key twist: observations are **not independent**. What happens at time $t$
depends on what happened at times $t-1, t-2, \dots$.

## 2.2. Turning a time series into an ML problem

To think of time series as a machine learning task, we often reframe:

> Predict $y_t$ using past values of the series.

We create a dataset of the form:

- Features: lagged values $(y_{t-1}, y_{t-2}, \dots, y_{t-p})$
- Target: $y_t$

So each training example is:

$$
\big( y_{t-1}, y_{t-2}, \dots, y_{t-p} \big) \;\; \to \;\; y_t.
$$

Any regression model (linear, random forest, neural net, etc.) can, in principle,
be applied to this data. But we must always respect the **time ordering**:

- Training set: earlier times,
- Validation/test sets: later times,
- No shuffling across time.

## 2.3. Classical vs ML flavors

**Classical time series models** (like ARIMA) are:

- Designed specifically for time-series structure,
- Often assume some form of **stationarity**,
- Use parametric relationships: autoregressive (AR), moving average (MA),
  differencing (I), etc.

**ML-style time series models**:

- Can be more flexible, with nonlinear relationships,
- Use extra features: calendar variables, exogenous regressors, lagged covariates,
- Include algorithms like gradient-boosted trees, random forests, or deep learning.

In this tutorial, we'll stick to a **classical ARIMA-style** model, but we'll
frame it with an ML mindset:

- Train on a training period,
- Evaluate on a test period,
- Forecast and compare to truth.

---

# 3. Example in R: forecasting synthetic "hospital admissions"

We'll build a toy example where:

- We simulate monthly hospital admissions over 10 years,
- The series has:
  - A slight upward trend,
  - Seasonality (e.g., winter peaks),
  - Random noise,
- We split into **training** and **test** periods,
- We fit an ARIMA model and generate forecasts.

You can later swap the synthetic data for real HEOR data.

```r

set.seed(123)

# We'll simulate 10 years of monthly data
n_years  <- 10
freq     <- 12
n_period <- n_years * freq

time_index <- 1:n_period

# Components:
# - Baseline around 100 admissions per month
# - Slight upward trend
# - Seasonal pattern (higher in winter)
# - Random noise

baseline <- 100
trend    <- 0.5 * time_index   # slow upward trend

# Seasonal component: use a simple sine wave
seasonality <- 10 * sin(2 * pi * time_index / freq)  # yearly cycle

# Random noise
noise <- rnorm(n_period, mean = 0, sd = 8)

admissions <- baseline + trend + seasonality + noise

# Create a time series object
admissions_ts <- ts(admissions, frequency = freq)
```

## 3.1. Visualizing the time series

```r

plot(
  admissions_ts,
  main = "Simulated Monthly Hospital Admissions",
  xlab = "Time (months)",
  ylab = "Admissions"
)
```

You should see:

- A general upward trend,
- Regular seasonal bumps,
- Noise around the pattern.

---

## 3.2. Train-test split that respects time

We'll:

- Use the first 8 years (96 months) as **training** data,
- Use the last 2 years (24 months) as **test** data.

```r

train_end <- 8 * freq   # 8 years of monthly data
train_ts  <- window(admissions_ts, end = c(8, freq))
test_ts   <- window(admissions_ts, start = c(9, 1))

length(train_ts); length(test_ts)
```

We're mimicking an ML workflow:

- The model is trained only on the first 8 years,
- Forecasts are compared to the last 2 years (which the model has never seen).

---

## 3.3. Fitting a forecasting model (ARIMA)

We'll use the `forecast` package's `auto.arima()` to:

- Automatically pick ARIMA orders based on the data,
- Including differencing and seasonal components if needed.

```r

# install.packages("forecast") # run once if needed
library(forecast)

fit_arima <- auto.arima(train_ts)
fit_arima
```

The printed output tells you:

- The ARIMA order (e.g., ARIMA(1,1,1)(0,1,1)[12]),
- Estimated coefficients,
- Information criteria (AIC, etc.).

---

## 3.4. Forecasting and evaluating performance

We forecast 24 months ahead (matching the test period) and compare predictions
with actual test data.

```r

library(ggplot2)

fc_arima <- forecast(fit_arima, h = length(test_ts))

autoplot(fc_arima) +
  autolayer(test_ts, series = "Actual", color = "black") +
  labs(
    title = "ARIMA Forecast vs Actual (Admissions)",
    x = "Time",
    y = "Admissions"
  )
```

We can compute simple error metrics:

```r

pred_vals <- as.numeric(fc_arima$mean)
true_vals <- as.numeric(test_ts)

# Mean Absolute Error (MAE)
mae <- mean(abs(pred_vals - true_vals))

# Root Mean Squared Error (RMSE)
rmse <- sqrt(mean((pred_vals - true_vals)^2))

c(MAE = mae, RMSE = rmse)
```

This gives you an ML-style evaluation of your time series model.

From here, you could:

- Add **explanatory variables** (e.g., holidays, flu season indicators),
- Try more flexible models (e.g., boosted trees with lag features),
- Compare multiple models via time-series cross-validation.

---

# 4. Strengths and limitations of time series methods (as ML tools)

## 4.1. Four strengths

1. **Explicitly models temporal dependence**  
   Time series methods embrace the fact that $y_t$ depends on past values. This is critical for forecasting and for correctly quantifying uncertainty over time.

2. **Good at short- and medium-term forecasting**  
   When trends and seasonal patterns are reasonably stable, time series models can provide accurate and interpretable short- and mid-horizon forecasts - highly valuable for planning and budgeting.

3. **Integrates naturally with ML thinking**  
   You can treat lagged values and time-based features as inputs to any regression algorithm, thus combining classical time series structure with modern ML flexibility.

4. **Diagnostics and structure**  
   Classical time series models (ARIMA, etc.) come with rich diagnostic tools (ACF, PACF, residual analysis) that help understand model misfit and dynamics, not just prediction accuracy.

---

## 4.2. Four limitations

1. **Sensitive to structural breaks and regime changes**  
   If a major policy change, pandemic, or coding change occurs, models trained on past data may extrapolate badly. Time series methods often assume that the future behaves "like the past," just with noise.

2. **Complex seasonal and calendar effects can be tricky**  
   Real-world data might have multiple seasonalities (e.g., weekly + yearly patterns) or irregular events (holidays, strikes) that standard models don't capture well without considerable feature engineering.

3. **High-dimensional multivariate series are challenging**  
   When many series interact (e.g., multiple regions, service lines), fully modeling the joint dynamics can become complex and computationally heavy.

4. **Overfitting and leakage are easy if you ignore time**  
   If you accidentally shuffle data, use future information in features, or split train/test incorrectly, you can get wildly optimistic performance estimates that do not generalize.

---

# 5. Why time series matters in HEOR and health policy

Time series methods are not a niche add-on; they sit at the heart of many HEOR
and policy questions because so much of what we care about is **how things evolve over time**.

## 5.1. Forecasting demand and utilization

Examples:

- How many hospital admissions will we see next winter?
- What will ED visits look like after a new triage policy?
- How will drug utilization trend over the next 3-5 years?

Forecasts inform:

- Capacity planning (beds, staff, supplies),
- Procurement and budgeting,
- Evaluation of whether a policy may push the system over capacity.

## 5.2. Cost projections and budget impact

Payers and policymakers need to know:

- How will costs evolve over time under different scenarios?
- What is the likely **budget impact** of a new intervention over 5-10 years?

Time series models, sometimes embedded in broader economic models, can provide:

- Baseline projections (status quo),
- Policy scenario projections,
- Ranges of uncertainty for planning.

## 5.3. Policy evaluation and dynamic effects

Time series structure is central to:

- **Interrupted time series (ITS)** designs,
- **Difference-in-differences** and **event-study** models,
- Assessing **before-and-after** changes while accounting for pre-existing trends.

Understanding time series behavior ensures that:

- You don't confuse a pre-existing trend with a policy effect,
- You can track how effects evolve and persist (or fade) over time.

## 5.4. Feeding more complex models

Time series outputs often become inputs to:

- Microsimulation models,
- Markov models,
- System dynamics models.

For example:

- Forecasted incidence rates,
- Time-varying costs or utilization rates,
- Dynamic coverage or adherence patterns.

Good time series modeling upstream makes downstream decision models more realistic.

---

# 6. Further reading

If you want to treat time series as both a statistical and ML problem (with a lot of R examples), these are great resources:

1. **Hyndman & Athanasopoulos - _Forecasting: Principles and Practice_ (online, free)**  
   A very practical and R-focused introduction to time series forecasting (including ARIMA, ETS, and modern approaches).

2. **Shumway & Stoffer - _Time Series Analysis and Its Applications_**  
   A balanced mix of theory and applications, with many examples and R code.

3. **Hyndman, Koehler, Ord, & Snyder - _Forecasting with Exponential Smoothing: The State Space Approach_**  
   More specialized, but great if you want to understand exponential smoothing and state space models deeply.

4. **Hastie, Tibshirani, & Friedman - _The Elements of Statistical Learning_ (chapters on time series / forecasting and regularization)**  
   Not time-series-specific, but very useful for thinking about ML models, regularization, and how they adapt (or don't) to temporal data.

Once you're comfortable with these foundations, you can start mixing in:

- Gradient-boosted trees or random forests on lagged features,
- Recurrent or temporal CNN architectures,
- Probabilistic forecasting frameworks -

all while keeping the HEOR and health policy questions front and center. 😄
