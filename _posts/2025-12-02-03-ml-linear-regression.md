---
title: "Linear Regression in R: Foundations, Estimation, and Interpretation"
date: 2025-12-02
categories: [tutorials, codes]
tags: [Machine Learning]
summary: "Linear regression is that one student in class who shows up everywhere: In basic stats In machine learning In econometrics In random policy reports your boss forwards you at 4:59 pm"
---
<section id="introduction" class="level1">
<h1>1. Introduction</h1>
<p>Linear regression is that one student in class who shows up everywhere: In basic stats In machine learning In econometrics In random policy reports your boss forwards you at 4:59 pm</p>
<p>It's simple enough to teach in an intro course, but powerful enough that a huge chunk of applied research quietly runs on some flavor of it. If you've ever seen a sentence like:</p>
<p>"After adjusting for age and sex, the outcome increased by 2.3 units (95% CI: 1.5, 3.1)"</p>
<p>...there's a high chance a regression model was lurking behind the scenes.</p>
<p>In my experience the key to understanding linear regression is to know the answers to three questions:</p>
<p>What the linear regression model actually says (in math, but gently),</p>
<p>How the coefficients are estimated (least squares idea),</p>
<p>How to fit and interpret a model in R using real data.</p>
<p>By the end, the goal is not that you "worship" linear regression, but that you see it for what it is: A workhorse model with clear assumptions. It is a baseline method you should almost always understand before throwing fancy machine learning at a problem. A translator between messy data and interpretable stories.</p>
<p>And because this is HEOR/health-policy flavored, we'll end by talking about why this humble model is still one of the most useful tools in our toolkit.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="co"># Install NHANES package if needed</span></span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="cf">if</span> (<span class="sc">!</span><span class="fu">requireNamespace</span>(<span class="st">"NHANES"</span>, <span class="at">quietly =</span> <span class="cn">TRUE</span>)) {</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">install.packages</span>(<span class="st">"NHANES"</span>)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(NHANES)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
<hr>
</section>
<section id="the-simple-linear-regression-model" class="level1">
<h1>2. The simple linear regression model</h1>
<p>Suppose we want to model a continuous outcome <span class="math inline">\(Y\)</span> (e.g., BMI) as a function of a single predictor <span class="math inline">\(X\)</span> (e.g., age).</p>
<p>The <strong>simple linear regression model</strong> is:</p>
<p><span class="math display">\[
Y_i = \beta_0 + \beta_1 X_i + \varepsilon_i,
\]</span></p>
<p>where:</p>
<ul>
<li><span class="math inline">\(Y_i\)</span> is the outcome for individual <span class="math inline">\(i\)</span>,</li>
<li><span class="math inline">\(X_i\)</span> is the predictor for individual <span class="math inline">\(i\)</span>,</li>
<li><span class="math inline">\(\beta_0\)</span> is the <strong>intercept</strong> (expected value of <span class="math inline">\(Y\)</span> when <span class="math inline">\(X = 0\)</span>),</li>
<li><span class="math inline">\(\beta_1\)</span> is the <strong>slope</strong> (change in <span class="math inline">\(Y\)</span> for a one-unit increase in <span class="math inline">\(X\)</span>),</li>
<li><span class="math inline">\(\varepsilon_i\)</span> is a random error term.</li>
</ul>
<p>We typically assume that:</p>
<ul>
<li><span class="math inline">\(E[\varepsilon_i] = 0\)</span> (errors have mean zero),</li>
<li>The errors have constant variance,</li>
<li>Errors are (approximately) independent.</li>
</ul>
<hr>
</section>
<section id="how-are-the-coefficients-estimated" class="level1">
<h1>3. How are the coefficients estimated?</h1>
<p>In practice, we do <strong>not</strong> know <span class="math inline">\(\beta_0\)</span> and <span class="math inline">\(\beta_1\)</span>. We estimate them from data using the <strong>least squares</strong> method.</p>
<p>Given <span class="math inline">\(n\)</span> observations, we choose <span class="math inline">\(\hat{\beta}_0\)</span> and <span class="math inline">\(\hat{\beta}_1\)</span> to minimize the sum of squared residuals:</p>
<p><span class="math display">\[
\text{SSE}(\beta_0, \beta_1) = \sum_{i=1}^n \left( Y_i - (\beta_0 + \beta_1 X_i) \right)^2.
\]</span></p>
<p>The values of <span class="math inline">\(\hat{\beta}_0\)</span> and <span class="math inline">\(\hat{\beta}_1\)</span> that minimize this quantity are the <strong>ordinary least squares (OLS)</strong> estimates.</p>
<p>In R, we do not compute these formulas by hand; we use the <code>lm()</code> function. However, it is important to understand that the fitted line is the one that minimizes the squared vertical distances between observed points and the line.</p>
<hr>
</section>
<section id="a-real-world-example-with-nhanes-data" class="level1">
<h1>4. A real-world example with NHANES data</h1>
<p>We will explore how <strong>Body Mass Index (BMI)</strong> relates to <strong>age</strong> and <strong>sex</strong> using a subset of the NHANES data.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"NHANES"</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>nhanes_clean <span class="ot">&lt;-</span> NHANES <span class="sc">%&gt;%</span></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Keep adults only, for example</span></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(Age <span class="sc">&gt;=</span> <span class="dv">18</span>) <span class="sc">%&gt;%</span></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Keep complete cases for the variables of interest</span></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">select</span>(BMI, Age, Gender) <span class="sc">%&gt;%</span></span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(<span class="sc">!</span><span class="fu">is.na</span>(BMI), <span class="sc">!</span><span class="fu">is.na</span>(Age), <span class="sc">!</span><span class="fu">is.na</span>(Gender))</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a><span class="co"># Inspect the first rows</span></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a><span class="fu">head</span>(nhanes_clean)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code># A tibble: 6 × 3
    BMI   Age Gender
  &lt;dbl&gt; &lt;int&gt; &lt;fct&gt; 
