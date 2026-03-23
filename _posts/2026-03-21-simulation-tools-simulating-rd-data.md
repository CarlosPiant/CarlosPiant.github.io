---
title: "Simulating Regression Discontinuity Data"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic dataset in which treatment is assigned by a cutoff rule, so the natural estimand is a local treatment effect at the threshold. The design is inspired by regression discontinuity..."
---
<p>This chapter creates a synthetic dataset in which treatment is assigned by a cutoff rule, so the natural estimand is a local treatment effect at the threshold. The design is inspired by regression discontinuity applications such as Lee's close-election study, where a running variable determines treatment assignment through an observed threshold <span class="citation" data-cites="lee2008">Lee (<a href="#ref-lee2008" role="doc-biblioref">2008</a>)</span>. The synthetic version here is not a replication of electoral data. Instead, it creates a health-system risk-score rule under which patients just above a cutoff are automatically enrolled into an intensive follow-up program. That makes it useful for testing whether a fitted regression discontinuity analysis can recover the true treatment effect at the threshold.</p>
<p>The practical reason to simulate regression discontinuity data is that threshold policies are everywhere in health systems. Eligibility for intensive care management, outreach, subsidies, or enhanced monitoring is often determined by scores, age thresholds, or risk cutoffs. Simulation makes the logic of that assignment rule fully explicit.</p>
<section id="what-variables-will-be-created" class="level2" data-number="49.1">
<h2 data-number="49.1" class="anchored" data-anchor-id="what-variables-will-be-created"><span class="header-section-number">49.1</span> What variables will be created</h2>
<p>The synthetic sample will represent patients evaluated for a post-discharge follow-up program. <code>risk_score</code> will be the running variable used for eligibility. <code>eligible</code> will indicate whether the score crosses the policy threshold. <code>baseline_risk</code> will represent latent baseline complexity that evolves smoothly through the cutoff. The outcome <code>hospital_days</code> will measure future inpatient days over the next year.</p>
<p>These variables are chosen to reproduce the core elements of a sharp regression discontinuity design: a continuous running variable, deterministic treatment assignment at a cutoff, and an outcome whose untreated mean is smooth in the running variable.</p>
</section>
<section id="the-data-generating-process" class="level2" data-number="49.2">
<h2 data-number="49.2" class="anchored" data-anchor-id="the-data-generating-process"><span class="header-section-number">49.2</span> The data-generating process</h2>
<p>The treatment rule is sharp:</p>
<p><span class="math display">\[
D_i = \mathbb{1}(X_i \ge c),
\]</span></p>
<p>where <span class="math inline">\(X_i\)</span> is the running variable and the cutoff is</p>
<p><span class="math display">\[
c = 0.
\]</span></p>
<p>The untreated potential outcome is generated as a smooth function of the running variable:</p>
<p><span class="math display">\[
Y_i(0) = \alpha_0 + \alpha_1 X_i + \alpha_2 X_i^2 + \varepsilon_i,
\]</span></p>
<p>with</p>
<p><span class="math display">\[
\varepsilon_i \sim \mathcal{N}(0, \sigma^2).
\]</span></p>
<p>Treatment creates a discontinuous jump at the threshold:</p>
<p><span class="math display">\[
Y_i(1) = Y_i(0) + \tau,
\]</span></p>
<p>and the observed outcome is</p>
<p><span class="math display">\[
Y_i = Y_i(0) + \tau D_i.
\]</span></p>
<p>For this simulation, the true parameters are</p>
<p><span class="math display">\[
\alpha_0 = 6,\;
\alpha_1 = 0.18,\;
\alpha_2 = 0.012,\;
\tau = -1.5,
\]</span></p>
<p>with</p>
<p><span class="math display">\[
\sigma = 1.2.
\]</span></p>
<p>The negative treatment effect means that eligibility for the intensive follow-up program lowers future hospital days by 1.5 days on average at the cutoff.</p>
</section>
<section id="step-1-generate-the-synthetic-sample" class="level2" data-number="49.3">
<h2 data-number="49.3" class="anchored" data-anchor-id="step-1-generate-the-synthetic-sample"><span class="header-section-number">49.3</span> Step 1: Generate the synthetic sample</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n <span class="ot">&lt;-</span> <span class="dv">3500</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>risk_score <span class="ot">&lt;-</span> <span class="fu">runif</span>(n, <span class="at">min =</span> <span class="sc">-</span><span class="dv">20</span>, <span class="at">max =</span> <span class="dv">20</span>)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>eligible <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(risk_score <span class="sc">&gt;=</span> <span class="dv">0</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>true_effect <span class="ot">&lt;-</span> <span class="sc">-</span><span class="fl">1.5</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>untreated_mean <span class="ot">&lt;-</span> <span class="dv">6</span> <span class="sc">+</span> <span class="fl">0.18</span> <span class="sc">*</span> risk_score <span class="sc">+</span> <span class="fl">0.012</span> <span class="sc">*</span> risk_score<span class="sc">^</span><span class="dv">2</span></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>hospital_days <span class="ot">&lt;-</span> untreated_mean <span class="sc">+</span> true_effect <span class="sc">*</span> eligible <span class="sc">+</span> <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="fl">1.2</span>)</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>synthetic_rd <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  risk_score,</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  eligible,</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  untreated_mean,</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  hospital_days</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>simulation_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(synthetic_rd),</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">treated_share =</span> <span class="fu">mean</span>(synthetic_rd<span class="sc">$</span>eligible),</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_outcome =</span> <span class="fu">mean</span>(synthetic_rd<span class="sc">$</span>hospital_days),</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">sd_outcome =</span> stats<span class="sc">::</span><span class="fu">sd</span>(synthetic_rd<span class="sc">$</span>hospital_days),</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">score_min =</span> <span class="fu">min</span>(synthetic_rd<span class="sc">$</span>risk_score),</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">score_max =</span> <span class="fu">max</span>(synthetic_rd<span class="sc">$</span>risk_score)</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>simulation_summary[, <span class="sc">-</span><span class="dv">1</span>] <span class="ot">&lt;-</span> <span class="fu">round</span>(simulation_summary[, <span class="sc">-</span><span class="dv">1</span>], <span class="dv">3</span>)</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>  simulation_summary,</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the synthetic regression discontinuity dataset"</span></span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the synthetic regression discontinuity dataset</caption>
<colgroup>
<col style="width: 17%">
<col style="width: 20%">
<col style="width: 18%">
<col style="width: 15%">
<col style="width: 14%">
<col style="width: 14%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">treated_share</th>
<th style="text-align: right;">mean_outcome</th>
<th style="text-align: right;">sd_outcome</th>
<th style="text-align: right;">score_min</th>
<th style="text-align: right;">score_max</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">3500</td>
<td style="text-align: right;">0.507</td>
<td style="text-align: right;">6.808</td>
<td style="text-align: right;">2.372</td>
<td style="text-align: right;">-19.996</td>
<td style="text-align: right;">19.987</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This code creates a clean sharp RD design. The only discontinuity in the generating process is the treatment effect at the cutoff. Everything else evolves smoothly with the running variable.</p>
</section>
<section id="step-2-fit-the-model-that-matches-the-true-generating-process" class="level2" data-number="49.4">
<h2 data-number="49.4" class="anchored" data-anchor-id="step-2-fit-the-model-that-matches-the-true-generating-process"><span class="header-section-number">49.4</span> Step 2: Fit the model that matches the true generating process</h2>
<p>The most direct recovery check is to estimate the local treatment effect with a local linear RD procedure. To give that estimate context, it is also useful to compare it with a naive treated-versus-untreated comparison and a global regression with score controls.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>naive_model <span class="ot">&lt;-</span> <span class="fu">lm</span>(hospital_days <span class="sc">~</span> eligible, <span class="at">data =</span> synthetic_rd)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>global_model <span class="ot">&lt;-</span> <span class="fu">lm</span>(</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  hospital_days <span class="sc">~</span> eligible <span class="sc">*</span> risk_score <span class="sc">+</span> <span class="fu">I</span>(risk_score<span class="sc">^</span><span class="dv">2</span>),</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_rd</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>rd_fit <span class="ot">&lt;-</span> rdrobust<span class="sc">::</span><span class="fu">rdrobust</span>(</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> synthetic_rd<span class="sc">$</span>hospital_days,</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> synthetic_rd<span class="sc">$</span>risk_score,</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">c =</span> <span class="dv">0</span></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>extract_hc1_effect <span class="ot">&lt;-</span> <span class="cf">function</span>(model, term, model_name) {</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  robust_vcov <span class="ot">&lt;-</span> sandwich<span class="sc">::</span><span class="fu">vcovHC</span>(model, <span class="at">type =</span> <span class="st">"HC1"</span>)</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  estimate <span class="ot">&lt;-</span> <span class="fu">coef</span>(model)[term]</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  se <span class="ot">&lt;-</span> <span class="fu">sqrt</span>(robust_vcov[term, term])</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">model =</span> model_name,</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> estimate,</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower =</span> estimate <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> se,</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper =</span> estimate <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> se</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>extract_rd_effect <span class="ot">&lt;-</span> <span class="cf">function</span>(fit, model_name) {</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">model =</span> model_name,</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> fit<span class="sc">$</span>coef[<span class="st">"Robust"</span>, <span class="st">"Coeff"</span>],</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower =</span> fit<span class="sc">$</span>ci[<span class="st">"Robust"</span>, <span class="st">"CI Lower"</span>],</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper =</span> fit<span class="sc">$</span>ci[<span class="st">"Robust"</span>, <span class="st">"CI Upper"</span>]</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>effect_table <span class="ot">&lt;-</span> <span class="fu">rbind</span>(</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>    <span class="at">model =</span> <span class="st">"True effect at the cutoff"</span>,</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> true_effect,</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower =</span> <span class="cn">NA_real_</span>,</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper =</span> <span class="cn">NA_real_</span></span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_hc1_effect</span>(naive_model, <span class="st">"eligible"</span>, <span class="st">"Naive treated vs untreated comparison"</span>),</span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_hc1_effect</span>(global_model, <span class="st">"eligible"</span>, <span class="st">"Global regression with score controls"</span>),</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_rd_effect</span>(rd_fit, <span class="st">"Local linear RD (robust)"</span>)</span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a>effect_table[, <span class="fu">c</span>(<span class="st">"estimate"</span>, <span class="st">"lower"</span>, <span class="st">"upper"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(effect_table[, <span class="fu">c</span>(<span class="st">"estimate"</span>, <span class="st">"lower"</span>, <span class="st">"upper"</span>)], <span class="dv">3</span>)</span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-50"><a href="#cb2-50" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-51"><a href="#cb2-51" aria-hidden="true" tabindex="-1"></a>  effect_table,</span>
<span id="cb2-52"><a href="#cb2-52" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Estimated treatment effects in the synthetic RD example"</span></span>
<span id="cb2-53"><a href="#cb2-53" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Estimated treatment effects in the synthetic RD example</caption>
<colgroup>
<col style="width: 14%">
<col style="width: 53%">
<col style="width: 12%">
<col style="width: 9%">
<col style="width: 9%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">model</th>
<th style="text-align: right;">estimate</th>
<th style="text-align: right;">lower</th>
<th style="text-align: right;">upper</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">1</td>
<td style="text-align: left;">True effect at the cutoff</td>
<td style="text-align: right;">-1.500</td>
<td style="text-align: right;">NA</td>
<td style="text-align: right;">NA</td>
</tr>
<tr class="even">
<td style="text-align: left;">eligible</td>
<td style="text-align: left;">Naive treated vs untreated comparison</td>
<td style="text-align: right;">2.040</td>
<td style="text-align: right;">1.900</td>
<td style="text-align: right;">2.181</td>
</tr>
<tr class="odd">
<td style="text-align: left;">eligible1</td>
<td style="text-align: left;">Global regression with score controls</td>
<td style="text-align: right;">-1.501</td>
<td style="text-align: right;">-1.658</td>
<td style="text-align: right;">-1.343</td>
</tr>
<tr class="even">
<td style="text-align: left;">11</td>
<td style="text-align: left;">Local linear RD (robust)</td>
<td style="text-align: right;">-1.400</td>
<td style="text-align: right;">-1.780</td>
<td style="text-align: right;">-1.020</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The local linear RD estimate should be close to the true effect because the data were generated exactly to satisfy the RD assumptions. The naive comparison is usually far less informative because treated and untreated units differ across the full support of the running variable.</p>
</section>
<section id="step-3-check-the-bandwidth-and-local-sample" class="level2" data-number="49.5">
<h2 data-number="49.5" class="anchored" data-anchor-id="step-3-check-the-bandwidth-and-local-sample"><span class="header-section-number">49.5</span> Step 3: Check the bandwidth and local sample</h2>
<p>One of the most important features of regression discontinuity is locality. The estimator should focus on observations near the cutoff rather than trying to compare the entire treated and untreated samples.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>bandwidth_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">side =</span> <span class="fu">c</span>(<span class="st">"Left of cutoff"</span>, <span class="st">"Right of cutoff"</span>),</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">bandwidth =</span> <span class="fu">c</span>(rd_fit<span class="sc">$</span>bws[<span class="st">"h"</span>, <span class="st">"left"</span>], rd_fit<span class="sc">$</span>bws[<span class="st">"h"</span>, <span class="st">"right"</span>]),</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">effective_n =</span> <span class="fu">c</span>(rd_fit<span class="sc">$</span>N_h[<span class="dv">1</span>], rd_fit<span class="sc">$</span>N_h[<span class="dv">2</span>])</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>bandwidth_table[, <span class="fu">c</span>(<span class="st">"bandwidth"</span>, <span class="st">"effective_n"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(bandwidth_table[, <span class="fu">c</span>(<span class="st">"bandwidth"</span>, <span class="st">"effective_n"</span>)], <span class="dv">3</span>)</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  bandwidth_table,</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Bandwidth and effective sample size used by the local RD estimator"</span></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Bandwidth and effective sample size used by the local RD estimator</caption>
<thead>
<tr class="header">
<th style="text-align: left;">side</th>
<th style="text-align: right;">bandwidth</th>
<th style="text-align: right;">effective_n</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Left of cutoff</td>
<td style="text-align: right;">5.145</td>
<td style="text-align: right;">434</td>
</tr>
<tr class="even">
<td style="text-align: left;">Right of cutoff</td>
<td style="text-align: right;">5.145</td>
<td style="text-align: right;">480</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table shows that the RD fit is not trying to learn from the whole sample. It is learning from a neighborhood around the threshold, which is exactly the point of the design.</p>
</section>
<section id="step-4-build-the-visual-discontinuity-plot" class="level2" data-number="49.6">
<h2 data-number="49.6" class="anchored" data-anchor-id="step-4-build-the-visual-discontinuity-plot"><span class="header-section-number">49.6</span> Step 4: Build the visual discontinuity plot</h2>
<p>A simulation chapter on RD should always make the jump visible. The code below creates binned averages and overlays local linear fits within the selected bandwidth.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>make_rd_bins <span class="ot">&lt;-</span> <span class="cf">function</span>(x, y, <span class="at">cutoff =</span> <span class="dv">0</span>, <span class="at">bins_per_side =</span> <span class="dv">15</span>) {</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  left_breaks <span class="ot">&lt;-</span> <span class="fu">seq</span>(<span class="fu">min</span>(x), cutoff, <span class="at">length.out =</span> bins_per_side <span class="sc">+</span> <span class="dv">1</span>)</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  right_breaks <span class="ot">&lt;-</span> <span class="fu">seq</span>(cutoff, <span class="fu">max</span>(x), <span class="at">length.out =</span> bins_per_side <span class="sc">+</span> <span class="dv">1</span>)</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  left_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> x[x <span class="sc">&lt;</span> cutoff],</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> y[x <span class="sc">&lt;</span> cutoff],</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">bin =</span> <span class="fu">cut</span>(</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>      x[x <span class="sc">&lt;</span> cutoff],</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>      <span class="at">breaks =</span> left_breaks,</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>      <span class="at">include.lowest =</span> <span class="cn">TRUE</span>,</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>      <span class="at">labels =</span> <span class="cn">FALSE</span></span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>  right_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> x[x <span class="sc">&gt;=</span> cutoff],</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> y[x <span class="sc">&gt;=</span> cutoff],</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">bin =</span> <span class="fu">cut</span>(</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>      x[x <span class="sc">&gt;=</span> cutoff],</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>      <span class="at">breaks =</span> right_breaks,</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>      <span class="at">include.lowest =</span> <span class="cn">TRUE</span>,</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>      <span class="at">labels =</span> <span class="cn">FALSE</span></span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>  left_bins <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(<span class="fu">cbind</span>(x, y) <span class="sc">~</span> bin, <span class="at">data =</span> left_data, <span class="at">FUN =</span> mean)</span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>  right_bins <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(<span class="fu">cbind</span>(x, y) <span class="sc">~</span> bin, <span class="at">data =</span> right_data, <span class="at">FUN =</span> mean)</span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-30"><a href="#cb4-30" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rbind</span>(left_bins[, <span class="fu">c</span>(<span class="st">"x"</span>, <span class="st">"y"</span>)], right_bins[, <span class="fu">c</span>(<span class="st">"x"</span>, <span class="st">"y"</span>)])</span>
<span id="cb4-31"><a href="#cb4-31" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb4-32"><a href="#cb4-32" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-33"><a href="#cb4-33" aria-hidden="true" tabindex="-1"></a>make_local_rd_lines <span class="ot">&lt;-</span> <span class="cf">function</span>(</span>
<span id="cb4-34"><a href="#cb4-34" aria-hidden="true" tabindex="-1"></a>  data,</span>
<span id="cb4-35"><a href="#cb4-35" aria-hidden="true" tabindex="-1"></a>  x_var,</span>
<span id="cb4-36"><a href="#cb4-36" aria-hidden="true" tabindex="-1"></a>  y_var,</span>
<span id="cb4-37"><a href="#cb4-37" aria-hidden="true" tabindex="-1"></a>  left_bandwidth,</span>
<span id="cb4-38"><a href="#cb4-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">right_bandwidth =</span> left_bandwidth,</span>
<span id="cb4-39"><a href="#cb4-39" aria-hidden="true" tabindex="-1"></a>  <span class="at">cutoff =</span> <span class="dv">0</span></span>
<span id="cb4-40"><a href="#cb4-40" aria-hidden="true" tabindex="-1"></a>) {</span>
<span id="cb4-41"><a href="#cb4-41" aria-hidden="true" tabindex="-1"></a>  running <span class="ot">&lt;-</span> data[[x_var]]</span>
<span id="cb4-42"><a href="#cb4-42" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-43"><a href="#cb4-43" aria-hidden="true" tabindex="-1"></a>  left_sample <span class="ot">&lt;-</span> data[running <span class="sc">&lt;</span> cutoff <span class="sc">&amp;</span> <span class="fu">abs</span>(running <span class="sc">-</span> cutoff) <span class="sc">&lt;=</span> left_bandwidth, ]</span>
<span id="cb4-44"><a href="#cb4-44" aria-hidden="true" tabindex="-1"></a>  right_sample <span class="ot">&lt;-</span> data[running <span class="sc">&gt;=</span> cutoff <span class="sc">&amp;</span> <span class="fu">abs</span>(running <span class="sc">-</span> cutoff) <span class="sc">&lt;=</span> right_bandwidth, ]</span>
<span id="cb4-45"><a href="#cb4-45" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-46"><a href="#cb4-46" aria-hidden="true" tabindex="-1"></a>  left_model <span class="ot">&lt;-</span> <span class="fu">lm</span>(stats<span class="sc">::</span><span class="fu">reformulate</span>(x_var, <span class="at">response =</span> y_var), <span class="at">data =</span> left_sample)</span>
<span id="cb4-47"><a href="#cb4-47" aria-hidden="true" tabindex="-1"></a>  right_model <span class="ot">&lt;-</span> <span class="fu">lm</span>(stats<span class="sc">::</span><span class="fu">reformulate</span>(x_var, <span class="at">response =</span> y_var), <span class="at">data =</span> right_sample)</span>
<span id="cb4-48"><a href="#cb4-48" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-49"><a href="#cb4-49" aria-hidden="true" tabindex="-1"></a>  left_grid <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(<span class="fu">seq</span>(cutoff <span class="sc">-</span> left_bandwidth, cutoff, <span class="at">length.out =</span> <span class="dv">100</span>))</span>
<span id="cb4-50"><a href="#cb4-50" aria-hidden="true" tabindex="-1"></a>  <span class="fu">names</span>(left_grid) <span class="ot">&lt;-</span> x_var</span>
<span id="cb4-51"><a href="#cb4-51" aria-hidden="true" tabindex="-1"></a>  left_grid<span class="sc">$</span>fit <span class="ot">&lt;-</span> <span class="fu">predict</span>(left_model, <span class="at">newdata =</span> left_grid)</span>
<span id="cb4-52"><a href="#cb4-52" aria-hidden="true" tabindex="-1"></a>  left_grid<span class="sc">$</span>side <span class="ot">&lt;-</span> <span class="st">"Left of cutoff"</span></span>
<span id="cb4-53"><a href="#cb4-53" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-54"><a href="#cb4-54" aria-hidden="true" tabindex="-1"></a>  right_grid <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(<span class="fu">seq</span>(cutoff, cutoff <span class="sc">+</span> right_bandwidth, <span class="at">length.out =</span> <span class="dv">100</span>))</span>
<span id="cb4-55"><a href="#cb4-55" aria-hidden="true" tabindex="-1"></a>  <span class="fu">names</span>(right_grid) <span class="ot">&lt;-</span> x_var</span>
<span id="cb4-56"><a href="#cb4-56" aria-hidden="true" tabindex="-1"></a>  right_grid<span class="sc">$</span>fit <span class="ot">&lt;-</span> <span class="fu">predict</span>(right_model, <span class="at">newdata =</span> right_grid)</span>
<span id="cb4-57"><a href="#cb4-57" aria-hidden="true" tabindex="-1"></a>  right_grid<span class="sc">$</span>side <span class="ot">&lt;-</span> <span class="st">"Right of cutoff"</span></span>
<span id="cb4-58"><a href="#cb4-58" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-59"><a href="#cb4-59" aria-hidden="true" tabindex="-1"></a>  plot_data <span class="ot">&lt;-</span> <span class="fu">rbind</span>(left_grid, right_grid)</span>
<span id="cb4-60"><a href="#cb4-60" aria-hidden="true" tabindex="-1"></a>  <span class="fu">names</span>(plot_data)[<span class="fu">names</span>(plot_data) <span class="sc">==</span> x_var] <span class="ot">&lt;-</span> <span class="st">"x"</span></span>
<span id="cb4-61"><a href="#cb4-61" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-62"><a href="#cb4-62" aria-hidden="true" tabindex="-1"></a>  plot_data</span>
<span id="cb4-63"><a href="#cb4-63" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb4-64"><a href="#cb4-64" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-65"><a href="#cb4-65" aria-hidden="true" tabindex="-1"></a>binned_rd <span class="ot">&lt;-</span> <span class="fu">make_rd_bins</span>(</span>
<span id="cb4-66"><a href="#cb4-66" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> synthetic_rd<span class="sc">$</span>risk_score,</span>
<span id="cb4-67"><a href="#cb4-67" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> synthetic_rd<span class="sc">$</span>hospital_days,</span>
<span id="cb4-68"><a href="#cb4-68" aria-hidden="true" tabindex="-1"></a>  <span class="at">cutoff =</span> <span class="dv">0</span>,</span>
<span id="cb4-69"><a href="#cb4-69" aria-hidden="true" tabindex="-1"></a>  <span class="at">bins_per_side =</span> <span class="dv">18</span></span>
<span id="cb4-70"><a href="#cb4-70" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-71"><a href="#cb4-71" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-72"><a href="#cb4-72" aria-hidden="true" tabindex="-1"></a>local_lines <span class="ot">&lt;-</span> <span class="fu">make_local_rd_lines</span>(</span>
<span id="cb4-73"><a href="#cb4-73" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_rd,</span>
<span id="cb4-74"><a href="#cb4-74" aria-hidden="true" tabindex="-1"></a>  <span class="at">x_var =</span> <span class="st">"risk_score"</span>,</span>
<span id="cb4-75"><a href="#cb4-75" aria-hidden="true" tabindex="-1"></a>  <span class="at">y_var =</span> <span class="st">"hospital_days"</span>,</span>
<span id="cb4-76"><a href="#cb4-76" aria-hidden="true" tabindex="-1"></a>  <span class="at">left_bandwidth =</span> rd_fit<span class="sc">$</span>bws[<span class="st">"h"</span>, <span class="st">"left"</span>],</span>
<span id="cb4-77"><a href="#cb4-77" aria-hidden="true" tabindex="-1"></a>  <span class="at">right_bandwidth =</span> rd_fit<span class="sc">$</span>bws[<span class="st">"h"</span>, <span class="st">"right"</span>],</span>
<span id="cb4-78"><a href="#cb4-78" aria-hidden="true" tabindex="-1"></a>  <span class="at">cutoff =</span> <span class="dv">0</span></span>
<span id="cb4-79"><a href="#cb4-79" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-80"><a href="#cb4-80" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-81"><a href="#cb4-81" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(synthetic_rd, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> risk_score, <span class="at">y =</span> hospital_days)) <span class="sc">+</span></span>
<span id="cb4-82"><a href="#cb4-82" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(<span class="at">alpha =</span> <span class="fl">0.08</span>, <span class="at">color =</span> <span class="st">"#8c8c8c"</span>, <span class="at">size =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb4-83"><a href="#cb4-83" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(</span>
<span id="cb4-84"><a href="#cb4-84" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> binned_rd,</span>
<span id="cb4-85"><a href="#cb4-85" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y),</span>
<span id="cb4-86"><a href="#cb4-86" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#0b5d4b"</span>,</span>
<span id="cb4-87"><a href="#cb4-87" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="fl">2.2</span></span>
<span id="cb4-88"><a href="#cb4-88" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-89"><a href="#cb4-89" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(</span>
<span id="cb4-90"><a href="#cb4-90" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> local_lines,</span>
<span id="cb4-91"><a href="#cb4-91" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> fit, <span class="at">color =</span> side),</span>
<span id="cb4-92"><a href="#cb4-92" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">1.1</span></span>
<span id="cb4-93"><a href="#cb4-93" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-94"><a href="#cb4-94" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="dv">0</span>, <span class="at">linetype =</span> <span class="dv">2</span>, <span class="at">color =</span> <span class="st">"#b54708"</span>) <span class="sc">+</span></span>
<span id="cb4-95"><a href="#cb4-95" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_color_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"Left of cutoff"</span> <span class="ot">=</span> <span class="st">"#3d5a80"</span>, <span class="st">"Right of cutoff"</span> <span class="ot">=</span> <span class="st">"#bc6c25"</span>)) <span class="sc">+</span></span>
<span id="cb4-96"><a href="#cb4-96" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb4-97"><a href="#cb4-97" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Synthetic regression discontinuity design"</span>,</span>
<span id="cb4-98"><a href="#cb4-98" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Binned averages and local linear fits reveal the treatment jump at the cutoff"</span>,</span>
<span id="cb4-99"><a href="#cb4-99" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Risk score running variable"</span>,</span>
<span id="cb4-100"><a href="#cb4-100" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Hospital days in the next year"</span>,</span>
<span id="cb4-101"><a href="#cb4-101" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="cn">NULL</span></span>
<span id="cb4-102"><a href="#cb4-102" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-103"><a href="#cb4-103" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/simulating-rd-data_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This is the key figure in the chapter. It shows both the smooth evolution of the outcome away from the threshold and the discrete jump exactly at the cutoff.</p>
</section>
<section id="step-5-compare-the-local-fitted-means-just-below-and-just-above-the-cutoff" class="level2" data-number="49.7">
<h2 data-number="49.7" class="anchored" data-anchor-id="step-5-compare-the-local-fitted-means-just-below-and-just-above-the-cutoff"><span class="header-section-number">49.7</span> Step 5: Compare the local fitted means just below and just above the cutoff</h2>
<p>The final recovery check is to compare the fitted left and right limits implied by the local RD regression.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>left_limit <span class="ot">&lt;-</span> local_lines<span class="sc">$</span>fit[local_lines<span class="sc">$</span>side <span class="sc">==</span> <span class="st">"Left of cutoff"</span>][<span class="fu">length</span>(local_lines<span class="sc">$</span>fit[local_lines<span class="sc">$</span>side <span class="sc">==</span> <span class="st">"Left of cutoff"</span>])]</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>right_limit <span class="ot">&lt;-</span> local_lines<span class="sc">$</span>fit[local_lines<span class="sc">$</span>side <span class="sc">==</span> <span class="st">"Right of cutoff"</span>][<span class="dv">1</span>]</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>limit_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">quantity =</span> <span class="fu">c</span>(</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Estimated left limit at the cutoff"</span>,</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Estimated right limit at the cutoff"</span>,</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Estimated discontinuity"</span>,</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>    <span class="st">"True discontinuity"</span></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">value =</span> <span class="fu">c</span>(</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>    left_limit,</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>    right_limit,</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>    right_limit <span class="sc">-</span> left_limit,</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>    true_effect</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>limit_table<span class="sc">$</span>value <span class="ot">&lt;-</span> <span class="fu">round</span>(limit_table<span class="sc">$</span>value, <span class="dv">3</span>)</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>  limit_table,</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Local fitted means and discontinuity at the threshold"</span></span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Local fitted means and discontinuity at the threshold</caption>
<thead>
<tr class="header">
<th style="text-align: left;">quantity</th>
<th style="text-align: right;">value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Estimated left limit at the cutoff</td>
<td style="text-align: right;">6.017</td>
</tr>
<tr class="even">
<td style="text-align: left;">Estimated right limit at the cutoff</td>
<td style="text-align: right;">4.492</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Estimated discontinuity</td>
<td style="text-align: right;">-1.525</td>
</tr>
<tr class="even">
<td style="text-align: left;">True discontinuity</td>
<td style="text-align: right;">-1.500</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table translates the geometry of the RD graph back into the estimand: the treatment effect is the jump between the left and right limits at the cutoff.</p>
</section>
<section id="main-assumptions-behind-this-simulation" class="level2" data-number="49.8">
<h2 data-number="49.8" class="anchored" data-anchor-id="main-assumptions-behind-this-simulation"><span class="header-section-number">49.8</span> Main assumptions behind this simulation</h2>
<p>The first assumption is continuity of untreated potential outcomes at the threshold. In this synthetic design, that is true by construction because the untreated mean is a smooth quadratic function of the running variable.</p>
<p>The second is sharp treatment assignment:</p>
<p><span class="math display">\[
D_i = \mathbb{1}(X_i \ge 0).
\]</span></p>
<p>The third is that individuals do not manipulate the running variable around the threshold. That is also built into the simulation because the score is drawn continuously and independently of the treatment rule.</p>
<p>These assumptions are useful for learning because they create the cleanest possible RD benchmark. Real data may violate them through sorting, heaping, measurement error in the running variable, or misspecified functional form.</p>
</section>
<section id="how-to-adapt-this-template" class="level2" data-number="49.9">
<h2 data-number="49.9" class="anchored" data-anchor-id="how-to-adapt-this-template"><span class="header-section-number">49.9</span> How to adapt this template</h2>
<p>Once the basic structure is clear, the same template can be modified in many useful ways. You can weaken the design by introducing manipulation near the cutoff. You can simulate a fuzzy RD in which crossing the threshold only raises treatment probability. You can change the untreated regression function to be more curved and then study bandwidth sensitivity. You can add covariates, clustered assignment, or heterogeneous treatment effects that vary with the score.</p>
<p>This is often the best way to build intuition for RD. The method is usually taught through continuity arguments and local-polynomial estimators, but simulation lets you see exactly how those ingredients behave when the truth is known.</p>
</section>
<section id="further-reading" class="level2" data-number="49.10">
<h2 data-number="49.10" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">49.10</span> Further reading</h2>
<p>Lee's close-election design remains one of the clearest motivating examples of RD logic in practice <span class="citation" data-cites="lee2008">Lee (<a href="#ref-lee2008" role="doc-biblioref">2008</a>)</span>. Imbens and Lemieux provide a widely used guide to implementation and interpretation <span class="citation" data-cites="imbens2008">Imbens and Lemieux (<a href="#ref-imbens2008" role="doc-biblioref">2008</a>)</span>. Calonico, Cattaneo, and Titiunik explain why robust bias-corrected inference became standard in modern RD work <span class="citation" data-cites="calonico2014">Calonico, Cattaneo, and Titiunik (<a href="#ref-calonico2014" role="doc-biblioref">2014</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-calonico2014" class="csl-entry" role="listitem">
Calonico, Sebastian, Matias D. Cattaneo, and Rocio Titiunik. 2014. <span>"Robust Nonparametric Confidence Intervals for Regression-Discontinuity Designs."</span> <em>Econometrica</em> 82 (6): 2295-2326. <a href="https://doi.org/10.3982/ECTA11757">https://doi.org/10.3982/ECTA11757</a>.
</div>
<div id="ref-imbens2008" class="csl-entry" role="listitem">
Imbens, Guido W., and Thomas Lemieux. 2008. <span>"Regression Discontinuity Designs: A Guide to Practice."</span> <em>Journal of Econometrics</em> 142 (2): 615-35. <a href="https://doi.org/10.1016/j.jeconom.2007.05.001">https://doi.org/10.1016/j.jeconom.2007.05.001</a>.
</div>
<div id="ref-lee2008" class="csl-entry" role="listitem">
Lee, David S. 2008. <span>"Randomized Experiments from Non-Random Selection in u.s. House Elections."</span> <em>Journal of Econometrics</em> 142 (2): 675-97. <a href="https://doi.org/10.1016/j.jeconom.2007.05.004">https://doi.org/10.1016/j.jeconom.2007.05.004</a>.
</div>
</div>
</section>
