---
title: "Sankey Diagram for Care Pathways"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a Sankey-style care-pathway diagram, a figure used to show how patients or episodes flow from one stage to the next. In applied health research, many decisions depend not only on endpoint outcomes..."
---
<p>This chapter builds a Sankey-style care-pathway diagram, a figure used to show how patients or episodes flow from one stage to the next. In applied health research, many decisions depend not only on endpoint outcomes but also on how people move through the system: admission source, discharge destination, treatment assignment, recurrence, recovery, readmission, and death. A Sankey diagram turns those sequential transitions into a single visual object. Instead of reading a set of disconnected cross-tabulations, the reader can see how large each stream is and where the main losses, bottlenecks, or unfavorable pathways occur. Wickham's grammar-of-graphics perspective is useful here because the figure can be built from layered polygons, labels, and rectangles rather than as a black-box chart type <span class="citation" data-cites="wickham2016ggplot2">Wickham (<a href="#ref-wickham2016ggplot2" role="doc-biblioref">2016</a>)</span>. Brunson's work on alluvial graphics also clarifies why these flow diagrams are so effective for categorical transitions across stages <span class="citation" data-cites="brunson2020ggalluvial">Brunson (<a href="#ref-brunson2020ggalluvial" role="doc-biblioref">2020</a>)</span>.</p>
<p>The point of the figure is not merely to show counts. It is to show structure. A care pathway often contains several stages, and the substantive question is how patients redistribute as they move through them. A Sankey diagram is useful when the flow itself is the message.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="76.1">
<h2 data-number="76.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">76.1</span> What the visualization is showing</h2>
<p>We will build a three-stage Sankey diagram in which:</p>
<ol type="1">
<li>each column is a stage in the pathway,</li>
<li>each block is a category within that stage,</li>
<li>each ribbon links one category to the next,</li>
<li>ribbon width is proportional to the number of patients following that path.</li>
</ol>
<p>The key reading rule is straightforward. Read the figure from left to right. Thick ribbons indicate common pathways. Thin ribbons indicate uncommon ones. When many ribbons converge into one block, that block is receiving patients from multiple upstream routes. When a block sends flow into several downstream destinations, it indicates branching after that stage.</p>
</section>
<section id="step-1-create-a-synthetic-care-pathway-flow-table" class="level2" data-number="76.2">
<h2 data-number="76.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-care-pathway-flow-table"><span class="header-section-number">76.2</span> Step 1: Create a synthetic care-pathway flow table</h2>
<p>We begin with a synthetic hospital pathway for a transitional-care program. The stages are:</p>
<ol type="1">
<li>admission source,</li>
<li>discharge destination,</li>
<li>30-day outcome.</li>
</ol>
<p>This is a good use case for a Sankey diagram because the policy question is inherently sequential. The analyst wants to know not only how many patients are readmitted, but which upstream routes are most associated with those downstream outcomes.</p>
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
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>allocate_nodes <span class="ot">&lt;-</span> <span class="cf">function</span>(totals, order, gap) {</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  totals <span class="ot">&lt;-</span> totals <span class="sc">|&gt;</span></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mutate</span>(<span class="at">node =</span> <span class="fu">factor</span>(node, <span class="at">levels =</span> order)) <span class="sc">|&gt;</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>    <span class="fu">arrange</span>(node)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>  total_height <span class="ot">&lt;-</span> <span class="fu">sum</span>(totals<span class="sc">$</span>value) <span class="sc">+</span> gap <span class="sc">*</span> (<span class="fu">nrow</span>(totals) <span class="sc">-</span> <span class="dv">1</span>)</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>  current_top <span class="ot">&lt;-</span> total_height</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  totals<span class="sc">$</span>ymax <span class="ot">&lt;-</span> <span class="cn">NA_real_</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  totals<span class="sc">$</span>ymin <span class="ot">&lt;-</span> <span class="cn">NA_real_</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  <span class="cf">for</span> (i <span class="cf">in</span> <span class="fu">seq_len</span>(<span class="fu">nrow</span>(totals))) {</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>    totals<span class="sc">$</span>ymax[i] <span class="ot">&lt;-</span> current_top</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>    totals<span class="sc">$</span>ymin[i] <span class="ot">&lt;-</span> current_top <span class="sc">-</span> totals<span class="sc">$</span>value[i]</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>    current_top <span class="ot">&lt;-</span> totals<span class="sc">$</span>ymin[i] <span class="sc">-</span> gap</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>  totals<span class="sc">$</span>y <span class="ot">&lt;-</span> (totals<span class="sc">$</span>ymin <span class="sc">+</span> totals<span class="sc">$</span>ymax) <span class="sc">/</span> <span class="dv">2</span></span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>  totals</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>make_ribbon_polygon <span class="ot">&lt;-</span> <span class="cf">function</span>(x0, x1, y0_min, y0_max, y1_min, y1_max, fill_group, flow_id, <span class="at">n_points =</span> <span class="dv">60</span>) {</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>  t <span class="ot">&lt;-</span> <span class="fu">seq</span>(<span class="dv">0</span>, <span class="dv">1</span>, <span class="at">length.out =</span> n_points)</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>  s <span class="ot">&lt;-</span> <span class="dv">3</span> <span class="sc">*</span> t<span class="sc">^</span><span class="dv">2</span> <span class="sc">-</span> <span class="dv">2</span> <span class="sc">*</span> t<span class="sc">^</span><span class="dv">3</span></span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>  x <span class="ot">&lt;-</span> x0 <span class="sc">+</span> (x1 <span class="sc">-</span> x0) <span class="sc">*</span> t</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>  y_upper <span class="ot">&lt;-</span> y0_max <span class="sc">+</span> (y1_max <span class="sc">-</span> y0_max) <span class="sc">*</span> s</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>  y_lower <span class="ot">&lt;-</span> y0_min <span class="sc">+</span> (y1_min <span class="sc">-</span> y0_min) <span class="sc">*</span> s</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="fu">c</span>(x, <span class="fu">rev</span>(x)),</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="fu">c</span>(y_upper, <span class="fu">rev</span>(y_lower)),</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>    <span class="at">flow_fill =</span> fill_group,</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>    <span class="at">flow_id =</span> flow_id</span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>prepare_sankey_components <span class="ot">&lt;-</span> <span class="cf">function</span>(flows, stage_vars, stage_orders, stage_titles, middle_stage, <span class="at">gap =</span> <span class="dv">18</span>, <span class="at">node_width =</span> <span class="fl">0.52</span>) {</span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>  x_positions <span class="ot">&lt;-</span> <span class="fu">seq</span>(<span class="dv">0</span>, <span class="at">by =</span> <span class="dv">3</span>, <span class="at">length.out =</span> <span class="fu">length</span>(stage_vars))</span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>  node_data <span class="ot">&lt;-</span> <span class="fu">bind_rows</span>(<span class="fu">lapply</span>(<span class="fu">seq_along</span>(stage_vars), <span class="cf">function</span>(i) {</span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>    stage <span class="ot">&lt;-</span> stage_vars[i]</span>
<span id="cb1-52"><a href="#cb1-52" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-53"><a href="#cb1-53" aria-hidden="true" tabindex="-1"></a>    totals <span class="ot">&lt;-</span> flows <span class="sc">|&gt;</span></span>
<span id="cb1-54"><a href="#cb1-54" aria-hidden="true" tabindex="-1"></a>      <span class="fu">group_by</span>(<span class="at">node =</span> .data[[stage]]) <span class="sc">|&gt;</span></span>
<span id="cb1-55"><a href="#cb1-55" aria-hidden="true" tabindex="-1"></a>      <span class="fu">summarise</span>(<span class="at">value =</span> <span class="fu">sum</span>(n), <span class="at">.groups =</span> <span class="st">"drop"</span>)</span>
<span id="cb1-56"><a href="#cb1-56" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-57"><a href="#cb1-57" aria-hidden="true" tabindex="-1"></a>    layout <span class="ot">&lt;-</span> <span class="fu">allocate_nodes</span>(totals, <span class="at">order =</span> stage_orders[[stage]], <span class="at">gap =</span> gap)</span>
<span id="cb1-58"><a href="#cb1-58" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-59"><a href="#cb1-59" aria-hidden="true" tabindex="-1"></a>    layout <span class="sc">|&gt;</span></span>
<span id="cb1-60"><a href="#cb1-60" aria-hidden="true" tabindex="-1"></a>      <span class="fu">mutate</span>(</span>
<span id="cb1-61"><a href="#cb1-61" aria-hidden="true" tabindex="-1"></a>        <span class="at">stage =</span> stage,</span>
<span id="cb1-62"><a href="#cb1-62" aria-hidden="true" tabindex="-1"></a>        <span class="at">x =</span> x_positions[i],</span>
<span id="cb1-63"><a href="#cb1-63" aria-hidden="true" tabindex="-1"></a>        <span class="at">xmin =</span> x <span class="sc">-</span> node_width <span class="sc">/</span> <span class="dv">2</span>,</span>
<span id="cb1-64"><a href="#cb1-64" aria-hidden="true" tabindex="-1"></a>        <span class="at">xmax =</span> x <span class="sc">+</span> node_width <span class="sc">/</span> <span class="dv">2</span></span>
<span id="cb1-65"><a href="#cb1-65" aria-hidden="true" tabindex="-1"></a>      )</span>
<span id="cb1-66"><a href="#cb1-66" aria-hidden="true" tabindex="-1"></a>  }))</span>
<span id="cb1-67"><a href="#cb1-67" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-68"><a href="#cb1-68" aria-hidden="true" tabindex="-1"></a>  ribbon_list <span class="ot">&lt;-</span> <span class="fu">lapply</span>(<span class="fu">seq_len</span>(<span class="fu">length</span>(stage_vars) <span class="sc">-</span> <span class="dv">1</span>), <span class="cf">function</span>(i) {</span>
<span id="cb1-69"><a href="#cb1-69" aria-hidden="true" tabindex="-1"></a>    source_stage <span class="ot">&lt;-</span> stage_vars[i]</span>
<span id="cb1-70"><a href="#cb1-70" aria-hidden="true" tabindex="-1"></a>    target_stage <span class="ot">&lt;-</span> stage_vars[i <span class="sc">+</span> <span class="dv">1</span>]</span>
<span id="cb1-71"><a href="#cb1-71" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-72"><a href="#cb1-72" aria-hidden="true" tabindex="-1"></a>    pair_flows <span class="ot">&lt;-</span> flows <span class="sc">|&gt;</span></span>
<span id="cb1-73"><a href="#cb1-73" aria-hidden="true" tabindex="-1"></a>      <span class="fu">group_by</span>(</span>
<span id="cb1-74"><a href="#cb1-74" aria-hidden="true" tabindex="-1"></a>        <span class="at">source =</span> .data[[source_stage]],</span>
<span id="cb1-75"><a href="#cb1-75" aria-hidden="true" tabindex="-1"></a>        <span class="at">target =</span> .data[[target_stage]],</span>
<span id="cb1-76"><a href="#cb1-76" aria-hidden="true" tabindex="-1"></a>        <span class="at">flow_fill =</span> .data[[middle_stage]]</span>
<span id="cb1-77"><a href="#cb1-77" aria-hidden="true" tabindex="-1"></a>      ) <span class="sc">|&gt;</span></span>
<span id="cb1-78"><a href="#cb1-78" aria-hidden="true" tabindex="-1"></a>      <span class="fu">summarise</span>(<span class="at">n =</span> <span class="fu">sum</span>(n), <span class="at">.groups =</span> <span class="st">"drop"</span>)</span>
<span id="cb1-79"><a href="#cb1-79" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-80"><a href="#cb1-80" aria-hidden="true" tabindex="-1"></a>    source_bounds <span class="ot">&lt;-</span> node_data <span class="sc">|&gt;</span></span>
<span id="cb1-81"><a href="#cb1-81" aria-hidden="true" tabindex="-1"></a>      <span class="fu">filter</span>(stage <span class="sc">==</span> source_stage) <span class="sc">|&gt;</span></span>
<span id="cb1-82"><a href="#cb1-82" aria-hidden="true" tabindex="-1"></a>      <span class="fu">select</span>(<span class="at">source =</span> node, <span class="at">source_x =</span> x, <span class="at">source_ymin =</span> ymin, <span class="at">source_ymax =</span> ymax)</span>
<span id="cb1-83"><a href="#cb1-83" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-84"><a href="#cb1-84" aria-hidden="true" tabindex="-1"></a>    target_bounds <span class="ot">&lt;-</span> node_data <span class="sc">|&gt;</span></span>
<span id="cb1-85"><a href="#cb1-85" aria-hidden="true" tabindex="-1"></a>      <span class="fu">filter</span>(stage <span class="sc">==</span> target_stage) <span class="sc">|&gt;</span></span>
<span id="cb1-86"><a href="#cb1-86" aria-hidden="true" tabindex="-1"></a>      <span class="fu">select</span>(<span class="at">target =</span> node, <span class="at">target_x =</span> x, <span class="at">target_ymin =</span> ymin, <span class="at">target_ymax =</span> ymax)</span>
<span id="cb1-87"><a href="#cb1-87" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-88"><a href="#cb1-88" aria-hidden="true" tabindex="-1"></a>    source_segments <span class="ot">&lt;-</span> pair_flows <span class="sc">|&gt;</span></span>
<span id="cb1-89"><a href="#cb1-89" aria-hidden="true" tabindex="-1"></a>      <span class="fu">mutate</span>(</span>
<span id="cb1-90"><a href="#cb1-90" aria-hidden="true" tabindex="-1"></a>        <span class="at">source =</span> <span class="fu">factor</span>(source, <span class="at">levels =</span> stage_orders[[source_stage]]),</span>
<span id="cb1-91"><a href="#cb1-91" aria-hidden="true" tabindex="-1"></a>        <span class="at">target =</span> <span class="fu">factor</span>(target, <span class="at">levels =</span> stage_orders[[target_stage]])</span>
<span id="cb1-92"><a href="#cb1-92" aria-hidden="true" tabindex="-1"></a>      ) <span class="sc">|&gt;</span></span>
<span id="cb1-93"><a href="#cb1-93" aria-hidden="true" tabindex="-1"></a>      <span class="fu">arrange</span>(source, target) <span class="sc">|&gt;</span></span>
<span id="cb1-94"><a href="#cb1-94" aria-hidden="true" tabindex="-1"></a>      <span class="fu">left_join</span>(source_bounds, <span class="at">by =</span> <span class="st">"source"</span>) <span class="sc">|&gt;</span></span>
<span id="cb1-95"><a href="#cb1-95" aria-hidden="true" tabindex="-1"></a>      <span class="fu">group_by</span>(source) <span class="sc">|&gt;</span></span>
<span id="cb1-96"><a href="#cb1-96" aria-hidden="true" tabindex="-1"></a>      <span class="fu">mutate</span>(</span>
<span id="cb1-97"><a href="#cb1-97" aria-hidden="true" tabindex="-1"></a>        <span class="at">seg_source_ymax =</span> source_ymax <span class="sc">-</span> <span class="fu">lag</span>(<span class="fu">cumsum</span>(n), <span class="at">default =</span> <span class="dv">0</span>),</span>
<span id="cb1-98"><a href="#cb1-98" aria-hidden="true" tabindex="-1"></a>        <span class="at">seg_source_ymin =</span> seg_source_ymax <span class="sc">-</span> n</span>
<span id="cb1-99"><a href="#cb1-99" aria-hidden="true" tabindex="-1"></a>      ) <span class="sc">|&gt;</span></span>
<span id="cb1-100"><a href="#cb1-100" aria-hidden="true" tabindex="-1"></a>      <span class="fu">ungroup</span>()</span>
<span id="cb1-101"><a href="#cb1-101" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-102"><a href="#cb1-102" aria-hidden="true" tabindex="-1"></a>    target_segments <span class="ot">&lt;-</span> pair_flows <span class="sc">|&gt;</span></span>
<span id="cb1-103"><a href="#cb1-103" aria-hidden="true" tabindex="-1"></a>      <span class="fu">mutate</span>(</span>
<span id="cb1-104"><a href="#cb1-104" aria-hidden="true" tabindex="-1"></a>        <span class="at">source =</span> <span class="fu">factor</span>(source, <span class="at">levels =</span> stage_orders[[source_stage]]),</span>
<span id="cb1-105"><a href="#cb1-105" aria-hidden="true" tabindex="-1"></a>        <span class="at">target =</span> <span class="fu">factor</span>(target, <span class="at">levels =</span> stage_orders[[target_stage]])</span>
<span id="cb1-106"><a href="#cb1-106" aria-hidden="true" tabindex="-1"></a>      ) <span class="sc">|&gt;</span></span>
<span id="cb1-107"><a href="#cb1-107" aria-hidden="true" tabindex="-1"></a>      <span class="fu">arrange</span>(target, source) <span class="sc">|&gt;</span></span>
<span id="cb1-108"><a href="#cb1-108" aria-hidden="true" tabindex="-1"></a>      <span class="fu">left_join</span>(target_bounds, <span class="at">by =</span> <span class="st">"target"</span>) <span class="sc">|&gt;</span></span>
<span id="cb1-109"><a href="#cb1-109" aria-hidden="true" tabindex="-1"></a>      <span class="fu">group_by</span>(target) <span class="sc">|&gt;</span></span>
<span id="cb1-110"><a href="#cb1-110" aria-hidden="true" tabindex="-1"></a>      <span class="fu">mutate</span>(</span>
<span id="cb1-111"><a href="#cb1-111" aria-hidden="true" tabindex="-1"></a>        <span class="at">seg_target_ymax =</span> target_ymax <span class="sc">-</span> <span class="fu">lag</span>(<span class="fu">cumsum</span>(n), <span class="at">default =</span> <span class="dv">0</span>),</span>
<span id="cb1-112"><a href="#cb1-112" aria-hidden="true" tabindex="-1"></a>        <span class="at">seg_target_ymin =</span> seg_target_ymax <span class="sc">-</span> n</span>
<span id="cb1-113"><a href="#cb1-113" aria-hidden="true" tabindex="-1"></a>      ) <span class="sc">|&gt;</span></span>
<span id="cb1-114"><a href="#cb1-114" aria-hidden="true" tabindex="-1"></a>      <span class="fu">ungroup</span>()</span>
<span id="cb1-115"><a href="#cb1-115" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-116"><a href="#cb1-116" aria-hidden="true" tabindex="-1"></a>    segment_data <span class="ot">&lt;-</span> source_segments <span class="sc">|&gt;</span></span>
<span id="cb1-117"><a href="#cb1-117" aria-hidden="true" tabindex="-1"></a>      <span class="fu">select</span>(source, target, flow_fill, n, source_x, seg_source_ymin, seg_source_ymax) <span class="sc">|&gt;</span></span>
<span id="cb1-118"><a href="#cb1-118" aria-hidden="true" tabindex="-1"></a>      <span class="fu">left_join</span>(</span>
<span id="cb1-119"><a href="#cb1-119" aria-hidden="true" tabindex="-1"></a>        target_segments <span class="sc">|&gt;</span></span>
<span id="cb1-120"><a href="#cb1-120" aria-hidden="true" tabindex="-1"></a>          <span class="fu">select</span>(source, target, flow_fill, n, target_x, seg_target_ymin, seg_target_ymax),</span>
<span id="cb1-121"><a href="#cb1-121" aria-hidden="true" tabindex="-1"></a>        <span class="at">by =</span> <span class="fu">c</span>(<span class="st">"source"</span>, <span class="st">"target"</span>, <span class="st">"flow_fill"</span>, <span class="st">"n"</span>)</span>
<span id="cb1-122"><a href="#cb1-122" aria-hidden="true" tabindex="-1"></a>      )</span>
<span id="cb1-123"><a href="#cb1-123" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-124"><a href="#cb1-124" aria-hidden="true" tabindex="-1"></a>    <span class="fu">bind_rows</span>(<span class="fu">lapply</span>(<span class="fu">seq_len</span>(<span class="fu">nrow</span>(segment_data)), <span class="cf">function</span>(j) {</span>
<span id="cb1-125"><a href="#cb1-125" aria-hidden="true" tabindex="-1"></a>      <span class="fu">make_ribbon_polygon</span>(</span>
<span id="cb1-126"><a href="#cb1-126" aria-hidden="true" tabindex="-1"></a>        <span class="at">x0 =</span> segment_data<span class="sc">$</span>source_x[j] <span class="sc">+</span> node_width <span class="sc">/</span> <span class="dv">2</span>,</span>
<span id="cb1-127"><a href="#cb1-127" aria-hidden="true" tabindex="-1"></a>        <span class="at">x1 =</span> segment_data<span class="sc">$</span>target_x[j] <span class="sc">-</span> node_width <span class="sc">/</span> <span class="dv">2</span>,</span>
<span id="cb1-128"><a href="#cb1-128" aria-hidden="true" tabindex="-1"></a>        <span class="at">y0_min =</span> segment_data<span class="sc">$</span>seg_source_ymin[j],</span>
<span id="cb1-129"><a href="#cb1-129" aria-hidden="true" tabindex="-1"></a>        <span class="at">y0_max =</span> segment_data<span class="sc">$</span>seg_source_ymax[j],</span>
<span id="cb1-130"><a href="#cb1-130" aria-hidden="true" tabindex="-1"></a>        <span class="at">y1_min =</span> segment_data<span class="sc">$</span>seg_target_ymin[j],</span>
<span id="cb1-131"><a href="#cb1-131" aria-hidden="true" tabindex="-1"></a>        <span class="at">y1_max =</span> segment_data<span class="sc">$</span>seg_target_ymax[j],</span>
<span id="cb1-132"><a href="#cb1-132" aria-hidden="true" tabindex="-1"></a>        <span class="at">fill_group =</span> <span class="fu">as.character</span>(segment_data<span class="sc">$</span>flow_fill[j]),</span>
<span id="cb1-133"><a href="#cb1-133" aria-hidden="true" tabindex="-1"></a>        <span class="at">flow_id =</span> <span class="fu">paste</span>(source_stage, target_stage, j, <span class="at">sep =</span> <span class="st">"_"</span>)</span>
<span id="cb1-134"><a href="#cb1-134" aria-hidden="true" tabindex="-1"></a>      )</span>
<span id="cb1-135"><a href="#cb1-135" aria-hidden="true" tabindex="-1"></a>    }))</span>
<span id="cb1-136"><a href="#cb1-136" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb1-137"><a href="#cb1-137" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-138"><a href="#cb1-138" aria-hidden="true" tabindex="-1"></a>  stage_labels <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-139"><a href="#cb1-139" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> x_positions,</span>
<span id="cb1-140"><a href="#cb1-140" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="fu">max</span>(node_data<span class="sc">$</span>ymax) <span class="sc">+</span> gap <span class="sc">*</span> <span class="fl">0.9</span>,</span>
<span id="cb1-141"><a href="#cb1-141" aria-hidden="true" tabindex="-1"></a>    <span class="at">label =</span> stage_titles</span>
<span id="cb1-142"><a href="#cb1-142" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-143"><a href="#cb1-143" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-144"><a href="#cb1-144" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(</span>
<span id="cb1-145"><a href="#cb1-145" aria-hidden="true" tabindex="-1"></a>    <span class="at">nodes =</span> node_data,</span>
<span id="cb1-146"><a href="#cb1-146" aria-hidden="true" tabindex="-1"></a>    <span class="at">ribbons =</span> <span class="fu">bind_rows</span>(ribbon_list),</span>
<span id="cb1-147"><a href="#cb1-147" aria-hidden="true" tabindex="-1"></a>    <span class="at">stage_labels =</span> stage_labels,</span>
<span id="cb1-148"><a href="#cb1-148" aria-hidden="true" tabindex="-1"></a>    <span class="at">plot_ymax =</span> stage_labels<span class="sc">$</span>y[<span class="dv">1</span>] <span class="sc">+</span> gap <span class="sc">*</span> <span class="fl">0.6</span></span>
<span id="cb1-149"><a href="#cb1-149" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-150"><a href="#cb1-150" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-151"><a href="#cb1-151" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-152"><a href="#cb1-152" aria-hidden="true" tabindex="-1"></a>draw_sankey_plot <span class="ot">&lt;-</span> <span class="cf">function</span>(components, fill_palette, title, subtitle) {</span>
<span id="cb1-153"><a href="#cb1-153" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>() <span class="sc">+</span></span>
<span id="cb1-154"><a href="#cb1-154" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_polygon</span>(</span>
<span id="cb1-155"><a href="#cb1-155" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> components<span class="sc">$</span>ribbons,</span>
<span id="cb1-156"><a href="#cb1-156" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">group =</span> flow_id, <span class="at">fill =</span> flow_fill),</span>
<span id="cb1-157"><a href="#cb1-157" aria-hidden="true" tabindex="-1"></a>      <span class="at">alpha =</span> <span class="fl">0.78</span>,</span>
<span id="cb1-158"><a href="#cb1-158" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="cn">NA</span></span>
<span id="cb1-159"><a href="#cb1-159" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-160"><a href="#cb1-160" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_rect</span>(</span>
<span id="cb1-161"><a href="#cb1-161" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> components<span class="sc">$</span>nodes,</span>
<span id="cb1-162"><a href="#cb1-162" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">xmin =</span> xmin, <span class="at">xmax =</span> xmax, <span class="at">ymin =</span> ymin, <span class="at">ymax =</span> ymax),</span>
<span id="cb1-163"><a href="#cb1-163" aria-hidden="true" tabindex="-1"></a>      <span class="at">inherit.aes =</span> <span class="cn">FALSE</span>,</span>
<span id="cb1-164"><a href="#cb1-164" aria-hidden="true" tabindex="-1"></a>      <span class="at">fill =</span> <span class="st">"#f7f7f7"</span>,</span>
<span id="cb1-165"><a href="#cb1-165" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#4d4d4d"</span>,</span>
<span id="cb1-166"><a href="#cb1-166" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.35</span></span>
<span id="cb1-167"><a href="#cb1-167" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-168"><a href="#cb1-168" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-169"><a href="#cb1-169" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> components<span class="sc">$</span>nodes,</span>
<span id="cb1-170"><a href="#cb1-170" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">label =</span> node),</span>
<span id="cb1-171"><a href="#cb1-171" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.0</span>,</span>
<span id="cb1-172"><a href="#cb1-172" aria-hidden="true" tabindex="-1"></a>      <span class="at">lineheight =</span> <span class="fl">0.92</span></span>
<span id="cb1-173"><a href="#cb1-173" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-174"><a href="#cb1-174" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-175"><a href="#cb1-175" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> components<span class="sc">$</span>stage_labels,</span>
<span id="cb1-176"><a href="#cb1-176" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">label =</span> label),</span>
<span id="cb1-177"><a href="#cb1-177" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.8</span>,</span>
<span id="cb1-178"><a href="#cb1-178" aria-hidden="true" tabindex="-1"></a>      <span class="at">fontface =</span> <span class="st">"bold"</span></span>
<span id="cb1-179"><a href="#cb1-179" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-180"><a href="#cb1-180" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_fill_manual</span>(<span class="at">values =</span> fill_palette, <span class="at">name =</span> <span class="cn">NULL</span>) <span class="sc">+</span></span>
<span id="cb1-181"><a href="#cb1-181" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coord_cartesian</span>(</span>
<span id="cb1-182"><a href="#cb1-182" aria-hidden="true" tabindex="-1"></a>      <span class="at">xlim =</span> <span class="fu">c</span>(<span class="fu">min</span>(components<span class="sc">$</span>stage_labels<span class="sc">$</span>x) <span class="sc">-</span> <span class="fl">1.0</span>, <span class="fu">max</span>(components<span class="sc">$</span>stage_labels<span class="sc">$</span>x) <span class="sc">+</span> <span class="fl">1.0</span>),</span>
<span id="cb1-183"><a href="#cb1-183" aria-hidden="true" tabindex="-1"></a>      <span class="at">ylim =</span> <span class="fu">c</span>(<span class="dv">0</span>, components<span class="sc">$</span>plot_ymax),</span>
<span id="cb1-184"><a href="#cb1-184" aria-hidden="true" tabindex="-1"></a>      <span class="at">clip =</span> <span class="st">"off"</span></span>
<span id="cb1-185"><a href="#cb1-185" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-186"><a href="#cb1-186" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb1-187"><a href="#cb1-187" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb1-188"><a href="#cb1-188" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle</span>
<span id="cb1-189"><a href="#cb1-189" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-190"><a href="#cb1-190" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_void</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb1-191"><a href="#cb1-191" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb1-192"><a href="#cb1-192" aria-hidden="true" tabindex="-1"></a>      <span class="at">legend.position =</span> <span class="st">"bottom"</span>,</span>
<span id="cb1-193"><a href="#cb1-193" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.title =</span> <span class="fu">element_text</span>(<span class="at">face =</span> <span class="st">"bold"</span>, <span class="at">size =</span> <span class="dv">13</span>),</span>
<span id="cb1-194"><a href="#cb1-194" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.subtitle =</span> <span class="fu">element_text</span>(<span class="at">size =</span> <span class="dv">10</span>, <span class="at">color =</span> <span class="st">"#4d4d4d"</span>),</span>
<span id="cb1-195"><a href="#cb1-195" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.margin =</span> <span class="fu">margin</span>(<span class="dv">10</span>, <span class="dv">10</span>, <span class="dv">12</span>, <span class="dv">10</span>)</span>
<span id="cb1-196"><a href="#cb1-196" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-197"><a href="#cb1-197" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>synthetic_flow_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">admission_source =</span> <span class="fu">c</span>(</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Emergency</span><span class="sc">\n</span><span class="st">department"</span>, <span class="dv">9</span>),</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Primary care</span><span class="sc">\n</span><span class="st">referral"</span>, <span class="dv">6</span>),</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Post-surgical</span><span class="sc">\n</span><span class="st">observation"</span>, <span class="dv">9</span>)</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">discharge_destination =</span> <span class="fu">c</span>(</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Home"</span>, <span class="dv">3</span>),</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Home with</span><span class="sc">\n</span><span class="st">nursing"</span>, <span class="dv">3</span>),</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Rehabilitation"</span>, <span class="dv">3</span>),</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Home"</span>, <span class="dv">3</span>),</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Home with</span><span class="sc">\n</span><span class="st">nursing"</span>, <span class="dv">3</span>),</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Home"</span>, <span class="dv">3</span>),</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Home with</span><span class="sc">\n</span><span class="st">nursing"</span>, <span class="dv">3</span>),</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>    <span class="fu">rep</span>(<span class="st">"Rehabilitation"</span>, <span class="dv">3</span>)</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">outcome_30d =</span> <span class="fu">rep</span>(</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>    <span class="fu">c</span>(<span class="st">"No</span><span class="sc">\n</span><span class="st">readmission"</span>, <span class="st">"Readmitted"</span>, <span class="st">"Died"</span>),</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">times =</span> <span class="dv">8</span></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">n =</span> <span class="fu">c</span>(</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>    <span class="dv">180</span>, <span class="dv">55</span>, <span class="dv">5</span>,</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>    <span class="dv">70</span>, <span class="dv">35</span>, <span class="dv">10</span>,</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>    <span class="dv">25</span>, <span class="dv">22</span>, <span class="dv">8</span>,</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>    <span class="dv">150</span>, <span class="dv">18</span>, <span class="dv">2</span>,</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>    <span class="dv">45</span>, <span class="dv">10</span>, <span class="dv">3</span>,</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>    <span class="dv">120</span>, <span class="dv">20</span>, <span class="dv">3</span>,</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>    <span class="dv">38</span>, <span class="dv">12</span>, <span class="dv">4</span>,</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>    <span class="dv">25</span>, <span class="dv">8</span>, <span class="dv">3</span></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> synthetic_flow_table <span class="sc">|&gt;</span></span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">admission_source =</span> <span class="fu">gsub</span>(<span class="st">"</span><span class="sc">\n</span><span class="st">"</span>, <span class="st">" "</span>, admission_source),</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>    <span class="at">discharge_destination =</span> <span class="fu">gsub</span>(<span class="st">"</span><span class="sc">\n</span><span class="st">"</span>, <span class="st">" "</span>, discharge_destination),</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>    <span class="at">outcome_30d =</span> <span class="fu">gsub</span>(<span class="st">"</span><span class="sc">\n</span><span class="st">"</span>, <span class="st">" "</span>, outcome_30d)</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(n)) <span class="sc">|&gt;</span></span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>  <span class="fu">slice_head</span>(<span class="at">n =</span> <span class="dv">10</span>)</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_summary, <span class="at">digits =</span> <span class="dv">0</span>),</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Largest synthetic care pathways that will appear in the Sankey diagram"</span></span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Largest synthetic care pathways that will appear in the Sankey diagram</caption>
<thead>
<tr class="header">
<th style="text-align: left;">admission_source</th>
<th style="text-align: left;">discharge_destination</th>
<th style="text-align: left;">outcome_30d</th>
<th style="text-align: right;">n</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Emergency department</td>
<td style="text-align: left;">Home</td>
<td style="text-align: left;">No readmission</td>
<td style="text-align: right;">180</td>
</tr>
<tr class="even">
<td style="text-align: left;">Primary care referral</td>
<td style="text-align: left;">Home</td>
<td style="text-align: left;">No readmission</td>
<td style="text-align: right;">150</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Post-surgical observation</td>
<td style="text-align: left;">Home</td>
<td style="text-align: left;">No readmission</td>
<td style="text-align: right;">120</td>
</tr>
<tr class="even">
<td style="text-align: left;">Emergency department</td>
<td style="text-align: left;">Home with nursing</td>
<td style="text-align: left;">No readmission</td>
<td style="text-align: right;">70</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Emergency department</td>
<td style="text-align: left;">Home</td>
<td style="text-align: left;">Readmitted</td>
<td style="text-align: right;">55</td>
</tr>
<tr class="even">
<td style="text-align: left;">Primary care referral</td>
<td style="text-align: left;">Home with nursing</td>
<td style="text-align: left;">No readmission</td>
<td style="text-align: right;">45</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Post-surgical observation</td>
<td style="text-align: left;">Home with nursing</td>
<td style="text-align: left;">No readmission</td>
<td style="text-align: right;">38</td>
</tr>
<tr class="even">
<td style="text-align: left;">Emergency department</td>
<td style="text-align: left;">Home with nursing</td>
<td style="text-align: left;">Readmitted</td>
<td style="text-align: right;">35</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Emergency department</td>
<td style="text-align: left;">Rehabilitation</td>
<td style="text-align: left;">No readmission</td>
<td style="text-align: right;">25</td>
</tr>
<tr class="even">
<td style="text-align: left;">Post-surgical observation</td>
<td style="text-align: left;">Rehabilitation</td>
<td style="text-align: left;">No readmission</td>
<td style="text-align: right;">25</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The synthetic table already contains the full pathway information, but it is hard to see the structure by inspection alone. The Sankey diagram will make the dominant routes immediately visible.</p>
</section>
<section id="step-2-build-a-reusable-static-sankey-diagram" class="level2" data-number="76.3">
<h2 data-number="76.3" class="anchored" data-anchor-id="step-2-build-a-reusable-static-sankey-diagram"><span class="header-section-number">76.3</span> Step 2: Build a reusable static Sankey diagram</h2>
<p>The functions above build the figure from two ingredients:</p>
<ol type="1">
<li>node rectangles, which define the categories at each stage,</li>
<li>ribbon polygons, which connect one stage to the next with widths proportional to counts.</li>
</ol>
<p>This is useful because it keeps the figure entirely reproducible in static <code>ggplot2</code> code. The diagram is therefore suitable for Quarto output, PDF export, and academic documents that need a non-interactive figure.</p>
</section>
<section id="step-3-draw-the-synthetic-sankey-diagram" class="level2" data-number="76.4">
<h2 data-number="76.4" class="anchored" data-anchor-id="step-3-draw-the-synthetic-sankey-diagram"><span class="header-section-number">76.4</span> Step 3: Draw the synthetic Sankey diagram</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>synthetic_stage_orders <span class="ot">&lt;-</span> <span class="fu">list</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">admission_source =</span> <span class="fu">c</span>(</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Emergency</span><span class="sc">\n</span><span class="st">department"</span>,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Primary care</span><span class="sc">\n</span><span class="st">referral"</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Post-surgical</span><span class="sc">\n</span><span class="st">observation"</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">discharge_destination =</span> <span class="fu">c</span>(</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Home"</span>,</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Home with</span><span class="sc">\n</span><span class="st">nursing"</span>,</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Rehabilitation"</span></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">outcome_30d =</span> <span class="fu">c</span>(</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>    <span class="st">"No</span><span class="sc">\n</span><span class="st">readmission"</span>,</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Readmitted"</span>,</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Died"</span></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>synthetic_components <span class="ot">&lt;-</span> <span class="fu">prepare_sankey_components</span>(</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">flows =</span> synthetic_flow_table,</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">stage_vars =</span> <span class="fu">c</span>(<span class="st">"admission_source"</span>, <span class="st">"discharge_destination"</span>, <span class="st">"outcome_30d"</span>),</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">stage_orders =</span> synthetic_stage_orders,</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">stage_titles =</span> <span class="fu">c</span>(<span class="st">"Admission source"</span>, <span class="st">"Discharge destination"</span>, <span class="st">"30-day outcome"</span>),</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">middle_stage =</span> <span class="st">"discharge_destination"</span>,</span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">gap =</span> <span class="dv">18</span></span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>synthetic_palette <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb3-29"><a href="#cb3-29" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Home"</span> <span class="ot">=</span> <span class="st">"#7fc97f"</span>,</span>
<span id="cb3-30"><a href="#cb3-30" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Home with</span><span class="sc">\n</span><span class="st">nursing"</span> <span class="ot">=</span> <span class="st">"#fdc086"</span>,</span>
<span id="cb3-31"><a href="#cb3-31" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Rehabilitation"</span> <span class="ot">=</span> <span class="st">"#beaed4"</span></span>
<span id="cb3-32"><a href="#cb3-32" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-33"><a href="#cb3-33" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-34"><a href="#cb3-34" aria-hidden="true" tabindex="-1"></a>synthetic_sankey <span class="ot">&lt;-</span> <span class="fu">draw_sankey_plot</span>(</span>
<span id="cb3-35"><a href="#cb3-35" aria-hidden="true" tabindex="-1"></a>  synthetic_components,</span>
<span id="cb3-36"><a href="#cb3-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">fill_palette =</span> synthetic_palette,</span>
<span id="cb3-37"><a href="#cb3-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"A Sankey diagram shows how patients redistribute across a care pathway"</span>,</span>
<span id="cb3-38"><a href="#cb3-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Synthetic hospital pathway from admission source to discharge destination to 30-day outcome"</span></span>
<span id="cb3-39"><a href="#cb3-39" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-40"><a href="#cb3-40" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-41"><a href="#cb3-41" aria-hidden="true" tabindex="-1"></a>synthetic_sankey</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/sankey-diagram-care-pathways_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure is useful because it answers several questions at once:</p>
<ol type="1">
<li>which admission source contributes the most patients,</li>
<li>which discharge destination receives most of them,</li>
<li>where the main readmission and death streams originate.</li>
</ol>
<p>The eye can follow the wide ribbons first. That is often enough to identify the dominant operational story before moving to precise counts.</p>
</section>
<section id="step-4-create-a-real-world-pathway-diagram-from-the-public-colon-trial-data" class="level2" data-number="76.5">
<h2 data-number="76.5" class="anchored" data-anchor-id="step-4-create-a-real-world-pathway-diagram-from-the-public-colon-trial-data"><span class="header-section-number">76.5</span> Step 4: Create a real-world pathway diagram from the public colon trial data</h2>
<p>For a real-world example, we use the public <code>colon</code> dataset distributed with <code>survival</code>, linked to the adjuvant colon cancer trials reported by Laurie and colleagues and Moertel and colleagues <span class="citation" data-cites="laurie1989">Laurie et al. (<a href="#ref-laurie1989" role="doc-biblioref">1989</a>)</span>; <span class="citation" data-cites="moertel1990">Moertel et al. (<a href="#ref-moertel1990" role="doc-biblioref">1990</a>)</span>. The original trial papers were not published as Sankey diagrams, so this is a transparent partial application. We use the public patient-level trial data to build a pathway figure with:</p>
<ol type="1">
<li>treatment arm,</li>
<li>recurrence status by 3 years,</li>
<li>survival status by 5 years.</li>
</ol>
<p>To keep the pathway definition interpretable, we restrict attention to patients whose recurrence-by-3-years and survival-by-5-years status can be determined from the public follow-up information. That makes the application partial but transparent.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(survival)</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>colon_patient <span class="ot">&lt;-</span> survival<span class="sc">::</span>colon <span class="sc">|&gt;</span></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">group_by</span>(id, rx) <span class="sc">|&gt;</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">summarise</span>(</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">recurrence_time =</span> time[etype <span class="sc">==</span> <span class="dv">1</span>][<span class="dv">1</span>],</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">recurrence_status =</span> status[etype <span class="sc">==</span> <span class="dv">1</span>][<span class="dv">1</span>],</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">death_time =</span> time[etype <span class="sc">==</span> <span class="dv">2</span>][<span class="dv">1</span>],</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">death_status =</span> status[etype <span class="sc">==</span> <span class="dv">2</span>][<span class="dv">1</span>],</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">.groups =</span> <span class="st">"drop"</span></span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">recurrence_3y =</span> <span class="fu">ifelse</span>(</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>      recurrence_status <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> recurrence_time <span class="sc">&lt;=</span> <span class="dv">1095</span>,</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Recurrence</span><span class="sc">\n</span><span class="st">by 3 years"</span>,</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>      <span class="fu">ifelse</span>(recurrence_time <span class="sc">&gt;=</span> <span class="dv">1095</span>, <span class="st">"No recurrence</span><span class="sc">\n</span><span class="st">by 3 years"</span>, <span class="cn">NA</span>)</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>    ),</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">survival_5y =</span> <span class="fu">ifelse</span>(</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>      death_status <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> death_time <span class="sc">&lt;=</span> <span class="dv">1825</span>,</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Died by</span><span class="sc">\n</span><span class="st">5 years"</span>,</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>      <span class="fu">ifelse</span>(death_time <span class="sc">&gt;=</span> <span class="dv">1825</span>, <span class="st">"Alive at</span><span class="sc">\n</span><span class="st">5 years"</span>, <span class="cn">NA</span>)</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>    ),</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">treatment_arm =</span> dplyr<span class="sc">::</span><span class="fu">recode</span>(</span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>      <span class="fu">as.character</span>(rx),</span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Obs"</span> <span class="ot">=</span> <span class="st">"Observation"</span>,</span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Lev"</span> <span class="ot">=</span> <span class="st">"Levamisole"</span>,</span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>      <span class="st">"Lev+5FU"</span> <span class="ot">=</span> <span class="st">"Levamisole</span><span class="sc">\n</span><span class="st">+ 5FU"</span></span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb4-30"><a href="#cb4-30" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(<span class="sc">!</span><span class="fu">is.na</span>(recurrence_3y), <span class="sc">!</span><span class="fu">is.na</span>(survival_5y))</span>
<span id="cb4-31"><a href="#cb4-31" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-32"><a href="#cb4-32" aria-hidden="true" tabindex="-1"></a>colon_pathways <span class="ot">&lt;-</span> colon_patient <span class="sc">|&gt;</span></span>
<span id="cb4-33"><a href="#cb4-33" aria-hidden="true" tabindex="-1"></a>  <span class="fu">count</span>(treatment_arm, recurrence_3y, survival_5y, <span class="at">name =</span> <span class="st">"n"</span>)</span>
<span id="cb4-34"><a href="#cb4-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-35"><a href="#cb4-35" aria-hidden="true" tabindex="-1"></a>colon_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-36"><a href="#cb4-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(colon_patient),</span>
<span id="cb4-37"><a href="#cb4-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">observation =</span> <span class="fu">sum</span>(colon_patient<span class="sc">$</span>treatment_arm <span class="sc">==</span> <span class="st">"Observation"</span>),</span>
<span id="cb4-38"><a href="#cb4-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">levamisole =</span> <span class="fu">sum</span>(colon_patient<span class="sc">$</span>treatment_arm <span class="sc">==</span> <span class="st">"Levamisole"</span>),</span>
<span id="cb4-39"><a href="#cb4-39" aria-hidden="true" tabindex="-1"></a>  <span class="at">levamisole_5fu =</span> <span class="fu">sum</span>(colon_patient<span class="sc">$</span>treatment_arm <span class="sc">==</span> <span class="st">"Levamisole</span><span class="sc">\n</span><span class="st">+ 5FU"</span>)</span>
<span id="cb4-40"><a href="#cb4-40" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-41"><a href="#cb4-41" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-42"><a href="#cb4-42" aria-hidden="true" tabindex="-1"></a>colon_top_paths <span class="ot">&lt;-</span> colon_pathways <span class="sc">|&gt;</span></span>
<span id="cb4-43"><a href="#cb4-43" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb4-44"><a href="#cb4-44" aria-hidden="true" tabindex="-1"></a>    <span class="at">treatment_arm =</span> <span class="fu">gsub</span>(<span class="st">"</span><span class="sc">\n</span><span class="st">"</span>, <span class="st">" "</span>, treatment_arm),</span>
<span id="cb4-45"><a href="#cb4-45" aria-hidden="true" tabindex="-1"></a>    <span class="at">recurrence_3y =</span> <span class="fu">gsub</span>(<span class="st">"</span><span class="sc">\n</span><span class="st">"</span>, <span class="st">" "</span>, recurrence_3y),</span>
<span id="cb4-46"><a href="#cb4-46" aria-hidden="true" tabindex="-1"></a>    <span class="at">survival_5y =</span> <span class="fu">gsub</span>(<span class="st">"</span><span class="sc">\n</span><span class="st">"</span>, <span class="st">" "</span>, survival_5y)</span>
<span id="cb4-47"><a href="#cb4-47" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb4-48"><a href="#cb4-48" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(n)) <span class="sc">|&gt;</span></span>
<span id="cb4-49"><a href="#cb4-49" aria-hidden="true" tabindex="-1"></a>  <span class="fu">slice_head</span>(<span class="at">n =</span> <span class="dv">10</span>)</span>
<span id="cb4-50"><a href="#cb4-50" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-51"><a href="#cb4-51" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-52"><a href="#cb4-52" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(colon_summary, <span class="at">digits =</span> <span class="dv">0</span>),</span>
<span id="cb4-53"><a href="#cb4-53" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Public colon cancer trial sample used in the Sankey-diagram example"</span></span>
<span id="cb4-54"><a href="#cb4-54" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Public colon cancer trial sample used in the Sankey-diagram example</caption>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">observation</th>
<th style="text-align: right;">levamisole</th>
<th style="text-align: right;">levamisole_5fu</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">896</td>
<td style="text-align: right;">303</td>
<td style="text-align: right;">302</td>
<td style="text-align: right;">291</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(colon_top_paths, <span class="at">digits =</span> <span class="dv">0</span>),</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Largest treatment-to-recurrence-to-survival pathways in the public colon trial data"</span></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Largest treatment-to-recurrence-to-survival pathways in the public colon trial data</caption>
<thead>
<tr class="header">
<th style="text-align: left;">treatment_arm</th>
<th style="text-align: left;">recurrence_3y</th>
<th style="text-align: left;">survival_5y</th>
<th style="text-align: right;">n</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Levamisole + 5FU</td>
<td style="text-align: left;">No recurrence by 3 years</td>
<td style="text-align: left;">Alive at 5 years</td>
<td style="text-align: right;">180</td>
</tr>
<tr class="even">
<td style="text-align: left;">Levamisole</td>
<td style="text-align: left;">No recurrence by 3 years</td>
<td style="text-align: left;">Alive at 5 years</td>
<td style="text-align: right;">145</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Observation</td>
<td style="text-align: left;">No recurrence by 3 years</td>
<td style="text-align: left;">Alive at 5 years</td>
<td style="text-align: right;">142</td>
</tr>
<tr class="even">
<td style="text-align: left;">Observation</td>
<td style="text-align: left;">Recurrence by 3 years</td>
<td style="text-align: left;">Died by 5 years</td>
<td style="text-align: right;">135</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Levamisole</td>
<td style="text-align: left;">Recurrence by 3 years</td>
<td style="text-align: left;">Died by 5 years</td>
<td style="text-align: right;">132</td>
</tr>
<tr class="even">
<td style="text-align: left;">Levamisole + 5FU</td>
<td style="text-align: left;">Recurrence by 3 years</td>
<td style="text-align: left;">Died by 5 years</td>
<td style="text-align: right;">96</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Levamisole</td>
<td style="text-align: left;">Recurrence by 3 years</td>
<td style="text-align: left;">Alive at 5 years</td>
<td style="text-align: right;">19</td>
</tr>
<tr class="even">
<td style="text-align: left;">Observation</td>
<td style="text-align: left;">Recurrence by 3 years</td>
<td style="text-align: left;">Alive at 5 years</td>
<td style="text-align: right;">18</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Levamisole + 5FU</td>
<td style="text-align: left;">No recurrence by 3 years</td>
<td style="text-align: left;">Died by 5 years</td>
<td style="text-align: right;">8</td>
</tr>
<tr class="even">
<td style="text-align: left;">Observation</td>
<td style="text-align: left;">No recurrence by 3 years</td>
<td style="text-align: left;">Died by 5 years</td>
<td style="text-align: right;">8</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The real-world table shows the pathway counts explicitly, but the visual structure is still hard to absorb from rows alone. That is exactly the problem the Sankey diagram solves.</p>
</section>
<section id="step-5-draw-the-real-world-sankey-diagram" class="level2" data-number="76.6">
<h2 data-number="76.6" class="anchored" data-anchor-id="step-5-draw-the-real-world-sankey-diagram"><span class="header-section-number">76.6</span> Step 5: Draw the real-world Sankey diagram</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>colon_stage_orders <span class="ot">&lt;-</span> <span class="fu">list</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">treatment_arm =</span> <span class="fu">c</span>(<span class="st">"Observation"</span>, <span class="st">"Levamisole"</span>, <span class="st">"Levamisole</span><span class="sc">\n</span><span class="st">+ 5FU"</span>),</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">recurrence_3y =</span> <span class="fu">c</span>(<span class="st">"No recurrence</span><span class="sc">\n</span><span class="st">by 3 years"</span>, <span class="st">"Recurrence</span><span class="sc">\n</span><span class="st">by 3 years"</span>),</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">survival_5y =</span> <span class="fu">c</span>(<span class="st">"Alive at</span><span class="sc">\n</span><span class="st">5 years"</span>, <span class="st">"Died by</span><span class="sc">\n</span><span class="st">5 years"</span>)</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>colon_components <span class="ot">&lt;-</span> <span class="fu">prepare_sankey_components</span>(</span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">flows =</span> colon_pathways,</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">stage_vars =</span> <span class="fu">c</span>(<span class="st">"treatment_arm"</span>, <span class="st">"recurrence_3y"</span>, <span class="st">"survival_5y"</span>),</span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">stage_orders =</span> colon_stage_orders,</span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">stage_titles =</span> <span class="fu">c</span>(<span class="st">"Treatment arm"</span>, <span class="st">"Recurrence status"</span>, <span class="st">"5-year survival"</span>),</span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">middle_stage =</span> <span class="st">"recurrence_3y"</span>,</span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">gap =</span> <span class="dv">18</span></span>
<span id="cb6-14"><a href="#cb6-14" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-15"><a href="#cb6-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-16"><a href="#cb6-16" aria-hidden="true" tabindex="-1"></a>colon_palette <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb6-17"><a href="#cb6-17" aria-hidden="true" tabindex="-1"></a>  <span class="st">"No recurrence</span><span class="sc">\n</span><span class="st">by 3 years"</span> <span class="ot">=</span> <span class="st">"#80b1d3"</span>,</span>
<span id="cb6-18"><a href="#cb6-18" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Recurrence</span><span class="sc">\n</span><span class="st">by 3 years"</span> <span class="ot">=</span> <span class="st">"#fb8072"</span></span>
<span id="cb6-19"><a href="#cb6-19" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-20"><a href="#cb6-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-21"><a href="#cb6-21" aria-hidden="true" tabindex="-1"></a>colon_sankey <span class="ot">&lt;-</span> <span class="fu">draw_sankey_plot</span>(</span>
<span id="cb6-22"><a href="#cb6-22" aria-hidden="true" tabindex="-1"></a>  colon_components,</span>
<span id="cb6-23"><a href="#cb6-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">fill_palette =</span> colon_palette,</span>
<span id="cb6-24"><a href="#cb6-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"A Sankey diagram summarizes patient pathways in the public colon trial data"</span>,</span>
<span id="cb6-25"><a href="#cb6-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Treatment arm to recurrence by 3 years to survival by 5 years"</span></span>
<span id="cb6-26"><a href="#cb6-26" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-27"><a href="#cb6-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-28"><a href="#cb6-28" aria-hidden="true" tabindex="-1"></a>colon_sankey</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/sankey-diagram-care-pathways_files/figure-html/unnamed-chunk-5-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This is a transparent partial replication rather than a reproduction of a published trial figure. The contribution here is methodological: the public trial data are recast as a pathway diagram so the reader can see how treatment arm, recurrence, and survival relate as sequential categories rather than as separate endpoint tables.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="76.7">
<h2 data-number="76.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">76.7</span> How to read the figure carefully</h2>
<p>Sankey diagrams are visually intuitive, but they can also be misleading if used carelessly. First, they show flows of observed counts, not causal mechanisms. A thick ribbon does not prove that the upstream category caused the downstream outcome. Second, category order matters. Reordering the blocks can make the same data look more or less tangled, so the ordering should reflect a clear substantive logic.</p>
<p>Third, the figure is strongest when the stages are genuinely sequential. A Sankey diagram is much less informative if the columns are only loosely related cross-sections. Finally, pathway diagrams should usually be paired with a table, because readers often want to identify the exact largest pathways after they have seen the overall structure.</p>
</section>
<section id="further-reading" class="level2" data-number="76.8">
<h2 data-number="76.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">76.8</span> Further reading</h2>
<p>For the general layered-graphics logic behind static figures of this kind, Wickham remains the core reference <span class="citation" data-cites="wickham2016ggplot2">Wickham (<a href="#ref-wickham2016ggplot2" role="doc-biblioref">2016</a>)</span>. For alluvial and Sankey-style categorical flow graphics in R, Brunson's formulation is a useful conceptual reference even when the figure is built manually rather than through a dedicated package <span class="citation" data-cites="brunson2020ggalluvial">Brunson (<a href="#ref-brunson2020ggalluvial" role="doc-biblioref">2020</a>)</span>. For the underlying colon trial data used in the real-world example, see Laurie and colleagues and Moertel and colleagues <span class="citation" data-cites="laurie1989">Laurie et al. (<a href="#ref-laurie1989" role="doc-biblioref">1989</a>)</span>; <span class="citation" data-cites="moertel1990">Moertel et al. (<a href="#ref-moertel1990" role="doc-biblioref">1990</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-brunson2020ggalluvial" class="csl-entry" role="listitem">
Brunson, Jason Cory. 2020. <span>"Ggalluvial: Layered Grammar for Alluvial Plots."</span> <em>Journal of Open Source Software</em> 5 (49): 2017. <a href="https://doi.org/10.21105/joss.02017">https://doi.org/10.21105/joss.02017</a>.
</div>
<div id="ref-laurie1989" class="csl-entry" role="listitem">
Laurie, John A., Charles G. Moertel, Thomas R. Fleming, H. S. Wieand, James E. Leigh, Joseph Rubin, G. W. McCormack, J. B. Gerstner, J. E. Krook, and James A. Mailliard. 1989. <span>"Surgical Adjuvant Therapy of Large-Bowel Carcinoma: An Evaluation of Levamisole and the Combination of Levamisole and Fluorouracil."</span> <em>Journal of Clinical Oncology</em> 7 (10): 1447-56. <a href="https://doi.org/10.1200/JCO.1989.7.10.1447">https://doi.org/10.1200/JCO.1989.7.10.1447</a>.
</div>
<div id="ref-moertel1990" class="csl-entry" role="listitem">
Moertel, Charles G., Thomas R. Fleming, John S. Macdonald, Daniel G. Haller, John A. Laurie, Phyllis J. Goodman, James S. Ungerleider, et al. 1990. <span>"Levamisole and Fluorouracil for Adjuvant Therapy of Resected Colon Carcinoma."</span> <em>New England Journal of Medicine</em> 322 (6): 352-58. <a href="https://doi.org/10.1056/NEJM199002083220602">https://doi.org/10.1056/NEJM199002083220602</a>.
</div>
<div id="ref-wickham2016ggplot2" class="csl-entry" role="listitem">
Wickham, Hadley. 2016. <em>Ggplot2: Elegant Graphics for Data Analysis</em>. Second. New York: Springer.
</div>
</div>
</section>
