---
title: "Ridge vs Lasso: Shrink, Select, or Both?"
date: 2025-12-18
categories: [tutorials, codes]
---

# 1. Introduction: two regularizers walk into a regression...

You now have:

- **Ridge regression**: shrinks coefficients, loves correlated predictors, never really lets go of any variable.
- **Lasso regression**: shrinks coefficients, but also **deletes** some predictors by setting their coefficients to zero.

It's like two different strategies for decluttering your office:

- Ridge: "Keep everything, but make each thing smaller and less influential."
- Lasso: "Throw some things out entirely, keep the rest."

So which one should you use?

In this tutorial we'll:

- Recap the key differences between ridge and lasso,
- Show a small R example where we fit **both** on the same data,
- Compare coefficients and prediction performance,
- Discuss when each method tends to shine,
- And give a HEOR/health policy perspective on choosing between them.

---

# 2. Quick recap: objectives and penalties

## 2.1. Ridge regression

Ridge solves:

$$
\min_{\beta} \; \sum_{i=1}^n (y_i - x_i^\top \beta)^2
+ \lambda \sum_{j=1}^p \beta_j^2.
$$

Characteristics:

- $L_2$ penalty,
- Shrinks coefficients toward zero,
- Keeps all predictors (no exact zeros),
- Great for multicollinearity and prediction.

## 2.2. Lasso regression

Lasso solves:

$$
\min_{\beta} \; \sum_{i=1}^n (y_i - x_i^\top \beta)^2
+ \lambda \sum_{j=1}^p |\beta_j|.
$$

Characteristics:

- $L_1$ penalty,
- Shrinks coefficients,
- Can set some coefficients exactly to zero (variable selection),
- May behave erratically with highly correlated predictors.

Roughly:

- **Ridge**: "I care about shrinkage and prediction."
- **Lasso**: "I care about sparsity and interpretability."

---

# 3. Example in R: ridge vs lasso on the same data

We'll again use `mtcars`:

- Outcome: mpg,
- Predictors: other car features.

We'll:

- Fit ridge and lasso with cross-validation,
- Compare which variables are selected,
- Compare prediction errors.

```r

set.seed(123)

data(mtcars)

y <- mtcars$mpg
X <- as.matrix(mtcars[, setdiff(names(mtcars), "mpg")])

n <- nrow(X)
train_idx <- sample(seq_len(n), size = floor(2 * n / 3))
test_idx  <- setdiff(seq_len(n), train_idx)

X_train <- X[train_idx, ]
y_train <- y[train_idx]

X_test <- X[test_idx, ]
y_test <- y[test_idx]

mae <- function(a, b) mean(abs(a - b))
rmse <- function(a, b) sqrt(mean((a - b)^2))
```

## 3.1. Fit ridge and lasso with glmnet

```r

# install.packages("glmnet") # if not installed
library(glmnet)

# Ridge (alpha = 0)
ridge_cv <- cv.glmnet(
  x = X_train,
  y = y_train,
  alpha = 0,
  standardize = TRUE
)

# Lasso (alpha = 1)
lasso_cv <- cv.glmnet(
  x = X_train,
  y = y_train,
  alpha = 1,
  standardize = TRUE
)

ridge_lambda <- ridge_cv$lambda.min
lasso_lambda <- lasso_cv$lambda.min

ridge_lambda
lasso_lambda
```

## 3.2. Predictions and performance

```r

ridge_pred <- predict(ridge_cv, s = ridge_lambda, newx = X_test)
lasso_pred <- predict(lasso_cv, s = lasso_lambda, newx = X_test)

c(
  Ridge_MAE  = mae(y_test, ridge_pred),
  Ridge_RMSE = rmse(y_test, ridge_pred),
  Lasso_MAE  = mae(y_test, lasso_pred),
  Lasso_RMSE = rmse(y_test, lasso_pred)
)
```

Depending on the random split, you may see:

- Ridge slightly better or lasso slightly better,
- Or similar performance.

In real HEOR applications, you'd use:

- Larger datasets,
- Multiple resamples or time-based splits,
- Possibly elastic net (compromise between ridge and lasso).

---

## 3.3. Comparing coefficients

