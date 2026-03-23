---
title: "Decision Trees and Markov Models"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter shows how to build a decision-analytic model schematic rather than a statistical results plot. The figure we will create is a two-panel diagram: a short-term decision tree on the left and a long-run..."
---
<p>This chapter shows how to build a decision-analytic model schematic rather than a statistical results plot. The figure we will create is a two-panel diagram: a short-term decision tree on the left and a long-run Markov state-transition diagram on the right. This is a useful visualization because many health-economic models have exactly that architecture. An acute treatment choice is represented with a decision tree, and downstream recurring outcomes are represented with a Markov process. Sonnenberg and Beck explain why state-transition models became central in medical decision making, while Briggs and Sculpher show why Markov structures are so common in health economic evaluation <span class="citation" data-cites="sonnenberg1993">Sonnenberg and Beck (<a href="#ref-sonnenberg1993" role="doc-biblioref">1993</a>)</span>; <span class="citation" data-cites="briggs1998markov">Briggs and Sculpher (<a href="#ref-briggs1998markov" role="doc-biblioref">1998</a>)</span>.</p>
<p>The point of the figure is not to present parameter estimates. It is to make model structure legible. A reader who cannot see the branching logic, health states, and transition pathways will struggle to understand the economic model no matter how polished the cost-effectiveness tables look.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="75.1">
<h2 data-number="75.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">75.1</span> What the visualization is showing</h2>
<p>The visualization has two linked panels.</p>
<ol type="1">
<li>The left panel is a decision tree. It shows a one-off choice among strategies and the immediate short-run pathways that follow.</li>
<li>The right panel is a Markov state diagram. It shows the health states entered after the initial decision and the transitions that can repeat over cycles.</li>
</ol>
<p>This type of figure is useful when:</p>
<ol type="1">
<li>the model combines an acute decision with longer-run disease progression,</li>
<li>the analyst needs to communicate structure before presenting results,</li>
<li>the audience includes readers who may not infer the model architecture from equations or code alone.</li>
</ol>
<p>The key reading rule is simple. Follow the tree from left to right for initial branching decisions. Then read the Markov panel as a state diagram in which arrows show which transitions are allowed from one cycle to the next.</p>
</section>
<section id="step-1-build-the-synthetic-decision-tree-data" class="level2" data-number="75.2">
<h2 data-number="75.2" class="anchored" data-anchor-id="step-1-build-the-synthetic-decision-tree-data"><span class="header-section-number">75.2</span> Step 1: Build the synthetic decision tree data</h2>
<p>We begin with a synthetic hospital-discharge decision problem. The acute decision is whether to use usual discharge planning or an enhanced follow-up pathway. Short-run outcomes are readmission or no readmission, and the enhanced pathway then feeds into a simple long-run recovery model.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(patchwork)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>format_numeric_table <span class="ot">&lt;-</span> <span class="cf">function</span>(df, <span class="at">digits =</span> <span class="dv">3</span>) {</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  numeric_cols <span class="ot">&lt;-</span> <span class="fu">vapply</span>(df, is.numeric, <span class="fu">logical</span>(<span class="dv">1</span>))</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  df[numeric_cols] <span class="ot">&lt;-</span> <span class="fu">lapply</span>(df[numeric_cols], round, <span class="at">digits =</span> digits)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  df</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>draw_decision_tree <span class="ot">&lt;-</span> <span class="cf">function</span>(nodes, edges, title, <span class="at">subtitle =</span> <span class="cn">NULL</span>) {</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>() <span class="sc">+</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> edges,</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">xend =</span> xend, <span class="at">yend =</span> yend),</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.9</span>,</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#5b6770"</span>,</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>      <span class="at">arrow =</span> <span class="fu">arrow</span>(<span class="at">length =</span> grid<span class="sc">::</span><span class="fu">unit</span>(<span class="fl">0.08</span>, <span class="st">"inches"</span>), <span class="at">type =</span> <span class="st">"closed"</span>)</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> edges,</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> label_x, <span class="at">y =</span> label_y, <span class="at">label =</span> label),</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.1</span>,</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#4d4d4d"</span></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_label</span>(</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> nodes,</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">label =</span> label, <span class="at">fill =</span> fill, <span class="at">color =</span> text_color),</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.25</span>,</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>      <span class="at">label.r =</span> grid<span class="sc">::</span><span class="fu">unit</span>(<span class="fl">0.15</span>, <span class="st">"lines"</span>),</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>      <span class="at">label.padding =</span> grid<span class="sc">::</span><span class="fu">unit</span>(<span class="fl">0.22</span>, <span class="st">"lines"</span>),</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.3</span>,</span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>      <span class="at">fontface =</span> <span class="st">"bold"</span>,</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>      <span class="at">show.legend =</span> <span class="cn">FALSE</span></span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_fill_identity</span>() <span class="sc">+</span></span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_color_identity</span>() <span class="sc">+</span></span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coord_cartesian</span>(<span class="at">xlim =</span> <span class="fu">c</span>(<span class="sc">-</span><span class="fl">0.2</span>, <span class="fl">5.2</span>), <span class="at">ylim =</span> <span class="fu">c</span>(<span class="sc">-</span><span class="fl">0.5</span>, <span class="fl">5.8</span>), <span class="at">clip =</span> <span class="st">"off"</span>) <span class="sc">+</span></span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_void</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.title =</span> <span class="fu">element_text</span>(<span class="at">face =</span> <span class="st">"bold"</span>, <span class="at">size =</span> <span class="dv">13</span>),</span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.subtitle =</span> <span class="fu">element_text</span>(<span class="at">size =</span> <span class="dv">10</span>, <span class="at">color =</span> <span class="st">"#4d4d4d"</span>),</span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.margin =</span> <span class="fu">margin</span>(<span class="dv">10</span>, <span class="dv">10</span>, <span class="dv">10</span>, <span class="dv">10</span>)</span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-52"><a href="#cb1-52" aria-hidden="true" tabindex="-1"></a>draw_markov_diagram <span class="ot">&lt;-</span> <span class="cf">function</span>(states, transitions, title, <span class="at">subtitle =</span> <span class="cn">NULL</span>) {</span>
<span id="cb1-53"><a href="#cb1-53" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>() <span class="sc">+</span></span>
<span id="cb1-54"><a href="#cb1-54" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_curve</span>(</span>
<span id="cb1-55"><a href="#cb1-55" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> <span class="fu">subset</span>(transitions, curvature <span class="sc">&gt;</span> <span class="dv">0</span>),</span>
<span id="cb1-56"><a href="#cb1-56" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">xend =</span> xend, <span class="at">yend =</span> yend),</span>
<span id="cb1-57"><a href="#cb1-57" aria-hidden="true" tabindex="-1"></a>      <span class="at">curvature =</span> <span class="fl">0.35</span>,</span>
<span id="cb1-58"><a href="#cb1-58" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.9</span>,</span>
<span id="cb1-59"><a href="#cb1-59" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#5b6770"</span>,</span>
<span id="cb1-60"><a href="#cb1-60" aria-hidden="true" tabindex="-1"></a>      <span class="at">arrow =</span> <span class="fu">arrow</span>(<span class="at">length =</span> grid<span class="sc">::</span><span class="fu">unit</span>(<span class="fl">0.08</span>, <span class="st">"inches"</span>), <span class="at">type =</span> <span class="st">"closed"</span>)</span>
<span id="cb1-61"><a href="#cb1-61" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-62"><a href="#cb1-62" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_curve</span>(</span>
<span id="cb1-63"><a href="#cb1-63" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> <span class="fu">subset</span>(transitions, curvature <span class="sc">&lt;</span> <span class="dv">0</span>),</span>
<span id="cb1-64"><a href="#cb1-64" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">xend =</span> xend, <span class="at">yend =</span> yend),</span>
<span id="cb1-65"><a href="#cb1-65" aria-hidden="true" tabindex="-1"></a>      <span class="at">curvature =</span> <span class="sc">-</span><span class="fl">0.15</span>,</span>
<span id="cb1-66"><a href="#cb1-66" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.9</span>,</span>
<span id="cb1-67"><a href="#cb1-67" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#5b6770"</span>,</span>
<span id="cb1-68"><a href="#cb1-68" aria-hidden="true" tabindex="-1"></a>      <span class="at">arrow =</span> <span class="fu">arrow</span>(<span class="at">length =</span> grid<span class="sc">::</span><span class="fu">unit</span>(<span class="fl">0.08</span>, <span class="st">"inches"</span>), <span class="at">type =</span> <span class="st">"closed"</span>)</span>
<span id="cb1-69"><a href="#cb1-69" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-70"><a href="#cb1-70" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_segment</span>(</span>
<span id="cb1-71"><a href="#cb1-71" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> <span class="fu">subset</span>(transitions, curvature <span class="sc">==</span> <span class="dv">0</span>),</span>
<span id="cb1-72"><a href="#cb1-72" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">xend =</span> xend, <span class="at">yend =</span> yend),</span>
<span id="cb1-73"><a href="#cb1-73" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.9</span>,</span>
<span id="cb1-74"><a href="#cb1-74" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#5b6770"</span>,</span>
<span id="cb1-75"><a href="#cb1-75" aria-hidden="true" tabindex="-1"></a>      <span class="at">arrow =</span> <span class="fu">arrow</span>(<span class="at">length =</span> grid<span class="sc">::</span><span class="fu">unit</span>(<span class="fl">0.08</span>, <span class="st">"inches"</span>), <span class="at">type =</span> <span class="st">"closed"</span>)</span>
<span id="cb1-76"><a href="#cb1-76" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-77"><a href="#cb1-77" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_text</span>(</span>
<span id="cb1-78"><a href="#cb1-78" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> transitions,</span>
<span id="cb1-79"><a href="#cb1-79" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> label_x, <span class="at">y =</span> label_y, <span class="at">label =</span> label),</span>
<span id="cb1-80"><a href="#cb1-80" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.0</span>,</span>
<span id="cb1-81"><a href="#cb1-81" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#4d4d4d"</span></span>
<span id="cb1-82"><a href="#cb1-82" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-83"><a href="#cb1-83" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_label</span>(</span>
<span id="cb1-84"><a href="#cb1-84" aria-hidden="true" tabindex="-1"></a>      <span class="at">data =</span> states,</span>
<span id="cb1-85"><a href="#cb1-85" aria-hidden="true" tabindex="-1"></a>      <span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> y, <span class="at">label =</span> label, <span class="at">fill =</span> fill, <span class="at">color =</span> text_color),</span>
<span id="cb1-86"><a href="#cb1-86" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.25</span>,</span>
<span id="cb1-87"><a href="#cb1-87" aria-hidden="true" tabindex="-1"></a>      <span class="at">label.r =</span> grid<span class="sc">::</span><span class="fu">unit</span>(<span class="fl">0.15</span>, <span class="st">"lines"</span>),</span>
<span id="cb1-88"><a href="#cb1-88" aria-hidden="true" tabindex="-1"></a>      <span class="at">label.padding =</span> grid<span class="sc">::</span><span class="fu">unit</span>(<span class="fl">0.24</span>, <span class="st">"lines"</span>),</span>
<span id="cb1-89"><a href="#cb1-89" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.4</span>,</span>
<span id="cb1-90"><a href="#cb1-90" aria-hidden="true" tabindex="-1"></a>      <span class="at">fontface =</span> <span class="st">"bold"</span>,</span>
<span id="cb1-91"><a href="#cb1-91" aria-hidden="true" tabindex="-1"></a>      <span class="at">show.legend =</span> <span class="cn">FALSE</span></span>
<span id="cb1-92"><a href="#cb1-92" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-93"><a href="#cb1-93" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_fill_identity</span>() <span class="sc">+</span></span>
<span id="cb1-94"><a href="#cb1-94" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_color_identity</span>() <span class="sc">+</span></span>
<span id="cb1-95"><a href="#cb1-95" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coord_cartesian</span>(<span class="at">xlim =</span> <span class="fu">c</span>(<span class="sc">-</span><span class="fl">0.2</span>, <span class="fl">4.8</span>), <span class="at">ylim =</span> <span class="fu">c</span>(<span class="sc">-</span><span class="fl">0.3</span>, <span class="fl">4.3</span>), <span class="at">clip =</span> <span class="st">"off"</span>) <span class="sc">+</span></span>
<span id="cb1-96"><a href="#cb1-96" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb1-97"><a href="#cb1-97" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb1-98"><a href="#cb1-98" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle</span>
<span id="cb1-99"><a href="#cb1-99" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-100"><a href="#cb1-100" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_void</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb1-101"><a href="#cb1-101" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb1-102"><a href="#cb1-102" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.title =</span> <span class="fu">element_text</span>(<span class="at">face =</span> <span class="st">"bold"</span>, <span class="at">size =</span> <span class="dv">13</span>),</span>
<span id="cb1-103"><a href="#cb1-103" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.subtitle =</span> <span class="fu">element_text</span>(<span class="at">size =</span> <span class="dv">10</span>, <span class="at">color =</span> <span class="st">"#4d4d4d"</span>),</span>
<span id="cb1-104"><a href="#cb1-104" aria-hidden="true" tabindex="-1"></a>      <span class="at">plot.margin =</span> <span class="fu">margin</span>(<span class="dv">10</span>, <span class="dv">10</span>, <span class="dv">10</span>, <span class="dv">10</span>)</span>
<span id="cb1-105"><a href="#cb1-105" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-106"><a href="#cb1-106" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>synthetic_tree_nodes <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">2</span>, <span class="dv">2</span>, <span class="fl">4.2</span>, <span class="fl">4.2</span>, <span class="fl">4.2</span>, <span class="fl">4.2</span>),</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> <span class="fu">c</span>(<span class="fl">2.5</span>, <span class="fl">4.3</span>, <span class="fl">0.9</span>, <span class="fl">5.2</span>, <span class="fl">3.4</span>, <span class="fl">1.8</span>, <span class="fl">0.0</span>),</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">label =</span> <span class="fu">c</span>(</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Choose</span><span class="sc">\n</span><span class="st">pathway"</span>,</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Usual</span><span class="sc">\n</span><span class="st">care"</span>,</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Enhanced</span><span class="sc">\n</span><span class="st">follow-up"</span>,</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Readmit"</span>,</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    <span class="st">"No</span><span class="sc">\n</span><span class="st">readmit"</span>,</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Readmit"</span>,</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>    <span class="st">"No</span><span class="sc">\n</span><span class="st">readmit"</span></span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">fill =</span> <span class="fu">c</span>(<span class="st">"#08519c"</span>, <span class="st">"#6baed6"</span>, <span class="st">"#6baed6"</span>, <span class="st">"#fdd0a2"</span>, <span class="st">"#fdd0a2"</span>, <span class="st">"#fdd0a2"</span>, <span class="st">"#fdd0a2"</span>),</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">text_color =</span> <span class="fu">c</span>(<span class="st">"white"</span>, <span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"black"</span>)</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>synthetic_tree_edges <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="fl">0.35</span>, <span class="fl">0.35</span>, <span class="fl">2.35</span>, <span class="fl">2.35</span>, <span class="fl">2.35</span>, <span class="fl">2.35</span>),</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> <span class="fu">c</span>(<span class="fl">2.7</span>, <span class="fl">2.3</span>, <span class="fl">4.45</span>, <span class="fl">4.10</span>, <span class="fl">1.05</span>, <span class="fl">0.75</span>),</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">xend =</span> <span class="fu">c</span>(<span class="fl">1.65</span>, <span class="fl">1.65</span>, <span class="fl">3.8</span>, <span class="fl">3.8</span>, <span class="fl">3.8</span>, <span class="fl">3.8</span>),</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">yend =</span> <span class="fu">c</span>(<span class="fl">4.1</span>, <span class="fl">1.1</span>, <span class="fl">5.1</span>, <span class="fl">3.5</span>, <span class="fl">1.9</span>, <span class="fl">0.1</span>),</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">label =</span> <span class="fu">c</span>(<span class="st">"55%"</span>, <span class="st">"45%"</span>, <span class="st">"p = 0.22"</span>, <span class="st">"p = 0.78"</span>, <span class="st">"p = 0.12"</span>, <span class="st">"p = 0.88"</span>),</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_x =</span> <span class="fu">c</span>(<span class="fl">0.95</span>, <span class="fl">0.95</span>, <span class="fl">3.05</span>, <span class="fl">3.05</span>, <span class="fl">3.05</span>, <span class="fl">3.05</span>),</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_y =</span> <span class="fu">c</span>(<span class="fl">4.55</span>, <span class="fl">1.55</span>, <span class="fl">5.35</span>, <span class="fl">3.85</span>, <span class="fl">2.25</span>, <span class="fl">0.45</span>)</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>synthetic_tree_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>  <span class="at">branch =</span> <span class="fu">c</span>(</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Usual care -&gt; Readmit"</span>,</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Usual care -&gt; No readmit"</span>,</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Enhanced follow-up -&gt; Readmit"</span>,</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Enhanced follow-up -&gt; No readmit"</span></span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>  <span class="at">probability =</span> <span class="fu">c</span>(<span class="fl">0.22</span>, <span class="fl">0.78</span>, <span class="fl">0.12</span>, <span class="fl">0.88</span>),</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>  <span class="at">short_run_cost =</span> <span class="fu">c</span>(<span class="dv">14000</span>, <span class="dv">4200</span>, <span class="dv">13500</span>, <span class="dv">5100</span>)</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_tree_table, <span class="at">digits =</span> <span class="dv">2</span>),</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Short-run branches used in the synthetic decision tree"</span></span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Short-run branches used in the synthetic decision tree</caption>
<thead>
<tr class="header">
<th style="text-align: left;">branch</th>
<th style="text-align: right;">probability</th>
<th style="text-align: right;">short_run_cost</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Usual care -&gt; Readmit</td>
<td style="text-align: right;">0.22</td>
<td style="text-align: right;">14000</td>
</tr>
<tr class="even">
<td style="text-align: left;">Usual care -&gt; No readmit</td>
<td style="text-align: right;">0.78</td>
<td style="text-align: right;">4200</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Enhanced follow-up -&gt; Readmit</td>
<td style="text-align: right;">0.12</td>
<td style="text-align: right;">13500</td>
</tr>
<tr class="even">
<td style="text-align: left;">Enhanced follow-up -&gt; No readmit</td>
<td style="text-align: right;">0.88</td>
<td style="text-align: right;">5100</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-2-draw-the-synthetic-decision-tree-panel" class="level2" data-number="75.3">
<h2 data-number="75.3" class="anchored" data-anchor-id="step-2-draw-the-synthetic-decision-tree-panel"><span class="header-section-number">75.3</span> Step 2: Draw the synthetic decision tree panel</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>synthetic_tree_plot <span class="ot">&lt;-</span> <span class="fu">draw_decision_tree</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  synthetic_tree_nodes,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  synthetic_tree_edges,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Synthetic decision tree"</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Short-run hospital-discharge pathways"</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>synthetic_tree_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/decision-trees-and-markov-models_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This is the first half of the figure. The reader can already see the initial decision, the branching structure, and the immediate outcomes. But if the model also includes recurring long-run outcomes, a tree alone is not enough.</p>
</section>
<section id="step-3-build-the-synthetic-markov-state-diagram" class="level2" data-number="75.4">
<h2 data-number="75.4" class="anchored" data-anchor-id="step-3-build-the-synthetic-markov-state-diagram"><span class="header-section-number">75.4</span> Step 3: Build the synthetic Markov state diagram</h2>
<p>Now we add a simple Markov state diagram for long-run follow-up after discharge. The states are stable recovery, post-readmission, and death.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_markov_states <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="fl">1.1</span>, <span class="fl">3.2</span>, <span class="fl">3.2</span>),</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> <span class="fu">c</span>(<span class="fl">2.0</span>, <span class="fl">3.2</span>, <span class="fl">0.8</span>),</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">label =</span> <span class="fu">c</span>(<span class="st">"Stable</span><span class="sc">\n</span><span class="st">recovery"</span>, <span class="st">"Post-</span><span class="sc">\n</span><span class="st">readmission"</span>, <span class="st">"Death"</span>),</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">fill =</span> <span class="fu">c</span>(<span class="st">"#74c476"</span>, <span class="st">"#9ecae1"</span>, <span class="st">"#d7301f"</span>),</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">text_color =</span> <span class="fu">c</span>(<span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"white"</span>)</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>synthetic_markov_transitions <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="fl">1.55</span>, <span class="fl">2.55</span>, <span class="fl">1.55</span>, <span class="fl">2.75</span>, <span class="fl">2.75</span>, <span class="fl">3.55</span>, <span class="fl">1.1</span>),</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> <span class="fu">c</span>(<span class="fl">2.15</span>, <span class="fl">2.95</span>, <span class="fl">1.85</span>, <span class="fl">2.75</span>, <span class="fl">2.95</span>, <span class="fl">0.95</span>, <span class="fl">1.55</span>),</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">xend =</span> <span class="fu">c</span>(<span class="fl">2.75</span>, <span class="fl">1.55</span>, <span class="fl">2.75</span>, <span class="fl">1.55</span>, <span class="fl">3.05</span>, <span class="fl">3.05</span>, <span class="fl">1.1</span>),</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">yend =</span> <span class="fu">c</span>(<span class="fl">2.95</span>, <span class="fl">2.15</span>, <span class="fl">0.95</span>, <span class="fl">1.85</span>, <span class="fl">1.00</span>, <span class="fl">3.05</span>, <span class="fl">2.45</span>),</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">curvature =</span> <span class="fu">c</span>(<span class="fl">0.12</span>, <span class="fl">0.12</span>, <span class="sc">-</span><span class="fl">0.12</span>, <span class="sc">-</span><span class="fl">0.12</span>, <span class="fl">0.00</span>, <span class="fl">0.35</span>, <span class="fl">0.45</span>),</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">label =</span> <span class="fu">c</span>(<span class="st">"p_SR"</span>, <span class="st">"p_RS"</span>, <span class="st">"p_SD"</span>, <span class="st">"p_RS2"</span>, <span class="st">"p_RD"</span>, <span class="st">"stay"</span>, <span class="st">"stay"</span>),</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_x =</span> <span class="fu">c</span>(<span class="fl">2.15</span>, <span class="fl">2.10</span>, <span class="fl">2.20</span>, <span class="fl">2.15</span>, <span class="fl">3.05</span>, <span class="fl">3.70</span>, <span class="fl">0.55</span>),</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_y =</span> <span class="fu">c</span>(<span class="fl">3.25</span>, <span class="fl">2.55</span>, <span class="fl">1.10</span>, <span class="fl">1.40</span>, <span class="fl">1.95</span>, <span class="fl">3.55</span>, <span class="fl">2.85</span>)</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>synthetic_markov_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">from =</span> <span class="fu">c</span>(<span class="st">"Stable recovery"</span>, <span class="st">"Stable recovery"</span>, <span class="st">"Post-readmission"</span>, <span class="st">"Post-readmission"</span>, <span class="st">"Death"</span>),</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">to =</span> <span class="fu">c</span>(<span class="st">"Post-readmission"</span>, <span class="st">"Death"</span>, <span class="st">"Stable recovery"</span>, <span class="st">"Death"</span>, <span class="st">"Death"</span>),</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">example_transition_probability =</span> <span class="fu">c</span>(<span class="fl">0.15</span>, <span class="fl">0.03</span>, <span class="fl">0.55</span>, <span class="fl">0.08</span>, <span class="fl">1.00</span>)</span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_markov_table, <span class="at">digits =</span> <span class="dv">2</span>),</span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Illustrative transition structure for the synthetic Markov panel"</span></span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Illustrative transition structure for the synthetic Markov panel</caption>
<thead>
<tr class="header">
<th style="text-align: left;">from</th>
<th style="text-align: left;">to</th>
<th style="text-align: right;">example_transition_probability</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Stable recovery</td>
<td style="text-align: left;">Post-readmission</td>
<td style="text-align: right;">0.15</td>
</tr>
<tr class="even">
<td style="text-align: left;">Stable recovery</td>
<td style="text-align: left;">Death</td>
<td style="text-align: right;">0.03</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Post-readmission</td>
<td style="text-align: left;">Stable recovery</td>
<td style="text-align: right;">0.55</td>
</tr>
<tr class="even">
<td style="text-align: left;">Post-readmission</td>
<td style="text-align: left;">Death</td>
<td style="text-align: right;">0.08</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Death</td>
<td style="text-align: left;">Death</td>
<td style="text-align: right;">1.00</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-4-draw-the-full-synthetic-decision-analytic-schematic" class="level2" data-number="75.5">
<h2 data-number="75.5" class="anchored" data-anchor-id="step-4-draw-the-full-synthetic-decision-analytic-schematic"><span class="header-section-number">75.5</span> Step 4: Draw the full synthetic decision-analytic schematic</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>synthetic_markov_plot <span class="ot">&lt;-</span> <span class="fu">draw_markov_diagram</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  synthetic_markov_states,</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  synthetic_markov_transitions,</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Synthetic Markov model"</span>,</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Long-run state transitions after the acute decision"</span></span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>synthetic_schematic <span class="ot">&lt;-</span> synthetic_tree_plot <span class="sc">+</span> synthetic_markov_plot <span class="sc">+</span></span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">plot_layout</span>(<span class="at">widths =</span> <span class="fu">c</span>(<span class="fl">1.2</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>  <span class="fu">plot_annotation</span>(</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"A decision-analytic schematic can show short-run branching and long-run recurrence in one figure"</span>,</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Decision tree on the left, Markov state diagram on the right"</span></span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>synthetic_schematic</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/decision-trees-and-markov-models_files/figure-html/unnamed-chunk-5-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This is the core visualization pattern. The left panel clarifies the one-time branching logic. The right panel clarifies what happens afterward over repeated cycles. Together they tell the reader much more than either panel could alone.</p>
</section>
<section id="step-5-create-a-real-world-decision-analytic-schematic-from-a-published-health-economic-application" class="level2" data-number="75.6">
<h2 data-number="75.6" class="anchored" data-anchor-id="step-5-create-a-real-world-decision-analytic-schematic-from-a-published-health-economic-application"><span class="header-section-number">75.6</span> Step 5: Create a real-world decision-analytic schematic from a published health-economic application</h2>
<p>For a real-world example, we build a partial published-inspired schematic based on the hip-replacement modeling literature by Briggs and colleagues <span class="citation" data-cites="briggs1998thr">Briggs et al. (<a href="#ref-briggs1998thr" role="doc-biblioref">1998</a>)</span> and the broader Markov-modeling framework described by Briggs and Sculpher and by Sonnenberg and Beck <span class="citation" data-cites="briggs1998markov">Briggs and Sculpher (<a href="#ref-briggs1998markov" role="doc-biblioref">1998</a>)</span>; <span class="citation" data-cites="sonnenberg1993">Sonnenberg and Beck (<a href="#ref-sonnenberg1993" role="doc-biblioref">1993</a>)</span>. The goal is not to reproduce the authors' exact final diagram pixel for pixel. The goal is to recreate the model architecture transparently from the published health-economic problem: an initial prosthesis choice followed by longer-run revision and mortality states.</p>
<p>This replication is therefore partial. It reconstructs the decision-model structure from the published problem description rather than reproducing the full original analysis or all underlying parameters.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>hip_tree_nodes <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">2</span>, <span class="dv">2</span>, <span class="fl">4.2</span>, <span class="fl">4.2</span>, <span class="fl">4.2</span>, <span class="fl">4.2</span>),</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> <span class="fu">c</span>(<span class="fl">2.5</span>, <span class="fl">4.3</span>, <span class="fl">0.9</span>, <span class="fl">5.2</span>, <span class="fl">3.4</span>, <span class="fl">1.8</span>, <span class="fl">0.0</span>),</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">label =</span> <span class="fu">c</span>(</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Select</span><span class="sc">\n</span><span class="st">prosthesis"</span>,</span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Charnley"</span>,</span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Spectron"</span>,</span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Enter</span><span class="sc">\n</span><span class="st">Markov</span><span class="sc">\n</span><span class="st">cohort"</span>,</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Perioperative</span><span class="sc">\n</span><span class="st">death"</span>,</span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Enter</span><span class="sc">\n</span><span class="st">Markov</span><span class="sc">\n</span><span class="st">cohort"</span>,</span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Perioperative</span><span class="sc">\n</span><span class="st">death"</span></span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">fill =</span> <span class="fu">c</span>(<span class="st">"#08519c"</span>, <span class="st">"#6baed6"</span>, <span class="st">"#6baed6"</span>, <span class="st">"#74c476"</span>, <span class="st">"#d7301f"</span>, <span class="st">"#74c476"</span>, <span class="st">"#d7301f"</span>),</span>
<span id="cb6-14"><a href="#cb6-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">text_color =</span> <span class="fu">c</span>(<span class="st">"white"</span>, <span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"white"</span>, <span class="st">"black"</span>, <span class="st">"white"</span>)</span>
<span id="cb6-15"><a href="#cb6-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-16"><a href="#cb6-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-17"><a href="#cb6-17" aria-hidden="true" tabindex="-1"></a>hip_tree_edges <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb6-18"><a href="#cb6-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="fl">0.35</span>, <span class="fl">0.35</span>, <span class="fl">2.35</span>, <span class="fl">2.35</span>, <span class="fl">2.35</span>, <span class="fl">2.35</span>),</span>
<span id="cb6-19"><a href="#cb6-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> <span class="fu">c</span>(<span class="fl">2.7</span>, <span class="fl">2.3</span>, <span class="fl">4.45</span>, <span class="fl">4.10</span>, <span class="fl">1.05</span>, <span class="fl">0.75</span>),</span>
<span id="cb6-20"><a href="#cb6-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">xend =</span> <span class="fu">c</span>(<span class="fl">1.65</span>, <span class="fl">1.65</span>, <span class="fl">3.8</span>, <span class="fl">3.8</span>, <span class="fl">3.8</span>, <span class="fl">3.8</span>),</span>
<span id="cb6-21"><a href="#cb6-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">yend =</span> <span class="fu">c</span>(<span class="fl">4.1</span>, <span class="fl">1.1</span>, <span class="fl">5.1</span>, <span class="fl">3.5</span>, <span class="fl">1.9</span>, <span class="fl">0.1</span>),</span>
<span id="cb6-22"><a href="#cb6-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">label =</span> <span class="fu">c</span>(<span class="st">"Option A"</span>, <span class="st">"Option B"</span>, <span class="st">"survive surgery"</span>, <span class="st">"peri-op death"</span>, <span class="st">"survive surgery"</span>, <span class="st">"peri-op death"</span>),</span>
<span id="cb6-23"><a href="#cb6-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_x =</span> <span class="fu">c</span>(<span class="fl">0.95</span>, <span class="fl">0.95</span>, <span class="fl">3.05</span>, <span class="fl">3.05</span>, <span class="fl">3.05</span>, <span class="fl">3.05</span>),</span>
<span id="cb6-24"><a href="#cb6-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_y =</span> <span class="fu">c</span>(<span class="fl">4.55</span>, <span class="fl">1.55</span>, <span class="fl">5.35</span>, <span class="fl">3.85</span>, <span class="fl">2.25</span>, <span class="fl">0.45</span>)</span>
<span id="cb6-25"><a href="#cb6-25" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-26"><a href="#cb6-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-27"><a href="#cb6-27" aria-hidden="true" tabindex="-1"></a>hip_markov_states <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb6-28"><a href="#cb6-28" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="fl">1.0</span>, <span class="fl">3.1</span>, <span class="fl">3.1</span>, <span class="fl">1.0</span>),</span>
<span id="cb6-29"><a href="#cb6-29" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> <span class="fu">c</span>(<span class="fl">3.1</span>, <span class="fl">3.1</span>, <span class="fl">1.0</span>, <span class="fl">1.0</span>),</span>
<span id="cb6-30"><a href="#cb6-30" aria-hidden="true" tabindex="-1"></a>  <span class="at">label =</span> <span class="fu">c</span>(<span class="st">"Primary</span><span class="sc">\n</span><span class="st">THR"</span>, <span class="st">"Revision"</span>, <span class="st">"Post-</span><span class="sc">\n</span><span class="st">revision"</span>, <span class="st">"Death"</span>),</span>
<span id="cb6-31"><a href="#cb6-31" aria-hidden="true" tabindex="-1"></a>  <span class="at">fill =</span> <span class="fu">c</span>(<span class="st">"#74c476"</span>, <span class="st">"#9ecae1"</span>, <span class="st">"#c6dbef"</span>, <span class="st">"#d7301f"</span>),</span>
<span id="cb6-32"><a href="#cb6-32" aria-hidden="true" tabindex="-1"></a>  <span class="at">text_color =</span> <span class="fu">c</span>(<span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"black"</span>, <span class="st">"white"</span>)</span>
<span id="cb6-33"><a href="#cb6-33" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-34"><a href="#cb6-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-35"><a href="#cb6-35" aria-hidden="true" tabindex="-1"></a>hip_markov_transitions <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb6-36"><a href="#cb6-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="fl">1.45</span>, <span class="fl">2.65</span>, <span class="fl">3.10</span>, <span class="fl">2.70</span>, <span class="fl">2.65</span>, <span class="fl">1.45</span>, <span class="fl">0.95</span>, <span class="fl">1.05</span>),</span>
<span id="cb6-37"><a href="#cb6-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> <span class="fu">c</span>(<span class="fl">3.10</span>, <span class="fl">3.10</span>, <span class="fl">2.70</span>, <span class="fl">1.35</span>, <span class="fl">2.95</span>, <span class="fl">2.65</span>, <span class="fl">1.35</span>, <span class="fl">3.45</span>),</span>
<span id="cb6-38"><a href="#cb6-38" aria-hidden="true" tabindex="-1"></a>  <span class="at">xend =</span> <span class="fu">c</span>(<span class="fl">2.65</span>, <span class="fl">1.45</span>, <span class="fl">3.10</span>, <span class="fl">2.70</span>, <span class="fl">0.95</span>, <span class="fl">0.95</span>, <span class="fl">1.95</span>, <span class="fl">1.90</span>),</span>
<span id="cb6-39"><a href="#cb6-39" aria-hidden="true" tabindex="-1"></a>  <span class="at">yend =</span> <span class="fu">c</span>(<span class="fl">3.10</span>, <span class="fl">3.10</span>, <span class="fl">1.40</span>, <span class="fl">2.75</span>, <span class="fl">1.10</span>, <span class="fl">1.10</span>, <span class="fl">1.00</span>, <span class="fl">3.45</span>),</span>
<span id="cb6-40"><a href="#cb6-40" aria-hidden="true" tabindex="-1"></a>  <span class="at">curvature =</span> <span class="fu">c</span>(<span class="fl">0.10</span>, <span class="fl">0.10</span>, <span class="fl">0.35</span>, <span class="sc">-</span><span class="fl">0.15</span>, <span class="fl">0.00</span>, <span class="sc">-</span><span class="fl">0.10</span>, <span class="fl">0.45</span>, <span class="fl">0.45</span>),</span>
<span id="cb6-41"><a href="#cb6-41" aria-hidden="true" tabindex="-1"></a>  <span class="at">label =</span> <span class="fu">c</span>(<span class="st">"revision"</span>, <span class="st">"back"</span>, <span class="st">"stay"</span>, <span class="st">"re-revision"</span>, <span class="st">"mortality"</span>, <span class="st">"mortality"</span>, <span class="st">"stay"</span>, <span class="st">"stay"</span>),</span>
<span id="cb6-42"><a href="#cb6-42" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_x =</span> <span class="fu">c</span>(<span class="fl">2.05</span>, <span class="fl">2.05</span>, <span class="fl">3.60</span>, <span class="fl">2.85</span>, <span class="fl">1.80</span>, <span class="fl">1.20</span>, <span class="fl">0.35</span>, <span class="fl">1.55</span>),</span>
<span id="cb6-43"><a href="#cb6-43" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_y =</span> <span class="fu">c</span>(<span class="fl">3.45</span>, <span class="fl">2.75</span>, <span class="fl">2.05</span>, <span class="fl">2.10</span>, <span class="fl">1.85</span>, <span class="fl">1.75</span>, <span class="fl">0.55</span>, <span class="fl">3.85</span>)</span>
<span id="cb6-44"><a href="#cb6-44" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-45"><a href="#cb6-45" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-46"><a href="#cb6-46" aria-hidden="true" tabindex="-1"></a>hip_model_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb6-47"><a href="#cb6-47" aria-hidden="true" tabindex="-1"></a>  <span class="at">component =</span> <span class="fu">c</span>(</span>
<span id="cb6-48"><a href="#cb6-48" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Initial decision"</span>,</span>
<span id="cb6-49"><a href="#cb6-49" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Short-run terminal branch"</span>,</span>
<span id="cb6-50"><a href="#cb6-50" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Long-run Markov states"</span>,</span>
<span id="cb6-51"><a href="#cb6-51" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Recurring event of interest"</span></span>
<span id="cb6-52"><a href="#cb6-52" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb6-53"><a href="#cb6-53" aria-hidden="true" tabindex="-1"></a>  <span class="at">published_inspired_structure =</span> <span class="fu">c</span>(</span>
<span id="cb6-54"><a href="#cb6-54" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Choice between prosthesis strategies"</span>,</span>
<span id="cb6-55"><a href="#cb6-55" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Perioperative death versus entry to follow-up cohort"</span>,</span>
<span id="cb6-56"><a href="#cb6-56" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Primary THR, Revision, Post-revision, Death"</span>,</span>
<span id="cb6-57"><a href="#cb6-57" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Revision surgery and subsequent survival states"</span></span>
<span id="cb6-58"><a href="#cb6-58" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb6-59"><a href="#cb6-59" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-60"><a href="#cb6-60" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-61"><a href="#cb6-61" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-62"><a href="#cb6-62" aria-hidden="true" tabindex="-1"></a>  hip_model_table,</span>
<span id="cb6-63"><a href="#cb6-63" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Published-inspired model components in the hip-replacement schematic"</span></span>
<span id="cb6-64"><a href="#cb6-64" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Published-inspired model components in the hip-replacement schematic</caption>
<colgroup>
<col style="width: 34%">
<col style="width: 65%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">component</th>
<th style="text-align: left;">published_inspired_structure</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Initial decision</td>
<td style="text-align: left;">Choice between prosthesis strategies</td>
</tr>
<tr class="even">
<td style="text-align: left;">Short-run terminal branch</td>
<td style="text-align: left;">Perioperative death versus entry to follow-up cohort</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Long-run Markov states</td>
<td style="text-align: left;">Primary THR, Revision, Post-revision, Death</td>
</tr>
<tr class="even">
<td style="text-align: left;">Recurring event of interest</td>
<td style="text-align: left;">Revision surgery and subsequent survival states</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a>hip_tree_plot <span class="ot">&lt;-</span> <span class="fu">draw_decision_tree</span>(</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>  hip_tree_nodes,</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>  hip_tree_edges,</span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Published-inspired decision tree"</span>,</span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Initial prosthesis choice and perioperative outcomes"</span></span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-8"><a href="#cb7-8" aria-hidden="true" tabindex="-1"></a>hip_markov_plot <span class="ot">&lt;-</span> <span class="fu">draw_markov_diagram</span>(</span>
<span id="cb7-9"><a href="#cb7-9" aria-hidden="true" tabindex="-1"></a>  hip_markov_states,</span>
<span id="cb7-10"><a href="#cb7-10" aria-hidden="true" tabindex="-1"></a>  hip_markov_transitions,</span>
<span id="cb7-11"><a href="#cb7-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Published-inspired Markov model"</span>,</span>
<span id="cb7-12"><a href="#cb7-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Long-run revision and survival states"</span></span>
<span id="cb7-13"><a href="#cb7-13" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb7-14"><a href="#cb7-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-15"><a href="#cb7-15" aria-hidden="true" tabindex="-1"></a>hip_schematic <span class="ot">&lt;-</span> hip_tree_plot <span class="sc">+</span> hip_markov_plot <span class="sc">+</span></span>
<span id="cb7-16"><a href="#cb7-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">plot_layout</span>(<span class="at">widths =</span> <span class="fu">c</span>(<span class="fl">1.2</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb7-17"><a href="#cb7-17" aria-hidden="true" tabindex="-1"></a>  <span class="fu">plot_annotation</span>(</span>
<span id="cb7-18"><a href="#cb7-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Decision tree plus Markov diagram for a published hip-replacement modeling problem"</span>,</span>
<span id="cb7-19"><a href="#cb7-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Partial schematic reconstruction based on Briggs and colleagues' decision-analytic setting"</span></span>
<span id="cb7-20"><a href="#cb7-20" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb7-21"><a href="#cb7-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-22"><a href="#cb7-22" aria-hidden="true" tabindex="-1"></a>hip_schematic</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/decision-trees-and-markov-models_files/figure-html/unnamed-chunk-7-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The real-world figure demonstrates the practical point of this chapter. Decision-analytic models are often easier to trust when their architecture is visible. A reader can see where the initial one-off decision ends and where recurrent long-run states begin.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="75.7">
<h2 data-number="75.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">75.7</span> How to read the figure carefully</h2>
<p>These schematics are not parameter tables. Their purpose is structural clarity, not numerical completeness. The most important reading question is whether the figure helps the reader understand the model's logic: what happens once, what repeats, which health states exist, and which transitions are allowed.</p>
<p>A second point is that not every arrow should be interpreted as equally likely. The figure communicates allowable pathways, not necessarily their magnitude. Probabilities and costs usually belong in companion tables or in the model code itself.</p>
<p>A third point is that these figures should be honest about simplification. If a published model contains tunnel states, age-dependent transition risks, or subgroup-specific branches, a small chapter figure may reasonably omit some detail. But the omitted detail should not change the reader's understanding of the model's essential architecture.</p>
</section>
<section id="further-reading" class="level2" data-number="75.8">
<h2 data-number="75.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">75.8</span> Further reading</h2>
<p>Sonnenberg and Beck remain a foundational guide to why Markov models became important in medical decision making <span class="citation" data-cites="sonnenberg1993">Sonnenberg and Beck (<a href="#ref-sonnenberg1993" role="doc-biblioref">1993</a>)</span>. Briggs and Sculpher provide a classic health-economic introduction to state-transition models <span class="citation" data-cites="briggs1998markov">Briggs and Sculpher (<a href="#ref-briggs1998markov" role="doc-biblioref">1998</a>)</span>. For a concrete applied setting, Briggs and colleagues' hip-replacement analysis is a useful reminder that decision-analytic diagrams are often the fastest way to explain a cost-effectiveness model before turning to its results <span class="citation" data-cites="briggs1998thr">Briggs et al. (<a href="#ref-briggs1998thr" role="doc-biblioref">1998</a>)</span>; <span class="citation" data-cites="hunink2014">Hunink et al. (<a href="#ref-hunink2014" role="doc-biblioref">2014</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-briggs1998markov" class="csl-entry" role="listitem">
Briggs, Andrew, and Mark Sculpher. 1998. <span>"An Introduction to Markov Modelling for Economic Evaluation."</span> <em>Pharmacoeconomics</em> 13 (4): 397-409. <a href="https://doi.org/10.2165/00019053-199813040-00003">https://doi.org/10.2165/00019053-199813040-00003</a>.
</div>
<div id="ref-briggs1998thr" class="csl-entry" role="listitem">
Briggs, Andrew, Mark Sculpher, Andrew Britton, David Murray, and Ray Fitzpatrick. 1998. <span>"The Costs and Benefits of Primary Total Hip Replacement: How Likely Are New Prostheses to Be Cost-Effective?"</span> <em>International Journal of Technology Assessment in Health Care</em> 14 (4): 743-61. <a href="https://doi.org/10.1017/S0266462300012058">https://doi.org/10.1017/S0266462300012058</a>.
</div>
<div id="ref-hunink2014" class="csl-entry" role="listitem">
Hunink, M. G. Myriam, Milton C. Weinstein, Eve Wittenberg, Michael F. Drummond, Joseph S. Pliskin, John B. Wong, and Paul P. Glasziou. 2014. <em>Decision Making in Health and Medicine: Integrating Evidence and Values</em>. 2nd ed. Cambridge: Cambridge University Press.
</div>
<div id="ref-sonnenberg1993" class="csl-entry" role="listitem">
Sonnenberg, Frank A., and J. Robert Beck. 1993. <span>"Markov Models in Medical Decision Making: A Practical Guide."</span> <em>Medical Decision Making</em> 13 (4): 322-38. <a href="https://doi.org/10.1177/0272989X9301300409">https://doi.org/10.1177/0272989X9301300409</a>.
</div>
</div>
</section>
