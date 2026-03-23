---
title: "Simulating Multilevel Data"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which patients are nested within clinics and the outcome depends on both patient-level covariates and clinic-level heterogeneity. The goal is to make the logic of..."
---
<p>This chapter creates a synthetic dataset in which patients are nested within clinics and the outcome depends on both patient-level covariates and clinic-level heterogeneity. The goal is to make the logic of multilevel data visible before fitting the matching mixed-effects model. The design follows the random-effects tradition formalized by Laird and Ware, where outcomes are shaped partly by individual characteristics and partly by shared group-level structure <span class="citation" data-cites="laird1982">Laird and Ware (<a href="#ref-laird1982" role="doc-biblioref">1982</a>)</span>.</p>
<p>In health economics and health systems research, clustering is not optional detail. Patients are treated inside clinics, hospitals, insurers, regions, and provider networks. A simulation that ignores that nesting can easily understate uncertainty or misrepresent how outcomes vary across institutions.</p>
<section id="what-variables-will-be-created" class="level2" data-number="55.1">
<h2 data-number="55.1" class="anchored" data-anchor-id="what-variables-will-be-created"><span class="header-section-number">55.1</span> What variables will be created</h2>
<p>The synthetic sample will represent patients enrolled in a chronic-care program across many clinics. <code>clinic</code> will identify the clinic. <code>age</code> will represent age in years. <code>severity</code> will be a continuous disease-severity score. <code>program</code> will indicate whether the patient receives an enhanced coaching intervention. <code>clinic_intercept</code> will be the latent clinic-specific deviation from the overall mean outcome. The continuous outcome <code>followup_hba1c</code> will represent a six-month glycated hemoglobin measure.</p>
<p>These variables give the data two layers: the patient layer and the clinic layer. That is the essence of multilevel simulation.</p>
</section>
<section id="the-data-generating-process" class="level2" data-number="55.2">
<h2 data-number="55.2" class="anchored" data-anchor-id="the-data-generating-process"><span class="header-section-number">55.2</span> The data-generating process</h2>
<p>The outcome follows a random-intercept model:</p>
<p><span class="math display">\[
Y_{ij} =
\beta_0 +
\beta_1 (\text{age}_{ij} - 60) +
\beta_2 \text{severity}_{ij} +
\beta_3 \text{program}_{ij} +
b_j + \varepsilon_{ij},
\]</span></p>
<p>where</p>
<p><span class="math display">\[
b_j \sim N(0, \tau^2),
\qquad
\varepsilon_{ij} \sim N(0, \sigma^2).
\]</span></p>
<p>For this simulation, the true parameters are</p>
<p><span class="math display">\[
\beta_0 = 7.4,\;
\beta_1 = 0.015,\;
\beta_2 = 0.55,\;
\beta_3 = -0.40,\;
\tau = 0.60,\;
\sigma = 0.80.
\]</span></p>
<p>The random intercept <span class="math inline">\(b_j\)</span> makes patients from the same clinic more similar than patients from different clinics, even after adjusting for measured covariates.</p>
</section>
<section id="step-1-generate-the-clinic-structure-and-patient-level-data" class="level2" data-number="55.3">
<h2 data-number="55.3" class="anchored" data-anchor-id="step-1-generate-the-clinic-structure-and-patient-level-data"><span class="header-section-number">55.3</span> Step 1: Generate the clinic structure and patient-level data</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n_clinics <span class="ot">&lt;-</span> <span class="dv">80</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>clinic_size <span class="ot">&lt;-</span> <span class="fu">sample</span>(<span class="dv">45</span><span class="sc">:</span><span class="dv">75</span>, <span class="at">size =</span> n_clinics, <span class="at">replace =</span> <span class="cn">TRUE</span>)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>clinic <span class="ot">&lt;-</span> <span class="fu">rep</span>(<span class="fu">seq_len</span>(n_clinics), <span class="at">times =</span> clinic_size)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>n <span class="ot">&lt;-</span> <span class="fu">length</span>(clinic)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>clinic_intercepts <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_clinics, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="fl">0.60</span>)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>age <span class="ot">&lt;-</span> <span class="fu">pmax</span>(<span class="fu">round</span>(<span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">61</span>, <span class="at">sd =</span> <span class="dv">11</span>)), <span class="dv">30</span>)</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>severity <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>program <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  n,</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">size =</span> <span class="dv">1</span>,</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">prob =</span> <span class="fu">plogis</span>(<span class="sc">-</span><span class="fl">0.2</span> <span class="sc">-</span> <span class="fl">0.25</span> <span class="sc">*</span> severity <span class="sc">+</span> <span class="fl">0.15</span> <span class="sc">*</span> (age <span class="sc">&lt;</span> <span class="dv">60</span>))</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>epsilon <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="fl">0.80</span>)</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>followup_hba1c <span class="ot">&lt;-</span> <span class="fl">7.4</span> <span class="sc">+</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.015</span> <span class="sc">*</span> (age <span class="sc">-</span> <span class="dv">60</span>) <span class="sc">+</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.55</span> <span class="sc">*</span> severity <span class="sc">-</span></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.40</span> <span class="sc">*</span> program <span class="sc">+</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>  clinic_intercepts[clinic] <span class="sc">+</span></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  epsilon</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>synthetic_multilevel <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">clinic =</span> <span class="fu">factor</span>(clinic),</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>  age,</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>  severity,</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>  program,</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>  followup_hba1c,</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>  <span class="at">clinic_intercept =</span> clinic_intercepts[clinic]</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>multilevel_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">clinics =</span> n_clinics,</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">patients =</span> <span class="fu">nrow</span>(synthetic_multilevel),</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_cluster_size =</span> <span class="fu">mean</span>(<span class="fu">table</span>(synthetic_multilevel<span class="sc">$</span>clinic)),</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_hba1c =</span> <span class="fu">mean</span>(synthetic_multilevel<span class="sc">$</span>followup_hba1c),</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  <span class="at">sd_hba1c =</span> <span class="fu">sd</span>(synthetic_multilevel<span class="sc">$</span>followup_hba1c)</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>multilevel_summary[, <span class="fu">c</span>(<span class="st">"mean_cluster_size"</span>, <span class="st">"mean_hba1c"</span>, <span class="st">"sd_hba1c"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(multilevel_summary[, <span class="fu">c</span>(<span class="st">"mean_cluster_size"</span>, <span class="st">"mean_hba1c"</span>, <span class="st">"sd_hba1c"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>  multilevel_summary,</span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the synthetic multilevel dataset"</span></span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the synthetic multilevel dataset</caption>
<thead>
<tr class="header">
<th style="text-align: right;">clinics</th>
<th style="text-align: right;">patients</th>
<th style="text-align: right;">mean_cluster_size</th>
<th style="text-align: right;">mean_hba1c</th>
<th style="text-align: right;">sd_hba1c</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">80</td>
<td style="text-align: right;">4749</td>
<td style="text-align: right;">59.362</td>
<td style="text-align: right;">7.147</td>
<td style="text-align: right;">1.174</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The key step is the clinic-specific intercept. That single latent term introduces within-clinic correlation across all patients from the same site.</p>
</section>
<section id="step-2-fit-the-mixed-effects-model-that-matches-the-truth" class="level2" data-number="55.4">
<h2 data-number="55.4" class="anchored" data-anchor-id="step-2-fit-the-mixed-effects-model-that-matches-the-truth"><span class="header-section-number">55.4</span> Step 2: Fit the mixed-effects model that matches the truth</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>multilevel_fit <span class="ot">&lt;-</span> nlme<span class="sc">::</span><span class="fu">lme</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">fixed =</span> followup_hba1c <span class="sc">~</span> age <span class="sc">+</span> severity <span class="sc">+</span> program,</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">random =</span> <span class="sc">~</span> <span class="dv">1</span> <span class="sc">|</span> clinic,</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_multilevel,</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">method =</span> <span class="st">"REML"</span></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>fixed_effects_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">term =</span> <span class="fu">names</span>(nlme<span class="sc">::</span><span class="fu">fixed.effects</span>(multilevel_fit)),</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_value =</span> <span class="fu">c</span>(</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>    <span class="st">"(Intercept)"</span> <span class="ot">=</span> <span class="fl">6.5</span>,</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">age =</span> <span class="fl">0.015</span>,</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">severity =</span> <span class="fl">0.55</span>,</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">program =</span> <span class="sc">-</span><span class="fl">0.40</span></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  )[<span class="fu">names</span>(nlme<span class="sc">::</span><span class="fu">fixed.effects</span>(multilevel_fit))],</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_value =</span> <span class="fu">as.numeric</span>(nlme<span class="sc">::</span><span class="fu">fixed.effects</span>(multilevel_fit))</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>fixed_effects_table<span class="sc">$</span>bias <span class="ot">&lt;-</span> fixed_effects_table<span class="sc">$</span>estimated_value <span class="sc">-</span> fixed_effects_table<span class="sc">$</span>true_value</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>fixed_effects_table[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>, <span class="st">"bias"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(fixed_effects_table[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>, <span class="st">"bias"</span>)], <span class="dv">3</span>)</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  fixed_effects_table,</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"True and estimated fixed effects in the random-intercept model"</span></span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>True and estimated fixed effects in the random-intercept model</caption>
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
<td style="text-align: right;">6.500</td>
<td style="text-align: right;">6.559</td>
<td style="text-align: right;">0.059</td>
</tr>
<tr class="even">
<td style="text-align: left;">age</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.015</td>
<td style="text-align: right;">0.013</td>
<td style="text-align: right;">-0.002</td>
</tr>
<tr class="odd">
<td style="text-align: left;">severity</td>
<td style="text-align: left;">severity</td>
<td style="text-align: right;">0.550</td>
<td style="text-align: right;">0.555</td>
<td style="text-align: right;">0.005</td>
</tr>
<tr class="even">
<td style="text-align: left;">program</td>
<td style="text-align: left;">program</td>
<td style="text-align: right;">-0.400</td>
<td style="text-align: right;">-0.387</td>
<td style="text-align: right;">0.013</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The intercept is <span class="math inline">\(6.5\)</span> in the fitted model because the generating equation was written with centered age, <span class="math inline">\(0.015(age - 60)\)</span>. Once age enters the fitted model in raw units, the implied intercept becomes <span class="math inline">\(7.4 - 0.015 \times 60 = 6.5\)</span>.</p>
</section>
<section id="step-3-compare-the-variance-components-and-the-intraclass-correlation" class="level2" data-number="55.5">
<h2 data-number="55.5" class="anchored" data-anchor-id="step-3-compare-the-variance-components-and-the-intraclass-correlation"><span class="header-section-number">55.5</span> Step 3: Compare the variance components and the intraclass correlation</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>variance_components <span class="ot">&lt;-</span> nlme<span class="sc">::</span><span class="fu">VarCorr</span>(multilevel_fit)</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>estimated_tau <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(variance_components[<span class="dv">1</span>, <span class="st">"StdDev"</span>])<span class="sc">^</span><span class="dv">2</span></span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>estimated_sigma <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(variance_components[<span class="dv">2</span>, <span class="st">"StdDev"</span>])<span class="sc">^</span><span class="dv">2</span></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>variance_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">component =</span> <span class="fu">c</span>(<span class="st">"clinic_variance"</span>, <span class="st">"residual_variance"</span>, <span class="st">"ICC"</span>),</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_value =</span> <span class="fu">c</span>(</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.60</span><span class="sc">^</span><span class="dv">2</span>,</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.80</span><span class="sc">^</span><span class="dv">2</span>,</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.60</span><span class="sc">^</span><span class="dv">2</span> <span class="sc">/</span> (<span class="fl">0.60</span><span class="sc">^</span><span class="dv">2</span> <span class="sc">+</span> <span class="fl">0.80</span><span class="sc">^</span><span class="dv">2</span>)</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_value =</span> <span class="fu">c</span>(</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>    estimated_tau,</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>    estimated_sigma,</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>    estimated_tau <span class="sc">/</span> (estimated_tau <span class="sc">+</span> estimated_sigma)</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>variance_table[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(variance_table[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>)], <span class="dv">3</span>)</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>  variance_table,</span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"True and estimated variance components in the multilevel simulation"</span></span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>True and estimated variance components in the multilevel simulation</caption>
<thead>
<tr class="header">
<th style="text-align: left;">component</th>
<th style="text-align: right;">true_value</th>
<th style="text-align: right;">estimated_value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">clinic_variance</td>
<td style="text-align: right;">0.36</td>
<td style="text-align: right;">0.385</td>
</tr>
<tr class="even">
<td style="text-align: left;">residual_variance</td>
<td style="text-align: right;">0.64</td>
<td style="text-align: right;">0.630</td>
</tr>
<tr class="odd">
<td style="text-align: left;">ICC</td>
<td style="text-align: right;">0.36</td>
<td style="text-align: right;">0.379</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The intraclass correlation coefficient, or ICC, is especially useful because it tells us what share of total variation is attributable to between-clinic differences.</p>
</section>
<section id="step-4-compare-true-and-estimated-clinic-effects" class="level2" data-number="55.6">
<h2 data-number="55.6" class="anchored" data-anchor-id="step-4-compare-true-and-estimated-clinic-effects"><span class="header-section-number">55.6</span> Step 4: Compare true and estimated clinic effects</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>clinic_effects <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">clinic =</span> <span class="fu">rownames</span>(nlme<span class="sc">::</span><span class="fu">ranef</span>(multilevel_fit)),</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_intercept =</span> <span class="fu">as.numeric</span>(nlme<span class="sc">::</span><span class="fu">ranef</span>(multilevel_fit)[, <span class="dv">1</span>]),</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_intercept =</span> clinic_intercepts</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  clinic_effects,</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> true_intercept, <span class="at">y =</span> estimated_intercept)</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>) <span class="sc">+</span></span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(<span class="at">color =</span> <span class="st">"#4d7c8a"</span>, <span class="at">alpha =</span> <span class="fl">0.7</span>) <span class="sc">+</span></span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_abline</span>(<span class="at">intercept =</span> <span class="dv">0</span>, <span class="at">slope =</span> <span class="dv">1</span>, <span class="at">linetype =</span> <span class="dv">2</span>, <span class="at">color =</span> <span class="st">"#8b5e34"</span>) <span class="sc">+</span></span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"True and estimated clinic intercepts in the multilevel simulation"</span>,</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"The dashed line marks perfect recovery of the clinic-level effects"</span>,</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"True clinic random intercept"</span>,</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Estimated clinic random intercept"</span></span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/simulating-multilevel-data_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The points should cluster around the 45-degree line, although the estimated clinic effects will be shrunk toward zero. That shrinkage is part of the model, not a mistake.</p>
</section>
<section id="main-assumptions-behind-this-simulation" class="level2" data-number="55.7">
<h2 data-number="55.7" class="anchored" data-anchor-id="main-assumptions-behind-this-simulation"><span class="header-section-number">55.7</span> Main assumptions behind this simulation</h2>
<p>The simulation assumes normally distributed random intercepts and normally distributed residual noise. It also assumes that the clinic-specific effects are independent of the patient-level covariates. Those assumptions are strong, but they are useful when learning because they make the interpretation of the mixed model clean.</p>
<p>This chapter includes only a random intercept. Real multilevel health data may also need random slopes, cross-level interactions, repeated measures over time, or non-Gaussian outcomes. Still, the random-intercept model is the right first step because it shows exactly how clustering changes the structure of the data.</p>
</section>
<section id="further-reading" class="level2" data-number="55.8">
<h2 data-number="55.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">55.8</span> Further reading</h2>
<p>Laird and Ware remain a classic entry point for the logic of random-effects models and repeated clustered data <span class="citation" data-cites="laird1982">Laird and Ware (<a href="#ref-laird1982" role="doc-biblioref">1982</a>)</span>. Their framework still underpins a large share of modern multilevel modeling in applied biostatistics, outcomes research, and health-services analysis.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-laird1982" class="csl-entry" role="listitem">
Laird, Nan M., and James H. Ware. 1982. <span>"Random-Effects Models for Longitudinal Data."</span> <em>Biometrics</em> 38 (4): 963-74. <a href="https://doi.org/10.2307/2529876">https://doi.org/10.2307/2529876</a>.
</div>
</div>
</section>
