---
title: "Temporal Series"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a temporal-series plot rather than a cross-sectional line chart. The goal is to show how an outcome evolves over time while preserving the two features that matter most in applied health data:..."
---
<p>This chapter builds a temporal-series plot rather than a cross-sectional line chart. The goal is to show how an outcome evolves over time while preserving the two features that matter most in applied health data: short-run fluctuation and longer-run movement. A good temporal-series figure makes it possible to see seasonality, secular trend, abrupt level shifts, and unusual months without forcing the reader to inspect a dense table of dates and values. Diggle's biostatistical time-series text is a natural reference point for this kind of health application, while Wickham's grammar of graphics provides a practical framework for turning the series into a clear, publication-ready figure <span class="citation" data-cites="diggle1990">Diggle (<a href="#ref-diggle1990" role="doc-biblioref">1990</a>)</span>; <span class="citation" data-cites="wickham2016ggplot2">Wickham (<a href="#ref-wickham2016ggplot2" role="doc-biblioref">2016</a>)</span>.</p>
<p>The specific figure we will build is a two-layer time-series display: a thin line for the raw monthly series and a thicker line for a 12-month moving average. This is a useful default in health economics, epidemiology, and outcomes research because the raw line shows the month-to-month data actually observed, while the smoother overlay helps the reader focus on the underlying direction of change.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="61.1">
<h2 data-number="61.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">61.1</span> What the visualization is showing</h2>
<p>A temporal-series plot places time on the horizontal axis and the observed outcome on the vertical axis. In this chapter, the figure contains two visual summaries of the same series:</p>
<ol type="1">
<li>a raw monthly line,</li>
<li>a 12-month moving-average line.</li>
</ol>
<p>This figure is useful when:</p>
<ol type="1">
<li>the analyst needs to show how an outcome changes over time,</li>
<li>seasonal noise should remain visible but not dominate the message,</li>
<li>the audience needs to distinguish temporary variation from sustained movement.</li>
</ol>
<p>The key reading rule is simple. The thin line shows the actual observed pattern, including spikes and dips. The thicker moving-average line should be read as the medium-run trajectory. When the two lines diverge temporarily, that usually indicates short-run volatility or seasonality rather than a structural change in the whole series.</p>
</section>
<section id="step-1-create-a-synthetic-health-services-time-series" class="level2" data-number="61.2">
<h2 data-number="61.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-health-services-time-series"><span class="header-section-number">61.2</span> Step 1: Create a synthetic health-services time series</h2>
<p>We begin with a synthetic monthly series for preventable emergency admissions. This is a good teaching example because the data contain several common features at once: winter seasonality, a slow upward baseline trend, and a policy change that reduces admissions after a transitional date.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>format_numeric_table <span class="ot">&lt;-</span> <span class="cf">function</span>(df, <span class="at">digits =</span> <span class="dv">2</span>) {</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  numeric_cols <span class="ot">&lt;-</span> <span class="fu">vapply</span>(df, is.numeric, <span class="fu">logical</span>(<span class="dv">1</span>))</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  df[numeric_cols] <span class="ot">&lt;-</span> <span class="fu">lapply</span>(df[numeric_cols], round, <span class="at">digits =</span> digits)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  df</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>moving_average <span class="ot">&lt;-</span> <span class="cf">function</span>(x, <span class="at">k =</span> <span class="dv">12</span>) {</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  <span class="fu">as.numeric</span>(stats<span class="sc">::</span><span class="fu">filter</span>(x, <span class="fu">rep</span>(<span class="dv">1</span> <span class="sc">/</span> k, k), <span class="at">sides =</span> <span class="dv">2</span>))</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>n_months <span class="ot">&lt;-</span> <span class="dv">72</span></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>synthetic_dates <span class="ot">&lt;-</span> <span class="fu">seq.Date</span>(<span class="fu">as.Date</span>(<span class="st">"2019-01-01"</span>), <span class="at">by =</span> <span class="st">"month"</span>, <span class="at">length.out =</span> n_months)</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>t <span class="ot">&lt;-</span> <span class="fu">seq_len</span>(n_months)</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>seasonal_pattern <span class="ot">&lt;-</span></span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="dv">16</span> <span class="sc">*</span> <span class="fu">sin</span>(<span class="dv">2</span> <span class="sc">*</span> pi <span class="sc">*</span> t <span class="sc">/</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="dv">10</span> <span class="sc">*</span> <span class="fu">cos</span>(<span class="dv">2</span> <span class="sc">*</span> pi <span class="sc">*</span> t <span class="sc">/</span> <span class="dv">12</span>)</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>baseline_trend <span class="ot">&lt;-</span> <span class="dv">185</span> <span class="sc">+</span> <span class="fl">0.75</span> <span class="sc">*</span> t</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>policy_effect <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(synthetic_dates <span class="sc">&gt;=</span> <span class="fu">as.Date</span>(<span class="st">"2022-07-01"</span>), <span class="sc">-</span><span class="dv">22</span>, <span class="dv">0</span>)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>noise <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_months, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="fl">6.5</span>)</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>synthetic_series <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">date =</span> synthetic_dates,</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">admissions =</span> baseline_trend <span class="sc">+</span> seasonal_pattern <span class="sc">+</span> policy_effect <span class="sc">+</span> noise</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>) <span class="sc">|&gt;</span></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">admissions =</span> <span class="fu">round</span>(admissions, <span class="dv">1</span>),</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">ma12 =</span> <span class="fu">moving_average</span>(admissions, <span class="at">k =</span> <span class="dv">12</span>),</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">year =</span> <span class="fu">format</span>(date, <span class="st">"%Y"</span>),</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">month =</span> <span class="fu">format</span>(date, <span class="st">"%m"</span>)</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> synthetic_series <span class="sc">|&gt;</span></span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">group_by</span>(year) <span class="sc">|&gt;</span></span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarise</span>(</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">mean_monthly_admissions =</span> <span class="fu">mean</span>(admissions),</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">winter_peak =</span> <span class="fu">max</span>(admissions[month <span class="sc">%in%</span> <span class="fu">c</span>(<span class="st">"12"</span>, <span class="st">"01"</span>, <span class="st">"02"</span>)]),</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">annual_minimum =</span> <span class="fu">min</span>(admissions),</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>    <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_summary, <span class="at">digits =</span> <span class="dv">1</span>),</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Yearly summary of the synthetic preventable-admissions series"</span></span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Yearly summary of the synthetic preventable-admissions series</caption>
<thead>
<tr class="header">
<th style="text-align: left;">year</th>
<th style="text-align: right;">mean_monthly_admissions</th>
<th style="text-align: right;">winter_peak</th>
<th style="text-align: right;">annual_minimum</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">2019</td>
<td style="text-align: right;">186.1</td>
<td style="text-align: right;">205.8</td>
<td style="text-align: right;">163.1</td>
</tr>
<tr class="even">
<td style="text-align: left;">2020</td>
<td style="text-align: right;">198.2</td>
<td style="text-align: right;">222.5</td>
<td style="text-align: right;">177.4</td>
</tr>
<tr class="odd">
<td style="text-align: left;">2021</td>
<td style="text-align: right;">211.8</td>
<td style="text-align: right;">235.8</td>
<td style="text-align: right;">188.2</td>
</tr>
<tr class="even">
<td style="text-align: left;">2022</td>
<td style="text-align: right;">205.4</td>
<td style="text-align: right;">233.3</td>
<td style="text-align: right;">170.8</td>
</tr>
<tr class="odd">
<td style="text-align: left;">2023</td>
<td style="text-align: right;">201.4</td>
<td style="text-align: right;">222.1</td>
<td style="text-align: right;">181.7</td>
</tr>
<tr class="even">
<td style="text-align: left;">2024</td>
<td style="text-align: right;">211.0</td>
<td style="text-align: right;">229.4</td>
<td style="text-align: right;">184.9</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The table is informative, but it cannot show the continuity of the series. A temporal-series plot is useful precisely because it connects adjacent months and makes the timing of peaks, troughs, and regime changes visible.</p>
</section>
<section id="step-2-build-the-synthetic-temporal-series-figure" class="level2" data-number="61.3">
<h2 data-number="61.3" class="anchored" data-anchor-id="step-2-build-the-synthetic-temporal-series-figure"><span class="header-section-number">61.3</span> Step 2: Build the synthetic temporal-series figure</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(synthetic_series, <span class="fu">aes</span>(<span class="at">x =</span> date, <span class="at">y =</span> admissions)) <span class="sc">+</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">annotate</span>(</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>    <span class="st">"rect"</span>,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">xmin =</span> <span class="fu">as.Date</span>(<span class="st">"2022-07-01"</span>),</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">xmax =</span> <span class="fu">max</span>(synthetic_series<span class="sc">$</span>date),</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">ymin =</span> <span class="sc">-</span><span class="cn">Inf</span>,</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">ymax =</span> <span class="cn">Inf</span>,</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.06</span>,</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"#74a57f"</span></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(<span class="at">linewidth =</span> <span class="fl">0.55</span>, <span class="at">color =</span> <span class="st">"#7f8c8d"</span>) <span class="sc">+</span></span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(<span class="fu">aes</span>(<span class="at">y =</span> ma12), <span class="at">linewidth =</span> <span class="fl">1.15</span>, <span class="at">color =</span> <span class="st">"#0b4f6c"</span>, <span class="at">na.rm =</span> <span class="cn">TRUE</span>) <span class="sc">+</span></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_vline</span>(</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">xintercept =</span> <span class="fu">as.Date</span>(<span class="st">"2022-07-01"</span>),</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.7</span>,</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#4d4d4d"</span></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"A temporal-series plot separates monthly noise from the underlying trajectory"</span>,</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Synthetic preventable emergency admissions with a 12-month moving average"</span>,</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="cn">NULL</span>,</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Monthly admissions"</span></span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>()</span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/temporal-series_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure works because the raw line and the smoother line serve different purposes. The grey series shows the monthly data actually observed. The blue line strips away much of the seasonal oscillation and makes the post-policy decline easier to see. The shaded post-intervention period is not itself an estimator of effect, but it helps the reader orient the timing of the series.</p>
</section>
<section id="step-3-identify-key-turning-points" class="level2" data-number="61.4">
<h2 data-number="61.4" class="anchored" data-anchor-id="step-3-identify-key-turning-points"><span class="header-section-number">61.4</span> Step 3: Identify key turning points</h2>
<p>As in several other chapters in this section, it is often useful to pair the figure with a short table naming the most important periods.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_turning_points <span class="ot">&lt;-</span> synthetic_series <span class="sc">|&gt;</span></span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(admissions)) <span class="sc">|&gt;</span></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">slice_head</span>(<span class="at">n =</span> <span class="dv">6</span>) <span class="sc">|&gt;</span></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">transmute</span>(</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">date =</span> <span class="fu">format</span>(date, <span class="st">"%Y-%m"</span>),</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">admissions =</span> admissions</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_turning_points, <span class="at">digits =</span> <span class="dv">1</span>),</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Highest monthly observations in the synthetic temporal series"</span></span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Highest monthly observations in the synthetic temporal series</caption>
<thead>
<tr class="header">
<th style="text-align: left;">date</th>
<th style="text-align: right;">admissions</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">2021-02</td>
<td style="text-align: right;">235.8</td>
</tr>
<tr class="even">
<td style="text-align: left;">2022-03</td>
<td style="text-align: right;">234.0</td>
</tr>
<tr class="odd">
<td style="text-align: left;">2022-01</td>
<td style="text-align: right;">233.3</td>
</tr>
<tr class="even">
<td style="text-align: left;">2021-03</td>
<td style="text-align: right;">232.5</td>
</tr>
<tr class="odd">
<td style="text-align: left;">2021-12</td>
<td style="text-align: right;">229.6</td>
</tr>
<tr class="even">
<td style="text-align: left;">2024-02</td>
<td style="text-align: right;">229.4</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The figure gives the shape of the whole process. The table names the local extremes precisely. Together they make the series easier to describe in text and easier to inspect critically.</p>
</section>
<section id="step-4-create-a-real-world-temporal-series-from-a-public-health-dataset" class="level2" data-number="61.5">
<h2 data-number="61.5" class="anchored" data-anchor-id="step-4-create-a-real-world-temporal-series-from-a-public-health-dataset"><span class="header-section-number">61.5</span> Step 4: Create a real-world temporal series from a public health dataset</h2>
<p>For a real-world example, we use the monthly UK lung-disease deaths series distributed with the <code>datasets</code> package in R. The help file cites Diggle's biostatistical time-series text as the source for these monthly deaths from bronchitis, emphysema, and asthma in the UK from 1974 through 1979 <span class="citation" data-cites="diggle1990">Diggle (<a href="#ref-diggle1990" role="doc-biblioref">1990</a>)</span>. This is therefore a transparent public-data application rather than a literal reconstruction of one published figure.</p>
<p>The point of the example is to show how the same figure design works in a real health time series with strong seasonality. Winter peaks are visually obvious in the raw line, while the 12-month moving average helps the reader see whether the underlying level is drifting up or down over the sample.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>lung_deaths <span class="ot">&lt;-</span> <span class="fu">get</span>(<span class="st">"ldeaths"</span>, <span class="at">envir =</span> <span class="fu">asNamespace</span>(<span class="st">"datasets"</span>))</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>time_index <span class="ot">&lt;-</span> <span class="fu">time</span>(lung_deaths)</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>years <span class="ot">&lt;-</span> <span class="fu">floor</span>(time_index)</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>months <span class="ot">&lt;-</span> <span class="fu">cycle</span>(lung_deaths)</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>real_series <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">date =</span> <span class="fu">as.Date</span>(<span class="fu">sprintf</span>(<span class="st">"%d-%02d-01"</span>, years, months)),</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">deaths =</span> <span class="fu">as.numeric</span>(lung_deaths)</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>) <span class="sc">|&gt;</span></span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">ma12 =</span> <span class="fu">moving_average</span>(deaths, <span class="at">k =</span> <span class="dv">12</span>),</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">year =</span> <span class="fu">format</span>(date, <span class="st">"%Y"</span>),</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">month =</span> <span class="fu">format</span>(date, <span class="st">"%m"</span>)</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>real_summary <span class="ot">&lt;-</span> real_series <span class="sc">|&gt;</span></span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">group_by</span>(year) <span class="sc">|&gt;</span></span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarise</span>(</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">mean_monthly_deaths =</span> <span class="fu">mean</span>(deaths),</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">annual_peak =</span> <span class="fu">max</span>(deaths),</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">annual_minimum =</span> <span class="fu">min</span>(deaths),</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(real_summary, <span class="at">digits =</span> <span class="dv">1</span>),</span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Yearly summary of the public UK lung-disease deaths series"</span></span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Yearly summary of the public UK lung-disease deaths series</caption>
<thead>
<tr class="header">
<th style="text-align: left;">year</th>
<th style="text-align: right;">mean_monthly_deaths</th>
<th style="text-align: right;">annual_peak</th>
<th style="text-align: right;">annual_minimum</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">1974</td>
<td style="text-align: right;">2178.3</td>
<td style="text-align: right;">3035</td>
<td style="text-align: right;">1524</td>
</tr>
<tr class="even">
<td style="text-align: left;">1975</td>
<td style="text-align: right;">2175.1</td>
<td style="text-align: right;">2938</td>
<td style="text-align: right;">1396</td>
</tr>
<tr class="odd">
<td style="text-align: left;">1976</td>
<td style="text-align: right;">2143.2</td>
<td style="text-align: right;">3891</td>
<td style="text-align: right;">1300</td>
</tr>
<tr class="even">
<td style="text-align: left;">1977</td>
<td style="text-align: right;">1935.8</td>
<td style="text-align: right;">3102</td>
<td style="text-align: right;">1346</td>
</tr>
<tr class="odd">
<td style="text-align: left;">1978</td>
<td style="text-align: right;">1995.9</td>
<td style="text-align: right;">3137</td>
<td style="text-align: right;">1357</td>
</tr>
<tr class="even">
<td style="text-align: left;">1979</td>
<td style="text-align: right;">1911.5</td>
<td style="text-align: right;">3084</td>
<td style="text-align: right;">1333</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-5-draw-the-real-world-temporal-series-figure" class="level2" data-number="61.6">
<h2 data-number="61.6" class="anchored" data-anchor-id="step-5-draw-the-real-world-temporal-series-figure"><span class="header-section-number">61.6</span> Step 5: Draw the real-world temporal-series figure</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(real_series, <span class="fu">aes</span>(<span class="at">x =</span> date, <span class="at">y =</span> deaths)) <span class="sc">+</span></span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(<span class="at">linewidth =</span> <span class="fl">0.55</span>, <span class="at">color =</span> <span class="st">"#8c8c8c"</span>) <span class="sc">+</span></span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(<span class="fu">aes</span>(<span class="at">y =</span> ma12), <span class="at">linewidth =</span> <span class="fl">1.15</span>, <span class="at">color =</span> <span class="st">"#8c2d04"</span>, <span class="at">na.rm =</span> <span class="cn">TRUE</span>) <span class="sc">+</span></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"The temporal-series plot shows both seasonality and medium-run movement"</span>,</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Monthly UK deaths from bronchitis, emphysema, and asthma, 1974-1979"</span>,</span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="cn">NULL</span>,</span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Deaths per month"</span></span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>()</span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/temporal-series_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This real-world figure shows why the layered temporal-series display is so useful. The raw line makes the winter peaks unmistakable. The moving average shows that the series has a broader level pattern beyond those seasonal swings. A table of annual means would partially capture that, but it would hide the month-to-month structure entirely.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="61.7">
<h2 data-number="61.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">61.7</span> How to read the figure carefully</h2>
<p>Temporal-series plots are descriptive before they are causal. A visible level shift after a policy date does not by itself prove that the policy caused the change. Other concurrent shocks, seasonal composition, and mean reversion can all create patterns that look persuasive in a line chart. The figure is therefore a communication tool, not a substitute for interrupted time-series estimation or other formal design-based analysis.</p>
<p>It is also important to interpret the moving average correctly. Smoothing is useful because it suppresses noise, but it also delays and dilutes abrupt changes. A 12-month moving average is helpful for medium-run interpretation, especially in seasonal monthly data, but it should not be used to claim precise turning points.</p>
<p>Finally, the graph should preserve enough of the raw series for the reader to see what has been smoothed away. That is why the thin monthly line matters. Without it, the reader cannot tell whether the smoother reflects a genuinely stable trajectory or only a noisy series averaged into apparent stability.</p>
</section>
<section id="further-reading" class="level2" data-number="61.8">
<h2 data-number="61.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">61.8</span> Further reading</h2>
<p>Diggle provides a concise health-oriented introduction to time-series data and is a natural reference for the UK lung-deaths series used here <span class="citation" data-cites="diggle1990">Diggle (<a href="#ref-diggle1990" role="doc-biblioref">1990</a>)</span>. Wickham's treatment of layered graphics is useful for readers who want to extend this figure design with annotations, faceting, or additional model-based overlays <span class="citation" data-cites="wickham2016ggplot2">Wickham (<a href="#ref-wickham2016ggplot2" role="doc-biblioref">2016</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-diggle1990" class="csl-entry" role="listitem">
Diggle, Peter J. 1990. <em>Time Series: A Biostatistical Introduction</em>. Oxford: Oxford University Press.
</div>
<div id="ref-wickham2016ggplot2" class="csl-entry" role="listitem">
Wickham, Hadley. 2016. <em>Ggplot2: Elegant Graphics for Data Analysis</em>. Second. New York: Springer.
</div>
</div>
</section>
