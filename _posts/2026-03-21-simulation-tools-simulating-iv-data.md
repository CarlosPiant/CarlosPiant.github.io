---
title: "Simulating Data from an Instrumental Variables Model"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which treatment is endogenous and must be identified through an instrumental variable. The design is inspired by the encouragement-style applications that run through the..."
---
<p>This chapter creates a synthetic dataset in which treatment is endogenous and must be identified through an instrumental variable. The design is inspired by the encouragement-style applications that run through the instrumental-variables literature, including fertility and labor-supply examples such as Angrist and Evans <span class="citation" data-cites="angrist1998">Angrist and Evans (<a href="#ref-angrist1998" role="doc-biblioref">1998</a>)</span>. The synthetic version here is not a replication of any one empirical study. Instead, it creates a simplified care-management setting in which unobserved severity affects both treatment take-up and outcomes, while an exogenous encouragement variable shifts treatment without directly affecting the outcome. That makes it useful for checking whether two-stage least squares can recover the true treatment effect when ordinary least squares cannot.</p>
<p>The practical reason to simulate IV data is that endogeneity is one of the main reasons applied regression fails. Treatment is often selected for reasons the analyst does not fully observe. Simulation makes that selection mechanism explicit and therefore provides a controlled setting for understanding what the instrument is supposed to fix.</p>
<section id="what-variables-will-be-created" class="level2" data-number="48.1">
<h2 data-number="48.1" class="anchored" data-anchor-id="what-variables-will-be-created"><span class="header-section-number">48.1</span> What variables will be created</h2>
<p>The synthetic sample will represent high-risk patients eligible for an intensive care-management program. <code>age</code> will represent age in years. <code>chronic</code> will count chronic conditions. <code>encouragement</code> will indicate whether the patient was assigned to a clinician with a more proactive outreach protocol. <code>severity_latent</code> will be an unobserved severity factor that affects both treatment take-up and cost. <code>program_enrollment</code> will indicate whether the patient actually enrolls in care management. The outcome <code>annual_cost</code> will record annual healthcare cost.</p>
<p>These variables are chosen to mimic the basic structure of an instrumental-variables problem: a treatment that is confounded, an instrument that affects treatment but not the outcome directly, and an unobserved factor that creates the endogeneity.</p>
</section>
<section id="the-data-generating-process" class="level2" data-number="48.2">
<h2 data-number="48.2" class="anchored" data-anchor-id="the-data-generating-process"><span class="header-section-number">48.2</span> The data-generating process</h2>
<p>The simulation uses a triangular system. Treatment is determined first:</p>
<p><span class="math display">\[
D_i = \mathbb{1}(D_i^* &gt; 0),
\]</span></p>
<p>where</p>
<p><span class="math display">\[
D_i^* =
\pi_0 +
\pi_1 Z_i +
\pi_2 \text{age}_i +
\pi_3 \text{chronic}_i +
\pi_4 U_i +
v_i.
\]</span></p>
<p>Here <span class="math inline">\(Z_i\)</span> is the instrument and <span class="math inline">\(U_i\)</span> is latent severity.</p>
<p>The outcome equation is</p>
<p><span class="math display">\[
Y_i =
\beta_0 +
\beta_1 D_i +
\beta_2 \text{age}_i +
\beta_3 \text{chronic}_i +
\beta_4 U_i +
\varepsilon_i.
\]</span></p>
<p>The key feature is that the latent severity term <span class="math inline">\(U_i\)</span> enters both equations. That creates endogeneity because treatment is correlated with the outcome error through a shared unobserved determinant.</p>
<p>For this simulation, the true parameters are set to</p>
<p><span class="math display">\[
\pi_0 = -1.1,\;
\pi_1 = 1.3,\;
\pi_2 = 0.015,\;
\pi_3 = 0.25,\;
\pi_4 = 0.9,
\]</span></p>
<p>and</p>
<p><span class="math display">\[
\beta_0 = 8500,\;
\beta_1 = -1800,\;
\beta_2 = 60,\;
\beta_3 = 950,\;
\beta_4 = 1600.
\]</span></p>
<p>The coefficient of interest is <span class="math inline">\(\beta_1 = -1800\)</span>, which means that true program enrollment lowers annual cost by $1,800 on average for the population generated here.</p>
</section>
<section id="step-1-generate-the-synthetic-sample" class="level2" data-number="48.3">
<h2 data-number="48.3" class="anchored" data-anchor-id="step-1-generate-the-synthetic-sample"><span class="header-section-number">48.3</span> Step 1: Generate the synthetic sample</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n <span class="ot">&lt;-</span> <span class="dv">7000</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>age <span class="ot">&lt;-</span> <span class="fu">pmax</span>(<span class="fu">round</span>(<span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">67</span>, <span class="at">sd =</span> <span class="dv">10</span>)), <span class="dv">40</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>chronic <span class="ot">&lt;-</span> <span class="fu">pmin</span>(<span class="fu">rpois</span>(n, <span class="at">lambda =</span> <span class="fl">2.4</span>), <span class="dv">7</span>)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>encouragement <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(n, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.5</span>)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>severity_latent <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>treatment_index <span class="ot">&lt;-</span> <span class="sc">-</span><span class="fl">1.1</span> <span class="sc">+</span></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>  <span class="fl">1.3</span> <span class="sc">*</span> encouragement <span class="sc">+</span></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.015</span> <span class="sc">*</span> age <span class="sc">+</span></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.25</span> <span class="sc">*</span> chronic <span class="sc">+</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.9</span> <span class="sc">*</span> severity_latent <span class="sc">+</span></span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>program_enrollment <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(treatment_index <span class="sc">&gt;</span> <span class="dv">0</span>)</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>annual_cost <span class="ot">&lt;-</span> <span class="dv">8500</span> <span class="sc">-</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  <span class="dv">1800</span> <span class="sc">*</span> program_enrollment <span class="sc">+</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  <span class="dv">60</span> <span class="sc">*</span> age <span class="sc">+</span></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  <span class="dv">950</span> <span class="sc">*</span> chronic <span class="sc">+</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>  <span class="dv">1600</span> <span class="sc">*</span> severity_latent <span class="sc">+</span></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1800</span>)</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>synthetic_iv <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  annual_cost,</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>  program_enrollment,</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>  encouragement,</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>  age,</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>  chronic,</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>  severity_latent</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>simulation_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(synthetic_iv),</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">treatment_rate =</span> <span class="fu">mean</span>(synthetic_iv<span class="sc">$</span>program_enrollment),</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">encouragement_rate =</span> <span class="fu">mean</span>(synthetic_iv<span class="sc">$</span>encouragement),</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_cost =</span> <span class="fu">mean</span>(synthetic_iv<span class="sc">$</span>annual_cost),</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_age =</span> <span class="fu">mean</span>(synthetic_iv<span class="sc">$</span>age),</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_chronic =</span> <span class="fu">mean</span>(synthetic_iv<span class="sc">$</span>chronic)</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>simulation_summary[, <span class="sc">-</span><span class="dv">1</span>] <span class="ot">&lt;-</span> <span class="fu">round</span>(simulation_summary[, <span class="sc">-</span><span class="dv">1</span>], <span class="dv">3</span>)</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>  simulation_summary,</span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the synthetic instrumental-variables dataset"</span></span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the synthetic instrumental-variables dataset</caption>
<colgroup>
<col style="width: 15%">
<col style="width: 19%">
<col style="width: 24%">
<col style="width: 12%">
<col style="width: 11%">
<col style="width: 16%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">treatment_rate</th>
<th style="text-align: right;">encouragement_rate</th>
<th style="text-align: right;">mean_cost</th>
<th style="text-align: right;">mean_age</th>
<th style="text-align: right;">mean_chronic</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">7000</td>
<td style="text-align: right;">0.773</td>
<td style="text-align: right;">0.498</td>
<td style="text-align: right;">13449.91</td>
<td style="text-align: right;">67.034</td>
<td style="text-align: right;">2.398</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The data now contain the exact feature that makes IV necessary. Higher latent severity raises treatment take-up and also raises cost. If that latent severity were omitted from the fitted regression, ordinary least squares would treat part of that confounding as if it were a treatment effect.</p>
</section>
<section id="step-2-show-why-ordinary-least-squares-is-biased" class="level2" data-number="48.4">
<h2 data-number="48.4" class="anchored" data-anchor-id="step-2-show-why-ordinary-least-squares-is-biased"><span class="header-section-number">48.4</span> Step 2: Show why ordinary least squares is biased</h2>
<p>First fit the naive linear regression that ignores the endogeneity problem.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>ols_fit <span class="ot">&lt;-</span> <span class="fu">lm</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  annual_cost <span class="sc">~</span> program_enrollment <span class="sc">+</span> age <span class="sc">+</span> chronic,</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_iv</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>ols_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">term =</span> <span class="fu">names</span>(<span class="fu">coef</span>(ols_fit)),</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimate =</span> <span class="fu">coef</span>(ols_fit)</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>ols_table<span class="sc">$</span>estimate <span class="ot">&lt;-</span> <span class="fu">round</span>(ols_table<span class="sc">$</span>estimate, <span class="dv">3</span>)</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  ols_table,</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Naive OLS estimates when treatment is endogenous"</span></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Naive OLS estimates when treatment is endogenous</caption>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">term</th>
<th style="text-align: right;">estimate</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: right;">7849.267</td>
</tr>
<tr class="even">
<td style="text-align: left;">program_enrollment</td>
<td style="text-align: left;">program_enrollment</td>
<td style="text-align: right;">-117.092</td>
</tr>
<tr class="odd">
<td style="text-align: left;">age</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">53.371</td>
</tr>
<tr class="even">
<td style="text-align: left;">chronic</td>
<td style="text-align: left;">chronic</td>
<td style="text-align: right;">881.456</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The coefficient on <code>program_enrollment</code> should be biased toward zero or even in the wrong direction relative to the true treatment effect because sicker patients are more likely to enroll.</p>
</section>
<section id="step-3-fit-the-model-that-matches-the-true-generating-process" class="level2" data-number="48.5">
<h2 data-number="48.5" class="anchored" data-anchor-id="step-3-fit-the-model-that-matches-the-true-generating-process"><span class="header-section-number">48.5</span> Step 3: Fit the model that matches the true generating process</h2>
<p>Now fit the correct IV specification using two-stage least squares, with <code>encouragement</code> as the instrument.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>iv_fit <span class="ot">&lt;-</span> AER<span class="sc">::</span><span class="fu">ivreg</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  annual_cost <span class="sc">~</span> program_enrollment <span class="sc">+</span> age <span class="sc">+</span> chronic <span class="sc">|</span></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>    encouragement <span class="sc">+</span> age <span class="sc">+</span> chronic,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_iv</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>truth_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">model =</span> <span class="fu">c</span>(<span class="st">"Naive OLS"</span>, <span class="st">"Two-stage least squares"</span>),</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_treatment_effect =</span> <span class="fu">c</span>(</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coef</span>(ols_fit)[<span class="st">"program_enrollment"</span>],</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coef</span>(iv_fit)[<span class="st">"program_enrollment"</span>]</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_treatment_effect =</span> <span class="sc">-</span><span class="dv">1800</span></span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>truth_table<span class="sc">$</span>bias <span class="ot">&lt;-</span> truth_table<span class="sc">$</span>estimated_treatment_effect <span class="sc">-</span> truth_table<span class="sc">$</span>true_treatment_effect</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>truth_table[, <span class="fu">c</span>(<span class="st">"estimated_treatment_effect"</span>, <span class="st">"true_treatment_effect"</span>, <span class="st">"bias"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(truth_table[, <span class="fu">c</span>(<span class="st">"estimated_treatment_effect"</span>, <span class="st">"true_treatment_effect"</span>, <span class="st">"bias"</span>)], <span class="dv">3</span>)</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>  truth_table,</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Naive and IV treatment-effect estimates compared with the known truth"</span></span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Naive and IV treatment-effect estimates compared with the known truth</caption>
<colgroup>
<col style="width: 29%">
<col style="width: 32%">
<col style="width: 26%">
<col style="width: 10%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">model</th>
<th style="text-align: right;">estimated_treatment_effect</th>
<th style="text-align: right;">true_treatment_effect</th>
<th style="text-align: right;">bias</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Naive OLS</td>
<td style="text-align: right;">-117.092</td>
<td style="text-align: right;">-1800</td>
<td style="text-align: right;">1682.908</td>
</tr>
<tr class="even">
<td style="text-align: left;">Two-stage least squares</td>
<td style="text-align: right;">-1365.691</td>
<td style="text-align: right;">-1800</td>
<td style="text-align: right;">434.309</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This is the main point of the exercise. The IV estimate should move much closer to the true treatment effect because the instrument isolates exogenous variation in treatment take-up.</p>
</section>
<section id="step-4-check-the-first-stage" class="level2" data-number="48.6">
<h2 data-number="48.6" class="anchored" data-anchor-id="step-4-check-the-first-stage"><span class="header-section-number">48.6</span> Step 4: Check the first stage</h2>
<p>An IV design only works if the instrument actually shifts treatment. The first-stage regression is therefore part of the generating process that must be checked explicitly.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>first_stage <span class="ot">&lt;-</span> <span class="fu">lm</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  program_enrollment <span class="sc">~</span> encouragement <span class="sc">+</span> age <span class="sc">+</span> chronic,</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_iv</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>first_stage_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">quantity =</span> <span class="fu">c</span>(</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>    <span class="st">"First-stage coefficient on encouragement"</span>,</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="st">"First-stage F statistic"</span></span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">value =</span> <span class="fu">c</span>(</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coef</span>(first_stage)[<span class="st">"encouragement"</span>],</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>    <span class="fu">summary</span>(first_stage)<span class="sc">$</span>fstatistic[<span class="dv">1</span>]</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>first_stage_table<span class="sc">$</span>value <span class="ot">&lt;-</span> <span class="fu">round</span>(first_stage_table<span class="sc">$</span>value, <span class="dv">3</span>)</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>  first_stage_table,</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"First-stage diagnostics in the synthetic IV design"</span></span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>First-stage diagnostics in the synthetic IV design</caption>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">quantity</th>
<th style="text-align: right;">value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">encouragement</td>
<td style="text-align: left;">First-stage coefficient on encouragement</td>
<td style="text-align: right;">0.261</td>
</tr>
<tr class="even">
<td style="text-align: left;">value</td>
<td style="text-align: left;">First-stage F statistic</td>
<td style="text-align: right;">353.682</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>first_stage_plot <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  program_enrollment <span class="sc">~</span> encouragement,</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_iv,</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  mean</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>first_stage_plot<span class="sc">$</span>encouragement <span class="ot">&lt;-</span> <span class="fu">factor</span>(</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>  first_stage_plot<span class="sc">$</span>encouragement,</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">levels =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>),</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">labels =</span> <span class="fu">c</span>(<span class="st">"No encouragement"</span>, <span class="st">"Encouragement"</span>)</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  first_stage_plot,</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> encouragement, <span class="at">y =</span> program_enrollment, <span class="at">fill =</span> encouragement)</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>) <span class="sc">+</span></span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_col</span>(<span class="at">width =</span> <span class="fl">0.65</span>) <span class="sc">+</span></span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_fill_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"No encouragement"</span> <span class="ot">=</span> <span class="st">"#8a5a44"</span>, <span class="st">"Encouragement"</span> <span class="ot">=</span> <span class="st">"#2f6f4f"</span>)) <span class="sc">+</span></span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"The instrument must shift treatment take-up"</span>,</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Enrollment rates by randomized encouragement status"</span>,</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="cn">NULL</span>,</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Share enrolled in care management"</span>,</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="cn">NULL</span></span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme</span>(<span class="at">legend.position =</span> <span class="st">"none"</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/simulating-iv-data_files/figure-html/unnamed-chunk-5-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The bar plot is the visual version of the first stage. If the bars were nearly identical, the instrument would be weak and the simulation would not be very informative.</p>
</section>
<section id="step-5-compare-predicted-treatment-by-observed-risk-groups" class="level2" data-number="48.7">
<h2 data-number="48.7" class="anchored" data-anchor-id="step-5-compare-predicted-treatment-by-observed-risk-groups"><span class="header-section-number">48.7</span> Step 5: Compare predicted treatment by observed risk groups</h2>
<p>One more useful check is to compare how enrollment changes across chronic-condition groups and instrument status.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>synthetic_iv<span class="sc">$</span>risk_group <span class="ot">&lt;-</span> <span class="fu">cut</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  synthetic_iv<span class="sc">$</span>chronic,</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">breaks =</span> <span class="fu">c</span>(<span class="sc">-</span><span class="cn">Inf</span>, <span class="dv">1</span>, <span class="dv">3</span>, <span class="dv">5</span>, <span class="cn">Inf</span>),</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">labels =</span> <span class="fu">c</span>(<span class="st">"0-1"</span>, <span class="st">"2-3"</span>, <span class="st">"4-5"</span>, <span class="st">"6+"</span>)</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>risk_first_stage <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(</span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>  program_enrollment <span class="sc">~</span> risk_group <span class="sc">+</span> encouragement,</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_iv,</span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>  mean</span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>risk_first_stage<span class="sc">$</span>encouragement <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(</span>
<span id="cb6-14"><a href="#cb6-14" aria-hidden="true" tabindex="-1"></a>  risk_first_stage<span class="sc">$</span>encouragement <span class="sc">==</span> <span class="dv">1</span>,</span>
<span id="cb6-15"><a href="#cb6-15" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Encouragement"</span>,</span>
<span id="cb6-16"><a href="#cb6-16" aria-hidden="true" tabindex="-1"></a>  <span class="st">"No encouragement"</span></span>
<span id="cb6-17"><a href="#cb6-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-18"><a href="#cb6-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-19"><a href="#cb6-19" aria-hidden="true" tabindex="-1"></a>risk_first_stage<span class="sc">$</span>program_enrollment <span class="ot">&lt;-</span> <span class="fu">round</span>(risk_first_stage<span class="sc">$</span>program_enrollment, <span class="dv">3</span>)</span>
<span id="cb6-20"><a href="#cb6-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-21"><a href="#cb6-21" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-22"><a href="#cb6-22" aria-hidden="true" tabindex="-1"></a>  risk_first_stage,</span>
<span id="cb6-23"><a href="#cb6-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Treatment take-up by chronic-condition group and instrument status"</span></span>
<span id="cb6-24"><a href="#cb6-24" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Treatment take-up by chronic-condition group and instrument status</caption>
<thead>
<tr class="header">
<th style="text-align: left;">risk_group</th>
<th style="text-align: left;">encouragement</th>
<th style="text-align: right;">program_enrollment</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">0-1</td>
<td style="text-align: left;">No encouragement</td>
<td style="text-align: right;">0.514</td>
</tr>
<tr class="even">
<td style="text-align: left;">2-3</td>
<td style="text-align: left;">No encouragement</td>
<td style="text-align: right;">0.665</td>
</tr>
<tr class="odd">
<td style="text-align: left;">4-5</td>
<td style="text-align: left;">No encouragement</td>
<td style="text-align: right;">0.765</td>
</tr>
<tr class="even">
<td style="text-align: left;">6+</td>
<td style="text-align: left;">No encouragement</td>
<td style="text-align: right;">0.862</td>
</tr>
<tr class="odd">
<td style="text-align: left;">0-1</td>
<td style="text-align: left;">Encouragement</td>
<td style="text-align: right;">0.849</td>
</tr>
<tr class="even">
<td style="text-align: left;">2-3</td>
<td style="text-align: left;">Encouragement</td>
<td style="text-align: right;">0.912</td>
</tr>
<tr class="odd">
<td style="text-align: left;">4-5</td>
<td style="text-align: left;">Encouragement</td>
<td style="text-align: right;">0.961</td>
</tr>
<tr class="even">
<td style="text-align: left;">6+</td>
<td style="text-align: left;">Encouragement</td>
<td style="text-align: right;">0.976</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table shows how the same instrument can operate in a population with different underlying risk. It also reinforces the basic logic of the DGP: treatment is more likely among sicker patients, but encouragement shifts take-up within those risk strata as well.</p>
</section>
<section id="main-assumptions-behind-this-simulation" class="level2" data-number="48.8">
<h2 data-number="48.8" class="anchored" data-anchor-id="main-assumptions-behind-this-simulation"><span class="header-section-number">48.8</span> Main assumptions behind this simulation</h2>
<p>The first assumption is instrument relevance:</p>
<p><span class="math display">\[
\mathrm{Cov}(Z_i, D_i) \neq 0.
\]</span></p>
<p>The second is exclusion: the instrument affects the outcome only through treatment. In this synthetic design, that is true by construction because <code>encouragement</code> does not appear in the outcome equation.</p>
<p>The third is independence: the instrument is independent of the latent severity factor. That is also true by construction because <code>encouragement</code> is randomized.</p>
<p>The fourth is that the structural treatment effect is constant in the outcome equation. Real IV applications often involve treatment-effect heterogeneity, in which case 2SLS should be interpreted more locally.</p>
</section>
<section id="how-to-adapt-this-template" class="level2" data-number="48.9">
<h2 data-number="48.9" class="anchored" data-anchor-id="how-to-adapt-this-template"><span class="header-section-number">48.9</span> How to adapt this template</h2>
<p>Once the basic structure is clear, the same IV simulation can be modified in many useful ways. You can weaken the instrument and study weak-instrument bias. You can allow the treatment effect to vary with severity and then compare the IV estimate with the average treatment effect. You can add direct violations of exclusion and see how quickly the estimate breaks down. You can simulate multiple instruments, clustered assignment, or binary outcomes with latent-index treatment selection.</p>
<p>In practice, these are some of the best ways to build intuition for IV. The method is often taught through assumptions alone, but simulation lets you see exactly what those assumptions mean in a known data-generating process.</p>
</section>
<section id="further-reading" class="level2" data-number="48.10">
<h2 data-number="48.10" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">48.10</span> Further reading</h2>
<p>Angrist and Evans provide one of the classic empirical examples of encouragement-type IV logic in applied economics <span class="citation" data-cites="angrist1998">Angrist and Evans (<a href="#ref-angrist1998" role="doc-biblioref">1998</a>)</span>. Imbens and Angrist explain the local causal interpretation that made modern IV reasoning more precise <span class="citation" data-cites="imbens1994">Imbens and Angrist (<a href="#ref-imbens1994" role="doc-biblioref">1994</a>)</span>. Staiger and Stock remain essential for understanding why first-stage strength matters so much for IV performance <span class="citation" data-cites="staiger1997">Staiger and Stock (<a href="#ref-staiger1997" role="doc-biblioref">1997</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-angrist1998" class="csl-entry" role="listitem">
Angrist, Joshua D., and William N. Evans. 1998. <span>"Children and Their Parents' Labor Supply: Evidence from Exogenous Variation in Family Size."</span> <em>The American Economic Review</em> 88 (3): 450-77. <a href="https://www.jstor.org/stable/116844">https://www.jstor.org/stable/116844</a>.
</div>
<div id="ref-imbens1994" class="csl-entry" role="listitem">
Imbens, Guido W., and Joshua D. Angrist. 1994. <span>"Identification and Estimation of Local Average Treatment Effects."</span> <em>Econometrica</em> 62 (2): 467-75. <a href="https://doi.org/10.2307/2951620">https://doi.org/10.2307/2951620</a>.
</div>
<div id="ref-staiger1997" class="csl-entry" role="listitem">
Staiger, Douglas, and James H. Stock. 1997. <span>"Instrumental Variables Regression with Weak Instruments."</span> <em>Econometrica</em> 65 (3): 557-86. <a href="https://doi.org/10.2307/2171753">https://doi.org/10.2307/2171753</a>.
</div>
</div>
</section>
