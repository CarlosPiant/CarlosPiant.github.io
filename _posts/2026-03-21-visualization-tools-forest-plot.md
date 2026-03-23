---
title: "Forest Plot"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a forest plot and shows how to present point estimates with confidence intervals in a way that is visually compact and statistically honest. Forest plots are one of the most common reporting..."
---
<p>This chapter creates a forest plot and shows how to present point estimates with confidence intervals in a way that is visually compact and statistically honest. Forest plots are one of the most common reporting figures in clinical trials, subgroup analyses, and meta-analyses because they let readers compare many effect estimates at once while keeping uncertainty visible <span class="citation" data-cites="lewis2001forest">Lewis and Clarke (<a href="#ref-lewis2001forest" role="doc-biblioref">2001</a>)</span>.</p>
<p>The figure is especially useful in health research because it solves a practical communication problem. Tables of odds ratios, hazard ratios, or mean differences are hard to scan when there are many subgroups or studies. A forest plot lets the reader see the direction, magnitude, and precision of each estimate immediately.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="67.1">
<h2 data-number="67.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">67.1</span> What the visualization is showing</h2>
<p>We will build a forest plot for effect estimates expressed as ratios. Each row will show:</p>
<ol type="1">
<li>the subgroup or study label,</li>
<li>a point estimate,</li>
<li>a confidence interval,</li>
<li>a vertical line marking the null value.</li>
</ol>
<p>When the estimate is a hazard ratio or odds ratio, the null value is 1. Confidence intervals entirely to the left of 1 suggest lower risk under the intervention. Intervals that cross 1 indicate that sampling uncertainty still includes no difference.</p>
</section>
<section id="step-1-create-a-subgroup-results-table" class="level2" data-number="67.2">
<h2 data-number="67.2" class="anchored" data-anchor-id="step-1-create-a-subgroup-results-table"><span class="header-section-number">67.2</span> Step 1: Create a subgroup-results table</h2>
<p>We will begin with a synthetic subgroup analysis for a hospital discharge intervention. The values are made up, but they mimic the structure of a typical trial appendix.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>synthetic_forest <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">subgroup =</span> <span class="fu">c</span>(</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Overall"</span>,</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Age &lt; 65"</span>,</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Age &gt;= 65"</span>,</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Women"</span>,</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Men"</span>,</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>    <span class="st">"No prior admission"</span>,</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Prior admission"</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimate =</span> <span class="fu">c</span>(<span class="fl">0.82</span>, <span class="fl">0.78</span>, <span class="fl">0.87</span>, <span class="fl">0.91</span>, <span class="fl">0.74</span>, <span class="fl">0.80</span>, <span class="fl">0.86</span>),</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">conf_low =</span> <span class="fu">c</span>(<span class="fl">0.72</span>, <span class="fl">0.63</span>, <span class="fl">0.71</span>, <span class="fl">0.73</span>, <span class="fl">0.60</span>, <span class="fl">0.66</span>, <span class="fl">0.70</span>),</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">conf_high =</span> <span class="fu">c</span>(<span class="fl">0.93</span>, <span class="fl">0.97</span>, <span class="fl">1.07</span>, <span class="fl">1.14</span>, <span class="fl">0.92</span>, <span class="fl">0.98</span>, <span class="fl">1.05</span>),</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">weight =</span> <span class="fu">c</span>(<span class="fl">1.00</span>, <span class="fl">0.68</span>, <span class="fl">0.59</span>, <span class="fl">0.54</span>, <span class="fl">0.63</span>, <span class="fl">0.71</span>, <span class="fl">0.57</span>),</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">row_type =</span> <span class="fu">c</span>(<span class="st">"Overall"</span>, <span class="fu">rep</span>(<span class="st">"Subgroup"</span>, <span class="dv">6</span>)),</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">row.names =</span> <span class="cn">NULL</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>synthetic_forest<span class="sc">$</span>estimate_label <span class="ot">&lt;-</span> <span class="fu">sprintf</span>(</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  <span class="st">"%.2f (%.2f to %.2f)"</span>,</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>  synthetic_forest<span class="sc">$</span>estimate,</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  synthetic_forest<span class="sc">$</span>conf_low,</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  synthetic_forest<span class="sc">$</span>conf_high</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>synthetic_table <span class="ot">&lt;-</span> synthetic_forest <span class="sc">|&gt;</span></span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">transmute</span>(</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>    subgroup,</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>    <span class="at">hazard_ratio =</span> <span class="fu">round</span>(estimate, <span class="dv">2</span>),</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower_95_ci =</span> <span class="fu">round</span>(conf_low, <span class="dv">2</span>),</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper_95_ci =</span> <span class="fu">round</span>(conf_high, <span class="dv">2</span>)</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  synthetic_table,</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Synthetic subgroup estimates that will be plotted in the forest plot"</span></span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Synthetic subgroup estimates that will be plotted in the forest plot</caption>
<thead>
<tr class="header">
<th style="text-align: left;">subgroup</th>
<th style="text-align: right;">hazard_ratio</th>
<th style="text-align: right;">lower_95_ci</th>
<th style="text-align: right;">upper_95_ci</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Overall</td>
<td style="text-align: right;">0.82</td>
<td style="text-align: right;">0.72</td>
<td style="text-align: right;">0.93</td>
</tr>
<tr class="even">
<td style="text-align: left;">Age &lt; 65</td>
<td style="text-align: right;">0.78</td>
<td style="text-align: right;">0.63</td>
<td style="text-align: right;">0.97</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Age &gt;= 65</td>
<td style="text-align: right;">0.87</td>
<td style="text-align: right;">0.71</td>
<td style="text-align: right;">1.07</td>
</tr>
<tr class="even">
<td style="text-align: left;">Women</td>
<td style="text-align: right;">0.91</td>
<td style="text-align: right;">0.73</td>
<td style="text-align: right;">1.14</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Men</td>
<td style="text-align: right;">0.74</td>
<td style="text-align: right;">0.60</td>
<td style="text-align: right;">0.92</td>
</tr>
<tr class="even">
<td style="text-align: left;">No prior admission</td>
<td style="text-align: right;">0.80</td>
<td style="text-align: right;">0.66</td>
<td style="text-align: right;">0.98</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Prior admission</td>
<td style="text-align: right;">0.86</td>
<td style="text-align: right;">0.70</td>
<td style="text-align: right;">1.05</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The table is the raw material for the figure. Each row is an effect estimate with its confidence interval. The only extra variables we add are a relative weight used to size the plotting symbols and a row type that tells the plot which estimate should be shown as the overall summary.</p>
</section>
<section id="step-2-build-a-reusable-forest-plot-function" class="level2" data-number="67.3">
<h2 data-number="67.3" class="anchored" data-anchor-id="step-2-build-a-reusable-forest-plot-function"><span class="header-section-number">67.3</span> Step 2: Build a reusable forest-plot function</h2>
<p>The plotting function below is designed for ratio measures such as odds ratios or hazard ratios, so it uses a log-scaled x-axis. That makes confidence intervals visually symmetric around the point estimate on the multiplicative scale.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>build_forest_plot <span class="ot">&lt;-</span> <span class="cf">function</span>(data, title, subtitle) {</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  plot_data <span class="ot">&lt;-</span> data <span class="sc">|&gt;</span></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>      <span class="at">subgroup =</span> <span class="fu">factor</span>(subgroup, <span class="at">levels =</span> <span class="fu">rev</span>(subgroup)),</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>      <span class="at">point_size =</span> <span class="fl">2.8</span> <span class="sc">+</span> <span class="fl">3.8</span> <span class="sc">*</span> weight,</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>      <span class="at">label_x =</span> <span class="fl">2.55</span></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>(plot_data, <span class="fu">aes</span>(<span class="at">y =</span> subgroup, <span class="at">x =</span> estimate)) <span class="sc">+</span></span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="dv">1</span>, <span class="at">color =</span> <span class="st">"#7f7f7f"</span>, <span class="at">linetype =</span> <span class="st">"dashed"</span>, <span class="at">linewidth =</span> <span class="fl">0.6</span>) <span class="sc">+</span></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> conf_low, <span class="at">xend =</span> conf_high, <span class="at">yend =</span> subgroup),</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.9</span>,</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#365c8d"</span></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_point</span>(</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> <span class="fu">subset</span>(plot_data, row_type <span class="sc">==</span> <span class="st">"Subgroup"</span>),</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">size =</span> point_size),</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>      <span class="at">shape =</span> <span class="dv">15</span>,</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#365c8d"</span>,</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>      <span class="at">show.legend =</span> <span class="cn">FALSE</span></span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_point</span>(</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> <span class="fu">subset</span>(plot_data, row_type <span class="sc">==</span> <span class="st">"Overall"</span>),</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">size =</span> point_size),</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>      <span class="at">shape =</span> <span class="dv">18</span>,</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#8c2d04"</span>,</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>      <span class="at">show.legend =</span> <span class="cn">FALSE</span></span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> label_x, <span class="at">label =</span> estimate_label),</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>      <span class="at">hjust =</span> <span class="dv">0</span>,</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.5</span>,</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#1f1f1f"</span></span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_x_log10</span>(</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>      <span class="at">breaks =</span> <span class="fu">c</span>(<span class="fl">0.4</span>, <span class="fl">0.5</span>, <span class="fl">0.75</span>, <span class="dv">1</span>, <span class="fl">1.5</span>, <span class="dv">2</span>),</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>      <span class="at">labels =</span> <span class="fu">c</span>(<span class="st">"0.40"</span>, <span class="st">"0.50"</span>, <span class="st">"0.75"</span>, <span class="st">"1.00"</span>, <span class="st">"1.50"</span>, <span class="st">"2.00"</span>),</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>      <span class="at">limits =</span> <span class="fu">c</span>(<span class="fl">0.35</span>, <span class="fl">2.85</span>)</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_size_identity</span>() <span class="sc">+</span></span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coord_cartesian</span>(<span class="at">clip =</span> <span class="st">"off"</span>) <span class="sc">+</span></span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle,</span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="st">"Hazard ratio"</span>,</span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> <span class="cn">NULL</span></span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb2-50"><a href="#cb2-50" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb2-51"><a href="#cb2-51" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.major.y =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb2-52"><a href="#cb2-52" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb2-53"><a href="#cb2-53" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.margin =</span> <span class="fu">margin</span>(<span class="dv">10</span>, <span class="dv">90</span>, <span class="dv">10</span>, <span class="dv">10</span>)</span>
<span id="cb2-54"><a href="#cb2-54" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-55"><a href="#cb2-55" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<p>This function deliberately keeps the design simple:</p>
<ul>
<li>a dashed vertical line marks the null effect,</li>
<li>horizontal segments show 95% confidence intervals,</li>
<li>squares show subgroup estimates,</li>
<li>a diamond marks the overall estimate,</li>
<li>the formatted estimate text is printed to the right.</li>
</ul>
<p>That is the standard grammar of a forest plot. Readers familiar with trials and meta-analyses will recognize it immediately.</p>
</section>
<section id="step-3-draw-the-synthetic-forest-plot" class="level2" data-number="67.4">
<h2 data-number="67.4" class="anchored" data-anchor-id="step-3-draw-the-synthetic-forest-plot"><span class="header-section-number">67.4</span> Step 3: Draw the synthetic forest plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>synthetic_forest_plot <span class="ot">&lt;-</span> <span class="fu">build_forest_plot</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  synthetic_forest,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Forest plot for a synthetic readmission subgroup analysis"</span>,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Squares show subgroup estimates; the diamond shows the overall hazard ratio"</span></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>synthetic_forest_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/forest-plot_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure works because it lets the reader answer three questions quickly:</p>
<ol type="1">
<li>Are most estimates on the same side of the null?</li>
<li>Which subgroups are imprecise?</li>
<li>Does the overall effect look consistent with the subgroup pattern?</li>
</ol>
<p>The plot should not be used to claim subgroup heterogeneity just because some intervals cross 1 and others do not. It is a visual summary, not a formal interaction test.</p>
</section>
<section id="step-4-build-a-real-world-forest-plot-from-a-public-trial-dataset" class="level2" data-number="67.5">
<h2 data-number="67.5" class="anchored" data-anchor-id="step-4-build-a-real-world-forest-plot-from-a-public-trial-dataset"><span class="header-section-number">67.5</span> Step 4: Build a real-world forest plot from a public trial dataset</h2>
<p>To move from a synthetic example to a real one, we can use the public <code>colon</code> dataset distributed with the <code>survival</code> package. These data come from the adjuvant colon cancer trials reported by Laurie and colleagues and Moertel and colleagues <span class="citation" data-cites="laurie1989">Laurie et al. (<a href="#ref-laurie1989" role="doc-biblioref">1989</a>)</span>; <span class="citation" data-cites="moertel1990">Moertel et al. (<a href="#ref-moertel1990" role="doc-biblioref">1990</a>)</span>.</p>
<p>The original trial publications did not include exactly this modern subgroup forest plot. The figure below is therefore a transparent partial replication: it uses the public paper-linked dataset to estimate subgroup treatment hazard ratios for overall survival and then presents them in forest-plot form.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(survival)</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>colon_os <span class="ot">&lt;-</span> survival<span class="sc">::</span>colon <span class="sc">|&gt;</span></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">filter</span>(etype <span class="sc">==</span> <span class="dv">2</span>, rx <span class="sc">%in%</span> <span class="fu">c</span>(<span class="st">"Obs"</span>, <span class="st">"Lev+5FU"</span>)) <span class="sc">|&gt;</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">treatment =</span> <span class="fu">ifelse</span>(rx <span class="sc">==</span> <span class="st">"Lev+5FU"</span>, <span class="dv">1</span>, <span class="dv">0</span>)</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>extract_cox_row <span class="ot">&lt;-</span> <span class="cf">function</span>(data, label, <span class="at">row_type =</span> <span class="st">"Subgroup"</span>) {</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>  fit <span class="ot">&lt;-</span> survival<span class="sc">::</span><span class="fu">coxph</span>(survival<span class="sc">::</span><span class="fu">Surv</span>(time, status) <span class="sc">~</span> treatment, <span class="at">data =</span> data)</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  fit_summary <span class="ot">&lt;-</span> <span class="fu">summary</span>(fit)</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">subgroup =</span> label,</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">n =</span> <span class="fu">nrow</span>(data),</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">events =</span> <span class="fu">sum</span>(data<span class="sc">$</span>status),</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">estimate =</span> fit_summary<span class="sc">$</span>coefficients[, <span class="st">"exp(coef)"</span>][<span class="dv">1</span>],</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">conf_low =</span> fit_summary<span class="sc">$</span>conf.int[, <span class="st">"lower .95"</span>][<span class="dv">1</span>],</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">conf_high =</span> fit_summary<span class="sc">$</span>conf.int[, <span class="st">"upper .95"</span>][<span class="dv">1</span>],</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">weight =</span> <span class="fu">min</span>(<span class="dv">1</span>, <span class="fu">sqrt</span>(<span class="fu">nrow</span>(data) <span class="sc">/</span> <span class="fu">nrow</span>(colon_os))),</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">row_type =</span> row_type,</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">row.names =</span> <span class="cn">NULL</span></span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>colon_forest <span class="ot">&lt;-</span> dplyr<span class="sc">::</span><span class="fu">bind_rows</span>(</span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(colon_os, <span class="st">"Overall"</span>, <span class="at">row_type =</span> <span class="st">"Overall"</span>),</span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(dplyr<span class="sc">::</span><span class="fu">filter</span>(colon_os, age <span class="sc">&lt;</span> <span class="dv">65</span>), <span class="st">"Age &lt; 65"</span>),</span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(dplyr<span class="sc">::</span><span class="fu">filter</span>(colon_os, age <span class="sc">&gt;=</span> <span class="dv">65</span>), <span class="st">"Age &gt;= 65"</span>),</span>
<span id="cb4-30"><a href="#cb4-30" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(dplyr<span class="sc">::</span><span class="fu">filter</span>(colon_os, sex <span class="sc">==</span> <span class="dv">0</span>), <span class="st">"Female"</span>),</span>
<span id="cb4-31"><a href="#cb4-31" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(dplyr<span class="sc">::</span><span class="fu">filter</span>(colon_os, sex <span class="sc">==</span> <span class="dv">1</span>), <span class="st">"Male"</span>),</span>
<span id="cb4-32"><a href="#cb4-32" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(dplyr<span class="sc">::</span><span class="fu">filter</span>(colon_os, obstruct <span class="sc">==</span> <span class="dv">0</span>), <span class="st">"No obstruction"</span>),</span>
<span id="cb4-33"><a href="#cb4-33" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(dplyr<span class="sc">::</span><span class="fu">filter</span>(colon_os, obstruct <span class="sc">==</span> <span class="dv">1</span>), <span class="st">"Obstruction"</span>),</span>
<span id="cb4-34"><a href="#cb4-34" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(dplyr<span class="sc">::</span><span class="fu">filter</span>(colon_os, adhere <span class="sc">==</span> <span class="dv">1</span>), <span class="st">"Adherent"</span>),</span>
<span id="cb4-35"><a href="#cb4-35" aria-hidden="true" tabindex="-1"></a>  <span class="fu">extract_cox_row</span>(dplyr<span class="sc">::</span><span class="fu">filter</span>(colon_os, adhere <span class="sc">==</span> <span class="dv">0</span>), <span class="st">"Non-adherent"</span>)</span>
<span id="cb4-36"><a href="#cb4-36" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-37"><a href="#cb4-37" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-38"><a href="#cb4-38" aria-hidden="true" tabindex="-1"></a>colon_forest<span class="sc">$</span>estimate_label <span class="ot">&lt;-</span> <span class="fu">sprintf</span>(</span>
<span id="cb4-39"><a href="#cb4-39" aria-hidden="true" tabindex="-1"></a>  <span class="st">"%.2f (%.2f to %.2f)"</span>,</span>
<span id="cb4-40"><a href="#cb4-40" aria-hidden="true" tabindex="-1"></a>  colon_forest<span class="sc">$</span>estimate,</span>
<span id="cb4-41"><a href="#cb4-41" aria-hidden="true" tabindex="-1"></a>  colon_forest<span class="sc">$</span>conf_low,</span>
<span id="cb4-42"><a href="#cb4-42" aria-hidden="true" tabindex="-1"></a>  colon_forest<span class="sc">$</span>conf_high</span>
<span id="cb4-43"><a href="#cb4-43" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-44"><a href="#cb4-44" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-45"><a href="#cb4-45" aria-hidden="true" tabindex="-1"></a>colon_table <span class="ot">&lt;-</span> colon_forest <span class="sc">|&gt;</span></span>
<span id="cb4-46"><a href="#cb4-46" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">transmute</span>(</span>
<span id="cb4-47"><a href="#cb4-47" aria-hidden="true" tabindex="-1"></a>    subgroup,</span>
<span id="cb4-48"><a href="#cb4-48" aria-hidden="true" tabindex="-1"></a>    <span class="at">sample_size =</span> n,</span>
<span id="cb4-49"><a href="#cb4-49" aria-hidden="true" tabindex="-1"></a>    events,</span>
<span id="cb4-50"><a href="#cb4-50" aria-hidden="true" tabindex="-1"></a>    <span class="at">hazard_ratio =</span> <span class="fu">round</span>(estimate, <span class="dv">2</span>),</span>
<span id="cb4-51"><a href="#cb4-51" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower_95_ci =</span> <span class="fu">round</span>(conf_low, <span class="dv">2</span>),</span>
<span id="cb4-52"><a href="#cb4-52" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper_95_ci =</span> <span class="fu">round</span>(conf_high, <span class="dv">2</span>)</span>
<span id="cb4-53"><a href="#cb4-53" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-54"><a href="#cb4-54" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-55"><a href="#cb4-55" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-56"><a href="#cb4-56" aria-hidden="true" tabindex="-1"></a>  colon_table,</span>
<span id="cb4-57"><a href="#cb4-57" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Subgroup hazard ratios estimated from the public colon cancer trial dataset"</span></span>
<span id="cb4-58"><a href="#cb4-58" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Subgroup hazard ratios estimated from the public colon cancer trial dataset</caption>
<colgroup>
<col style="width: 21%">
<col style="width: 16%">
<col style="width: 9%">
<col style="width: 18%">
<col style="width: 16%">
<col style="width: 16%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">subgroup</th>
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">events</th>
<th style="text-align: right;">hazard_ratio</th>
<th style="text-align: right;">lower_95_ci</th>
<th style="text-align: right;">upper_95_ci</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Overall</td>
<td style="text-align: right;">619</td>
<td style="text-align: right;">291</td>
<td style="text-align: right;">0.69</td>
<td style="text-align: right;">0.55</td>
<td style="text-align: right;">0.87</td>
</tr>
<tr class="even">
<td style="text-align: left;">Age &lt; 65</td>
<td style="text-align: right;">376</td>
<td style="text-align: right;">173</td>
<td style="text-align: right;">0.70</td>
<td style="text-align: right;">0.52</td>
<td style="text-align: right;">0.95</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Age &gt;= 65</td>
<td style="text-align: right;">243</td>
<td style="text-align: right;">118</td>
<td style="text-align: right;">0.66</td>
<td style="text-align: right;">0.46</td>
<td style="text-align: right;">0.95</td>
</tr>
<tr class="even">
<td style="text-align: left;">Female</td>
<td style="text-align: right;">312</td>
<td style="text-align: right;">152</td>
<td style="text-align: right;">0.86</td>
<td style="text-align: right;">0.63</td>
<td style="text-align: right;">1.19</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Male</td>
<td style="text-align: right;">307</td>
<td style="text-align: right;">139</td>
<td style="text-align: right;">0.52</td>
<td style="text-align: right;">0.37</td>
<td style="text-align: right;">0.74</td>
</tr>
<tr class="even">
<td style="text-align: left;">No obstruction</td>
<td style="text-align: right;">502</td>
<td style="text-align: right;">231</td>
<td style="text-align: right;">0.69</td>
<td style="text-align: right;">0.53</td>
<td style="text-align: right;">0.90</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Obstruction</td>
<td style="text-align: right;">117</td>
<td style="text-align: right;">60</td>
<td style="text-align: right;">0.71</td>
<td style="text-align: right;">0.42</td>
<td style="text-align: right;">1.19</td>
</tr>
<tr class="even">
<td style="text-align: left;">Adherent</td>
<td style="text-align: right;">86</td>
<td style="text-align: right;">49</td>
<td style="text-align: right;">0.76</td>
<td style="text-align: right;">0.43</td>
<td style="text-align: right;">1.35</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Non-adherent</td>
<td style="text-align: right;">533</td>
<td style="text-align: right;">242</td>
<td style="text-align: right;">0.68</td>
<td style="text-align: right;">0.53</td>
<td style="text-align: right;">0.88</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table now contains real model outputs rather than hand-entered values. The next step is simply to hand that results table to the same plotting function.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>colon_forest_plot <span class="ot">&lt;-</span> <span class="fu">build_forest_plot</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  colon_forest,</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Forest plot of subgroup treatment effects in the public colon trial data"</span>,</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Hazard ratios for Levamisole + 5FU versus observation for overall survival"</span></span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>colon_forest_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/forest-plot_files/figure-html/unnamed-chunk-5-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The real-world figure follows the same design rules as the synthetic one, but now the rows come from a fitted Cox model in each subgroup. That is a common workflow in applied papers: estimate the model first, then construct a clean forest plot for reporting.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="67.6">
<h2 data-number="67.6" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">67.6</span> How to read the figure carefully</h2>
<p>Forest plots are powerful precisely because they compress a lot of information. That also makes them easy to overinterpret.</p>
<p>The most common mistake is to read every apparent subgroup difference as real effect modification. Overlapping and non-overlapping intervals can be suggestive, but the correct statistical question is usually whether a treatment-by-subgroup interaction is supported.</p>
<p>A second issue is scale. Ratio measures should usually be plotted on a log scale so that equal distances correspond to equal multiplicative changes.</p>
<p>A third issue is visual hierarchy. The forest plot should make the main signal easy to see without exaggerating certainty. Heavy colors, overly large symbols, or crowded labels can turn a useful figure into a misleading one.</p>
</section>
<section id="further-reading" class="level2" data-number="67.7">
<h2 data-number="67.7" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">67.7</span> Further reading</h2>
<p>Lewis and Clarke give one of the clearest short explanations of what forest plots are trying to accomplish and why they became so central in evidence synthesis <span class="citation" data-cites="lewis2001forest">Lewis and Clarke (<a href="#ref-lewis2001forest" role="doc-biblioref">2001</a>)</span>. The colon cancer trial papers by Laurie and colleagues and Moertel and colleagues provide a practical clinical context for subgroup reporting and effect-estimate visualization <span class="citation" data-cites="laurie1989">Laurie et al. (<a href="#ref-laurie1989" role="doc-biblioref">1989</a>)</span>; <span class="citation" data-cites="moertel1990">Moertel et al. (<a href="#ref-moertel1990" role="doc-biblioref">1990</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-laurie1989" class="csl-entry" role="listitem">
Laurie, John A., Charles G. Moertel, Thomas R. Fleming, H. S. Wieand, James E. Leigh, Joseph Rubin, G. W. McCormack, J. B. Gerstner, J. E. Krook, and James A. Mailliard. 1989. <span>"Surgical Adjuvant Therapy of Large-Bowel Carcinoma: An Evaluation of Levamisole and the Combination of Levamisole and Fluorouracil."</span> <em>Journal of Clinical Oncology</em> 7 (10): 1447-56. <a href="https://doi.org/10.1200/JCO.1989.7.10.1447">https://doi.org/10.1200/JCO.1989.7.10.1447</a>.
</div>
<div id="ref-lewis2001forest" class="csl-entry" role="listitem">
Lewis, Steff, and Mike Clarke. 2001. <span>"Forest Plots: Trying to See the Wood and the Trees."</span> <em>BMJ</em> 322 (7300): 1479-80. <a href="https://doi.org/10.1136/bmj.322.7300.1479">https://doi.org/10.1136/bmj.322.7300.1479</a>.
</div>
<div id="ref-moertel1990" class="csl-entry" role="listitem">
Moertel, Charles G., Thomas R. Fleming, John S. Macdonald, Daniel G. Haller, John A. Laurie, Phyllis J. Goodman, James S. Ungerleider, et al. 1990. <span>"Levamisole and Fluorouracil for Adjuvant Therapy of Resected Colon Carcinoma."</span> <em>New England Journal of Medicine</em> 322 (6): 352-58. <a href="https://doi.org/10.1056/NEJM199002083220602">https://doi.org/10.1056/NEJM199002083220602</a>.
</div>
</div>
</section>
