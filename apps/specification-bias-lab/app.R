library(shiny)
library(ggplot2)
library(dplyr)

inv_logit <- function(x) {
  1 / (1 + exp(-x))
}

clamp <- function(x, lower = 1e-6, upper = 1 - 1e-6) {
  pmin(pmax(x, lower), upper)
}

format_num <- function(x, digits = 3) {
  ifelse(is.na(x), NA_character_, format(round(x, digits), nsmall = digits, trim = TRUE))
}

safe_require <- function(pkg) {
  requireNamespace(pkg, quietly = TRUE)
}

model_choices <- list(
  "Epidemiology" = c(
    "Logistic Regression" = "logistic",
    "Cox Proportional Hazards Model" = "cox",
    "Poisson/Negative Binomial Regression" = "poisson_nb",
    "Linear Regression" = "linear_regression",
    "Generalized Additive Models (GAMs)" = "gam"
  ),
  "Health Economics" = c(
    "Ordinary Least Squares (OLS) Regression" = "ols",
    "Generalized Linear Models (GLM, Gamma log-link)" = "glm_gamma",
    "Instrumental Variables (IV) / Two-Stage Least Squares (2SLS)" = "iv_2sls",
    "Difference-in-Differences (DiD)" = "did",
    "Generalized Estimating Equations (GEE) / Random Effects Models" = "gee_re"
  ),
  "Causal Inference" = c(
    "Propensity Score Matching (PSM)/Regression" = "psm",
    "Double/Debiased Machine Learning (DML)" = "dml",
    "Targeted Maximum Likelihood Estimation (TMLE)" = "tmle",
    "Augmented Inverse Probability Weighting (AIPW)" = "aipw",
    "Structural Equation Modeling (SEM) / Directed Acyclic Graphs (DAGs)" = "sem_dag"
  ),
  "Machine Learning" = c(
    "LASSO Regression" = "lasso",
    "Random Forest/Gradient Boosting (XGBoost style)" = "rf_xgb",
    "Elastic Net Regression" = "elastic_net",
    "Neural Networks/Deep Learning" = "neural_net",
    "Meta-learners (T-Learner, X-Learner)" = "meta_learner"
  )
)

model_labels <- c(
  logistic = "Logistic Regression",
  cox = "Cox Proportional Hazards Model",
  poisson_nb = "Poisson/Negative Binomial Regression",
  linear_regression = "Linear Regression",
  gam = "Generalized Additive Models (GAMs)",
  ols = "Ordinary Least Squares (OLS) Regression",
  glm_gamma = "Generalized Linear Model (Gamma log-link)",
  iv_2sls = "Instrumental Variables / 2SLS",
  did = "Difference-in-Differences (DiD)",
  gee_re = "GEE / Random Effects",
  psm = "Propensity Score Matching/Regression",
  dml = "Double/Debiased Machine Learning (DML)",
  tmle = "Targeted Maximum Likelihood Estimation (TMLE)",
  aipw = "Augmented Inverse Probability Weighting (AIPW)",
  sem_dag = "SEM / DAG-guided regression",
  lasso = "LASSO Regression",
  rf_xgb = "Random Forest / Boosting-style",
  elastic_net = "Elastic Net Regression",
  neural_net = "Neural Network",
  meta_learner = "Meta-learner (T-Learner)"
)

dgp_catalog <- list(
  linear_continuous = list(
    title = "Linear Continuous Outcome",
    equation = "Y = \\beta_0 + \\beta_1 A + \\beta_2 X_1 + \\beta_3 X_2 + \\beta_4 X_3 + \\varepsilon",
    description = "A correctly specified linear additive process. OLS/Linear regression should recover effects with low bias.",
    coef_notes = c(
      "beta1 is the average additive effect of treatment A on Y.",
      "beta2 and beta4 are marginal effects of one-unit increases in X1 and X3.",
      "beta3 is the mean difference associated with the binary covariate X2."
    ),
    correct_model = "linear_regression"
  ),
  binary_risk = list(
    title = "Binary Disease Risk (Logit)",
    equation = "\\text{logit}(P(Y=1)) = \\beta_0 + \\beta_1 A + \\beta_2 X_1 + \\beta_3 X_2 + \\beta_4 X_3",
    description = "A binary risk process where coefficients live on log-odds scale. Logistic regression is correctly specified.",
    coef_notes = c(
      "exp(beta1) is the odds ratio for treatment A, adjusted for covariates.",
      "Positive beta means higher disease risk on the log-odds scale.",
      "Odds ratios are multiplicative and not risk differences."
    ),
    correct_model = "logistic"
  ),
  survival_ph = list(
    title = "Time-to-Event Proportional Hazards",
    equation = "h(t|X) = h_0(t)\\exp(\\beta_1 A + \\beta_2 X_1 + \\beta_3 X_2 + \\beta_4 X_3)",
    description = "A proportional hazards process for survival data. The Cox model is the target specification.",
    coef_notes = c(
      "exp(beta1) is the hazard ratio for treatment A.",
      "beta coefficients are log-hazard shifts.",
      "Hazard ratios compare instantaneous risk at each time point."
    ),
    correct_model = "cox"
  ),
  count_rate = list(
    title = "Count/Rate Process",
    equation = "\\log(E[Y|X]) = \\beta_0 + \\beta_1 A + \\beta_2 X_1 + \\beta_3 X_2 + \\beta_4 X_3",
    description = "A count process with possible overdispersion. Poisson or Negative Binomial is the right family.",
    coef_notes = c(
      "exp(beta1) is the rate ratio for A.",
      "Log-link keeps expected counts positive.",
      "Overdispersion suggests preferring Negative Binomial over Poisson."
    ),
    correct_model = "poisson_nb"
  ),
  nonlinear_exposure = list(
    title = "Nonlinear Exposure-Response",
    equation = "Y = \\beta_0 + \\beta_1 A + f_1(X_1) + f_2(X_3) + \\beta_2 X_2 + \\varepsilon",
    description = "The true relationship is nonlinear in covariates. GAMs should reduce misspecification bias.",
    coef_notes = c(
      "beta1 remains the adjusted linear effect of A.",
      "f1 and f2 are smooth functions, not fixed one-unit effects.",
      "Interpreting shapes of smooth terms is as important as p-values."
    ),
    correct_model = "gam"
  ),
  cost_gamma = list(
    title = "Skewed Cost Outcome",
    equation = "\\log(E[Cost|X]) = \\beta_0 + \\beta_1 A + \\beta_2 X_1 + \\beta_3 X_2 + \\beta_4 X_3",
    description = "A non-negative, right-skewed cost process. GLM with Gamma family and log link is correctly specified.",
    coef_notes = c(
      "exp(beta1) is the multiplicative change in expected cost for A.",
      "Gamma variance grows with the mean, matching common health cost data.",
      "Interpret coefficients as cost ratios rather than additive dollars."
    ),
    correct_model = "glm_gamma"
  ),
  endogeneity_iv = list(
    title = "Endogeneity with Instrument",
    equation = "\\begin{aligned}A &= \\pi_0 + \\pi_1 Z + \\pi_2 X + v\\\\
Y &= \\beta_0 + \\beta_1 A + \\beta_2 X + u
\\end{aligned}",
    description = "Treatment A is endogenous (correlated with unobserved u). IV/2SLS can recover a less biased causal effect when Z is valid.",
    coef_notes = c(
      "beta1 is a local causal effect identified through instrument Z.",
      "Validity needs relevance (Z affects A) and exclusion (Z affects Y only via A).",
      "Naive OLS is biased when A and unobserved factors co-move."
    ),
    correct_model = "iv_2sls"
  ),
  policy_did = list(
    title = "Policy Evaluation with DiD",
    equation = "Y_{it}=\\beta_0+\\beta_1 Treat_i+\\beta_2 Post_t+\\beta_3(Treat_i\\times Post_t)+\\epsilon_{it}",
    description = "A two-group, two-period policy setting. Difference-in-Differences isolates the incremental post-policy effect.",
    coef_notes = c(
      "beta3 is the DiD estimate: the treatment effect under parallel trends.",
      "beta1 captures baseline group differences.",
      "beta2 captures time shocks common to both groups."
    ),
    correct_model = "did"
  ),
  panel_longitudinal = list(
    title = "Longitudinal Repeated Measures",
    equation = "Y_{it} = \\beta_0 + \\beta_1 A_{it} + \\beta_2 time_t + b_i + \\epsilon_{it}",
    description = "Repeated outcomes within individuals introduce within-person correlation. GEE or random effects handles this dependency.",
    coef_notes = c(
      "beta1 is the adjusted treatment effect across repeated measurements.",
      "bi captures person-level heterogeneity.",
      "Ignoring clustering underestimates uncertainty."
    ),
    correct_model = "gee_re"
  ),
  causal_selection = list(
    title = "Causal Inference with Selection Bias",
    equation = "\\tau = E[Y(1)-Y(0)],\\quad A \\sim e(X),\\quad Y = AY(1)+(1-A)Y(0)",
    description = "Treatment is assigned based on covariates, creating confounding. Doubly robust estimators target less biased ATEs.",
    coef_notes = c(
      "The key estimand is ATE, not only regression slope coefficients.",
      "Propensity scores model treatment assignment e(X).",
      "Outcome models and treatment models jointly reduce bias in doubly robust methods."
    ),
    correct_model = "aipw"
  ),
  highdim_sparse = list(
    title = "High-Dimensional Sparse Signal",
    equation = "Y = \\beta_0 + \\beta_A A + \\sum_{j=1}^{p}\\beta_j W_j + \\varepsilon,\\quad \\beta_j=0\\text{ for most }j",
    description = "Many predictors with only a few true signals. Regularization (LASSO/Elastic Net) improves prediction and selection.",
    coef_notes = c(
      "Most coefficients are truly zero in sparse settings.",
      "LASSO shrinks small effects to zero for variable selection.",
      "Penalized estimates trade slight bias for lower variance and better out-of-sample fit."
    ),
    correct_model = "lasso"
  )
)

manual_sections <- list(
  `1. Choose the true data-generating process` =
    "Pick a process from the left panel. This process is treated as the truth and drives synthetic data generation.",
  `2. Set simulation controls` =
    "Set sample size, number of covariates, optional interactions, and random seed, then click Generate data and fit model.",
  `3. Read the true equation` =
    "In the True Process tab, review the equation, assumptions, and interpretation of coefficients.",
  `4. Select an estimation model` =
    "Choose one model from epidemiology, health economics, causal inference, or machine learning lists.",
  `5. Compare specification quality` =
    "The Bias and Prediction tab shows prediction error and treatment-effect bias for your selected model. Optionally compare with the benchmark model implied by the true process.",
  `6. Interpret coefficients` =
    "Use the Model Fit tab to read coefficient estimates and scale-specific interpretation (additive effects, odds ratios, hazard ratios, or ATE).",
  `7. Download synthetic data` =
    "Use the dataset selector and Download button in the sidebar to export the generated data as CSV.",
  `8. Inspect DAG and structural equations` =
    "Use the DAG tab to inspect the causal graph and verify it aligns with the displayed structural equations."
)

