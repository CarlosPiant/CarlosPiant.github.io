---
title: "Coefficient Plots"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a coefficient plot and shows how to turn a fitted regression model into a clear, publication-ready figure. Coefficient plots are useful because they put point estimates and confidence intervals..."
---
<p>This chapter creates a coefficient plot and shows how to turn a fitted regression model into a clear, publication-ready figure. Coefficient plots are useful because they put point estimates and confidence intervals at the center of the presentation rather than hiding them in a table of numbers. That is why they have become a standard way to report regression results in many applied fields <span class="citation" data-cites="kastellec2007graphs">Kastellec and Leoni (<a href="#ref-kastellec2007graphs" role="doc-biblioref">2007</a>)</span>.</p>
<p>The figure is especially helpful when a model has several predictors. A regression table forces the reader to move back and forth across rows and columns to understand sign, magnitude, and uncertainty. A coefficient plot makes those three features visible at once.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="69.1">
<h2 data-number="69.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">69.1</span> What the visualization is showing</h2>
<p>We will build a coefficient plot for a regression model. Each row will show:</p>
<ol type="1">
<li>a predictor label,</li>
<li>the estimated coefficient,</li>
<li>its confidence interval,</li>
<li>a vertical reference line at the null value.</li>
</ol>
<p>When the coefficients are shown on the original model scale, the null value is usually 0. Values to the right of 0 indicate a positive association; values to the left indicate a negative association. Confidence intervals that cross 0 indicate that the data are still compatible with no association at the chosen confidence level.</p>
</section>
<section id="step-1-create-and-fit-a-synthetic-regression-model" class="level2" data-number="69.2">
<h2 data-number="69.2" class="anchored" data-anchor-id="step-1-create-and-fit-a-synthetic-regression-model"><span class="header-section-number">69.2</span> Step 1: Create and fit a synthetic regression model</h2>
<p>We will start with a synthetic logistic regression for 30-day hospital readmission. The purpose is not to make a substantive claim. It is to create a realistic model object from which we can build a polished coefficient plot.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>n_patients <span class="ot">&lt;-</span> <span class="dv">800</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>synthetic_readmission <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">age10 =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="fl">6.8</span>, <span class="at">sd =</span> <span class="fl">1.1</span>),</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">prior_admissions =</span> <span class="fu">rpois</span>(n_patients, <span class="at">lambda =</span> <span class="fl">1.3</span>),</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">comorbidity_score =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>),</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">social_risk =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>),</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">intervention =</span> <span class="fu">rbinom</span>(n_patients, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.5</span>)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>linear_predictor <span class="ot">&lt;-</span> <span class="fu">with</span>(</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  synthetic_readmission,</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="sc">-</span><span class="fl">1.2</span> <span class="sc">+</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.22</span> <span class="sc">*</span> age10 <span class="sc">+</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.28</span> <span class="sc">*</span> prior_admissions <span class="sc">+</span></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.40</span> <span class="sc">*</span> comorbidity_score <span class="sc">+</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.31</span> <span class="sc">*</span> social_risk <span class="sc">-</span></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.45</span> <span class="sc">*</span> intervention</span>
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
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>extract_glm_coefficients <span class="ot">&lt;-</span> <span class="cf">function</span>(model, labels) {</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  model_summary <span class="ot">&lt;-</span> <span class="fu">summary</span>(model)</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>  out <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>    <span class="at">term =</span> <span class="fu">rownames</span>(model_summary<span class="sc">$</span>coefficients),</span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> model_summary<span class="sc">$</span>coefficients[, <span class="dv">1</span>],</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>    <span class="at">std_error =</span> model_summary<span class="sc">$</span>coefficients[, <span class="dv">2</span>],</span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>    <span class="at">row.names =</span> <span class="cn">NULL</span></span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">filter</span>(term <span class="sc">!=</span> <span class="st">"(Intercept)"</span>) <span class="sc">|&gt;</span></span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>      <span class="at">conf_low =</span> estimate <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> std_error,</span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>      <span class="at">conf_high =</span> estimate <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> std_error,</span>
<span id="cb1-52"><a href="#cb1-52" aria-hidden="true" tabindex="-1"></a>      <span class="at">term_label =</span> labels[term],</span>
<span id="cb1-53"><a href="#cb1-53" aria-hidden="true" tabindex="-1"></a>      <span class="at">odds_ratio =</span> <span class="fu">exp</span>(estimate),</span>
<span id="cb1-54"><a href="#cb1-54" aria-hidden="true" tabindex="-1"></a>      <span class="at">or_low =</span> <span class="fu">exp</span>(conf_low),</span>
<span id="cb1-55"><a href="#cb1-55" aria-hidden="true" tabindex="-1"></a>      <span class="at">or_high =</span> <span class="fu">exp</span>(conf_high)</span>
<span id="cb1-56"><a href="#cb1-56" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-57"><a href="#cb1-57" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-58"><a href="#cb1-58" aria-hidden="true" tabindex="-1"></a>  out</span>
<span id="cb1-59"><a href="#cb1-59" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-60"><a href="#cb1-60" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-61"><a href="#cb1-61" aria-hidden="true" tabindex="-1"></a>synthetic_labels <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb1-62"><a href="#cb1-62" aria-hidden="true" tabindex="-1"></a>  <span class="at">intervention =</span> <span class="st">"Discharge intervention"</span>,</span>
<span id="cb1-63"><a href="#cb1-63" aria-hidden="true" tabindex="-1"></a>  <span class="at">age10 =</span> <span class="st">"Age (per 10 years)"</span>,</span>
<span id="cb1-64"><a href="#cb1-64" aria-hidden="true" tabindex="-1"></a>  <span class="at">prior_admissions =</span> <span class="st">"Prior admissions"</span>,</span>
<span id="cb1-65"><a href="#cb1-65" aria-hidden="true" tabindex="-1"></a>  <span class="at">comorbidity_score =</span> <span class="st">"Comorbidity score"</span>,</span>
<span id="cb1-66"><a href="#cb1-66" aria-hidden="true" tabindex="-1"></a>  <span class="at">social_risk =</span> <span class="st">"Social risk index"</span></span>
<span id="cb1-67"><a href="#cb1-67" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-68"><a href="#cb1-68" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-69"><a href="#cb1-69" aria-hidden="true" tabindex="-1"></a>synthetic_coef <span class="ot">&lt;-</span> <span class="fu">extract_glm_coefficients</span>(synthetic_logit, synthetic_labels)</span>
<span id="cb1-70"><a href="#cb1-70" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-71"><a href="#cb1-71" aria-hidden="true" tabindex="-1"></a>synthetic_table <span class="ot">&lt;-</span> synthetic_coef <span class="sc">|&gt;</span></span>
<span id="cb1-72"><a href="#cb1-72" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">transmute</span>(</span>
<span id="cb1-73"><a href="#cb1-73" aria-hidden="true" tabindex="-1"></a>    <span class="at">predictor =</span> term_label,</span>
<span id="cb1-74"><a href="#cb1-74" aria-hidden="true" tabindex="-1"></a>    <span class="at">log_odds_coefficient =</span> <span class="fu">round</span>(estimate, <span class="dv">3</span>),</span>
<span id="cb1-75"><a href="#cb1-75" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower_95_ci =</span> <span class="fu">round</span>(conf_low, <span class="dv">3</span>),</span>
<span id="cb1-76"><a href="#cb1-76" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper_95_ci =</span> <span class="fu">round</span>(conf_high, <span class="dv">3</span>),</span>
<span id="cb1-77"><a href="#cb1-77" aria-hidden="true" tabindex="-1"></a>    <span class="at">odds_ratio =</span> <span class="fu">round</span>(odds_ratio, <span class="dv">2</span>)</span>
<span id="cb1-78"><a href="#cb1-78" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-79"><a href="#cb1-79" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-80"><a href="#cb1-80" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-81"><a href="#cb1-81" aria-hidden="true" tabindex="-1"></a>  synthetic_table,</span>
<span id="cb1-82"><a href="#cb1-82" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Synthetic logistic regression estimates used in the coefficient plot"</span></span>
<span id="cb1-83"><a href="#cb1-83" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Synthetic logistic regression estimates used in the coefficient plot</caption>
<colgroup>
<col style="width: 29%">
<col style="width: 26%">
<col style="width: 15%">
<col style="width: 15%">
<col style="width: 13%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">predictor</th>
<th style="text-align: right;">log_odds_coefficient</th>
<th style="text-align: right;">lower_95_ci</th>
<th style="text-align: right;">upper_95_ci</th>
<th style="text-align: right;">odds_ratio</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Discharge intervention</td>
<td style="text-align: right;">-0.439</td>
<td style="text-align: right;">-0.733</td>
<td style="text-align: right;">-0.145</td>
<td style="text-align: right;">0.64</td>
</tr>
<tr class="even">
<td style="text-align: left;">Age (per 10 years)</td>
<td style="text-align: right;">0.351</td>
<td style="text-align: right;">0.212</td>
<td style="text-align: right;">0.490</td>
<td style="text-align: right;">1.42</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Prior admissions</td>
<td style="text-align: right;">0.339</td>
<td style="text-align: right;">0.204</td>
<td style="text-align: right;">0.473</td>
<td style="text-align: right;">1.40</td>
</tr>
<tr class="even">
<td style="text-align: left;">Comorbidity score</td>
<td style="text-align: right;">0.242</td>
<td style="text-align: right;">0.087</td>
<td style="text-align: right;">0.397</td>
<td style="text-align: right;">1.27</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Social risk index</td>
<td style="text-align: right;">0.176</td>
<td style="text-align: right;">0.027</td>
<td style="text-align: right;">0.325</td>
<td style="text-align: right;">1.19</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table is exactly the type of result that often appears in appendices. The coefficient plot will present the same information more directly.</p>
</section>
<section id="step-2-build-a-reusable-coefficient-plot-function" class="level2" data-number="69.3">
<h2 data-number="69.3" class="anchored" data-anchor-id="step-2-build-a-reusable-coefficient-plot-function"><span class="header-section-number">69.3</span> Step 2: Build a reusable coefficient-plot function</h2>
<p>The function below creates a coefficient plot on the original coefficient scale. It uses a vertical line at 0, horizontal intervals, and colored points that distinguish positive from negative associations.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>build_coefficient_plot <span class="ot">&lt;-</span> <span class="cf">function</span>(data, title, subtitle, x_label) {</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  plot_data <span class="ot">&lt;-</span> data <span class="sc">|&gt;</span></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>      <span class="at">term_label =</span> <span class="fu">factor</span>(term_label, <span class="at">levels =</span> <span class="fu">rev</span>(term_label)),</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>      <span class="at">direction =</span> <span class="fu">ifelse</span>(estimate <span class="sc">&gt;=</span> <span class="dv">0</span>, <span class="st">"Positive"</span>, <span class="st">"Negative"</span>),</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>      <span class="at">label_text =</span> <span class="fu">sprintf</span>(<span class="st">"%.2f (%.2f to %.2f)"</span>, estimate, conf_low, conf_high)</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  label_position <span class="ot">&lt;-</span> <span class="fu">max</span>(plot_data<span class="sc">$</span>conf_high) <span class="sc">+</span> <span class="fl">0.15</span> <span class="sc">*</span> <span class="fu">diff</span>(<span class="fu">range</span>(<span class="fu">c</span>(plot_data<span class="sc">$</span>conf_low, plot_data<span class="sc">$</span>conf_high)))</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>(plot_data, <span class="fu">aes</span>(<span class="at">x =</span> estimate, <span class="at">y =</span> term_label, <span class="at">color =</span> direction)) <span class="sc">+</span></span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="dv">0</span>, <span class="at">color =</span> <span class="st">"#7f7f7f"</span>, <span class="at">linetype =</span> <span class="st">"dashed"</span>, <span class="at">linewidth =</span> <span class="fl">0.6</span>) <span class="sc">+</span></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> conf_low, <span class="at">xend =</span> conf_high, <span class="at">yend =</span> term_label),</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.9</span>,</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>      <span class="at">show.legend =</span> <span class="cn">FALSE</span></span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_point</span>(<span class="at">size =</span> <span class="fl">3.2</span>, <span class="at">show.legend =</span> <span class="cn">FALSE</span>) <span class="sc">+</span></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> label_position, <span class="at">label =</span> label_text),</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>      <span class="at">hjust =</span> <span class="dv">0</span>,</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#1f1f1f"</span>,</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.5</span></span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_color_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"Negative"</span> <span class="ot">=</span> <span class="st">"#2b8cbe"</span>, <span class="st">"Positive"</span> <span class="ot">=</span> <span class="st">"#8c2d04"</span>)) <span class="sc">+</span></span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coord_cartesian</span>(</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>      <span class="at">xlim =</span> <span class="fu">c</span>(</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>        <span class="fu">min</span>(plot_data<span class="sc">$</span>conf_low) <span class="sc">-</span> <span class="fl">0.15</span> <span class="sc">*</span> <span class="fu">diff</span>(<span class="fu">range</span>(<span class="fu">c</span>(plot_data<span class="sc">$</span>conf_low, plot_data<span class="sc">$</span>conf_high))),</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>        label_position <span class="sc">+</span> <span class="fl">0.35</span></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>      ),</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>      <span class="at">clip =</span> <span class="st">"off"</span></span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle,</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> x_label,</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> <span class="cn">NULL</span></span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.major.y =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.margin =</span> <span class="fu">margin</span>(<span class="dv">10</span>, <span class="dv">110</span>, <span class="dv">10</span>, <span class="dv">10</span>)</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<p>The design is deliberately minimal. The figure needs only a few components to work well:</p>
<ul>
<li>a null line,</li>
<li>point estimates,</li>
<li>confidence intervals,</li>
<li>readable term labels,</li>
<li>numerical annotations when desired.</li>
</ul>
<p>The moment extra decoration becomes dominant, the plot stops doing its job.</p>
</section>
<section id="step-3-draw-the-synthetic-coefficient-plot" class="level2" data-number="69.4">
<h2 data-number="69.4" class="anchored" data-anchor-id="step-3-draw-the-synthetic-coefficient-plot"><span class="header-section-number">69.4</span> Step 3: Draw the synthetic coefficient plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>synthetic_coefficient_plot <span class="ot">&lt;-</span> <span class="fu">build_coefficient_plot</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  synthetic_coef,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Coefficient plot for a synthetic readmission model"</span>,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Points show logistic regression coefficients; bars show 95% confidence intervals"</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">x_label =</span> <span class="st">"Log-odds coefficient"</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>synthetic_coefficient_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/coefficient-plots_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure can be read much faster than the regression table. The discharge intervention is clearly protective because its coefficient is negative and its interval stays below 0. Age, prior admissions, comorbidity, and social risk all move in the opposite direction.</p>
</section>
<section id="step-4-create-a-real-world-coefficient-plot-from-a-public-clinical-trial-dataset" class="level2" data-number="69.5">
<h2 data-number="69.5" class="anchored" data-anchor-id="step-4-create-a-real-world-coefficient-plot-from-a-public-clinical-trial-dataset"><span class="header-section-number">69.5</span> Step 4: Create a real-world coefficient plot from a public clinical trial dataset</h2>
<p>For a real-world example, we can use the public <code>colon</code> dataset from the <code>survival</code> package. These data come from adjuvant colon cancer trials reported by Laurie and colleagues and Moertel and colleagues <span class="citation" data-cites="laurie1989">Laurie et al. (<a href="#ref-laurie1989" role="doc-biblioref">1989</a>)</span>; <span class="citation" data-cites="moertel1990">Moertel et al. (<a href="#ref-moertel1990" role="doc-biblioref">1990</a>)</span>. We will fit a multivariable Cox proportional hazards model for overall survival and then visualize the adjusted log hazard ratios with a coefficient plot.</p>
<p>This is a transparent partial replication. The original trial papers were not published with exactly this plot, and the covariate specification below is a modern teaching adaptation rather than a reconstruction of the original printed model table.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(survival)</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>colon_os <span class="ot">&lt;-</span> survival<span class="sc">::</span>colon <span class="sc">|&gt;</span></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">filter</span>(etype <span class="sc">==</span> <span class="dv">2</span>, rx <span class="sc">%in%</span> <span class="fu">c</span>(<span class="st">"Obs"</span>, <span class="st">"Lev+5FU"</span>)) <span class="sc">|&gt;</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">treatment =</span> <span class="fu">ifelse</span>(rx <span class="sc">==</span> <span class="st">"Lev+5FU"</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">age10 =</span> age <span class="sc">/</span> <span class="dv">10</span>,</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">male =</span> <span class="fu">ifelse</span>(sex <span class="sc">==</span> <span class="dv">1</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">nodes4 =</span> <span class="fu">ifelse</span>(nodes <span class="sc">&gt;</span> <span class="dv">4</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">obstruction =</span> <span class="fu">ifelse</span>(obstruct <span class="sc">==</span> <span class="dv">1</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">adherence =</span> <span class="fu">ifelse</span>(adhere <span class="sc">==</span> <span class="dv">1</span>, <span class="dv">1</span>, <span class="dv">0</span>)</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>colon_cox <span class="ot">&lt;-</span> survival<span class="sc">::</span><span class="fu">coxph</span>(</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>  survival<span class="sc">::</span><span class="fu">Surv</span>(time, status) <span class="sc">~</span> treatment <span class="sc">+</span> age10 <span class="sc">+</span> male <span class="sc">+</span> nodes4 <span class="sc">+</span> obstruction <span class="sc">+</span> adherence,</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> colon_os</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>extract_cox_coefficients <span class="ot">&lt;-</span> <span class="cf">function</span>(model, labels) {</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>  model_summary <span class="ot">&lt;-</span> <span class="fu">summary</span>(model)</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>  out <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">term =</span> <span class="fu">rownames</span>(model_summary<span class="sc">$</span>coefficients),</span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> model_summary<span class="sc">$</span>coefficients[, <span class="st">"coef"</span>],</span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">std_error =</span> model_summary<span class="sc">$</span>coefficients[, <span class="st">"se(coef)"</span>],</span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">row.names =</span> <span class="cn">NULL</span></span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>      <span class="at">conf_low =</span> estimate <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> std_error,</span>
<span id="cb4-30"><a href="#cb4-30" aria-hidden="true" tabindex="-1"></a>      <span class="at">conf_high =</span> estimate <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> std_error,</span>
<span id="cb4-31"><a href="#cb4-31" aria-hidden="true" tabindex="-1"></a>      <span class="at">term_label =</span> labels[term],</span>
<span id="cb4-32"><a href="#cb4-32" aria-hidden="true" tabindex="-1"></a>      <span class="at">hazard_ratio =</span> <span class="fu">exp</span>(estimate),</span>
<span id="cb4-33"><a href="#cb4-33" aria-hidden="true" tabindex="-1"></a>      <span class="at">hr_low =</span> <span class="fu">exp</span>(conf_low),</span>
<span id="cb4-34"><a href="#cb4-34" aria-hidden="true" tabindex="-1"></a>      <span class="at">hr_high =</span> <span class="fu">exp</span>(conf_high)</span>
<span id="cb4-35"><a href="#cb4-35" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb4-36"><a href="#cb4-36" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-37"><a href="#cb4-37" aria-hidden="true" tabindex="-1"></a>  out</span>
<span id="cb4-38"><a href="#cb4-38" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb4-39"><a href="#cb4-39" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-40"><a href="#cb4-40" aria-hidden="true" tabindex="-1"></a>colon_labels <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb4-41"><a href="#cb4-41" aria-hidden="true" tabindex="-1"></a>  <span class="at">treatment =</span> <span class="st">"Levamisole + 5FU treatment"</span>,</span>
<span id="cb4-42"><a href="#cb4-42" aria-hidden="true" tabindex="-1"></a>  <span class="at">age10 =</span> <span class="st">"Age (per 10 years)"</span>,</span>
<span id="cb4-43"><a href="#cb4-43" aria-hidden="true" tabindex="-1"></a>  <span class="at">male =</span> <span class="st">"Male sex"</span>,</span>
<span id="cb4-44"><a href="#cb4-44" aria-hidden="true" tabindex="-1"></a>  <span class="at">nodes4 =</span> <span class="st">"More than 4 positive nodes"</span>,</span>
<span id="cb4-45"><a href="#cb4-45" aria-hidden="true" tabindex="-1"></a>  <span class="at">obstruction =</span> <span class="st">"Obstruction present"</span>,</span>
<span id="cb4-46"><a href="#cb4-46" aria-hidden="true" tabindex="-1"></a>  <span class="at">adherence =</span> <span class="st">"Adherent to protocol"</span></span>
<span id="cb4-47"><a href="#cb4-47" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-48"><a href="#cb4-48" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-49"><a href="#cb4-49" aria-hidden="true" tabindex="-1"></a>colon_coef <span class="ot">&lt;-</span> <span class="fu">extract_cox_coefficients</span>(colon_cox, colon_labels)</span>
<span id="cb4-50"><a href="#cb4-50" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-51"><a href="#cb4-51" aria-hidden="true" tabindex="-1"></a>colon_table <span class="ot">&lt;-</span> colon_coef <span class="sc">|&gt;</span></span>
<span id="cb4-52"><a href="#cb4-52" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">transmute</span>(</span>
<span id="cb4-53"><a href="#cb4-53" aria-hidden="true" tabindex="-1"></a>    <span class="at">predictor =</span> term_label,</span>
<span id="cb4-54"><a href="#cb4-54" aria-hidden="true" tabindex="-1"></a>    <span class="at">log_hazard_ratio =</span> <span class="fu">round</span>(estimate, <span class="dv">3</span>),</span>
<span id="cb4-55"><a href="#cb4-55" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower_95_ci =</span> <span class="fu">round</span>(conf_low, <span class="dv">3</span>),</span>
<span id="cb4-56"><a href="#cb4-56" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper_95_ci =</span> <span class="fu">round</span>(conf_high, <span class="dv">3</span>),</span>
<span id="cb4-57"><a href="#cb4-57" aria-hidden="true" tabindex="-1"></a>    <span class="at">hazard_ratio =</span> <span class="fu">round</span>(hazard_ratio, <span class="dv">2</span>)</span>
<span id="cb4-58"><a href="#cb4-58" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-59"><a href="#cb4-59" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-60"><a href="#cb4-60" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-61"><a href="#cb4-61" aria-hidden="true" tabindex="-1"></a>  colon_table,</span>
<span id="cb4-62"><a href="#cb4-62" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Adjusted Cox model estimates from the public colon cancer trial data"</span></span>
<span id="cb4-63"><a href="#cb4-63" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Adjusted Cox model estimates from the public colon cancer trial data</caption>
<colgroup>
<col style="width: 33%">
<col style="width: 20%">
<col style="width: 14%">
<col style="width: 14%">
<col style="width: 16%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">predictor</th>
<th style="text-align: right;">log_hazard_ratio</th>
<th style="text-align: right;">lower_95_ci</th>
<th style="text-align: right;">upper_95_ci</th>
<th style="text-align: right;">hazard_ratio</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Levamisole + 5FU treatment</td>
<td style="text-align: right;">-0.388</td>
<td style="text-align: right;">-0.625</td>
<td style="text-align: right;">-0.151</td>
<td style="text-align: right;">0.68</td>
</tr>
<tr class="even">
<td style="text-align: left;">Age (per 10 years)</td>
<td style="text-align: right;">0.023</td>
<td style="text-align: right;">-0.074</td>
<td style="text-align: right;">0.121</td>
<td style="text-align: right;">1.02</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Male sex</td>
<td style="text-align: right;">-0.114</td>
<td style="text-align: right;">-0.347</td>
<td style="text-align: right;">0.119</td>
<td style="text-align: right;">0.89</td>
</tr>
<tr class="even">
<td style="text-align: left;">More than 4 positive nodes</td>
<td style="text-align: right;">0.962</td>
<td style="text-align: right;">0.718</td>
<td style="text-align: right;">1.205</td>
<td style="text-align: right;">2.62</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Obstruction present</td>
<td style="text-align: right;">0.153</td>
<td style="text-align: right;">-0.139</td>
<td style="text-align: right;">0.446</td>
<td style="text-align: right;">1.17</td>
</tr>
<tr class="even">
<td style="text-align: left;">Adherent to protocol</td>
<td style="text-align: right;">0.289</td>
<td style="text-align: right;">-0.023</td>
<td style="text-align: right;">0.601</td>
<td style="text-align: right;">1.34</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The coefficient table is now built from a real fitted model. The plot uses exactly the same visual grammar as the synthetic example, but the estimates come from an applied clinical dataset.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>colon_coefficient_plot <span class="ot">&lt;-</span> <span class="fu">build_coefficient_plot</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  colon_coef,</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Coefficient plot for an adjusted Cox model in the colon trial data"</span>,</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Points show log hazard ratios; bars show 95% confidence intervals"</span>,</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">x_label =</span> <span class="st">"Log hazard ratio"</span></span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>colon_coefficient_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/coefficient-plots_files/figure-html/unnamed-chunk-5-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure highlights the strongest associations immediately. The treatment term is clearly protective, with a negative adjusted log hazard ratio. Having more than 4 positive nodes is strongly associated with worse survival. Other terms, such as age or obstruction, are more uncertain in this particular specification.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="69.6">
<h2 data-number="69.6" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">69.6</span> How to read the figure carefully</h2>
<p>A coefficient plot is a summary of model output, not a substitute for modeling judgment. The plotted intervals reflect sampling uncertainty conditional on the fitted model. They do not tell the reader whether the model specification is correct, whether confounding has been handled adequately, or whether the effect scale is the most relevant one.</p>
<p>The figure is also easiest to interpret when the coefficient scale is meaningful. For logistic and Cox models, many readers ultimately think in odds ratios or hazard ratios, even if the plot is drawn on the log scale. That is why it is often helpful to include numerical labels or a companion table.</p>
<p>Finally, coefficient plots are most useful when they are selective. If a model has dozens of fixed effects, interactions, and transformed terms, plotting everything can make the figure unreadable. In those cases, the analyst should decide which parameters are substantively important enough to show.</p>
</section>
<section id="further-reading" class="level2" data-number="69.7">
<h2 data-number="69.7" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">69.7</span> Further reading</h2>
<p>Kastellec and Leoni provide a clear argument for replacing dense regression tables with figures that foreground estimates and uncertainty <span class="citation" data-cites="kastellec2007graphs">Kastellec and Leoni (<a href="#ref-kastellec2007graphs" role="doc-biblioref">2007</a>)</span>. The colon cancer trial papers by Laurie and colleagues and Moertel and colleagues provide a real clinical setting in which multivariable treatment-effect reporting is useful <span class="citation" data-cites="laurie1989">Laurie et al. (<a href="#ref-laurie1989" role="doc-biblioref">1989</a>)</span>; <span class="citation" data-cites="moertel1990">Moertel et al. (<a href="#ref-moertel1990" role="doc-biblioref">1990</a>)</span>.</p>


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
