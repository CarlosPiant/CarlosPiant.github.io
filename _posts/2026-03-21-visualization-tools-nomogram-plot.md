---
title: "Nomogram Plot"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a nomogram plot, a figure that translates a prediction model into a visual points system. Nomograms are especially common in clinical prediction because they help readers approximate an..."
---
<p>This chapter builds a nomogram plot, a figure that translates a prediction model into a visual points system. Nomograms are especially common in clinical prediction because they help readers approximate an individual's predicted risk without reading regression coefficients directly. Rather than reporting a fitted model as a table of log-odds or hazard ratios, the nomogram converts each predictor into a point contribution, sums the points, and maps the total to a predicted probability or survival outcome. Iasonos and colleagues explain why nomograms became popular in oncology and prognosis research: they preserve the model structure while making it more usable for bedside or policy-oriented interpretation <span class="citation" data-cites="iasonos2008nomograms">Iasonos et al. (<a href="#ref-iasonos2008nomograms" role="doc-biblioref">2008</a>)</span>.</p>
<p>The main value of the figure is interpretability. A coefficient table tells the analyst how predictors shift the linear predictor. A nomogram tells the reader how a particular patient profile translates into a total risk score. That makes it a useful communication device when the audience cares about individualized prediction rather than only model fit.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="70.1">
<h2 data-number="70.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">70.1</span> What the visualization is showing</h2>
<p>We will build a static nomogram for a logistic regression model. The figure will contain:</p>
<ol type="1">
<li>a top points axis,</li>
<li>one row for each predictor,</li>
<li>a total-points axis,</li>
<li>a predicted-risk axis.</li>
</ol>
<p>The underlying logic is additive. If the fitted model is</p>
<p><span class="math display">\[
\text{logit}\{P(Y=1 \mid X)\} = \beta_0 + \beta_1 X_1 + \cdots + \beta_p X_p,
\]</span></p>
<p>then the nomogram rescales the predictor contributions <span class="math inline">\(\beta_j X_j\)</span> into points. The strongest predictor range is often assigned 100 points, and the other predictors are scaled relative to it. The reader can then add the points across predictors and convert the total back into predicted risk.</p>
<p>The key reading rule is simple: for each predictor, locate the patient's value, read the corresponding points, sum those points across rows, and then project the total onto the risk scale.</p>
</section>
<section id="step-1-fit-a-synthetic-prediction-model" class="level2" data-number="70.2">
<h2 data-number="70.2" class="anchored" data-anchor-id="step-1-fit-a-synthetic-prediction-model"><span class="header-section-number">70.2</span> Step 1: Fit a synthetic prediction model</h2>
<p>We begin with a synthetic 30-day readmission model. The purpose is not to claim substantive truth. It is to create a realistic fitted logistic model that can be turned into a clean nomogram.</p>
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
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>prepare_nomogram <span class="ot">&lt;-</span> <span class="cf">function</span>(model, specs, <span class="at">top_points =</span> <span class="dv">100</span>) {</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  beta <span class="ot">&lt;-</span> <span class="fu">coef</span>(model)</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  intercept <span class="ot">&lt;-</span> <span class="fu">unname</span>(beta[<span class="dv">1</span>])</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  predictor_info <span class="ot">&lt;-</span> <span class="fu">lapply</span>(specs, <span class="cf">function</span>(spec) {</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>    b <span class="ot">&lt;-</span> <span class="fu">unname</span>(beta[spec<span class="sc">$</span>term])</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>    values <span class="ot">&lt;-</span> <span class="cf">if</span> (spec<span class="sc">$</span>type <span class="sc">==</span> <span class="st">"continuous"</span>) {</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>      <span class="fu">seq</span>(spec<span class="sc">$</span>min, spec<span class="sc">$</span>max, <span class="at">length.out =</span> spec<span class="sc">$</span>n_ticks)</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>    } <span class="cf">else</span> {</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>      spec<span class="sc">$</span>values</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>    }</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>    contribution <span class="ot">&lt;-</span> b <span class="sc">*</span> values</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>    min_contribution <span class="ot">&lt;-</span> <span class="fu">min</span>(contribution)</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>    max_contribution <span class="ot">&lt;-</span> <span class="fu">max</span>(contribution)</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>    range_contribution <span class="ot">&lt;-</span> max_contribution <span class="sc">-</span> min_contribution</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>    <span class="fu">list</span>(</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>      <span class="at">term =</span> spec<span class="sc">$</span>term,</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>      <span class="at">label =</span> spec<span class="sc">$</span>label,</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>      <span class="at">type =</span> spec<span class="sc">$</span>type,</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>      <span class="at">values =</span> values,</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>      <span class="at">value_labels =</span> <span class="cf">if</span> (<span class="sc">!</span><span class="fu">is.null</span>(spec<span class="sc">$</span>value_labels)) spec<span class="sc">$</span>value_labels <span class="cf">else</span> <span class="fu">as.character</span>(<span class="fu">round</span>(values, <span class="dv">2</span>)),</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>      <span class="at">contribution =</span> contribution,</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>      <span class="at">min_contribution =</span> min_contribution,</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>      <span class="at">max_contribution =</span> max_contribution,</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>      <span class="at">range_contribution =</span> range_contribution</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>  max_range <span class="ot">&lt;-</span> <span class="fu">max</span>(<span class="fu">vapply</span>(predictor_info, <span class="cf">function</span>(x) x<span class="sc">$</span>range_contribution, <span class="fu">numeric</span>(<span class="dv">1</span>)))</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>  point_scale <span class="ot">&lt;-</span> top_points <span class="sc">/</span> max_range</span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>  axis_df <span class="ot">&lt;-</span> <span class="fu">bind_rows</span>(<span class="fu">lapply</span>(predictor_info, <span class="cf">function</span>(info) {</span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>    points <span class="ot">&lt;-</span> point_scale <span class="sc">*</span> (info<span class="sc">$</span>contribution <span class="sc">-</span> info<span class="sc">$</span>min_contribution)</span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(</span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>      <span class="at">row =</span> info<span class="sc">$</span>label,</span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>      <span class="at">value =</span> info<span class="sc">$</span>values,</span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>      <span class="at">value_label =</span> info<span class="sc">$</span>value_labels,</span>
<span id="cb1-52"><a href="#cb1-52" aria-hidden="true" tabindex="-1"></a>      <span class="at">points =</span> points,</span>
<span id="cb1-53"><a href="#cb1-53" aria-hidden="true" tabindex="-1"></a>      <span class="at">row_type =</span> <span class="st">"predictor"</span>,</span>
<span id="cb1-54"><a href="#cb1-54" aria-hidden="true" tabindex="-1"></a>      <span class="at">row_max_points =</span> <span class="fu">max</span>(points),</span>
<span id="cb1-55"><a href="#cb1-55" aria-hidden="true" tabindex="-1"></a>      <span class="at">stringsAsFactors =</span> <span class="cn">FALSE</span></span>
<span id="cb1-56"><a href="#cb1-56" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-57"><a href="#cb1-57" aria-hidden="true" tabindex="-1"></a>  }))</span>
<span id="cb1-58"><a href="#cb1-58" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-59"><a href="#cb1-59" aria-hidden="true" tabindex="-1"></a>  base_lp <span class="ot">&lt;-</span> intercept <span class="sc">+</span> <span class="fu">sum</span>(<span class="fu">vapply</span>(predictor_info, <span class="cf">function</span>(x) x<span class="sc">$</span>min_contribution, <span class="fu">numeric</span>(<span class="dv">1</span>)))</span>
<span id="cb1-60"><a href="#cb1-60" aria-hidden="true" tabindex="-1"></a>  total_max_points <span class="ot">&lt;-</span> <span class="fu">sum</span>(<span class="fu">vapply</span>(predictor_info, <span class="cf">function</span>(x) point_scale <span class="sc">*</span> x<span class="sc">$</span>range_contribution, <span class="fu">numeric</span>(<span class="dv">1</span>)))</span>
<span id="cb1-61"><a href="#cb1-61" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-62"><a href="#cb1-62" aria-hidden="true" tabindex="-1"></a>  risk_grid <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="fl">0.05</span>, <span class="fl">0.10</span>, <span class="fl">0.20</span>, <span class="fl">0.30</span>, <span class="fl">0.50</span>, <span class="fl">0.70</span>, <span class="fl">0.85</span>, <span class="fl">0.95</span>)</span>
<span id="cb1-63"><a href="#cb1-63" aria-hidden="true" tabindex="-1"></a>  total_points_for_risk <span class="ot">&lt;-</span> point_scale <span class="sc">*</span> (<span class="fu">qlogis</span>(risk_grid) <span class="sc">-</span> base_lp)</span>
<span id="cb1-64"><a href="#cb1-64" aria-hidden="true" tabindex="-1"></a>  keep <span class="ot">&lt;-</span> total_points_for_risk <span class="sc">&gt;=</span> <span class="dv">0</span> <span class="sc">&amp;</span> total_points_for_risk <span class="sc">&lt;=</span> total_max_points</span>
<span id="cb1-65"><a href="#cb1-65" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-66"><a href="#cb1-66" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(</span>
<span id="cb1-67"><a href="#cb1-67" aria-hidden="true" tabindex="-1"></a>    <span class="at">axis_df =</span> axis_df,</span>
<span id="cb1-68"><a href="#cb1-68" aria-hidden="true" tabindex="-1"></a>    <span class="at">point_scale =</span> point_scale,</span>
<span id="cb1-69"><a href="#cb1-69" aria-hidden="true" tabindex="-1"></a>    <span class="at">total_max_points =</span> total_max_points,</span>
<span id="cb1-70"><a href="#cb1-70" aria-hidden="true" tabindex="-1"></a>    <span class="at">risk_axis =</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-71"><a href="#cb1-71" aria-hidden="true" tabindex="-1"></a>      <span class="at">risk =</span> risk_grid[keep],</span>
<span id="cb1-72"><a href="#cb1-72" aria-hidden="true" tabindex="-1"></a>      <span class="at">total_points =</span> total_points_for_risk[keep],</span>
<span id="cb1-73"><a href="#cb1-73" aria-hidden="true" tabindex="-1"></a>      <span class="at">stringsAsFactors =</span> <span class="cn">FALSE</span></span>
<span id="cb1-74"><a href="#cb1-74" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-75"><a href="#cb1-75" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-76"><a href="#cb1-76" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-77"><a href="#cb1-77" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-78"><a href="#cb1-78" aria-hidden="true" tabindex="-1"></a>draw_nomogram <span class="ot">&lt;-</span> <span class="cf">function</span>(nomogram_obj, title, subtitle) {</span>
<span id="cb1-79"><a href="#cb1-79" aria-hidden="true" tabindex="-1"></a>  predictor_rows <span class="ot">&lt;-</span> <span class="fu">unique</span>(nomogram_obj<span class="sc">$</span>axis_df<span class="sc">$</span>row)</span>
<span id="cb1-80"><a href="#cb1-80" aria-hidden="true" tabindex="-1"></a>  row_order <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="st">"Points"</span>, predictor_rows, <span class="st">"Total points"</span>, <span class="st">"Predicted risk"</span>)</span>
<span id="cb1-81"><a href="#cb1-81" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-82"><a href="#cb1-82" aria-hidden="true" tabindex="-1"></a>  row_positions <span class="ot">&lt;-</span> <span class="fu">setNames</span>(<span class="fu">rev</span>(<span class="fu">seq_along</span>(row_order)), row_order)</span>
<span id="cb1-83"><a href="#cb1-83" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-84"><a href="#cb1-84" aria-hidden="true" tabindex="-1"></a>  predictor_lines <span class="ot">&lt;-</span> nomogram_obj<span class="sc">$</span>axis_df <span class="sc">|&gt;</span></span>
<span id="cb1-85"><a href="#cb1-85" aria-hidden="true" tabindex="-1"></a>    <span class="fu">group_by</span>(row) <span class="sc">|&gt;</span></span>
<span id="cb1-86"><a href="#cb1-86" aria-hidden="true" tabindex="-1"></a>    <span class="fu">summarise</span>(</span>
<span id="cb1-87"><a href="#cb1-87" aria-hidden="true" tabindex="-1"></a>      <span class="at">xmin =</span> <span class="dv">0</span>,</span>
<span id="cb1-88"><a href="#cb1-88" aria-hidden="true" tabindex="-1"></a>      <span class="at">xmax =</span> <span class="fu">max</span>(points),</span>
<span id="cb1-89"><a href="#cb1-89" aria-hidden="true" tabindex="-1"></a>      <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb1-90"><a href="#cb1-90" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">|&gt;</span></span>
<span id="cb1-91"><a href="#cb1-91" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mutate</span>(<span class="at">y =</span> row_positions[row])</span>
<span id="cb1-92"><a href="#cb1-92" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-93"><a href="#cb1-93" aria-hidden="true" tabindex="-1"></a>  top_axis <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-94"><a href="#cb1-94" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="fu">seq</span>(<span class="dv">0</span>, <span class="dv">100</span>, <span class="at">by =</span> <span class="dv">20</span>),</span>
<span id="cb1-95"><a href="#cb1-95" aria-hidden="true" tabindex="-1"></a>    <span class="at">label =</span> <span class="fu">seq</span>(<span class="dv">0</span>, <span class="dv">100</span>, <span class="at">by =</span> <span class="dv">20</span>),</span>
<span id="cb1-96"><a href="#cb1-96" aria-hidden="true" tabindex="-1"></a>    <span class="at">row =</span> <span class="st">"Points"</span>,</span>
<span id="cb1-97"><a href="#cb1-97" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="fu">unname</span>(row_positions[<span class="st">"Points"</span>])</span>
<span id="cb1-98"><a href="#cb1-98" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-99"><a href="#cb1-99" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-100"><a href="#cb1-100" aria-hidden="true" tabindex="-1"></a>  predictor_ticks <span class="ot">&lt;-</span> nomogram_obj<span class="sc">$</span>axis_df <span class="sc">|&gt;</span></span>
<span id="cb1-101"><a href="#cb1-101" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mutate</span>(<span class="at">y =</span> row_positions[row])</span>
<span id="cb1-102"><a href="#cb1-102" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-103"><a href="#cb1-103" aria-hidden="true" tabindex="-1"></a>  total_points_ticks <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-104"><a href="#cb1-104" aria-hidden="true" tabindex="-1"></a>    <span class="at">total_points =</span> <span class="fu">seq</span>(<span class="dv">0</span>, nomogram_obj<span class="sc">$</span>total_max_points, <span class="at">length.out =</span> <span class="dv">6</span>),</span>
<span id="cb1-105"><a href="#cb1-105" aria-hidden="true" tabindex="-1"></a>    <span class="at">label =</span> <span class="fu">round</span>(<span class="fu">seq</span>(<span class="dv">0</span>, nomogram_obj<span class="sc">$</span>total_max_points, <span class="at">length.out =</span> <span class="dv">6</span>)),</span>
<span id="cb1-106"><a href="#cb1-106" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="dv">100</span> <span class="sc">*</span> <span class="fu">seq</span>(<span class="dv">0</span>, nomogram_obj<span class="sc">$</span>total_max_points, <span class="at">length.out =</span> <span class="dv">6</span>) <span class="sc">/</span> nomogram_obj<span class="sc">$</span>total_max_points,</span>
<span id="cb1-107"><a href="#cb1-107" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="fu">unname</span>(row_positions[<span class="st">"Total points"</span>])</span>
<span id="cb1-108"><a href="#cb1-108" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-109"><a href="#cb1-109" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-110"><a href="#cb1-110" aria-hidden="true" tabindex="-1"></a>  risk_ticks <span class="ot">&lt;-</span> nomogram_obj<span class="sc">$</span>risk_axis <span class="sc">|&gt;</span></span>
<span id="cb1-111"><a href="#cb1-111" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mutate</span>(</span>
<span id="cb1-112"><a href="#cb1-112" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="dv">100</span> <span class="sc">*</span> total_points <span class="sc">/</span> nomogram_obj<span class="sc">$</span>total_max_points,</span>
<span id="cb1-113"><a href="#cb1-113" aria-hidden="true" tabindex="-1"></a>      <span class="at">label =</span> <span class="fu">sprintf</span>(<span class="st">"%.2f"</span>, risk),</span>
<span id="cb1-114"><a href="#cb1-114" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> <span class="fu">unname</span>(row_positions[<span class="st">"Predicted risk"</span>])</span>
<span id="cb1-115"><a href="#cb1-115" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-116"><a href="#cb1-116" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-117"><a href="#cb1-117" aria-hidden="true" tabindex="-1"></a>  row_labels <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-118"><a href="#cb1-118" aria-hidden="true" tabindex="-1"></a>    <span class="at">row =</span> row_order,</span>
<span id="cb1-119"><a href="#cb1-119" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="fu">unname</span>(row_positions[row_order])</span>
<span id="cb1-120"><a href="#cb1-120" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-121"><a href="#cb1-121" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-122"><a href="#cb1-122" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>() <span class="sc">+</span></span>
<span id="cb1-123"><a href="#cb1-123" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-124"><a href="#cb1-124" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> predictor_lines,</span>
<span id="cb1-125"><a href="#cb1-125" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> xmin, <span class="at">xend =</span> xmax, <span class="at">y =</span> y, <span class="at">yend =</span> y),</span>
<span id="cb1-126"><a href="#cb1-126" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.7</span>,</span>
<span id="cb1-127"><a href="#cb1-127" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#4d4d4d"</span></span>
<span id="cb1-128"><a href="#cb1-128" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-129"><a href="#cb1-129" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-130"><a href="#cb1-130" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> <span class="fu">data.frame</span>(<span class="at">y =</span> row_positions[<span class="st">"Points"</span>]),</span>
<span id="cb1-131"><a href="#cb1-131" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> <span class="dv">0</span>, <span class="at">xend =</span> <span class="dv">100</span>, <span class="at">y =</span> y, <span class="at">yend =</span> y),</span>
<span id="cb1-132"><a href="#cb1-132" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.7</span>,</span>
<span id="cb1-133"><a href="#cb1-133" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#4d4d4d"</span></span>
<span id="cb1-134"><a href="#cb1-134" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-135"><a href="#cb1-135" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-136"><a href="#cb1-136" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> <span class="fu">data.frame</span>(<span class="at">y =</span> row_positions[<span class="st">"Total points"</span>]),</span>
<span id="cb1-137"><a href="#cb1-137" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> <span class="dv">0</span>, <span class="at">xend =</span> <span class="dv">100</span>, <span class="at">y =</span> y, <span class="at">yend =</span> y),</span>
<span id="cb1-138"><a href="#cb1-138" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.7</span>,</span>
<span id="cb1-139"><a href="#cb1-139" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#4d4d4d"</span></span>
<span id="cb1-140"><a href="#cb1-140" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-141"><a href="#cb1-141" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-142"><a href="#cb1-142" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> <span class="fu">data.frame</span>(<span class="at">y =</span> row_positions[<span class="st">"Predicted risk"</span>]),</span>
<span id="cb1-143"><a href="#cb1-143" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> <span class="dv">0</span>, <span class="at">xend =</span> <span class="dv">100</span>, <span class="at">y =</span> y, <span class="at">yend =</span> y),</span>
<span id="cb1-144"><a href="#cb1-144" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.7</span>,</span>
<span id="cb1-145"><a href="#cb1-145" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#4d4d4d"</span></span>
<span id="cb1-146"><a href="#cb1-146" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-147"><a href="#cb1-147" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-148"><a href="#cb1-148" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> top_axis,</span>
<span id="cb1-149"><a href="#cb1-149" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">xend =</span> x, <span class="at">y =</span> y <span class="sc">-</span> <span class="fl">0.14</span>, <span class="at">yend =</span> y <span class="sc">+</span> <span class="fl">0.14</span>),</span>
<span id="cb1-150"><a href="#cb1-150" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.55</span></span>
<span id="cb1-151"><a href="#cb1-151" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-152"><a href="#cb1-152" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-153"><a href="#cb1-153" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> top_axis,</span>
<span id="cb1-154"><a href="#cb1-154" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y <span class="sc">+</span> <span class="fl">0.34</span>, <span class="at">label =</span> label),</span>
<span id="cb1-155"><a href="#cb1-155" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.0</span></span>
<span id="cb1-156"><a href="#cb1-156" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-157"><a href="#cb1-157" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-158"><a href="#cb1-158" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> predictor_ticks,</span>
<span id="cb1-159"><a href="#cb1-159" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> points, <span class="at">xend =</span> points, <span class="at">y =</span> y <span class="sc">-</span> <span class="fl">0.14</span>, <span class="at">yend =</span> y <span class="sc">+</span> <span class="fl">0.14</span>),</span>
<span id="cb1-160"><a href="#cb1-160" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.55</span></span>
<span id="cb1-161"><a href="#cb1-161" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-162"><a href="#cb1-162" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-163"><a href="#cb1-163" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> predictor_ticks,</span>
<span id="cb1-164"><a href="#cb1-164" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> points, <span class="at">y =</span> y <span class="sc">+</span> <span class="fl">0.34</span>, <span class="at">label =</span> value_label),</span>
<span id="cb1-165"><a href="#cb1-165" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">2.8</span></span>
<span id="cb1-166"><a href="#cb1-166" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-167"><a href="#cb1-167" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-168"><a href="#cb1-168" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> total_points_ticks,</span>
<span id="cb1-169"><a href="#cb1-169" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">xend =</span> x, <span class="at">y =</span> y <span class="sc">-</span> <span class="fl">0.14</span>, <span class="at">yend =</span> y <span class="sc">+</span> <span class="fl">0.14</span>),</span>
<span id="cb1-170"><a href="#cb1-170" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.55</span></span>
<span id="cb1-171"><a href="#cb1-171" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-172"><a href="#cb1-172" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-173"><a href="#cb1-173" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> total_points_ticks,</span>
<span id="cb1-174"><a href="#cb1-174" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y <span class="sc">+</span> <span class="fl">0.34</span>, <span class="at">label =</span> label),</span>
<span id="cb1-175"><a href="#cb1-175" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.0</span></span>
<span id="cb1-176"><a href="#cb1-176" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-177"><a href="#cb1-177" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-178"><a href="#cb1-178" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> risk_ticks,</span>
<span id="cb1-179"><a href="#cb1-179" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">xend =</span> x, <span class="at">y =</span> y <span class="sc">-</span> <span class="fl">0.14</span>, <span class="at">yend =</span> y <span class="sc">+</span> <span class="fl">0.14</span>),</span>
<span id="cb1-180"><a href="#cb1-180" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.55</span></span>
<span id="cb1-181"><a href="#cb1-181" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-182"><a href="#cb1-182" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-183"><a href="#cb1-183" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> risk_ticks,</span>
<span id="cb1-184"><a href="#cb1-184" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y <span class="sc">+</span> <span class="fl">0.34</span>, <span class="at">label =</span> label),</span>
<span id="cb1-185"><a href="#cb1-185" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.0</span></span>
<span id="cb1-186"><a href="#cb1-186" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-187"><a href="#cb1-187" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-188"><a href="#cb1-188" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> row_labels,</span>
<span id="cb1-189"><a href="#cb1-189" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> <span class="sc">-</span><span class="dv">15</span>, <span class="at">y =</span> y, <span class="at">label =</span> row),</span>
<span id="cb1-190"><a href="#cb1-190" aria-hidden="true" tabindex="-1"></a>      <span class="at">hjust =</span> <span class="dv">1</span>,</span>
<span id="cb1-191"><a href="#cb1-191" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.4</span>,</span>
<span id="cb1-192"><a href="#cb1-192" aria-hidden="true" tabindex="-1"></a>      <span class="at">fontface =</span> <span class="fu">ifelse</span>(row_labels<span class="sc">$</span>row <span class="sc">%in%</span> <span class="fu">c</span>(<span class="st">"Points"</span>, <span class="st">"Total points"</span>, <span class="st">"Predicted risk"</span>), <span class="st">"bold"</span>, <span class="st">"plain"</span>)</span>
<span id="cb1-193"><a href="#cb1-193" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-194"><a href="#cb1-194" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coord_cartesian</span>(<span class="at">xlim =</span> <span class="fu">c</span>(<span class="sc">-</span><span class="dv">18</span>, <span class="dv">102</span>), <span class="at">ylim =</span> <span class="fu">c</span>(<span class="fl">0.5</span>, <span class="fu">max</span>(row_positions) <span class="sc">+</span> <span class="fl">0.9</span>), <span class="at">clip =</span> <span class="st">"off"</span>) <span class="sc">+</span></span>
<span id="cb1-195"><a href="#cb1-195" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb1-196"><a href="#cb1-196" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb1-197"><a href="#cb1-197" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle</span>
<span id="cb1-198"><a href="#cb1-198" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-199"><a href="#cb1-199" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_void</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb1-200"><a href="#cb1-200" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb1-201"><a href="#cb1-201" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.title =</span> <span class="fu">element_text</span>(<span class="at">face =</span> <span class="st">"bold"</span>, <span class="at">size =</span> <span class="dv">13</span>),</span>
<span id="cb1-202"><a href="#cb1-202" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.subtitle =</span> <span class="fu">element_text</span>(<span class="at">size =</span> <span class="dv">10</span>, <span class="at">color =</span> <span class="st">"#4d4d4d"</span>),</span>
<span id="cb1-203"><a href="#cb1-203" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.margin =</span> <span class="fu">margin</span>(<span class="dv">10</span>, <span class="dv">20</span>, <span class="dv">10</span>, <span class="dv">50</span>)</span>
<span id="cb1-204"><a href="#cb1-204" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-205"><a href="#cb1-205" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2028</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>n_patients <span class="ot">&lt;-</span> <span class="dv">900</span></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>synthetic_nomogram_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">age10 =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="fl">6.7</span>, <span class="at">sd =</span> <span class="fl">1.1</span>),</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">comorbidity =</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>),</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">prior_adm =</span> <span class="fu">rpois</span>(n_patients, <span class="at">lambda =</span> <span class="fl">1.5</span>),</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">female =</span> <span class="fu">rbinom</span>(n_patients, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.56</span>),</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">care_program =</span> <span class="fu">rbinom</span>(n_patients, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.45</span>)</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>synthetic_lp <span class="ot">&lt;-</span> <span class="fu">with</span>(</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  synthetic_nomogram_data,</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  <span class="sc">-</span><span class="fl">2.1</span> <span class="sc">+</span></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.28</span> <span class="sc">*</span> age10 <span class="sc">+</span></span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.52</span> <span class="sc">*</span> comorbidity <span class="sc">+</span></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.24</span> <span class="sc">*</span> prior_adm <span class="sc">-</span></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.22</span> <span class="sc">*</span> female <span class="sc">-</span></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.58</span> <span class="sc">*</span> care_program</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>synthetic_nomogram_data<span class="sc">$</span>readmission <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  n_patients,</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">size =</span> <span class="dv">1</span>,</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>  <span class="at">prob =</span> <span class="fu">plogis</span>(synthetic_lp)</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>synthetic_model <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  readmission <span class="sc">~</span> age10 <span class="sc">+</span> comorbidity <span class="sc">+</span> prior_adm <span class="sc">+</span> female <span class="sc">+</span> care_program,</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_nomogram_data,</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(synthetic_nomogram_data),</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">readmission_rate =</span> <span class="fu">mean</span>(synthetic_nomogram_data<span class="sc">$</span>readmission),</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_age10 =</span> <span class="fu">mean</span>(synthetic_nomogram_data<span class="sc">$</span>age10),</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_prior_adm =</span> <span class="fu">mean</span>(synthetic_nomogram_data<span class="sc">$</span>prior_adm)</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_summary, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Synthetic readmission sample used for the nomogram"</span></span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Synthetic readmission sample used for the nomogram</caption>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">readmission_rate</th>
<th style="text-align: right;">mean_age10</th>
<th style="text-align: right;">mean_prior_adm</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">900</td>
<td style="text-align: right;">0.453</td>
<td style="text-align: right;">6.716</td>
<td style="text-align: right;">1.468</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-2-convert-the-synthetic-model-into-nomogram-scales" class="level2" data-number="70.3">
<h2 data-number="70.3" class="anchored" data-anchor-id="step-2-convert-the-synthetic-model-into-nomogram-scales"><span class="header-section-number">70.3</span> Step 2: Convert the synthetic model into nomogram scales</h2>
<p>The main transformation is from regression contribution to points. For each predictor, the lowest-risk value on the plotted range is assigned 0 points, and the highest-risk value gets a larger point value proportional to its contribution to the linear predictor.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>synthetic_specs <span class="ot">&lt;-</span> <span class="fu">list</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"age10"</span>, <span class="at">label =</span> <span class="st">"Age (per 10 years)"</span>, <span class="at">type =</span> <span class="st">"continuous"</span>, <span class="at">min =</span> <span class="fl">4.5</span>, <span class="at">max =</span> <span class="fl">9.0</span>, <span class="at">n_ticks =</span> <span class="dv">6</span>),</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"comorbidity"</span>, <span class="at">label =</span> <span class="st">"Comorbidity score"</span>, <span class="at">type =</span> <span class="st">"continuous"</span>, <span class="at">min =</span> <span class="sc">-</span><span class="fl">2.0</span>, <span class="at">max =</span> <span class="fl">2.0</span>, <span class="at">n_ticks =</span> <span class="dv">5</span>),</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"prior_adm"</span>, <span class="at">label =</span> <span class="st">"Prior admissions"</span>, <span class="at">type =</span> <span class="st">"continuous"</span>, <span class="at">min =</span> <span class="dv">0</span>, <span class="at">max =</span> <span class="dv">5</span>, <span class="at">n_ticks =</span> <span class="dv">6</span>),</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"female"</span>, <span class="at">label =</span> <span class="st">"Female"</span>, <span class="at">type =</span> <span class="st">"binary"</span>, <span class="at">values =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>), <span class="at">value_labels =</span> <span class="fu">c</span>(<span class="st">"No"</span>, <span class="st">"Yes"</span>)),</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"care_program"</span>, <span class="at">label =</span> <span class="st">"Care-management program"</span>, <span class="at">type =</span> <span class="st">"binary"</span>, <span class="at">values =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>), <span class="at">value_labels =</span> <span class="fu">c</span>(<span class="st">"No"</span>, <span class="st">"Yes"</span>))</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>synthetic_nomogram <span class="ot">&lt;-</span> <span class="fu">prepare_nomogram</span>(</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">model =</span> synthetic_model,</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">specs =</span> synthetic_specs</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>synthetic_point_ranges <span class="ot">&lt;-</span> synthetic_nomogram<span class="sc">$</span>axis_df <span class="sc">|&gt;</span></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  <span class="fu">group_by</span>(row) <span class="sc">|&gt;</span></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarise</span>(</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">min_points =</span> <span class="fu">min</span>(points),</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">max_points =</span> <span class="fu">max</span>(points),</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_point_ranges, <span class="at">digits =</span> <span class="dv">1</span>),</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Point ranges assigned to each predictor in the synthetic nomogram"</span></span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Point ranges assigned to each predictor in the synthetic nomogram</caption>
<thead>
<tr class="header">
<th style="text-align: left;">row</th>
<th style="text-align: right;">min_points</th>
<th style="text-align: right;">max_points</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Age (per 10 years)</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">56.3</td>
</tr>
<tr class="even">
<td style="text-align: left;">Care-management program</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">25.5</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Comorbidity score</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">100.0</td>
</tr>
<tr class="even">
<td style="text-align: left;">Female</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">5.7</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Prior admissions</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">32.0</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The table shows which predictors dominate the point system. The nomogram itself turns those ranges into a readable bedside-style figure.</p>
</section>
<section id="step-3-draw-the-synthetic-nomogram" class="level2" data-number="70.4">
<h2 data-number="70.4" class="anchored" data-anchor-id="step-3-draw-the-synthetic-nomogram"><span class="header-section-number">70.4</span> Step 3: Draw the synthetic nomogram</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_nomogram_plot <span class="ot">&lt;-</span> <span class="fu">draw_nomogram</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  synthetic_nomogram,</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"A nomogram translates a readmission model into an additive point system"</span>,</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Synthetic 30-day readmission example"</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>synthetic_nomogram_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/nomogram-plot_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure can be read row by row. An older patient with a high comorbidity score and multiple prior admissions accumulates more points. Enrollment in the care-management program reduces points because it lowers predicted risk in the fitted model.</p>
</section>
<section id="step-4-build-a-real-world-nomogram-from-a-public-prognostic-dataset" class="level2" data-number="70.5">
<h2 data-number="70.5" class="anchored" data-anchor-id="step-4-build-a-real-world-nomogram-from-a-public-prognostic-dataset"><span class="header-section-number">70.5</span> Step 4: Build a real-world nomogram from a public prognostic dataset</h2>
<p>For a real-world example, we use the public <code>lung</code> dataset distributed with <code>survival</code>, the NCCTG lung cancer data. The original dataset is not itself a published nomogram, so this is a transparent partial application. We fit a simple 180-day mortality model and then convert it into a nomogram-style figure using age, sex, ECOG performance status, and recent weight loss.</p>
<p>The goal is not to claim that this is the definitive prognostic tool for lung cancer. It is to show how a clinically familiar prediction problem can be presented in nomogram form with fully reproducible code.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(survival)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>lung_nomogram_data <span class="ot">&lt;-</span> survival<span class="sc">::</span>lung <span class="sc">|&gt;</span></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">transmute</span>(</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">dead_180 =</span> <span class="fu">ifelse</span>(status <span class="sc">==</span> <span class="dv">2</span> <span class="sc">&amp;</span> time <span class="sc">&lt;=</span> <span class="dv">180</span>, <span class="dv">1</span>, <span class="fu">ifelse</span>(time <span class="sc">&gt;</span> <span class="dv">180</span>, <span class="dv">0</span>, <span class="cn">NA</span>)),</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">age10 =</span> age <span class="sc">/</span> <span class="dv">10</span>,</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">female =</span> <span class="fu">ifelse</span>(sex <span class="sc">==</span> <span class="dv">2</span>, <span class="dv">1</span>, <span class="dv">0</span>),</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">ecog =</span> ph.ecog,</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">wtloss10 =</span> wt.loss <span class="sc">/</span> <span class="dv">10</span></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>lung_nomogram_data <span class="ot">&lt;-</span> lung_nomogram_data[<span class="fu">complete.cases</span>(lung_nomogram_data), ]</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>lung_model <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  dead_180 <span class="sc">~</span> age10 <span class="sc">+</span> female <span class="sc">+</span> ecog <span class="sc">+</span> wtloss10,</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> lung_nomogram_data,</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>lung_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(lung_nomogram_data),</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">mortality_180d =</span> <span class="fu">mean</span>(lung_nomogram_data<span class="sc">$</span>dead_180),</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_age10 =</span> <span class="fu">mean</span>(lung_nomogram_data<span class="sc">$</span>age10),</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">female_share =</span> <span class="fu">mean</span>(lung_nomogram_data<span class="sc">$</span>female)</span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(lung_summary, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Public NCCTG lung cancer sample used for the nomogram example"</span></span>
<span id="cb5-30"><a href="#cb5-30" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Public NCCTG lung cancer sample used for the nomogram example</caption>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">mortality_180d</th>
<th style="text-align: right;">mean_age10</th>
<th style="text-align: right;">female_share</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">207</td>
<td style="text-align: right;">0.256</td>
<td style="text-align: right;">6.248</td>
<td style="text-align: right;">0.391</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>lung_specs <span class="ot">&lt;-</span> <span class="fu">list</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"age10"</span>, <span class="at">label =</span> <span class="st">"Age (per 10 years)"</span>, <span class="at">type =</span> <span class="st">"continuous"</span>, <span class="at">min =</span> <span class="fl">4.0</span>, <span class="at">max =</span> <span class="fl">8.5</span>, <span class="at">n_ticks =</span> <span class="dv">6</span>),</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"female"</span>, <span class="at">label =</span> <span class="st">"Female"</span>, <span class="at">type =</span> <span class="st">"binary"</span>, <span class="at">values =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>), <span class="at">value_labels =</span> <span class="fu">c</span>(<span class="st">"No"</span>, <span class="st">"Yes"</span>)),</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"ecog"</span>, <span class="at">label =</span> <span class="st">"ECOG status"</span>, <span class="at">type =</span> <span class="st">"continuous"</span>, <span class="at">min =</span> <span class="dv">0</span>, <span class="at">max =</span> <span class="dv">3</span>, <span class="at">n_ticks =</span> <span class="dv">4</span>),</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(<span class="at">term =</span> <span class="st">"wtloss10"</span>, <span class="at">label =</span> <span class="st">"Weight loss (per 10 lb)"</span>, <span class="at">type =</span> <span class="st">"continuous"</span>, <span class="at">min =</span> <span class="dv">0</span>, <span class="at">max =</span> <span class="dv">4</span>, <span class="at">n_ticks =</span> <span class="dv">5</span>)</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>lung_nomogram <span class="ot">&lt;-</span> <span class="fu">prepare_nomogram</span>(</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">model =</span> lung_model,</span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">specs =</span> lung_specs</span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>lung_point_ranges <span class="ot">&lt;-</span> lung_nomogram<span class="sc">$</span>axis_df <span class="sc">|&gt;</span></span>
<span id="cb6-14"><a href="#cb6-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">group_by</span>(row) <span class="sc">|&gt;</span></span>
<span id="cb6-15"><a href="#cb6-15" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarise</span>(</span>
<span id="cb6-16"><a href="#cb6-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">min_points =</span> <span class="fu">min</span>(points),</span>
<span id="cb6-17"><a href="#cb6-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">max_points =</span> <span class="fu">max</span>(points),</span>
<span id="cb6-18"><a href="#cb6-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb6-19"><a href="#cb6-19" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb6-20"><a href="#cb6-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-21"><a href="#cb6-21" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-22"><a href="#cb6-22" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(lung_point_ranges, <span class="at">digits =</span> <span class="dv">1</span>),</span>
<span id="cb6-23"><a href="#cb6-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Point ranges in the public lung-cancer nomogram"</span></span>
<span id="cb6-24"><a href="#cb6-24" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Point ranges in the public lung-cancer nomogram</caption>
<thead>
<tr class="header">
<th style="text-align: left;">row</th>
<th style="text-align: right;">min_points</th>
<th style="text-align: right;">max_points</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Age (per 10 years)</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">37.9</td>
</tr>
<tr class="even">
<td style="text-align: left;">ECOG status</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">100.0</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Female</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">44.2</td>
</tr>
<tr class="even">
<td style="text-align: left;">Weight loss (per 10 lb)</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">27.3</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-5-draw-the-real-world-nomogram" class="level2" data-number="70.6">
<h2 data-number="70.6" class="anchored" data-anchor-id="step-5-draw-the-real-world-nomogram"><span class="header-section-number">70.6</span> Step 5: Draw the real-world nomogram</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a>lung_nomogram_plot <span class="ot">&lt;-</span> <span class="fu">draw_nomogram</span>(</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>  lung_nomogram,</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Nomogram for 180-day mortality in the public NCCTG lung cancer data"</span>,</span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"A transparent partial prognostic nomogram built from survival::lung"</span></span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a>lung_nomogram_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/nomogram-plot_files/figure-html/unnamed-chunk-7-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This is a transparent partial replication rather than a recreation of a published nomogram figure. The clinical dataset is real and public, the outcome is clinically meaningful, and the plotted nomogram uses the same additive-translation logic that makes nomograms useful in applied prognosis research.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="70.7">
<h2 data-number="70.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">70.7</span> How to read the figure carefully</h2>
<p>Nomograms are attractive because they simplify prediction, but that simplicity can hide model fragility. The figure does not validate the model. It only displays it. A poorly calibrated or poorly transported model can still produce a beautifully legible nomogram.</p>
<p>Three cautions matter most:</p>
<ol type="1">
<li>the plotted predictor ranges should match the population where the model is intended to be used;</li>
<li>the point system is only as credible as the underlying model specification and validation;</li>
<li>extrapolation beyond the plotted range is not justified simply because the figure looks smooth.</li>
</ol>
<p>In practice, a nomogram is most useful when it is paired with calibration, discrimination, and external-validation evidence rather than presented as a stand-alone predictive instrument.</p>
</section>
<section id="further-reading" class="level2" data-number="70.8">
<h2 data-number="70.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">70.8</span> Further reading</h2>
<p>Iasonos and colleagues provide one of the clearest practical discussions of how to build and interpret nomograms in prognostic research <span class="citation" data-cites="iasonos2008nomograms">Iasonos et al. (<a href="#ref-iasonos2008nomograms" role="doc-biblioref">2008</a>)</span>. For the broader graphics framework behind manually built static figures, Wickham remains the core reference <span class="citation" data-cites="wickham2016ggplot2">Wickham (<a href="#ref-wickham2016ggplot2" role="doc-biblioref">2016</a>)</span>. Readers who want to connect a nomogram to the wider evaluation of prediction models should read it together with the calibration material already included elsewhere in the book.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-iasonos2008nomograms" class="csl-entry" role="listitem">
Iasonos, Alexia, Deborah Schrag, Gopa Raj, and Katherine S. Panageas. 2008. <span>"How to Build and Interpret a Nomogram for Cancer Prognosis."</span> <em>Journal of Clinical Oncology</em> 26 (8): 1364-70. <a href="https://doi.org/10.1200/JCO.2007.12.9791">https://doi.org/10.1200/JCO.2007.12.9791</a>.
</div>
<div id="ref-wickham2016ggplot2" class="csl-entry" role="listitem">
Wickham, Hadley. 2016. <em>Ggplot2: Elegant Graphics for Data Analysis</em>. Second. New York: Springer.
</div>
</div>
</section>
