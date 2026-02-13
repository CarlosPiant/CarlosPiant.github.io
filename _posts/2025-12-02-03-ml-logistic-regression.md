---
title: "Logistic Regression in R: Predicting Binary Outcomes"
date: 2025-12-02
categories: [tutorials, codes]
tags: [Machine Learning]
summary: "If linear regression is the overachiever of statistics, logistic regression is its cousin who shows up whenever the question is basically:"
---
<section id="introduction-when-your-outcome-is-just-yes-or-no" class="level1">
<h1>1. Introduction: when your outcome is just "yes" or "no"</h1>
<p>If linear regression is the overachiever of statistics, <strong>logistic regression</strong> is its cousin who shows up whenever the question is basically:</p>
<blockquote class="blockquote">
<p>"Will this happen or not?"</p>
</blockquote>
<p>In other words:<br>
- Did the patient have <strong>high blood pressure</strong>? (Yes/No)<br>
- Was the person <strong>readmitted</strong> within 30 days? (Yes/No)<br>
- Did the patient <strong>adhere</strong> to treatment? (Yes/No)</p>
<p>Linear regression tries to predict a number on a continuous scale. Logistic regression is the one we call when the outcome is <strong>binary</strong>: 0/1, Yes/No, Success/Failure.</p>
<p>You <em>could</em> try to brute-force things by running a linear regression on 0/1 outcomes and pretending that the predicted values are probabilities. But:</p>
<ul>
<li>Linear regression can happily predict values below 0 or above 1<br>
</li>
<li>The relationship between predictors and probability is often <strong>nonlinear</strong><br>
</li>
<li>The variance assumptions for linear regression get grumpy and walk away</li>
</ul>
<p>Logistic regression fixes this by:</p>
<ul>
<li>Modeling the <em>log-odds</em> instead of the outcome directly, and<br>
</li>
<li>Using a squishy S-shaped function (the <strong>logistic function</strong>) to translate linear combinations of predictors into probabilities between 0 and 1.</li>
</ul>
<hr>
</section>
<section id="foundations-of-logistic-regression" class="level1">
<h1>2. Foundations of logistic regression</h1>
<section id="binary-outcomes-and-probabilities" class="level2">
<h2 class="anchored" data-anchor-id="binary-outcomes-and-probabilities">2.1. Binary outcomes and probabilities</h2>
<p>We will assume a binary outcome <span class="math inline">\(Y\)</span> that takes values:</p>
<ul>
<li><span class="math inline">\(Y = 1\)</span> if the event happens (e.g., high blood pressure),</li>
<li><span class="math inline">\(Y = 0\)</span> if it does not.</li>
</ul>
<p>For each individual with predictor values <span class="math inline">\(X\)</span> (e.g., age, BMI, gender), we are interested in:</p>
<p><span class="math display">\[
p(X) = P(Y = 1 \mid X).
\]</span></p>
<p>This is a probability, so it must lie between 0 and 1.</p>
</section>
<section id="why-not-just-use-linear-regression" class="level2">
<h2 class="anchored" data-anchor-id="why-not-just-use-linear-regression">2.2. Why not just use linear regression?</h2>
<p>If we used a linear regression model like</p>
<p><span class="math display">\[
Y_i = \beta_0 + \beta_1 X_i + \varepsilon_i,
\]</span></p>
<p>with <span class="math inline">\(Y_i\)</span> in {0, 1}, we would run into problems:</p>
<ul>
<li>The model can produce predicted values below 0 or above 1.</li>
<li>The error variance is not constant (it depends on <span class="math inline">\(p(X)\)</span>).</li>
<li>The relationship between predictors and the probability is often curved, not straight.</li>
</ul>
<p>Enter logistic regression.</p>
</section>
<section id="the-logistic-regression-model" class="level2">
<h2 class="anchored" data-anchor-id="the-logistic-regression-model">2.3. The logistic regression model</h2>
<p>Logistic regression models the <strong>log-odds</strong> of the outcome instead of the probability directly.</p>
<p>The <strong>odds</strong> of the event are:</p>
<p><span class="math display">\[
\text{odds}(X) = \frac{p(X)}{1 - p(X)}.
\]</span></p>
<p>The <strong>log-odds</strong> (also called the <strong>logit</strong>) are:</p>
<p><span class="math display">\[
\text{logit}(p(X)) = \log\left(\frac{p(X)}{1 - p(X)}\right).
\]</span></p>
<p>The logistic regression model assumes that the log-odds are a linear function of the predictors:</p>
<p><span class="math display">\[
\log\left(\frac{p(X)}{1 - p(X)}\right) = \beta_0 + \beta_1 X_1 + \beta_2 X_2 + \cdots + \beta_k X_k.
\]</span></p>
<p>This has two big consequences:</p>
<ol type="1">
<li>The right-hand side is linear in the predictors, which is familiar and easy to work with.</li>
<li>The model automatically keeps <span class="math inline">\(p(X)\)</span> between 0 and 1 via the logistic function:</li>
</ol>
<p><span class="math display">\[
p(X) = \frac{1}{1 + \exp\left(-(\beta_0 + \beta_1 X_1 + \cdots + \beta_k X_k)\right)}.
\]</span></p>
</section>
<section id="interpreting-coefficients-in-terms-of-odds-ratios" class="level2">
<h2 class="anchored" data-anchor-id="interpreting-coefficients-in-terms-of-odds-ratios">2.4. Interpreting coefficients (in terms of odds ratios)</h2>
<p>For a single continuous predictor <span class="math inline">\(X\)</span>, holding all other predictors constant:</p>
<ul>
<li><span class="math inline">\(\beta_1\)</span> is the change in <strong>log-odds</strong> of the event for a one-unit increase in <span class="math inline">\(X\)</span>.</li>
<li><span class="math inline">\(\exp(\beta_1)\)</span> is the <strong>odds ratio</strong>: the multiplicative change in odds for a one-unit increase in <span class="math inline">\(X\)</span>.</li>
</ul>
<p>For a binary predictor (e.g., Male vs Female):</p>
<ul>
<li><span class="math inline">\(\exp(\beta_1)\)</span> is the ratio of the odds of the event for one category vs the reference category.</li>
</ul>
<p>People rarely think in log-odds in daily life. Odds ratios and <strong>predicted probabilities</strong> are usually easier to interpret, especially in HEOR.</p>
<hr>
</section>
</section>
<section id="example-with-real-world-data-nhanes" class="level1">
<h1>3. Example with real-world data (NHANES)</h1>
<p>We will reuse the <strong>NHANES</strong> dataset from the R package <code>NHANES</code>, but this time we'll model a binary outcome: whether someone has <strong>high blood pressure</strong>.</p>
<p>We'll model:</p>
<ul>
<li>Outcome: <code>HighBP</code> (Yes/No)</li>
<li>Predictors: <code>Age</code>, <code>BMI</code>, <code>Gender</code></li>
</ul>
<section id="load-and-prepare-the-data" class="level2">
<h2 class="anchored" data-anchor-id="load-and-prepare-the-data">3.1. Load and prepare the data</h2>
<p>We focus on adults (Age ≥ 18) and keep only complete cases for simplicity.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="co"># Install NHANES package if needed</span></span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="cf">if</span> (<span class="sc">!</span><span class="fu">requireNamespace</span>(<span class="st">"NHANES"</span>, <span class="at">quietly =</span> <span class="cn">TRUE</span>)) {</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">install.packages</span>(<span class="st">"NHANES"</span>)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(NHANES)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"NHANES"</span>)</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a><span class="co"># Create the variable HighBP (Yes/No)</span></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>NHANES <span class="ot">&lt;-</span> NHANES <span class="sc">%&gt;%</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">HighBP =</span> <span class="fu">ifelse</span>(BPSysAve<span class="sc">&gt;=</span> <span class="dv">130</span> <span class="sc">|</span> BPDiaAve <span class="sc">&gt;=</span> <span class="dv">80</span>, <span class="st">"Yes"</span>, <span class="st">"No"</span>)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a><span class="co">#table(NHANES$HighBP, useNA = "ifany")</span></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>nhanes_logit <span class="ot">&lt;-</span> NHANES <span class="sc">%&gt;%</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(Age <span class="sc">&gt;=</span> <span class="dv">18</span>) <span class="sc">%&gt;%</span></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  <span class="fu">select</span>(HighBP, Age, BMI, Gender) <span class="sc">%&gt;%</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(<span class="sc">!</span><span class="fu">is.na</span>(HighBP), <span class="sc">!</span><span class="fu">is.na</span>(Age), <span class="sc">!</span><span class="fu">is.na</span>(BMI), <span class="sc">!</span><span class="fu">is.na</span>(Gender)) <span class="sc">%&gt;%</span></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">HighBP =</span> <span class="fu">factor</span>(HighBP, <span class="at">levels =</span> <span class="fu">c</span>(<span class="st">"No"</span>, <span class="st">"Yes"</span>)),</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">Gender =</span> <span class="fu">factor</span>(Gender)</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a><span class="fu">summary</span>(nhanes_logit)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code> HighBP          Age             BMI           Gender    
 No :4696   Min.   :18.00   Min.   :15.02   female:3601  
 Yes:2454   1st Qu.:31.00   1st Qu.:23.94   male  :3549  
            Median :45.00   Median :27.62                
            Mean   :46.23   Mean   :28.69                
            3rd Qu.:59.00   3rd Qu.:32.10                
            Max.   :80.00   Max.   :81.25                </code></pre>
