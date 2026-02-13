---
title: "Time Series as a Machine Learning Tool: Let the Past Predict the Future"
date: 2025-12-18
categories: [tutorials, codes]
tags: [Machine Learning]
summary: "Most of the models we use in machine learning are like goldfish:"
---
<section id="introduction-when-your-data-has-a-memory-and-an-attitude" class="level1">
<h1>1. Introduction: when your data has a memory (and an attitude)</h1>
<p>Most of the models we use in machine learning are like goldfish:</p>
<ul>
<li>They look at a row of features,</li>
<li>They predict an outcome,</li>
<li>They completely forget everything that happened before.</li>
</ul>
<p>But then you meet <strong>time series data</strong>, and it's more like that one colleague who remembers every meeting, every deadline, and every mistake:</p>
<ul>
<li>Yesterday's hospital admissions look suspiciously like today's.</li>
<li>Last quarter's drug spending predicts this quarter... a little too well.</li>
<li>Flu seasons keep coming back like a Netflix series with too many seasons.</li>
</ul>
<p>If you feed time series into a standard ML algorithm <strong>without</strong> telling it about time, it will happily:</p>
<ul>
<li>Shuffle your data,</li>
<li>Break all temporal structure,</li>
<li>And then proudly overfit the past while being terrible at forecasting the future.</li>
</ul>
<p>So we need models that <strong>treat time as a first-class citizen</strong>.</p>
<p>In this tutorial we'll treat <strong>time series forecasting</strong> as a kind of supervised learning problem, but one where:</p>
<ul>
<li>The features are <em>lagged values</em> and other time-based transformations,</li>
<li>We must respect the <strong>order of observations</strong>,</li>
<li>Validation and testing must be done in a <strong>time-aware</strong> way.</li>
</ul>
<p>We'll:</p>
<ul>
<li>Lay the conceptual foundations of time series as ML,</li>
<li>Build a simple forecasting model in R with synthetic "hospital admissions" data,</li>
<li>Discuss strengths and limitations,</li>
<li>And wrap up with why this really matters for <strong>HEOR and health policy</strong>.</li>
</ul>
<hr>
</section>
<section id="foundations-time-series-as-supervised-learning" class="level1">
<h1>2. Foundations: time series as supervised learning</h1>
<section id="what-is-a-time-series" class="level2">
<h2 class="anchored" data-anchor-id="what-is-a-time-series">2.1. What is a time series?</h2>
<p>A <strong>time series</strong> is a sequence of observations ordered in time:</p>
<p><span class="math display">\[
y_1, y_2, \dots, y_T
\]</span></p>
<p>Examples in HEOR:</p>
<ul>
<li>Monthly hospital admissions,</li>
<li>Weekly ED visits,</li>
<li>Quarterly drug spending,</li>
<li>Annual mortality rates by region.</li>
</ul>
<p>The key twist: observations are <strong>not independent</strong>. What happens at time <span class="math inline">\(t\)</span> depends on what happened at times <span class="math inline">\(t-1, t-2, \dots\)</span>.</p>
</section>
<section id="turning-a-time-series-into-an-ml-problem" class="level2">
<h2 class="anchored" data-anchor-id="turning-a-time-series-into-an-ml-problem">2.2. Turning a time series into an ML problem</h2>
<p>To think of time series as a machine learning task, we often reframe:</p>
<blockquote class="blockquote">
<p>Predict <span class="math inline">\(y_t\)</span> using past values of the series.</p>
</blockquote>
<p>We create a dataset of the form:</p>
<ul>
<li>Features: lagged values <span class="math inline">\((y_{t-1}, y_{t-2}, \dots, y_{t-p})\)</span></li>
<li>Target: <span class="math inline">\(y_t\)</span></li>
</ul>
<p>So each training example is:</p>
<p><span class="math display">\[
\big( y_{t-1}, y_{t-2}, \dots, y_{t-p} \big) \;\; \to \;\; y_t.
\]</span></p>
<p>Any regression model (linear, random forest, neural net, etc.) can, in principle, be applied to this data. But we must always respect the <strong>time ordering</strong>:</p>
<ul>
<li>Training set: earlier times,</li>
<li>Validation/test sets: later times,</li>
<li>No shuffling across time.</li>
</ul>
</section>
<section id="classical-vs-ml-flavors" class="level2">
<h2 class="anchored" data-anchor-id="classical-vs-ml-flavors">2.3. Classical vs ML flavors</h2>
<p><strong>Classical time series models</strong> (like ARIMA) are:</p>
<ul>
<li>Designed specifically for time-series structure,</li>
<li>Often assume some form of <strong>stationarity</strong>,</li>
<li>Use parametric relationships: autoregressive (AR), moving average (MA), differencing (I), etc.</li>
</ul>
<p><strong>ML-style time series models</strong>:</p>
<ul>
<li>Can be more flexible, with nonlinear relationships,</li>
<li>Use extra features: calendar variables, exogenous regressors, lagged covariates,</li>
<li>Include algorithms like gradient-boosted trees, random forests, or deep learning.</li>
</ul>
<p>In this tutorial, we'll stick to a <strong>classical ARIMA-style</strong> model, but we'll frame it with an ML mindset:</p>
<ul>
<li>Train on a training period,</li>
<li>Evaluate on a test period,</li>
<li>Forecast and compare to truth.</li>
</ul>
<hr>
</section>
</section>
<section id="example-in-r-forecasting-synthetic-hospital-admissions" class="level1">
<h1>3. Example in R: forecasting synthetic "hospital admissions"</h1>
<p>We'll build a toy example where:</p>
<ul>
<li>We simulate monthly hospital admissions over 10 years,</li>
<li>The series has:
<ul>
<li>A slight upward trend,</li>
<li>Seasonality (e.g., winter peaks),</li>
<li>Random noise,</li>
</ul></li>
<li>We split into <strong>training</strong> and <strong>test</strong> periods,</li>
<li>We fit an ARIMA model and generate forecasts.</li>
</ul>
<p>You can later swap the synthetic data for real HEOR data.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="co"># We'll simulate 10 years of monthly data</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>n_years  <span class="ot">&lt;-</span> <span class="dv">10</span></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>freq     <span class="ot">&lt;-</span> <span class="dv">12</span></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>n_period <span class="ot">&lt;-</span> n_years <span class="sc">*</span> freq</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>time_index <span class="ot">&lt;-</span> <span class="dv">1</span><span class="sc">:</span>n_period</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a><span class="co"># Components:</span></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a><span class="co"># - Baseline around 100 admissions per month</span></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a><span class="co"># - Slight upward trend</span></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a><span class="co"># - Seasonal pattern (higher in winter)</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a><span class="co"># - Random noise</span></span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>baseline <span class="ot">&lt;-</span> <span class="dv">100</span></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>trend    <span class="ot">&lt;-</span> <span class="fl">0.5</span> <span class="sc">*</span> time_index   <span class="co"># slow upward trend</span></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a><span class="co"># Seasonal component: use a simple sine wave</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>seasonality <span class="ot">&lt;-</span> <span class="dv">10</span> <span class="sc">*</span> <span class="fu">sin</span>(<span class="dv">2</span> <span class="sc">*</span> pi <span class="sc">*</span> time_index <span class="sc">/</span> freq)  <span class="co"># yearly cycle</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a><span class="co"># Random noise</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>noise <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_period, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">8</span>)</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>admissions <span class="ot">&lt;-</span> baseline <span class="sc">+</span> trend <span class="sc">+</span> seasonality <span class="sc">+</span> noise</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a><span class="co"># Create a time series object</span></span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>admissions_ts <span class="ot">&lt;-</span> <span class="fu">ts</span>(admissions, <span class="at">frequency =</span> freq)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
<section id="visualizing-the-time-series" class="level2">
<h2 class="anchored" data-anchor-id="visualizing-the-time-series">3.1. Visualizing the time series</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">plot</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  admissions_ts,</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">main =</span> <span class="st">"Simulated Monthly Hospital Admissions"</span>,</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">xlab =</span> <span class="st">"Time (months)"</span>,</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">ylab =</span> <span class="st">"Admissions"</span></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/03-ml-time-series_files/figure-html/ts-plot-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Simulated monthly hospital admissions with trend and seasonality.</figcaption>
</figure>
</div>
</div>
</div>
<p>You should see:</p>
<ul>
<li>A general upward trend,</li>
<li>Regular seasonal bumps,</li>
<li>Noise around the pattern.</li>
</ul>
<hr>
</section>
<section id="traintest-split-that-respects-time" class="level2">
<h2 class="anchored" data-anchor-id="traintest-split-that-respects-time">3.2. Train-test split that respects time</h2>
<p>We'll:</p>
<ul>
<li>Use the first 8 years (96 months) as <strong>training</strong> data,</li>
<li>Use the last 2 years (24 months) as <strong>test</strong> data.</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>train_end <span class="ot">&lt;-</span> <span class="dv">8</span> <span class="sc">*</span> freq   <span class="co"># 8 years of monthly data</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>train_ts  <span class="ot">&lt;-</span> <span class="fu">window</span>(admissions_ts, <span class="at">end =</span> <span class="fu">c</span>(<span class="dv">8</span>, freq))</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>test_ts   <span class="ot">&lt;-</span> <span class="fu">window</span>(admissions_ts, <span class="at">start =</span> <span class="fu">c</span>(<span class="dv">9</span>, <span class="dv">1</span>))</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a><span class="fu">length</span>(train_ts); <span class="fu">length</span>(test_ts)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>[1] 96</code></pre>
</div>
<div class="cell-output cell-output-stdout">
<pre><code>[1] 24</code></pre>
</div>
</div>
<p>We're mimicking an ML workflow:</p>
<ul>
<li>The model is trained only on the first 8 years,</li>
<li>Forecasts are compared to the last 2 years (which the model has never seen).</li>
</ul>
<hr>
</section>
<section id="fitting-a-forecasting-model-arima" class="level2">
<h2 class="anchored" data-anchor-id="fitting-a-forecasting-model-arima">3.3. Fitting a forecasting model (ARIMA)</h2>
<p>We'll use the <code>forecast</code> package's <code>auto.arima()</code> to:</p>
<ul>
<li>Automatically pick ARIMA orders based on the data,</li>
<li>Including differencing and seasonal components if needed.</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a><span class="co"># install.packages("forecast") # run once if needed</span></span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(forecast)</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>fit_arima <span class="ot">&lt;-</span> <span class="fu">auto.arima</span>(train_ts)</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>fit_arima</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>Series: train_ts 
ARIMA(1,1,1) 