make_split <- function(n, prop = 0.7) {
  train_idx <- sample.int(n, size = floor(prop * n))
  list(train = train_idx, test = setdiff(seq_len(n), train_idx))
}

split_by_id <- function(df, id_col = "id", prop = 0.7) {
  ids <- unique(df[[id_col]])
  id_train <- sample(ids, size = floor(prop * length(ids)))
  list(
    train = df[df[[id_col]] %in% id_train, , drop = FALSE],
    test = df[!df[[id_col]] %in% id_train, , drop = FALSE]
  )
}

get_covariate_names <- function(df) {
  covs <- grep("^X[0-9]+$", names(df), value = TRUE)
  covs[order(as.integer(sub("^X", "", covs)))]
}

pick_covariates <- function(df, max_n = NULL) {
  covs <- get_covariate_names(df)
  if (is.null(max_n)) return(covs)
  head(covs, max_n)
}

build_formula <- function(lhs, rhs_terms, env = parent.frame()) {
  rhs_terms <- rhs_terms[!is.na(rhs_terms) & nzchar(rhs_terms)]
  rhs <- if (length(rhs_terms) == 0) "1" else paste(rhs_terms, collapse = " + ")
  as.formula(paste(lhs, "~", rhs), env = env)
}

build_covariates <- function(n, n_covariates) {
  n_covariates <- max(3, as.integer(n_covariates))
  X <- replicate(n_covariates, rnorm(n))
  X <- as.data.frame(X)
  names(X) <- paste0("X", seq_len(n_covariates))

  if (n_covariates >= 2) X$X2 <- rbinom(n, 1, 0.45)
  if (n_covariates >= 5) X$X5 <- rbinom(n, 1, 0.50)
  X
}

build_interaction_signal <- function(interaction_terms, X, A) {
  if (length(interaction_terms) == 0) {
    return(list(
      signal = rep(0, nrow(X)),
      treat_modifier = rep(0, nrow(X)),
      used_terms = character(),
      coefficients = numeric()
    ))
  }

  signal <- rep(0, nrow(X))
  treat_modifier <- rep(0, nrow(X))
  used_terms <- character()
  coefs <- numeric()

  for (term in unique(interaction_terms)) {
    parts <- strsplit(term, ":", fixed = TRUE)[[1]]
    if (length(parts) != 2) next

    v1 <- if (parts[1] == "A") A else X[[parts[1]]]
    v2 <- if (parts[2] == "A") A else X[[parts[2]]]
    if (is.null(v1) || is.null(v2)) next

    gamma <- if ("A" %in% parts) 0.35 else 0.20
    signal <- signal + gamma * v1 * v2
    used_terms <- c(used_terms, term)
    coefs <- c(coefs, gamma)

    if ("A" %in% parts) {
      other <- setdiff(parts, "A")[1]
      if (!is.na(other) && other %in% names(X)) {
        treat_modifier <- treat_modifier + gamma * X[[other]]
      }
    }
  }

  names(coefs) <- used_terms
  list(
    signal = signal,
    treat_modifier = treat_modifier,
    used_terms = used_terms,
    coefficients = coefs
  )
}

latex_var <- function(v, dgp_id = NULL) {
  if (v == "A" && !is.null(dgp_id) && dgp_id == "policy_did") return("Treat_i")
  if (v == "A" && !is.null(dgp_id) && dgp_id == "panel_longitudinal") return("A_{it}")
  if (grepl("^X[0-9]+$", v)) return(paste0("X_{", sub("^X", "", v), "}"))
  v
}

plain_var <- function(v, dgp_id = NULL) {
  if (v == "A" && !is.null(dgp_id) && dgp_id == "policy_did") return("Treat")
  if (v == "A" && !is.null(dgp_id) && dgp_id == "panel_longitudinal") return("A_it")
  v
}

interaction_gamma_value <- function(term) {
  if (grepl("(^A:|:A$)", term)) 0.35 else 0.20
}

compose_terms <- function(terms) {
  terms <- terms[!is.na(terms) & nzchar(terms)]
  if (length(terms) == 0) return("0")
  paste(terms, collapse = " + ")
}

covariate_terms_latex <- function(covariates, prefix = "\\beta") {
  if (length(covariates) == 0) return(character())
  vapply(seq_along(covariates), function(i) {
    paste0(prefix, "_{", i, "} ", latex_var(covariates[i]))
  }, character(1))
}

interaction_terms_latex <- function(interactions, dgp_id = NULL) {
  if (length(interactions) == 0) return(character())
  vapply(seq_along(interactions), function(i) {
    parts <- strsplit(interactions[i], ":", fixed = TRUE)[[1]]
    if (length(parts) != 2) return("")
    p1 <- latex_var(parts[1], dgp_id = dgp_id)
    p2 <- latex_var(parts[2], dgp_id = dgp_id)
    paste0("\\gamma_{", i, "}(", p1, "\\times ", p2, ")")
  }, character(1))
}

build_dynamic_equations <- function(dgp_id, covariates, interactions) {
  cov_terms <- covariate_terms_latex(covariates, prefix = "\\beta")
  int_terms <- interaction_terms_latex(interactions, dgp_id = dgp_id)

  rhs_linear <- compose_terms(c("\\beta_0", "\\beta_A A", cov_terms, int_terms))
  rhs_linear_panel <- compose_terms(c("\\beta_0", "\\beta_A A_{it}", "\\beta_t time_t", cov_terms, int_terms))
  rhs_linear_did <- compose_terms(c(
    "\\beta_0", "\\delta_1 Treat_i", "\\delta_2 Post_t", "\\delta_3(Treat_i\\times Post_t)",
    cov_terms, int_terms
  ))

  eq_main <- switch(
    dgp_id,
    linear_continuous = paste0("Y = ", rhs_linear, " + \\varepsilon"),
    binary_risk = paste0("\\text{logit}(P(Y=1)) = ", rhs_linear),
    survival_ph = paste0("h(t|X) = h_0(t)\\exp(", compose_terms(c("\\beta_A A", cov_terms, int_terms)), ")"),
    count_rate = paste0("\\log(E[Y|X]) = ", rhs_linear),
    nonlinear_exposure = paste0(
      "Y = \\beta_0 + \\beta_A A + f_1(X_{1}) + f_2(X_{3}) + ",
      compose_terms(c(cov_terms, int_terms)),
      " + \\varepsilon"
    ),
    cost_gamma = paste0("\\log(E[Cost|X]) = ", rhs_linear),
    endogeneity_iv = paste0(
      "\\begin{aligned}",
      "A_{endo} &= \\pi_0 + \\pi_Z Z + ", compose_terms(covariate_terms_latex(covariates, prefix = "\\pi")), " + v \\\\ ",
      "Y &= \\beta_0 + \\beta_A A_{endo} + ", compose_terms(c(cov_terms, int_terms)), " + u",
      "\\end{aligned}"
    ),
    policy_did = paste0("Y_{it} = ", rhs_linear_did, " + \\varepsilon_{it}"),
    panel_longitudinal = paste0("Y_{it} = ", rhs_linear_panel, " + b_i + \\varepsilon_{it}"),
    causal_selection = paste0(
      "\\begin{aligned}",
      "\\text{logit}(e(X)) &= \\alpha_0 + ", compose_terms(covariate_terms_latex(covariates, prefix = "\\alpha")), " \\\\ ",
      "Y &= \\beta_0 + \\tau A + ", compose_terms(c(cov_terms, int_terms)), " + u + \\varepsilon",
      "\\end{aligned}"
    ),
    highdim_sparse = paste0(
      "Y = \\beta_0 + \\beta_A A + \\sum_{j=1}^{20}\\theta_j W_j + ",
      compose_terms(c(cov_terms, int_terms)),
      " + \\varepsilon"
    ),
    paste0("Y = ", rhs_linear, " + \\varepsilon")
  )

  structural_eq <- switch(
    dgp_id,
    endogeneity_iv = c(
      paste0("A_{endo} = \\pi_0 + \\pi_Z Z + ", compose_terms(covariate_terms_latex(covariates, prefix = "\\pi")), " + v"),
      paste0("Y = \\beta_0 + \\beta_A A_{endo} + ", compose_terms(c(cov_terms, int_terms)), " + u")
    ),
    policy_did = c(
      "Post_t \\in \\{0,1\\},\\ Treat_i \\in \\{0,1\\}",
      paste0("Y_{it} = ", rhs_linear_did, " + \\varepsilon_{it}")
    ),
    panel_longitudinal = c(
      paste0("A_{it} = g(X_i, time_t)"),
      paste0("Y_{it} = ", rhs_linear_panel, " + b_i + \\varepsilon_{it}")
    ),
    causal_selection = c(
      paste0("\\text{logit}(e(X)) = \\alpha_0 + ", compose_terms(covariate_terms_latex(covariates, prefix = "\\alpha"))),
      paste0("Y = \\beta_0 + \\tau A + ", compose_terms(c(cov_terms, int_terms)), " + u + \\varepsilon")
    ),
    c(eq_main)
  )

  list(main = eq_main, structural = structural_eq)
}

beta_cross_for_dgp <- function(dgp_id) {
  switch(
    dgp_id,
    linear_continuous = 0.9,
    binary_risk = 1.1,
    survival_ph = 0.85,
    count_rate = 0.75,
    nonlinear_exposure = 0.9,
    cost_gamma = 0.55,
    endogeneity_iv = 1.15,
    policy_did = 0.8,
    panel_longitudinal = 0.75,
    causal_selection = 0.65,
    highdim_sparse = 0.5,
    0.8
  )
}

base_covariate_coef <- function(dgp_id) {
  switch(
    dgp_id,
    linear_continuous = c(X1 = 1.0, X2 = -0.8, X3 = 0.5),
    binary_risk = c(X1 = 0.95, X2 = -0.75, X3 = 0.45),
    survival_ph = c(X1 = 0.7, X2 = -0.6, X3 = 0.35),
    count_rate = c(X1 = 0.85, X2 = -0.35, X3 = 0.25),
    nonlinear_exposure = c(X2 = -0.85, X4 = 0.15),
    cost_gamma = c(X1 = 0.65, X2 = -0.3, X3 = 0.2),
    endogeneity_iv = c(X1 = 0.8, X2 = -0.5, X3 = 0.4),
    policy_did = c(X1 = 0.7, X2 = -0.6, X3 = 0.3),
    panel_longitudinal = c(X1 = 0.75, X2 = -0.55, X3 = 0.25),
    causal_selection = c(X1 = 0.75, X2 = -0.7, X3 = 0.45),
    highdim_sparse = c(X1 = 0.5, X2 = -0.45, X3 = 0.3),
    c(X1 = 0.7, X2 = -0.5, X3 = 0.2)
  )
}

map_term_for_component <- function(term, dgp_id) {
  if (dgp_id == "policy_did" && term == "A") return("Treat_i")
  if (dgp_id == "panel_longitudinal" && term == "A") return("A_it")
  term
}

