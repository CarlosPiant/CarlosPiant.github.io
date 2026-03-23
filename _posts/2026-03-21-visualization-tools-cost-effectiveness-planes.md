---
title: "Cost-Effectiveness Planes"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a cost-effectiveness plane from a trial-style economic evaluation and shows how to visualize uncertainty in incremental costs and incremental effects at the same time. The figure is one of the..."
---
<p>This chapter creates a cost-effectiveness plane from a trial-style economic evaluation and shows how to visualize uncertainty in incremental costs and incremental effects at the same time. The figure is one of the central reporting tools in health economics because it displays not only the average result, but the direction and spread of the uncertainty around that result. The example here uses synthetic patient-level cost and QALY data, but the plotting logic follows the uncertainty framework widely used in applied economic evaluation <span class="citation" data-cites="fenwick2001">Fenwick, Claxton, and Sculpher (<a href="#ref-fenwick2001" role="doc-biblioref">2001</a>)</span>.</p>
<p>The cost-effectiveness plane places incremental effect on the x-axis and incremental cost on the y-axis. Each point represents one bootstrap replicate. The four quadrants then summarize the practical meaning of the uncertainty: better and more costly, better and less costly, worse and less costly, or worse and more costly.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="77.1">
<h2 data-number="77.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">77.1</span> What the visualization is showing</h2>
<p>We will simulate two arms of a simple comparative study: usual care and an intervention. For each arm, we will generate one-year costs and one-year QALYs at the patient level. We will then bootstrap the mean incremental cost and mean incremental QALY many times and place those bootstrap replicates on the cost-effectiveness plane.</p>
</section>
<section id="step-1-create-a-trial-style-dataset" class="level2" data-number="77.2">
<h2 data-number="77.2" class="anchored" data-anchor-id="step-1-create-a-trial-style-dataset"><span class="header-section-number">77.2</span> Step 1: Create a trial-style dataset</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n_control <span class="ot">&lt;-</span> <span class="dv">250</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>n_intervention <span class="ot">&lt;-</span> <span class="dv">250</span></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>control_cost <span class="ot">&lt;-</span> <span class="fu">rlnorm</span>(n_control, <span class="at">meanlog =</span> <span class="fu">log</span>(<span class="dv">11500</span>), <span class="at">sdlog =</span> <span class="fl">0.38</span>)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>intervention_cost <span class="ot">&lt;-</span> <span class="fu">rlnorm</span>(n_intervention, <span class="at">meanlog =</span> <span class="fu">log</span>(<span class="dv">12350</span>), <span class="at">sdlog =</span> <span class="fl">0.36</span>)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>control_qaly <span class="ot">&lt;-</span> <span class="fu">pmin</span>(<span class="fu">pmax</span>(<span class="fu">rnorm</span>(n_control, <span class="at">mean =</span> <span class="fl">0.66</span>, <span class="at">sd =</span> <span class="fl">0.12</span>), <span class="dv">0</span>), <span class="dv">1</span>)</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>intervention_qaly <span class="ot">&lt;-</span> <span class="fu">pmin</span>(<span class="fu">pmax</span>(<span class="fu">rnorm</span>(n_intervention, <span class="at">mean =</span> <span class="fl">0.71</span>, <span class="at">sd =</span> <span class="fl">0.11</span>), <span class="dv">0</span>), <span class="dv">1</span>)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>ce_trial_data <span class="ot">&lt;-</span> <span class="fu">rbind</span>(</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">arm =</span> <span class="st">"Usual care"</span>, <span class="at">cost =</span> control_cost, <span class="at">qaly =</span> control_qaly),</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">arm =</span> <span class="st">"Intervention"</span>, <span class="at">cost =</span> intervention_cost, <span class="at">qaly =</span> intervention_qaly)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>trial_summary <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">cbind</span>(cost, qaly) <span class="sc">~</span> arm,</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> ce_trial_data,</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">FUN =</span> mean</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>trial_summary[, <span class="fu">c</span>(<span class="st">"cost"</span>, <span class="st">"qaly"</span>)] <span class="ot">&lt;-</span> <span class="fu">round</span>(trial_summary[, <span class="fu">c</span>(<span class="st">"cost"</span>, <span class="st">"qaly"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  trial_summary,</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Mean one-year costs and QALYs in the synthetic trial dataset"</span></span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Mean one-year costs and QALYs in the synthetic trial dataset</caption>
<thead>
<tr class="header">
<th style="text-align: left;">arm</th>
<th style="text-align: right;">cost</th>
<th style="text-align: right;">qaly</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Intervention</td>
<td style="text-align: right;">13494.76</td>
<td style="text-align: right;">0.706</td>
</tr>
<tr class="even">
<td style="text-align: left;">Usual care</td>
<td style="text-align: right;">12469.19</td>
<td style="text-align: right;">0.661</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The example is synthetic, but it reproduces the structure of a standard trial-based economic evaluation: patient-level outcomes in two study arms and uncertainty around the incremental comparison.</p>
</section>
<section id="step-2-bootstrap-incremental-cost-and-effect" class="level2" data-number="77.3">
<h2 data-number="77.3" class="anchored" data-anchor-id="step-2-bootstrap-incremental-cost-and-effect"><span class="header-section-number">77.3</span> Step 2: Bootstrap incremental cost and effect</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>B <span class="ot">&lt;-</span> <span class="dv">1000</span></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>bootstrap_results <span class="ot">&lt;-</span> <span class="fu">do.call</span>(</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  rbind,</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">lapply</span>(<span class="fu">seq_len</span>(B), <span class="cf">function</span>(i) {</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>    sample_control <span class="ot">&lt;-</span> control_cost[<span class="fu">sample.int</span>(n_control, n_control, <span class="at">replace =</span> <span class="cn">TRUE</span>)]</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    sample_intervention <span class="ot">&lt;-</span> intervention_cost[<span class="fu">sample.int</span>(n_intervention, n_intervention, <span class="at">replace =</span> <span class="cn">TRUE</span>)]</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>    qaly_control <span class="ot">&lt;-</span> control_qaly[<span class="fu">sample.int</span>(n_control, n_control, <span class="at">replace =</span> <span class="cn">TRUE</span>)]</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>    qaly_intervention <span class="ot">&lt;-</span> intervention_qaly[<span class="fu">sample.int</span>(n_intervention, n_intervention, <span class="at">replace =</span> <span class="cn">TRUE</span>)]</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>      <span class="at">incremental_cost =</span> <span class="fu">mean</span>(sample_intervention) <span class="sc">-</span> <span class="fu">mean</span>(sample_control),</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>      <span class="at">incremental_qaly =</span> <span class="fu">mean</span>(qaly_intervention) <span class="sc">-</span> <span class="fu">mean</span>(qaly_control)</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>mean_incremental_cost <span class="ot">&lt;-</span> <span class="fu">mean</span>(bootstrap_results<span class="sc">$</span>incremental_cost)</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>mean_incremental_qaly <span class="ot">&lt;-</span> <span class="fu">mean</span>(bootstrap_results<span class="sc">$</span>incremental_qaly)</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>summary_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">quantity =</span> <span class="fu">c</span>(<span class="st">"Mean incremental cost"</span>, <span class="st">"Mean incremental QALY"</span>, <span class="st">"ICER"</span>),</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">value =</span> <span class="fu">c</span>(</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>    mean_incremental_cost,</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>    mean_incremental_qaly,</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>    mean_incremental_cost <span class="sc">/</span> mean_incremental_qaly</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>summary_table<span class="sc">$</span>value <span class="ot">&lt;-</span> <span class="fu">round</span>(summary_table<span class="sc">$</span>value, <span class="dv">3</span>)</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>  summary_table,</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the bootstrap incremental results"</span></span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the bootstrap incremental results</caption>
<thead>
<tr class="header">
<th style="text-align: left;">quantity</th>
<th style="text-align: right;">value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Mean incremental cost</td>
<td style="text-align: right;">1029.326</td>
</tr>
<tr class="even">
<td style="text-align: left;">Mean incremental QALY</td>
<td style="text-align: right;">0.045</td>
</tr>
<tr class="odd">
<td style="text-align: left;">ICER</td>
<td style="text-align: right;">22807.750</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-3-build-the-cost-effectiveness-plane" class="level2" data-number="77.4">
<h2 data-number="77.4" class="anchored" data-anchor-id="step-3-build-the-cost-effectiveness-plane"><span class="header-section-number">77.4</span> Step 3: Build the cost-effectiveness plane</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>wtp <span class="ot">&lt;-</span> <span class="dv">50000</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>effect_limits <span class="ot">&lt;-</span> <span class="fu">range</span>(bootstrap_results<span class="sc">$</span>incremental_qaly)</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>effect_grid <span class="ot">&lt;-</span> <span class="fu">seq</span>(effect_limits[<span class="dv">1</span>] <span class="sc">-</span> <span class="fl">0.01</span>, effect_limits[<span class="dv">2</span>] <span class="sc">+</span> <span class="fl">0.01</span>, <span class="at">length.out =</span> <span class="dv">200</span>)</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>wtp_line <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">incremental_qaly =</span> effect_grid,</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">incremental_cost =</span> wtp <span class="sc">*</span> effect_grid</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  bootstrap_results,</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> incremental_qaly, <span class="at">y =</span> incremental_cost)</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>) <span class="sc">+</span></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_hline</span>(<span class="at">yintercept =</span> <span class="dv">0</span>, <span class="at">color =</span> <span class="st">"#5c5c5c"</span>, <span class="at">linewidth =</span> <span class="fl">0.6</span>) <span class="sc">+</span></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="dv">0</span>, <span class="at">color =</span> <span class="st">"#5c5c5c"</span>, <span class="at">linewidth =</span> <span class="fl">0.6</span>) <span class="sc">+</span></span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(<span class="at">color =</span> <span class="st">"#457b9d"</span>, <span class="at">alpha =</span> <span class="fl">0.35</span>, <span class="at">size =</span> <span class="fl">1.5</span>) <span class="sc">+</span></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> wtp_line,</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> incremental_qaly, <span class="at">y =</span> incremental_cost),</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">inherit.aes =</span> <span class="cn">FALSE</span>,</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#d62828"</span>,</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.9</span></span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(</span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a>      <span class="at">incremental_qaly =</span> mean_incremental_qaly,</span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>      <span class="at">incremental_cost =</span> mean_incremental_cost</span>
<span id="cb3-29"><a href="#cb3-29" aria-hidden="true" tabindex="-1"></a>    ),</span>
<span id="cb3-30"><a href="#cb3-30" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> incremental_qaly, <span class="at">y =</span> incremental_cost),</span>
<span id="cb3-31"><a href="#cb3-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">inherit.aes =</span> <span class="cn">FALSE</span>,</span>
<span id="cb3-32"><a href="#cb3-32" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#1d3557"</span>,</span>
<span id="cb3-33"><a href="#cb3-33" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="dv">3</span></span>
<span id="cb3-34"><a href="#cb3-34" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-35"><a href="#cb3-35" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">annotate</span>(<span class="st">"text"</span>, <span class="at">x =</span> <span class="fl">0.08</span>, <span class="at">y =</span> <span class="fu">max</span>(bootstrap_results<span class="sc">$</span>incremental_cost), <span class="at">label =</span> <span class="st">"More effective,</span><span class="sc">\n</span><span class="st">more costly"</span>, <span class="at">hjust =</span> <span class="dv">1</span>, <span class="at">size =</span> <span class="fl">3.6</span>) <span class="sc">+</span></span>
<span id="cb3-36"><a href="#cb3-36" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">annotate</span>(<span class="st">"text"</span>, <span class="at">x =</span> <span class="fl">0.08</span>, <span class="at">y =</span> <span class="fu">min</span>(bootstrap_results<span class="sc">$</span>incremental_cost), <span class="at">label =</span> <span class="st">"More effective,</span><span class="sc">\n</span><span class="st">less costly"</span>, <span class="at">hjust =</span> <span class="dv">1</span>, <span class="at">vjust =</span> <span class="dv">0</span>, <span class="at">size =</span> <span class="fl">3.6</span>) <span class="sc">+</span></span>
<span id="cb3-37"><a href="#cb3-37" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">annotate</span>(<span class="st">"text"</span>, <span class="at">x =</span> <span class="fu">min</span>(bootstrap_results<span class="sc">$</span>incremental_qaly), <span class="at">y =</span> <span class="fu">max</span>(bootstrap_results<span class="sc">$</span>incremental_cost), <span class="at">label =</span> <span class="st">"Less effective,</span><span class="sc">\n</span><span class="st">more costly"</span>, <span class="at">hjust =</span> <span class="dv">0</span>, <span class="at">size =</span> <span class="fl">3.6</span>) <span class="sc">+</span></span>
<span id="cb3-38"><a href="#cb3-38" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">annotate</span>(<span class="st">"text"</span>, <span class="at">x =</span> <span class="fu">min</span>(bootstrap_results<span class="sc">$</span>incremental_qaly), <span class="at">y =</span> <span class="fu">min</span>(bootstrap_results<span class="sc">$</span>incremental_cost), <span class="at">label =</span> <span class="st">"Less effective,</span><span class="sc">\n</span><span class="st">less costly"</span>, <span class="at">hjust =</span> <span class="dv">0</span>, <span class="at">vjust =</span> <span class="dv">0</span>, <span class="at">size =</span> <span class="fl">3.6</span>) <span class="sc">+</span></span>
<span id="cb3-39"><a href="#cb3-39" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb3-40"><a href="#cb3-40" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Cost-effectiveness plane for the synthetic economic evaluation"</span>,</span>
<span id="cb3-41"><a href="#cb3-41" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Each point is a bootstrap replicate; the red line shows a willingness-to-pay threshold of $50,000 per QALY"</span>,</span>
<span id="cb3-42"><a href="#cb3-42" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Incremental QALYs"</span>,</span>
<span id="cb3-43"><a href="#cb3-43" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Incremental costs ($)"</span></span>
<span id="cb3-44"><a href="#cb3-44" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-45"><a href="#cb3-45" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/cost-effectiveness-planes_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure works because it compresses a large amount of uncertainty into one visual frame. The cloud of points shows variability. The quadrant location shows whether the intervention tends to improve outcomes, reduce costs, or both. The willingness-to-pay line adds a decision threshold.</p>
</section>
<section id="step-4-summarize-the-quadrant-probabilities" class="level2" data-number="77.5">
<h2 data-number="77.5" class="anchored" data-anchor-id="step-4-summarize-the-quadrant-probabilities"><span class="header-section-number">77.5</span> Step 4: Summarize the quadrant probabilities</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>quadrant_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">quadrant =</span> <span class="fu">c</span>(</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>    <span class="st">"More effective and more costly"</span>,</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>    <span class="st">"More effective and less costly"</span>,</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Less effective and more costly"</span>,</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Less effective and less costly"</span></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">probability =</span> <span class="fu">c</span>(</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(bootstrap_results<span class="sc">$</span>incremental_qaly <span class="sc">&gt;</span> <span class="dv">0</span> <span class="sc">&amp;</span> bootstrap_results<span class="sc">$</span>incremental_cost <span class="sc">&gt;</span> <span class="dv">0</span>),</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(bootstrap_results<span class="sc">$</span>incremental_qaly <span class="sc">&gt;</span> <span class="dv">0</span> <span class="sc">&amp;</span> bootstrap_results<span class="sc">$</span>incremental_cost <span class="sc">&lt;</span> <span class="dv">0</span>),</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(bootstrap_results<span class="sc">$</span>incremental_qaly <span class="sc">&lt;</span> <span class="dv">0</span> <span class="sc">&amp;</span> bootstrap_results<span class="sc">$</span>incremental_cost <span class="sc">&gt;</span> <span class="dv">0</span>),</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(bootstrap_results<span class="sc">$</span>incremental_qaly <span class="sc">&lt;</span> <span class="dv">0</span> <span class="sc">&amp;</span> bootstrap_results<span class="sc">$</span>incremental_cost <span class="sc">&lt;</span> <span class="dv">0</span>)</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>quadrant_table<span class="sc">$</span>probability <span class="ot">&lt;-</span> <span class="fu">round</span>(quadrant_table<span class="sc">$</span>probability, <span class="dv">3</span>)</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>  quadrant_table,</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Probability mass in each quadrant of the cost-effectiveness plane"</span></span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Probability mass in each quadrant of the cost-effectiveness plane</caption>
<thead>
<tr class="header">
<th style="text-align: left;">quadrant</th>
<th style="text-align: right;">probability</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">More effective and more costly</td>
<td style="text-align: right;">0.988</td>
</tr>
<tr class="even">
<td style="text-align: left;">More effective and less costly</td>
<td style="text-align: right;">0.012</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Less effective and more costly</td>
<td style="text-align: right;">0.000</td>
</tr>
<tr class="even">
<td style="text-align: left;">Less effective and less costly</td>
<td style="text-align: right;">0.000</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-5-add-simple-cost-effectiveness-probabilities-at-common-thresholds" class="level2" data-number="77.6">
<h2 data-number="77.6" class="anchored" data-anchor-id="step-5-add-simple-cost-effectiveness-probabilities-at-common-thresholds"><span class="header-section-number">77.6</span> Step 5: Add simple cost-effectiveness probabilities at common thresholds</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>thresholds <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="dv">20000</span>, <span class="dv">50000</span>, <span class="dv">100000</span>)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>ce_probability_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">threshold =</span> thresholds,</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">probability_cost_effective =</span> <span class="fu">sapply</span>(</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>    thresholds,</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>    <span class="cf">function</span>(lambda) {</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>      <span class="fu">mean</span>(lambda <span class="sc">*</span> bootstrap_results<span class="sc">$</span>incremental_qaly <span class="sc">-</span> bootstrap_results<span class="sc">$</span>incremental_cost <span class="sc">&gt;</span> <span class="dv">0</span>)</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>    }</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>ce_probability_table<span class="sc">$</span>probability_cost_effective <span class="ot">&lt;-</span></span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(ce_probability_table<span class="sc">$</span>probability_cost_effective, <span class="dv">3</span>)</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>  ce_probability_table,</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Probability the intervention is cost-effective at selected willingness-to-pay thresholds"</span></span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Probability the intervention is cost-effective at selected willingness-to-pay thresholds</caption>
<thead>
<tr class="header">
<th style="text-align: right;">threshold</th>
<th style="text-align: right;">probability_cost_effective</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">2e+04</td>
<td style="text-align: right;">0.402</td>
</tr>
<tr class="even">
<td style="text-align: right;">5e+04</td>
<td style="text-align: right;">0.967</td>
</tr>
<tr class="odd">
<td style="text-align: right;">1e+05</td>
<td style="text-align: right;">1.000</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="77.7">
<h2 data-number="77.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">77.7</span> How to read the figure carefully</h2>
<p>The cost-effectiveness plane is a visualization of uncertainty, not a decision rule by itself. A cloud centered in the northeast quadrant means the intervention tends to improve outcomes but also raises costs. Whether that is acceptable depends on the decision maker's willingness to pay for additional health gain.</p>
<p>The interpretation also depends on the outcome scale. Here the x-axis is QALYs, which makes the willingness-to-pay line easy to interpret. In other applications the effect scale could be cases averted, life-years gained, or some other endpoint, and the decision threshold would need to match that scale.</p>
</section>
<section id="further-reading" class="level2" data-number="77.8">
<h2 data-number="77.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">77.8</span> Further reading</h2>
<p>Fenwick, Claxton, and Sculpher provide one of the clearest discussions of how uncertainty should be represented in cost-effectiveness analysis and why visual tools such as the cost-effectiveness plane matter <span class="citation" data-cites="fenwick2001">Fenwick, Claxton, and Sculpher (<a href="#ref-fenwick2001" role="doc-biblioref">2001</a>)</span>. A natural next step after this chapter is to extend the same bootstrap results into a cost-effectiveness acceptability curve.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-fenwick2001" class="csl-entry" role="listitem">
Fenwick, Elisabeth, Karl Claxton, and Mark Sculpher. 2001. <span>"Representing Uncertainty: The Role of Cost-Effectiveness Acceptability Curves."</span> <em>Health Economics</em> 10 (8): 779-87. <a href="https://doi.org/10.1002/hec.635">https://doi.org/10.1002/hec.635</a>.
</div>
</div>
</section>