Coefficients:
         ar1      ma1
      0.4140  -0.8678
s.e.  0.1139   0.0513

sigma^2 = 94.92:  log likelihood = -350.41
AIC=706.81   AICc=707.08   BIC=714.47</code></pre>
</div>
</div>
<p>The printed output tells you:</p>
<ul>
<li>The ARIMA order (e.g., ARIMA(1,1,1)(0,1,1)[12]),</li>
<li>Estimated coefficients,</li>
<li>Information criteria (AIC, etc.).</li>
</ul>
<hr>
</section>
<section id="forecasting-and-evaluating-performance" class="level2">
<h2 class="anchored" data-anchor-id="forecasting-and-evaluating-performance">3.4. Forecasting and evaluating performance</h2>
<p>We forecast 24 months ahead (matching the test period) and compare predictions with actual test data.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb8"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb8-1"><a href="#cb8-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb8-2"><a href="#cb8-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-3"><a href="#cb8-3" aria-hidden="true" tabindex="-1"></a>fc_arima <span class="ot">&lt;-</span> <span class="fu">forecast</span>(fit_arima, <span class="at">h =</span> <span class="fu">length</span>(test_ts))</span>
<span id="cb8-4"><a href="#cb8-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-5"><a href="#cb8-5" aria-hidden="true" tabindex="-1"></a><span class="fu">autoplot</span>(fc_arima) <span class="sc">+</span></span>
<span id="cb8-6"><a href="#cb8-6" aria-hidden="true" tabindex="-1"></a>  <span class="fu">autolayer</span>(test_ts, <span class="at">series =</span> <span class="st">"Actual"</span>, <span class="at">color =</span> <span class="st">"black"</span>) <span class="sc">+</span></span>
<span id="cb8-7"><a href="#cb8-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb8-8"><a href="#cb8-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"ARIMA Forecast vs Actual (Admissions)"</span>,</span>
<span id="cb8-9"><a href="#cb8-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Time"</span>,</span>
<span id="cb8-10"><a href="#cb8-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Admissions"</span></span>
<span id="cb8-11"><a href="#cb8-11" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/03-ml-time-series_files/figure-html/ts-forecast-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>ARIMA forecasts vs actual admissions.</figcaption>
</figure>
</div>
</div>
</div>
<p>We can compute simple error metrics:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb9"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb9-1"><a href="#cb9-1" aria-hidden="true" tabindex="-1"></a>pred_vals <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(fc_arima<span class="sc">$</span>mean)</span>
<span id="cb9-2"><a href="#cb9-2" aria-hidden="true" tabindex="-1"></a>true_vals <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(test_ts)</span>
<span id="cb9-3"><a href="#cb9-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-4"><a href="#cb9-4" aria-hidden="true" tabindex="-1"></a><span class="co"># Mean Absolute Error (MAE)</span></span>
<span id="cb9-5"><a href="#cb9-5" aria-hidden="true" tabindex="-1"></a>mae <span class="ot">&lt;-</span> <span class="fu">mean</span>(<span class="fu">abs</span>(pred_vals <span class="sc">-</span> true_vals))</span>
<span id="cb9-6"><a href="#cb9-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-7"><a href="#cb9-7" aria-hidden="true" tabindex="-1"></a><span class="co"># Root Mean Squared Error (RMSE)</span></span>
<span id="cb9-8"><a href="#cb9-8" aria-hidden="true" tabindex="-1"></a>rmse <span class="ot">&lt;-</span> <span class="fu">sqrt</span>(<span class="fu">mean</span>((pred_vals <span class="sc">-</span> true_vals)<span class="sc">^</span><span class="dv">2</span>))</span>
<span id="cb9-9"><a href="#cb9-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-10"><a href="#cb9-10" aria-hidden="true" tabindex="-1"></a><span class="fu">c</span>(<span class="at">MAE =</span> mae, <span class="at">RMSE =</span> rmse)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>      MAE      RMSE 
 9.995854 13.048229 </code></pre>