map_interaction_for_component <- function(term, dgp_id) {
  parts <- strsplit(term, ":", fixed = TRUE)[[1]]
  if (length(parts) != 2) return(term)
  parts <- vapply(parts, map_term_for_component, character(1), dgp_id = dgp_id)
  paste(parts, collapse = ":")
}

build_true_parameter_table <- function(dgp_id, n_covariates, interactions) {
  covariates <- paste0("X", seq_len(n_covariates))
  rows <- list()
  add_row <- function(component, term, value, note = "") {
    rows[[length(rows) + 1]] <<- data.frame(
      Component = component,
      Term = term,
      True_Value = format_num(value, digits = 3),
      Note = note,
      stringsAsFactors = FALSE
    )
  }
  add_note_row <- function(component, term, note = "") {
    rows[[length(rows) + 1]] <<- data.frame(
      Component = component,
      Term = term,
      True_Value = "-",
      Note = note,
      stringsAsFactors = FALSE
    )
  }

  beta_cross <- beta_cross_for_dgp(dgp_id)
  base_map <- base_covariate_coef(dgp_id)
  extra_covs <- setdiff(covariates, c("X1", "X2", "X3", "X4"))
  extra_coef_cross <- if (length(extra_covs) > 0) 0.08 / sqrt(length(extra_covs)) else NA_real_

  if (dgp_id %in% c("linear_continuous", "binary_risk", "survival_ph", "count_rate", "cost_gamma", "nonlinear_exposure")) {
    component <- "Main outcome equation"
    add_row(component, "A", beta_cross, "Treatment coefficient")
    for (cv in intersect(names(base_map), covariates)) {
      add_row(component, cv, base_map[[cv]], "Covariate coefficient")
    }
    if (length(extra_covs) > 0 && !is.na(extra_coef_cross)) {
      for (cv in extra_covs) {
        add_row(component, cv, extra_coef_cross, "Extra covariate coefficient")
      }
    }
    if (dgp_id == "nonlinear_exposure") {
      add_note_row(component, "sin(pi*X1)", "Nonlinear smooth component")
      add_row(component, "X3^2", 0.75, "Quadratic nonlinear component")
    }
  }

  if (dgp_id == "policy_did") {
    component <- "DiD outcome equation"
    add_row(component, "Treat_i", 0.4, "Baseline group difference")
    add_row(component, "Post_t", 0.6, "Common time trend")
    add_row(component, "Treat_i:Post_t", 1.3, "Policy effect")
    add_row(component, "X1", 0.7, "Covariate coefficient")
    add_row(component, "X2", -0.4, "Covariate coefficient")
    did_extra_covs <- setdiff(covariates, c("X1", "X2"))
    if (length(did_extra_covs) > 0) {
      did_extra_coef <- 0.05 / sqrt(length(did_extra_covs))
      for (cv in did_extra_covs) add_row(component, cv, did_extra_coef, "Extra covariate coefficient")
    }
  }

  if (dgp_id == "panel_longitudinal") {
    component <- "Panel outcome equation"
    add_row(component, "A_it", 1.0, "Treatment effect")
    add_row(component, "time_t", 0.5, "Time trend")
    add_row(component, "X1", 0.65, "Covariate coefficient")
    add_row(component, "X2", -0.45, "Covariate coefficient")
    panel_extra_covs <- setdiff(covariates, c("X1", "X2"))
    if (length(panel_extra_covs) > 0) {
      panel_extra_coef <- 0.05 / sqrt(length(panel_extra_covs))
      for (cv in panel_extra_covs) add_row(component, cv, panel_extra_coef, "Extra covariate coefficient")
    }
  }

  if (dgp_id == "endogeneity_iv") {
    add_row("Treatment assignment (latent index)", "Z", 0.9, "Instrument relevance")
    add_row("Treatment assignment (latent index)", "X1", 0.65, "Covariate coefficient")
    add_row("Treatment assignment (latent index)", "X2", -0.45, "Covariate coefficient")
    add_row("Outcome equation for IV target", "A_endo", 1.4, "Causal effect (LATE target)")
    add_row("Outcome equation for IV target", "X1", 0.8, "Covariate coefficient")
    add_row("Outcome equation for IV target", "X2", -0.6, "Covariate coefficient")
  }

  if (dgp_id == "causal_selection") {
    add_row("Treatment propensity index", "X1", 1.1, "Selection into treatment")
    add_row("Treatment propensity index", "X2", -1.0, "Selection into treatment")
    add_row("Treatment propensity index", "X3", 0.7, "Selection into treatment")
    add_row("Baseline outcome mu0", "X1", 0.9, "Outcome confounding")
    add_row("Baseline outcome mu0", "X2", -0.65, "Outcome confounding")
    add_row("Baseline outcome mu0", "X3", 0.45, "Outcome confounding")
    add_row("Treatment effect function tau(X)", "tau_intercept", 0.45, "Base treatment effect")
    add_row("Treatment effect function tau(X)", "X1", 0.5, "Heterogeneous treatment effect")
  }

  if (dgp_id == "highdim_sparse") {
    add_row("High-dimensional outcome", "A", 1.0, "Treatment coefficient")
    add_row("High-dimensional outcome", "W1", 1.1, "Active signal")
    add_row("High-dimensional outcome", "W4", -1.0, "Active signal")
    add_row("High-dimensional outcome", "W7", 0.8, "Active signal")
    add_row("High-dimensional outcome", "W11", -0.6, "Active signal")
    add_note_row("High-dimensional outcome", "Other W_j", "Set to 0 (sparsity)")
  }

  if (length(interactions) > 0) {
    component <- switch(
      dgp_id,
      policy_did = "DiD interaction terms",
      panel_longitudinal = "Panel interaction terms",
      "Selected interaction terms"
    )
    for (term in interactions) {
      mapped <- map_interaction_for_component(term, dgp_id = dgp_id)
      add_row(component, mapped, interaction_gamma_value(term), "User-selected interaction")
    }
  }

  if (length(rows) == 0) {
    return(data.frame(
      Component = "Main outcome equation",
      Term = "A",
      True_Value = format_num(beta_cross),
      Note = "Treatment coefficient",
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

build_dag_spec <- function(dgp_id, covariates, interactions) {
  nodes <- data.frame(id = character(), label = character(), type = character(), stringsAsFactors = FALSE)
  edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)

  add_node <- function(id, label = id, type = "observed") {
    if (!(id %in% nodes$id)) {
      nodes <<- rbind(nodes, data.frame(id = id, label = label, type = type, stringsAsFactors = FALSE))
    }
  }
  add_edge <- function(from, to) {
    edges <<- rbind(edges, data.frame(from = from, to = to, stringsAsFactors = FALSE))
  }

  outcome_id <- switch(
    dgp_id,
    binary_risk = "Y_logit",
    survival_ph = "hazard",
    count_rate = "log_mean_count",
    cost_gamma = "log_mean_cost",
    policy_did = "Y_it",
    panel_longitudinal = "Y_it",
    "Y"
  )
  outcome_label <- switch(
    dgp_id,
    binary_risk = "logit(P(Y=1))",
    survival_ph = "h(t|X)",
    count_rate = "log E[Y|X]",
    cost_gamma = "log E[Cost|X]",
    policy_did = "Y_it",
    panel_longitudinal = "Y_it",
    "Y"
  )

  for (cv in covariates) add_node(cv, label = cv, type = "covariate")
  add_node(outcome_id, label = outcome_label, type = "outcome")

  if (dgp_id == "endogeneity_iv") {
    add_node("A_endo", label = "A_endo", type = "treatment")
    add_node("Z", label = "Z", type = "instrument")
    add_node("U", label = "U (unobs)", type = "latent")
    for (cv in covariates) {
      add_edge(cv, "A_endo")
      add_edge(cv, outcome_id)
    }
    add_edge("Z", "A_endo")
    add_edge("U", "A_endo")
    add_edge("U", outcome_id)
    add_edge("A_endo", outcome_id)
  } else if (dgp_id == "policy_did") {
    add_node("Treat", label = "Treat_i", type = "treatment")
    add_node("Post", label = "Post_t", type = "time")
    add_node("TreatPost", label = "Treat_i*Post_t", type = "interaction")
    for (cv in covariates) add_edge(cv, outcome_id)
    add_edge("Treat", "TreatPost")
    add_edge("Post", "TreatPost")
    add_edge("Treat", outcome_id)
    add_edge("Post", outcome_id)
    add_edge("TreatPost", outcome_id)
  } else if (dgp_id == "panel_longitudinal") {
    add_node("A_it", label = "A_it", type = "treatment")
    add_node("time_t", label = "time_t", type = "time")
    add_node("b_i", label = "b_i (unobs)", type = "latent")
    for (cv in covariates) {
      add_edge(cv, "A_it")
      add_edge(cv, outcome_id)
    }
    add_edge("time_t", "A_it")
    add_edge("time_t", outcome_id)
    add_edge("A_it", outcome_id)
    add_edge("b_i", outcome_id)
  } else if (dgp_id == "causal_selection") {
    add_node("A", label = "A", type = "treatment")
    add_node("U", label = "U (unobs)", type = "latent")
    for (cv in covariates) {
      add_edge(cv, "A")
      add_edge(cv, outcome_id)
    }
    add_edge("U", "A")
    add_edge("U", outcome_id)
    add_edge("A", outcome_id)
  } else {
    add_node("A", label = "A", type = "treatment")
    for (cv in covariates) {
      add_edge(cv, "A")
      add_edge(cv, outcome_id)
    }
    add_edge("A", outcome_id)
    if (dgp_id == "highdim_sparse") {
      add_node("W_block", label = "W1..W20", type = "covariate")
      add_edge("W_block", outcome_id)
    }
  }

  if (length(interactions) > 0) {
    for (i in seq_along(interactions)) {
      parts <- strsplit(interactions[i], ":", fixed = TRUE)[[1]]
      if (length(parts) != 2) next

      p1 <- plain_var(parts[1], dgp_id = dgp_id)
      p2 <- plain_var(parts[2], dgp_id = dgp_id)

      p1_id <- switch(p1, Treat = "Treat", A_it = "A_it", p1)
      p2_id <- switch(p2, Treat = "Treat", A_it = "A_it", p2)

      if (!(p1_id %in% nodes$id) || !(p2_id %in% nodes$id)) next
      int_id <- paste0("Int", i)
      int_label <- paste0(p1, "*", p2)
      add_node(int_id, label = int_label, type = "interaction")
      add_edge(p1_id, int_id)
      add_edge(p2_id, int_id)
      add_edge(int_id, outcome_id)
    }
  }

  edges <- unique(edges)
  list(nodes = nodes, edges = edges)
}

dag_to_dot <- function(dag) {
  type_style <- list(
    covariate = list(fill = "#dceaf7", shape = "box"),
    treatment = list(fill = "#b8d1e8", shape = "box"),
    interaction = list(fill = "#cfd8e2", shape = "ellipse"),
    outcome = list(fill = "#5f6b7a", shape = "box"),
    instrument = list(fill = "#bed5ea", shape = "diamond"),
    time = list(fill = "#d8e3ef", shape = "box"),
    latent = list(fill = "#d9d9d9", shape = "ellipse"),
    observed = list(fill = "#e7f0f8", shape = "box")
  )

  node_lines <- vapply(seq_len(nrow(dag$nodes)), function(i) {
    nd <- dag$nodes[i, ]
    st <- type_style[[nd$type]]
    if (is.null(st)) st <- type_style$observed
    font_color <- if (nd$type == "outcome") "#ffffff" else "#203140"
    paste0(
      "\"", nd$id, "\" [label=\"", nd$label, "\", shape=", st$shape,
      ", style=\"filled,rounded\", fillcolor=\"", st$fill, "\", fontcolor=\"", font_color, "\"];"
    )
  }, character(1))

  edge_lines <- vapply(seq_len(nrow(dag$edges)), function(i) {
    ed <- dag$edges[i, ]
    paste0("\"", ed$from, "\" -> \"", ed$to, "\";")
  }, character(1))

  paste(
    c(
      "digraph SpecificationDAG {",
      "graph [rankdir=LR, bgcolor=\"#f7fbff\"];",
      "node [fontname=\"Helvetica\", color=\"#355670\"];",
      "edge [color=\"#5f6b7a\", arrowsize=0.7];",
      node_lines,
      edge_lines,
      "}"
    ),
    collapse = "\n"
  )
}

generate_simulation <- function(dgp_id, n, seed, n_covariates = 8, interaction_terms = character()) {
  set.seed(seed)

  X <- build_covariates(n = n, n_covariates = n_covariates)
  covariate_names <- names(X)
  x <- function(j, default = 0) {
    nm <- paste0("X", j)
    if (nm %in% names(X)) X[[nm]] else rep(default, n)
  }
  X1 <- x(1)
  X2 <- x(2)
  X3 <- x(3)
  X4 <- x(4)
  X5 <- x(5)
  X6 <- x(6)
  X7 <- x(7)
  X8 <- x(8)

  Z <- rbinom(n, 1, 0.5)
  U <- rnorm(n)

  p_treat <- inv_logit(-0.3 + 0.8 * X1 - 0.7 * X2 + 0.5 * X3 + 0.5 * Z + 0.7 * U)
  if (dgp_id == "causal_selection") {
    p_treat <- inv_logit(-0.6 + 1.1 * X1 - 1.0 * X2 + 0.7 * X3 + 0.9 * U)
  }
  A <- rbinom(n, 1, p_treat)
  interaction_info <- build_interaction_signal(interaction_terms = interaction_terms, X = X, A = A)

  extra_covs <- setdiff(names(X), c("X1", "X2", "X3", "X4"))
  extra_signal <- if (length(extra_covs) > 0) {
    as.numeric(as.matrix(X[, extra_covs, drop = FALSE]) %*%
      rep(0.08 / sqrt(length(extra_covs)), length(extra_covs)))
  } else {
    rep(0, n)
  }

  beta_cross <- switch(
    dgp_id,
    linear_continuous = 0.9,
    binary_risk = 1.1,
    survival_ph = 0.85,
    count_rate = 0.75,
    nonlinear_exposure = 0.9,
    cost_gamma = 0.55,
    endogeneity_iv = 1.15,
    policy_did = 0.8,
    panel_longitudinal = 0.75,
    causal_selection = 0.65,
    highdim_sparse = 0.5,
    0.8
  )
  avg_treat_lp <- beta_cross + mean(interaction_info$treat_modifier)

  eta_true <- switch(
    dgp_id,
    nonlinear_exposure = 0.2 + beta_cross * A + sin(pi * X1) + 0.75 * (X3^2) - 0.85 * X2 + 0.15 * X4,
    endogeneity_iv = 0.1 + beta_cross * A + 0.8 * X1 - 0.5 * X2 + 0.4 * X3 + 1.0 * U,
    binary_risk = -0.8 + beta_cross * A + 0.95 * X1 - 0.75 * X2 + 0.45 * X3,
    survival_ph = -0.6 + beta_cross * A + 0.7 * X1 - 0.6 * X2 + 0.35 * X3,
    count_rate = 0.1 + beta_cross * A + 0.85 * X1 - 0.35 * X2 + 0.25 * X3,
    cost_gamma = 1.1 + beta_cross * A + 0.65 * X1 - 0.3 * X2 + 0.2 * X3,
    linear_continuous = 0.25 + beta_cross * A + 1.0 * X1 - 0.8 * X2 + 0.5 * X3,
    policy_did = 0.35 + beta_cross * A + 0.7 * X1 - 0.6 * X2 + 0.3 * X3,
    panel_longitudinal = 0.3 + beta_cross * A + 0.75 * X1 - 0.55 * X2 + 0.25 * X3,
    causal_selection = 0.2 + beta_cross * A + 0.75 * X1 - 0.7 * X2 + 0.45 * X3,
    highdim_sparse = 0.2 + beta_cross * A + 0.5 * X1 - 0.45 * X2 + 0.3 * X3,
    0.3 + beta_cross * A + 0.7 * X1 - 0.5 * X2 + 0.2 * X3
  )
  eta_true <- eta_true + interaction_info$signal + extra_signal

  Y_cont <- eta_true + rnorm(n, sd = 1)
  p_bin <- inv_logit(eta_true)
  Y_bin <- rbinom(n, 1, p_bin)

  eta_exp <- pmin(pmax(eta_true, -4), 4)
  lambda_count <- exp(eta_exp)
  if (dgp_id == "count_rate") {
    Y_count <- rnbinom(n, size = 1.6, mu = lambda_count)
  } else {
    Y_count <- rpois(n, lambda = lambda_count)
  }

  mu_cost <- exp(eta_exp)
  Y_cost <- rgamma(n, shape = 2.4, scale = mu_cost / 2.4)

  rate_surv <- exp(eta_exp - 2.1)
  event_time <- rexp(n, rate = rate_surv)
  censor_time <- rexp(n, rate = 0.12)
  time <- pmin(event_time, censor_time)
  event <- as.integer(event_time <= censor_time)

  A_endo <- as.integer(0.9 * Z + 0.8 * U + 0.65 * X1 - 0.45 * X2 + rnorm(n) > 0)
  beta_iv <- if (dgp_id == "endogeneity_iv") 1.4 else 0.9
  mu_iv <- 0.5 + beta_iv * A_endo + 0.8 * X1 - 0.6 * X2 + 1.1 * U
  Y_iv <- mu_iv + rnorm(n, sd = 1)

  tau <- if (dgp_id == "causal_selection") 0.45 + 0.5 * X1 else 0.6 + 0.1 * X1
  tau <- tau + interaction_info$treat_modifier
  mu0 <- 1.0 + 0.9 * X1 - 0.65 * X2 + 0.45 * X3 + 0.55 * U
  mu1 <- mu0 + tau
  mu_causal <- mu0 + tau * A
  Y_causal <- mu_causal + rnorm(n, sd = 1)
  ate_true <- mean(tau)

  n_panel_id <- max(60, floor(n / 3))
  id_panel <- seq_len(n_panel_id)
  panel_cov <- build_covariates(n_panel_id, n_covariates)
  panel_cov$id <- id_panel
  panel_cov$b_i <- rnorm(n_panel_id, sd = 0.8)
  panel_df <- expand.grid(id = id_panel, time = 0:3) %>%
    left_join(panel_cov, by = "id")

  panel_df$A <- rbinom(
    nrow(panel_df),
    1,
    inv_logit(-0.2 + 0.6 * panel_df$X1 - 0.5 * panel_df$X2 + 0.2 * panel_df$time)
  )
  beta_panel <- if (dgp_id == "panel_longitudinal") 1.0 else 0.6
  panel_cov_extra <- setdiff(covariate_names, c("X1", "X2"))
  panel_extra_signal <- if (length(panel_cov_extra) > 0) {
    as.numeric(as.matrix(panel_df[, panel_cov_extra, drop = FALSE]) %*%
      rep(0.05 / sqrt(length(panel_cov_extra)), length(panel_cov_extra)))
  } else {
    rep(0, nrow(panel_df))
  }
  panel_int <- build_interaction_signal(
    interaction_terms = interaction_info$used_terms,
    X = panel_df[, covariate_names, drop = FALSE],
    A = panel_df$A
  )
  panel_df$eta_fixed_panel <- 1.2 + beta_panel * panel_df$A + 0.5 * panel_df$time +
    0.65 * panel_df$X1 - 0.45 * panel_df$X2 + panel_extra_signal + panel_int$signal
  panel_df$eta_true_panel <- panel_df$eta_fixed_panel + panel_df$b_i
  panel_df$Y_panel <- panel_df$eta_true_panel + rnorm(nrow(panel_df), sd = 0.9)

  n_did_id <- max(80, floor(n / 2))
  did_cov <- build_covariates(n_did_id, n_covariates)
  did_cov$id <- seq_len(n_did_id)
  did_cov$group <- rbinom(n_did_id, 1, 0.5)
  did_cov$u_i <- rnorm(n_did_id, sd = 0.6)
  did_df <- expand.grid(id = seq_len(n_did_id), post = 0:1) %>%
    left_join(did_cov, by = "id")
  did_effect <- if (dgp_id == "policy_did") 1.3 else 0.7
  did_cov_extra <- setdiff(covariate_names, c("X1", "X2"))
  did_extra_signal <- if (length(did_cov_extra) > 0) {
    as.numeric(as.matrix(did_df[, did_cov_extra, drop = FALSE]) %*%
      rep(0.05 / sqrt(length(did_cov_extra)), length(did_cov_extra)))
  } else {
    rep(0, nrow(did_df))
  }
  did_int <- build_interaction_signal(
    interaction_terms = interaction_info$used_terms,
    X = did_df[, covariate_names, drop = FALSE],
    A = did_df$group
  )
  did_df$eta_true_did <- 4.2 + 0.4 * did_df$group + 0.6 * did_df$post +
    did_effect * (did_df$group * did_df$post) + 0.7 * did_df$X1 - 0.4 * did_df$X2 +
    did_extra_signal + did_int$signal + did_df$u_i
  did_df$Y_did <- did_df$eta_true_did + rnorm(nrow(did_df), sd = 1)

  W <- replicate(20, rnorm(n))
  colnames(W) <- paste0("W", seq_len(ncol(W)))
  W <- as.data.frame(W)
  beta_hd <- if (dgp_id == "highdim_sparse") 1.0 else 0.5
  beta_w <- rep(0, 20)
  beta_w[c(1, 4, 7, 11)] <- c(1.1, -1.0, 0.8, -0.6)
  eta_true_hd <- 0.2 + beta_hd * A + as.numeric(as.matrix(W) %*% beta_w)
  Y_hd <- eta_true_hd + rnorm(n, sd = 1)

  cross_df <- data.frame(
    id = seq_len(n),
    cluster = sample(seq_len(max(20, floor(n / 30))), n, replace = TRUE),
    A = A,
    Z = Z,
    A_endo = A_endo
  )
  cross_df <- cbind(cross_df, X)
  cross_df <- cbind(
    cross_df,
    data.frame(
      eta_true = eta_true,
      Y_cont = Y_cont,
      Y_bin = Y_bin,
      p_bin = p_bin,
      Y_count = Y_count,
      lambda_count = lambda_count,
      Y_cost = Y_cost,
      mu_cost = mu_cost,
      time = time,
      event = event,
      Y_iv = Y_iv,
      mu_iv = mu_iv,
      Y_causal = Y_causal,
      mu_causal = mu_causal,
      tau_true = tau,
      ate_true = ate_true
    )
  )

  hd_df <- cbind(
    data.frame(
      id = cross_df$id,
      A = A,
      Y_hd = Y_hd,
      eta_true_hd = eta_true_hd
    ),
    W
  )

  cross_split <- make_split(nrow(cross_df), prop = 0.7)
  hd_split <- make_split(nrow(hd_df), prop = 0.7)
  panel_split <- split_by_id(panel_df, id_col = "id", prop = 0.7)
  did_split <- split_by_id(did_df, id_col = "id", prop = 0.7)

  info <- dgp_catalog[[dgp_id]]
  structural_spec <- build_dynamic_equations(
    dgp_id = dgp_id,
    covariates = covariate_names,
    interactions = interaction_info$used_terms
  )
  dag_spec <- build_dag_spec(
    dgp_id = dgp_id,
    covariates = covariate_names,
    interactions = interaction_info$used_terms
  )

  true_params <- c(
    logistic = avg_treat_lp,
    cox = avg_treat_lp,
    poisson_nb = avg_treat_lp,
    linear_regression = avg_treat_lp,
    gam = avg_treat_lp,
    ols = avg_treat_lp,
    glm_gamma = avg_treat_lp,
    iv_2sls = beta_iv,
    did = did_effect + mean(did_int$treat_modifier),
    gee_re = beta_panel + mean(panel_int$treat_modifier),
    psm = ate_true,
    dml = ate_true,
    tmle = ate_true,
    aipw = ate_true,
    sem_dag = avg_treat_lp,
    lasso = beta_hd,
    rf_xgb = NA_real_,
    elastic_net = beta_hd,
    neural_net = NA_real_,
    meta_learner = ate_true
  )

  list(
    dgp_id = dgp_id,
    info = info,
    covariate_names = covariate_names,
    n_covariates = n_covariates,
    interaction_terms = interaction_info$used_terms,
    interaction_coefficients = interaction_info$coefficients,
    equation_dynamic = structural_spec$main,
    structural_equations = structural_spec$structural,
    dag_spec = dag_spec,
    cross_full = cross_df,
    hd_full = hd_df,
    panel_full = panel_df,
    did_full = did_df,
    cross_train = cross_df[cross_split$train, , drop = FALSE],
    cross_test = cross_df[cross_split$test, , drop = FALSE],
    hd_train = hd_df[hd_split$train, , drop = FALSE],
    hd_test = hd_df[hd_split$test, , drop = FALSE],
    panel_train = panel_split$train,
    panel_test = panel_split$test,
    did_train = did_split$train,
    did_test = did_split$test,
    true_params = true_params
  )
}

coeff_table_from_matrix <- function(mat) {
  if (is.null(dim(mat))) {
    return(data.frame(Term = character(), Estimate = numeric(), Std_Error = numeric(), P_Value = numeric()))
  }

  cn <- tolower(colnames(mat))
  est_idx <- which(cn %in% c("estimate", "coef", "value", "coefficients"))[1]
  if (is.na(est_idx)) est_idx <- 1

  se_idx <- grep("std\\.? ?error|se\\(|std\\.err|std\\.error|std\\. deviation", cn)[1]
  p_idx <- grep("pr|p\\.?value|p-value|pvalue", cn)[1]

  out <- data.frame(
    Term = rownames(mat),
    Estimate = as.numeric(mat[, est_idx]),
    Std_Error = if (!is.na(se_idx)) as.numeric(mat[, se_idx]) else NA_real_,
    P_Value = if (!is.na(p_idx)) as.numeric(mat[, p_idx]) else NA_real_,
    stringsAsFactors = FALSE
  )
  out
}

coeff_table_glmnet <- function(cvfit, term_prefix = "") {
  co <- as.matrix(stats::coef(cvfit, s = "lambda.min"))
  df <- data.frame(
    Term = rownames(co),
    Estimate = as.numeric(co[, 1]),
    Std_Error = NA_real_,
    P_Value = NA_real_,
    stringsAsFactors = FALSE
  )
  if (nzchar(term_prefix)) {
    df$Term <- paste0(term_prefix, df$Term)
  }
  df
}

metrics_from_pred <- function(pred, truth) {
  keep <- is.finite(pred) & is.finite(truth)
  if (!any(keep)) {
    return(c(mean_bias = NA_real_, mae = NA_real_, rmse = NA_real_))
  }
  pred <- pred[keep]
  truth <- truth[keep]
  c(
    mean_bias = mean(pred - truth),
    mae = mean(abs(pred - truth)),
    rmse = sqrt(mean((pred - truth)^2))
  )
}

result_skeleton <- function(model_id) {
  list(
    model_id = model_id,
    model_label = model_labels[[model_id]],
    status = "ok",
    message = "",
    summary_text = "",
    coef_table = data.frame(Term = character(), Estimate = numeric(), Std_Error = numeric(), P_Value = numeric()),
    theta_hat = NA_real_,
    theta_true = NA_real_,
    theta_label = "Treatment effect",
    pred_df = NULL,
    preview_df = NULL
  )
}

fit_model <- function(model_id, sim) {
  res <- result_skeleton(model_id)
  preview_cols <- function(df, outcome, include = character(), n_cov = 3) {
    covs <- head(get_covariate_names(df), n_cov)
    unique(c(outcome, include, covs))
  }

  tryCatch({
    if (model_id == "logistic") {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 6)
      fit <- glm(build_formula("Y_bin", c("A", covs)), family = binomial(), data = train)
      p <- clamp(predict(fit, newdata = test, type = "response"))
      eta_pred <- qlogis(p)
      res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
      res$theta_hat <- unname(coef(fit)["A"])
      res$theta_true <- sim$true_params[["logistic"]]
      res$summary_text <- "Binary outcome model fit on log-odds scale."
      res$pred_df <- data.frame(truth = test$eta_true, pred = eta_pred, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_bin", "A"), drop = FALSE], 8)

    } else if (model_id == "cox") {
      if (!safe_require("survival")) stop("Package 'survival' is required for Cox models.")
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 5)
      fit <- survival::coxph(build_formula("survival::Surv(time, event)", c("A", covs)), data = train)
      lp <- as.numeric(predict(fit, newdata = test, type = "lp"))
      cox_mat <- summary(fit)$coefficients[, c("coef", "se(coef)", "Pr(>|z|)"), drop = FALSE]
      colnames(cox_mat) <- c("Estimate", "Std.Error", "Pr(>|z|)")
      res$coef_table <- coeff_table_from_matrix(cox_mat)
      res$theta_hat <- unname(coef(fit)["A"])
      res$theta_true <- sim$true_params[["cox"]]
      res$summary_text <- "Semi-parametric proportional hazards model."
      res$pred_df <- data.frame(truth = test$eta_true, pred = lp, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "time", c("event", "A")), drop = FALSE], 8)

    } else if (model_id == "poisson_nb") {
      train <- sim$cross_train
      test <- sim$cross_test
      overdisp <- var(train$Y_count) > mean(train$Y_count) * 1.5
      covs <- pick_covariates(train, 6)
      f_count <- build_formula("Y_count", c("A", covs))

      if (overdisp && safe_require("MASS")) {
        fit <- MASS::glm.nb(f_count, data = train)
        res$summary_text <- "Negative Binomial model selected because overdispersion was detected."
      } else {
        fit <- glm(f_count, family = poisson(), data = train)
        res$summary_text <- "Poisson model fit."
      }

      mu_pred <- pmax(predict(fit, newdata = test, type = "response"), 1e-8)
      eta_pred <- log(mu_pred)
      res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
      res$theta_hat <- unname(coef(fit)["A"])
      res$theta_true <- sim$true_params[["poisson_nb"]]
      res$pred_df <- data.frame(truth = test$eta_true, pred = eta_pred, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_count", "A"), drop = FALSE], 8)

    } else if (model_id %in% c("linear_regression", "ols")) {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 6)
      fit <- lm(build_formula("Y_cont", c("A", covs)), data = train)
      yhat <- predict(fit, newdata = test)
      res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
      res$theta_hat <- unname(coef(fit)["A"])
      res$theta_true <- sim$true_params[[model_id]]
      res$summary_text <- "Linear additive model fit for continuous outcome."
      res$pred_df <- data.frame(truth = test$eta_true, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_cont", "A"), drop = FALSE], 8)

    } else if (model_id == "gam") {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 6)
      smooth_covs <- unique(head(covs[c(1, min(3, length(covs)))], 2))
      linear_covs <- setdiff(covs, smooth_covs)
      if (safe_require("mgcv")) {
        rhs_terms <- c("A", paste0("s(", smooth_covs, ")"), linear_covs)
        fit <- mgcv::gam(build_formula("Y_cont", rhs_terms), data = train)
        yhat <- predict(fit, newdata = test)
        res$coef_table <- coeff_table_from_matrix(summary(fit)$p.table)
        res$theta_hat <- unname(coef(fit)["A"])
        res$summary_text <- "GAM with smooth terms for nonlinear covariates."
      } else {
        poly_terms <- character()
        if (length(smooth_covs) >= 1) poly_terms <- c(poly_terms, paste0("poly(", smooth_covs[1], ", 3)"))
        if (length(smooth_covs) >= 2) poly_terms <- c(poly_terms, paste0("poly(", smooth_covs[2], ", 2)"))
        fit <- lm(build_formula("Y_cont", c("A", poly_terms, linear_covs)), data = train)
        yhat <- predict(fit, newdata = test)
        res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
        res$theta_hat <- unname(coef(fit)["A"])
        res$summary_text <- "Package 'mgcv' not found. Fallback used polynomial linear model."
        res$status <- "warning"
      }
      res$theta_true <- sim$true_params[["gam"]]
      res$pred_df <- data.frame(truth = test$eta_true, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_cont", "A"), drop = FALSE], 8)

    } else if (model_id == "glm_gamma") {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 6)
      fit <- glm(build_formula("Y_cost", c("A", covs)), family = Gamma(link = "log"), data = train)
      mu_pred <- pmax(predict(fit, newdata = test, type = "response"), 1e-8)
      eta_pred <- log(mu_pred)
      res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
      res$theta_hat <- unname(coef(fit)["A"])
      res$theta_true <- sim$true_params[["glm_gamma"]]
      res$summary_text <- "Gamma GLM with log link for skewed non-negative outcomes."
      res$pred_df <- data.frame(truth = test$eta_true, pred = eta_pred, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_cost", "A"), drop = FALSE], 8)

    } else if (model_id == "iv_2sls") {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 5)
      iv_rhs <- c("A_endo", covs)
      iv_inst <- c("Z", covs)

      if (safe_require("AER")) {
        f_iv <- as.formula(
          paste(
            "Y_iv ~", paste(iv_rhs, collapse = " + "),
            "|", paste(iv_inst, collapse = " + ")
          )
        )
        fit <- AER::ivreg(f_iv, data = train)
        yhat <- predict(fit, newdata = test)
        res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
        res$theta_hat <- unname(coef(fit)["A_endo"])
        res$summary_text <- "2SLS estimated with AER::ivreg."
      } else {
        stage1 <- lm(build_formula("A_endo", c("Z", covs)), data = train)
        train$A_hat <- predict(stage1, newdata = train)
        stage2 <- lm(build_formula("Y_iv", c("A_hat", covs)), data = train)
        test$A_hat <- predict(stage1, newdata = test)
        yhat <- predict(stage2, newdata = test)
        res$coef_table <- coeff_table_from_matrix(summary(stage2)$coefficients)
        res$coef_table$Term[res$coef_table$Term == "A_hat"] <- "A_endo (2SLS)"
        res$theta_hat <- unname(coef(stage2)["A_hat"])
        res$summary_text <- "AER not found. Manual two-stage least squares fallback was used."
        res$status <- "warning"
      }

      res$theta_true <- sim$true_params[["iv_2sls"]]
      res$pred_df <- data.frame(truth = test$mu_iv, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_iv", c("A_endo", "Z")), drop = FALSE], 8)

    } else if (model_id == "did") {
      train <- sim$did_train
      test <- sim$did_test
      covs <- pick_covariates(train, 6)
      fit <- lm(build_formula("Y_did", c("group", "post", "group:post", covs)), data = train)
      yhat <- predict(fit, newdata = test)
      res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
      res$theta_hat <- unname(coef(fit)["group:post"])
      res$theta_true <- sim$true_params[["did"]]
      res$theta_label <- "Policy effect (DiD interaction)"
      res$summary_text <- "Difference-in-Differences model estimated on panel-style data."
      res$pred_df <- data.frame(truth = test$eta_true_did, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_did", c("group", "post")), drop = FALSE], 8)

    } else if (model_id == "gee_re") {
      train <- sim$panel_train
      test <- sim$panel_test
      covs <- pick_covariates(train, 6)
      rhs <- c("A", "time", covs)

      if (safe_require("geepack")) {
        fit <- geepack::geeglm(build_formula("Y_panel", rhs), id = id, corstr = "exchangeable", data = train)
        yhat <- predict(fit, newdata = test, type = "response")
        gee_mat <- summary(fit)$coefficients
        res$coef_table <- coeff_table_from_matrix(gee_mat)
        res$theta_hat <- unname(coef(fit)["A"])
        res$summary_text <- "GEE with exchangeable working correlation."
      } else if (safe_require("nlme")) {
        fit <- nlme::lme(build_formula("Y_panel", rhs), random = ~1 | id, data = train)
        yhat <- predict(fit, newdata = test, level = 0)
        res$coef_table <- coeff_table_from_matrix(summary(fit)$tTable)
        res$theta_hat <- unname(nlme::fixef(fit)["A"])
        res$summary_text <- "geepack not found. Random intercept model (nlme::lme) used."
        res$status <- "warning"
      } else {
        fit <- lm(build_formula("Y_panel", rhs), data = train)
        yhat <- predict(fit, newdata = test)
        res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
        res$theta_hat <- unname(coef(fit)["A"])
        res$summary_text <- "Neither geepack nor nlme found. Simple linear fallback used."
        res$status <- "warning"
      }

      res$theta_true <- sim$true_params[["gee_re"]]
      res$pred_df <- data.frame(truth = test$eta_fixed_panel, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_panel", c("id", "time", "A")), drop = FALSE], 8)

    } else if (model_id == "psm") {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 6)

      ps_fit <- glm(build_formula("A", covs), family = binomial(), data = train)
      p_hat <- clamp(predict(ps_fit, type = "response"))
      w <- ifelse(train$A == 1, 1 / p_hat, 1 / (1 - p_hat))

      out_fit <- lm(build_formula("Y_causal", c("A", covs)), data = train, weights = w)
      yhat <- predict(out_fit, newdata = test)

      res$coef_table <- coeff_table_from_matrix(summary(out_fit)$coefficients)
      res$theta_hat <- unname(coef(out_fit)["A"])
      res$theta_true <- sim$true_params[["psm"]]
      res$theta_label <- "Average treatment effect (approx.)"
      res$summary_text <- "Propensity-score weighting plus outcome regression."
      res$pred_df <- data.frame(truth = test$mu_causal, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_causal", "A"), drop = FALSE], 8)

    } else if (model_id == "dml") {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 6)

      n <- nrow(train)
      fold <- sample(rep(1:2, length.out = n))
      m_hat <- rep(NA_real_, n)
      e_hat <- rep(NA_real_, n)

      for (k in 1:2) {
        idx_hold <- which(fold == k)
        idx_fit <- setdiff(seq_len(n), idx_hold)

        m_fit <- lm(build_formula("Y_causal", covs), data = train[idx_fit, , drop = FALSE])
        e_fit <- glm(build_formula("A", covs), family = binomial(), data = train[idx_fit, , drop = FALSE])

        m_hat[idx_hold] <- predict(m_fit, newdata = train[idx_hold, , drop = FALSE])
        e_hat[idx_hold] <- clamp(predict(e_fit, newdata = train[idx_hold, , drop = FALSE], type = "response"))
      }

      theta_fit <- lm(I(Y_causal - m_hat) ~ 0 + I(A - e_hat), data = train)
      theta_hat <- unname(coef(theta_fit)[1])

      m_full <- lm(build_formula("Y_causal", covs), data = train)
      e_full <- glm(build_formula("A", covs), family = binomial(), data = train)
      m_test <- predict(m_full, newdata = test)
      e_test <- clamp(predict(e_full, newdata = test, type = "response"))
      yhat <- m_test + theta_hat * (test$A - e_test)

      res$coef_table <- data.frame(
        Term = "A (orthogonalized)",
        Estimate = theta_hat,
        Std_Error = NA_real_,
        P_Value = NA_real_,
        stringsAsFactors = FALSE
      )
      res$theta_hat <- theta_hat
      res$theta_true <- sim$true_params[["dml"]]
      res$theta_label <- "Average treatment effect (DML)"
      res$summary_text <- "Cross-fitted orthogonal score implementation of partialling-out DML."
      res$pred_df <- data.frame(truth = test$mu_causal, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_causal", "A"), drop = FALSE], 8)

    } else if (model_id %in% c("tmle", "aipw")) {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 6)

      ps_fit <- glm(build_formula("A", covs), family = binomial(), data = train)
      p_train <- clamp(predict(ps_fit, type = "response"))
      p_test <- clamp(predict(ps_fit, newdata = test, type = "response"))

      mu1_fit <- lm(build_formula("Y_causal", covs), data = train[train$A == 1, , drop = FALSE])
      mu0_fit <- lm(build_formula("Y_causal", covs), data = train[train$A == 0, , drop = FALSE])

      mu1_train <- predict(mu1_fit, newdata = train)
      mu0_train <- predict(mu0_fit, newdata = train)
      mu1_test <- predict(mu1_fit, newdata = test)
      mu0_test <- predict(mu0_fit, newdata = test)

      aipw_score <- (mu1_train - mu0_train) +
        train$A * (train$Y_causal - mu1_train) / p_train -
        (1 - train$A) * (train$Y_causal - mu0_train) / (1 - p_train)
      theta_hat <- mean(aipw_score)

      if (model_id == "tmle" && safe_require("tmle")) {
        tm <- tmle::tmle(
          Y = train$Y_causal,
          A = train$A,
          W = train[, covs, drop = FALSE],
          family = "gaussian"
        )
        theta_hat <- unname(tm$estimates$ATE$psi)
        res$summary_text <- "TMLE estimated with tmle package."
      } else if (model_id == "tmle") {
        res$summary_text <- "Package 'tmle' not found. AIPW-style doubly robust fallback used."
        res$status <- "warning"
      } else {
        res$summary_text <- "Augmented inverse probability weighting (AIPW) estimator."
      }

      yhat <- mu0_test + (mu1_test - mu0_test) * test$A
      res$coef_table <- data.frame(
        Term = if (model_id == "tmle") "ATE (TMLE)" else "ATE (AIPW)",
        Estimate = theta_hat,
        Std_Error = NA_real_,
        P_Value = NA_real_,
        stringsAsFactors = FALSE
      )
      res$theta_hat <- theta_hat
      res$theta_true <- sim$true_params[[model_id]]
      res$theta_label <- "Average treatment effect"
      res$pred_df <- data.frame(truth = test$mu_causal, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_causal", "A"), drop = FALSE], 8)

    } else if (model_id == "sem_dag") {
      train <- sim$cross_train
      test <- sim$cross_test
      covs <- pick_covariates(train, 3)
      y_rhs <- if (length(covs) > 0) paste(c("A", covs), collapse = " + ") else "A"
      a_rhs <- if (length(covs) > 0) paste(covs, collapse = " + ") else "1"
      lavaan_ok <- FALSE
      if (safe_require("lavaan")) {
        sem_try <- tryCatch({
          sem_spec <- paste0(
            "A ~ ", a_rhs, "\n",
            "Y_cont ~ ", y_rhs, "\n"
          )
          fit <- lavaan::sem(sem_spec, data = train, meanstructure = TRUE)
          pe <- lavaan::parameterEstimates(fit)
          reg_pe <- pe[pe$op == "~" & pe$lhs == "Y_cont", c("rhs", "est", "se", "pvalue")]
          if (nrow(reg_pe) == 0) stop("No Y_cont regression coefficients were returned by lavaan.")

          res$coef_table <- data.frame(
            Term = reg_pe$rhs,
            Estimate = reg_pe$est,
            Std_Error = reg_pe$se,
            P_Value = reg_pe$pvalue,
            stringsAsFactors = FALSE
          )
          theta_row <- reg_pe[reg_pe$rhs == "A", , drop = FALSE]
          res$theta_hat <- if (nrow(theta_row) == 1) theta_row$est else NA_real_

          out_fit <- lm(build_formula("Y_cont", c("A", covs)), data = train)
          yhat <- predict(out_fit, newdata = test)
          res$summary_text <- "Path model estimated with lavaan (DAG-guided structure)."
          lavaan_ok <- TRUE
          list(yhat = yhat)
        }, error = function(e) {
          res$status <- "warning"
          res$summary_text <- paste0(
            "lavaan estimation failed (", conditionMessage(e),
            "). DAG-guided linear regression fallback used."
          )
          NULL
        })
        if (!is.null(sem_try)) {
          yhat <- sem_try$yhat
        }
      }
      if (!lavaan_ok) {
        fit <- lm(build_formula("Y_cont", c("A", covs)), data = train)
        yhat <- predict(fit, newdata = test)
        res$coef_table <- coeff_table_from_matrix(summary(fit)$coefficients)
        res$theta_hat <- unname(coef(fit)["A"])
        if (!safe_require("lavaan")) {
          res$summary_text <- "Package 'lavaan' not found. DAG-guided linear regression fallback used."
          res$status <- "warning"
        }
      }

      res$theta_true <- sim$true_params[["sem_dag"]]
      res$pred_df <- data.frame(truth = test$eta_true, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_cont", "A"), drop = FALSE], 8)

    } else if (model_id %in% c("lasso", "elastic_net")) {
      if (!safe_require("glmnet")) stop("Package 'glmnet' is required for LASSO/Elastic Net.")
      train <- sim$hd_train
      test <- sim$hd_test

      alpha_val <- if (model_id == "lasso") 1 else 0.5
      x_train <- as.matrix(train[, c("A", paste0("W", 1:20))])
      y_train <- train$Y_hd
      x_test <- as.matrix(test[, c("A", paste0("W", 1:20))])

      cvfit <- glmnet::cv.glmnet(x_train, y_train, alpha = alpha_val)
      yhat <- as.numeric(predict(cvfit, newx = x_test, s = "lambda.min"))
      coefs <- coeff_table_glmnet(cvfit)

      res$coef_table <- coefs[order(abs(coefs$Estimate), decreasing = TRUE), ]
      res$coef_table <- head(res$coef_table, 12)
      theta_row <- coefs[coefs$Term == "A", , drop = FALSE]
      res$theta_hat <- if (nrow(theta_row) == 1) theta_row$Estimate else NA_real_
      res$theta_true <- sim$true_params[[model_id]]
      res$summary_text <- if (model_id == "lasso") {
        "LASSO regression fit with cross-validated lambda."
      } else {
        "Elastic Net regression fit with alpha = 0.5 and cross-validated lambda."
      }
      res$pred_df <- data.frame(truth = test$eta_true_hd, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, c("Y_hd", "A", "W1", "W2", "W3", "W4")], 8)

    } else if (model_id == "rf_xgb") {
      train <- sim$hd_train
      test <- sim$hd_test

      if (safe_require("randomForest")) {
        fit <- randomForest::randomForest(
          Y_hd ~ ., data = train[, c("Y_hd", "A", paste0("W", 1:20))],
          ntree = 300,
          mtry = 6,
          importance = TRUE
        )
        yhat <- as.numeric(predict(fit, newdata = test[, c("A", paste0("W", 1:20))]))
        imp <- randomForest::importance(fit)
        imp_df <- data.frame(
          Term = rownames(imp),
          Estimate = as.numeric(imp[, 1]),
          Std_Error = NA_real_,
          P_Value = NA_real_,
          stringsAsFactors = FALSE
        )
        res$coef_table <- imp_df[order(-imp_df$Estimate), ]
        res$coef_table <- head(res$coef_table, 12)
        res$summary_text <- "Random Forest fit (tree ensemble proxy for boosting-style ML option)."
      } else {
        fit <- rpart::rpart(Y_hd ~ ., data = train[, c("Y_hd", "A", paste0("W", 1:20))])
        yhat <- as.numeric(predict(fit, newdata = test[, c("A", paste0("W", 1:20))]))
        res$coef_table <- data.frame(
          Term = "Tree model",
          Estimate = NA_real_,
          Std_Error = NA_real_,
          P_Value = NA_real_,
          stringsAsFactors = FALSE
        )
        res$summary_text <- "Package 'randomForest' not found. Decision tree fallback used."
        res$status <- "warning"
      }

      res$theta_hat <- NA_real_
      res$theta_true <- sim$true_params[["rf_xgb"]]
      res$theta_label <- "No single linear coefficient"
      res$pred_df <- data.frame(truth = test$eta_true_hd, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, c("Y_hd", "A", "W1", "W2", "W3", "W4")], 8)

    } else if (model_id == "neural_net") {
      train <- sim$hd_train
      test <- sim$hd_test
      if (!safe_require("nnet")) stop("Package 'nnet' is required for neural net option.")

      fit <- nnet::nnet(
        Y_hd ~ ., data = train[, c("Y_hd", "A", paste0("W", 1:20))],
        size = 6,
        linout = TRUE,
        decay = 0.01,
        maxit = 500,
        trace = FALSE
      )
      yhat <- as.numeric(predict(fit, newdata = test[, c("A", paste0("W", 1:20))]))
      res$coef_table <- data.frame(
        Term = "Neural network",
        Estimate = NA_real_,
        Std_Error = NA_real_,
        P_Value = NA_real_,
        stringsAsFactors = FALSE
      )
      res$theta_hat <- NA_real_
      res$theta_true <- sim$true_params[["neural_net"]]
      res$theta_label <- "No single linear coefficient"
      res$summary_text <- "Feed-forward neural network for nonlinear prediction."
      res$pred_df <- data.frame(truth = test$eta_true_hd, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, c("Y_hd", "A", "W1", "W2", "W3", "W4")], 8)

    } else if (model_id == "meta_learner") {
      train <- sim$cross_train
      test <- sim$cross_test

      xvars <- pick_covariates(train, 6)
      train_t <- train[train$A == 1, , drop = FALSE]
      train_c <- train[train$A == 0, , drop = FALSE]

      if (safe_require("randomForest") && nrow(train_t) > 20 && nrow(train_c) > 20) {
        m1 <- randomForest::randomForest(Y_causal ~ ., data = train_t[, c("Y_causal", xvars)])
        m0 <- randomForest::randomForest(Y_causal ~ ., data = train_c[, c("Y_causal", xvars)])
        mu1_hat <- as.numeric(predict(m1, newdata = test[, xvars]))
        mu0_hat <- as.numeric(predict(m0, newdata = test[, xvars]))
        res$summary_text <- "T-learner with Random Forest nuisance models."
      } else {
        m1 <- lm(build_formula("Y_causal", xvars), data = train_t)
        m0 <- lm(build_formula("Y_causal", xvars), data = train_c)
        mu1_hat <- predict(m1, newdata = test)
        mu0_hat <- predict(m0, newdata = test)
        res$summary_text <- "T-learner with linear nuisance models."
      }

      ite_hat <- mu1_hat - mu0_hat
      theta_hat <- mean(ite_hat)
      yhat <- mu0_hat + ite_hat * test$A

      res$coef_table <- data.frame(
        Term = "ATE (T-learner)",
        Estimate = theta_hat,
        Std_Error = NA_real_,
        P_Value = NA_real_,
        stringsAsFactors = FALSE
      )
      res$theta_hat <- theta_hat
      res$theta_true <- sim$true_params[["meta_learner"]]
      res$theta_label <- "Average treatment effect"
      res$pred_df <- data.frame(truth = test$mu_causal, pred = yhat, model = res$model_label)
      res$preview_df <- head(train[, preview_cols(train, "Y_causal", "A"), drop = FALSE], 8)

    } else {
      stop("Unknown model choice.")
    }

  }, error = function(e) {
    res$status <<- "error"
    res$message <<- conditionMessage(e)
  })

  if (!is.null(res$pred_df)) {
    m <- metrics_from_pred(res$pred_df$pred, res$pred_df$truth)
    res$metrics <- m
  } else {
    res$metrics <- c(mean_bias = NA_real_, mae = NA_real_, rmse = NA_real_)
  }

  if (nrow(res$coef_table) > 0) {
    res$coef_table <- res$coef_table %>%
      mutate(
        Estimate = round(Estimate, 4),
        Std_Error = round(Std_Error, 4),
        P_Value = round(P_Value, 4)
      )
  }

  res
}

interpret_theta <- function(model_id, theta_hat) {
  if (is.na(theta_hat)) {
    return("This model does not expose a single treatment coefficient on a simple linear scale.")
  }

  if (model_id %in% c("logistic", "cox", "poisson_nb", "glm_gamma")) {
    rr <- exp(theta_hat)
    return(paste0(
      "Treatment coefficient is on a log scale. exp(coef) = ", round(rr, 3),
      ", interpreted as a multiplicative change (odds, hazard, rate, or mean ratio)."
    ))
  }

  if (model_id == "did") {
    return("The interaction coefficient Treat x Post is the policy effect under the parallel-trends assumption.")
  }

  if (model_id %in% c("psm", "dml", "tmle", "aipw", "meta_learner")) {
    return("The reported coefficient is an ATE estimate: expected average change in outcome when treatment switches from 0 to 1.")
  }

  "Treatment coefficient is additive: expected mean outcome difference for A = 1 vs A = 0, conditional on covariates."
}

build_bias_row <- function(res, label) {
  data.frame(
    Model = label,
    Mean_Bias = format_num(res$metrics[["mean_bias"]]),
    MAE = format_num(res$metrics[["mae"]]),
    RMSE = format_num(res$metrics[["rmse"]]),
    Theta_Hat = format_num(res$theta_hat),
    Theta_True = format_num(res$theta_true),
    Theta_Bias = format_num(res$theta_hat - res$theta_true),
    stringsAsFactors = FALSE
  )
}

ui <- fluidPage(
  tags$head(
    tags$style(HTML(" 
      body { background: #eef4fb; }
      .app-shell { max-width: 1400px; margin: 0 auto; }
      .app-title { background: linear-gradient(90deg, #4682B4, #5f6b7a); color: #ffffff; padding: 14px 18px; border-radius: 8px; margin-bottom: 12px; }
      .panel-card { background: #f7fbff; border: 1px solid #d5e3f2; border-radius: 8px; padding: 12px; margin-bottom: 12px; }
      .equation-card { background: #dceaf7; border-left: 6px solid #4682B4; border-radius: 6px; padding: 10px 12px; margin-bottom: 10px; }
      .coeff-card { background: #f2f4f7; border-left: 6px solid #5f6b7a; border-radius: 6px; padding: 10px 12px; }
      .btn-primary, .btn-default { background-color: #4682B4; color: #ffffff; border-color: #4682B4; }
      .nav-tabs > li > a { color: #355670; }
      .help-block { color: #4e5a67; }
    "))
  ),

  div(class = "app-shell",
      div(class = "app-title",
          h2("Specification Bias Lab: Synthetic Data and Model Choice", style = "margin: 0;"),
          p("Explore how model specification affects prediction bias and coefficient interpretation.", style = "margin: 6px 0 0 0;")
      ),

      sidebarLayout(
        sidebarPanel(
          div(class = "panel-card",
              selectInput(
                "dgp_choice",
                "True Data-Generating Process",
                choices = setNames(names(dgp_catalog), vapply(dgp_catalog, `[[`, character(1), "title")),
                selected = "linear_continuous"
              ),
              numericInput("n_obs", "Sample size", value = 1200, min = 200, max = 20000, step = 100),
              numericInput("n_covariates", "Number of covariates (X1...Xp)", value = 8, min = 3, max = 30, step = 1),
              checkboxInput("use_interactions", "Add interaction terms to TRUE DGP", value = FALSE),
              uiOutput("interaction_terms_ui"),
              numericInput("seed", "Random seed", value = 1234, min = 1, step = 1),
              selectInput("model_choice", "Estimation model", choices = model_choices, selected = "linear_regression"),
              checkboxInput("compare_correct", "Compare with correct benchmark model", value = TRUE),
              actionButton("run_model", "Generate data and fit model")
          ),
          div(class = "panel-card",
              selectInput(
                "download_dataset",
                "Dataset to download",
                choices = c(
                  "Cross-sectional synthetic data" = "cross",
                  "High-dimensional data" = "hd",
                  "Longitudinal panel data" = "panel",
                  "DiD policy panel data" = "did"
                ),
                selected = "cross"
              ),
              downloadButton("download_data", "Download generated data (CSV)")
          ),
          div(class = "panel-card",
              strong("Teaching objective"),
              p("The app contrasts your selected model with the true process and, when requested, with the benchmark model implied by that true process.")
          )
        ),

        mainPanel(
          tabsetPanel(
            tabPanel(
              "True Process",
              br(),
              uiOutput("true_process_ui")
            ),
            tabPanel(
              "DAG",
              br(),
              uiOutput("dag_plot_ui"),
              br(),
              uiOutput("dag_equations_ui")
            ),
            tabPanel(
              "Model Fit",
              br(),
              verbatimTextOutput("fit_status"),
              tableOutput("coef_table"),
              br(),
              div(class = "coeff-card", uiOutput("coef_interpretation"))
            ),
            tabPanel(
              "Bias and Prediction",
              br(),
              tableOutput("bias_table"),
              plotOutput("pred_plot", height = "420px")
            ),
            tabPanel(
              "Data Preview",
              br(),
              tableOutput("preview_table")
            ),
            tabPanel(
              "User Manual",
              br(),
              uiOutput("manual_ui")
            )
          )
        )
      )
  )
)

server <- function(input, output, session) {
  output$interaction_terms_ui <- renderUI({
    req(input$n_covariates)
    if (!isTRUE(input$use_interactions)) return(NULL)

    vars <- c("A", paste0("X", seq_len(input$n_covariates)))
    pairs <- combn(vars, 2, simplify = FALSE)
    pair_labels <- vapply(pairs, function(x) paste0(x[1], ":", x[2]), character(1))

    selectizeInput(
      "interaction_terms",
      "Select interaction terms for the TRUE process",
      choices = pair_labels,
      selected = head(pair_labels, 2),
      multiple = TRUE,
      options = list(placeholder = "Example: A:X1, X1:X3")
    )
  })

  selected_interactions <- reactive({
    if (!isTRUE(input$use_interactions)) return(character())
    x <- input$interaction_terms
    if (is.null(x)) character() else x
  })

  current_structure <- reactive({
    covariates <- paste0("X", seq_len(input$n_covariates))
    list(
      info = dgp_catalog[[input$dgp_choice]],
      covariates = covariates,
      interactions = selected_interactions(),
      equations = build_dynamic_equations(
        dgp_id = input$dgp_choice,
        covariates = covariates,
        interactions = selected_interactions()
      ),
      dag = build_dag_spec(
        dgp_id = input$dgp_choice,
        covariates = covariates,
        interactions = selected_interactions()
      )
    )
  })

  sim_results <- eventReactive(input$run_model, {
    sim <- generate_simulation(
      dgp_id = input$dgp_choice,
      n = input$n_obs,
      seed = input$seed,
      n_covariates = input$n_covariates,
      interaction_terms = selected_interactions()
    )

    selected <- fit_model(input$model_choice, sim)

    benchmark <- NULL
    bench_id <- sim$info$correct_model
    if (isTRUE(input$compare_correct)) {
      benchmark <- fit_model(bench_id, sim)
    }

    list(sim = sim, selected = selected, benchmark = benchmark)
  }, ignoreNULL = FALSE)

  output$download_data <- downloadHandler(
    filename = function() {
      paste0(
        "synthetic_data_",
        input$dgp_choice, "_",
        input$download_dataset, "_",
        format(Sys.Date(), "%Y%m%d"),
        ".csv"
      )
    },
    content = function(file) {
      sr <- sim_results()
      dat <- switch(
        input$download_dataset,
        cross = sr$sim$cross_full,
        hd = sr$sim$hd_full,
        panel = sr$sim$panel_full,
        did = sr$sim$did_full,
        sr$sim$cross_full
      )
      utils::write.csv(dat, file, row.names = FALSE)
    }
  )

  output$dag_plot_ui <- renderUI({
    if (safe_require("DiagrammeR")) {
      DiagrammeR::grVizOutput("dag_plot", height = "560px")
    } else {
      div(
        class = "panel-card",
        p("Install package 'DiagrammeR' to display the DAG visualization."),
        tags$code("install.packages('DiagrammeR')")
      )
    }
  })

  if (safe_require("DiagrammeR")) {
    output$dag_plot <- DiagrammeR::renderGrViz({
      cs <- current_structure()
      dot <- dag_to_dot(cs$dag)
      DiagrammeR::grViz(dot)
    })
  }

  output$dag_equations_ui <- renderUI({
    cs <- current_structure()
    eqs <- cs$equations$structural
    tagList(
      div(
        class = "panel-card",
        h4("Structural Equations"),
        tags$ul(
          lapply(eqs, function(eq) {
            tags$li(withMathJax(HTML(paste0("$$", eq, "$$"))))
          })
        )
      )
    )
  })

  output$true_process_ui <- renderUI({
    cs <- current_structure()
    info <- cs$info
    benchmark_label <- model_labels[[info$correct_model]]
    interaction_block <- NULL
    if (length(cs$interactions) > 0) {
      coef_lines <- paste0(
        cs$interactions,
        " (gamma = ",
        format_num(vapply(cs$interactions, interaction_gamma_value, numeric(1)), digits = 2),
        ")"
      )
      interaction_block <- tags$div(
        p(strong("Interactions added to the true process:")),
        tags$ul(lapply(coef_lines, tags$li))
      )
    }

    tagList(
      div(class = "panel-card",
          h3(info$title),
          p(info$description),
          div(class = "equation-card",
              withMathJax(HTML(paste0("$$", cs$equations$main, "$$")))
          ),
          p(strong("Covariates generated: "), input$n_covariates),
          interaction_block,
          p(strong("Benchmark model for this process: "), benchmark_label)
      ),
      div(class = "panel-card",
          h4("How to interpret coefficients in this true process"),
          tags$ul(
            lapply(info$coef_notes, tags$li)
          )
      ),
      div(class = "panel-card",
          h4("True Parameter Values Used in Data Generation"),
          p("These values are the structural coefficients used to simulate the selected true process."),
          tableOutput("true_params_table")
      )
    )
  })

  output$true_params_table <- renderTable({
    cs <- current_structure()
    build_true_parameter_table(
      dgp_id = input$dgp_choice,
      n_covariates = input$n_covariates,
      interactions = cs$interactions
    )
  }, striped = TRUE, bordered = TRUE, spacing = "xs")

  output$fit_status <- renderText({
    sr <- sim_results()
    sel <- sr$selected

    status_label <- switch(
      sel$status,
      ok = "Status: model fit completed.",
      warning = "Status: model fit completed with fallback/warning.",
      error = "Status: model fit failed.",
      "Status: unknown."
    )

    paste(
      "Selected model:", sel$model_label,
      "\n", status_label,
      "\n", ifelse(nchar(sel$summary_text) > 0, sel$summary_text, ""),
      "\n", ifelse(nchar(sel$message) > 0, paste("Details:", sel$message), ""),
      sep = ""
    )
  })

  output$coef_table <- renderTable({
    sr <- sim_results()
    sr$selected$coef_table
  }, striped = TRUE, bordered = TRUE, spacing = "xs")

  output$coef_interpretation <- renderUI({
    sr <- sim_results()
    sel <- sr$selected
    txt <- interpret_theta(sel$model_id, sel$theta_hat)

    tagList(
      p(strong("Coefficient interpretation for selected model:")),
      p(txt)
    )
  })

  output$bias_table <- renderTable({
    sr <- sim_results()
    rows <- build_bias_row(sr$selected, paste0("Selected: ", sr$selected$model_label))

    if (!is.null(sr$benchmark)) {
      rows <- bind_rows(
        rows,
        build_bias_row(sr$benchmark, paste0("Benchmark: ", sr$benchmark$model_label))
      )
    }

    rows
  }, striped = TRUE, bordered = TRUE, spacing = "s")

  output$pred_plot <- renderPlot({
    sr <- sim_results()
    dfs <- list()

    if (!is.null(sr$selected$pred_df)) {
      dfs[[length(dfs) + 1]] <- sr$selected$pred_df
    }

    if (!is.null(sr$benchmark) && !is.null(sr$benchmark$pred_df)) {
      dfs[[length(dfs) + 1]] <- sr$benchmark$pred_df
    }

    if (length(dfs) == 0) {
      plot.new()
      text(0.5, 0.5, "No prediction output available for this model.")
      return(invisible(NULL))
    }

    pred_df <- bind_rows(dfs)

    ggplot(pred_df, aes(x = truth, y = pred, color = model)) +
      geom_point(alpha = 0.35, size = 1.6) +
      geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray35") +
      facet_wrap(~ model, scales = "free") +
      scale_color_manual(values = c("#4682B4", "#5f6b7a")) +
      labs(
        title = "Predicted vs True Signal",
        subtitle = "The 45-degree line indicates unbiased prediction.",
        x = "True latent signal / conditional mean",
        y = "Model prediction",
        color = "Model"
      ) +
      theme_minimal(base_size = 12) +
      theme(
        plot.background = element_rect(fill = "#eef4fb", color = NA),
        panel.background = element_rect(fill = "#f7fbff", color = NA),
        legend.position = "none"
      )
  })

  output$preview_table <- renderTable({
    sr <- sim_results()
    sr$selected$preview_df
  }, striped = TRUE, bordered = TRUE, spacing = "xs")

  output$manual_ui <- renderUI({
    tagList(
      div(class = "panel-card",
          h3("User Manual"),
          p("This app demonstrates how specification choices affect bias and interpretation across epidemiology, health economics, causal inference, and machine learning models."),
          tags$ol(
            lapply(names(manual_sections), function(title) {
              tags$li(
                strong(title),
                tags$div(manual_sections[[title]])
              )
            })
          )
      ),
      div(class = "panel-card",
          h4("Recommended workflow"),
          tags$ul(
            tags$li("Start with the benchmark model suggested by the selected true process."),
            tags$li("Switch to intentionally misspecified models and compare bias metrics."),
            tags$li("Use coefficient interpretation notes to explain why scale and link function matter."),
            tags$li("Repeat with different seeds and sample sizes to study finite-sample behavior.")
          )
      )
    )
  })
}

shinyApp(ui, server)