1  32.2    34 male  
2  32.2    34 male  
3  32.2    34 male  
4  30.6    49 female
5  27.2    45 female
6  27.2    45 female</code></pre>
</div>
</div>
<p>Let's quickly summarize the variables:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a><span class="fu">summary</span>(nhanes_clean)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>      BMI             Age           Gender    
 Min.   :15.02   Min.   :18.00   female:3763  
 1st Qu.:23.96   1st Qu.:31.00   male  :3651  
 Median :27.60   Median :45.00                
 Mean   :28.67   Mean   :46.17                
 3rd Qu.:32.10   3rd Qu.:59.00                
 Max.   :81.25   Max.   :80.00                </code></pre>
</div>
</div>
<ul>
<li><strong>BMI</strong>: continuous outcome (kg/m^2).</li>
<li><strong>Age</strong>: continuous predictor (years).</li>
<li><strong>Gender</strong>: categorical predictor (Male / Female).</li>
</ul>
<p>We'll start with a <strong>simple model</strong>: BMI as a function of Age only.</p>
<hr>
<section id="simple-linear-regression-bmi-age" class="level2">
<h2 class="anchored" data-anchor-id="simple-linear-regression-bmi-age">4.1. Simple linear regression: BMI ~ Age</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>fit_simple <span class="ot">&lt;-</span> <span class="fu">lm</span>(BMI <span class="sc">~</span> Age, <span class="at">data =</span> nhanes_clean)</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a><span class="fu">summary</span>(fit_simple)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>
Call:
lm(formula = BMI ~ Age, data = nhanes_clean)

Residuals:
    Min      1Q  Median      3Q     Max 
-14.011  -4.693  -1.120   3.460  52.446 

Coefficients:
             Estimate Std. Error t value Pr(&gt;|t|)    
