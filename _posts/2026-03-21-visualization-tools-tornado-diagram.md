---
title: "Tornado Diagram"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a tornado diagram for a simple health-economic decision problem. The figure is designed to show which uncertain inputs move the result the most when they are varied one at a time across plausible..."
---
<p>This chapter creates a tornado diagram for a simple health-economic decision problem. The figure is designed to show which uncertain inputs move the result the most when they are varied one at a time across plausible ranges. In practice, that makes the tornado diagram one of the fastest ways to explain sensitivity analysis to readers who do not want to inspect a long appendix of tables. The example here uses a synthetic vaccination decision model, but the logic follows the deterministic sensitivity-analysis workflows commonly used in health-economic modeling and decision analysis <span class="citation" data-cites="briggs2006">Briggs, Claxton, and Sculpher (<a href="#ref-briggs2006" role="doc-biblioref">2006</a>)</span>; <span class="citation" data-cites="fenwick2001">Fenwick, Claxton, and Sculpher (<a href="#ref-fenwick2001" role="doc-biblioref">2001</a>)</span>.</p>
<p>The visualization we will build is centered on incremental net monetary benefit, or NMB. For each parameter, we hold everything else at its base-case value, vary that one input from a low value to a high value, and record how much the incremental NMB changes. The parameters are then sorted by the width of that change. The widest bar goes at the top, which is why the chart looks like a tornado.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="78.1">
<h2 data-number="78.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">78.1</span> What the visualization is showing</h2>
<p>The figure will summarize one-way sensitivity analysis for a preventive intervention compared with usual care. The decision model will use a willingness-to-pay threshold of <code>$50,000</code> per QALY. Each bar in the tornado diagram will show how the incremental NMB changes when one parameter moves from its low value to its high value while all other parameters remain fixed.</p>
<p>The parameters will be:</p>
<p><code>program_cost</code>, the added intervention cost per patient; <code>hospital_cost</code>, the cost of an avoidable hospitalization; <code>baseline_risk</code>, the annual hospitalization risk under usual care; <code>relative_risk</code>, the intervention effect on hospitalization; <code>qaly_loss</code>, the QALY decrement associated with hospitalization; and <code>uptake</code>, the fraction of eligible patients who actually receive the intervention.</p>
</section>
<section id="step-1-define-the-base-case-decision-model" class="level2" data-number="78.2">
<h2 data-number="78.2" class="anchored" data-anchor-id="step-1-define-the-base-case-decision-model"><span class="header-section-number">78.2</span> Step 1: Define the base-case decision model</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a>wtp <span class="ot">&lt;-</span> <span class="dv">50000</span></span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>base_values <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">program_cost =</span> <span class="dv">420</span>,</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">hospital_cost =</span> <span class="dv">6800</span>,</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">baseline_risk =</span> <span class="fl">0.18</span>,</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">relative_risk =</span> <span class="fl">0.78</span>,</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">qaly_loss =</span> <span class="fl">0.032</span>,</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">uptake =</span> <span class="fl">0.72</span></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>parameter_ranges <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">parameter =</span> <span class="fu">names</span>(base_values),</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">low =</span> <span class="fu">c</span>(<span class="dv">260</span>, <span class="dv">5200</span>, <span class="fl">0.12</span>, <span class="fl">0.65</span>, <span class="fl">0.018</span>, <span class="fl">0.55</span>),</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">high =</span> <span class="fu">c</span>(<span class="dv">620</span>, <span class="dv">8800</span>, <span class="fl">0.25</span>, <span class="fl">0.92</span>, <span class="fl">0.050</span>, <span class="fl">0.90</span>)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>parameter_ranges<span class="sc">$</span>base <span class="ot">&lt;-</span> base_values[parameter_ranges<span class="sc">$</span>parameter]</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>calculate_incremental_nmb <span class="ot">&lt;-</span> <span class="cf">function</span>(values, <span class="at">wtp =</span> <span class="dv">50000</span>) {</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  avoided_events <span class="ot">&lt;-</span> values[<span class="st">"baseline_risk"</span>] <span class="sc">*</span> (<span class="dv">1</span> <span class="sc">-</span> values[<span class="st">"relative_risk"</span>]) <span class="sc">*</span> values[<span class="st">"uptake"</span>]</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  incremental_qaly <span class="ot">&lt;-</span> avoided_events <span class="sc">*</span> values[<span class="st">"qaly_loss"</span>]</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>  incremental_cost <span class="ot">&lt;-</span> values[<span class="st">"program_cost"</span>] <span class="sc">*</span> values[<span class="st">"uptake"</span>] <span class="sc">-</span></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>    avoided_events <span class="sc">*</span> values[<span class="st">"hospital_cost"</span>]</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  wtp <span class="sc">*</span> incremental_qaly <span class="sc">-</span> incremental_cost</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>base_nmb <span class="ot">&lt;-</span> <span class="fu">calculate_incremental_nmb</span>(base_values, <span class="at">wtp =</span> wtp)</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>base_case_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>  <span class="at">quantity =</span> <span class="fu">c</span>(<span class="st">"Incremental cost"</span>, <span class="st">"Incremental QALY"</span>, <span class="st">"Incremental NMB"</span>),</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>  <span class="at">value =</span> <span class="fu">c</span>(</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>    base_values[<span class="st">"program_cost"</span>] <span class="sc">*</span> base_values[<span class="st">"uptake"</span>] <span class="sc">-</span></span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>      base_values[<span class="st">"baseline_risk"</span>] <span class="sc">*</span> (<span class="dv">1</span> <span class="sc">-</span> base_values[<span class="st">"relative_risk"</span>]) <span class="sc">*</span> base_values[<span class="st">"uptake"</span>] <span class="sc">*</span> base_values[<span class="st">"hospital_cost"</span>],</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>    base_values[<span class="st">"baseline_risk"</span>] <span class="sc">*</span> (<span class="dv">1</span> <span class="sc">-</span> base_values[<span class="st">"relative_risk"</span>]) <span class="sc">*</span> base_values[<span class="st">"uptake"</span>] <span class="sc">*</span> base_values[<span class="st">"qaly_loss"</span>],</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>    base_nmb</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>base_case_table<span class="sc">$</span>value <span class="ot">&lt;-</span> <span class="fu">round</span>(base_case_table<span class="sc">$</span>value, <span class="dv">3</span>)</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>  base_case_table,</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Base-case incremental results used for the tornado diagram"</span></span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Base-case incremental results used for the tornado diagram</caption>
<thead>
<tr class="header">
<th style="text-align: left;">quantity</th>
<th style="text-align: right;">value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Incremental cost</td>
<td style="text-align: right;">108.518</td>
</tr>
<tr class="even">
<td style="text-align: left;">Incremental QALY</td>
<td style="text-align: right;">0.001</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Incremental NMB</td>
<td style="text-align: right;">-62.899</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This setup matters because a tornado diagram always depends on a specific target quantity. In this chapter the target is incremental NMB, not incremental cost or incremental effect alone.</p>
</section>
<section id="step-2-run-the-one-way-sensitivity-analysis" class="level2" data-number="78.3">
<h2 data-number="78.3" class="anchored" data-anchor-id="step-2-run-the-one-way-sensitivity-analysis"><span class="header-section-number">78.3</span> Step 2: Run the one-way sensitivity analysis</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>tornado_results <span class="ot">&lt;-</span> <span class="fu">do.call</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  rbind,</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">lapply</span>(<span class="fu">seq_len</span>(<span class="fu">nrow</span>(parameter_ranges)), <span class="cf">function</span>(i) {</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>    parameter_name <span class="ot">&lt;-</span> parameter_ranges<span class="sc">$</span>parameter[i]</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>    low_values <span class="ot">&lt;-</span> base_values</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>    high_values <span class="ot">&lt;-</span> base_values</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    low_values[parameter_name] <span class="ot">&lt;-</span> parameter_ranges<span class="sc">$</span>low[i]</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>    high_values[parameter_name] <span class="ot">&lt;-</span> parameter_ranges<span class="sc">$</span>high[i]</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>    low_nmb <span class="ot">&lt;-</span> <span class="fu">calculate_incremental_nmb</span>(low_values, <span class="at">wtp =</span> wtp)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>    high_nmb <span class="ot">&lt;-</span> <span class="fu">calculate_incremental_nmb</span>(high_values, <span class="at">wtp =</span> wtp)</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>      <span class="at">parameter =</span> parameter_name,</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>      <span class="at">low_nmb =</span> low_nmb,</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>      <span class="at">high_nmb =</span> high_nmb</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>tornado_results<span class="sc">$</span>range_width <span class="ot">&lt;-</span> <span class="fu">abs</span>(tornado_results<span class="sc">$</span>high_nmb <span class="sc">-</span> tornado_results<span class="sc">$</span>low_nmb)</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>tornado_results <span class="ot">&lt;-</span> tornado_results[<span class="fu">order</span>(tornado_results<span class="sc">$</span>range_width, <span class="at">decreasing =</span> <span class="cn">TRUE</span>), ]</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>tornado_results<span class="sc">$</span>parameter <span class="ot">&lt;-</span> <span class="fu">factor</span>(tornado_results<span class="sc">$</span>parameter, <span class="at">levels =</span> tornado_results<span class="sc">$</span>parameter)</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>tornado_table <span class="ot">&lt;-</span> tornado_results</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>tornado_table[, <span class="fu">c</span>(<span class="st">"low_nmb"</span>, <span class="st">"high_nmb"</span>, <span class="st">"range_width"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(tornado_table[, <span class="fu">c</span>(<span class="st">"low_nmb"</span>, <span class="st">"high_nmb"</span>, <span class="st">"range_width"</span>)], <span class="dv">2</span>)</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  tornado_table,</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"One-way sensitivity analysis results ranked by impact on incremental net monetary benefit"</span></span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>One-way sensitivity analysis results ranked by impact on incremental net monetary benefit</caption>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">parameter</th>
<th style="text-align: right;">low_nmb</th>
<th style="text-align: right;">high_nmb</th>
<th style="text-align: right;">range_width</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">baseline_risk3</td>
<td style="text-align: left;">relative_risk</td>
<td style="text-align: right;">78.62</td>
<td style="text-align: right;">-215.31</td>
<td style="text-align: right;">293.93</td>
</tr>
<tr class="even">
<td style="text-align: left;">baseline_risk</td>
<td style="text-align: left;">program_cost</td>
<td style="text-align: right;">52.30</td>
<td style="text-align: right;">-206.90</td>
<td style="text-align: right;">259.20</td>
</tr>
<tr class="odd">
<td style="text-align: left;">baseline_risk2</td>
<td style="text-align: left;">baseline_risk</td>
<td style="text-align: right;">-142.73</td>
<td style="text-align: right;">30.24</td>
<td style="text-align: right;">172.97</td>
</tr>
<tr class="even">
<td style="text-align: left;">baseline_risk1</td>
<td style="text-align: left;">hospital_cost</td>
<td style="text-align: right;">-108.52</td>
<td style="text-align: right;">-5.88</td>
<td style="text-align: right;">102.64</td>
</tr>
<tr class="odd">
<td style="text-align: left;">baseline_risk4</td>
<td style="text-align: left;">qaly_loss</td>
<td style="text-align: right;">-82.86</td>
<td style="text-align: right;">-37.24</td>
<td style="text-align: right;">45.62</td>
</tr>
<tr class="even">
<td style="text-align: left;">baseline_risk5</td>
<td style="text-align: left;">uptake</td>
<td style="text-align: right;">-48.05</td>
<td style="text-align: right;">-78.62</td>
<td style="text-align: right;">30.58</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The table already contains the full information needed for the plot. The figure simply turns that ranking into something faster to read.</p>
</section>
<section id="step-3-reshape-the-data-for-the-tornado-figure" class="level2" data-number="78.4">
<h2 data-number="78.4" class="anchored" data-anchor-id="step-3-reshape-the-data-for-the-tornado-figure"><span class="header-section-number">78.4</span> Step 3: Reshape the data for the tornado figure</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>tornado_plot_data <span class="ot">&lt;-</span> <span class="fu">rbind</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">parameter =</span> tornado_results<span class="sc">$</span>parameter,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">scenario =</span> <span class="st">"Low value"</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">nmb =</span> tornado_results<span class="sc">$</span>low_nmb</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">parameter =</span> tornado_results<span class="sc">$</span>parameter,</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">scenario =</span> <span class="st">"High value"</span>,</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">nmb =</span> tornado_results<span class="sc">$</span>high_nmb</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>segment_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">parameter =</span> tornado_results<span class="sc">$</span>parameter,</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">xmin =</span> <span class="fu">pmin</span>(tornado_results<span class="sc">$</span>low_nmb, tornado_results<span class="sc">$</span>high_nmb),</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">xmax =</span> <span class="fu">pmax</span>(tornado_results<span class="sc">$</span>low_nmb, tornado_results<span class="sc">$</span>high_nmb)</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<p>The only real trick in a tornado diagram is that we want horizontal ranges, not separate unrelated points. That is why the plotting data include both the segment endpoints and the individual low/high markers.</p>
</section>
<section id="step-4-build-the-tornado-diagram" class="level2" data-number="78.5">
<h2 data-number="78.5" class="anchored" data-anchor-id="step-4-build-the-tornado-diagram"><span class="header-section-number">78.5</span> Step 4: Build the tornado diagram</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>() <span class="sc">+</span></span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_vline</span>(</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">xintercept =</span> base_nmb,</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#8b5e34"</span>,</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.8</span></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_segment</span>(</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> segment_data,</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> xmin,</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>      <span class="at">xend =</span> xmax,</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> parameter,</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>      <span class="at">yend =</span> parameter</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>    ),</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#7a7a7a"</span>,</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="dv">6</span>,</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">lineend =</span> <span class="st">"butt"</span></span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> tornado_plot_data,</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> nmb, <span class="at">y =</span> parameter, <span class="at">color =</span> scenario),</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="dv">3</span></span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Tornado diagram for one-way sensitivity analysis"</span>,</span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Bars show how incremental net monetary benefit changes when one parameter is varied at a time"</span>,</span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Incremental net monetary benefit ($)"</span>,</span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="cn">NULL</span>,</span>
<span id="cb4-30"><a href="#cb4-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"Scenario"</span></span>
<span id="cb4-31"><a href="#cb4-31" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-32"><a href="#cb4-32" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_color_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"#457b9d"</span>, <span class="st">"#d62828"</span>)) <span class="sc">+</span></span>
<span id="cb4-33"><a href="#cb4-33" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb4-34"><a href="#cb4-34" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme</span>(</span>
<span id="cb4-35"><a href="#cb4-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid.major.y =</span> ggplot2<span class="sc">::</span><span class="fu">element_blank</span>()</span>
<span id="cb4-36"><a href="#cb4-36" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/tornado-diagram_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure works because the ranking is built into the vertical order. The top bars represent the assumptions with the greatest influence on the decision result. The dashed vertical line marks the base-case NMB, so the reader can see not only the width of the change but also whether a parameter pushes the result above or below that benchmark.</p>
</section>
<section id="step-5-label-the-direction-of-influence" class="level2" data-number="78.6">
<h2 data-number="78.6" class="anchored" data-anchor-id="step-5-label-the-direction-of-influence"><span class="header-section-number">78.6</span> Step 5: Label the direction of influence</h2>
<p>The plot becomes even more useful when paired with a short table clarifying which side corresponds to the low value and which side corresponds to the high value.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>direction_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">parameter =</span> <span class="fu">as.character</span>(tornado_results<span class="sc">$</span>parameter),</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">lower_nmb_scenario =</span> <span class="fu">ifelse</span>(tornado_results<span class="sc">$</span>low_nmb <span class="sc">&lt;</span> tornado_results<span class="sc">$</span>high_nmb, <span class="st">"Low value"</span>, <span class="st">"High value"</span>),</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">higher_nmb_scenario =</span> <span class="fu">ifelse</span>(tornado_results<span class="sc">$</span>low_nmb <span class="sc">&lt;</span> tornado_results<span class="sc">$</span>high_nmb, <span class="st">"High value"</span>, <span class="st">"Low value"</span>)</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>  direction_table,</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Direction of influence for each parameter in the tornado diagram"</span></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Direction of influence for each parameter in the tornado diagram</caption>
<thead>
<tr class="header">
<th style="text-align: left;">parameter</th>
<th style="text-align: left;">lower_nmb_scenario</th>
<th style="text-align: left;">higher_nmb_scenario</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">relative_risk</td>
<td style="text-align: left;">High value</td>
<td style="text-align: left;">Low value</td>
</tr>
<tr class="even">
<td style="text-align: left;">program_cost</td>
<td style="text-align: left;">High value</td>
<td style="text-align: left;">Low value</td>
</tr>
<tr class="odd">
<td style="text-align: left;">baseline_risk</td>
<td style="text-align: left;">Low value</td>
<td style="text-align: left;">High value</td>
</tr>
<tr class="even">
<td style="text-align: left;">hospital_cost</td>
<td style="text-align: left;">Low value</td>
<td style="text-align: left;">High value</td>
</tr>
<tr class="odd">
<td style="text-align: left;">qaly_loss</td>
<td style="text-align: left;">Low value</td>
<td style="text-align: left;">High value</td>
</tr>
<tr class="even">
<td style="text-align: left;">uptake</td>
<td style="text-align: left;">High value</td>
<td style="text-align: left;">Low value</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This small companion table helps prevent a common reading mistake. A wide bar tells us a parameter matters, but it does not by itself tell us whether increasing the parameter makes the intervention look better or worse.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="78.7">
<h2 data-number="78.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">78.7</span> How to read the figure carefully</h2>
<p>A tornado diagram is a local sensitivity-analysis tool. It changes one parameter at a time and keeps all others fixed. That makes it easy to explain, but it also means the figure does not capture interaction effects or joint uncertainty across parameters. It is therefore best read as a prioritization tool, not as a complete uncertainty analysis.</p>
<p>The ranges also matter. A tornado diagram can be made to look dramatic or trivial depending on how wide the chosen low and high values are. That is why the chapter uses explicit ranges and why applied work should explain where those ranges came from, whether from confidence intervals, literature reviews, expert elicitation, or policy scenarios.</p>
</section>
<section id="further-reading" class="level2" data-number="78.8">
<h2 data-number="78.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">78.8</span> Further reading</h2>
<p>Briggs, Claxton, and Sculpher provide one of the most useful practical discussions of deterministic sensitivity analysis in health-economic modeling <span class="citation" data-cites="briggs2006">Briggs, Claxton, and Sculpher (<a href="#ref-briggs2006" role="doc-biblioref">2006</a>)</span>. Fenwick and coauthors are a natural companion reading when the next step is to move from one-way sensitivity analysis to broader uncertainty representation and decision-focused summaries <span class="citation" data-cites="fenwick2001">Fenwick, Claxton, and Sculpher (<a href="#ref-fenwick2001" role="doc-biblioref">2001</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-briggs2006" class="csl-entry" role="listitem">
Briggs, Andrew, Karl Claxton, and Mark Sculpher. 2006. <em>Decision Modelling for Health Economic Evaluation</em>. Oxford: Oxford University Press.
</div>
<div id="ref-fenwick2001" class="csl-entry" role="listitem">
Fenwick, Elisabeth, Karl Claxton, and Mark Sculpher. 2001. <span>"Representing Uncertainty: The Role of Cost-Effectiveness Acceptability Curves."</span> <em>Health Economics</em> 10 (8): 779-87. <a href="https://doi.org/10.1002/hec.635">https://doi.org/10.1002/hec.635</a>.
</div>
</div>
</section>
