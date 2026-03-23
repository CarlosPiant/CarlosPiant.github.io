---
title: "Dot-and-Whisker Marginal Effects Plot"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a dot-and-whisker marginal effects plot and shows how to display model results on an outcome scale that readers can often interpret more directly than raw coefficients. Coefficient plots are..."
---
<p>This chapter creates a dot-and-whisker marginal effects plot and shows how to display model results on an outcome scale that readers can often interpret more directly than raw coefficients. Coefficient plots are useful, but they can be hard to read when the model uses a nonlinear link such as logistic regression. A coefficient in log-odds units is mathematically correct, yet it is not always the quantity a policy reader wants to see. A marginal effects plot solves that problem by plotting changes in predicted probability, expected count, or expected outcome rather than changes in the model's linear predictor.</p>
<p>The figure is especially useful in health economics and decision sciences because many substantive questions are naturally framed in terms of probability or expected outcome differences. How much does a discharge intervention change the probability of readmission? How much does poor adherence change the predicted risk of death? How much does treatment change an expected outcome for a typical patient profile? Those are marginal-effects questions.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="72.1">
<h2 data-number="72.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">72.1</span> What the visualization is showing</h2>
<p>We will build a dot-and-whisker plot for average marginal effects from a regression model. Each row will show:</p>
<ol type="1">
<li>a predictor label,</li>
<li>an estimated marginal effect,</li>
<li>a confidence interval,</li>
<li>a vertical reference line at the null value.</li>
</ol>
<p>For average marginal effects on a probability scale, the null value is 0. Values to the right of 0 indicate an increase in predicted probability. Values to the left indicate a decrease. Confidence intervals that cross 0 indicate that the data remain compatible with no average marginal effect at the chosen confidence level.</p>
<p>The main conceptual difference from a coefficient plot is that the x-axis now represents an outcome-scale effect rather than a model-parameter scale.</p>
</section>
<section id="step-1-create-and-fit-a-synthetic-regression-model" class="level2" data-number="72.2">
<h2 data-number="72.2" class="anchored" data-anchor-id="step-1-create-and-fit-a-synthetic-regression-model"><span class="header-section-number">72.2</span> Step 1: Create and fit a synthetic regression model</h2>
<p>We will start with a synthetic logistic regression for 30-day hospital readmission. The goal is to build a fitted model from which we can compute average marginal effects and then visualize them.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>n_patients <span class="ot">&lt;-</span> <span class="dv">900</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>synthetic_readmission <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">age10 =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="fl">6.9</span>, <span class="at">sd =</span> <span class="fl">1.0</span>),</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">prior_admissions =</span> <span class="fu">rpois</span>(n_patients, <span class="at">lambda =</span> <span class="fl">1.4</span>),</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">comorbidity_score =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>),</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">social_risk =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>),</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">intervention =</span> <span class="fu">rbinom</span>(n_patients, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.5</span>)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>linear_predictor <span class="ot">&lt;-</span> <span class="fu">with</span>(</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  synthetic_readmission,</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="sc">-</span><span class="fl">1.15</span> <span class="sc">+</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.20</span> <span class="sc">*</span> age10 <span class="sc">+</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.30</span> <span class="sc">*</span> prior_admissions <span class="sc">+</span></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.42</span> <span class="sc">*</span> comorbidity_score <span class="sc">+</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.28</span> <span class="sc">*</span> social_risk <span class="sc">-</span></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.48</span> <span class="sc">*</span> intervention</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>synthetic_readmission<span class="sc">$</span>readmission <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>  n_patients,</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>  <span class="at">size =</span> <span class="dv">1</span>,</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>  <span class="at">prob =</span> <span class="fu">plogis</span>(linear_predictor)</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>synthetic_logit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>  readmission <span class="sc">~</span> intervention <span class="sc">+</span> age10 <span class="sc">+</span> prior_admissions <span class="sc">+</span> comorbidity_score <span class="sc">+</span> social_risk,</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_readmission,</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(synthetic_readmission),</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>  <span class="at">readmission_rate =</span> <span class="fu">mean</span>(synthetic_readmission<span class="sc">$</span>readmission),</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_age10 =</span> <span class="fu">mean</span>(synthetic_readmission<span class="sc">$</span>age10),</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_prior_admissions =</span> <span class="fu">mean</span>(synthetic_readmission<span class="sc">$</span>prior_admissions)</span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>synthetic_summary[, <span class="sc">-</span><span class="dv">1</span>] <span class="ot">&lt;-</span> <span class="fu">round</span>(synthetic_summary[, <span class="sc">-</span><span class="dv">1</span>], <span class="dv">3</span>)</span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>  synthetic_summary,</span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the synthetic readmission dataset used for the marginal effects plot"</span></span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the synthetic readmission dataset used for the marginal effects plot</caption>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">readmission_rate</th>
<th style="text-align: right;">mean_age10</th>
<th style="text-align: right;">mean_prior_admissions</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">900</td>
<td style="text-align: right;">0.606</td>
<td style="text-align: right;">6.923</td>
<td style="text-align: right;">1.424</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This model is similar to the one used in the coefficient-plot chapter, but the quantity we will report is different. We want changes in predicted readmission probability, not just changes in log-odds.</p>
</section>
<section id="step-2-compute-average-marginal-effects-manually" class="level2" data-number="72.3">
<h2 data-number="72.3" class="anchored" data-anchor-id="step-2-compute-average-marginal-effects-manually"><span class="header-section-number">72.3</span> Step 2: Compute average marginal effects manually</h2>
<p>Because the local environment does not rely on a dedicated marginal-effects package, we will compute the effects directly from the fitted model. For a binary predictor such as <code>intervention</code>, the average marginal effect is the average difference in predicted probability when the variable is set to 1 versus 0 for every observation. For a continuous predictor, we can approximate the derivative by taking a small finite difference.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>compute_binary_ame <span class="ot">&lt;-</span> <span class="cf">function</span>(model, data, var) {</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  data_lo <span class="ot">&lt;-</span> data</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  data_hi <span class="ot">&lt;-</span> data</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  data_lo[[var]] <span class="ot">&lt;-</span> <span class="dv">0</span></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  data_hi[[var]] <span class="ot">&lt;-</span> <span class="dv">1</span></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  p_lo <span class="ot">&lt;-</span> <span class="fu">predict</span>(model, <span class="at">newdata =</span> data_lo, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  p_hi <span class="ot">&lt;-</span> <span class="fu">predict</span>(model, <span class="at">newdata =</span> data_hi, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  diffs <span class="ot">&lt;-</span> p_hi <span class="sc">-</span> p_lo</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">term =</span> var,</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> <span class="fu">mean</span>(diffs),</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">std_error =</span> <span class="fu">sd</span>(diffs) <span class="sc">/</span> <span class="fu">sqrt</span>(<span class="fu">length</span>(diffs))</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>compute_continuous_ame <span class="ot">&lt;-</span> <span class="cf">function</span>(model, data, var, <span class="at">step =</span> <span class="fl">0.1</span>) {</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  data_lo <span class="ot">&lt;-</span> data</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>  data_hi <span class="ot">&lt;-</span> data</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  data_lo[[var]] <span class="ot">&lt;-</span> data_lo[[var]] <span class="sc">-</span> step <span class="sc">/</span> <span class="dv">2</span></span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  data_hi[[var]] <span class="ot">&lt;-</span> data_hi[[var]] <span class="sc">+</span> step <span class="sc">/</span> <span class="dv">2</span></span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>  p_lo <span class="ot">&lt;-</span> <span class="fu">predict</span>(model, <span class="at">newdata =</span> data_lo, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>  p_hi <span class="ot">&lt;-</span> <span class="fu">predict</span>(model, <span class="at">newdata =</span> data_hi, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  diffs <span class="ot">&lt;-</span> (p_hi <span class="sc">-</span> p_lo) <span class="sc">/</span> step</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>    <span class="at">term =</span> var,</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> <span class="fu">mean</span>(diffs),</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">std_error =</span> <span class="fu">sd</span>(diffs) <span class="sc">/</span> <span class="fu">sqrt</span>(<span class="fu">length</span>(diffs))</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>synthetic_ame <span class="ot">&lt;-</span> dplyr<span class="sc">::</span><span class="fu">bind_rows</span>(</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_binary_ame</span>(synthetic_logit, synthetic_readmission, <span class="st">"intervention"</span>),</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_continuous_ame</span>(synthetic_logit, synthetic_readmission, <span class="st">"age10"</span>),</span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_continuous_ame</span>(synthetic_logit, synthetic_readmission, <span class="st">"prior_admissions"</span>, <span class="at">step =</span> <span class="dv">1</span>),</span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_continuous_ame</span>(synthetic_logit, synthetic_readmission, <span class="st">"comorbidity_score"</span>),</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_continuous_ame</span>(synthetic_logit, synthetic_readmission, <span class="st">"social_risk"</span>)</span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>) <span class="sc">|&gt;</span></span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a>    <span class="at">conf_low =</span> estimate <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> std_error,</span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>    <span class="at">conf_high =</span> estimate <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> std_error,</span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a>    <span class="at">term_label =</span> <span class="fu">c</span>(</span>
<span id="cb2-50"><a href="#cb2-50" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Discharge intervention"</span>,</span>
<span id="cb2-51"><a href="#cb2-51" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Age (per 10 years)"</span>,</span>
<span id="cb2-52"><a href="#cb2-52" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Prior admissions"</span>,</span>
<span id="cb2-53"><a href="#cb2-53" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Comorbidity score"</span>,</span>
<span id="cb2-54"><a href="#cb2-54" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Social risk index"</span></span>
<span id="cb2-55"><a href="#cb2-55" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-56"><a href="#cb2-56" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-57"><a href="#cb2-57" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-58"><a href="#cb2-58" aria-hidden="true" tabindex="-1"></a>synthetic_table <span class="ot">&lt;-</span> synthetic_ame <span class="sc">|&gt;</span></span>
<span id="cb2-59"><a href="#cb2-59" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">transmute</span>(</span>
<span id="cb2-60"><a href="#cb2-60" aria-hidden="true" tabindex="-1"></a>    <span class="at">predictor =</span> term_label,</span>
<span id="cb2-61"><a href="#cb2-61" aria-hidden="true" tabindex="-1"></a>    <span class="at">average_marginal_effect =</span> <span class="fu">round</span>(estimate, <span class="dv">3</span>),</span>
<span id="cb2-62"><a href="#cb2-62" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower_95_ci =</span> <span class="fu">round</span>(conf_low, <span class="dv">3</span>),</span>
<span id="cb2-63"><a href="#cb2-63" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper_95_ci =</span> <span class="fu">round</span>(conf_high, <span class="dv">3</span>)</span>
<span id="cb2-64"><a href="#cb2-64" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-65"><a href="#cb2-65" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-66"><a href="#cb2-66" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-67"><a href="#cb2-67" aria-hidden="true" tabindex="-1"></a>  synthetic_table,</span>
<span id="cb2-68"><a href="#cb2-68" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Synthetic average marginal effects on the readmission probability scale"</span></span>
<span id="cb2-69"><a href="#cb2-69" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Synthetic average marginal effects on the readmission probability scale</caption>
<colgroup>
<col style="width: 32%">
<col style="width: 33%">
<col style="width: 16%">
<col style="width: 16%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">predictor</th>
<th style="text-align: right;">average_marginal_effect</th>
<th style="text-align: right;">lower_95_ci</th>
<th style="text-align: right;">upper_95_ci</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Discharge intervention</td>
<td style="text-align: right;">-0.080</td>
<td style="text-align: right;">-0.081</td>
<td style="text-align: right;">-0.079</td>
</tr>
<tr class="even">
<td style="text-align: left;">Age (per 10 years)</td>
<td style="text-align: right;">0.049</td>
<td style="text-align: right;">0.049</td>
<td style="text-align: right;">0.050</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Prior admissions</td>
<td style="text-align: right;">0.053</td>
<td style="text-align: right;">0.053</td>
<td style="text-align: right;">0.054</td>
</tr>
<tr class="even">
<td style="text-align: left;">Comorbidity score</td>
<td style="text-align: right;">0.088</td>
<td style="text-align: right;">0.087</td>
<td style="text-align: right;">0.089</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Social risk index</td>
<td style="text-align: right;">0.068</td>
<td style="text-align: right;">0.067</td>
<td style="text-align: right;">0.068</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table contains the information that the plot will encode. A coefficient plot would show effects in log-odds units; this plot will show changes in predicted readmission probability.</p>
</section>
<section id="step-3-build-a-reusable-dot-and-whisker-plotting-function" class="level2" data-number="72.4">
<h2 data-number="72.4" class="anchored" data-anchor-id="step-3-build-a-reusable-dot-and-whisker-plotting-function"><span class="header-section-number">72.4</span> Step 3: Build a reusable dot-and-whisker plotting function</h2>
<p>The function below is designed for marginal effects with confidence intervals centered around a null value of 0. The aesthetic grammar is similar to a coefficient plot, but the x-axis label now refers to marginal effects rather than model coefficients.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>build_marginal_effects_plot <span class="ot">&lt;-</span> <span class="cf">function</span>(data, title, subtitle, x_label) {</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  plot_data <span class="ot">&lt;-</span> data <span class="sc">|&gt;</span></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>      <span class="at">term_label =</span> <span class="fu">factor</span>(term_label, <span class="at">levels =</span> <span class="fu">rev</span>(term_label)),</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>      <span class="at">direction =</span> <span class="fu">ifelse</span>(estimate <span class="sc">&gt;=</span> <span class="dv">0</span>, <span class="st">"Increase"</span>, <span class="st">"Decrease"</span>),</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>      <span class="at">label_text =</span> <span class="fu">sprintf</span>(<span class="st">"%.3f (%.3f to %.3f)"</span>, estimate, conf_low, conf_high)</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  label_position <span class="ot">&lt;-</span> <span class="fu">max</span>(plot_data<span class="sc">$</span>conf_high) <span class="sc">+</span> <span class="fl">0.15</span> <span class="sc">*</span> <span class="fu">diff</span>(<span class="fu">range</span>(<span class="fu">c</span>(plot_data<span class="sc">$</span>conf_low, plot_data<span class="sc">$</span>conf_high)))</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>(plot_data, <span class="fu">aes</span>(<span class="at">x =</span> estimate, <span class="at">y =</span> term_label, <span class="at">color =</span> direction)) <span class="sc">+</span></span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="dv">0</span>, <span class="at">color =</span> <span class="st">"#7f7f7f"</span>, <span class="at">linetype =</span> <span class="st">"dashed"</span>, <span class="at">linewidth =</span> <span class="fl">0.6</span>) <span class="sc">+</span></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> conf_low, <span class="at">xend =</span> conf_high, <span class="at">yend =</span> term_label),</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.95</span>,</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>      <span class="at">show.legend =</span> <span class="cn">FALSE</span></span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_point</span>(<span class="at">size =</span> <span class="fl">3.2</span>, <span class="at">show.legend =</span> <span class="cn">FALSE</span>) <span class="sc">+</span></span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> label_position, <span class="at">label =</span> label_text),</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>      <span class="at">hjust =</span> <span class="dv">0</span>,</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#1f1f1f"</span>,</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.4</span></span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_color_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"Decrease"</span> <span class="ot">=</span> <span class="st">"#2b8cbe"</span>, <span class="st">"Increase"</span> <span class="ot">=</span> <span class="st">"#8c2d04"</span>)) <span class="sc">+</span></span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coord_cartesian</span>(</span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a>      <span class="at">xlim =</span> <span class="fu">c</span>(</span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>        <span class="fu">min</span>(plot_data<span class="sc">$</span>conf_low) <span class="sc">-</span> <span class="fl">0.18</span> <span class="sc">*</span> <span class="fu">diff</span>(<span class="fu">range</span>(<span class="fu">c</span>(plot_data<span class="sc">$</span>conf_low, plot_data<span class="sc">$</span>conf_high))),</span>
<span id="cb3-29"><a href="#cb3-29" aria-hidden="true" tabindex="-1"></a>        label_position <span class="sc">+</span> <span class="fl">0.05</span></span>
<span id="cb3-30"><a href="#cb3-30" aria-hidden="true" tabindex="-1"></a>      ),</span>
<span id="cb3-31"><a href="#cb3-31" aria-hidden="true" tabindex="-1"></a>      <span class="at">clip =</span> <span class="st">"off"</span></span>
<span id="cb3-32"><a href="#cb3-32" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb3-33"><a href="#cb3-33" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb3-34"><a href="#cb3-34" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb3-35"><a href="#cb3-35" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle,</span>
<span id="cb3-36"><a href="#cb3-36" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> x_label,</span>
<span id="cb3-37"><a href="#cb3-37" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> <span class="cn">NULL</span></span>
<span id="cb3-38"><a href="#cb3-38" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb3-39"><a href="#cb3-39" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb3-40"><a href="#cb3-40" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb3-41"><a href="#cb3-41" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.major.y =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb3-42"><a href="#cb3-42" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb3-43"><a href="#cb3-43" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.margin =</span> <span class="fu">margin</span>(<span class="dv">10</span>, <span class="dv">110</span>, <span class="dv">10</span>, <span class="dv">10</span>)</span>
<span id="cb3-44"><a href="#cb3-44" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb3-45"><a href="#cb3-45" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<p>The figure is intentionally restrained. The point is to show estimated magnitude and uncertainty on a scale that is closer to the substantive question being asked.</p>
</section>
<section id="step-4-draw-the-synthetic-marginal-effects-plot" class="level2" data-number="72.5">
<h2 data-number="72.5" class="anchored" data-anchor-id="step-4-draw-the-synthetic-marginal-effects-plot"><span class="header-section-number">72.5</span> Step 4: Draw the synthetic marginal effects plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_marginal_plot <span class="ot">&lt;-</span> <span class="fu">build_marginal_effects_plot</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  synthetic_ame,</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Dot-and-whisker plot of synthetic average marginal effects"</span>,</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Points show average changes in readmission probability; bars show 95% confidence intervals"</span>,</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">x_label =</span> <span class="st">"Average marginal effect on readmission probability"</span></span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>synthetic_marginal_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/dot-and-whisker-marginal-effects-plot_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure is often easier to explain than the corresponding coefficient plot. The intervention's marginal effect can now be read as an average percentage-point change in readmission probability rather than as a change in log-odds.</p>
</section>
<section id="step-5-create-a-real-world-marginal-effects-plot-from-a-public-trial-dataset" class="level2" data-number="72.6">
<h2 data-number="72.6" class="anchored" data-anchor-id="step-5-create-a-real-world-marginal-effects-plot-from-a-public-trial-dataset"><span class="header-section-number">72.6</span> Step 5: Create a real-world marginal effects plot from a public trial dataset</h2>
<p>For a real-world example, we can use the public <code>colon</code> dataset from the <code>survival</code> package. These data come from the adjuvant colon cancer trials reported by Laurie and colleagues and Moertel and colleagues <span class="citation" data-cites="laurie1989">Laurie et al. (<a href="#ref-laurie1989" role="doc-biblioref">1989</a>)</span>; <span class="citation" data-cites="moertel1990">Moertel et al. (<a href="#ref-moertel1990" role="doc-biblioref">1990</a>)</span>. Instead of plotting raw logistic or Cox coefficients, we will fit a logistic model for 1-year mortality and then plot average marginal effects on the probability scale.</p>
<p>This is a transparent partial replication. The original trial publications did not report exactly this plot, and the 1-year mortality model below is a modern teaching adaptation rather than a reconstruction of the original printed analyses.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(survival)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>colon_1y <span class="ot">&lt;-</span> survival<span class="sc">::</span>colon <span class="sc">|&gt;</span></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">filter</span>(etype <span class="sc">==</span> <span class="dv">2</span>, rx <span class="sc">%in%</span> <span class="fu">c</span>(<span class="st">"Obs"</span>, <span class="st">"Lev+5FU"</span>)) <span class="sc">|&gt;</span></span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">treatment =</span> <span class="fu">ifelse</span>(rx <span class="sc">==</span> <span class="st">"Lev+5FU"</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">age10 =</span> age <span class="sc">/</span> <span class="dv">10</span>,</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">male =</span> <span class="fu">ifelse</span>(sex <span class="sc">==</span> <span class="dv">1</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">nodes4 =</span> <span class="fu">ifelse</span>(nodes <span class="sc">&gt;</span> <span class="dv">4</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">obstruction =</span> <span class="fu">ifelse</span>(obstruct <span class="sc">==</span> <span class="dv">1</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">adherence =</span> <span class="fu">ifelse</span>(adhere <span class="sc">==</span> <span class="dv">1</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">death_1y =</span> <span class="fu">ifelse</span>(status <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> time <span class="sc">&lt;=</span> <span class="dv">365</span>, <span class="dv">1</span>, <span class="dv">0</span>)</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">filter</span>(</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>    <span class="sc">!</span><span class="fu">is.na</span>(treatment),</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>    <span class="sc">!</span><span class="fu">is.na</span>(age10),</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>    <span class="sc">!</span><span class="fu">is.na</span>(male),</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>    <span class="sc">!</span><span class="fu">is.na</span>(nodes4),</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>    <span class="sc">!</span><span class="fu">is.na</span>(obstruction),</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>    <span class="sc">!</span><span class="fu">is.na</span>(adherence),</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>    <span class="sc">!</span><span class="fu">is.na</span>(death_1y)</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>colon_logit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>  death_1y <span class="sc">~</span> treatment <span class="sc">+</span> age10 <span class="sc">+</span> male <span class="sc">+</span> nodes4 <span class="sc">+</span> obstruction <span class="sc">+</span> adherence,</span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> colon_1y,</span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-30"><a href="#cb5-30" aria-hidden="true" tabindex="-1"></a>colon_ame <span class="ot">&lt;-</span> dplyr<span class="sc">::</span><span class="fu">bind_rows</span>(</span>
<span id="cb5-31"><a href="#cb5-31" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_binary_ame</span>(colon_logit, colon_1y, <span class="st">"treatment"</span>),</span>
<span id="cb5-32"><a href="#cb5-32" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_continuous_ame</span>(colon_logit, colon_1y, <span class="st">"age10"</span>),</span>
<span id="cb5-33"><a href="#cb5-33" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_binary_ame</span>(colon_logit, colon_1y, <span class="st">"male"</span>),</span>
<span id="cb5-34"><a href="#cb5-34" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_binary_ame</span>(colon_logit, colon_1y, <span class="st">"nodes4"</span>),</span>
<span id="cb5-35"><a href="#cb5-35" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_binary_ame</span>(colon_logit, colon_1y, <span class="st">"obstruction"</span>),</span>
<span id="cb5-36"><a href="#cb5-36" aria-hidden="true" tabindex="-1"></a>  <span class="fu">compute_binary_ame</span>(colon_logit, colon_1y, <span class="st">"adherence"</span>)</span>
<span id="cb5-37"><a href="#cb5-37" aria-hidden="true" tabindex="-1"></a>) <span class="sc">|&gt;</span></span>
<span id="cb5-38"><a href="#cb5-38" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb5-39"><a href="#cb5-39" aria-hidden="true" tabindex="-1"></a>    <span class="at">conf_low =</span> estimate <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> std_error,</span>
<span id="cb5-40"><a href="#cb5-40" aria-hidden="true" tabindex="-1"></a>    <span class="at">conf_high =</span> estimate <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> std_error,</span>
<span id="cb5-41"><a href="#cb5-41" aria-hidden="true" tabindex="-1"></a>    <span class="at">term_label =</span> <span class="fu">c</span>(</span>
<span id="cb5-42"><a href="#cb5-42" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Levamisole + 5FU treatment"</span>,</span>
<span id="cb5-43"><a href="#cb5-43" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Age (per 10 years)"</span>,</span>
<span id="cb5-44"><a href="#cb5-44" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Male sex"</span>,</span>
<span id="cb5-45"><a href="#cb5-45" aria-hidden="true" tabindex="-1"></a>      <span class="st">"More than 4 positive nodes"</span>,</span>
<span id="cb5-46"><a href="#cb5-46" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Obstruction present"</span>,</span>
<span id="cb5-47"><a href="#cb5-47" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Adherent to protocol"</span></span>
<span id="cb5-48"><a href="#cb5-48" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb5-49"><a href="#cb5-49" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-50"><a href="#cb5-50" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-51"><a href="#cb5-51" aria-hidden="true" tabindex="-1"></a>colon_table <span class="ot">&lt;-</span> colon_ame <span class="sc">|&gt;</span></span>
<span id="cb5-52"><a href="#cb5-52" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">transmute</span>(</span>
<span id="cb5-53"><a href="#cb5-53" aria-hidden="true" tabindex="-1"></a>    <span class="at">predictor =</span> term_label,</span>
<span id="cb5-54"><a href="#cb5-54" aria-hidden="true" tabindex="-1"></a>    <span class="at">average_marginal_effect =</span> <span class="fu">round</span>(estimate, <span class="dv">3</span>),</span>
<span id="cb5-55"><a href="#cb5-55" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower_95_ci =</span> <span class="fu">round</span>(conf_low, <span class="dv">3</span>),</span>
<span id="cb5-56"><a href="#cb5-56" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper_95_ci =</span> <span class="fu">round</span>(conf_high, <span class="dv">3</span>)</span>
<span id="cb5-57"><a href="#cb5-57" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-58"><a href="#cb5-58" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-59"><a href="#cb5-59" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-60"><a href="#cb5-60" aria-hidden="true" tabindex="-1"></a>  colon_table,</span>
<span id="cb5-61"><a href="#cb5-61" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Average marginal effects from a logistic model for 1-year mortality in the public colon trial data"</span></span>
<span id="cb5-62"><a href="#cb5-62" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Average marginal effects from a logistic model for 1-year mortality in the public colon trial data</caption>
<colgroup>
<col style="width: 36%">
<col style="width: 32%">
<col style="width: 16%">
<col style="width: 16%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">predictor</th>
<th style="text-align: right;">average_marginal_effect</th>
<th style="text-align: right;">lower_95_ci</th>
<th style="text-align: right;">upper_95_ci</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Levamisole + 5FU treatment</td>
<td style="text-align: right;">0.014</td>
<td style="text-align: right;">0.013</td>
<td style="text-align: right;">0.015</td>
</tr>
<tr class="even">
<td style="text-align: left;">Age (per 10 years)</td>
<td style="text-align: right;">0.033</td>
<td style="text-align: right;">0.031</td>
<td style="text-align: right;">0.035</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Male sex</td>
<td style="text-align: right;">-0.018</td>
<td style="text-align: right;">-0.019</td>
<td style="text-align: right;">-0.016</td>
</tr>
<tr class="even">
<td style="text-align: left;">More than 4 positive nodes</td>
<td style="text-align: right;">0.101</td>
<td style="text-align: right;">0.097</td>
<td style="text-align: right;">0.105</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Obstruction present</td>
<td style="text-align: right;">0.067</td>
<td style="text-align: right;">0.063</td>
<td style="text-align: right;">0.070</td>
</tr>
<tr class="even">
<td style="text-align: left;">Adherent to protocol</td>
<td style="text-align: right;">0.056</td>
<td style="text-align: right;">0.053</td>
<td style="text-align: right;">0.058</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>colon_marginal_plot <span class="ot">&lt;-</span> <span class="fu">build_marginal_effects_plot</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  colon_ame,</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Dot-and-whisker plot of marginal effects in the public colon trial data"</span>,</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Points show average effects on the 1-year mortality probability; bars show 95% confidence intervals"</span>,</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">x_label =</span> <span class="st">"Average marginal effect on 1-year mortality probability"</span></span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>colon_marginal_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/dot-and-whisker-marginal-effects-plot_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure highlights something coefficient tables often hide: some predictors may have modest-looking model coefficients but practically meaningful effects on predicted risk once translated onto the probability scale.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="72.7">
<h2 data-number="72.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">72.7</span> How to read the figure carefully</h2>
<p>A marginal effects plot is usually easier to interpret than a coefficient plot, but it is not assumption free. The displayed uncertainty still depends on the fitted model. The plotted effects are summaries of predicted differences under that model, not model-free causal quantities.</p>
<p>The plot is also sensitive to how marginal effects are defined. For binary variables, the average discrete change from 0 to 1 is often the most natural choice. For continuous variables, the derivative or finite-difference approximation depends on scaling. A change per 10 years of age will look different from a change per single year. That is why labels and units matter.</p>
<p>Finally, the plot is only as informative as the model and outcome scale. If the fitted model is badly misspecified, a well-designed figure will still summarize the wrong quantity very clearly.</p>
</section>
<section id="further-reading" class="level2" data-number="72.8">
<h2 data-number="72.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">72.8</span> Further reading</h2>
<p>Kastellec and Leoni make the general case for estimate-focused graphics rather than dense regression tables <span class="citation" data-cites="kastellec2007graphs">Kastellec and Leoni (<a href="#ref-kastellec2007graphs" role="doc-biblioref">2007</a>)</span>. The colon cancer trial papers by Laurie and colleagues and Moertel and colleagues provide the public clinical setting used for the partial real-world example <span class="citation" data-cites="laurie1989">Laurie et al. (<a href="#ref-laurie1989" role="doc-biblioref">1989</a>)</span>; <span class="citation" data-cites="moertel1990">Moertel et al. (<a href="#ref-moertel1990" role="doc-biblioref">1990</a>)</span>. A natural next step after this chapter is to compare coefficient plots and marginal-effects plots directly for the same nonlinear model so readers can see why the distinction matters.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-kastellec2007graphs" class="csl-entry" role="listitem">
Kastellec, Jonathan P., and Eduardo L. Leoni. 2007. <span>"Using Graphs Instead of Tables in Political Science."</span> <em>Perspectives on Politics</em> 5 (4): 755-71. <a href="https://doi.org/10.1017/S1537592707072209">https://doi.org/10.1017/S1537592707072209</a>.
</div>
<div id="ref-laurie1989" class="csl-entry" role="listitem">
Laurie, John A., Charles G. Moertel, Thomas R. Fleming, H. S. Wieand, James E. Leigh, Joseph Rubin, G. W. McCormack, J. B. Gerstner, J. E. Krook, and James A. Mailliard. 1989. <span>"Surgical Adjuvant Therapy of Large-Bowel Carcinoma: An Evaluation of Levamisole and the Combination of Levamisole and Fluorouracil."</span> <em>Journal of Clinical Oncology</em> 7 (10): 1447-56. <a href="https://doi.org/10.1200/JCO.1989.7.10.1447">https://doi.org/10.1200/JCO.1989.7.10.1447</a>.
</div>
<div id="ref-moertel1990" class="csl-entry" role="listitem">
Moertel, Charles G., Thomas R. Fleming, John S. Macdonald, Daniel G. Haller, John A. Laurie, Phyllis J. Goodman, James S. Ungerleider, et al. 1990. <span>"Levamisole and Fluorouracil for Adjuvant Therapy of Resected Colon Carcinoma."</span> <em>New England Journal of Medicine</em> 322 (6): 352-58. <a href="https://doi.org/10.1056/NEJM199002083220602">https://doi.org/10.1056/NEJM199002083220602</a>.
</div>
</div>
</section>