(Intercept) 27.542532   0.220383 124.976  &lt; 2e-16 ***
Age          0.024474   0.004467   5.478 4.43e-08 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 6.685 on 7412 degrees of freedom
Multiple R-squared:  0.004033,  Adjusted R-squared:  0.003899 
F-statistic: 30.01 on 1 and 7412 DF,  p-value: 4.432e-08</code></pre>
</div>
</div>
<p>Key components in the output:</p>
<ul>
<li><strong>Estimate for (Intercept)</strong>: <span class="math inline">\(\hat{\beta}_0\)</span>, the predicted BMI at Age = 0. (This value is often not of direct scientific interest if Age = 0 is outside the observed range, but it is needed for the model.)</li>
<li><strong>Estimate for Age</strong>: <span class="math inline">\(\hat{\beta}_1\)</span>, the change in BMI per one-year increase in age (on average), according to this simple linear model.</li>
<li><strong>Std. Error</strong>: standard errors of the coefficient estimates.</li>
<li><strong>t value</strong> and <strong>Pr(&gt;|t|)</strong>: used for hypothesis tests (e.g., test if <span class="math inline">\(\beta_1 = 0\)</span>).</li>
</ul>
<section id="interpreting-the-slope" class="level3">
<h3 class="anchored" data-anchor-id="interpreting-the-slope">Interpreting the slope</h3>
<p>If the estimated slope for Age is, for example, <strong>0.05</strong>, we would say:</p>
<blockquote class="blockquote">
<p>For each additional year of age, BMI increases by <strong>0.05 units on average</strong>,<br>
according to our simple linear regression model.</p>
</blockquote>
<p>This interpretation:</p>
<ul>
<li>Is <strong>conditional on the model being a good approximation</strong>.</li>
<li>Is <strong>on average</strong>, not for any specific individual.</li>
</ul>
<hr>
</section>
</section>
<section id="multiple-linear-regression-bmi-age-gender" class="level2">
<h2 class="anchored" data-anchor-id="multiple-linear-regression-bmi-age-gender">4.2. Multiple linear regression: BMI ~ Age + Gender</h2>
<p>We can extend to <strong>multiple linear regression</strong> by including Gender:</p>
<p>[ _i = _0 + _1 _i + _2 _i + _i, ]</p>
<p>where Gender is treated as a categorical variable. R will automatically use <strong>dummy (indicator) variables</strong>.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb8"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb8-1"><a href="#cb8-1" aria-hidden="true" tabindex="-1"></a>fit_multi <span class="ot">&lt;-</span> <span class="fu">lm</span>(BMI <span class="sc">~</span> Age <span class="sc">+</span> Gender, <span class="at">data =</span> nhanes_clean)</span>
<span id="cb8-2"><a href="#cb8-2" aria-hidden="true" tabindex="-1"></a><span class="fu">summary</span>(fit_multi)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>
Call:
lm(formula = BMI ~ Age + Gender, data = nhanes_clean)

Residuals:
    Min      1Q  Median      3Q     Max 
-13.990  -4.686  -1.136   3.450  52.469 

Coefficients:
             Estimate Std. Error t value Pr(&gt;|t|)    