</div>
</div>
<p>Here:</p>
<ul>
<li><code>HighBP</code> is our binary outcome.</li>
<li><code>Age</code> and <code>BMI</code> are continuous predictors.</li>
<li><code>Gender</code> is a categorical predictor (e.g., Male/Female).</li>
</ul>
</section>
<section id="fit-a-logistic-regression-model" class="level2">
<h2 class="anchored" data-anchor-id="fit-a-logistic-regression-model">3.2. Fit a logistic regression model</h2>
<p>We use <code>glm()</code> with <code>family = binomial</code> to fit a logistic regression:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>fit_logit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  HighBP <span class="sc">~</span> Age <span class="sc">+</span> BMI <span class="sc">+</span> Gender,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> nhanes_logit,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> binomial</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a><span class="fu">summary</span>(fit_logit)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>
Call:
glm(formula = HighBP ~ Age + BMI + Gender, family = binomial, 
    data = nhanes_logit)

Coefficients:
             Estimate Std. Error z value Pr(&gt;|z|)    
(Intercept) -4.027080   0.150800 -26.705   &lt;2e-16 ***
Age          0.040756   0.001608  25.339   &lt;2e-16 ***
BMI          0.039734   0.003951  10.056   &lt;2e-16 ***
Gendermale   0.524048   0.053677   9.763   &lt;2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 9197.0  on 7149  degrees of freedom
Residual deviance: 8303.9  on 7146  degrees of freedom
AIC: 8311.9

