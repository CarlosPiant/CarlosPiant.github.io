---
title: "Survival Curves"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a Kaplan-Meier survival plot for a clinical time-to-event dataset and shows how to turn raw follow-up times into an interpretable curve. The figure is designed to answer a simple but important..."
---
<p>This chapter builds a Kaplan-Meier survival plot for a clinical time-to-event dataset and shows how to turn raw follow-up times into an interpretable curve. The figure is designed to answer a simple but important question: how quickly does an event accumulate over time, and how does that pattern differ across groups? In health economics, epidemiology, and outcomes research, survival curves are one of the most direct ways to display prognosis, treatment durability, readmission-free survival, or mortality. The example here uses the <code>lung</code> dataset archived in the <code>survival</code> package and is inspired by the core survival-modeling tradition established by Kaplan, Meier, and Cox <span class="citation" data-cites="kaplan1958">Kaplan and Meier (<a href="#ref-kaplan1958" role="doc-biblioref">1958</a>)</span>; <span class="citation" data-cites="cox1972">Cox (<a href="#ref-cox1972" role="doc-biblioref">1972</a>)</span>; <span class="citation" data-cites="therneau2024">Therneau (<a href="#ref-therneau2024" role="doc-biblioref">2024</a>)</span>.</p>
<p>The visualization we will build is a pair of Kaplan-Meier curves comparing readout over time across two groups in the study sample. The step shape matters. It reminds the reader that survival does not decline continuously in the observed data. It drops when events occur and stays flat between events.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="63.1">
<h2 data-number="63.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">63.1</span> What the visualization is showing</h2>
<p>The <code>lung</code> dataset contains survival follow-up information for patients in a North Central Cancer Treatment Group lung-cancer study. We will use:</p>
<p><code>time</code> as follow-up time in days, <code>status</code> as the event indicator, and <code>sex</code> as the grouping variable. In this dataset, <span class="math inline">\(status = 2\)</span> means the event occurred and <span class="math inline">\(status = 1\)</span> means the observation is censored. The Kaplan-Meier curve will show the estimated probability of remaining event-free over time.</p>
</section>
<section id="step-1-prepare-the-data" class="level2" data-number="63.2">
<h2 data-number="63.2" class="anchored" data-anchor-id="step-1-prepare-the-data"><span class="header-section-number">63.2</span> Step 1: Prepare the data</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a>lung_data <span class="ot">&lt;-</span> survival<span class="sc">::</span>lung[, <span class="fu">c</span>(<span class="st">"time"</span>, <span class="st">"status"</span>, <span class="st">"sex"</span>)]</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a>lung_data <span class="ot">&lt;-</span> <span class="fu">na.omit</span>(lung_data)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>lung_data<span class="sc">$</span>event <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(lung_data<span class="sc">$</span>status <span class="sc">==</span> <span class="dv">2</span>)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>lung_data<span class="sc">$</span>sex_label <span class="ot">&lt;-</span> <span class="fu">factor</span>(</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  lung_data<span class="sc">$</span>sex,</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">levels =</span> <span class="fu">c</span>(<span class="dv">1</span>, <span class="dv">2</span>),</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">labels =</span> <span class="fu">c</span>(<span class="st">"Male"</span>, <span class="st">"Female"</span>)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>summary_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(lung_data),</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">events =</span> <span class="fu">sum</span>(lung_data<span class="sc">$</span>event),</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">event_rate =</span> <span class="fu">mean</span>(lung_data<span class="sc">$</span>event),</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">median_followup =</span> <span class="fu">median</span>(lung_data<span class="sc">$</span>time)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>summary_table[, <span class="fu">c</span>(<span class="st">"event_rate"</span>, <span class="st">"median_followup"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(summary_table[, <span class="fu">c</span>(<span class="st">"event_rate"</span>, <span class="st">"median_followup"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  summary_table,</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the lung-cancer survival dataset"</span></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the lung-cancer survival dataset</caption>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">events</th>
<th style="text-align: right;">event_rate</th>
<th style="text-align: right;">median_followup</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">228</td>
<td style="text-align: right;">165</td>
<td style="text-align: right;">0.724</td>
<td style="text-align: right;">255.5</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The most important preparation step is to make the event coding explicit. A survival curve depends on two things: the observed time and whether that time ended in an event or in censoring.</p>
</section>
<section id="step-2-fit-the-kaplan-meier-curves" class="level2" data-number="63.3">
<h2 data-number="63.3" class="anchored" data-anchor-id="step-2-fit-the-kaplan-meier-curves"><span class="header-section-number">63.3</span> Step 2: Fit the Kaplan-Meier curves</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>km_fit <span class="ot">&lt;-</span> survival<span class="sc">::</span><span class="fu">survfit</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  survival<span class="sc">::</span><span class="fu">Surv</span>(time, event) <span class="sc">~</span> sex_label,</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> lung_data</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>km_summary <span class="ot">&lt;-</span> <span class="fu">summary</span>(km_fit)</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>km_plot_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">time =</span> km_summary<span class="sc">$</span>time,</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">surv =</span> km_summary<span class="sc">$</span>surv,</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">lower =</span> km_summary<span class="sc">$</span>lower,</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">upper =</span> km_summary<span class="sc">$</span>upper,</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">strata =</span> <span class="fu">sub</span>(<span class="st">"sex_label="</span>, <span class="st">""</span>, km_summary<span class="sc">$</span>strata)</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>landmark_table <span class="ot">&lt;-</span> <span class="fu">summary</span>(km_fit, <span class="at">times =</span> <span class="fu">c</span>(<span class="dv">90</span>, <span class="dv">180</span>, <span class="dv">365</span>))</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>landmark_df <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">group =</span> <span class="fu">sub</span>(<span class="st">"sex_label="</span>, <span class="st">""</span>, landmark_table<span class="sc">$</span>strata),</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">time =</span> landmark_table<span class="sc">$</span>time,</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">survival =</span> landmark_table<span class="sc">$</span>surv</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>landmark_df<span class="sc">$</span>survival <span class="ot">&lt;-</span> <span class="fu">round</span>(landmark_df<span class="sc">$</span>survival, <span class="dv">3</span>)</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>  landmark_df,</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Estimated survival probabilities at selected landmark times"</span></span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Estimated survival probabilities at selected landmark times</caption>
<thead>
<tr class="header">
<th style="text-align: left;">group</th>
<th style="text-align: right;">time</th>
<th style="text-align: right;">survival</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Male</td>
<td style="text-align: right;">90</td>
<td style="text-align: right;">0.848</td>
</tr>
<tr class="even">
<td style="text-align: left;">Male</td>
<td style="text-align: right;">180</td>
<td style="text-align: right;">0.644</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Male</td>
<td style="text-align: right;">365</td>
<td style="text-align: right;">0.336</td>
</tr>
<tr class="even">
<td style="text-align: left;">Female</td>
<td style="text-align: right;">90</td>
<td style="text-align: right;">0.933</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Female</td>
<td style="text-align: right;">180</td>
<td style="text-align: right;">0.842</td>
</tr>
<tr class="even">
<td style="text-align: left;">Female</td>
<td style="text-align: right;">365</td>
<td style="text-align: right;">0.526</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table complements the plot. A figure gives the full trajectory, while landmark values make it easier to quote specific survival probabilities in the text.</p>
</section>
<section id="step-3-build-the-survival-curve-figure" class="level2" data-number="63.4">
<h2 data-number="63.4" class="anchored" data-anchor-id="step-3-build-the-survival-curve-figure"><span class="header-section-number">63.4</span> Step 3: Build the survival curve figure</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(km_plot_data, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> time, <span class="at">y =</span> surv, <span class="at">color =</span> strata)) <span class="sc">+</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_step</span>(<span class="at">linewidth =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_step</span>(</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">y =</span> lower),</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">3</span>,</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.6</span>,</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.7</span></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_step</span>(</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">y =</span> upper),</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">3</span>,</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.6</span>,</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.7</span></span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Kaplan-Meier survival curves in the lung-cancer dataset"</span>,</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Dashed step lines show pointwise 95% confidence limits"</span>,</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Days of follow-up"</span>,</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Estimated survival probability"</span>,</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"Group"</span></span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_color_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"#7f5539"</span>, <span class="st">"#386641"</span>)) <span class="sc">+</span></span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">coord_cartesian</span>(<span class="at">ylim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/survival-curves_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure works because it preserves the structure of survival data instead of smoothing it away. The steps show when events happen. The vertical distance between curves shows the separation in survival experience. The dashed confidence limits show the uncertainty around those estimates.</p>
</section>
<section id="step-4-add-a-cumulative-event-view" class="level2" data-number="63.5">
<h2 data-number="63.5" class="anchored" data-anchor-id="step-4-add-a-cumulative-event-view"><span class="header-section-number">63.5</span> Step 4: Add a cumulative-event view</h2>
<p>Sometimes readers find it easier to interpret event accumulation directly. A simple transformation of the survival curve gives the cumulative incidence of the event:</p>
<p><span class="math display">\[
1 - \hat{S}(t).
\]</span></p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>km_plot_data<span class="sc">$</span>cumulative_event <span class="ot">&lt;-</span> <span class="dv">1</span> <span class="sc">-</span> km_plot_data<span class="sc">$</span>surv</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(km_plot_data, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> time, <span class="at">y =</span> cumulative_event, <span class="at">color =</span> strata)) <span class="sc">+</span></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_step</span>(<span class="at">linewidth =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Cumulative event curves derived from the Kaplan-Meier estimates"</span>,</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"The same information can be viewed as event accumulation rather than survival"</span>,</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Days of follow-up"</span>,</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Cumulative event probability"</span>,</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"Group"</span></span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_color_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"#7f5539"</span>, <span class="st">"#386641"</span>)) <span class="sc">+</span></span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">coord_cartesian</span>(<span class="at">ylim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/survival-curves_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This second view is often useful in policy or services settings where the event, such as readmission or treatment failure, is the quantity of direct interest.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="63.6">
<h2 data-number="63.6" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">63.6</span> How to read the figure carefully</h2>
<p>Kaplan-Meier curves are descriptive. They show the observed survival pattern in the sample after accounting for censoring, but they do not by themselves adjust for confounding or other prognostic differences across groups. They also assume non-informative censoring, which means the censoring mechanism should not be systematically tied to the unobserved future event process.</p>
<p>The curve also becomes less precise later in follow-up, especially when few patients remain under observation. That is why it is good practice to interpret the tail of a survival curve more cautiously than the early and middle portions.</p>
</section>
<section id="further-reading" class="level2" data-number="63.7">
<h2 data-number="63.7" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">63.7</span> Further reading</h2>
<p>Kaplan and Meier provide the classic foundation for this plot type <span class="citation" data-cites="kaplan1958">Kaplan and Meier (<a href="#ref-kaplan1958" role="doc-biblioref">1958</a>)</span>. Cox is the natural next step when the goal shifts from descriptive curves to adjusted hazard modeling <span class="citation" data-cites="cox1972">Cox (<a href="#ref-cox1972" role="doc-biblioref">1972</a>)</span>. The <code>survival</code> package documentation is also useful when moving from introductory figures to more complex survival displays <span class="citation" data-cites="therneau2024">Therneau (<a href="#ref-therneau2024" role="doc-biblioref">2024</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-cox1972" class="csl-entry" role="listitem">
Cox, D. R. 1972. <span>"Regression Models and Life-Tables."</span> <em>Journal of the Royal Statistical Society. Series B (Methodological)</em> 34 (2): 187-202. <a href="https://doi.org/10.1111/j.2517-6161.1972.tb00899.x">https://doi.org/10.1111/j.2517-6161.1972.tb00899.x</a>.
</div>
<div id="ref-kaplan1958" class="csl-entry" role="listitem">
Kaplan, E. L., and Paul Meier. 1958. <span>"Nonparametric Estimation from Incomplete Observations."</span> <em>Journal of the American Statistical Association</em> 53 (282): 457-81. <a href="https://doi.org/10.1080/01621459.1958.10501452">https://doi.org/10.1080/01621459.1958.10501452</a>.
</div>
<div id="ref-therneau2024" class="csl-entry" role="listitem">
Therneau, Terry M. 2024. <em>A Package for Survival Analysis in r</em>. CRAN. <a href="https://CRAN.R-project.org/package=survival">https://CRAN.R-project.org/package=survival</a>.
</div>
</div>
</section>
