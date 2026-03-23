---
title: "Love Plot for Covariate Balance"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a Love plot, a figure designed to show covariate balance before and after an adjustment step such as matching or weighting. In observational health research, one of the first questions after..."
---
<p>This chapter builds a Love plot, a figure designed to show covariate balance before and after an adjustment step such as matching or weighting. In observational health research, one of the first questions after estimating a propensity score is whether the treated and control groups actually became more comparable on the observed covariates. A Love plot answers that question quickly because it places the absolute standardized mean difference for each covariate on one horizontal axis and then overlays the values before and after adjustment. Stuart and Austin both emphasize that balance diagnostics are central to credible propensity-score work, not optional decoration <span class="citation" data-cites="stuart2010">Stuart (<a href="#ref-stuart2010" role="doc-biblioref">2010</a>)</span>; <span class="citation" data-cites="austin2009balance">Austin (<a href="#ref-austin2009balance" role="doc-biblioref">2009</a>)</span>.</p>
<p>The figure is useful because a propensity-score model can look sophisticated while still leaving important imbalance behind. A regression table or a list of mean comparisons is too fragmented to show the whole pattern. A Love plot lets the reader see which variables were initially far apart, which ones improved after adjustment, and whether the post-adjustment imbalance is small enough to support a more credible causal comparison.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="68.1">
<h2 data-number="68.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">68.1</span> What the visualization is showing</h2>
<p>We will build a Love plot with:</p>
<ol type="1">
<li>one row per covariate,</li>
<li>an absolute standardized mean difference before adjustment,</li>
<li>an absolute standardized mean difference after adjustment,</li>
<li>vertical reference lines that mark common balance thresholds.</li>
</ol>
<p>The standardized mean difference for a continuous covariate is</p>
<p><span class="math display">\[
\text{SMD}(X) = \frac{\bar{X}_1 - \bar{X}_0}{\sqrt{\frac{s_1^2 + s_0^2}{2}}},
\]</span></p>
<p>where group 1 is the treated group and group 0 is the control group. For a binary covariate, the same formula applies if the means are interpreted as proportions and the variances as Bernoulli variances. The Love plot usually displays the absolute value, because the practical question is the size of the imbalance rather than its direction.</p>
<p>Values below about 0.1 are often treated as acceptable in applied work, although that threshold is a rule of thumb rather than a theorem. The plot is therefore a diagnostic figure: it helps the analyst judge whether the design stage has made the groups similar enough on the observed covariates.</p>
</section>
<section id="step-1-create-a-synthetic-observational-dataset-with-confounding" class="level2" data-number="68.2">
<h2 data-number="68.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-observational-dataset-with-confounding"><span class="header-section-number">68.2</span> Step 1: Create a synthetic observational dataset with confounding</h2>
<p>We begin with a synthetic care-management example. Treatment assignment is deliberately confounded: older, sicker, and lower-income patients are more likely to receive the intervention. That makes the initial covariate imbalance visible and gives the Love plot something meaningful to diagnose.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(MatchIt)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>format_numeric_table <span class="ot">&lt;-</span> <span class="cf">function</span>(df, <span class="at">digits =</span> <span class="dv">3</span>) {</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  numeric_cols <span class="ot">&lt;-</span> <span class="fu">vapply</span>(df, is.numeric, <span class="fu">logical</span>(<span class="dv">1</span>))</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  df[numeric_cols] <span class="ot">&lt;-</span> <span class="fu">lapply</span>(df[numeric_cols], round, <span class="at">digits =</span> digits)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  df</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>weighted_mean <span class="ot">&lt;-</span> <span class="cf">function</span>(x, w) {</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">sum</span>(w <span class="sc">*</span> x) <span class="sc">/</span> <span class="fu">sum</span>(w)</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>weighted_var <span class="ot">&lt;-</span> <span class="cf">function</span>(x, w) {</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>  mu <span class="ot">&lt;-</span> <span class="fu">weighted_mean</span>(x, w)</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">sum</span>(w <span class="sc">*</span> (x <span class="sc">-</span> mu)<span class="sc">^</span><span class="dv">2</span>) <span class="sc">/</span> <span class="fu">sum</span>(w)</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>smd_numeric <span class="ot">&lt;-</span> <span class="cf">function</span>(x, z, <span class="at">w =</span> <span class="cn">NULL</span>) {</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  <span class="cf">if</span> (<span class="fu">is.null</span>(w)) {</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>    w <span class="ot">&lt;-</span> <span class="fu">rep</span>(<span class="dv">1</span>, <span class="fu">length</span>(x))</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  xt <span class="ot">&lt;-</span> x[z <span class="sc">==</span> <span class="dv">1</span>]</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>  xc <span class="ot">&lt;-</span> x[z <span class="sc">==</span> <span class="dv">0</span>]</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>  wt <span class="ot">&lt;-</span> w[z <span class="sc">==</span> <span class="dv">1</span>]</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>  wc <span class="ot">&lt;-</span> w[z <span class="sc">==</span> <span class="dv">0</span>]</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>  vt <span class="ot">&lt;-</span> <span class="fu">weighted_var</span>(xt, wt)</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>  vc <span class="ot">&lt;-</span> <span class="fu">weighted_var</span>(xc, wc)</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>  <span class="cf">if</span> ((vt <span class="sc">+</span> vc) <span class="sc">==</span> <span class="dv">0</span>) {</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>    <span class="fu">return</span>(<span class="dv">0</span>)</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>  (<span class="fu">weighted_mean</span>(xt, wt) <span class="sc">-</span> <span class="fu">weighted_mean</span>(xc, wc)) <span class="sc">/</span> <span class="fu">sqrt</span>((vt <span class="sc">+</span> vc) <span class="sc">/</span> <span class="dv">2</span>)</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>compute_balance <span class="ot">&lt;-</span> <span class="cf">function</span>(data, covariates, treat_var, weight_list, labels) {</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>  z <span class="ot">&lt;-</span> data[[treat_var]]</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>  balance_rows <span class="ot">&lt;-</span> <span class="fu">lapply</span>(<span class="fu">names</span>(weight_list), <span class="cf">function</span>(sample_label) {</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>    w <span class="ot">&lt;-</span> weight_list[[sample_label]]</span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(</span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>      <span class="at">covariate =</span> covariates,</span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>      <span class="at">sample =</span> sample_label,</span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>      <span class="at">smd =</span> <span class="fu">vapply</span>(covariates, <span class="cf">function</span>(v) <span class="fu">smd_numeric</span>(data[[v]], z, w), <span class="fu">numeric</span>(<span class="dv">1</span>)),</span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>      <span class="at">row.names =</span> <span class="cn">NULL</span></span>
<span id="cb1-52"><a href="#cb1-52" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-53"><a href="#cb1-53" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb1-54"><a href="#cb1-54" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-55"><a href="#cb1-55" aria-hidden="true" tabindex="-1"></a>  <span class="fu">bind_rows</span>(balance_rows) <span class="sc">|&gt;</span></span>
<span id="cb1-56"><a href="#cb1-56" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mutate</span>(</span>
<span id="cb1-57"><a href="#cb1-57" aria-hidden="true" tabindex="-1"></a>      <span class="at">abs_smd =</span> <span class="fu">abs</span>(smd),</span>
<span id="cb1-58"><a href="#cb1-58" aria-hidden="true" tabindex="-1"></a>      <span class="at">covariate_label =</span> <span class="fu">unname</span>(labels[covariate])</span>
<span id="cb1-59"><a href="#cb1-59" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-60"><a href="#cb1-60" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-61"><a href="#cb1-61" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-62"><a href="#cb1-62" aria-hidden="true" tabindex="-1"></a>build_love_plot <span class="ot">&lt;-</span> <span class="cf">function</span>(balance_df, title, subtitle) {</span>
<span id="cb1-63"><a href="#cb1-63" aria-hidden="true" tabindex="-1"></a>  segment_df <span class="ot">&lt;-</span> balance_df <span class="sc">|&gt;</span></span>
<span id="cb1-64"><a href="#cb1-64" aria-hidden="true" tabindex="-1"></a>    <span class="fu">group_by</span>(covariate_label) <span class="sc">|&gt;</span></span>
<span id="cb1-65"><a href="#cb1-65" aria-hidden="true" tabindex="-1"></a>    <span class="fu">summarize</span>(</span>
<span id="cb1-66"><a href="#cb1-66" aria-hidden="true" tabindex="-1"></a>      <span class="at">min_abs_smd =</span> <span class="fu">min</span>(abs_smd),</span>
<span id="cb1-67"><a href="#cb1-67" aria-hidden="true" tabindex="-1"></a>      <span class="at">max_abs_smd =</span> <span class="fu">max</span>(abs_smd),</span>
<span id="cb1-68"><a href="#cb1-68" aria-hidden="true" tabindex="-1"></a>      <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb1-69"><a href="#cb1-69" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">|&gt;</span></span>
<span id="cb1-70"><a href="#cb1-70" aria-hidden="true" tabindex="-1"></a>    <span class="fu">arrange</span>(min_abs_smd)</span>
<span id="cb1-71"><a href="#cb1-71" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-72"><a href="#cb1-72" aria-hidden="true" tabindex="-1"></a>  plot_df <span class="ot">&lt;-</span> balance_df <span class="sc">|&gt;</span></span>
<span id="cb1-73"><a href="#cb1-73" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mutate</span>(</span>
<span id="cb1-74"><a href="#cb1-74" aria-hidden="true" tabindex="-1"></a>      <span class="at">covariate_label =</span> <span class="fu">factor</span>(covariate_label, <span class="at">levels =</span> segment_df<span class="sc">$</span>covariate_label)</span>
<span id="cb1-75"><a href="#cb1-75" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-76"><a href="#cb1-76" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-77"><a href="#cb1-77" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>(plot_df, <span class="fu">aes</span>(<span class="at">x =</span> abs_smd, <span class="at">y =</span> covariate_label, <span class="at">color =</span> sample, <span class="at">shape =</span> sample)) <span class="sc">+</span></span>
<span id="cb1-78"><a href="#cb1-78" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-79"><a href="#cb1-79" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> segment_df,</span>
<span id="cb1-80"><a href="#cb1-80" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(</span>
<span id="cb1-81"><a href="#cb1-81" aria-hidden="true" tabindex="-1"></a>        <span class="at">x =</span> min_abs_smd,</span>
<span id="cb1-82"><a href="#cb1-82" aria-hidden="true" tabindex="-1"></a>        <span class="at">xend =</span> max_abs_smd,</span>
<span id="cb1-83"><a href="#cb1-83" aria-hidden="true" tabindex="-1"></a>        <span class="at">y =</span> covariate_label,</span>
<span id="cb1-84"><a href="#cb1-84" aria-hidden="true" tabindex="-1"></a>        <span class="at">yend =</span> covariate_label</span>
<span id="cb1-85"><a href="#cb1-85" aria-hidden="true" tabindex="-1"></a>      ),</span>
<span id="cb1-86"><a href="#cb1-86" aria-hidden="true" tabindex="-1"></a>      <span class="at">inherit.aes =</span> <span class="cn">FALSE</span>,</span>
<span id="cb1-87"><a href="#cb1-87" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.8</span>,</span>
<span id="cb1-88"><a href="#cb1-88" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#d9d9d9"</span></span>
<span id="cb1-89"><a href="#cb1-89" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-90"><a href="#cb1-90" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="fl">0.1</span>, <span class="at">linetype =</span> <span class="st">"dashed"</span>, <span class="at">linewidth =</span> <span class="fl">0.7</span>, <span class="at">color =</span> <span class="st">"#7f2704"</span>) <span class="sc">+</span></span>
<span id="cb1-91"><a href="#cb1-91" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="fl">0.2</span>, <span class="at">linetype =</span> <span class="st">"dotted"</span>, <span class="at">linewidth =</span> <span class="fl">0.7</span>, <span class="at">color =</span> <span class="st">"#7f7f7f"</span>) <span class="sc">+</span></span>
<span id="cb1-92"><a href="#cb1-92" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_point</span>(<span class="at">size =</span> <span class="fl">3.1</span>) <span class="sc">+</span></span>
<span id="cb1-93"><a href="#cb1-93" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_color_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"Before adjustment"</span> <span class="ot">=</span> <span class="st">"#8c2d04"</span>, <span class="st">"After adjustment"</span> <span class="ot">=</span> <span class="st">"#2171b5"</span>)) <span class="sc">+</span></span>
<span id="cb1-94"><a href="#cb1-94" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_shape_manual</span>(<span class="at">values =</span> <span class="fu">c</span>(<span class="st">"Before adjustment"</span> <span class="ot">=</span> <span class="dv">16</span>, <span class="st">"After adjustment"</span> <span class="ot">=</span> <span class="dv">17</span>)) <span class="sc">+</span></span>
<span id="cb1-95"><a href="#cb1-95" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb1-96"><a href="#cb1-96" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb1-97"><a href="#cb1-97" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle,</span>
<span id="cb1-98"><a href="#cb1-98" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="st">"Absolute standardized mean difference"</span>,</span>
<span id="cb1-99"><a href="#cb1-99" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> <span class="cn">NULL</span>,</span>
<span id="cb1-100"><a href="#cb1-100" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="cn">NULL</span>,</span>
<span id="cb1-101"><a href="#cb1-101" aria-hidden="true" tabindex="-1"></a>      <span class="at">shape =</span> <span class="cn">NULL</span></span>
<span id="cb1-102"><a href="#cb1-102" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-103"><a href="#cb1-103" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb1-104"><a href="#cb1-104" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb1-105"><a href="#cb1-105" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.major.y =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb1-106"><a href="#cb1-106" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb1-107"><a href="#cb1-107" aria-hidden="true" tabindex="-1"></a>      <span class="at">legend.position =</span> <span class="st">"bottom"</span></span>
<span id="cb1-108"><a href="#cb1-108" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-109"><a href="#cb1-109" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2027</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>n_patients <span class="ot">&lt;-</span> <span class="dv">1200</span></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>synthetic_balance_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">age =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">67</span>, <span class="at">sd =</span> <span class="dv">10</span>),</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">prior_admissions =</span> <span class="fu">rpois</span>(n_patients, <span class="at">lambda =</span> <span class="fl">1.4</span>),</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">comorbidity_score =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>),</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">female =</span> <span class="fu">rbinom</span>(n_patients, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.55</span>),</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">low_income =</span> <span class="fu">rbinom</span>(n_patients, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.32</span>),</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">baseline_cost_k =</span> <span class="fu">rgamma</span>(n_patients, <span class="at">shape =</span> <span class="dv">4</span>, <span class="at">scale =</span> <span class="fl">1.6</span>)</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>synthetic_treat_lp <span class="ot">&lt;-</span> <span class="fu">with</span>(</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  synthetic_balance_data,</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="sc">-</span><span class="fl">0.8</span> <span class="sc">+</span></span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.035</span> <span class="sc">*</span> age <span class="sc">+</span></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.40</span> <span class="sc">*</span> prior_admissions <span class="sc">+</span></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.85</span> <span class="sc">*</span> comorbidity_score <span class="sc">+</span></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.55</span> <span class="sc">*</span> low_income <span class="sc">-</span></span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.18</span> <span class="sc">*</span> female <span class="sc">+</span></span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.20</span> <span class="sc">*</span> baseline_cost_k</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>synthetic_balance_data<span class="sc">$</span>treat <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>  n_patients,</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">size =</span> <span class="dv">1</span>,</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>  <span class="at">prob =</span> <span class="fu">plogis</span>(synthetic_treat_lp)</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>synthetic_ps_model <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  treat <span class="sc">~</span> age <span class="sc">+</span> prior_admissions <span class="sc">+</span> comorbidity_score <span class="sc">+</span> female <span class="sc">+</span> low_income <span class="sc">+</span> baseline_cost_k,</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_balance_data,</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>synthetic_ps <span class="ot">&lt;-</span> <span class="fu">pmin</span>(</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>  <span class="fu">pmax</span>(<span class="fu">predict</span>(synthetic_ps_model, <span class="at">type =</span> <span class="st">"response"</span>), <span class="fl">0.025</span>),</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.975</span></span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>treat_rate <span class="ot">&lt;-</span> <span class="fu">mean</span>(synthetic_balance_data<span class="sc">$</span>treat)</span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>synthetic_weights <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(</span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>  synthetic_balance_data<span class="sc">$</span>treat <span class="sc">==</span> <span class="dv">1</span>,</span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a>  treat_rate <span class="sc">/</span> synthetic_ps,</span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a>  (<span class="dv">1</span> <span class="sc">-</span> treat_rate) <span class="sc">/</span> (<span class="dv">1</span> <span class="sc">-</span> synthetic_ps)</span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-50"><a href="#cb2-50" aria-hidden="true" tabindex="-1"></a>synthetic_covariates <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb2-51"><a href="#cb2-51" aria-hidden="true" tabindex="-1"></a>  <span class="st">"age"</span>,</span>
<span id="cb2-52"><a href="#cb2-52" aria-hidden="true" tabindex="-1"></a>  <span class="st">"prior_admissions"</span>,</span>
<span id="cb2-53"><a href="#cb2-53" aria-hidden="true" tabindex="-1"></a>  <span class="st">"comorbidity_score"</span>,</span>
<span id="cb2-54"><a href="#cb2-54" aria-hidden="true" tabindex="-1"></a>  <span class="st">"female"</span>,</span>
<span id="cb2-55"><a href="#cb2-55" aria-hidden="true" tabindex="-1"></a>  <span class="st">"low_income"</span>,</span>
<span id="cb2-56"><a href="#cb2-56" aria-hidden="true" tabindex="-1"></a>  <span class="st">"baseline_cost_k"</span></span>
<span id="cb2-57"><a href="#cb2-57" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-58"><a href="#cb2-58" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-59"><a href="#cb2-59" aria-hidden="true" tabindex="-1"></a>synthetic_labels <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb2-60"><a href="#cb2-60" aria-hidden="true" tabindex="-1"></a>  <span class="at">age =</span> <span class="st">"Age"</span>,</span>
<span id="cb2-61"><a href="#cb2-61" aria-hidden="true" tabindex="-1"></a>  <span class="at">prior_admissions =</span> <span class="st">"Prior admissions"</span>,</span>
<span id="cb2-62"><a href="#cb2-62" aria-hidden="true" tabindex="-1"></a>  <span class="at">comorbidity_score =</span> <span class="st">"Comorbidity score"</span>,</span>
<span id="cb2-63"><a href="#cb2-63" aria-hidden="true" tabindex="-1"></a>  <span class="at">female =</span> <span class="st">"Female"</span>,</span>
<span id="cb2-64"><a href="#cb2-64" aria-hidden="true" tabindex="-1"></a>  <span class="at">low_income =</span> <span class="st">"Low income"</span>,</span>
<span id="cb2-65"><a href="#cb2-65" aria-hidden="true" tabindex="-1"></a>  <span class="at">baseline_cost_k =</span> <span class="st">"Baseline cost (thousand USD)"</span></span>
<span id="cb2-66"><a href="#cb2-66" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-67"><a href="#cb2-67" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-68"><a href="#cb2-68" aria-hidden="true" tabindex="-1"></a>synthetic_balance <span class="ot">&lt;-</span> <span class="fu">compute_balance</span>(</span>
<span id="cb2-69"><a href="#cb2-69" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_balance_data,</span>
<span id="cb2-70"><a href="#cb2-70" aria-hidden="true" tabindex="-1"></a>  <span class="at">covariates =</span> synthetic_covariates,</span>
<span id="cb2-71"><a href="#cb2-71" aria-hidden="true" tabindex="-1"></a>  <span class="at">treat_var =</span> <span class="st">"treat"</span>,</span>
<span id="cb2-72"><a href="#cb2-72" aria-hidden="true" tabindex="-1"></a>  <span class="at">weight_list =</span> <span class="fu">list</span>(</span>
<span id="cb2-73"><a href="#cb2-73" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Before adjustment"</span> <span class="ot">=</span> <span class="fu">rep</span>(<span class="dv">1</span>, <span class="fu">nrow</span>(synthetic_balance_data)),</span>
<span id="cb2-74"><a href="#cb2-74" aria-hidden="true" tabindex="-1"></a>    <span class="st">"After adjustment"</span> <span class="ot">=</span> synthetic_weights</span>
<span id="cb2-75"><a href="#cb2-75" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-76"><a href="#cb2-76" aria-hidden="true" tabindex="-1"></a>  <span class="at">labels =</span> synthetic_labels</span>
<span id="cb2-77"><a href="#cb2-77" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-78"><a href="#cb2-78" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-79"><a href="#cb2-79" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-80"><a href="#cb2-80" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(synthetic_balance_data),</span>
<span id="cb2-81"><a href="#cb2-81" aria-hidden="true" tabindex="-1"></a>  <span class="at">treatment_rate =</span> <span class="fu">mean</span>(synthetic_balance_data<span class="sc">$</span>treat),</span>
<span id="cb2-82"><a href="#cb2-82" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_propensity_score =</span> <span class="fu">mean</span>(synthetic_ps),</span>
<span id="cb2-83"><a href="#cb2-83" aria-hidden="true" tabindex="-1"></a>  <span class="at">max_weight =</span> <span class="fu">max</span>(synthetic_weights),</span>
<span id="cb2-84"><a href="#cb2-84" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_weight =</span> <span class="fu">mean</span>(synthetic_weights)</span>
<span id="cb2-85"><a href="#cb2-85" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-86"><a href="#cb2-86" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-87"><a href="#cb2-87" aria-hidden="true" tabindex="-1"></a>synthetic_balance_table <span class="ot">&lt;-</span> <span class="fu">merge</span>(</span>
<span id="cb2-88"><a href="#cb2-88" aria-hidden="true" tabindex="-1"></a>  <span class="fu">subset</span>(</span>
<span id="cb2-89"><a href="#cb2-89" aria-hidden="true" tabindex="-1"></a>    synthetic_balance,</span>
<span id="cb2-90"><a href="#cb2-90" aria-hidden="true" tabindex="-1"></a>    sample <span class="sc">==</span> <span class="st">"Before adjustment"</span>,</span>
<span id="cb2-91"><a href="#cb2-91" aria-hidden="true" tabindex="-1"></a>    <span class="at">select =</span> <span class="fu">c</span>(<span class="st">"covariate_label"</span>, <span class="st">"abs_smd"</span>)</span>
<span id="cb2-92"><a href="#cb2-92" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-93"><a href="#cb2-93" aria-hidden="true" tabindex="-1"></a>  <span class="fu">subset</span>(</span>
<span id="cb2-94"><a href="#cb2-94" aria-hidden="true" tabindex="-1"></a>    synthetic_balance,</span>
<span id="cb2-95"><a href="#cb2-95" aria-hidden="true" tabindex="-1"></a>    sample <span class="sc">==</span> <span class="st">"After adjustment"</span>,</span>
<span id="cb2-96"><a href="#cb2-96" aria-hidden="true" tabindex="-1"></a>    <span class="at">select =</span> <span class="fu">c</span>(<span class="st">"covariate_label"</span>, <span class="st">"abs_smd"</span>)</span>
<span id="cb2-97"><a href="#cb2-97" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-98"><a href="#cb2-98" aria-hidden="true" tabindex="-1"></a>  <span class="at">by =</span> <span class="st">"covariate_label"</span>,</span>
<span id="cb2-99"><a href="#cb2-99" aria-hidden="true" tabindex="-1"></a>  <span class="at">suffixes =</span> <span class="fu">c</span>(<span class="st">"_before"</span>, <span class="st">"_after"</span>)</span>
<span id="cb2-100"><a href="#cb2-100" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-101"><a href="#cb2-101" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-102"><a href="#cb2-102" aria-hidden="true" tabindex="-1"></a>synthetic_balance_table <span class="ot">&lt;-</span> synthetic_balance_table <span class="sc">|&gt;</span></span>
<span id="cb2-103"><a href="#cb2-103" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(abs_smd_before))</span>
<span id="cb2-104"><a href="#cb2-104" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-105"><a href="#cb2-105" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-106"><a href="#cb2-106" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_summary, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb2-107"><a href="#cb2-107" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Synthetic propensity-score weighting setup for the Love plot"</span></span>
<span id="cb2-108"><a href="#cb2-108" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Synthetic propensity-score weighting setup for the Love plot</caption>
<colgroup>
<col style="width: 16%">
<col style="width: 20%">
<col style="width: 30%">
<col style="width: 15%">
<col style="width: 16%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">treatment_rate</th>
<th style="text-align: right;">mean_propensity_score</th>
<th style="text-align: right;">max_weight</th>
<th style="text-align: right;">mean_weight</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">1200</td>
<td style="text-align: right;">0.953</td>
<td style="text-align: right;">0.947</td>
<td style="text-align: right;">2.913</td>
<td style="text-align: right;">0.993</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_balance_table, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Absolute standardized mean differences before and after weighting in the synthetic example"</span></span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Absolute standardized mean differences before and after weighting in the synthetic example</caption>
<thead>
<tr class="header">
<th style="text-align: left;">covariate_label</th>
<th style="text-align: right;">abs_smd_before</th>
<th style="text-align: right;">abs_smd_after</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Comorbidity score</td>
<td style="text-align: right;">0.758</td>
<td style="text-align: right;">0.199</td>
</tr>
<tr class="even">
<td style="text-align: left;">Baseline cost (thousand USD)</td>
<td style="text-align: right;">0.617</td>
<td style="text-align: right;">0.165</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Prior admissions</td>
<td style="text-align: right;">0.421</td>
<td style="text-align: right;">0.096</td>
</tr>
<tr class="even">
<td style="text-align: left;">Age</td>
<td style="text-align: right;">0.271</td>
<td style="text-align: right;">0.087</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Low income</td>
<td style="text-align: right;">0.240</td>
<td style="text-align: right;">0.266</td>
</tr>
<tr class="even">
<td style="text-align: left;">Female</td>
<td style="text-align: right;">0.139</td>
<td style="text-align: right;">0.029</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The tables already show the logic of the figure. Several covariates are meaningfully imbalanced before weighting, especially comorbidity, prior admissions, and low income. The weighted sample is much closer on those same variables.</p>
</section>
<section id="step-2-draw-the-synthetic-love-plot" class="level2" data-number="68.3">
<h2 data-number="68.3" class="anchored" data-anchor-id="step-2-draw-the-synthetic-love-plot"><span class="header-section-number">68.3</span> Step 2: Draw the synthetic Love plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_love_plot <span class="ot">&lt;-</span> <span class="fu">build_love_plot</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  synthetic_balance,</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"A Love plot makes covariate balance visible before and after weighting"</span>,</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Synthetic care-management example using stabilized inverse-probability weights"</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>synthetic_love_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/love-plot-covariate-balance_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This plot is easier to read than the table because it compresses the design-stage diagnostic into one visual pattern. The most important features are:</p>
<ol type="1">
<li>the red points, which show the initial imbalance,</li>
<li>the blue points, which show the post-weighting imbalance,</li>
<li>the distance between the two points on each row, which shows how much the adjustment helped,</li>
<li>the 0.1 reference line, which gives a rough target for acceptable balance.</li>
</ol>
<p>If the blue points were still mostly to the right of 0.1, the weighting model would need more work. That might mean adding nonlinear terms, interactions, trimming poor-overlap regions, or changing the adjustment method entirely.</p>
</section>
<section id="step-3-build-a-real-world-love-plot-from-the-public-lalonde-benchmark" class="level2" data-number="68.4">
<h2 data-number="68.4" class="anchored" data-anchor-id="step-3-build-a-real-world-love-plot-from-the-public-lalonde-benchmark"><span class="header-section-number">68.4</span> Step 3: Build a real-world Love plot from the public LaLonde benchmark</h2>
<p>For a real-world example, we use the public LaLonde job-training benchmark distributed with <code>MatchIt</code>, linked to LaLonde's experimental evaluation and the influential reanalysis by Dehejia and Wahba <span class="citation" data-cites="lalonde1986">LaLonde (<a href="#ref-lalonde1986" role="doc-biblioref">1986</a>)</span>; <span class="citation" data-cites="dehejia1999">Dehejia and Wahba (<a href="#ref-dehejia1999" role="doc-biblioref">1999</a>)</span>. The <code>MatchIt</code> framework developed by Ho, Imai, King, and Stuart is a natural teaching setting because it turns the design problem into an explicit preprocessing step <span class="citation" data-cites="ho2011matchit">Ho et al. (<a href="#ref-ho2011matchit" role="doc-biblioref">2011</a>)</span>.</p>
<p>The goal here is not to reproduce the full treatment-effect literature on the National Supported Work data. Instead, this is a transparent partial application focused on the figure itself: we estimate a nearest-neighbor propensity-score match and then ask whether the matched sample is more balanced on the observed covariates than the original one.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"lalonde"</span>, <span class="at">package =</span> <span class="st">"MatchIt"</span>)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>lalonde_plot_data <span class="ot">&lt;-</span> lalonde <span class="sc">|&gt;</span></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">black =</span> <span class="fu">as.integer</span>(race <span class="sc">==</span> <span class="st">"black"</span>),</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">hispan =</span> <span class="fu">as.integer</span>(race <span class="sc">==</span> <span class="st">"hispan"</span>),</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">re74_k =</span> re74 <span class="sc">/</span> <span class="dv">1000</span>,</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">re75_k =</span> re75 <span class="sc">/</span> <span class="dv">1000</span></span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>lalonde_match <span class="ot">&lt;-</span> MatchIt<span class="sc">::</span><span class="fu">matchit</span>(</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>  treat <span class="sc">~</span> age <span class="sc">+</span> educ <span class="sc">+</span> black <span class="sc">+</span> hispan <span class="sc">+</span> married <span class="sc">+</span> nodegree <span class="sc">+</span> re74_k <span class="sc">+</span> re75_k,</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> lalonde_plot_data,</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">method =</span> <span class="st">"nearest"</span>,</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">ratio =</span> <span class="dv">1</span></span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>lalonde_covariates <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  <span class="st">"age"</span>,</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>  <span class="st">"educ"</span>,</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>  <span class="st">"black"</span>,</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>  <span class="st">"hispan"</span>,</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>  <span class="st">"married"</span>,</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>  <span class="st">"nodegree"</span>,</span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>  <span class="st">"re74_k"</span>,</span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>  <span class="st">"re75_k"</span></span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a>lalonde_labels <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb5-30"><a href="#cb5-30" aria-hidden="true" tabindex="-1"></a>  <span class="at">age =</span> <span class="st">"Age"</span>,</span>
<span id="cb5-31"><a href="#cb5-31" aria-hidden="true" tabindex="-1"></a>  <span class="at">educ =</span> <span class="st">"Years of education"</span>,</span>
<span id="cb5-32"><a href="#cb5-32" aria-hidden="true" tabindex="-1"></a>  <span class="at">black =</span> <span class="st">"Black"</span>,</span>
<span id="cb5-33"><a href="#cb5-33" aria-hidden="true" tabindex="-1"></a>  <span class="at">hispan =</span> <span class="st">"Hispanic"</span>,</span>
<span id="cb5-34"><a href="#cb5-34" aria-hidden="true" tabindex="-1"></a>  <span class="at">married =</span> <span class="st">"Married"</span>,</span>
<span id="cb5-35"><a href="#cb5-35" aria-hidden="true" tabindex="-1"></a>  <span class="at">nodegree =</span> <span class="st">"No high-school degree"</span>,</span>
<span id="cb5-36"><a href="#cb5-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">re74_k =</span> <span class="st">"Earnings in 1974 (thousand USD)"</span>,</span>
<span id="cb5-37"><a href="#cb5-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">re75_k =</span> <span class="st">"Earnings in 1975 (thousand USD)"</span></span>
<span id="cb5-38"><a href="#cb5-38" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-39"><a href="#cb5-39" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-40"><a href="#cb5-40" aria-hidden="true" tabindex="-1"></a>lalonde_balance <span class="ot">&lt;-</span> <span class="fu">compute_balance</span>(</span>
<span id="cb5-41"><a href="#cb5-41" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> lalonde_plot_data,</span>
<span id="cb5-42"><a href="#cb5-42" aria-hidden="true" tabindex="-1"></a>  <span class="at">covariates =</span> lalonde_covariates,</span>
<span id="cb5-43"><a href="#cb5-43" aria-hidden="true" tabindex="-1"></a>  <span class="at">treat_var =</span> <span class="st">"treat"</span>,</span>
<span id="cb5-44"><a href="#cb5-44" aria-hidden="true" tabindex="-1"></a>  <span class="at">weight_list =</span> <span class="fu">list</span>(</span>
<span id="cb5-45"><a href="#cb5-45" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Before adjustment"</span> <span class="ot">=</span> <span class="fu">rep</span>(<span class="dv">1</span>, <span class="fu">nrow</span>(lalonde_plot_data)),</span>
<span id="cb5-46"><a href="#cb5-46" aria-hidden="true" tabindex="-1"></a>    <span class="st">"After adjustment"</span> <span class="ot">=</span> lalonde_match<span class="sc">$</span>weights</span>
<span id="cb5-47"><a href="#cb5-47" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb5-48"><a href="#cb5-48" aria-hidden="true" tabindex="-1"></a>  <span class="at">labels =</span> lalonde_labels</span>
<span id="cb5-49"><a href="#cb5-49" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-50"><a href="#cb5-50" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-51"><a href="#cb5-51" aria-hidden="true" tabindex="-1"></a>lalonde_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-52"><a href="#cb5-52" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(lalonde_plot_data),</span>
<span id="cb5-53"><a href="#cb5-53" aria-hidden="true" tabindex="-1"></a>  <span class="at">treated_share =</span> <span class="fu">mean</span>(lalonde_plot_data<span class="sc">$</span>treat),</span>
<span id="cb5-54"><a href="#cb5-54" aria-hidden="true" tabindex="-1"></a>  <span class="at">matched_units =</span> <span class="fu">sum</span>(lalonde_match<span class="sc">$</span>weights <span class="sc">&gt;</span> <span class="dv">0</span>),</span>
<span id="cb5-55"><a href="#cb5-55" aria-hidden="true" tabindex="-1"></a>  <span class="at">treated_matched =</span> <span class="fu">sum</span>(lalonde_plot_data<span class="sc">$</span>treat <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> lalonde_match<span class="sc">$</span>weights <span class="sc">&gt;</span> <span class="dv">0</span>),</span>
<span id="cb5-56"><a href="#cb5-56" aria-hidden="true" tabindex="-1"></a>  <span class="at">control_matched =</span> <span class="fu">sum</span>(lalonde_plot_data<span class="sc">$</span>treat <span class="sc">==</span> <span class="dv">0</span> <span class="sc">&amp;</span> lalonde_match<span class="sc">$</span>weights <span class="sc">&gt;</span> <span class="dv">0</span>)</span>
<span id="cb5-57"><a href="#cb5-57" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-58"><a href="#cb5-58" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-59"><a href="#cb5-59" aria-hidden="true" tabindex="-1"></a>lalonde_balance_table <span class="ot">&lt;-</span> <span class="fu">merge</span>(</span>
<span id="cb5-60"><a href="#cb5-60" aria-hidden="true" tabindex="-1"></a>  <span class="fu">subset</span>(</span>
<span id="cb5-61"><a href="#cb5-61" aria-hidden="true" tabindex="-1"></a>    lalonde_balance,</span>
<span id="cb5-62"><a href="#cb5-62" aria-hidden="true" tabindex="-1"></a>    sample <span class="sc">==</span> <span class="st">"Before adjustment"</span>,</span>
<span id="cb5-63"><a href="#cb5-63" aria-hidden="true" tabindex="-1"></a>    <span class="at">select =</span> <span class="fu">c</span>(<span class="st">"covariate_label"</span>, <span class="st">"abs_smd"</span>)</span>
<span id="cb5-64"><a href="#cb5-64" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb5-65"><a href="#cb5-65" aria-hidden="true" tabindex="-1"></a>  <span class="fu">subset</span>(</span>
<span id="cb5-66"><a href="#cb5-66" aria-hidden="true" tabindex="-1"></a>    lalonde_balance,</span>
<span id="cb5-67"><a href="#cb5-67" aria-hidden="true" tabindex="-1"></a>    sample <span class="sc">==</span> <span class="st">"After adjustment"</span>,</span>
<span id="cb5-68"><a href="#cb5-68" aria-hidden="true" tabindex="-1"></a>    <span class="at">select =</span> <span class="fu">c</span>(<span class="st">"covariate_label"</span>, <span class="st">"abs_smd"</span>)</span>
<span id="cb5-69"><a href="#cb5-69" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb5-70"><a href="#cb5-70" aria-hidden="true" tabindex="-1"></a>  <span class="at">by =</span> <span class="st">"covariate_label"</span>,</span>
<span id="cb5-71"><a href="#cb5-71" aria-hidden="true" tabindex="-1"></a>  <span class="at">suffixes =</span> <span class="fu">c</span>(<span class="st">"_before"</span>, <span class="st">"_after"</span>)</span>
<span id="cb5-72"><a href="#cb5-72" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-73"><a href="#cb5-73" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-74"><a href="#cb5-74" aria-hidden="true" tabindex="-1"></a>lalonde_balance_table <span class="ot">&lt;-</span> lalonde_balance_table <span class="sc">|&gt;</span></span>
<span id="cb5-75"><a href="#cb5-75" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(abs_smd_before))</span>
<span id="cb5-76"><a href="#cb5-76" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-77"><a href="#cb5-77" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-78"><a href="#cb5-78" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(lalonde_summary, <span class="at">digits =</span> <span class="dv">1</span>),</span>
<span id="cb5-79"><a href="#cb5-79" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Public LaLonde benchmark setup for the Love plot example"</span></span>
<span id="cb5-80"><a href="#cb5-80" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Public LaLonde benchmark setup for the Love plot example</caption>
<colgroup>
<col style="width: 16%">
<col style="width: 19%">
<col style="width: 19%">
<col style="width: 22%">
<col style="width: 22%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">treated_share</th>
<th style="text-align: right;">matched_units</th>
<th style="text-align: right;">treated_matched</th>
<th style="text-align: right;">control_matched</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">614</td>
<td style="text-align: right;">0.3</td>
<td style="text-align: right;">370</td>
<td style="text-align: right;">185</td>
<td style="text-align: right;">185</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(lalonde_balance_table, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Absolute standardized mean differences before and after nearest-neighbor matching in the LaLonde benchmark"</span></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Absolute standardized mean differences before and after nearest-neighbor matching in the LaLonde benchmark</caption>
<thead>
<tr class="header">
<th style="text-align: left;">covariate_label</th>
<th style="text-align: right;">abs_smd_before</th>
<th style="text-align: right;">abs_smd_after</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Black</td>
<td style="text-align: right;">1.671</td>
<td style="text-align: right;">0.854</td>
</tr>
<tr class="even">
<td style="text-align: left;">Married</td>
<td style="text-align: right;">0.721</td>
<td style="text-align: right;">0.054</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Earnings in 1974 (thousand USD)</td>
<td style="text-align: right;">0.597</td>
<td style="text-align: right;">0.054</td>
</tr>
<tr class="even">
<td style="text-align: left;">Earnings in 1975 (thousand USD)</td>
<td style="text-align: right;">0.288</td>
<td style="text-align: right;">0.028</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Hispanic</td>
<td style="text-align: right;">0.277</td>
<td style="text-align: right;">0.467</td>
</tr>
<tr class="even">
<td style="text-align: left;">Age</td>
<td style="text-align: right;">0.242</td>
<td style="text-align: right;">0.057</td>
</tr>
<tr class="odd">
<td style="text-align: left;">No high-school degree</td>
<td style="text-align: right;">0.235</td>
<td style="text-align: right;">0.150</td>
</tr>
<tr class="even">
<td style="text-align: left;">Years of education</td>
<td style="text-align: right;">0.045</td>
<td style="text-align: right;">0.110</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The main substantive point is that the figure is evaluating the design stage rather than the outcome model. That is why Love plots are so useful in causal work. They separate the question "Did the design create comparable groups?" from the later question "What treatment effect do we estimate once the design is acceptable?"</p>
</section>
<section id="step-4-draw-the-real-world-love-plot" class="level2" data-number="68.5">
<h2 data-number="68.5" class="anchored" data-anchor-id="step-4-draw-the-real-world-love-plot"><span class="header-section-number">68.5</span> Step 4: Draw the real-world Love plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a>lalonde_love_plot <span class="ot">&lt;-</span> <span class="fu">build_love_plot</span>(</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>  lalonde_balance,</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Love plot for covariate balance in the public LaLonde benchmark"</span>,</span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Absolute standardized mean differences before and after nearest-neighbor propensity-score matching"</span></span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a>lalonde_love_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/love-plot-covariate-balance_files/figure-html/unnamed-chunk-5-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This is a transparent partial replication rather than a literal reproduction of a figure from the original papers. LaLonde and Dehejia-Wahba were not published as Love-plot tutorials. The contribution here is different: it uses the public benchmark data and a standard matching design to show how a balance figure helps diagnose whether observational adjustment has moved the analysis closer to an experimental comparison.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="68.6">
<h2 data-number="68.6" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">68.6</span> How to read the figure carefully</h2>
<p>A Love plot is easy to misread if the analyst treats it as a causal estimate rather than a diagnostic. The figure does not prove that confounding has been solved. It shows only whether the observed covariates included in the balance check are more similar across treated and control groups.</p>
<p>Three reading rules matter most:</p>
<ol type="1">
<li>focus first on the post-adjustment points, because those determine whether the design is acceptable;</li>
<li>compare the whole pattern rather than one covariate in isolation, because one stubbornly imbalanced variable can still matter even if most others improved;</li>
<li>remember that excellent balance on observed covariates does not eliminate the possibility of unmeasured confounding.</li>
</ol>
<p>In practice, the Love plot is strongest when paired with overlap checks, sample-size accounting, and a clear explanation of the propensity-score or matching specification.</p>
</section>
<section id="further-reading" class="level2" data-number="68.7">
<h2 data-number="68.7" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">68.7</span> Further reading</h2>
<p>For broader guidance on causal design with propensity scores, Stuart's review remains a strong conceptual reference <span class="citation" data-cites="stuart2010">Stuart (<a href="#ref-stuart2010" role="doc-biblioref">2010</a>)</span>. Austin gives a practical discussion of propensity-score implementation and diagnostics, including standardized differences and the role of balance assessment in applied work <span class="citation" data-cites="austin2011">Austin (<a href="#ref-austin2011" role="doc-biblioref">2011</a>)</span>; <span class="citation" data-cites="austin2009balance">Austin (<a href="#ref-austin2009balance" role="doc-biblioref">2009</a>)</span>. For the preprocessing perspective on matching, Ho and colleagues provide the foundational <code>MatchIt</code> reference <span class="citation" data-cites="ho2011matchit">Ho et al. (<a href="#ref-ho2011matchit" role="doc-biblioref">2011</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-austin2009balance" class="csl-entry" role="listitem">
Austin, Peter C. 2009. <span>"Balance Diagnostics for Comparing the Distribution of Baseline Covariates Between Treatment Groups in Propensity-Score Matched Samples."</span> <em>Statistics in Medicine</em> 28 (25): 3083-3107. <a href="https://doi.org/10.1002/sim.3697">https://doi.org/10.1002/sim.3697</a>.
</div>
<div id="ref-austin2011" class="csl-entry" role="listitem">
---. 2011. <span>"An Introduction to Propensity Score Methods for Reducing the Effects of Confounding in Observational Studies."</span> <em>Multivariate Behavioral Research</em> 46 (3): 399-424. <a href="https://doi.org/10.1080/00273171.2011.568786">https://doi.org/10.1080/00273171.2011.568786</a>.
</div>
<div id="ref-dehejia1999" class="csl-entry" role="listitem">
Dehejia, Rajeev H., and Sadek Wahba. 1999. <span>"Causal Effects in Nonexperimental Studies: Reevaluating the Evaluation of Training Programs."</span> <em>Journal of the American Statistical Association</em> 94 (448): 1053-62. <a href="https://doi.org/10.1080/01621459.1999.10473858">https://doi.org/10.1080/01621459.1999.10473858</a>.
</div>
<div id="ref-ho2011matchit" class="csl-entry" role="listitem">
Ho, Daniel E., Kosuke Imai, Gary King, and Elizabeth A. Stuart. 2011. <span>"MatchIt: Nonparametric Preprocessing for Parametric Causal Inference."</span> <em>Journal of Statistical Software</em> 42 (8): 1-28. <a href="https://doi.org/10.18637/jss.v042.i08">https://doi.org/10.18637/jss.v042.i08</a>.
</div>
<div id="ref-lalonde1986" class="csl-entry" role="listitem">
LaLonde, Robert J. 1986. <span>"Evaluating the Econometric Evaluations of Training Programs with Experimental Data."</span> <em>The American Economic Review</em> 76 (4): 604-20. <a href="https://www.jstor.org/stable/1806062">https://www.jstor.org/stable/1806062</a>.
</div>
<div id="ref-stuart2010" class="csl-entry" role="listitem">
Stuart, Elizabeth A. 2010. <span>"Matching Methods for Causal Inference: A Review and a Look Forward."</span> <em>Statistical Science</em> 25 (1): 1-21. <a href="https://doi.org/10.1214/09-STS313">https://doi.org/10.1214/09-STS313</a>.
</div>
</div>
</section>