Number of Fisher Scoring iterations: 3</code></pre>
</div>
</div>
<p>The <code>summary()</code> output shows:</p>
<ul>
<li>Coefficients on the <strong>log-odds</strong> scale,</li>
<li>Standard errors, z-values, and p-values,</li>
<li>Overall model information (null deviance, residual deviance, etc.).</li>
</ul>
</section>
<section id="from-log-odds-to-odds-ratios" class="level2">
<h2 class="anchored" data-anchor-id="from-log-odds-to-odds-ratios">3.3. From log-odds to odds ratios</h2>
<p>To get odds ratios and 95% confidence intervals:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>coefs <span class="ot">&lt;-</span> <span class="fu">summary</span>(fit_logit)<span class="sc">$</span>coefficients</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>coefs</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>               Estimate  Std. Error   z value      Pr(&gt;|z|)
(Intercept) -4.02708013 0.150800403 -26.70470 4.150479e-157
Age          0.04075613 0.001608415  25.33932 1.178622e-141
BMI          0.03973447 0.003951168  10.05639  8.610123e-24
Gendermale   0.52404778 0.053676539   9.76307  1.621709e-22</code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a><span class="co"># Odds ratios and 95% CI</span></span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>or <span class="ot">&lt;-</span> <span class="fu">exp</span>(coefs[, <span class="st">"Estimate"</span>])</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>ci_low <span class="ot">&lt;-</span> <span class="fu">exp</span>(coefs[, <span class="st">"Estimate"</span>] <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> coefs[, <span class="st">"Std. Error"</span>])</span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>ci_high <span class="ot">&lt;-</span> <span class="fu">exp</span>(coefs[, <span class="st">"Estimate"</span>] <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> coefs[, <span class="st">"Std. Error"</span>])</span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a>or_table <span class="ot">&lt;-</span> <span class="fu">cbind</span>(</span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">OR =</span> or,</span>
<span id="cb7-8"><a href="#cb7-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">CI_low =</span> ci_low,</span>
<span id="cb7-9"><a href="#cb7-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">CI_high =</span> ci_high</span>
<span id="cb7-10"><a href="#cb7-10" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb7-11"><a href="#cb7-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-12"><a href="#cb7-12" aria-hidden="true" tabindex="-1"></a><span class="fu">round</span>(or_table, <span class="dv">3</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>               OR CI_low CI_high
(Intercept) 0.018  0.013   0.024
Age         1.042  1.038   1.045
BMI         1.041  1.033   1.049
Gendermale  1.689  1.520   1.876</code></pre>
</div>
</div>
<p>Interpretation example (hypothetical):</p>
<ul>
<li><p>If the odds ratio for Age is 1.04, we might say:<br>
&gt; For each additional year of age, the odds of having high blood pressure &gt; increase by about 4%, holding BMI and gender constant.</p></li>
<li><p>If the odds ratio for BMI is 1.05, we might say:<br>
&gt; For each one-unit increase in BMI, the odds of high blood pressure increase &gt; by about 5%, holding age and gender constant.</p></li>
</ul>
<p>Remember: this is <strong>odds</strong>, not probabilities - but we can get those too.</p>
</section>
<section id="predicted-probabilities-for-specific-profiles" class="level2">
<h2 class="anchored" data-anchor-id="predicted-probabilities-for-specific-profiles">3.4. Predicted probabilities for specific profiles</h2>
<p>Let's compute predicted probabilities for a few hypothetical individuals:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb9"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb9-1"><a href="#cb9-1" aria-hidden="true" tabindex="-1"></a>new_people <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb9-2"><a href="#cb9-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">Age =</span> <span class="fu">c</span>(<span class="dv">30</span>, <span class="dv">50</span>, <span class="dv">65</span>),</span>
<span id="cb9-3"><a href="#cb9-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">BMI =</span> <span class="fu">c</span>(<span class="dv">22</span>, <span class="dv">30</span>, <span class="dv">35</span>),</span>
<span id="cb9-4"><a href="#cb9-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">Gender =</span> <span class="fu">factor</span>(<span class="fu">c</span>(<span class="st">"Female"</span>, <span class="st">"Female"</span>, <span class="st">"Male"</span>), <span class="at">levels =</span> <span class="fu">levels</span>(nhanes_logit<span class="sc">$</span>Gender))</span>
<span id="cb9-5"><a href="#cb9-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb9-6"><a href="#cb9-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-7"><a href="#cb9-7" aria-hidden="true" tabindex="-1"></a>new_people<span class="sc">$</span>pred_prob <span class="ot">&lt;-</span> <span class="fu">predict</span>(</span>
<span id="cb9-8"><a href="#cb9-8" aria-hidden="true" tabindex="-1"></a>  fit_logit,</span>
<span id="cb9-9"><a href="#cb9-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">newdata =</span> new_people,</span>
<span id="cb9-10"><a href="#cb9-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">type =</span> <span class="st">"response"</span>  <span class="co"># gives predicted probabilities</span></span>
<span id="cb9-11"><a href="#cb9-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb9-12"><a href="#cb9-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-13"><a href="#cb9-13" aria-hidden="true" tabindex="-1"></a>new_people</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>  Age BMI Gender pred_prob
1  30  22   &lt;NA&gt;        NA
2  50  30   &lt;NA&gt;        NA
3  65  35   &lt;NA&gt;        NA</code></pre>
</div>
</div>
<p>Now we can say things like:</p>
<ul>
<li>A 30-year-old woman with BMI 22 has an estimated probability <strong>p</strong> of high BP.</li>
<li>A 50-year-old woman with BMI 30 has a higher estimated probability.</li>
<li>A 65-year-old man with BMI 35 has a higher estimated probability still.</li>
</ul>
<p>These kinds of comparisons are extremely common in HEOR and health policy reports.</p>
</section>
<section id="visualizing-predicted-probabilities" class="level2">
<h2 class="anchored" data-anchor-id="visualizing-predicted-probabilities">3.5. Visualizing predicted probabilities</h2>
<p>We can also visualize the relationship between age and the probability of high blood pressure, for example at a fixed BMI, by using <code>ggplot2</code>:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb11"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb11-1"><a href="#cb11-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb11-2"><a href="#cb11-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb11-3"><a href="#cb11-3" aria-hidden="true" tabindex="-1"></a><span class="co"># For plotting, we create a grid over Age and Gender at a fixed BMI (e.g., 27)</span></span>
<span id="cb11-4"><a href="#cb11-4" aria-hidden="true" tabindex="-1"></a>age_grid <span class="ot">&lt;-</span> <span class="fu">seq</span>(<span class="dv">20</span>, <span class="dv">80</span>, <span class="at">by =</span> <span class="dv">1</span>)</span>
<span id="cb11-5"><a href="#cb11-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb11-6"><a href="#cb11-6" aria-hidden="true" tabindex="-1"></a>plot_data <span class="ot">&lt;-</span> <span class="fu">expand.grid</span>(</span>
<span id="cb11-7"><a href="#cb11-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">Age =</span> age_grid,</span>
<span id="cb11-8"><a href="#cb11-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">Gender =</span> <span class="fu">levels</span>(nhanes_logit<span class="sc">$</span>Gender)</span>
<span id="cb11-9"><a href="#cb11-9" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb11-10"><a href="#cb11-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb11-11"><a href="#cb11-11" aria-hidden="true" tabindex="-1"></a>plot_data<span class="sc">$</span>BMI <span class="ot">=</span> <span class="dv">27</span></span>
<span id="cb11-12"><a href="#cb11-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb11-13"><a href="#cb11-13" aria-hidden="true" tabindex="-1"></a>plot_data<span class="sc">$</span>pred_prob <span class="ot">&lt;-</span> <span class="fu">predict</span>(</span>
<span id="cb11-14"><a href="#cb11-14" aria-hidden="true" tabindex="-1"></a>  fit_logit,</span>
<span id="cb11-15"><a href="#cb11-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">newdata =</span> plot_data,</span>
<span id="cb11-16"><a href="#cb11-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">type =</span> <span class="st">"response"</span></span>
<span id="cb11-17"><a href="#cb11-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb11-18"><a href="#cb11-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb11-19"><a href="#cb11-19" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(plot_data, <span class="fu">aes</span>(<span class="at">x =</span> Age, <span class="at">y =</span> pred_prob, <span class="at">color =</span> Gender)) <span class="sc">+</span></span>
<span id="cb11-20"><a href="#cb11-20" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(<span class="at">size =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb11-21"><a href="#cb11-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb11-22"><a href="#cb11-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Age (years)"</span>,</span>
<span id="cb11-23"><a href="#cb11-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Predicted probability of HighBP"</span>,</span>
<span id="cb11-24"><a href="#cb11-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Predicted probability of high blood pressure by age and gender"</span>,</span>
<span id="cb11-25"><a href="#cb11-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"Gender"</span></span>
<span id="cb11-26"><a href="#cb11-26" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb11-27"><a href="#cb11-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ylim</span>(<span class="dv">0</span>, <span class="dv">1</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/03-ml-logistic-regression_files/figure-html/logit-prob-plot-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Estimated probability of high blood pressure by age and gender.</figcaption>
</figure>
</div>
</div>
</div>
<p>This gives us a smooth curve showing how the predicted probability of high blood pressure increases with age, and how it differs by gender (according to the model).</p>
<hr>
</section>
</section>
<section id="why-logistic-regression-matters-in-heor-and-health-policy" class="level1">
<h1>4. Why logistic regression matters in HEOR and health policy</h1>
<p>Logistic regression is not just a statistical trick for binary outcomes. In HEOR and health policy, it is one of the <strong>core tools</strong> for understanding and predicting key events.</p>
<section id="modeling-clinical-and-utilization-outcomes" class="level2">
<h2 class="anchored" data-anchor-id="modeling-clinical-and-utilization-outcomes">4.1. Modeling clinical and utilization outcomes</h2>
<p>Many important outcomes are binary:</p>
<ul>
<li>Hospitalization (yes/no)</li>
<li>ICU admission (yes/no)</li>
<li>Treatment adherence (yes/no)</li>
<li>Presence of a comorbidity (yes/no)</li>
<li>Response to treatment (responder/non-responder)</li>
</ul>
<p>Logistic regression provides:</p>
<ul>
<li>Adjusted comparisons between groups,</li>
<li>Estimates of how risk changes with age, comorbidities, or treatment,</li>
<li>A way to generate <strong>risk scores</strong> or <strong>propensities</strong>.</li>
</ul>
</section>
<section id="inputs-for-decision-analytic-and-simulation-models" class="level2">
<h2 class="anchored" data-anchor-id="inputs-for-decision-analytic-and-simulation-models">4.2. Inputs for decision-analytic and simulation models</h2>
<p>Decision-analytic models often need:</p>
<ul>
<li>Transition probabilities (e.g., probability of having a heart attack next year),</li>
<li>Event risks given patient characteristics,</li>
<li>Baseline and treatment-specific risk estimates.</li>
</ul>
<p>Logistic regression models can be used to:</p>
<ul>
<li>Estimate event probabilities given age, sex, disease status, etc.,</li>
<li>Provide individualized risk predictions that feed into <strong>microsimulation</strong> models,</li>
<li>Inform scenario analyses where you change risk factors or treatment patterns.</li>
</ul>
</section>
<section id="adjusting-for-confounding-in-observational-studies" class="level2">
<h2 class="anchored" data-anchor-id="adjusting-for-confounding-in-observational-studies">4.3. Adjusting for confounding in observational studies</h2>
<p>When outcomes are binary (e.g., did the patient die? was the patient hospitalized?), logistic regression serves as a basic workhorse for:</p>
<ul>
<li>Estimating <strong>adjusted odds ratios</strong>,</li>
<li>Implementing propensity score methods (propensity scores are often estimated using logistic regression),</li>
<li>Exploring how sensitive results are to different sets of covariates.</li>
</ul>
<p>While more advanced causal methods exist, logistic regression is often the first step - and sometimes the main engine - behind applied HEOR analyses.</p>
</section>
<section id="communicating-risk-to-decision-makers" class="level2">
<h2 class="anchored" data-anchor-id="communicating-risk-to-decision-makers">4.4. Communicating risk to decision-makers</h2>
<p>Logistic regression outputs can be turned into:</p>
<ul>
<li>Tables of predicted probabilities for different patient profiles,</li>
<li>Risk curves by age or comorbidity,</li>
<li>Simple "if-then" summaries that are understandable by clinicians, payers, and policy stakeholders.</li>
</ul>
<p>Being able to say:</p>
<blockquote class="blockquote">
<p>"In this population, patients with characteristic X have roughly <strong>twice the odds</strong> of event Y compared to patients without X, after adjustment."</p>
</blockquote>
<p>...is incredibly valuable in policy discussions.</p>
<hr>
</section>
</section>
<section id="further-reading" class="level1">
<h1>5. Further reading</h1>
<p>If you want to dive deeper into logistic regression (especially in health and biomedical settings), here are some classic and accessible references:</p>
<ol type="1">
<li><p><strong>Hosmer, Lemeshow, and Sturdivant - <em>Applied Logistic Regression</em></strong><br>
A widely used, application-focused text with many medical and epidemiological examples.</p></li>
<li><p><strong>Agresti - <em>An Introduction to Categorical Data Analysis</em></strong><br>
A broader look at categorical data methods, with logistic regression as a key chapter.</p></li>
<li><p><strong>Harrell - <em>Regression Modeling Strategies</em></strong><br>
Excellent for thinking carefully about model specification, validation, and interpretation in clinical and health research.</p></li>
<li><p><strong>UCLA IDRE: Logistic Regression in R (online tutorial)</strong><br>
A very practical, example-driven introduction to fitting and interpreting logistic regression models using R.</p></li>
</ol>
<p>Pick one (or more) of these when you're ready to go beyond the basics and into the land of model diagnostics, nonlinearity, interactions, and all the fun ways logistic regression can surprise you.</p>


<!-- -->

</section>