```r

ridge_coefs <- as.matrix(coef(ridge_cv, s = ridge_lambda))
lasso_coefs <- as.matrix(coef(lasso_cv, s = lasso_lambda))

ridge_coefs
lasso_coefs
```

You should notice:

- Ridge: all predictors have **non-zero** coefficients (though shrunk),
- Lasso: some coefficients are **exactly zero**.

This is the core trade-off:

- Ridge keeps everyone in the model but turns the volume down,
- Lasso keeps only some predictors and silences the rest.

---

# 4. When to prefer ridge vs lasso (four points each)

## 4.1. Ridge tends to be better when...

1. **Predictors are highly correlated**  
   Ridge handles collinearity gracefully by distributing shrinkage among correlated predictors.

2. **You care mainly about prediction accuracy**  
   If interpretability via sparsity is not crucial, ridge often provides stable and good predictions.

3. **True signal is spread across many predictors**  
   If the "truth" uses many small effects, ridge's continuous shrinkage can be more appropriate than lasso's tendency to zero things out.

4. **You want smooth coefficient paths**  
   Ridge coefficient paths as a function of $\lambda$ are smoother and less jumpy than lasso's, which can help in understanding how shrinkage behaves.

## 4.2. Lasso tends to be better when...

1. **You expect only a subset of predictors to matter**  
   If you believe the true model is sparse, lasso is a natural choice.

2. **Interpretability and simplicity are important**  
   Lasso gives you a smaller set of predictors, which is easier to explain to clinicians, managers, or policymakers.

3. **You have more predictors than observations ($p > n$)**  
   Lasso can still work and perform variable selection in high-dimensional settings (ridge can also work, but does not select).

4. **You want a quick automatic feature selection tool**  
   Lasso is often used as a first-pass tool to winnow down large sets of variables.

---

# 5. HEOR and health policy perspective: choosing a regularizer

In HEOR and health policy, the choice between ridge and lasso often depends on the **goal of the model**:

## 5.1. Forecasting and risk adjustment

If you are focused on:

- Predicting costs,
- Predicting utilization,
- Building risk adjustment models for payment,

and you have:

- Many correlated predictors,
- Less need for strict variable selection,

then **ridge** is often a strong default:

- It stabilizes estimates,
- Reduces overfitting,
- Uses all available information.

## 5.2. Variable selection and explainable scores

If you are focused on:

- Identifying key risk factors,
- Building simple risk scores,
- Communicating which variables "matter most",

then **lasso** is attractive:

- It generates a compact set of predictors,
- Facilitates communication ("the model uses 12 variables, not 120"),
- Can guide future data collection or survey design.

## 5.3. Combined approach: elastic net

When:

- Predictors are highly correlated, **and**
- You'd like some sparsity but also some grouping behavior,

you might consider **elastic net**, which combines ridge and lasso penalties:

$$
\lambda \left[ \alpha \sum_{j} |\beta_j| + (1 - \alpha) \sum_{j} \beta_j^2 \right],
$$

with $\alpha \in [0, 1]$ controlling the mix.

Elastic net often performs well in HEOR contexts with:

- Many correlated clinical and utilization variables,
- A desire for some variable selection plus stable coefficients.

---

# 6. Further reading

1. **James, Witten, Hastie, & Tibshirani - _An Introduction to Statistical Learning_ (Ch. 6).**  
   Excellent applied guide to ridge, lasso, and elastic net, with R examples.

2. **Hastie, Tibshirani, & Friedman - _The Elements of Statistical Learning_ (Ch. 3, 7).**  
   More detailed, including bias-variance tradeoffs and regularization paths.

3. **Hastie, Tibshirani, & Wainwright - _Statistical Learning with Sparsity: The Lasso and Generalizations._**  
   The go-to monograph for lasso, elastic net, and related sparse methods.

4. **glmnet vignettes and documentation.**  
   Practical resource for fitting and tuning ridge, lasso, and elastic net models in R across many outcome types (Gaussian, binomial, Poisson, etc.).

Ultimately, in HEOR and health policy, you rarely commit to only one:

- You try **ridge**, **lasso**, and often **elastic net**,
- Compare via cross-validation or time-based splits,
- Choose the model that best balances **predictive performance**, **stability**, and **interpretability** for your specific question. 😄
