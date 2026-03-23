---
title: "Simulating Poisson Data"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which the outcome is the number of outpatient doctor visits observed over a follow-up period. The aim is to build a count variable whose true generating process is known in..."
---
<p>This chapter creates a synthetic dataset in which the outcome is the number of outpatient doctor visits observed over a follow-up period. The aim is to build a count variable whose true generating process is known in advance, so that a fitted Poisson regression can be checked against the truth. The design is inspired by the count-data applications discussed by Cameron and Trivedi, where outcomes such as doctor visits, hospital use, or service contacts are modeled as non-negative integers rather than as continuous variables <span class="citation" data-cites="cameron1986">Cameron and Trivedi (<a href="#ref-cameron1986" role="doc-biblioref">1986</a>)</span>.</p>
<p>The practical reason to simulate Poisson data is simple. Count outcomes appear everywhere in health economics and health systems research: number of primary-care visits, emergency department contacts, admissions, prescriptions, missed appointments, or claims. If the underlying mean structure is log-linear, then Poisson regression is the natural first model to test. Simulation makes that structure visible.</p>
<section id="what-variables-will-be-created" class="level2" data-number="53.1">
<h2 data-number="53.1" class="anchored" data-anchor-id="what-variables-will-be-created"><span class="header-section-number">53.1</span> What variables will be created</h2>
<p>The synthetic sample will represent patients followed for outpatient utilization after discharge. <code>age</code> will represent age in years. <code>chronic</code> will count the number of chronic conditions. <code>female</code> will be a binary indicator. <code>poor_health</code> will indicate a high self-reported burden of illness. <code>months_observed</code> will record the amount of follow-up time available for each patient. The outcome <code>doctor_visits</code> will count how many outpatient visits occur during that period.</p>
<p>These variables are chosen because they reproduce the basic ingredients of a count-data application: baseline risk factors, a follow-up window, and an event count whose expected value changes systematically across patients.</p>
</section>
<section id="the-data-generating-process" class="level2" data-number="53.2">
<h2 data-number="53.2" class="anchored" data-anchor-id="the-data-generating-process"><span class="header-section-number">53.2</span> The data-generating process</h2>
<p>The Poisson model assumes that conditional on the covariates, the count outcome follows</p>
<p><span class="math display">\[
Y_i \sim \text{Poisson}(\mu_i),
\]</span></p>
<p>with mean</p>
<p><span class="math display">\[
\mu_i = t_i \exp(\eta_i),
\]</span></p>
<p>where <span class="math inline">\(t_i\)</span> is the exposure time and</p>
<p><span class="math display">\[
\eta_i =
\beta_0 +
\beta_1 \text{age}_i +
\beta_2 \text{chronic}_i +
\beta_3 \text{female}_i +
\beta_4 \text{poor\_health}_i.
\]</span></p>
<p>For this simulation, the true coefficients are set to</p>
<p><span class="math display">\[
\beta_0 = -1.55,\;
\beta_1 = 0.012,\;
\beta_2 = 0.22,\;
\beta_3 = 0.10,\;
\beta_4 = 0.55.
\]</span></p>
<p>The quantity <span class="math inline">\(t_i\)</span> is important. If one patient is observed for 12 months and another for only 6 months, the longer-observed patient has more time to accumulate visits. That is why Poisson models for utilization often include an offset term such as <span class="math inline">\(\log(t_i)\)</span>.</p>
</section>
<section id="step-1-generate-the-synthetic-sample" class="level2" data-number="53.3">
<h2 data-number="53.3" class="anchored" data-anchor-id="step-1-generate-the-synthetic-sample"><span class="header-section-number">53.3</span> Step 1: Generate the synthetic sample</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n <span class="ot">&lt;-</span> <span class="dv">7000</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>age <span class="ot">&lt;-</span> <span class="fu">pmax</span>(<span class="fu">round</span>(<span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">59</span>, <span class="at">sd =</span> <span class="dv">13</span>)), <span class="dv">18</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>chronic <span class="ot">&lt;-</span> <span class="fu">pmin</span>(<span class="fu">rpois</span>(n, <span class="at">lambda =</span> <span class="fl">1.7</span>), <span class="dv">6</span>)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>female <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(n, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.56</span>)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>poor_health <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  n,</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">size =</span> <span class="dv">1</span>,</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">prob =</span> <span class="fu">plogis</span>(<span class="sc">-</span><span class="fl">1.2</span> <span class="sc">+</span> <span class="fl">0.45</span> <span class="sc">*</span> chronic <span class="sc">+</span> <span class="fl">0.015</span> <span class="sc">*</span> (age <span class="sc">-</span> <span class="dv">60</span>))</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>months_observed <span class="ot">&lt;-</span> <span class="fu">sample</span>(<span class="dv">6</span><span class="sc">:</span><span class="dv">12</span>, <span class="at">size =</span> n, <span class="at">replace =</span> <span class="cn">TRUE</span>)</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>eta <span class="ot">&lt;-</span> <span class="sc">-</span><span class="fl">1.55</span> <span class="sc">+</span></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.012</span> <span class="sc">*</span> age <span class="sc">+</span></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.22</span> <span class="sc">*</span> chronic <span class="sc">+</span></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.10</span> <span class="sc">*</span> female <span class="sc">+</span></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.55</span> <span class="sc">*</span> poor_health</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>true_rate <span class="ot">&lt;-</span> <span class="fu">exp</span>(eta)</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>true_mean <span class="ot">&lt;-</span> months_observed <span class="sc">*</span> true_rate</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>doctor_visits <span class="ot">&lt;-</span> <span class="fu">rpois</span>(n, <span class="at">lambda =</span> true_mean)</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>synthetic_visits <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  doctor_visits,</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>  age,</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>  chronic,</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>  female,</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>  poor_health,</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>  months_observed,</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>  true_rate,</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>  true_mean</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>simulation_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(synthetic_visits),</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_visits =</span> <span class="fu">mean</span>(synthetic_visits<span class="sc">$</span>doctor_visits),</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_age =</span> <span class="fu">mean</span>(synthetic_visits<span class="sc">$</span>age),</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_chronic =</span> <span class="fu">mean</span>(synthetic_visits<span class="sc">$</span>chronic),</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_followup_months =</span> <span class="fu">mean</span>(synthetic_visits<span class="sc">$</span>months_observed)</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>simulation_summary[, <span class="fu">c</span>(<span class="st">"mean_visits"</span>, <span class="st">"mean_age"</span>, <span class="st">"mean_chronic"</span>, <span class="st">"mean_followup_months"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(simulation_summary[, <span class="fu">c</span>(<span class="st">"mean_visits"</span>, <span class="st">"mean_age"</span>, <span class="st">"mean_chronic"</span>, <span class="st">"mean_followup_months"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>  simulation_summary,</span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the synthetic Poisson dataset"</span></span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the synthetic Poisson dataset</caption>
<colgroup>
<col style="width: 17%">
<col style="width: 17%">
<col style="width: 13%">
<col style="width: 19%">
<col style="width: 31%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">mean_visits</th>
<th style="text-align: right;">mean_age</th>
<th style="text-align: right;">mean_chronic</th>
<th style="text-align: right;">mean_followup_months</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">7000</td>
<td style="text-align: right;">8.403</td>
<td style="text-align: right;">59.046</td>
<td style="text-align: right;">1.699</td>
<td style="text-align: right;">8.987</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This code builds the covariates first, then transforms them into a conditional mean through the exponential link, and finally draws counts from a Poisson distribution. The model therefore has a deterministic part, <span class="math inline">\(\mu_i\)</span>, and a stochastic part, the Poisson draw around that mean.</p>
</section>
<section id="step-2-fit-the-poisson-model-that-matches-the-truth" class="level2" data-number="53.4">
<h2 data-number="53.4" class="anchored" data-anchor-id="step-2-fit-the-poisson-model-that-matches-the-truth"><span class="header-section-number">53.4</span> Step 2: Fit the Poisson model that matches the truth</h2>
<p>Now fit the same log-linear model used to generate the data:</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>poisson_fit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  doctor_visits <span class="sc">~</span> age <span class="sc">+</span> chronic <span class="sc">+</span> female <span class="sc">+</span> poor_health <span class="sc">+</span> <span class="fu">offset</span>(<span class="fu">log</span>(months_observed)),</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_visits,</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">poisson</span>()</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>truth <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="st">"(Intercept)"</span> <span class="ot">=</span> <span class="sc">-</span><span class="fl">1.55</span>,</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">age =</span> <span class="fl">0.012</span>,</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">chronic =</span> <span class="fl">0.22</span>,</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">female =</span> <span class="fl">0.10</span>,</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">poor_health =</span> <span class="fl">0.55</span></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>comparison_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">term =</span> <span class="fu">names</span>(<span class="fu">coef</span>(poisson_fit)),</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_value =</span> truth[<span class="fu">names</span>(<span class="fu">coef</span>(poisson_fit))],</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_value =</span> <span class="fu">coef</span>(poisson_fit)</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>comparison_table<span class="sc">$</span>bias <span class="ot">&lt;-</span> comparison_table<span class="sc">$</span>estimated_value <span class="sc">-</span> comparison_table<span class="sc">$</span>true_value</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>comparison_table[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>, <span class="st">"bias"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(comparison_table[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>, <span class="st">"bias"</span>)], <span class="dv">3</span>)</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>  comparison_table,</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"True and estimated coefficients under the correctly specified Poisson model"</span></span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>True and estimated coefficients under the correctly specified Poisson model</caption>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">term</th>
<th style="text-align: right;">true_value</th>
<th style="text-align: right;">estimated_value</th>
<th style="text-align: right;">bias</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: right;">-1.550</td>
<td style="text-align: right;">-1.552</td>
<td style="text-align: right;">-0.002</td>
</tr>
<tr class="even">
<td style="text-align: left;">age</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.012</td>
<td style="text-align: right;">0.012</td>
<td style="text-align: right;">0.000</td>
</tr>
<tr class="odd">
<td style="text-align: left;">chronic</td>
<td style="text-align: left;">chronic</td>
<td style="text-align: right;">0.220</td>
<td style="text-align: right;">0.221</td>
<td style="text-align: right;">0.001</td>
</tr>
<tr class="even">
<td style="text-align: left;">female</td>
<td style="text-align: left;">female</td>
<td style="text-align: right;">0.100</td>
<td style="text-align: right;">0.100</td>
<td style="text-align: right;">0.000</td>
</tr>
<tr class="odd">
<td style="text-align: left;">poor_health</td>
<td style="text-align: left;">poor_health</td>
<td style="text-align: right;">0.550</td>
<td style="text-align: right;">0.547</td>
<td style="text-align: right;">-0.003</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>As in the earlier simulation chapters, the key question is whether the fitted model recovers the parameters we used to create the data. Because the model is correctly specified and the sample is fairly large, the answer should be approximately yes.</p>
</section>
<section id="step-3-compare-expected-counts-across-patient-profiles" class="level2" data-number="53.5">
<h2 data-number="53.5" class="anchored" data-anchor-id="step-3-compare-expected-counts-across-patient-profiles"><span class="header-section-number">53.5</span> Step 3: Compare expected counts across patient profiles</h2>
<p>Coefficients on the log scale are useful, but expected counts are easier to interpret. The next block compares the true and fitted mean number of visits for a sequence of chronic-condition counts under two health-status profiles.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>profiles <span class="ot">&lt;-</span> <span class="fu">expand.grid</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">chronic =</span> <span class="dv">0</span><span class="sc">:</span><span class="dv">6</span>,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">poor_health =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>)</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>profiles<span class="sc">$</span>age <span class="ot">&lt;-</span> <span class="dv">60</span></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>profiles<span class="sc">$</span>female <span class="ot">&lt;-</span> <span class="dv">1</span></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>profiles<span class="sc">$</span>months_observed <span class="ot">&lt;-</span> <span class="dv">12</span></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>profiles<span class="sc">$</span>true_mean <span class="ot">&lt;-</span> profiles<span class="sc">$</span>months_observed <span class="sc">*</span> <span class="fu">exp</span>(</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  <span class="sc">-</span><span class="fl">1.55</span> <span class="sc">+</span></span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.012</span> <span class="sc">*</span> profiles<span class="sc">$</span>age <span class="sc">+</span></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.22</span> <span class="sc">*</span> profiles<span class="sc">$</span>chronic <span class="sc">+</span></span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.10</span> <span class="sc">*</span> profiles<span class="sc">$</span>female <span class="sc">+</span></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.55</span> <span class="sc">*</span> profiles<span class="sc">$</span>poor_health</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>profiles<span class="sc">$</span>fitted_mean <span class="ot">&lt;-</span> <span class="fu">predict</span>(poisson_fit, <span class="at">newdata =</span> profiles, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>profiles<span class="sc">$</span>health_status <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(profiles<span class="sc">$</span>poor_health <span class="sc">==</span> <span class="dv">1</span>, <span class="st">"Poor health"</span>, <span class="st">"Better health"</span>)</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>  profiles,</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> chronic, <span class="at">color =</span> health_status)</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>) <span class="sc">+</span></span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(</span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">y =</span> true_mean),</span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">1.1</span></span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-29"><a href="#cb3-29" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(</span>
<span id="cb3-30"><a href="#cb3-30" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">y =</span> fitted_mean),</span>
<span id="cb3-31"><a href="#cb3-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb3-32"><a href="#cb3-32" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.9</span></span>
<span id="cb3-33"><a href="#cb3-33" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-34"><a href="#cb3-34" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb3-35"><a href="#cb3-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"True and fitted mean visit counts in the synthetic Poisson dataset"</span>,</span>
<span id="cb3-36"><a href="#cb3-36" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Solid lines show the generating means; dashed lines show the fitted model"</span>,</span>
<span id="cb3-37"><a href="#cb3-37" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Number of chronic conditions"</span>,</span>
<span id="cb3-38"><a href="#cb3-38" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Expected doctor visits over 12 months"</span>,</span>
<span id="cb3-39"><a href="#cb3-39" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"Profile"</span></span>
<span id="cb3-40"><a href="#cb3-40" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-41"><a href="#cb3-41" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_color_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"#3d5a80"</span>, <span class="st">"#bc6c25"</span>)) <span class="sc">+</span></span>
<span id="cb3-42"><a href="#cb3-42" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/simulating-poisson-data_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>When the dashed lines remain close to the solid lines, the fitted model is reproducing the conditional mean structure correctly. That is exactly what we want in a well-behaved Poisson simulation.</p>
</section>
<section id="step-4-check-the-rate-ratios" class="level2" data-number="53.6">
<h2 data-number="53.6" class="anchored" data-anchor-id="step-4-check-the-rate-ratios"><span class="header-section-number">53.6</span> Step 4: Check the rate ratios</h2>
<p>Poisson regression is often interpreted through rate ratios, which are obtained by exponentiating the coefficients.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>rate_ratio_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">term =</span> comparison_table<span class="sc">$</span>term,</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_rate_ratio =</span> <span class="fu">exp</span>(comparison_table<span class="sc">$</span>true_value),</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_rate_ratio =</span> <span class="fu">exp</span>(comparison_table<span class="sc">$</span>estimated_value)</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>rate_ratio_table[, <span class="fu">c</span>(<span class="st">"true_rate_ratio"</span>, <span class="st">"estimated_rate_ratio"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(rate_ratio_table[, <span class="fu">c</span>(<span class="st">"true_rate_ratio"</span>, <span class="st">"estimated_rate_ratio"</span>)], <span class="dv">3</span>)</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  rate_ratio_table,</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"True and estimated rate ratios in the synthetic Poisson dataset"</span></span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>True and estimated rate ratios in the synthetic Poisson dataset</caption>
<thead>
<tr class="header">
<th style="text-align: left;">term</th>
<th style="text-align: right;">true_rate_ratio</th>
<th style="text-align: right;">estimated_rate_ratio</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: right;">0.212</td>
<td style="text-align: right;">0.212</td>
</tr>
<tr class="even">
<td style="text-align: left;">age</td>
<td style="text-align: right;">1.012</td>
<td style="text-align: right;">1.012</td>
</tr>
<tr class="odd">
<td style="text-align: left;">chronic</td>
<td style="text-align: right;">1.246</td>
<td style="text-align: right;">1.247</td>
</tr>
<tr class="even">
<td style="text-align: left;">female</td>
<td style="text-align: right;">1.105</td>
<td style="text-align: right;">1.105</td>
</tr>
<tr class="odd">
<td style="text-align: left;">poor_health</td>
<td style="text-align: right;">1.733</td>
<td style="text-align: right;">1.728</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>For example, the true coefficient on <code>poor_health</code> is <span class="math inline">\(0.55\)</span>, which corresponds to a rate ratio of about <span class="math inline">\(\exp(0.55) = 1.73\)</span>. That means patients in poor health are designed to have about 73% more visits per unit of follow-up time than otherwise similar patients who are not in poor health.</p>
</section>
<section id="step-5-compare-observed-and-theoretical-count-frequencies" class="level2" data-number="53.7">
<h2 data-number="53.7" class="anchored" data-anchor-id="step-5-compare-observed-and-theoretical-count-frequencies"><span class="header-section-number">53.7</span> Step 5: Compare observed and theoretical count frequencies</h2>
<p>One of the simplest diagnostics is to compare the observed distribution of counts for a reference subgroup with the Poisson probabilities implied by that subgroup's mean.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>reference_group <span class="ot">&lt;-</span> <span class="fu">subset</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  synthetic_visits,</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  chronic <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> poor_health <span class="sc">==</span> <span class="dv">0</span> <span class="sc">&amp;</span> female <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> months_observed <span class="sc">==</span> <span class="dv">12</span></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>max_count <span class="ot">&lt;-</span> <span class="fu">min</span>(<span class="dv">12</span>, <span class="fu">max</span>(reference_group<span class="sc">$</span>doctor_visits))</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>count_support <span class="ot">&lt;-</span> <span class="dv">0</span><span class="sc">:</span>max_count</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>observed_counts <span class="ot">&lt;-</span> <span class="fu">table</span>(<span class="fu">factor</span>(reference_group<span class="sc">$</span>doctor_visits, <span class="at">levels =</span> count_support))</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>observed_prob <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(observed_counts) <span class="sc">/</span> <span class="fu">sum</span>(observed_counts)</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>lambda_reference <span class="ot">&lt;-</span> <span class="dv">12</span> <span class="sc">*</span> <span class="fu">exp</span>(<span class="sc">-</span><span class="fl">1.55</span> <span class="sc">+</span> <span class="fl">0.012</span> <span class="sc">*</span> <span class="dv">60</span> <span class="sc">+</span> <span class="fl">0.22</span> <span class="sc">*</span> <span class="dv">1</span> <span class="sc">+</span> <span class="fl">0.10</span> <span class="sc">*</span> <span class="dv">1</span> <span class="sc">+</span> <span class="fl">0.55</span> <span class="sc">*</span> <span class="dv">0</span>)</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>theoretical_prob <span class="ot">&lt;-</span> <span class="fu">dpois</span>(count_support, <span class="at">lambda =</span> lambda_reference)</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>distribution_check <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">count =</span> count_support,</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">observed_probability =</span> observed_prob,</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">theoretical_probability =</span> theoretical_prob</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>distribution_check[, <span class="fu">c</span>(<span class="st">"observed_probability"</span>, <span class="st">"theoretical_probability"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(distribution_check[, <span class="fu">c</span>(<span class="st">"observed_probability"</span>, <span class="st">"theoretical_probability"</span>)], <span class="dv">3</span>)</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>  distribution_check,</span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Observed and theoretical count probabilities for a reference subgroup"</span></span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Observed and theoretical count probabilities for a reference subgroup</caption>
<thead>
<tr class="header">
<th style="text-align: right;">count</th>
<th style="text-align: right;">observed_probability</th>
<th style="text-align: right;">theoretical_probability</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">0</td>
<td style="text-align: right;">0.000</td>
<td style="text-align: right;">0.001</td>
</tr>
<tr class="even">
<td style="text-align: right;">1</td>
<td style="text-align: right;">0.000</td>
<td style="text-align: right;">0.005</td>
</tr>
<tr class="odd">
<td style="text-align: right;">2</td>
<td style="text-align: right;">0.034</td>
<td style="text-align: right;">0.019</td>
</tr>
<tr class="even">
<td style="text-align: right;">3</td>
<td style="text-align: right;">0.042</td>
<td style="text-align: right;">0.046</td>
</tr>
<tr class="odd">
<td style="text-align: right;">4</td>
<td style="text-align: right;">0.102</td>
<td style="text-align: right;">0.083</td>
</tr>
<tr class="even">
<td style="text-align: right;">5</td>
<td style="text-align: right;">0.144</td>
<td style="text-align: right;">0.120</td>
</tr>
<tr class="odd">
<td style="text-align: right;">6</td>
<td style="text-align: right;">0.136</td>
<td style="text-align: right;">0.144</td>
</tr>
<tr class="even">
<td style="text-align: right;">7</td>
<td style="text-align: right;">0.102</td>
<td style="text-align: right;">0.149</td>
</tr>
<tr class="odd">
<td style="text-align: right;">8</td>
<td style="text-align: right;">0.127</td>
<td style="text-align: right;">0.134</td>
</tr>
<tr class="even">
<td style="text-align: right;">9</td>
<td style="text-align: right;">0.127</td>
<td style="text-align: right;">0.107</td>
</tr>
<tr class="odd">
<td style="text-align: right;">10</td>
<td style="text-align: right;">0.068</td>
<td style="text-align: right;">0.077</td>
</tr>
<tr class="even">
<td style="text-align: right;">11</td>
<td style="text-align: right;">0.085</td>
<td style="text-align: right;">0.051</td>
</tr>
<tr class="odd">
<td style="text-align: right;">12</td>
<td style="text-align: right;">0.034</td>
<td style="text-align: right;">0.030</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>distribution_plot <span class="ot">&lt;-</span> <span class="fu">rbind</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">count =</span> count_support,</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">probability =</span> observed_prob,</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">source =</span> <span class="st">"Observed"</span></span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">count =</span> count_support,</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">probability =</span> theoretical_prob,</span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">source =</span> <span class="st">"Theoretical Poisson"</span></span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-14"><a href="#cb6-14" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(distribution_plot, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> count, <span class="at">y =</span> probability, <span class="at">fill =</span> source)) <span class="sc">+</span></span>
<span id="cb6-15"><a href="#cb6-15" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_col</span>(<span class="at">position =</span> <span class="st">"dodge"</span>) <span class="sc">+</span></span>
<span id="cb6-16"><a href="#cb6-16" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb6-17"><a href="#cb6-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Observed and theoretical count frequencies for a reference subgroup"</span>,</span>
<span id="cb6-18"><a href="#cb6-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"A well-generated Poisson sample should roughly match the theoretical count probabilities"</span>,</span>
<span id="cb6-19"><a href="#cb6-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Doctor visits"</span>,</span>
<span id="cb6-20"><a href="#cb6-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Probability"</span>,</span>
<span id="cb6-21"><a href="#cb6-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"Source"</span></span>
<span id="cb6-22"><a href="#cb6-22" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-23"><a href="#cb6-23" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_fill_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"#6c9bd2"</span>, <span class="st">"#d08c42"</span>)) <span class="sc">+</span></span>
<span id="cb6-24"><a href="#cb6-24" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/simulating-poisson-data_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This comparison is not meant to be exact in a finite subgroup. It is meant to show that the simulated frequencies align reasonably well with the shape implied by the Poisson model.</p>
</section>
<section id="main-assumptions-behind-this-simulation" class="level2" data-number="53.8">
<h2 data-number="53.8" class="anchored" data-anchor-id="main-assumptions-behind-this-simulation"><span class="header-section-number">53.8</span> Main assumptions behind this simulation</h2>
<p>The most important assumption is that the count outcome is conditionally Poisson, which means that the conditional mean and conditional variance are equal:</p>
<p><span class="math display">\[
\mathbb{E}(Y_i \mid X_i) = \text{Var}(Y_i \mid X_i) = \mu_i.
\]</span></p>
<p>That assumption is often too strict in real utilization data, where overdispersion is common. But it is exactly the right place to start when learning how count models work.</p>
<p>The chapter also assumes that the log-linear mean model is correctly specified and that the offset enters with coefficient one through <span class="math inline">\(\log(t_i)\)</span>. Those assumptions make the exercise transparent. Later simulations can relax them by introducing overdispersion, zero inflation, clustering, or serial dependence.</p>
</section>
<section id="further-reading" class="level2" data-number="53.9">
<h2 data-number="53.9" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">53.9</span> Further reading</h2>
<p>Cameron and Trivedi remain a foundational applied reference for count-data econometrics and are especially helpful for connecting Poisson models to real utilization outcomes <span class="citation" data-cites="cameron1986">Cameron and Trivedi (<a href="#ref-cameron1986" role="doc-biblioref">1986</a>)</span>. Nelder and Wedderburn are the classic reference for the generalized linear model framework that makes Poisson regression natural in the first place <span class="citation" data-cites="nelder1972">Nelder and Wedderburn (<a href="#ref-nelder1972" role="doc-biblioref">1972</a>)</span>. Together, they provide a strong bridge between the mechanics of simulation and the broader modeling tradition used in applied health economics.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-cameron1986" class="csl-entry" role="listitem">
Cameron, A. Colin, and Pravin K. Trivedi. 1986. <span>"Econometric Models Based on Count Data: Comparisons and Applications of Some Estimators and Tests."</span> <em>Journal of Applied Econometrics</em> 1 (1): 29-53. <a href="https://doi.org/10.1002/jae.3950010104">https://doi.org/10.1002/jae.3950010104</a>.
</div>
<div id="ref-nelder1972" class="csl-entry" role="listitem">
Nelder, J. A., and R. W. M. Wedderburn. 1972. <span>"Generalized Linear Models."</span> <em>Journal of the Royal Statistical Society. Series A (General)</em> 135 (3): 370-84. <a href="https://doi.org/10.2307/2344614">https://doi.org/10.2307/2344614</a>.
</div>
</div>
</section>
