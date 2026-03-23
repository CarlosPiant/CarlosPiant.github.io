---
title: "Choropleth Maps for Regional Health Variation"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a choropleth map, a figure in which geographic areas are shaded according to a rate, proportion, or other area-level summary. Choropleth maps are useful in health research because many policy and..."
---
<p>This chapter builds a choropleth map, a figure in which geographic areas are shaded according to a rate, proportion, or other area-level summary. Choropleth maps are useful in health research because many policy and epidemiologic questions are fundamentally regional. Analysts often want to show how mortality, access, screening uptake, or disease burden varies across counties, districts, or states. Bivand, Pebesma, and Gomez-Rubio emphasize that mapped areal data are most informative when the quantity being mapped is chosen carefully and the geography is treated as part of the analysis rather than as decoration <span class="citation" data-cites="bivandpebesmagomez2013">Bivand, Pebesma, and Gómez-Rubio (<a href="#ref-bivandpebesmagomez2013" role="doc-biblioref">2013</a>)</span>. Pebesma's <code>sf</code> framework also made this type of spatial graphic much easier to build reproducibly in R <span class="citation" data-cites="pebesma2018sf">Pebesma (<a href="#ref-pebesma2018sf" role="doc-biblioref">2018</a>)</span>.</p>
<p>The key design principle is simple but important: choropleth maps should usually display rates rather than raw counts. Large regions often have large counts simply because they contain more people. If the purpose is to show regional health variation, the mapped quantity should usually normalize for population at risk or event exposure.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="60.1">
<h2 data-number="60.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">60.1</span> What the visualization is showing</h2>
<p>We will build a choropleth map in which:</p>
<ol type="1">
<li>each polygon is a region,</li>
<li>fill color represents a health rate,</li>
<li>darker colors indicate higher values,</li>
<li>region boundaries remain visible enough to preserve geographic structure.</li>
</ol>
<p>The figure is most useful when the outcome is naturally defined at an areal level, such as a county mortality rate, a district vaccination rate, or a state-level screening prevalence. The main reading rule is that the map should be interpreted as a regional surface: adjacent high-value regions suggest clustering, while isolated dark or light polygons may indicate local outliers or unstable small-area rates.</p>
</section>
<section id="step-1-create-a-synthetic-regional-health-rate-surface" class="level2" data-number="60.2">
<h2 data-number="60.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-regional-health-rate-surface"><span class="header-section-number">60.2</span> Step 1: Create a synthetic regional health-rate surface</h2>
<p>We begin with a synthetic map. The purpose is to show the mechanics of a choropleth without relying on real administrative boundaries. We will create a small grid of rectangular regions and assign each one a synthetic preventable-hospitalization rate.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(sf)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(viridisLite)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>format_numeric_table <span class="ot">&lt;-</span> <span class="cf">function</span>(df, <span class="at">digits =</span> <span class="dv">2</span>) {</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  numeric_cols <span class="ot">&lt;-</span> <span class="fu">vapply</span>(df, is.numeric, <span class="fu">logical</span>(<span class="dv">1</span>))</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  df[numeric_cols] <span class="ot">&lt;-</span> <span class="fu">lapply</span>(df[numeric_cols], round, <span class="at">digits =</span> digits)</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>  df</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2027</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>synthetic_bbox <span class="ot">&lt;-</span> <span class="fu">st_as_sfc</span>(</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">st_bbox</span>(<span class="fu">c</span>(<span class="at">xmin =</span> <span class="dv">0</span>, <span class="at">ymin =</span> <span class="dv">0</span>, <span class="at">xmax =</span> <span class="dv">6</span>, <span class="at">ymax =</span> <span class="dv">5</span>), <span class="at">crs =</span> <span class="fu">st_crs</span>(<span class="dv">3857</span>))</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>synthetic_grid <span class="ot">&lt;-</span> <span class="fu">st_make_grid</span>(synthetic_bbox, <span class="at">n =</span> <span class="fu">c</span>(<span class="dv">6</span>, <span class="dv">5</span>))</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>synthetic_map <span class="ot">&lt;-</span> <span class="fu">st_sf</span>(</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">region_id =</span> <span class="fu">seq_along</span>(synthetic_grid),</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">geometry =</span> synthetic_grid</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>centroids <span class="ot">&lt;-</span> <span class="fu">st_coordinates</span>(<span class="fu">st_point_on_surface</span>(<span class="fu">st_geometry</span>(synthetic_map)))</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>synthetic_map <span class="ot">&lt;-</span> synthetic_map <span class="sc">|&gt;</span></span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">col_id =</span> <span class="fu">round</span>(centroids[, <span class="st">"X"</span>] <span class="sc">-</span> <span class="fl">0.5</span>),</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">row_id =</span> <span class="fu">round</span>(centroids[, <span class="st">"Y"</span>] <span class="sc">-</span> <span class="fl">0.5</span>),</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">deprivation =</span> <span class="fl">0.7</span> <span class="sc">*</span> col_id <span class="sc">+</span> <span class="fl">0.4</span> <span class="sc">*</span> row_id <span class="sc">+</span> <span class="fu">rnorm</span>(<span class="fu">n</span>(), <span class="at">sd =</span> <span class="fl">0.35</span>),</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">primary_care_access =</span> <span class="fl">3.2</span> <span class="sc">-</span> <span class="fl">0.45</span> <span class="sc">*</span> col_id <span class="sc">+</span> <span class="fl">0.15</span> <span class="sc">*</span> row_id <span class="sc">+</span> <span class="fu">rnorm</span>(<span class="fu">n</span>(), <span class="at">sd =</span> <span class="fl">0.20</span>),</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">preventable_admission_rate =</span> <span class="fu">pmax</span>(</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>      <span class="dv">55</span> <span class="sc">+</span> <span class="dv">9</span> <span class="sc">*</span> deprivation <span class="sc">-</span> <span class="dv">6</span> <span class="sc">*</span> primary_care_access <span class="sc">+</span> <span class="fu">rnorm</span>(<span class="fu">n</span>(), <span class="at">sd =</span> <span class="dv">3</span>),</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>      <span class="dv">15</span></span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>    ),</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">region =</span> <span class="fu">paste0</span>(<span class="st">"Region "</span>, <span class="fu">sprintf</span>(<span class="st">"%02d"</span>, region_id))</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> synthetic_map <span class="sc">|&gt;</span></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  <span class="fu">st_drop_geometry</span>() <span class="sc">|&gt;</span></span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(preventable_admission_rate)) <span class="sc">|&gt;</span></span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  <span class="fu">select</span>(region, preventable_admission_rate, deprivation, primary_care_access) <span class="sc">|&gt;</span></span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>  <span class="fu">slice_head</span>(<span class="at">n =</span> <span class="dv">8</span>)</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_summary, <span class="at">digits =</span> <span class="dv">2</span>),</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Highest-rate regions in the synthetic choropleth example"</span></span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Highest-rate regions in the synthetic choropleth example</caption>
<colgroup>
<col style="width: 14%">
<col style="width: 39%">
<col style="width: 17%">
<col style="width: 28%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">region</th>
<th style="text-align: right;">preventable_admission_rate</th>
<th style="text-align: right;">deprivation</th>
<th style="text-align: right;">primary_care_access</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Region 30</td>
<td style="text-align: right;">97.18</td>
<td style="text-align: right;">5.33</td>
<td style="text-align: right;">1.78</td>
</tr>
<tr class="even">
<td style="text-align: left;">Region 24</td>
<td style="text-align: right;">86.34</td>
<td style="text-align: right;">4.27</td>
<td style="text-align: right;">1.11</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Region 06</td>
<td style="text-align: right;">83.99</td>
<td style="text-align: right;">3.76</td>
<td style="text-align: right;">0.80</td>
</tr>
<tr class="even">
<td style="text-align: left;">Region 28</td>
<td style="text-align: right;">82.65</td>
<td style="text-align: right;">3.80</td>
<td style="text-align: right;">2.11</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Region 29</td>
<td style="text-align: right;">80.89</td>
<td style="text-align: right;">4.48</td>
<td style="text-align: right;">1.90</td>
</tr>
<tr class="even">
<td style="text-align: left;">Region 23</td>
<td style="text-align: right;">80.65</td>
<td style="text-align: right;">4.09</td>
<td style="text-align: right;">1.98</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Region 12</td>
<td style="text-align: right;">80.14</td>
<td style="text-align: right;">3.72</td>
<td style="text-align: right;">1.00</td>
</tr>
<tr class="even">
<td style="text-align: left;">Region 17</td>
<td style="text-align: right;">79.20</td>
<td style="text-align: right;">3.96</td>
<td style="text-align: right;">1.86</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The synthetic data have a clear spatial logic. Regions farther to the upper right tend to have higher deprivation and weaker primary-care access, which translates into higher preventable-admission rates. That gives the map a meaningful pattern rather than random color noise.</p>
</section>
<section id="step-2-build-the-synthetic-choropleth-map" class="level2" data-number="60.3">
<h2 data-number="60.3" class="anchored" data-anchor-id="step-2-build-the-synthetic-choropleth-map"><span class="header-section-number">60.3</span> Step 2: Build the synthetic choropleth map</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(synthetic_map) <span class="sc">+</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_sf</span>(<span class="fu">aes</span>(<span class="at">fill =</span> preventable_admission_rate), <span class="at">color =</span> <span class="st">"white"</span>, <span class="at">linewidth =</span> <span class="fl">0.5</span>) <span class="sc">+</span></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">scale_fill_gradientn</span>(</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">colors =</span> viridisLite<span class="sc">::</span><span class="fu">magma</span>(<span class="dv">7</span>),</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">name =</span> <span class="st">"Rate per 1,000"</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"A choropleth map shows regional variation in a health rate"</span>,</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Synthetic preventable-admission rates across a grid of regions"</span>,</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">caption =</span> <span class="st">"Darker shading indicates higher rates"</span></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">axis.text =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">axis.title =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid =</span> <span class="fu">element_blank</span>()</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/choropleth-maps-regional-health-variation_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure works because it uses geography only for the job geography can do well. The map lets the reader see where high-rate regions cluster, whether there is a gradient across space, and whether a few polygons stand out from their neighbors.</p>
</section>
<section id="step-3-pair-the-map-with-a-compact-regional-summary" class="level2" data-number="60.4">
<h2 data-number="60.4" class="anchored" data-anchor-id="step-3-pair-the-map-with-a-compact-regional-summary"><span class="header-section-number">60.4</span> Step 3: Pair the map with a compact regional summary</h2>
<p>Maps are strongest when paired with a short table that names the most extreme regions directly. A reader can see the spatial pattern in the figure and then use the table to identify the regions precisely.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_distribution <span class="ot">&lt;-</span> synthetic_map <span class="sc">|&gt;</span></span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">st_drop_geometry</span>() <span class="sc">|&gt;</span></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarize</span>(</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">min_rate =</span> <span class="fu">min</span>(preventable_admission_rate),</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">median_rate =</span> <span class="fu">median</span>(preventable_admission_rate),</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">mean_rate =</span> <span class="fu">mean</span>(preventable_admission_rate),</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">max_rate =</span> <span class="fu">max</span>(preventable_admission_rate)</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_distribution, <span class="at">digits =</span> <span class="dv">2</span>),</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Distribution of rates in the synthetic choropleth example"</span></span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Distribution of rates in the synthetic choropleth example</caption>
<thead>
<tr class="header">
<th style="text-align: right;">min_rate</th>
<th style="text-align: right;">median_rate</th>
<th style="text-align: right;">mean_rate</th>
<th style="text-align: right;">max_rate</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">31.9</td>
<td style="text-align: right;">62.41</td>
<td style="text-align: right;">63.64</td>
<td style="text-align: right;">97.18</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This is also a good point to emphasize the main methodological caution: if these were event counts rather than rates, the map would mostly reflect where large populations happen to live. Choropleths are most defensible when the shading encodes a quantity that is comparable across areas.</p>
</section>
<section id="step-4-create-a-real-world-choropleth-map-from-public-health-data" class="level2" data-number="60.5">
<h2 data-number="60.5" class="anchored" data-anchor-id="step-4-create-a-real-world-choropleth-map-from-public-health-data"><span class="header-section-number">60.5</span> Step 4: Create a real-world choropleth map from public health data</h2>
<p>For a real-world example, we use the public North Carolina county dataset bundled with <code>sf</code>. These polygons include counts of births and sudden infant death cases in 1974 and 1979 and have long served as a teaching example in spatial epidemiology and disease mapping <span class="citation" data-cites="bivandpebesmagomez2013">Bivand, Pebesma, and Gómez-Rubio (<a href="#ref-bivandpebesmagomez2013" role="doc-biblioref">2013</a>)</span>; <span class="citation" data-cites="pebesma2018sf">Pebesma (<a href="#ref-pebesma2018sf" role="doc-biblioref">2018</a>)</span>. The figure below maps the 1979 sudden infant death syndrome rate per 1,000 births across counties.</p>
<p>This is a transparent partial application rather than a reconstruction of one published figure. The underlying public data are real, the health outcome is real, and the map is built for teaching the choropleth itself.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>nc <span class="ot">&lt;-</span> <span class="fu">st_read</span>(<span class="fu">system.file</span>(<span class="st">"shape/nc.shp"</span>, <span class="at">package =</span> <span class="st">"sf"</span>), <span class="at">quiet =</span> <span class="cn">TRUE</span>) <span class="sc">|&gt;</span></span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">sid_rate_79 =</span> <span class="dv">1000</span> <span class="sc">*</span> SID79 <span class="sc">/</span> BIR79,</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">nonwhite_birth_share_79 =</span> NWBIR79 <span class="sc">/</span> BIR79</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>nc_summary <span class="ot">&lt;-</span> nc <span class="sc">|&gt;</span></span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">st_drop_geometry</span>() <span class="sc">|&gt;</span></span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarize</span>(</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">counties =</span> <span class="fu">n</span>(),</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">total_births_1979 =</span> <span class="fu">sum</span>(BIR79),</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">total_sid_1979 =</span> <span class="fu">sum</span>(SID79),</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">mean_sid_rate_79 =</span> <span class="fu">mean</span>(sid_rate_79),</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">median_sid_rate_79 =</span> <span class="fu">median</span>(sid_rate_79)</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>nc_extremes <span class="ot">&lt;-</span> nc <span class="sc">|&gt;</span></span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">st_drop_geometry</span>() <span class="sc">|&gt;</span></span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">select</span>(NAME, BIR79, SID79, sid_rate_79) <span class="sc">|&gt;</span></span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(sid_rate_79)) <span class="sc">|&gt;</span></span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>  <span class="fu">slice_head</span>(<span class="at">n =</span> <span class="dv">8</span>)</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(nc_summary, <span class="at">digits =</span> <span class="dv">2</span>),</span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the public North Carolina county health-variation dataset"</span></span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the public North Carolina county health-variation dataset</caption>
<colgroup>
<col style="width: 11%">
<col style="width: 23%">
<col style="width: 19%">
<col style="width: 21%">
<col style="width: 24%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: right;">counties</th>
<th style="text-align: right;">total_births_1979</th>
<th style="text-align: right;">total_sid_1979</th>
<th style="text-align: right;">mean_sid_rate_79</th>
<th style="text-align: right;">median_sid_rate_79</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">100</td>
<td style="text-align: right;">422392</td>
<td style="text-align: right;">836</td>
<td style="text-align: right;">2.04</td>
<td style="text-align: right;">2.08</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(nc_extremes, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Highest county SIDS rates per 1,000 births in the 1979 North Carolina data"</span></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Highest county SIDS rates per 1,000 births in the 1979 North Carolina data</caption>
<thead>
<tr class="header">
<th style="text-align: left;">NAME</th>
<th style="text-align: right;">BIR79</th>
<th style="text-align: right;">SID79</th>
<th style="text-align: right;">sid_rate_79</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Scotland</td>
<td style="text-align: right;">2617</td>
<td style="text-align: right;">16</td>
<td style="text-align: right;">6.114</td>
</tr>
<tr class="even">
<td style="text-align: left;">Camden</td>
<td style="text-align: right;">350</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">5.714</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Alleghany</td>
<td style="text-align: right;">542</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">5.535</td>
</tr>
<tr class="even">
<td style="text-align: left;">Montgomery</td>
<td style="text-align: right;">1598</td>
<td style="text-align: right;">8</td>
<td style="text-align: right;">5.006</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Columbus</td>
<td style="text-align: right;">4144</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">4.102</td>
</tr>
<tr class="even">
<td style="text-align: left;">Halifax</td>
<td style="text-align: right;">4463</td>
<td style="text-align: right;">17</td>
<td style="text-align: right;">3.809</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Cleveland</td>
<td style="text-align: right;">5526</td>
<td style="text-align: right;">21</td>
<td style="text-align: right;">3.800</td>
</tr>
<tr class="even">
<td style="text-align: left;">Cabarrus</td>
<td style="text-align: right;">5669</td>
<td style="text-align: right;">20</td>
<td style="text-align: right;">3.528</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The rate is the right mapped quantity here because births vary substantially across counties. A map of raw SIDS counts would mostly show where there were more births, not where the rate of infant death was unusually high.</p>
</section>
<section id="step-5-draw-the-real-world-choropleth-map" class="level2" data-number="60.6">
<h2 data-number="60.6" class="anchored" data-anchor-id="step-5-draw-the-real-world-choropleth-map"><span class="header-section-number">60.6</span> Step 5: Draw the real-world choropleth map</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(nc) <span class="sc">+</span></span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_sf</span>(<span class="fu">aes</span>(<span class="at">fill =</span> sid_rate_79), <span class="at">color =</span> <span class="st">"grey95"</span>, <span class="at">linewidth =</span> <span class="fl">0.15</span>) <span class="sc">+</span></span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">scale_fill_gradientn</span>(</span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">colors =</span> viridisLite<span class="sc">::</span><span class="fu">viridis</span>(<span class="dv">7</span>),</span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">name =</span> <span class="st">"SIDS rate</span><span class="sc">\n</span><span class="st">per 1,000 births"</span></span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb7-8"><a href="#cb7-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Choropleth map of county-level infant mortality variation"</span>,</span>
<span id="cb7-9"><a href="#cb7-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Public North Carolina county SIDS rates in 1979 from the sf sample dataset"</span>,</span>
<span id="cb7-10"><a href="#cb7-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">caption =</span> <span class="st">"Mapped quantity is the rate, not the raw count of cases"</span></span>
<span id="cb7-11"><a href="#cb7-11" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb7-12"><a href="#cb7-12" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb7-13"><a href="#cb7-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb7-14"><a href="#cb7-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">axis.text =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb7-15"><a href="#cb7-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">axis.title =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb7-16"><a href="#cb7-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid =</span> <span class="fu">element_blank</span>()</span>
<span id="cb7-17"><a href="#cb7-17" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/choropleth-maps-regional-health-variation_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This real-world figure shows why choropleth maps are so useful for regional health variation. The map makes it possible to see geographic heterogeneity immediately, rather than forcing the reader to parse a county-by-county table. It also makes clear why the analyst should think carefully about regional interpretation: some dark counties are contiguous, while others are isolated and may reflect small-area volatility as much as true underlying risk.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="60.7">
<h2 data-number="60.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">60.7</span> How to read the figure carefully</h2>
<p>Choropleth maps are persuasive, which is exactly why they need discipline. First, area does not equal population. Large rural polygons can dominate the image even when they contain relatively few births or people. Second, mapped rates can be unstable in small regions. A county with few births can have a very high rate after only a small number of events. In applied work, that is one reason analysts often consider smoothing or empirical Bayes shrinkage before mapping.</p>
<p>Third, the choice of color scale matters. Sequential palettes work well for strictly ordered quantities like rates. Diverging palettes are better when there is a meaningful midpoint such as zero change or national average deviation. Finally, maps should usually be read together with a table or contextual note so that high-value regions can be identified precisely and not just visually.</p>
</section>
<section id="further-reading" class="level2" data-number="60.8">
<h2 data-number="60.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">60.8</span> Further reading</h2>
<p>For a broad treatment of areal data and mapping practice in R, Bivand, Pebesma, and Gomez-Rubio remain the core reference <span class="citation" data-cites="bivandpebesmagomez2013">Bivand, Pebesma, and Gómez-Rubio (<a href="#ref-bivandpebesmagomez2013" role="doc-biblioref">2013</a>)</span>. Pebesma's article on simple features is the key reference for modern spatial workflows in R <span class="citation" data-cites="pebesma2018sf">Pebesma (<a href="#ref-pebesma2018sf" role="doc-biblioref">2018</a>)</span>. For readers who want to move from descriptive maps to formal spatial analysis, the spatial-association and areal-data references already used elsewhere in the book are natural next steps <span class="citation" data-cites="bivandwong2018">Bivand and Wong (<a href="#ref-bivandwong2018" role="doc-biblioref">2018</a>)</span>; <span class="citation" data-cites="bivand2022areal">Bivand (<a href="#ref-bivand2022areal" role="doc-biblioref">2022</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-bivand2022areal" class="csl-entry" role="listitem">
Bivand, Roger. 2022. <span>"R Packages for Analyzing Spatial Data: A Comparative Case Study with Areal Data."</span> <em>Geographical Analysis</em> 54 (3): 488-518. <a href="https://doi.org/10.1111/gean.12319">https://doi.org/10.1111/gean.12319</a>.
</div>
<div id="ref-bivandpebesmagomez2013" class="csl-entry" role="listitem">
Bivand, Roger, Edzer Pebesma, and Virgilio Gómez-Rubio. 2013. <em>Applied Spatial Data Analysis with r</em>. Second. New York: Springer. <a href="https://asdar-book.org/">https://asdar-book.org/</a>.
</div>
<div id="ref-bivandwong2018" class="csl-entry" role="listitem">
Bivand, Roger, and David Wong. 2018. <span>"Comparing Implementations of Global and Local Indicators of Spatial Association."</span> <em>TEST</em> 27 (3): 716-48. <a href="https://doi.org/10.1007/s11749-018-0599-x">https://doi.org/10.1007/s11749-018-0599-x</a>.
</div>
<div id="ref-pebesma2018sf" class="csl-entry" role="listitem">
Pebesma, Edzer. 2018. <span>"Simple Features for <span>R</span>: Standardized Support for Spatial Vector Data."</span> <em>The R Journal</em> 10 (1): 439-46. <a href="https://doi.org/10.32614/RJ-2018-009">https://doi.org/10.32614/RJ-2018-009</a>.
</div>
</div>
</section>