(Intercept) 27.517376   0.236659 116.275  &lt; 2e-16 ***
Age          0.024535   0.004473   5.486 4.25e-08 ***
Gendermale   0.045363   0.155469   0.292     0.77    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 6.685 on 7411 degrees of freedom
Multiple R-squared:  0.004044,  Adjusted R-squared:  0.003776 
F-statistic: 15.05 on 2 and 7411 DF,  p-value: 3.008e-07</code></pre>
</div>
</div>
<p>Now the output includes:</p>
<ul>
<li>Intercept</li>
<li>Age</li>
<li>GenderMale (if R uses GenderFemale as the reference category)</li>
</ul>
<section id="interpreting-coefficients-in-the-multiple-regression" class="level3">
<h3 class="anchored" data-anchor-id="interpreting-coefficients-in-the-multiple-regression">Interpreting coefficients in the multiple regression</h3>
<p>Suppose the summary shows something like:</p>
<ul>
<li>Intercept: 25.0</li>
<li>Age: 0.03</li>
<li>GenderMale: 1.2</li>
</ul>
<p>Then we can interpret:</p>
<ul>
<li><p><strong>Intercept</strong> (25.0): Predicted BMI for the <strong>reference group</strong> when Age = 0. If GenderFemale is the reference category, this is BMI for a 0-year-old female (again, Age = 0 may not be directly meaningful, but the parameter is needed).</p></li>
<li><p><strong>Age</strong> (0.03): Holding Gender constant, each additional year of age is associated with an average <strong>0.03 unit increase in BMI</strong>.</p></li>
<li><p><strong>GenderMale</strong> (1.2): Holding Age constant, males have on average <strong>1.2 units higher BMI</strong> compared to females (if females are the reference category).</p></li>
</ul>
<p>Note the phrase <strong>"holding other variables constant"</strong> - this is key for interpreting coefficients in multiple regression.</p>
<hr>
</section>
</section>
</section>
<section id="visualizing-the-fitted-model" class="level1">
<h1>5. Visualizing the fitted model</h1>
<p>Visual diagnostics help assess whether a <strong>linear</strong> model is reasonable. We can plot BMI vs Age with the fitted regression line for the simple model.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb10"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb10-1"><a href="#cb10-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb10-2"><a href="#cb10-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb10-3"><a href="#cb10-3" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(nhanes_clean, <span class="fu">aes</span>(<span class="at">x =</span> Age, <span class="at">y =</span> BMI)) <span class="sc">+</span></span>
<span id="cb10-4"><a href="#cb10-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_point</span>(<span class="at">alpha =</span> <span class="fl">0.3</span>) <span class="sc">+</span></span>
<span id="cb10-5"><a href="#cb10-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_smooth</span>(<span class="at">method =</span> <span class="st">"lm"</span>, <span class="at">se =</span> <span class="cn">TRUE</span>, <span class="at">color =</span> <span class="st">"#3b7fbf"</span>) <span class="sc">+</span></span>
<span id="cb10-6"><a href="#cb10-6" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb10-7"><a href="#cb10-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"BMI vs Age with Linear Regression Fit"</span>,</span>
<span id="cb10-8"><a href="#cb10-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Age (years)"</span>,</span>
<span id="cb10-9"><a href="#cb10-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Body Mass Index (BMI)"</span></span>
<span id="cb10-10"><a href="#cb10-10" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/03-ml-linear-regression_files/figure-html/plot-simple-lm-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Scatter plot of BMI vs Age with fitted regression line (simple model).</figcaption>
</figure>
</div>
</div>
</div>
<p>We can also look at <strong>diagnostic plots</strong> for the multiple regression model:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb11"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb11-1"><a href="#cb11-1" aria-hidden="true" tabindex="-1"></a><span class="fu">par</span>(<span class="at">mfrow =</span> <span class="fu">c</span>(<span class="dv">2</span>, <span class="dv">2</span>))</span>
<span id="cb11-2"><a href="#cb11-2" aria-hidden="true" tabindex="-1"></a><span class="fu">plot</span>(fit_multi)</span>
<span id="cb11-3"><a href="#cb11-3" aria-hidden="true" tabindex="-1"></a><span class="fu">par</span>(<span class="at">mfrow =</span> <span class="fu">c</span>(<span class="dv">1</span>, <span class="dv">1</span>))</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/03-ml-linear-regression_files/figure-html/diag-plots-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Diagnostic plots for the multiple linear regression model.</figcaption>
</figure>
</div>
</div>
</div>
<p>These plots help us check:</p>
<ul>
<li>Residuals vs fitted: linearity and constant variance</li>
<li>Normal Q-Q: approximate normality of residuals</li>
<li>Scale-Location: further check of homoscedasticity</li>
<li>Residuals vs leverage: potential influential points</li>
</ul>
<hr>
</section>
<section id="why-linear-regression-matters-in-heor-and-health-policy" class="level1">
<h1>6. Why linear regression matters in HEOR and health policy</h1>
<p>So... was all this effort to estimate and interpret slopes worth it? In HEOR and health policy, the answer is a pretty strong yes.</p>
<p>Here are a few reasons why linear regression still earns its keep:</p>
<section id="describing-relationships-in-real-world-data" class="level2">
<h2 class="anchored" data-anchor-id="describing-relationships-in-real-world-data">Describing relationships in real-world data</h2>
<p>We constantly want to understand how outcomes vary across people:</p>
<p>How do costs vary by age, comorbidity burden, or treatment group?</p>
<p>How does quality of life (e.g., EQ-5D) change with disease severity?</p>
<p>How does resource use (e.g., number of visits) change with risk factors?</p>
</section>
<section id="regression-gives-us-a-structured-way-to-say-things-like" class="level2">
<h2 class="anchored" data-anchor-id="regression-gives-us-a-structured-way-to-say-things-like">Regression gives us a structured way to say things like:</h2>
<p>"After adjusting for age and sex, patients in group A had on average $X higher costs than group B."</p>
<p>Even if the model is not the final "causal" answer, it's a very useful descriptive tool.</p>
</section>
<section id="feeding-parameters-into-decision-analytic-models" class="level2">
<h2 class="anchored" data-anchor-id="feeding-parameters-into-decision-analytic-models">Feeding parameters into decision-analytic models</h2>
<p>Economic evaluation and simulation models often need inputs such as:</p>
<p>Age-specific mean costs</p>
<p>Treatment-specific utility values</p>
<p>Predicted outcomes under different risk profiles</p>
<p>Linear regression models (and their cousins) are a natural way to estimate these inputs, for example:</p>
<p>Predicting annual cost as a function of age, sex, and disease stage,</p>
<p>Predicting utility as a function of health states,</p>
<p>Deriving baseline risk or progression rates conditional on covariates.</p>
<p>Those regression outputs then become parameters in Markov models, microsimulation models, or other decision-analytic structures.</p>
</section>
<section id="adjusting-for-confounders-in-observational-comparisons" class="level2">
<h2 class="anchored" data-anchor-id="adjusting-for-confounders-in-observational-comparisons">Adjusting for confounders in observational comparisons</h2>
<p>In health policy, we rarely get perfect randomized trials for every question. We often end up comparing:</p>
<p>Treated vs untreated,</p>
<p>Insured vs uninsured,</p>
<p>Before vs after a policy change.</p>
<p>Linear regression (and generalized linear models) are a basic way to:</p>
<p>Adjust for measured confounders (age, sex, comorbidities, etc.),</p>
<p>Provide adjusted mean differences that are more interpretable than raw averages.</p>
<p>It's not magic-and it doesn't fix unmeasured confounding-but it's often step one in a more complete causal analysis.</p>
</section>
<section id="a-baseline-to-compare-fancier-models-against" class="level2">
<h2 class="anchored" data-anchor-id="a-baseline-to-compare-fancier-models-against">A baseline to compare fancier models against</h2>
<p>Even when you move to Random forests, Gradient boosting, Neural nets, you should almost always compare them to a simple linear model. Why?</p>
<ul>
<li><p>It's fast, interpretable, and easy to debug.</p></li>
<li><p>If a fancy model barely improves over linear regression, you might not need the extra complexity.</p></li>
<li><p>If a fancy model does improve a lot, linear regression helps you understand where and why the simple assumptions were failing.</p></li>
<li><p>In HEOR, where explainability and transparency matter (e.g., for HTA bodies, regulators, and policy stakeholders), having a clear linear model as a reference is extremely valuable.</p></li>
</ul>


<!-- -->

</section>
</section>
