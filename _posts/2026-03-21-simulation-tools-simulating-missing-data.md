---
title: "Simulating Missing Data"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset with a known complete-data linear model and then introduces missingness under three different mechanisms: missing completely at random, missing at random, and missing not at..."
---
<p>This chapter creates a synthetic dataset with a known complete-data linear model and then introduces missingness under three different mechanisms: missing completely at random, missing at random, and missing not at random. The aim is to show that missing data are not just blank cells in a spreadsheet. They are part of the data-generating process and can change what happens when the true model is fitted to incomplete data. The framework follows Rubin's foundational distinction between MCAR, MAR, and MNAR mechanisms <span class="citation" data-cites="rubin1976">Rubin (<a href="#ref-rubin1976" role="doc-biblioref">1976</a>)</span>.</p>
<p>The practical motivation is immediate. Health economics and health services datasets routinely lose information because patients skip questionnaires, providers omit measurements, or administrative systems capture some variables more reliably than others. A simulation is one of the clearest ways to see why the mechanism of missingness matters.</p>
<section id="what-variables-will-be-created" class="level2" data-number="56.1">
<h2 data-number="56.1" class="anchored" data-anchor-id="what-variables-will-be-created"><span class="header-section-number">56.1</span> What variables will be created</h2>
<p>The complete synthetic sample will contain <code>age</code>, <code>severity</code>, <code>program</code>, and <code>annual_cost</code>. <code>annual_cost</code> will be the continuous outcome generated from a linear regression model. The missing-data mechanisms will then affect the predictor <code>severity</code>, creating three incomplete versions of the same dataset: <code>severity_mcar</code>, <code>severity_mar</code>, and <code>severity_mnar</code>.</p>
<p>These versions allow us to fit the same regression repeatedly and see how the estimates change when the missingness mechanism changes.</p>
</section>
<section id="the-complete-data-generating-process" class="level2" data-number="56.2">
<h2 data-number="56.2" class="anchored" data-anchor-id="the-complete-data-generating-process"><span class="header-section-number">56.2</span> The complete-data generating process</h2>
<p>The full data follow a linear model:</p>
<p><span class="math display">\[
\text{annual\_cost}_i =
\beta_0 +
\beta_1 \text{age}_i +
\beta_2 \text{severity}_i +
\beta_3 \text{program}_i +
\varepsilon_i,
\]</span></p>
<p>where</p>
<p><span class="math display">\[
\beta_0 = 1800,\;
\beta_1 = 22,\;
\beta_2 = 420,\;
\beta_3 = -350,
\]</span></p>
<p>and</p>
<p><span class="math display">\[
\varepsilon_i \sim N(0, 700^2).
\]</span></p>
<p>Missingness is then applied to <code>severity</code> in three different ways:</p>
<p><span class="math display">\[
R_i^{MCAR} \sim \text{Bernoulli}(0.75),
\]</span></p>
<p>so the observation is kept with constant probability.</p>
<p>For MAR, the missingness depends on observed variables:</p>
<p><span class="math display">\[
\Pr(R_i^{MAR} = 1) =
\text{logit}^{-1}(1.6 - 0.02(\text{age}_i - 60) + 0.55 \text{program}_i - 0.00035 \text{annual\_cost}_i).
\]</span></p>
<p>For MNAR, the missingness depends directly on the unobserved value of <code>severity</code>:</p>
<p><span class="math display">\[
\Pr(R_i^{MNAR} = 1) =
\text{logit}^{-1}(1.2 - 0.9 \text{severity}_i).
\]</span></p>
</section>
<section id="step-1-generate-the-complete-dataset" class="level2" data-number="56.3">
<h2 data-number="56.3" class="anchored" data-anchor-id="step-1-generate-the-complete-dataset"><span class="header-section-number">56.3</span> Step 1: Generate the complete dataset</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n <span class="ot">&lt;-</span> <span class="dv">5000</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>age <span class="ot">&lt;-</span> <span class="fu">pmax</span>(<span class="fu">round</span>(<span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">61</span>, <span class="at">sd =</span> <span class="dv">12</span>)), <span class="dv">25</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>severity <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>program <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(n, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.48</span>)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>error_term <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">700</span>)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>annual_cost <span class="ot">&lt;-</span> <span class="dv">1800</span> <span class="sc">+</span></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>  <span class="dv">22</span> <span class="sc">*</span> age <span class="sc">+</span></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  <span class="dv">420</span> <span class="sc">*</span> severity <span class="sc">-</span></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="dv">350</span> <span class="sc">*</span> program <span class="sc">+</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  error_term</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>complete_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>  age,</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  severity,</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  program,</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  annual_cost</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>complete_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(complete_data),</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_age =</span> <span class="fu">mean</span>(complete_data<span class="sc">$</span>age),</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_severity =</span> <span class="fu">mean</span>(complete_data<span class="sc">$</span>severity),</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">program_rate =</span> <span class="fu">mean</span>(complete_data<span class="sc">$</span>program),</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_cost =</span> <span class="fu">mean</span>(complete_data<span class="sc">$</span>annual_cost)</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>complete_summary[, <span class="fu">c</span>(<span class="st">"mean_age"</span>, <span class="st">"mean_severity"</span>, <span class="st">"program_rate"</span>, <span class="st">"mean_cost"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(complete_summary[, <span class="fu">c</span>(<span class="st">"mean_age"</span>, <span class="st">"mean_severity"</span>, <span class="st">"program_rate"</span>, <span class="st">"mean_cost"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>  complete_summary,</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the complete synthetic dataset before missingness is introduced"</span></span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the complete synthetic dataset before missingness is introduced</caption>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">mean_age</th>
<th style="text-align: right;">mean_severity</th>
<th style="text-align: right;">program_rate</th>
<th style="text-align: right;">mean_cost</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">5000</td>
<td style="text-align: right;">60.904</td>
<td style="text-align: right;">0.015</td>
<td style="text-align: right;">0.483</td>
<td style="text-align: right;">2990.998</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-2-impose-three-missing-data-mechanisms" class="level2" data-number="56.4">
<h2 data-number="56.4" class="anchored" data-anchor-id="step-2-impose-three-missing-data-mechanisms"><span class="header-section-number">56.4</span> Step 2: Impose three missing-data mechanisms</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>keep_mcar <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(n, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.75</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>keep_mar <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  n,</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">size =</span> <span class="dv">1</span>,</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">prob =</span> <span class="fu">plogis</span>(<span class="fl">1.6</span> <span class="sc">-</span> <span class="fl">0.02</span> <span class="sc">*</span> (age <span class="sc">-</span> <span class="dv">60</span>) <span class="sc">+</span> <span class="fl">0.55</span> <span class="sc">*</span> program <span class="sc">-</span> <span class="fl">0.00035</span> <span class="sc">*</span> annual_cost)</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>keep_mnar <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  n,</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">size =</span> <span class="dv">1</span>,</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">prob =</span> <span class="fu">plogis</span>(<span class="fl">1.2</span> <span class="sc">-</span> <span class="fl">0.9</span> <span class="sc">*</span> severity)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>data_mcar <span class="ot">&lt;-</span> complete_data</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>data_mar <span class="ot">&lt;-</span> complete_data</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>data_mnar <span class="ot">&lt;-</span> complete_data</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>data_mcar<span class="sc">$</span>severity[keep_mcar <span class="sc">==</span> <span class="dv">0</span>] <span class="ot">&lt;-</span> <span class="cn">NA</span></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>data_mar<span class="sc">$</span>severity[keep_mar <span class="sc">==</span> <span class="dv">0</span>] <span class="ot">&lt;-</span> <span class="cn">NA</span></span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>data_mnar<span class="sc">$</span>severity[keep_mnar <span class="sc">==</span> <span class="dv">0</span>] <span class="ot">&lt;-</span> <span class="cn">NA</span></span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>missingness_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">mechanism =</span> <span class="fu">c</span>(<span class="st">"MCAR"</span>, <span class="st">"MAR"</span>, <span class="st">"MNAR"</span>),</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">missing_rate =</span> <span class="fu">c</span>(</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(<span class="fu">is.na</span>(data_mcar<span class="sc">$</span>severity)),</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(<span class="fu">is.na</span>(data_mar<span class="sc">$</span>severity)),</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(<span class="fu">is.na</span>(data_mnar<span class="sc">$</span>severity))</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>missingness_summary<span class="sc">$</span>missing_rate <span class="ot">&lt;-</span> <span class="fu">round</span>(missingness_summary<span class="sc">$</span>missing_rate, <span class="dv">3</span>)</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>  missingness_summary,</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Missingness rates under the three simulated mechanisms"</span></span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Missingness rates under the three simulated mechanisms</caption>
<thead>
<tr class="header">
<th style="text-align: left;">mechanism</th>
<th style="text-align: right;">missing_rate</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">MCAR</td>
<td style="text-align: right;">0.256</td>
</tr>
<tr class="even">
<td style="text-align: left;">MAR</td>
<td style="text-align: right;">0.330</td>
</tr>
<tr class="odd">
<td style="text-align: left;">MNAR</td>
<td style="text-align: right;">0.274</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The data all started from the same complete sample. The only difference across the three versions is how the missingness was generated.</p>
</section>
<section id="step-3-fit-the-true-regression-model-before-and-after-missingness" class="level2" data-number="56.5">
<h2 data-number="56.5" class="anchored" data-anchor-id="step-3-fit-the-true-regression-model-before-and-after-missingness"><span class="header-section-number">56.5</span> Step 3: Fit the true regression model before and after missingness</h2>
<p>Now fit the same linear model to the complete data and to the complete cases under each missing-data mechanism.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>fit_complete <span class="ot">&lt;-</span> <span class="fu">lm</span>(annual_cost <span class="sc">~</span> age <span class="sc">+</span> severity <span class="sc">+</span> program, <span class="at">data =</span> complete_data)</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>fit_mcar <span class="ot">&lt;-</span> <span class="fu">lm</span>(annual_cost <span class="sc">~</span> age <span class="sc">+</span> severity <span class="sc">+</span> program, <span class="at">data =</span> data_mcar)</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>fit_mar <span class="ot">&lt;-</span> <span class="fu">lm</span>(annual_cost <span class="sc">~</span> age <span class="sc">+</span> severity <span class="sc">+</span> program, <span class="at">data =</span> data_mar)</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>fit_mnar <span class="ot">&lt;-</span> <span class="fu">lm</span>(annual_cost <span class="sc">~</span> age <span class="sc">+</span> severity <span class="sc">+</span> program, <span class="at">data =</span> data_mnar)</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>true_coefficients <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="st">"(Intercept)"</span> <span class="ot">=</span> <span class="dv">1800</span>,</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">age =</span> <span class="dv">22</span>,</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">severity =</span> <span class="dv">420</span>,</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">program =</span> <span class="sc">-</span><span class="dv">350</span></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>coefficient_table <span class="ot">&lt;-</span> <span class="fu">rbind</span>(</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">mechanism =</span> <span class="st">"Complete data"</span>,</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">term =</span> <span class="fu">names</span>(<span class="fu">coef</span>(fit_complete)),</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> <span class="fu">coef</span>(fit_complete)</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">mechanism =</span> <span class="st">"MCAR complete case"</span>,</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">term =</span> <span class="fu">names</span>(<span class="fu">coef</span>(fit_mcar)),</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> <span class="fu">coef</span>(fit_mcar)</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">mechanism =</span> <span class="st">"MAR complete case"</span>,</span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">term =</span> <span class="fu">names</span>(<span class="fu">coef</span>(fit_mar)),</span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> <span class="fu">coef</span>(fit_mar)</span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-29"><a href="#cb3-29" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb3-30"><a href="#cb3-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">mechanism =</span> <span class="st">"MNAR complete case"</span>,</span>
<span id="cb3-31"><a href="#cb3-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">term =</span> <span class="fu">names</span>(<span class="fu">coef</span>(fit_mnar)),</span>
<span id="cb3-32"><a href="#cb3-32" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> <span class="fu">coef</span>(fit_mnar)</span>
<span id="cb3-33"><a href="#cb3-33" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb3-34"><a href="#cb3-34" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-35"><a href="#cb3-35" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-36"><a href="#cb3-36" aria-hidden="true" tabindex="-1"></a>coefficient_table<span class="sc">$</span>true_value <span class="ot">&lt;-</span> true_coefficients[coefficient_table<span class="sc">$</span>term]</span>
<span id="cb3-37"><a href="#cb3-37" aria-hidden="true" tabindex="-1"></a>coefficient_table<span class="sc">$</span>bias <span class="ot">&lt;-</span> coefficient_table<span class="sc">$</span>estimate <span class="sc">-</span> coefficient_table<span class="sc">$</span>true_value</span>
<span id="cb3-38"><a href="#cb3-38" aria-hidden="true" tabindex="-1"></a>coefficient_table[, <span class="fu">c</span>(<span class="st">"estimate"</span>, <span class="st">"true_value"</span>, <span class="st">"bias"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb3-39"><a href="#cb3-39" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(coefficient_table[, <span class="fu">c</span>(<span class="st">"estimate"</span>, <span class="st">"true_value"</span>, <span class="st">"bias"</span>)], <span class="dv">2</span>)</span>
<span id="cb3-40"><a href="#cb3-40" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-41"><a href="#cb3-41" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-42"><a href="#cb3-42" aria-hidden="true" tabindex="-1"></a>  coefficient_table,</span>
<span id="cb3-43"><a href="#cb3-43" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Regression estimates under complete data and three missing-data mechanisms"</span></span>
<span id="cb3-44"><a href="#cb3-44" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Regression estimates under complete data and three missing-data mechanisms</caption>
<colgroup>
<col style="width: 18%">
<col style="width: 26%">
<col style="width: 16%">
<col style="width: 12%">
<col style="width: 15%">
<col style="width: 9%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">mechanism</th>
<th style="text-align: left;">term</th>
<th style="text-align: right;">estimate</th>
<th style="text-align: right;">true_value</th>
<th style="text-align: right;">bias</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: left;">Complete data</td>
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: right;">1866.32</td>
<td style="text-align: right;">1800</td>
<td style="text-align: right;">66.32</td>
</tr>
<tr class="even">
<td style="text-align: left;">age</td>
<td style="text-align: left;">Complete data</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">20.94</td>
<td style="text-align: right;">22</td>
<td style="text-align: right;">-1.06</td>
</tr>
<tr class="odd">
<td style="text-align: left;">severity</td>
<td style="text-align: left;">Complete data</td>
<td style="text-align: left;">severity</td>
<td style="text-align: right;">431.30</td>
<td style="text-align: right;">420</td>
<td style="text-align: right;">11.30</td>
</tr>
<tr class="even">
<td style="text-align: left;">program</td>
<td style="text-align: left;">Complete data</td>
<td style="text-align: left;">program</td>
<td style="text-align: right;">-325.83</td>
<td style="text-align: right;">-350</td>
<td style="text-align: right;">24.17</td>
</tr>
<tr class="odd">
<td style="text-align: left;">(Intercept)1</td>
<td style="text-align: left;">MCAR complete case</td>
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: right;">1916.63</td>
<td style="text-align: right;">1800</td>
<td style="text-align: right;">116.63</td>
</tr>
<tr class="even">
<td style="text-align: left;">age1</td>
<td style="text-align: left;">MCAR complete case</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">20.35</td>
<td style="text-align: right;">22</td>
<td style="text-align: right;">-1.65</td>
</tr>
<tr class="odd">
<td style="text-align: left;">severity1</td>
<td style="text-align: left;">MCAR complete case</td>
<td style="text-align: left;">severity</td>
<td style="text-align: right;">423.71</td>
<td style="text-align: right;">420</td>
<td style="text-align: right;">3.71</td>
</tr>
<tr class="even">
<td style="text-align: left;">program1</td>
<td style="text-align: left;">MCAR complete case</td>
<td style="text-align: left;">program</td>
<td style="text-align: right;">-325.32</td>
<td style="text-align: right;">-350</td>
<td style="text-align: right;">24.68</td>
</tr>
<tr class="odd">
<td style="text-align: left;">(Intercept)2</td>
<td style="text-align: left;">MAR complete case</td>
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: right;">1805.21</td>
<td style="text-align: right;">1800</td>
<td style="text-align: right;">5.21</td>
</tr>
<tr class="even">
<td style="text-align: left;">age2</td>
<td style="text-align: left;">MAR complete case</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">21.15</td>
<td style="text-align: right;">22</td>
<td style="text-align: right;">-0.85</td>
</tr>
<tr class="odd">
<td style="text-align: left;">severity2</td>
<td style="text-align: left;">MAR complete case</td>
<td style="text-align: left;">severity</td>
<td style="text-align: right;">434.94</td>
<td style="text-align: right;">420</td>
<td style="text-align: right;">14.94</td>
</tr>
<tr class="even">
<td style="text-align: left;">program2</td>
<td style="text-align: left;">MAR complete case</td>
<td style="text-align: left;">program</td>
<td style="text-align: right;">-324.53</td>
<td style="text-align: right;">-350</td>
<td style="text-align: right;">25.47</td>
</tr>
<tr class="odd">
<td style="text-align: left;">(Intercept)3</td>
<td style="text-align: left;">MNAR complete case</td>
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: right;">1865.76</td>
<td style="text-align: right;">1800</td>
<td style="text-align: right;">65.76</td>
</tr>
<tr class="even">
<td style="text-align: left;">age3</td>
<td style="text-align: left;">MNAR complete case</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">21.19</td>
<td style="text-align: right;">22</td>
<td style="text-align: right;">-0.81</td>
</tr>
<tr class="odd">
<td style="text-align: left;">severity3</td>
<td style="text-align: left;">MNAR complete case</td>
<td style="text-align: left;">severity</td>
<td style="text-align: right;">440.82</td>
<td style="text-align: right;">420</td>
<td style="text-align: right;">20.82</td>
</tr>
<tr class="even">
<td style="text-align: left;">program3</td>
<td style="text-align: left;">MNAR complete case</td>
<td style="text-align: left;">program</td>
<td style="text-align: right;">-340.94</td>
<td style="text-align: right;">-350</td>
<td style="text-align: right;">9.06</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table is the center of the chapter. It shows what happens when the same substantive model meets different missing-data processes.</p>
</section>
<section id="step-4-visualize-how-the-coefficient-estimates-move" class="level2" data-number="56.6">
<h2 data-number="56.6" class="anchored" data-anchor-id="step-4-visualize-how-the-coefficient-estimates-move"><span class="header-section-number">56.6</span> Step 4: Visualize how the coefficient estimates move</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>plot_table <span class="ot">&lt;-</span> <span class="fu">subset</span>(coefficient_table, term <span class="sc">!=</span> <span class="st">"(Intercept)"</span>)</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  plot_table,</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> term, <span class="at">y =</span> estimate, <span class="at">color =</span> mechanism)</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>) <span class="sc">+</span></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_hline</span>(</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> <span class="fu">unique</span>(plot_table[, <span class="fu">c</span>(<span class="st">"term"</span>, <span class="st">"true_value"</span>)]),</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">yintercept =</span> true_value),</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#8b5e34"</span>,</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.8</span>,</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">inherit.aes =</span> <span class="cn">FALSE</span></span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">position =</span> ggplot2<span class="sc">::</span><span class="fu">position_dodge</span>(<span class="at">width =</span> <span class="fl">0.35</span>),</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="fl">2.4</span></span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Coefficient recovery under different missing-data mechanisms"</span>,</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Dashed lines show the true coefficient values"</span>,</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Coefficient"</span>,</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Estimated value"</span>,</span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"Dataset"</span></span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_color_manual</span>(</span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">values =</span> <span class="fu">c</span>(<span class="st">"#2a9d8f"</span>, <span class="st">"#457b9d"</span>, <span class="st">"#e9c46a"</span>, <span class="st">"#d62828"</span>)</span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/simulating-missing-data_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>In a simulation like this, the full-data model is the benchmark. The incomplete-data models are not being judged against one another in the abstract. They are being judged against the truth.</p>
</section>
<section id="step-5-check-how-missingness-reshapes-the-observed-severity-distribution" class="level2" data-number="56.7">
<h2 data-number="56.7" class="anchored" data-anchor-id="step-5-check-how-missingness-reshapes-the-observed-severity-distribution"><span class="header-section-number">56.7</span> Step 5: Check how missingness reshapes the observed severity distribution</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>severity_distribution <span class="ot">&lt;-</span> <span class="fu">rbind</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">source =</span> <span class="st">"Complete"</span>, <span class="at">severity =</span> complete_data<span class="sc">$</span>severity),</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">source =</span> <span class="st">"MCAR observed"</span>, <span class="at">severity =</span> data_mcar<span class="sc">$</span>severity[<span class="sc">!</span><span class="fu">is.na</span>(data_mcar<span class="sc">$</span>severity)]),</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">source =</span> <span class="st">"MAR observed"</span>, <span class="at">severity =</span> data_mar<span class="sc">$</span>severity[<span class="sc">!</span><span class="fu">is.na</span>(data_mar<span class="sc">$</span>severity)]),</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">source =</span> <span class="st">"MNAR observed"</span>, <span class="at">severity =</span> data_mnar<span class="sc">$</span>severity[<span class="sc">!</span><span class="fu">is.na</span>(data_mnar<span class="sc">$</span>severity)])</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(severity_distribution, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> severity, <span class="at">color =</span> source)) <span class="sc">+</span></span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_density</span>(<span class="at">linewidth =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Observed severity distributions after different missing-data mechanisms"</span>,</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"MNAR missingness distorts the observed covariate distribution most strongly"</span>,</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Severity"</span>,</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Density"</span>,</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"Dataset"</span></span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_color_manual</span>(</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">values =</span> <span class="fu">c</span>(<span class="st">"#264653"</span>, <span class="st">"#2a9d8f"</span>, <span class="st">"#e9c46a"</span>, <span class="st">"#d62828"</span>)</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/simulating-missing-data_files/figure-html/unnamed-chunk-5-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure helps explain why missing-data mechanisms matter. They do not just remove observations. They can reshape the observed sample itself.</p>
</section>
<section id="main-assumptions-behind-this-simulation" class="level2" data-number="56.8">
<h2 data-number="56.8" class="anchored" data-anchor-id="main-assumptions-behind-this-simulation"><span class="header-section-number">56.8</span> Main assumptions behind this simulation</h2>
<p>The complete-data model is linear with homoskedastic Gaussian noise. The chapter also treats the missingness mechanism as known because it is simulated. That is very different from real applied work, where the mechanism usually has to be argued for rather than observed directly.</p>
<p>The complete-case analysis used here is deliberately simple. It is not presented as a recommended final solution. It is included because it gives a clean way to see how different missing-data mechanisms can change the estimates even when the substantive regression model itself is unchanged.</p>
</section>
<section id="further-reading" class="level2" data-number="56.9">
<h2 data-number="56.9" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">56.9</span> Further reading</h2>
<p>Rubin's paper remains the standard conceptual starting point for understanding why the mechanism of missingness matters for inference <span class="citation" data-cites="rubin1976">Rubin (<a href="#ref-rubin1976" role="doc-biblioref">1976</a>)</span>. It is still the cleanest bridge between practical missing-data problems and the statistical logic needed to think about them rigorously.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-rubin1976" class="csl-entry" role="listitem">
Rubin, Donald B. 1976. <span>"Inference and Missing Data."</span> <em>Biometrika</em> 63 (3): 581-92. <a href="https://doi.org/10.1093/biomet/63.3.581">https://doi.org/10.1093/biomet/63.3.581</a>.
</div>
</div>
</section>
