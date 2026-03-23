---
title: "Calibration Belt Plot"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a calibration belt plot for a binary risk-prediction model. The purpose of the figure is to show not only whether predicted probabilities line up with observed outcomes, but also where along the..."
---
<p>This chapter creates a calibration belt plot for a binary risk-prediction model. The purpose of the figure is to show not only whether predicted probabilities line up with observed outcomes, but also where along the risk range the model appears to be miscalibrated. A standard calibration plot often combines grouped observed-versus-predicted points with a smooth curve. A calibration belt goes one step further by placing a confidence band around the estimated calibration curve so the reader can see where the ideal 45-degree line falls inside or outside the plausible range of calibration functions <span class="citation" data-cites="finazzi2011">Finazzi et al. (<a href="#ref-finazzi2011" role="doc-biblioref">2011</a>)</span>; <span class="citation" data-cites="nattino2014">Nattino, Finazzi, and Bertolini (<a href="#ref-nattino2014" role="doc-biblioref">2014</a>)</span>.</p>
<p>This makes the figure especially useful in applied health research. A prediction model may be well calibrated on average yet still overpredict high-risk patients or underpredict low-risk patients. A single intercept or slope cannot show where that happens. A calibration belt can.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="65.1">
<h2 data-number="65.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">65.1</span> What the visualization is showing</h2>
<p>We will build a calibration belt plot for predicted probabilities from a binary-outcome model. The figure will show:</p>
<ol type="1">
<li>the ideal 45-degree line,</li>
<li>an estimated smooth calibration curve,</li>
<li>nested confidence belts around that curve,</li>
<li>optionally, grouped calibration points for reference.</li>
</ol>
<p>When the calibration curve lies on the 45-degree line, the model is perfectly calibrated. When the belt excludes the 45-degree line over a range of predicted probabilities, that part of the risk range is where calibration problems are most evident.</p>
</section>
<section id="step-1-create-a-synthetic-external-validation-setting" class="level2" data-number="65.2">
<h2 data-number="65.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-external-validation-setting"><span class="header-section-number">65.2</span> Step 1: Create a synthetic external-validation setting</h2>
<p>To make the purpose of the figure clear, we will start with a synthetic example in which a logistic model is fit in a development sample and then applied to a shifted validation sample. The validation data are generated from a slightly different risk structure, so some miscalibration should appear.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>n_dev <span class="ot">&lt;-</span> <span class="dv">2500</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>n_val <span class="ot">&lt;-</span> <span class="dv">2500</span></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>generate_risk_data <span class="ot">&lt;-</span> <span class="cf">function</span>(n, <span class="at">intercept_shift =</span> <span class="dv">0</span>) {</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>  age10 <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="fl">6.5</span>, <span class="at">sd =</span> <span class="fl">1.0</span>)</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  biomarker <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>)</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  comorbidity <span class="ot">&lt;-</span> <span class="fu">rpois</span>(n, <span class="at">lambda =</span> <span class="fl">1.5</span>)</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  smoker <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(n, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.3</span>)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>  true_eta <span class="ot">&lt;-</span> <span class="sc">-</span><span class="fl">1.2</span> <span class="sc">+</span> intercept_shift <span class="sc">+</span></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.35</span> <span class="sc">*</span> age10 <span class="sc">+</span></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.75</span> <span class="sc">*</span> biomarker <span class="sc">+</span></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.18</span> <span class="sc">*</span> comorbidity <span class="sc">+</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.40</span> <span class="sc">*</span> smoker <span class="sc">+</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.35</span> <span class="sc">*</span> biomarker <span class="sc">*</span> smoker <span class="sc">-</span></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.25</span> <span class="sc">*</span> biomarker<span class="sc">^</span><span class="dv">2</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  event <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(n, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fu">plogis</span>(true_eta))</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>    age10,</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>    biomarker,</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>    comorbidity,</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>    smoker,</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>    event</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>development_data <span class="ot">&lt;-</span> <span class="fu">generate_risk_data</span>(n_dev, <span class="at">intercept_shift =</span> <span class="dv">0</span>)</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>validation_data <span class="ot">&lt;-</span> <span class="fu">generate_risk_data</span>(n_val, <span class="at">intercept_shift =</span> <span class="fl">0.25</span>)</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>calibration_fit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  event <span class="sc">~</span> age10 <span class="sc">+</span> biomarker <span class="sc">+</span> comorbidity <span class="sc">+</span> smoker,</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> development_data,</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>validation_data<span class="sc">$</span>predicted_risk <span class="ot">&lt;-</span> <span class="fu">predict</span>(</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>  calibration_fit,</span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>  <span class="at">newdata =</span> validation_data,</span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>  <span class="at">type =</span> <span class="st">"response"</span></span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>  <span class="at">development_n =</span> <span class="fu">nrow</span>(development_data),</span>
<span id="cb1-52"><a href="#cb1-52" aria-hidden="true" tabindex="-1"></a>  <span class="at">validation_n =</span> <span class="fu">nrow</span>(validation_data),</span>
<span id="cb1-53"><a href="#cb1-53" aria-hidden="true" tabindex="-1"></a>  <span class="at">validation_event_rate =</span> <span class="fu">mean</span>(validation_data<span class="sc">$</span>event),</span>
<span id="cb1-54"><a href="#cb1-54" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_predicted_risk =</span> <span class="fu">mean</span>(validation_data<span class="sc">$</span>predicted_risk),</span>
<span id="cb1-55"><a href="#cb1-55" aria-hidden="true" tabindex="-1"></a>  <span class="at">brier_score =</span> <span class="fu">mean</span>((validation_data<span class="sc">$</span>predicted_risk <span class="sc">-</span> validation_data<span class="sc">$</span>event)<span class="sc">^</span><span class="dv">2</span>)</span>
<span id="cb1-56"><a href="#cb1-56" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-57"><a href="#cb1-57" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-58"><a href="#cb1-58" aria-hidden="true" tabindex="-1"></a>synthetic_summary[, <span class="fu">c</span>(<span class="st">"validation_event_rate"</span>, <span class="st">"mean_predicted_risk"</span>, <span class="st">"brier_score"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-59"><a href="#cb1-59" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(synthetic_summary[, <span class="fu">c</span>(<span class="st">"validation_event_rate"</span>, <span class="st">"mean_predicted_risk"</span>, <span class="st">"brier_score"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-60"><a href="#cb1-60" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-61"><a href="#cb1-61" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-62"><a href="#cb1-62" aria-hidden="true" tabindex="-1"></a>  synthetic_summary,</span>
<span id="cb1-63"><a href="#cb1-63" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the synthetic development and validation samples"</span></span>
<span id="cb1-64"><a href="#cb1-64" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the synthetic development and validation samples</caption>
<colgroup>
<col style="width: 17%">
<col style="width: 16%">
<col style="width: 27%">
<col style="width: 24%">
<col style="width: 14%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: right;">development_n</th>
<th style="text-align: right;">validation_n</th>
<th style="text-align: right;">validation_event_rate</th>
<th style="text-align: right;">mean_predicted_risk</th>
<th style="text-align: right;">brier_score</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">2500</td>
<td style="text-align: right;">2500</td>
<td style="text-align: right;">0.768</td>
<td style="text-align: right;">0.738</td>
<td style="text-align: right;">0.151</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The development model is intentionally misspecified because it omits the interaction and nonlinear term used in the true data-generating process. The validation sample also has a shifted intercept, which introduces additional miscalibration.</p>
</section>
<section id="step-2-build-a-calibration-belt-function" class="level2" data-number="65.3">
<h2 data-number="65.3" class="anchored" data-anchor-id="step-2-build-a-calibration-belt-function"><span class="header-section-number">65.3</span> Step 2: Build a calibration-belt function</h2>
<p>The calibration belt models the relationship between the logit of predicted probability and the logit of observed outcome probability with a polynomial logistic regression. The code below uses AIC to choose the polynomial degree from 1 to 3, then computes fitted calibration probabilities and nested confidence belts across a grid of predicted risks.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>build_calibration_belt <span class="ot">&lt;-</span> <span class="cf">function</span>(predicted_risk, observed_outcome, <span class="at">max_degree =</span> <span class="dv">3</span>) {</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  clipped_risk <span class="ot">&lt;-</span> <span class="fu">pmin</span>(<span class="fu">pmax</span>(predicted_risk, <span class="fl">1e-6</span>), <span class="dv">1</span> <span class="sc">-</span> <span class="fl">1e-6</span>)</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  logit_risk <span class="ot">&lt;-</span> <span class="fu">qlogis</span>(clipped_risk)</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  fits <span class="ot">&lt;-</span> <span class="fu">lapply</span>(<span class="fu">seq_len</span>(max_degree), <span class="cf">function</span>(degree) {</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>    <span class="fu">glm</span>(</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>      observed_outcome <span class="sc">~</span> <span class="fu">poly</span>(logit_risk, <span class="at">degree =</span> degree, <span class="at">raw =</span> <span class="cn">TRUE</span>),</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>      <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  aic_values <span class="ot">&lt;-</span> <span class="fu">sapply</span>(fits, AIC)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>  best_degree <span class="ot">&lt;-</span> <span class="fu">which.min</span>(aic_values)</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  best_fit <span class="ot">&lt;-</span> fits[[best_degree]]</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  grid <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">predicted_risk =</span> <span class="fu">seq</span>(<span class="fu">min</span>(clipped_risk), <span class="fu">max</span>(clipped_risk), <span class="at">length.out =</span> <span class="dv">250</span>)</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>  grid<span class="sc">$</span>logit_risk <span class="ot">&lt;-</span> <span class="fu">qlogis</span>(grid<span class="sc">$</span>predicted_risk)</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  predicted_link <span class="ot">&lt;-</span> <span class="fu">predict</span>(best_fit, <span class="at">newdata =</span> grid, <span class="at">type =</span> <span class="st">"link"</span>, <span class="at">se.fit =</span> <span class="cn">TRUE</span>)</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>  eta_hat <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(predicted_link<span class="sc">$</span>fit)</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>  eta_se <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(predicted_link<span class="sc">$</span>se.fit)</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  z80 <span class="ot">&lt;-</span> <span class="fu">qnorm</span>(<span class="fl">0.90</span>)</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>  z95 <span class="ot">&lt;-</span> <span class="fu">qnorm</span>(<span class="fl">0.975</span>)</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>  grid<span class="sc">$</span>calibrated_risk <span class="ot">&lt;-</span> <span class="fu">plogis</span>(eta_hat)</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>  grid<span class="sc">$</span>lower80 <span class="ot">&lt;-</span> <span class="fu">plogis</span>(eta_hat <span class="sc">-</span> z80 <span class="sc">*</span> eta_se)</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  grid<span class="sc">$</span>upper80 <span class="ot">&lt;-</span> <span class="fu">plogis</span>(eta_hat <span class="sc">+</span> z80 <span class="sc">*</span> eta_se)</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>  grid<span class="sc">$</span>lower95 <span class="ot">&lt;-</span> <span class="fu">plogis</span>(eta_hat <span class="sc">-</span> z95 <span class="sc">*</span> eta_se)</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  grid<span class="sc">$</span>upper95 <span class="ot">&lt;-</span> <span class="fu">plogis</span>(eta_hat <span class="sc">+</span> z95 <span class="sc">*</span> eta_se)</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>  grid<span class="sc">$</span>ideal <span class="ot">&lt;-</span> grid<span class="sc">$</span>predicted_risk</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>  rank_id <span class="ot">&lt;-</span> <span class="fu">rank</span>(clipped_risk, <span class="at">ties.method =</span> <span class="st">"first"</span>)</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  decile_breaks <span class="ot">&lt;-</span> <span class="fu">quantile</span>(rank_id, <span class="at">probs =</span> <span class="fu">seq</span>(<span class="dv">0</span>, <span class="dv">1</span>, <span class="fl">0.1</span>))</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>  decile_breaks <span class="ot">&lt;-</span> <span class="fu">unique</span>(decile_breaks)</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>  decile <span class="ot">&lt;-</span> <span class="fu">cut</span>(</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>    rank_id,</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>    <span class="at">breaks =</span> decile_breaks,</span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>    <span class="at">include.lowest =</span> <span class="cn">TRUE</span></span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>  grouped <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a>    <span class="at">decile =</span> decile,</span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a>    <span class="at">predicted_risk =</span> clipped_risk,</span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>    <span class="at">observed_outcome =</span> observed_outcome</span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb2-50"><a href="#cb2-50" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">group_by</span>(decile) <span class="sc">|&gt;</span></span>
<span id="cb2-51"><a href="#cb2-51" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">summarise</span>(</span>
<span id="cb2-52"><a href="#cb2-52" aria-hidden="true" tabindex="-1"></a>      <span class="at">predicted_risk =</span> <span class="fu">mean</span>(predicted_risk),</span>
<span id="cb2-53"><a href="#cb2-53" aria-hidden="true" tabindex="-1"></a>      <span class="at">observed_outcome =</span> <span class="fu">mean</span>(observed_outcome),</span>
<span id="cb2-54"><a href="#cb2-54" aria-hidden="true" tabindex="-1"></a>      <span class="at">count =</span> dplyr<span class="sc">::</span><span class="fu">n</span>(),</span>
<span id="cb2-55"><a href="#cb2-55" aria-hidden="true" tabindex="-1"></a>      <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb2-56"><a href="#cb2-56" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-57"><a href="#cb2-57" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-58"><a href="#cb2-58" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(</span>
<span id="cb2-59"><a href="#cb2-59" aria-hidden="true" tabindex="-1"></a>    <span class="at">fit =</span> best_fit,</span>
<span id="cb2-60"><a href="#cb2-60" aria-hidden="true" tabindex="-1"></a>    <span class="at">degree =</span> best_degree,</span>
<span id="cb2-61"><a href="#cb2-61" aria-hidden="true" tabindex="-1"></a>    <span class="at">aic_values =</span> aic_values,</span>
<span id="cb2-62"><a href="#cb2-62" aria-hidden="true" tabindex="-1"></a>    <span class="at">grid =</span> grid,</span>
<span id="cb2-63"><a href="#cb2-63" aria-hidden="true" tabindex="-1"></a>    <span class="at">grouped =</span> grouped</span>
<span id="cb2-64"><a href="#cb2-64" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-65"><a href="#cb2-65" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<p>This is a simplified pedagogic implementation rather than a full reproduction of the formal calibration-belt testing algorithm in the original papers. But it captures the main visual logic: an estimated calibration curve plus nested confidence belts that can be compared with the ideal line.</p>
</section>
<section id="step-3-draw-the-synthetic-calibration-belt-plot" class="level2" data-number="65.4">
<h2 data-number="65.4" class="anchored" data-anchor-id="step-3-draw-the-synthetic-calibration-belt-plot"><span class="header-section-number">65.4</span> Step 3: Draw the synthetic calibration belt plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>synthetic_belt <span class="ot">&lt;-</span> <span class="fu">build_calibration_belt</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">predicted_risk =</span> validation_data<span class="sc">$</span>predicted_risk,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">observed_outcome =</span> validation_data<span class="sc">$</span>event</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>synthetic_belt_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">selected_polynomial_degree =</span> synthetic_belt<span class="sc">$</span>degree,</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">aic_degree_1 =</span> synthetic_belt<span class="sc">$</span>aic_values[<span class="dv">1</span>],</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">aic_degree_2 =</span> synthetic_belt<span class="sc">$</span>aic_values[<span class="dv">2</span>],</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">aic_degree_3 =</span> synthetic_belt<span class="sc">$</span>aic_values[<span class="dv">3</span>]</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>synthetic_belt_table[,] <span class="ot">&lt;-</span> <span class="fu">round</span>(synthetic_belt_table, <span class="dv">3</span>)</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  synthetic_belt_table,</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Polynomial degree selection for the synthetic calibration belt"</span></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Polynomial degree selection for the synthetic calibration belt</caption>
<thead>
<tr class="header">
<th style="text-align: right;">selected_polynomial_degree</th>
<th style="text-align: right;">aic_degree_1</th>
<th style="text-align: right;">aic_degree_2</th>
<th style="text-align: right;">aic_degree_3</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">2</td>
<td style="text-align: right;">2347.565</td>
<td style="text-align: right;">2323.227</td>
<td style="text-align: right;">2324.408</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>() <span class="sc">+</span></span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_ribbon</span>(</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> synthetic_belt<span class="sc">$</span>grid,</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">ymin =</span> lower95, <span class="at">ymax =</span> upper95),</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"#cfe1f2"</span>,</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.8</span></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_ribbon</span>(</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> synthetic_belt<span class="sc">$</span>grid,</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">ymin =</span> lower80, <span class="at">ymax =</span> upper80),</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"#7fb3d5"</span>,</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.75</span></span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_abline</span>(</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">intercept =</span> <span class="dv">0</span>,</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">slope =</span> <span class="dv">1</span>,</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#8b5e34"</span>,</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.8</span></span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> synthetic_belt<span class="sc">$</span>grid,</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">y =</span> calibrated_risk),</span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#1f4e79"</span>,</span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="dv">1</span></span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_point</span>(</span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> synthetic_belt<span class="sc">$</span>grouped,</span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">y =</span> observed_outcome, <span class="at">size =</span> count),</span>
<span id="cb4-30"><a href="#cb4-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#2a9d8f"</span>,</span>
<span id="cb4-31"><a href="#cb4-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.8</span></span>
<span id="cb4-32"><a href="#cb4-32" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-33"><a href="#cb4-33" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb4-34"><a href="#cb4-34" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Calibration belt plot for a synthetic external-validation sample"</span>,</span>
<span id="cb4-35"><a href="#cb4-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"The inner and outer shaded regions show 80% and 95% calibration belts"</span>,</span>
<span id="cb4-36"><a href="#cb4-36" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Predicted probability"</span>,</span>
<span id="cb4-37"><a href="#cb4-37" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Observed event probability"</span>,</span>
<span id="cb4-38"><a href="#cb4-38" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="st">"Bin size"</span></span>
<span id="cb4-39"><a href="#cb4-39" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-40"><a href="#cb4-40" aria-hidden="true" tabindex="-1"></a>  <span class="fu">coord_cartesian</span>(<span class="at">xlim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>), <span class="at">ylim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb4-41"><a href="#cb4-41" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/calibration-belt-plot_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure can be read in a way that grouped calibration points alone cannot. The curve shows the estimated calibration relationship, while the belt makes uncertainty visible across the whole probability range. Where the ideal line falls well outside the belt, miscalibration is most evident.</p>
</section>
<section id="step-4-create-a-real-world-calibration-belt-from-a-public-clinical-prediction-dataset" class="level2" data-number="65.5">
<h2 data-number="65.5" class="anchored" data-anchor-id="step-4-create-a-real-world-calibration-belt-from-a-public-clinical-prediction-dataset"><span class="header-section-number">65.5</span> Step 4: Create a real-world calibration belt from a public clinical prediction dataset</h2>
<p>For a real-world example, we can use the public <code>Pima.tr</code> and <code>Pima.te</code> datasets distributed with <code>MASS</code>. These data come from the diabetes-prediction application described by Smith and coauthors <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>. The model below is fit in the training sample and evaluated in the test sample, which gives a natural external-validation setting for a calibration belt.</p>
<p>This is a transparent partial application. The original Smith paper did not publish a calibration belt, and the calibration-belt methodology itself was proposed much later by Finazzi and colleagues and further refined by Nattino and colleagues <span class="citation" data-cites="finazzi2011">Finazzi et al. (<a href="#ref-finazzi2011" role="doc-biblioref">2011</a>)</span>; <span class="citation" data-cites="nattino2014">Nattino, Finazzi, and Bertolini (<a href="#ref-nattino2014" role="doc-biblioref">2014</a>)</span>. The figure below therefore combines a public clinical dataset with the later calibration-belt methodology rather than reproducing a single published plot verbatim.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.tr"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.te"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>pima_fit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  type <span class="sc">~</span> npreg <span class="sc">+</span> glu <span class="sc">+</span> bp <span class="sc">+</span> skin <span class="sc">+</span> bmi <span class="sc">+</span> ped <span class="sc">+</span> age,</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> Pima.tr,</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>pima_predicted <span class="ot">&lt;-</span> <span class="fu">predict</span>(pima_fit, <span class="at">newdata =</span> Pima.te, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>pima_observed <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(Pima.te<span class="sc">$</span>type <span class="sc">==</span> <span class="st">"Yes"</span>)</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>pima_belt <span class="ot">&lt;-</span> <span class="fu">build_calibration_belt</span>(</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">predicted_risk =</span> pima_predicted,</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">observed_outcome =</span> pima_observed</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>pima_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">length</span>(pima_observed),</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">event_rate =</span> <span class="fu">mean</span>(pima_observed),</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_predicted_risk =</span> <span class="fu">mean</span>(pima_predicted),</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">brier_score =</span> <span class="fu">mean</span>((pima_predicted <span class="sc">-</span> pima_observed)<span class="sc">^</span><span class="dv">2</span>),</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">selected_polynomial_degree =</span> pima_belt<span class="sc">$</span>degree</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>pima_summary[, <span class="fu">c</span>(<span class="st">"event_rate"</span>, <span class="st">"mean_predicted_risk"</span>, <span class="st">"brier_score"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(pima_summary[, <span class="fu">c</span>(<span class="st">"event_rate"</span>, <span class="st">"mean_predicted_risk"</span>, <span class="st">"brier_score"</span>)], <span class="dv">3</span>)</span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-30"><a href="#cb5-30" aria-hidden="true" tabindex="-1"></a>  pima_summary,</span>
<span id="cb5-31"><a href="#cb5-31" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the public diabetes prediction sample used for the calibration belt"</span></span>
<span id="cb5-32"><a href="#cb5-32" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the public diabetes prediction sample used for the calibration belt</caption>
<colgroup>
<col style="width: 14%">
<col style="width: 13%">
<col style="width: 24%">
<col style="width: 14%">
<col style="width: 32%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">event_rate</th>
<th style="text-align: right;">mean_predicted_risk</th>
<th style="text-align: right;">brier_score</th>
<th style="text-align: right;">selected_polynomial_degree</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">332</td>
<td style="text-align: right;">0.328</td>
<td style="text-align: right;">0.337</td>
<td style="text-align: right;">0.139</td>
<td style="text-align: right;">2</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>() <span class="sc">+</span></span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_ribbon</span>(</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> pima_belt<span class="sc">$</span>grid,</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">ymin =</span> lower95, <span class="at">ymax =</span> upper95),</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"#e6eef5"</span>,</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.85</span></span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_ribbon</span>(</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> pima_belt<span class="sc">$</span>grid,</span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">ymin =</span> lower80, <span class="at">ymax =</span> upper80),</span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"#9ecae1"</span>,</span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.8</span></span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-14"><a href="#cb6-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_abline</span>(</span>
<span id="cb6-15"><a href="#cb6-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">intercept =</span> <span class="dv">0</span>,</span>
<span id="cb6-16"><a href="#cb6-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">slope =</span> <span class="dv">1</span>,</span>
<span id="cb6-17"><a href="#cb6-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb6-18"><a href="#cb6-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#8b5e34"</span>,</span>
<span id="cb6-19"><a href="#cb6-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.8</span></span>
<span id="cb6-20"><a href="#cb6-20" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-21"><a href="#cb6-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(</span>
<span id="cb6-22"><a href="#cb6-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> pima_belt<span class="sc">$</span>grid,</span>
<span id="cb6-23"><a href="#cb6-23" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">y =</span> calibrated_risk),</span>
<span id="cb6-24"><a href="#cb6-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#264653"</span>,</span>
<span id="cb6-25"><a href="#cb6-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="dv">1</span></span>
<span id="cb6-26"><a href="#cb6-26" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-27"><a href="#cb6-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_point</span>(</span>
<span id="cb6-28"><a href="#cb6-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> pima_belt<span class="sc">$</span>grouped,</span>
<span id="cb6-29"><a href="#cb6-29" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">y =</span> observed_outcome, <span class="at">size =</span> count),</span>
<span id="cb6-30"><a href="#cb6-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#2a9d8f"</span>,</span>
<span id="cb6-31"><a href="#cb6-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.8</span></span>
<span id="cb6-32"><a href="#cb6-32" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-33"><a href="#cb6-33" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb6-34"><a href="#cb6-34" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Calibration belt plot for diabetes risk predictions"</span>,</span>
<span id="cb6-35"><a href="#cb6-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Public Pima test data with nested 80% and 95% calibration belts"</span>,</span>
<span id="cb6-36"><a href="#cb6-36" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Predicted probability"</span>,</span>
<span id="cb6-37"><a href="#cb6-37" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Observed event probability"</span>,</span>
<span id="cb6-38"><a href="#cb6-38" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="st">"Bin size"</span></span>
<span id="cb6-39"><a href="#cb6-39" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-40"><a href="#cb6-40" aria-hidden="true" tabindex="-1"></a>  <span class="fu">coord_cartesian</span>(<span class="at">xlim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>), <span class="at">ylim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb6-41"><a href="#cb6-41" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/calibration-belt-plot_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This real-world example highlights the added value of the belt. The grouped points are still useful, but the belt clarifies whether apparent deviations from perfect calibration are large relative to sampling uncertainty and where in the risk range those deviations are concentrated.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="65.6">
<h2 data-number="65.6" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">65.6</span> How to read the figure carefully</h2>
<p>A calibration belt should not be read as a mechanical pass-fail device. The width of the belt depends on sample size and information density across the risk range. Belts naturally widen in sparse high-risk or low-risk regions, which means the same apparent deviation from the ideal line can be more consequential in one part of the graph than another.</p>
<p>The figure is also sensitive to how the calibration curve is modeled. The original methodology uses a polynomial relation on the logit scale and a formal testing framework to choose its complexity. The simplified implementation in this chapter uses AIC-based degree selection for teaching and reproducibility. That is useful pedagogically, but it is not a drop-in replacement for every formal calibration-belt procedure used in applied validation studies.</p>
<p>Finally, a calibration belt complements rather than replaces other calibration summaries. Intercept, slope, Brier score, and decision-relevant performance still matter.</p>
</section>
<section id="further-reading" class="level2" data-number="65.7">
<h2 data-number="65.7" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">65.7</span> Further reading</h2>
<p>Finazzi and colleagues introduced the calibration belt as a confidence-band approach to calibration assessment for dichotomous outcomes <span class="citation" data-cites="finazzi2011">Finazzi et al. (<a href="#ref-finazzi2011" role="doc-biblioref">2011</a>)</span>. Nattino and colleagues refined the associated testing framework and clarified the role of polynomial degree selection <span class="citation" data-cites="nattino2014">Nattino, Finazzi, and Bertolini (<a href="#ref-nattino2014" role="doc-biblioref">2014</a>)</span>. Van Calster and colleagues provide a broader modern discussion of why calibration deserves more attention in prediction research <span class="citation" data-cites="vancalster2019">Van Calster et al. (<a href="#ref-vancalster2019" role="doc-biblioref">2019</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-finazzi2011" class="csl-entry" role="listitem">
Finazzi, Stefano, Daniele Poole, Davide Luciani, Paola E. Cogo, and Guido Bertolini. 2011. <span>"Calibration Belt for Quality-of-Care Assessment Based on Dichotomous Outcomes."</span> <em>PLOS ONE</em> 6 (2): e16110. <a href="https://doi.org/10.1371/journal.pone.0016110">https://doi.org/10.1371/journal.pone.0016110</a>.
</div>
<div id="ref-nattino2014" class="csl-entry" role="listitem">
Nattino, Giovanni, Stefano Finazzi, and Guido Bertolini. 2014. <span>"A New Calibration Test and a Reappraisal of the Calibration Belt for the Assessment of Prediction Models Based on Dichotomous Outcomes."</span> <em>Statistics in Medicine</em> 33 (14): 2390-2407. <a href="https://doi.org/10.1002/sim.6100">https://doi.org/10.1002/sim.6100</a>.
</div>
<div id="ref-smith1988" class="csl-entry" role="listitem">
Smith, J. W., J. E. Everhart, W. C. Dickson, W. C. Knowler, and R. S. Johannes. 1988. <span>"Using the <span>ADAP</span> Learning Algorithm to Forecast the Onset of Diabetes Mellitus."</span> In <em>Proceedings of the Symposium on Computer Applications in Medical Care</em>, 261-65.
</div>
<div id="ref-vancalster2019" class="csl-entry" role="listitem">
Van Calster, Ben, David J. McLernon, Maarten van Smeden, Laure Wynants, and Ewout W. Steyerberg. 2019. <span>"Calibration: The Achilles Heel of Predictive Analytics."</span> <em>BMC Medicine</em> 17 (1): 230. <a href="https://doi.org/10.1186/s12916-019-1466-7">https://doi.org/10.1186/s12916-019-1466-7</a>.
</div>
</div>
</section>