</div>
</div>
<p>This gives you an ML-style evaluation of your time series model.</p>
<p>From here, you could:</p>
<ul>
<li>Add <strong>explanatory variables</strong> (e.g., holidays, flu season indicators),</li>
<li>Try more flexible models (e.g., boosted trees with lag features),</li>
<li>Compare multiple models via time-series cross-validation.</li>
</ul>
<hr>
</section>
</section>
<section id="strengths-and-limitations-of-time-series-methods-as-ml-tools" class="level1">
<h1>4. Strengths and limitations of time series methods (as ML tools)</h1>
<section id="four-strengths" class="level2">
<h2 class="anchored" data-anchor-id="four-strengths">4.1. Four strengths</h2>
<ol type="1">
<li><p><strong>Explicitly models temporal dependence</strong><br>
Time series methods embrace the fact that <span class="math inline">\(y_t\)</span> depends on past values. This is critical for forecasting and for correctly quantifying uncertainty over time.</p></li>
<li><p><strong>Good at short- and medium-term forecasting</strong><br>
When trends and seasonal patterns are reasonably stable, time series models can provide accurate and interpretable short- and mid-horizon forecasts - highly valuable for planning and budgeting.</p></li>
<li><p><strong>Integrates naturally with ML thinking</strong><br>
You can treat lagged values and time-based features as inputs to any regression algorithm, thus combining classical time series structure with modern ML flexibility.</p></li>
<li><p><strong>Diagnostics and structure</strong><br>
Classical time series models (ARIMA, etc.) come with rich diagnostic tools (ACF, PACF, residual analysis) that help understand model misfit and dynamics, not just prediction accuracy.</p></li>
</ol>
<hr>
</section>
<section id="four-limitations" class="level2">
<h2 class="anchored" data-anchor-id="four-limitations">4.2. Four limitations</h2>
<ol type="1">
<li><p><strong>Sensitive to structural breaks and regime changes</strong><br>
If a major policy change, pandemic, or coding change occurs, models trained on past data may extrapolate badly. Time series methods often assume that the future behaves "like the past," just with noise.</p></li>
<li><p><strong>Complex seasonal and calendar effects can be tricky</strong><br>
Real-world data might have multiple seasonalities (e.g., weekly + yearly patterns) or irregular events (holidays, strikes) that standard models don't capture well without considerable feature engineering.</p></li>
<li><p><strong>High-dimensional multivariate series are challenging</strong><br>
When many series interact (e.g., multiple regions, service lines), fully modeling the joint dynamics can become complex and computationally heavy.</p></li>
<li><p><strong>Overfitting and leakage are easy if you ignore time</strong><br>
If you accidentally shuffle data, use future information in features, or split train/test incorrectly, you can get wildly optimistic performance estimates that do not generalize.</p></li>
</ol>
<hr>
</section>
</section>
<section id="why-time-series-matters-in-heor-and-health-policy" class="level1">
<h1>5. Why time series matters in HEOR and health policy</h1>
<p>Time series methods are not a niche add-on; they sit at the heart of many HEOR and policy questions because so much of what we care about is <strong>how things evolve over time</strong>.</p>
<section id="forecasting-demand-and-utilization" class="level2">
<h2 class="anchored" data-anchor-id="forecasting-demand-and-utilization">5.1. Forecasting demand and utilization</h2>
<p>Examples:</p>
<ul>
<li>How many hospital admissions will we see next winter?</li>
<li>What will ED visits look like after a new triage policy?</li>
<li>How will drug utilization trend over the next 3-5 years?</li>
</ul>
<p>Forecasts inform:</p>
<ul>
<li>Capacity planning (beds, staff, supplies),</li>
<li>Procurement and budgeting,</li>
<li>Evaluation of whether a policy may push the system over capacity.</li>
</ul>
</section>
<section id="cost-projections-and-budget-impact" class="level2">
<h2 class="anchored" data-anchor-id="cost-projections-and-budget-impact">5.2. Cost projections and budget impact</h2>
<p>Payers and policymakers need to know:</p>
<ul>
<li>How will costs evolve over time under different scenarios?</li>
<li>What is the likely <strong>budget impact</strong> of a new intervention over 5-10 years?</li>
</ul>
<p>Time series models, sometimes embedded in broader economic models, can provide:</p>
<ul>
<li>Baseline projections (status quo),</li>
<li>Policy scenario projections,</li>
<li>Ranges of uncertainty for planning.</li>
</ul>
</section>
<section id="policy-evaluation-and-dynamic-effects" class="level2">
<h2 class="anchored" data-anchor-id="policy-evaluation-and-dynamic-effects">5.3. Policy evaluation and dynamic effects</h2>
<p>Time series structure is central to:</p>
<ul>
<li><strong>Interrupted time series (ITS)</strong> designs,</li>
<li><strong>Difference-in-differences</strong> and <strong>event-study</strong> models,</li>
<li>Assessing <strong>before-and-after</strong> changes while accounting for pre-existing trends.</li>
</ul>
<p>Understanding time series behavior ensures that:</p>
<ul>
<li>You don't confuse a pre-existing trend with a policy effect,</li>
<li>You can track how effects evolve and persist (or fade) over time.</li>
</ul>
</section>
<section id="feeding-more-complex-models" class="level2">
<h2 class="anchored" data-anchor-id="feeding-more-complex-models">5.4. Feeding more complex models</h2>
<p>Time series outputs often become inputs to:</p>
<ul>
<li>Microsimulation models,</li>
<li>Markov models,</li>
<li>System dynamics models.</li>
</ul>
<p>For example:</p>
<ul>
<li>Forecasted incidence rates,</li>
<li>Time-varying costs or utilization rates,</li>
<li>Dynamic coverage or adherence patterns.</li>
</ul>
<p>Good time series modeling upstream makes downstream decision models more realistic.</p>
<hr>
</section>
</section>
<section id="further-reading" class="level1">
<h1>6. Further reading</h1>
<p>If you want to treat time series as both a statistical and ML problem (with a lot of R examples), these are great resources:</p>
<ol type="1">
<li><p><strong>Hyndman &amp; Athanasopoulos - <em>Forecasting: Principles and Practice</em> (online, free)</strong><br>
A very practical and R-focused introduction to time series forecasting (including ARIMA, ETS, and modern approaches).</p></li>
<li><p><strong>Shumway &amp; Stoffer - <em>Time Series Analysis and Its Applications</em></strong><br>
A balanced mix of theory and applications, with many examples and R code.</p></li>
<li><p><strong>Hyndman, Koehler, Ord, &amp; Snyder - <em>Forecasting with Exponential Smoothing: The State Space Approach</em></strong><br>
More specialized, but great if you want to understand exponential smoothing and state space models deeply.</p></li>
<li><p><strong>Hastie, Tibshirani, &amp; Friedman - <em>The Elements of Statistical Learning</em> (chapters on time series / forecasting and regularization)</strong><br>
Not time-series-specific, but very useful for thinking about ML models, regularization, and how they adapt (or don't) to temporal data.</p></li>
</ol>
<p>Once you're comfortable with these foundations, you can start mixing in:</p>
<ul>
<li>Gradient-boosted trees or random forests on lagged features,</li>
<li>Recurrent or temporal CNN architectures,</li>
<li>Probabilistic forecasting frameworks -</li>
</ul>
<p>all while keeping the HEOR and health policy questions front and center. 😄</p>


<!-- -->

</section>
