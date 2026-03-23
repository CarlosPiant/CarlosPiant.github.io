---
title: "Simulating Difference-in-Differences Data"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter creates a synthetic panel dataset in which a subset of hospitals adopts a policy after a known implementation date, so the natural estimator is difference-in-differences. The design is inspired by..."
---
<p>This chapter creates a synthetic panel dataset in which a subset of hospitals adopts a policy after a known implementation date, so the natural estimator is difference-in-differences. The design is inspired by policy-evaluation settings such as Card and Krueger's minimum-wage comparison and the large DiD literature that followed <span class="citation" data-cites="cardkrueger1994">(<a href="#ref-cardkrueger1994" role="doc-biblioref"><strong>cardkrueger1994?</strong></a>)</span>; <span class="citation" data-cites="bertrand2004">Bertrand, Duflo, and Mullainathan (<a href="#ref-bertrand2004" role="doc-biblioref">2004</a>)</span>. The synthetic version here is not a replication of labor-market data. Instead, it creates a hospital-panel setting in which a care-coordination reform is introduced in treated hospitals after year 4, while untreated hospitals provide the comparison trend. That makes it useful for checking whether a fitted DiD model can recover the true treatment effect when the parallel-trends assumption is built into the data-generating process.</p>
<p>The practical reason to simulate DiD data is that policy analysis is often about changes over time, not only differences in levels. Simulation lets the analyst write down the untreated trend, the treatment timing, the adoption group, and the policy effect explicitly before fitting the estimator.</p>
<section id="what-variables-will-be-created" class="level2" data-number="50.1">
<h2 data-number="50.1" class="anchored" data-anchor-id="what-variables-will-be-created"><span class="header-section-number">50.1</span> What variables will be created</h2>
<p>The synthetic sample will represent hospitals observed annually over an eight-year period. <code>hospital</code> will index the hospitals. <code>year</code> will index calendar time. <code>treated_hospital</code> will indicate whether the hospital eventually adopts the policy. <code>post</code> will indicate whether the observation occurs after policy introduction. <code>did_treatment</code> will equal one only for treated hospitals in post-policy years. The outcome <code>avoidable_ed</code> will measure avoidable emergency department visits per 1,000 discharges.</p>
<p>These variables reproduce the essential structure of a two-group panel DiD design: group membership, time, treatment timing, and an outcome that evolves over time.</p>
</section>
<section id="the-data-generating-process" class="level2" data-number="50.2">
<h2 data-number="50.2" class="anchored" data-anchor-id="the-data-generating-process"><span class="header-section-number">50.2</span> The data-generating process</h2>
<p>The untreated outcome follows</p>
<p><span class="math display">\[
Y_{it}(0) = \alpha_i + \lambda_t + \varepsilon_{it},
\]</span></p>
<p>where <span class="math inline">\(\alpha_i\)</span> is a hospital fixed effect and <span class="math inline">\(\lambda_t\)</span> is a common time trend. The treatment effect enters only for treated hospitals after the policy begins:</p>
<p><span class="math display">\[
Y_{it}(1) = Y_{it}(0) + \tau.
\]</span></p>
<p>The observed outcome is</p>
<p><span class="math display">\[
Y_{it} = Y_{it}(0) + \tau D_{it},
\]</span></p>
<p>where</p>
<p><span class="math display">\[
D_{it} = \mathbb{1}(\text{treated hospital}) \times \mathbb{1}(\text{post period}).
\]</span></p>
<p>For this simulation, the policy effect is</p>
<p><span class="math display">\[
\tau = -4,
\]</span></p>
<p>meaning the reform lowers avoidable emergency department visits by 4 visits per 1,000 discharges.</p>
<p>The key identifying assumption is built into the DGP by construction: in the absence of treatment, the treated and untreated hospitals follow parallel trends over time. Baseline levels are allowed to differ through hospital fixed effects, but untreated time trends are common.</p>
</section>
<section id="step-1-generate-the-synthetic-panel" class="level2" data-number="50.3">
<h2 data-number="50.3" class="anchored" data-anchor-id="step-1-generate-the-synthetic-panel"><span class="header-section-number">50.3</span> Step 1: Generate the synthetic panel</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n_hospitals <span class="ot">&lt;-</span> <span class="dv">80</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>n_years <span class="ot">&lt;-</span> <span class="dv">8</span></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>hospital_id <span class="ot">&lt;-</span> <span class="fu">rep</span>(<span class="fu">seq_len</span>(n_hospitals), <span class="at">each =</span> n_years)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>year_num <span class="ot">&lt;-</span> <span class="fu">rep</span>(<span class="fu">seq_len</span>(n_years), <span class="at">times =</span> n_hospitals)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>treated_hospital <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(hospital_id <span class="sc">&lt;=</span> n_hospitals <span class="sc">/</span> <span class="dv">2</span>, <span class="dv">1</span>, <span class="dv">0</span>)</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>post <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(year_num <span class="sc">&gt;=</span> <span class="dv">5</span>, <span class="dv">1</span>, <span class="dv">0</span>)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>did_treatment <span class="ot">&lt;-</span> treated_hospital <span class="sc">*</span> post</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>hospital_fe <span class="ot">&lt;-</span> <span class="fu">rep</span>(<span class="fu">rnorm</span>(n_hospitals, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="fl">5.5</span>), <span class="at">each =</span> n_years)</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>time_trend <span class="ot">&lt;-</span> <span class="fu">rep</span>(<span class="fu">seq</span>(<span class="dv">0</span>, <span class="sc">-</span><span class="fl">6.5</span>, <span class="at">length.out =</span> n_years), <span class="at">times =</span> n_hospitals)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>true_effect <span class="ot">&lt;-</span> <span class="sc">-</span><span class="dv">4</span></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>avoidable_ed <span class="ot">&lt;-</span> <span class="dv">46</span> <span class="sc">+</span></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  hospital_fe <span class="sc">+</span></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  time_trend <span class="sc">+</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  true_effect <span class="sc">*</span> did_treatment <span class="sc">+</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rnorm</span>(n_hospitals <span class="sc">*</span> n_years, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="fl">2.6</span>)</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>synthetic_did <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">hospital =</span> <span class="fu">factor</span>(hospital_id),</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">year =</span> <span class="fu">factor</span>(year_num),</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  year_num,</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  treated_hospital,</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>  post,</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>  did_treatment,</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>  avoidable_ed</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>simulation_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>  <span class="at">hospitals =</span> n_hospitals,</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>  <span class="at">years =</span> n_years,</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">treated_share =</span> <span class="fu">mean</span>(<span class="fu">unique</span>(treated_hospital)),</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_outcome =</span> <span class="fu">mean</span>(synthetic_did<span class="sc">$</span>avoidable_ed),</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">sd_outcome =</span> stats<span class="sc">::</span><span class="fu">sd</span>(synthetic_did<span class="sc">$</span>avoidable_ed)</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>simulation_summary[, <span class="fu">c</span>(<span class="st">"treated_share"</span>, <span class="st">"mean_outcome"</span>, <span class="st">"sd_outcome"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(simulation_summary[, <span class="fu">c</span>(<span class="st">"treated_share"</span>, <span class="st">"mean_outcome"</span>, <span class="st">"sd_outcome"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>  simulation_summary,</span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the synthetic difference-in-differences panel"</span></span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the synthetic difference-in-differences panel</caption>
<thead>
<tr class="header">
<th style="text-align: right;">hospitals</th>
<th style="text-align: right;">years</th>
<th style="text-align: right;">treated_share</th>
<th style="text-align: right;">mean_outcome</th>
<th style="text-align: right;">sd_outcome</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">80</td>
<td style="text-align: right;">8</td>
<td style="text-align: right;">0.5</td>
<td style="text-align: right;">41.391</td>
<td style="text-align: right;">6.665</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The panel now contains two ingredients that matter for DiD. First, treated and untreated hospitals have different baseline levels because of hospital fixed effects. Second, untreated trends move in parallel over time because the same calendar trend applies to both groups before the policy begins.</p>
</section>
<section id="step-2-fit-the-model-that-matches-the-true-generating-process" class="level2" data-number="50.4">
<h2 data-number="50.4" class="anchored" data-anchor-id="step-2-fit-the-model-that-matches-the-true-generating-process"><span class="header-section-number">50.4</span> Step 2: Fit the model that matches the true generating process</h2>
<p>The natural recovery check is a two-way fixed-effects DiD regression. For context, it is also useful to compare that estimate with a naive post-period comparison.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>extract_clustered_effect <span class="ot">&lt;-</span> <span class="cf">function</span>(model, term, cluster, model_name) {</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  robust_vcov <span class="ot">&lt;-</span> sandwich<span class="sc">::</span><span class="fu">vcovCL</span>(model, <span class="at">cluster =</span> cluster, <span class="at">type =</span> <span class="st">"HC1"</span>)</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  estimate <span class="ot">&lt;-</span> <span class="fu">coef</span>(model)[term]</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  se <span class="ot">&lt;-</span> <span class="fu">sqrt</span>(robust_vcov[term, term])</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">model =</span> model_name,</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> estimate,</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower =</span> estimate <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> se,</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper =</span> estimate <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> se</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>naive_post_model <span class="ot">&lt;-</span> <span class="fu">lm</span>(</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  avoidable_ed <span class="sc">~</span> treated_hospital,</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> <span class="fu">subset</span>(synthetic_did, post <span class="sc">==</span> <span class="dv">1</span>)</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>did_model <span class="ot">&lt;-</span> <span class="fu">lm</span>(</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  avoidable_ed <span class="sc">~</span> did_treatment <span class="sc">+</span> hospital <span class="sc">+</span> year,</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_did</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>effect_table <span class="ot">&lt;-</span> <span class="fu">rbind</span>(</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">model =</span> <span class="st">"True effect"</span>,</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> true_effect,</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower =</span> <span class="cn">NA_real_</span>,</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper =</span> <span class="cn">NA_real_</span></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_clustered_effect</span>(</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>    naive_post_model,</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>    <span class="st">"treated_hospital"</span>,</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>    <span class="at">cluster =</span> <span class="sc">~</span> hospital,</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">model_name =</span> <span class="st">"Naive post-period comparison"</span></span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_clustered_effect</span>(</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>    did_model,</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>    <span class="st">"did_treatment"</span>,</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>    <span class="at">cluster =</span> <span class="sc">~</span> hospital,</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>    <span class="at">model_name =</span> <span class="st">"Difference-in-differences"</span></span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>effect_table[, <span class="fu">c</span>(<span class="st">"estimate"</span>, <span class="st">"lower"</span>, <span class="st">"upper"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(effect_table[, <span class="fu">c</span>(<span class="st">"estimate"</span>, <span class="st">"lower"</span>, <span class="st">"upper"</span>)], <span class="dv">3</span>)</span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a>  effect_table,</span>
<span id="cb2-50"><a href="#cb2-50" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Estimated treatment effects in the synthetic DiD panel"</span></span>
<span id="cb2-51"><a href="#cb2-51" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Estimated treatment effects in the synthetic DiD panel</caption>
<colgroup>
<col style="width: 24%">
<col style="width: 42%">
<col style="width: 13%">
<col style="width: 10%">
<col style="width: 10%">
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
<td style="text-align: left;">True effect</td>
<td style="text-align: right;">-4.000</td>
<td style="text-align: right;">NA</td>
<td style="text-align: right;">NA</td>
</tr>
<tr class="even">
<td style="text-align: left;">treated_hospital</td>
<td style="text-align: left;">Naive post-period comparison</td>
<td style="text-align: right;">-3.824</td>
<td style="text-align: right;">-6.227</td>
<td style="text-align: right;">-1.421</td>
</tr>
<tr class="odd">
<td style="text-align: left;">did_treatment</td>
<td style="text-align: left;">Difference-in-differences</td>
<td style="text-align: right;">-4.551</td>
<td style="text-align: right;">-5.428</td>
<td style="text-align: right;">-3.675</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The DiD estimate should be close to the true effect because the data were generated exactly to satisfy the design assumptions. The naive post-period comparison is less informative because it compares hospitals with different baseline levels after the policy has already been implemented.</p>
</section>
<section id="step-3-check-the-pre-treatment-trend-structure" class="level2" data-number="50.5">
<h2 data-number="50.5" class="anchored" data-anchor-id="step-3-check-the-pre-treatment-trend-structure"><span class="header-section-number">50.5</span> Step 3: Check the pre-treatment trend structure</h2>
<p>Difference-in-differences relies on changes over time, not just treated-versus-untreated level differences. The most important descriptive check is therefore the group trend plot.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>trend_data <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  avoidable_ed <span class="sc">~</span> year_num <span class="sc">+</span> treated_hospital,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_did,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">FUN =</span> mean</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>trend_data<span class="sc">$</span>group <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  trend_data<span class="sc">$</span>treated_hospital <span class="sc">==</span> <span class="dv">1</span>,</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Treated hospitals"</span>,</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Comparison hospitals"</span></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>  trend_data,</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> year_num, <span class="at">y =</span> avoidable_ed, <span class="at">color =</span> group)</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>) <span class="sc">+</span></span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(<span class="at">linewidth =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(<span class="at">size =</span> <span class="dv">2</span>) <span class="sc">+</span></span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="fl">4.5</span>, <span class="at">linetype =</span> <span class="st">"dashed"</span>, <span class="at">color =</span> <span class="st">"#4c566a"</span>) <span class="sc">+</span></span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_color_manual</span>(</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">values =</span> <span class="fu">c</span>(<span class="st">"Treated hospitals"</span> <span class="ot">=</span> <span class="st">"#8a5a44"</span>, <span class="st">"Comparison hospitals"</span> <span class="ot">=</span> <span class="st">"#2f6f4f"</span>)</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Synthetic difference-in-differences design"</span>,</span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"The policy is introduced for treated hospitals after year 4"</span>,</span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Year"</span>,</span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Avoidable ED visits per 1,000 discharges"</span>,</span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="cn">NULL</span></span>
<span id="cb3-29"><a href="#cb3-29" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-30"><a href="#cb3-30" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/simulating-did-data_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The figure should show parallel movement before treatment and a post-policy divergence afterward. That is the visual signature of a well-behaved DiD design.</p>
</section>
<section id="step-4-recover-the-2x2-did-contrast-directly-from-means" class="level2" data-number="50.6">
<h2 data-number="50.6" class="anchored" data-anchor-id="step-4-recover-the-2x2-did-contrast-directly-from-means"><span class="header-section-number">50.6</span> Step 4: Recover the 2x2 DiD contrast directly from means</h2>
<p>Because this is a classic two-group panel, it is useful to compute the DiD contrast directly from sample means as a second recovery check.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>mean_table <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  avoidable_ed <span class="sc">~</span> treated_hospital <span class="sc">+</span> post,</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_did,</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  mean</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>mean_table<span class="sc">$</span>group <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(mean_table<span class="sc">$</span>treated_hospital <span class="sc">==</span> <span class="dv">1</span>, <span class="st">"Treated"</span>, <span class="st">"Comparison"</span>)</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>mean_table<span class="sc">$</span>period <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(mean_table<span class="sc">$</span>post <span class="sc">==</span> <span class="dv">1</span>, <span class="st">"Post"</span>, <span class="st">"Pre"</span>)</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>mean_table<span class="sc">$</span>avoidable_ed <span class="ot">&lt;-</span> <span class="fu">round</span>(mean_table<span class="sc">$</span>avoidable_ed, <span class="dv">3</span>)</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>  mean_table[, <span class="fu">c</span>(<span class="st">"group"</span>, <span class="st">"period"</span>, <span class="st">"avoidable_ed"</span>)],</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Mean outcome by group and period in the synthetic DiD panel"</span></span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Mean outcome by group and period in the synthetic DiD panel</caption>
<thead>
<tr class="header">
<th style="text-align: left;">group</th>
<th style="text-align: left;">period</th>
<th style="text-align: right;">avoidable_ed</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Comparison</td>
<td style="text-align: left;">Pre</td>
<td style="text-align: right;">44.051</td>
</tr>
<tr class="even">
<td style="text-align: left;">Treated</td>
<td style="text-align: left;">Pre</td>
<td style="text-align: right;">44.778</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Comparison</td>
<td style="text-align: left;">Post</td>
<td style="text-align: right;">40.280</td>
</tr>
<tr class="even">
<td style="text-align: left;">Treated</td>
<td style="text-align: left;">Post</td>
<td style="text-align: right;">36.456</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>treated_post <span class="ot">&lt;-</span> mean_table<span class="sc">$</span>avoidable_ed[mean_table<span class="sc">$</span>treated_hospital <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> mean_table<span class="sc">$</span>post <span class="sc">==</span> <span class="dv">1</span>]</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>treated_pre <span class="ot">&lt;-</span> mean_table<span class="sc">$</span>avoidable_ed[mean_table<span class="sc">$</span>treated_hospital <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> mean_table<span class="sc">$</span>post <span class="sc">==</span> <span class="dv">0</span>]</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>control_post <span class="ot">&lt;-</span> mean_table<span class="sc">$</span>avoidable_ed[mean_table<span class="sc">$</span>treated_hospital <span class="sc">==</span> <span class="dv">0</span> <span class="sc">&amp;</span> mean_table<span class="sc">$</span>post <span class="sc">==</span> <span class="dv">1</span>]</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>control_pre <span class="ot">&lt;-</span> mean_table<span class="sc">$</span>avoidable_ed[mean_table<span class="sc">$</span>treated_hospital <span class="sc">==</span> <span class="dv">0</span> <span class="sc">&amp;</span> mean_table<span class="sc">$</span>post <span class="sc">==</span> <span class="dv">0</span>]</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>did_from_means <span class="ot">&lt;-</span> (treated_post <span class="sc">-</span> treated_pre) <span class="sc">-</span> (control_post <span class="sc">-</span> control_pre)</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>did_check <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">quantity =</span> <span class="fu">c</span>(</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Treated change"</span>,</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Comparison change"</span>,</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Difference-in-differences from sample means"</span>,</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>    <span class="st">"True effect"</span></span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">value =</span> <span class="fu">c</span>(</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>    treated_post <span class="sc">-</span> treated_pre,</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>    control_post <span class="sc">-</span> control_pre,</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>    did_from_means,</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>    true_effect</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>did_check<span class="sc">$</span>value <span class="ot">&lt;-</span> <span class="fu">round</span>(did_check<span class="sc">$</span>value, <span class="dv">3</span>)</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>  did_check,</span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Direct two-by-two difference-in-differences recovery check"</span></span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Direct two-by-two difference-in-differences recovery check</caption>
<thead>
<tr class="header">
<th style="text-align: left;">quantity</th>
<th style="text-align: right;">value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Treated change</td>
<td style="text-align: right;">-8.322</td>
</tr>
<tr class="even">
<td style="text-align: left;">Comparison change</td>
<td style="text-align: right;">-3.771</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Difference-in-differences from sample means</td>
<td style="text-align: right;">-4.551</td>
</tr>
<tr class="even">
<td style="text-align: left;">True effect</td>
<td style="text-align: right;">-4.000</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table is useful because it reminds the reader that the fixed-effects regression is just a structured way of computing the same underlying contrast.</p>
</section>
<section id="step-5-show-what-happens-when-the-treated-and-untreated-groups-are-compared-only-after-the-policy" class="level2" data-number="50.7">
<h2 data-number="50.7" class="anchored" data-anchor-id="step-5-show-what-happens-when-the-treated-and-untreated-groups-are-compared-only-after-the-policy"><span class="header-section-number">50.7</span> Step 5: Show what happens when the treated and untreated groups are compared only after the policy</h2>
<p>Simulation is most useful when it reveals the failure mode of the naive estimator. The post-period-only comparison confounds the treatment effect with the pre-existing level difference between hospital groups.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>post_group_means <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  avoidable_ed <span class="sc">~</span> treated_hospital,</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> <span class="fu">subset</span>(synthetic_did, post <span class="sc">==</span> <span class="dv">1</span>),</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  mean</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>post_group_means<span class="sc">$</span>group <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(post_group_means<span class="sc">$</span>treated_hospital <span class="sc">==</span> <span class="dv">1</span>, <span class="st">"Treated"</span>, <span class="st">"Comparison"</span>)</span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>post_group_means<span class="sc">$</span>avoidable_ed <span class="ot">&lt;-</span> <span class="fu">round</span>(post_group_means<span class="sc">$</span>avoidable_ed, <span class="dv">3</span>)</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>  post_group_means[, <span class="fu">c</span>(<span class="st">"group"</span>, <span class="st">"avoidable_ed"</span>)],</span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Naive post-policy group means"</span></span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Naive post-policy group means</caption>
<thead>
<tr class="header">
<th style="text-align: left;">group</th>
<th style="text-align: right;">avoidable_ed</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Comparison</td>
<td style="text-align: right;">40.280</td>
</tr>
<tr class="even">
<td style="text-align: left;">Treated</td>
<td style="text-align: right;">36.456</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This is the comparison that DiD is designed to improve on. Looking only after treatment ignores baseline differences that were already present before the policy began.</p>
</section>
<section id="main-assumptions-behind-this-simulation" class="level2" data-number="50.8">
<h2 data-number="50.8" class="anchored" data-anchor-id="main-assumptions-behind-this-simulation"><span class="header-section-number">50.8</span> Main assumptions behind this simulation</h2>
<p>The first assumption is parallel trends in untreated outcomes. In this synthetic design, that is true by construction because both groups share the same calendar trend before the policy.</p>
<p>The second is that treatment timing is well defined and begins only for the treated hospitals after year 4.</p>
<p>The third is that no other group-specific shock occurs exactly when the policy starts. The simulation omits such shocks so that the treatment effect is the only source of post-period divergence.</p>
<p>These assumptions are useful for learning because they create the cleanest DiD benchmark. Real applications may violate them through differential pretrends, compositional change, serial correlation, or concurrent policies.</p>
</section>
<section id="how-to-adapt-this-template" class="level2" data-number="50.9">
<h2 data-number="50.9" class="anchored" data-anchor-id="how-to-adapt-this-template"><span class="header-section-number">50.9</span> How to adapt this template</h2>
<p>Once the basic structure is clear, the same DiD simulation can be modified in many useful ways. You can introduce violations of parallel trends, stagger treatment timing, dynamic treatment effects, serially correlated errors, or treatment-effect heterogeneity. You can also simulate repeated cross-sections instead of panels, or compare simple two-way fixed effects with more modern estimators under staggered adoption.</p>
<p>This is often the best way to build intuition for DiD. The method is simple in notation but highly sensitive to the assumptions built into the panel structure. Simulation makes those assumptions visible.</p>
</section>
<section id="further-reading" class="level2" data-number="50.10">
<h2 data-number="50.10" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">50.10</span> Further reading</h2>
<p>Card and Krueger remain a classic empirical example of policy-induced comparison over time <span class="citation" data-cites="cardkrueger1994">(<a href="#ref-cardkrueger1994" role="doc-biblioref"><strong>cardkrueger1994?</strong></a>)</span>. Bertrand, Duflo, and Mullainathan remain essential for understanding inference and serial correlation in DiD panels <span class="citation" data-cites="bertrand2004">Bertrand, Duflo, and Mullainathan (<a href="#ref-bertrand2004" role="doc-biblioref">2004</a>)</span>. Goodman-Bacon shows why treatment timing matters so much once adoption becomes staggered <span class="citation" data-cites="goodmanbacon2021">Goodman-Bacon (<a href="#ref-goodmanbacon2021" role="doc-biblioref">2021</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-bertrand2004" class="csl-entry" role="listitem">
Bertrand, Marianne, Esther Duflo, and Sendhil Mullainathan. 2004. <span>"How Much Should We Trust Differences-in-Differences Estimates?"</span> <em>The Quarterly Journal of Economics</em> 119 (1): 249-75. <a href="https://doi.org/10.1162/003355304772839588">https://doi.org/10.1162/003355304772839588</a>.
</div>
<div id="ref-goodmanbacon2021" class="csl-entry" role="listitem">
Goodman-Bacon, Andrew. 2021. <span>"Difference-in-Differences with Variation in Treatment Timing."</span> <em>Journal of Econometrics</em> 225 (2): 254-77. <a href="https://doi.org/10.1016/j.jeconom.2021.03.014">https://doi.org/10.1016/j.jeconom.2021.03.014</a>.
</div>
</div>
</section>
