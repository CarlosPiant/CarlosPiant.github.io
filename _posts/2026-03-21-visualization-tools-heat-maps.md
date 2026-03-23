---
title: "Heat Maps"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a general heat map rather than a correlation-matrix heat map. The goal is to show how to display the intensity of an outcome across two dimensions such as time of day by day of week, age group by..."
---
<p>This chapter builds a general heat map rather than a correlation-matrix heat map. The goal is to show how to display the intensity of an outcome across two dimensions such as time of day by day of week, age group by deprivation group, or glucose level by body mass index. Heat maps are useful because they turn a large table of values into a visual surface that the eye can scan quickly for gradients, clusters, and peaks. Wilkinson and Friendly trace the broader history of the heat map as a shaded matrix display and show why it became such a flexible graphical tool across scientific fields <span class="citation" data-cites="wilkinsonfriendly2009">Wilkinson and Friendly (<a href="#ref-wilkinsonfriendly2009" role="doc-biblioref">2009</a>)</span>.</p>
<p>The figure we will build here is especially useful in applied health research when the analyst wants to show how a rate, count, or predicted probability changes over two interacting dimensions. Unlike a line plot, a heat map does not force one dimension to play the privileged role of the horizontal axis while the other is split into many small series. That makes it a natural choice when the interaction itself is the main message.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="59.1">
<h2 data-number="59.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">59.1</span> What the visualization is showing</h2>
<p>A heat map is a matrix of tiles. Each tile corresponds to a cell defined by one category or interval on the x-axis and another on the y-axis. The fill color represents the value in that cell.</p>
<p>The figure is most useful when:</p>
<ol type="1">
<li>the outcome is measured over a two-dimensional grid,</li>
<li>the reader needs to see high and low regions quickly,</li>
<li>interactions matter more than individual marginal trends.</li>
</ol>
<p>The key reading rule is simple: darker or more saturated tiles represent larger values, lighter tiles represent smaller values, and neighboring tiles should be interpreted as part of a surface rather than as isolated bars.</p>
</section>
<section id="step-1-create-a-synthetic-health-services-intensity-example" class="level2" data-number="59.2">
<h2 data-number="59.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-health-services-intensity-example"><span class="header-section-number">59.2</span> Step 1: Create a synthetic health-services intensity example</h2>
<p>We begin with a synthetic example showing average hourly urgent-care demand by day of week. This is a good use case for a heat map because the analyst cares about joint timing structure, not only daily totals or hourly averages in isolation.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>format_numeric_table <span class="ot">&lt;-</span> <span class="cf">function</span>(df, <span class="at">digits =</span> <span class="dv">2</span>) {</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  numeric_cols <span class="ot">&lt;-</span> <span class="fu">vapply</span>(df, is.numeric, <span class="fu">logical</span>(<span class="dv">1</span>))</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  df[numeric_cols] <span class="ot">&lt;-</span> <span class="fu">lapply</span>(df[numeric_cols], round, <span class="at">digits =</span> digits)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  df</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>days <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="st">"Mon"</span>, <span class="st">"Tue"</span>, <span class="st">"Wed"</span>, <span class="st">"Thu"</span>, <span class="st">"Fri"</span>, <span class="st">"Sat"</span>, <span class="st">"Sun"</span>)</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>hours <span class="ot">&lt;-</span> <span class="dv">0</span><span class="sc">:</span><span class="dv">23</span></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>synthetic_heat <span class="ot">&lt;-</span> <span class="fu">expand.grid</span>(</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">day =</span> <span class="fu">factor</span>(days, <span class="at">levels =</span> days),</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">hour =</span> hours</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>day_effect <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="at">Mon =</span> <span class="fl">1.05</span>, <span class="at">Tue =</span> <span class="fl">1.00</span>, <span class="at">Wed =</span> <span class="fl">1.02</span>, <span class="at">Thu =</span> <span class="fl">1.08</span>, <span class="at">Fri =</span> <span class="fl">1.18</span>, <span class="at">Sat =</span> <span class="fl">0.88</span>, <span class="at">Sun =</span> <span class="fl">0.80</span>)</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>synthetic_heat<span class="sc">$</span>baseline_pattern <span class="ot">&lt;-</span></span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  <span class="dv">7</span> <span class="sc">+</span></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  <span class="dv">14</span> <span class="sc">*</span> <span class="fu">exp</span>(<span class="sc">-</span>((synthetic_heat<span class="sc">$</span>hour <span class="sc">-</span> <span class="dv">10</span>) <span class="sc">/</span> <span class="fl">4.2</span>)<span class="sc">^</span><span class="dv">2</span>) <span class="sc">+</span></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="dv">18</span> <span class="sc">*</span> <span class="fu">exp</span>(<span class="sc">-</span>((synthetic_heat<span class="sc">$</span>hour <span class="sc">-</span> <span class="dv">18</span>) <span class="sc">/</span> <span class="fl">3.3</span>)<span class="sc">^</span><span class="dv">2</span>)</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>synthetic_heat<span class="sc">$</span>expected_visits <span class="ot">&lt;-</span></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>  synthetic_heat<span class="sc">$</span>baseline_pattern <span class="sc">*</span> day_effect[<span class="fu">as.character</span>(synthetic_heat<span class="sc">$</span>day)] <span class="sc">+</span></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ifelse</span>(synthetic_heat<span class="sc">$</span>day <span class="sc">%in%</span> <span class="fu">c</span>(<span class="st">"Sat"</span>, <span class="st">"Sun"</span>) <span class="sc">&amp;</span> synthetic_heat<span class="sc">$</span>hour <span class="sc">%in%</span> <span class="dv">12</span><span class="sc">:</span><span class="dv">16</span>, <span class="sc">-</span><span class="dv">3</span>, <span class="dv">0</span>) <span class="sc">+</span></span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ifelse</span>(synthetic_heat<span class="sc">$</span>day <span class="sc">==</span> <span class="st">"Mon"</span> <span class="sc">&amp;</span> synthetic_heat<span class="sc">$</span>hour <span class="sc">%in%</span> <span class="dv">7</span><span class="sc">:</span><span class="dv">10</span>, <span class="dv">4</span>, <span class="dv">0</span>)</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>synthetic_heat<span class="sc">$</span>mean_visits <span class="ot">&lt;-</span> <span class="fu">pmax</span>(</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(synthetic_heat<span class="sc">$</span>expected_visits <span class="sc">+</span> <span class="fu">rnorm</span>(<span class="fu">nrow</span>(synthetic_heat), <span class="at">sd =</span> <span class="fl">1.2</span>), <span class="dv">1</span>),</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  <span class="dv">0</span></span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> synthetic_heat <span class="sc">|&gt;</span></span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>  <span class="fu">group_by</span>(day) <span class="sc">|&gt;</span></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarise</span>(</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">mean_daily_hourly_visits =</span> <span class="fu">mean</span>(mean_visits),</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>    <span class="at">peak_hour =</span> hour[<span class="fu">which.max</span>(mean_visits)],</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>    <span class="at">peak_visits =</span> <span class="fu">max</span>(mean_visits),</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>    <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_summary, <span class="at">digits =</span> <span class="dv">2</span>),</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the synthetic urgent-care demand surface"</span></span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the synthetic urgent-care demand surface</caption>
<thead>
<tr class="header">
<th style="text-align: left;">day</th>
<th style="text-align: right;">mean_daily_hourly_visits</th>
<th style="text-align: right;">peak_hour</th>
<th style="text-align: right;">peak_visits</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Mon</td>
<td style="text-align: right;">16.99</td>
<td style="text-align: right;">10</td>
<td style="text-align: right;">26.7</td>
</tr>
<tr class="even">
<td style="text-align: left;">Tue</td>
<td style="text-align: right;">15.69</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">26.6</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Wed</td>
<td style="text-align: right;">16.31</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">27.3</td>
</tr>
<tr class="even">
<td style="text-align: left;">Thu</td>
<td style="text-align: right;">16.41</td>
<td style="text-align: right;">18</td>
<td style="text-align: right;">28.6</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Fri</td>
<td style="text-align: right;">18.75</td>
<td style="text-align: right;">18</td>
<td style="text-align: right;">29.9</td>
</tr>
<tr class="even">
<td style="text-align: left;">Sat</td>
<td style="text-align: right;">13.08</td>
<td style="text-align: right;">18</td>
<td style="text-align: right;">25.5</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Sun</td>
<td style="text-align: right;">12.10</td>
<td style="text-align: right;">18</td>
<td style="text-align: right;">21.0</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The table is readable, but it loses the interaction structure. To see when demand concentrates jointly by day and hour, we need the heat map itself.</p>
</section>
<section id="step-2-build-the-synthetic-heat-map" class="level2" data-number="59.3">
<h2 data-number="59.3" class="anchored" data-anchor-id="step-2-build-the-synthetic-heat-map"><span class="header-section-number">59.3</span> Step 2: Build the synthetic heat map</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(synthetic_heat, <span class="fu">aes</span>(<span class="at">x =</span> day, <span class="at">y =</span> <span class="fu">factor</span>(hour), <span class="at">fill =</span> mean_visits)) <span class="sc">+</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_tile</span>(<span class="at">color =</span> <span class="st">"white"</span>, <span class="at">linewidth =</span> <span class="fl">0.5</span>) <span class="sc">+</span></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">scale_fill_gradient</span>(</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">low =</span> <span class="st">"#f7fbff"</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">high =</span> <span class="st">"#08306b"</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Synthetic urgent-care demand varies jointly by day and hour"</span>,</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Heat maps are useful when the interaction structure is the main message"</span>,</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="cn">NULL</span>,</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Hour of day"</span>,</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"Mean visits"</span></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid =</span> <span class="fu">element_blank</span>()</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/heat-maps_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure makes the demand surface immediately visible. The Monday morning intensity and Friday evening peak are easy to spot, and the weekend lull is clear without reading dozens of separate numbers. That is exactly what a heat map should do well.</p>
</section>
<section id="step-3-identify-the-most-intense-cells" class="level2" data-number="59.4">
<h2 data-number="59.4" class="anchored" data-anchor-id="step-3-identify-the-most-intense-cells"><span class="header-section-number">59.4</span> Step 3: Identify the most intense cells</h2>
<p>It is often helpful to pair a heat map with a short ranked table of the most important cells.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>top_synthetic_cells <span class="ot">&lt;-</span> synthetic_heat <span class="sc">|&gt;</span></span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(mean_visits)) <span class="sc">|&gt;</span></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">slice_head</span>(<span class="at">n =</span> <span class="dv">8</span>) <span class="sc">|&gt;</span></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">select</span>(day, hour, mean_visits)</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(top_synthetic_cells, <span class="at">digits =</span> <span class="dv">1</span>),</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Highest-intensity cells in the synthetic heat map"</span></span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Highest-intensity cells in the synthetic heat map</caption>
<thead>
<tr class="header">
<th style="text-align: left;">day</th>
<th style="text-align: right;">hour</th>
<th style="text-align: right;">mean_visits</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Fri</td>
<td style="text-align: right;">18</td>
<td style="text-align: right;">29.9</td>
</tr>
<tr class="even">
<td style="text-align: left;">Fri</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">29.7</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Thu</td>
<td style="text-align: right;">18</td>
<td style="text-align: right;">28.6</td>
</tr>
<tr class="even">
<td style="text-align: left;">Fri</td>
<td style="text-align: right;">19</td>
<td style="text-align: right;">28.4</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Wed</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">27.3</td>
</tr>
<tr class="even">
<td style="text-align: left;">Mon</td>
<td style="text-align: right;">10</td>
<td style="text-align: right;">26.7</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Tue</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">26.6</td>
</tr>
<tr class="even">
<td style="text-align: left;">Thu</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">26.5</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This combination works well in teaching and reporting. The figure gives the global pattern, and the small table names the local peaks precisely.</p>
</section>
<section id="step-4-create-a-real-world-risk-heat-map-from-a-public-scientific-dataset" class="level2" data-number="59.5">
<h2 data-number="59.5" class="anchored" data-anchor-id="step-4-create-a-real-world-risk-heat-map-from-a-public-scientific-dataset"><span class="header-section-number">59.5</span> Step 4: Create a real-world risk heat map from a public scientific dataset</h2>
<p>For a real-world example, we use the public Pima diabetes data distributed with <code>MASS</code>, linked to the classification problem studied by Smith and colleagues <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>. The figure will show observed diabetes prevalence across bins of plasma glucose and body mass index. This is a transparent partial application rather than a literal recreation of a figure in the original paper. The paper is the scientific source of the dataset and prediction problem, while the heat map is a teaching visualization built on the public data.</p>
<p>The point of the figure is to show how diabetes prevalence changes jointly over two clinically meaningful dimensions. A table could report prevalence in each bin, but a heat map makes the risk surface much easier to interpret.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.tr"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.te"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>pima_all <span class="ot">&lt;-</span> <span class="fu">rbind</span>(Pima.tr, Pima.te)</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>pima_all<span class="sc">$</span>diabetes <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(pima_all<span class="sc">$</span>type <span class="sc">==</span> <span class="st">"Yes"</span>)</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>glu_breaks <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="dv">80</span>, <span class="dv">100</span>, <span class="dv">120</span>, <span class="dv">140</span>, <span class="dv">160</span>, <span class="dv">200</span>)</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>bmi_breaks <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="dv">18</span>, <span class="dv">25</span>, <span class="dv">30</span>, <span class="dv">35</span>, <span class="dv">40</span>, <span class="dv">50</span>)</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>pima_all<span class="sc">$</span>glu_group <span class="ot">&lt;-</span> <span class="fu">cut</span>(</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>  pima_all<span class="sc">$</span>glu,</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">breaks =</span> glu_breaks,</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">include.lowest =</span> <span class="cn">TRUE</span>,</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">right =</span> <span class="cn">FALSE</span></span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>pima_all<span class="sc">$</span>bmi_group <span class="ot">&lt;-</span> <span class="fu">cut</span>(</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  pima_all<span class="sc">$</span>bmi,</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">breaks =</span> bmi_breaks,</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">include.lowest =</span> <span class="cn">TRUE</span>,</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">right =</span> <span class="cn">FALSE</span></span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>risk_heat <span class="ot">&lt;-</span> pima_all <span class="sc">|&gt;</span></span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(<span class="sc">!</span><span class="fu">is.na</span>(glu_group), <span class="sc">!</span><span class="fu">is.na</span>(bmi_group)) <span class="sc">|&gt;</span></span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>  <span class="fu">group_by</span>(glu_group, bmi_group) <span class="sc">|&gt;</span></span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarise</span>(</span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">n =</span> <span class="fu">n</span>(),</span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">diabetes_prevalence =</span> <span class="fu">mean</span>(diabetes),</span>
<span id="cb5-30"><a href="#cb5-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb5-31"><a href="#cb5-31" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-32"><a href="#cb5-32" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-33"><a href="#cb5-33" aria-hidden="true" tabindex="-1"></a>risk_heat<span class="sc">$</span>glu_group <span class="ot">&lt;-</span> <span class="fu">factor</span>(risk_heat<span class="sc">$</span>glu_group, <span class="at">levels =</span> <span class="fu">levels</span>(pima_all<span class="sc">$</span>glu_group))</span>
<span id="cb5-34"><a href="#cb5-34" aria-hidden="true" tabindex="-1"></a>risk_heat<span class="sc">$</span>bmi_group <span class="ot">&lt;-</span> <span class="fu">factor</span>(risk_heat<span class="sc">$</span>bmi_group, <span class="at">levels =</span> <span class="fu">rev</span>(<span class="fu">levels</span>(pima_all<span class="sc">$</span>bmi_group)))</span>
<span id="cb5-35"><a href="#cb5-35" aria-hidden="true" tabindex="-1"></a>risk_heat<span class="sc">$</span>prevalence_display <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(risk_heat<span class="sc">$</span>n <span class="sc">&gt;=</span> <span class="dv">5</span>, risk_heat<span class="sc">$</span>diabetes_prevalence, <span class="cn">NA_real_</span>)</span>
<span id="cb5-36"><a href="#cb5-36" aria-hidden="true" tabindex="-1"></a>risk_heat<span class="sc">$</span>prevalence_label <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(<span class="fu">is.na</span>(risk_heat<span class="sc">$</span>prevalence_display), <span class="st">""</span>, <span class="fu">sprintf</span>(<span class="st">"%.2f"</span>, risk_heat<span class="sc">$</span>prevalence_display))</span>
<span id="cb5-37"><a href="#cb5-37" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-38"><a href="#cb5-38" aria-hidden="true" tabindex="-1"></a>risk_summary <span class="ot">&lt;-</span> risk_heat <span class="sc">|&gt;</span></span>
<span id="cb5-39"><a href="#cb5-39" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(n <span class="sc">&gt;=</span> <span class="dv">5</span>) <span class="sc">|&gt;</span></span>
<span id="cb5-40"><a href="#cb5-40" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(diabetes_prevalence), <span class="fu">desc</span>(n)) <span class="sc">|&gt;</span></span>
<span id="cb5-41"><a href="#cb5-41" aria-hidden="true" tabindex="-1"></a>  <span class="fu">slice_head</span>(<span class="at">n =</span> <span class="dv">8</span>)</span>
<span id="cb5-42"><a href="#cb5-42" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-43"><a href="#cb5-43" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-44"><a href="#cb5-44" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(</span>
<span id="cb5-45"><a href="#cb5-45" aria-hidden="true" tabindex="-1"></a>    risk_summary[, <span class="fu">c</span>(<span class="st">"glu_group"</span>, <span class="st">"bmi_group"</span>, <span class="st">"n"</span>, <span class="st">"diabetes_prevalence"</span>)],</span>
<span id="cb5-46"><a href="#cb5-46" aria-hidden="true" tabindex="-1"></a>    <span class="at">digits =</span> <span class="dv">3</span></span>
<span id="cb5-47"><a href="#cb5-47" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb5-48"><a href="#cb5-48" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Highest-prevalence cells in the public Pima diabetes heat map"</span></span>
<span id="cb5-49"><a href="#cb5-49" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Highest-prevalence cells in the public Pima diabetes heat map</caption>
<thead>
<tr class="header">
<th style="text-align: left;">glu_group</th>
<th style="text-align: left;">bmi_group</th>
<th style="text-align: right;">n</th>
<th style="text-align: right;">diabetes_prevalence</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">[160,200]</td>
<td style="text-align: left;">[35,40)</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">0.941</td>
</tr>
<tr class="even">
<td style="text-align: left;">[160,200]</td>
<td style="text-align: left;">[40,50]</td>
<td style="text-align: right;">15</td>
<td style="text-align: right;">0.867</td>
</tr>
<tr class="odd">
<td style="text-align: left;">[160,200]</td>
<td style="text-align: left;">[30,35)</td>
<td style="text-align: right;">29</td>
<td style="text-align: right;">0.828</td>
</tr>
<tr class="even">
<td style="text-align: left;">[160,200]</td>
<td style="text-align: left;">[25,30)</td>
<td style="text-align: right;">7</td>
<td style="text-align: right;">0.714</td>
</tr>
<tr class="odd">
<td style="text-align: left;">[140,160)</td>
<td style="text-align: left;">[35,40)</td>
<td style="text-align: right;">14</td>
<td style="text-align: right;">0.643</td>
</tr>
<tr class="even">
<td style="text-align: left;">[120,140)</td>
<td style="text-align: left;">[40,50]</td>
<td style="text-align: right;">13</td>
<td style="text-align: right;">0.615</td>
</tr>
<tr class="odd">
<td style="text-align: left;">[140,160)</td>
<td style="text-align: left;">[30,35)</td>
<td style="text-align: right;">24</td>
<td style="text-align: right;">0.542</td>
</tr>
<tr class="even">
<td style="text-align: left;">[140,160)</td>
<td style="text-align: left;">[40,50]</td>
<td style="text-align: right;">14</td>
<td style="text-align: right;">0.500</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-5-draw-the-real-world-heat-map" class="level2" data-number="59.6">
<h2 data-number="59.6" class="anchored" data-anchor-id="step-5-draw-the-real-world-heat-map"><span class="header-section-number">59.6</span> Step 5: Draw the real-world heat map</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(risk_heat, <span class="fu">aes</span>(<span class="at">x =</span> glu_group, <span class="at">y =</span> bmi_group, <span class="at">fill =</span> prevalence_display)) <span class="sc">+</span></span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_tile</span>(<span class="at">color =</span> <span class="st">"white"</span>, <span class="at">linewidth =</span> <span class="fl">0.6</span>) <span class="sc">+</span></span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_text</span>(<span class="fu">aes</span>(<span class="at">label =</span> prevalence_label), <span class="at">size =</span> <span class="fl">3.1</span>) <span class="sc">+</span></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">scale_fill_gradient</span>(</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">low =</span> <span class="st">"#fff5f0"</span>,</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">high =</span> <span class="st">"#99000d"</span></span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Observed diabetes prevalence rises across glucose and BMI categories"</span>,</span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Public Pima diabetes data linked to Smith et al. (1988)"</span>,</span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Plasma glucose category"</span>,</span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Body mass index category"</span>,</span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"Prevalence"</span></span>
<span id="cb6-14"><a href="#cb6-14" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-15"><a href="#cb6-15" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb6-16"><a href="#cb6-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb6-17"><a href="#cb6-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb6-18"><a href="#cb6-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">axis.text.x =</span> <span class="fu">element_text</span>(<span class="at">angle =</span> <span class="dv">20</span>, <span class="at">hjust =</span> <span class="dv">1</span>)</span>
<span id="cb6-19"><a href="#cb6-19" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/heat-maps_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The real-world figure shows why heat maps are valuable for risk communication. The reader can see immediately that high glucose and high BMI cells concentrate much larger diabetes prevalence than the low-glucose, lower-BMI cells. A line plot would force one of those variables into the background. The heat map keeps both dimensions central.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="59.7">
<h2 data-number="59.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">59.7</span> How to read the figure carefully</h2>
<p>Heat maps are powerful because they compress a lot of information, but they also require care. First, the choice of bin boundaries matters. Different glucose or BMI intervals would change the appearance of the surface, especially in small datasets. Second, some cells may contain few observations, so visually striking tiles should be checked against their sample size before being overinterpreted.</p>
<p>It is also important to remember that a heat map is usually descriptive. In the Pima example, a dark cell does not mean glucose and BMI jointly cause diabetes in a simple deterministic way. It means that, in the observed sample, prevalence is high in that part of the two-dimensional predictor space.</p>
<p>Finally, color scales matter. Sequential palettes work well when the value goes from low to high. Diverging palettes are better when zero or another midpoint is substantively important. Choosing the wrong palette can make the figure harder to interpret than the underlying table.</p>
</section>
<section id="how-this-figure-complements-the-rest-of-the-book" class="level2" data-number="59.8">
<h2 data-number="59.8" class="anchored" data-anchor-id="how-this-figure-complements-the-rest-of-the-book"><span class="header-section-number">59.8</span> How this figure complements the rest of the book</h2>
<p>Heat maps are useful across many parts of the tutorial collection. In epidemiology they can show age-by-time incidence intensity. In health economics they can show uptake or spending by risk group and insurance type. In machine learning they can display predicted risk surfaces, confusion structures, or hyperparameter grids. In decision sciences they can show threshold-dependent policy recommendations over two varying parameters.</p>
<p>The key lesson is that heat maps are not just attractive graphics. They are compact two-dimensional summaries that help the reader see where outcomes, risks, or counts concentrate.</p>
</section>
<section id="further-reading" class="level2" data-number="59.9">
<h2 data-number="59.9" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">59.9</span> Further reading</h2>
<p>Wilkinson and Friendly provide a concise historical discussion of the heat map as a scientific display and explain how clustered heat maps emerged from older matrix-shading traditions <span class="citation" data-cites="wilkinsonfriendly2009">Wilkinson and Friendly (<a href="#ref-wilkinsonfriendly2009" role="doc-biblioref">2009</a>)</span>. For the real-world prediction setting used here, Smith and colleagues provide the original diabetes-classification application behind the public Pima data <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>. A natural next step after this chapter is to compare a simple descriptive heat map like this one with a model-based prediction surface built from logistic regression or another flexible model.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-smith1988" class="csl-entry" role="listitem">
Smith, J. W., J. E. Everhart, W. C. Dickson, W. C. Knowler, and R. S. Johannes. 1988. <span>"Using the <span>ADAP</span> Learning Algorithm to Forecast the Onset of Diabetes Mellitus."</span> In <em>Proceedings of the Symposium on Computer Applications in Medical Care</em>, 261-65.
</div>
<div id="ref-wilkinsonfriendly2009" class="csl-entry" role="listitem">
Wilkinson, Leland, and Michael Friendly. 2009. <span>"The History of the Cluster Heat Map."</span> <em>The American Statistician</em> 63 (2): 179-84. <a href="https://doi.org/10.1198/tas.2009.0033">https://doi.org/10.1198/tas.2009.0033</a>.
</div>
</div>
</section>
