---
title: "Ridge vs Lasso: Shrink, Select, or Both?"
date: 2025-12-18
categories: [tutorials, codes]
tags: [Machine Learning]
summary: "Ridge regression: shrinks coefficients, loves correlated predictors, never really lets go of any variable. - Lasso regression: shrinks coefficients, but also deletes some predictors by setting their coefficients to zero."
---
<section id="introduction-two-regularizers-walk-into-a-regression" class="level1">
<h1>1. Introduction: two regularizers walk into a regression...</h1>
<p>You now have:</p>
<ul>
<li><strong>Ridge regression</strong>: shrinks coefficients, loves correlated predictors, never really lets go of any variable.</li>
<li><strong>Lasso regression</strong>: shrinks coefficients, but also <strong>deletes</strong> some predictors by setting their coefficients to zero.</li>
</ul>
<p>It's like two different strategies for decluttering your office:</p>
<ul>
<li>Ridge: "Keep everything, but make each thing smaller and less influential."</li>
<li>Lasso: "Throw some things out entirely, keep the rest."</li>
</ul>
<p>So which one should you use?</p>
<p>In this tutorial we'll:</p>
<ul>
<li>Recap the key differences between ridge and lasso,</li>
<li>Show a small R example where we fit <strong>both</strong> on the same data,</li>
<li>Compare coefficients and prediction performance,</li>
<li>Discuss when each method tends to shine,</li>
<li>And give a HEOR/health policy perspective on choosing between them.</li>
</ul>
<hr>
</section>
<section id="quick-recap-objectives-and-penalties" class="level1">
<h1>2. Quick recap: objectives and penalties</h1>
<section id="ridge-regression" class="level2">
<h2 class="anchored" data-anchor-id="ridge-regression">2.1. Ridge regression</h2>
<p>Ridge solves:</p>
<p><span class="math display">\[
\min_{\beta} \; \sum_{i=1}^n (y_i - x_i^\top \beta)^2
+ \lambda \sum_{j=1}^p \beta_j^2.
\]</span></p>
<p>Characteristics:</p>
<ul>
<li><span class="math inline">\(L_2\)</span> penalty,</li>
<li>Shrinks coefficients toward zero,</li>
<li>Keeps all predictors (no exact zeros),</li>
<li>Great for multicollinearity and prediction.</li>
</ul>
</section>
<section id="lasso-regression" class="level2">
<h2 class="anchored" data-anchor-id="lasso-regression">2.2. Lasso regression</h2>
<p>Lasso solves:</p>
<p><span class="math display">\[
\min_{\beta} \; \sum_{i=1}^n (y_i - x_i^\top \beta)^2
+ \lambda \sum_{j=1}^p |\beta_j|.
\]</span></p>
<p>Characteristics:</p>
<ul>
<li><span class="math inline">\(L_1\)</span> penalty,</li>
<li>Shrinks coefficients,</li>
<li>Can set some coefficients exactly to zero (variable selection),</li>
<li>May behave erratically with highly correlated predictors.</li>
</ul>
<p>Roughly:</p>
<ul>
<li><strong>Ridge</strong>: "I care about shrinkage and prediction."</li>
<li><strong>Lasso</strong>: "I care about sparsity and interpretability."</li>
</ul>
<hr>
</section>
</section>
<section id="example-in-r-ridge-vs-lasso-on-the-same-data" class="level1">
<h1>3. Example in R: ridge vs lasso on the same data</h1>
<p>We'll again use <code>mtcars</code>:</p>
<ul>
<li>Outcome: mpg,</li>
<li>Predictors: other car features.</li>
</ul>
<p>We'll:</p>
<ul>
<li>Fit ridge and lasso with cross-validation,</li>
<li>Compare which variables are selected,</li>
<li>Compare prediction errors.</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(mtcars)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>y <span class="ot">&lt;-</span> mtcars<span class="sc">$</span>mpg</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>X <span class="ot">&lt;-</span> <span class="fu">as.matrix</span>(mtcars[, <span class="fu">setdiff</span>(<span class="fu">names</span>(mtcars), <span class="st">"mpg"</span>)])</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>n <span class="ot">&lt;-</span> <span class="fu">nrow</span>(X)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>train_idx <span class="ot">&lt;-</span> <span class="fu">sample</span>(<span class="fu">seq_len</span>(n), <span class="at">size =</span> <span class="fu">floor</span>(<span class="dv">2</span> <span class="sc">*</span> n <span class="sc">/</span> <span class="dv">3</span>))</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>test_idx  <span class="ot">&lt;-</span> <span class="fu">setdiff</span>(<span class="fu">seq_len</span>(n), train_idx)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>X_train <span class="ot">&lt;-</span> X[train_idx, ]</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>y_train <span class="ot">&lt;-</span> y[train_idx]</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>X_test <span class="ot">&lt;-</span> X[test_idx, ]</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>y_test <span class="ot">&lt;-</span> y[test_idx]</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>mae <span class="ot">&lt;-</span> <span class="cf">function</span>(a, b) <span class="fu">mean</span>(<span class="fu">abs</span>(a <span class="sc">-</span> b))</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>rmse <span class="ot">&lt;-</span> <span class="cf">function</span>(a, b) <span class="fu">sqrt</span>(<span class="fu">mean</span>((a <span class="sc">-</span> b)<span class="sc">^</span><span class="dv">2</span>))</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
<section id="fit-ridge-and-lasso-with-glmnet" class="level2">
<h2 class="anchored" data-anchor-id="fit-ridge-and-lasso-with-glmnet">3.1. Fit ridge and lasso with glmnet</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="co"># install.packages("glmnet") # if not installed</span></span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(glmnet)</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a><span class="co"># Ridge (alpha = 0)</span></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>ridge_cv <span class="ot">&lt;-</span> <span class="fu">cv.glmnet</span>(</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> X_train,</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> y_train,</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">alpha =</span> <span class="dv">0</span>,</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">standardize =</span> <span class="cn">TRUE</span></span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a><span class="co"># Lasso (alpha = 1)</span></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>lasso_cv <span class="ot">&lt;-</span> <span class="fu">cv.glmnet</span>(</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> X_train,</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> y_train,</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">alpha =</span> <span class="dv">1</span>,</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">standardize =</span> <span class="cn">TRUE</span></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>ridge_lambda <span class="ot">&lt;-</span> ridge_cv<span class="sc">$</span>lambda.min</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>lasso_lambda <span class="ot">&lt;-</span> lasso_cv<span class="sc">$</span>lambda.min</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>ridge_lambda</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>[1] 3.755852</code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>lasso_lambda</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>[1] 0.7546382</code></pre>
</div>
</div>
</section>
<section id="predictions-and-performance" class="level2">
<h2 class="anchored" data-anchor-id="predictions-and-performance">3.2. Predictions and performance</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>ridge_pred <span class="ot">&lt;-</span> <span class="fu">predict</span>(ridge_cv, <span class="at">s =</span> ridge_lambda, <span class="at">newx =</span> X_test)</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>lasso_pred <span class="ot">&lt;-</span> <span class="fu">predict</span>(lasso_cv, <span class="at">s =</span> lasso_lambda, <span class="at">newx =</span> X_test)</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a><span class="fu">c</span>(</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">Ridge_MAE  =</span> <span class="fu">mae</span>(y_test, ridge_pred),</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">Ridge_RMSE =</span> <span class="fu">rmse</span>(y_test, ridge_pred),</span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">Lasso_MAE  =</span> <span class="fu">mae</span>(y_test, lasso_pred),</span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">Lasso_RMSE =</span> <span class="fu">rmse</span>(y_test, lasso_pred)</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code> Ridge_MAE Ridge_RMSE  Lasso_MAE Lasso_RMSE 
  1.765704   2.125979   2.150564   2.573753 </code></pre>
</div>
</div>
<p>Depending on the random split, you may see:</p>
<ul>
<li>Ridge slightly better or lasso slightly better,</li>
<li>Or similar performance.</li>
</ul>
<p>In real HEOR applications, you'd use:</p>
<ul>
<li>Larger datasets,</li>
<li>Multiple resamples or time-based splits,</li>
<li>Possibly elastic net (compromise between ridge and lasso).</li>
</ul>
<hr>
</section>
<section id="comparing-coefficients" class="level2">
<h2 class="anchored" data-anchor-id="comparing-coefficients">3.3. Comparing coefficients</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb8"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb8-1"><a href="#cb8-1" aria-hidden="true" tabindex="-1"></a>ridge_coefs <span class="ot">&lt;-</span> <span class="fu">as.matrix</span>(<span class="fu">coef</span>(ridge_cv, <span class="at">s =</span> ridge_lambda))</span>
<span id="cb8-2"><a href="#cb8-2" aria-hidden="true" tabindex="-1"></a>lasso_coefs <span class="ot">&lt;-</span> <span class="fu">as.matrix</span>(<span class="fu">coef</span>(lasso_cv, <span class="at">s =</span> lasso_lambda))</span>
<span id="cb8-3"><a href="#cb8-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-4"><a href="#cb8-4" aria-hidden="true" tabindex="-1"></a>ridge_coefs</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>              s=3.755852
(Intercept) 23.200914135
cyl         -0.412956425
disp        -0.006834794
hp          -0.010611267
drat         0.923706506
wt          -1.708992610
qsec         0.194016184
vs           0.911076969
am           1.525615075
gear         0.384467806
carb        -0.440830544</code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb10"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb10-1"><a href="#cb10-1" aria-hidden="true" tabindex="-1"></a>lasso_coefs</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>            s=0.7546382
(Intercept) 38.72538353
cyl         -0.86646118
disp         0.00000000
hp          -0.01091364
drat         0.00000000
wt          -3.85636803
qsec         0.03321608
vs           0.00000000
am           0.00000000
gear         0.00000000
carb         0.00000000</code></pre>
</div>
</div>
<p>You should notice:</p>
<ul>
<li>Ridge: all predictors have <strong>non-zero</strong> coefficients (though shrunk),</li>
<li>Lasso: some coefficients are <strong>exactly zero</strong>.</li>
</ul>
<p>This is the core trade-off:</p>
<ul>
<li>Ridge keeps everyone in the model but turns the volume down,</li>
<li>Lasso keeps only some predictors and silences the rest.</li>
</ul>
<hr>
</section>
</section>
<section id="when-to-prefer-ridge-vs-lasso-four-points-each" class="level1">
<h1>4. When to prefer ridge vs lasso (four points each)</h1>
<section id="ridge-tends-to-be-better-when" class="level2">
<h2 class="anchored" data-anchor-id="ridge-tends-to-be-better-when">4.1. Ridge tends to be better when...</h2>
<ol type="1">
<li><p><strong>Predictors are highly correlated</strong><br>
Ridge handles collinearity gracefully by distributing shrinkage among correlated predictors.</p></li>
<li><p><strong>You care mainly about prediction accuracy</strong><br>
If interpretability via sparsity is not crucial, ridge often provides stable and good predictions.</p></li>
<li><p><strong>True signal is spread across many predictors</strong><br>
If the "truth" uses many small effects, ridge's continuous shrinkage can be more appropriate than lasso's tendency to zero things out.</p></li>
<li><p><strong>You want smooth coefficient paths</strong><br>
Ridge coefficient paths as a function of <span class="math inline">\(\lambda\)</span> are smoother and less jumpy than lasso's, which can help in understanding how shrinkage behaves.</p></li>
</ol>
</section>
<section id="lasso-tends-to-be-better-when" class="level2">
<h2 class="anchored" data-anchor-id="lasso-tends-to-be-better-when">4.2. Lasso tends to be better when...</h2>
<ol type="1">
<li><p><strong>You expect only a subset of predictors to matter</strong><br>
If you believe the true model is sparse, lasso is a natural choice.</p></li>
<li><p><strong>Interpretability and simplicity are important</strong><br>
Lasso gives you a smaller set of predictors, which is easier to explain to clinicians, managers, or policymakers.</p></li>
<li><p><strong>You have more predictors than observations (<span class="math inline">\(p &gt; n\)</span>)</strong><br>
Lasso can still work and perform variable selection in high-dimensional settings (ridge can also work, but does not select).</p></li>
<li><p><strong>You want a quick automatic feature selection tool</strong><br>
Lasso is often used as a first-pass tool to winnow down large sets of variables.</p></li>
</ol>
<hr>
</section>
</section>
<section id="heor-and-health-policy-perspective-choosing-a-regularizer" class="level1">
<h1>5. HEOR and health policy perspective: choosing a regularizer</h1>
<p>In HEOR and health policy, the choice between ridge and lasso often depends on the <strong>goal of the model</strong>:</p>
<section id="forecasting-and-risk-adjustment" class="level2">
<h2 class="anchored" data-anchor-id="forecasting-and-risk-adjustment">5.1. Forecasting and risk adjustment</h2>
<p>If you are focused on:</p>
<ul>
<li>Predicting costs,</li>
<li>Predicting utilization,</li>
<li>Building risk adjustment models for payment,</li>
</ul>
<p>and you have:</p>
<ul>
<li>Many correlated predictors,</li>
<li>Less need for strict variable selection,</li>
</ul>
<p>then <strong>ridge</strong> is often a strong default:</p>
<ul>
<li>It stabilizes estimates,</li>
<li>Reduces overfitting,</li>
<li>Uses all available information.</li>
</ul>
</section>
<section id="variable-selection-and-explainable-scores" class="level2">
<h2 class="anchored" data-anchor-id="variable-selection-and-explainable-scores">5.2. Variable selection and explainable scores</h2>
<p>If you are focused on:</p>
<ul>
<li>Identifying key risk factors,</li>
<li>Building simple risk scores,</li>
<li>Communicating which variables "matter most",</li>
</ul>
<p>then <strong>lasso</strong> is attractive:</p>
<ul>
<li>It generates a compact set of predictors,</li>
<li>Facilitates communication ("the model uses 12 variables, not 120"),</li>
<li>Can guide future data collection or survey design.</li>
</ul>
</section>
<section id="combined-approach-elastic-net" class="level2">
<h2 class="anchored" data-anchor-id="combined-approach-elastic-net">5.3. Combined approach: elastic net</h2>
<p>When:</p>
<ul>
<li>Predictors are highly correlated, <strong>and</strong></li>
<li>You'd like some sparsity but also some grouping behavior,</li>
</ul>
<p>you might consider <strong>elastic net</strong>, which combines ridge and lasso penalties:</p>
<p><span class="math display">\[
\lambda \left[ \alpha \sum_{j} |\beta_j| + (1 - \alpha) \sum_{j} \beta_j^2 \right],
\]</span></p>
<p>with <span class="math inline">\(\alpha \in [0, 1]\)</span> controlling the mix.</p>
<p>Elastic net often performs well in HEOR contexts with:</p>
<ul>
<li>Many correlated clinical and utilization variables,</li>
<li>A desire for some variable selection plus stable coefficients.</li>
</ul>
<hr>
</section>
</section>
<section id="further-reading" class="level1">
<h1>6. Further reading</h1>
<ol type="1">
<li><p><strong>James, Witten, Hastie, &amp; Tibshirani - <em>An Introduction to Statistical Learning</em> (Ch. 6).</strong><br>
Excellent applied guide to ridge, lasso, and elastic net, with R examples.</p></li>
<li><p><strong>Hastie, Tibshirani, &amp; Friedman - <em>The Elements of Statistical Learning</em> (Ch. 3, 7).</strong><br>
More detailed, including bias-variance tradeoffs and regularization paths.</p></li>
<li><p><strong>Hastie, Tibshirani, &amp; Wainwright - <em>Statistical Learning with Sparsity: The Lasso and Generalizations.</em></strong><br>
The go-to monograph for lasso, elastic net, and related sparse methods.</p></li>
<li><p><strong>glmnet vignettes and documentation.</strong><br>
Practical resource for fitting and tuning ridge, lasso, and elastic net models in R across many outcome types (Gaussian, binomial, Poisson, etc.).</p></li>
</ol>
<p>Ultimately, in HEOR and health policy, you rarely commit to only one:</p>
<ul>
<li>You try <strong>ridge</strong>, <strong>lasso</strong>, and often <strong>elastic net</strong>,</li>
<li>Compare via cross-validation or time-based splits,</li>
<li>Choose the model that best balances <strong>predictive performance</strong>, <strong>stability</strong>, and <strong>interpretability</strong> for your specific question. 😄</li>
</ul>


<!-- -->

</section>
