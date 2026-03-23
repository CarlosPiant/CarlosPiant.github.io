---
title: "SEIR Models"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a compartment-trajectory figure for an SEIR model. The goal is to show how to visualize the flow of a population through the susceptible, exposed, infectious, and recovered states in a way that is..."
---
<p>This chapter builds a compartment-trajectory figure for an SEIR model. The goal is to show how to visualize the flow of a population through the susceptible, exposed, infectious, and recovered states in a way that is both epidemiologically interpretable and visually clear. SEIR figures are useful because they reveal something that a simple epidemic curve cannot: the latent build-up of exposed individuals before infectious prevalence peaks. Kermack and McKendrick established the broader compartmental logic, while Hethcote and Anderson and May explain why latent-state extensions matter in infectious-disease modeling <span class="citation" data-cites="kermack1927">Kermack and McKendrick (<a href="#ref-kermack1927" role="doc-biblioref">1927</a>)</span>; <span class="citation" data-cites="hethcote2000">Hethcote (<a href="#ref-hethcote2000" role="doc-biblioref">2000</a>)</span>; <span class="citation" data-cites="andersonmay1991">Anderson and May (<a href="#ref-andersonmay1991" role="doc-biblioref">1991</a>)</span>.</p>
<p>The figure we will build here is especially useful when the analyst wants to communicate timing. The exposed compartment peaks before the infectious compartment, the susceptible stock declines over the outbreak, and recovery accumulates only after transmission has already accelerated. A good SEIR plot turns those relationships into a readable visual narrative.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="62.1">
<h2 data-number="62.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">62.1</span> What the visualization is showing</h2>
<p>An SEIR trajectory plot is a multi-line figure in which each line represents the size of one compartment over time:</p>
<ol type="1">
<li>susceptible (<span class="math inline">\(S\)</span>),</li>
<li>exposed but not yet infectious (<span class="math inline">\(E\)</span>),</li>
<li>infectious (<span class="math inline">\(I\)</span>),</li>
<li>recovered or removed (<span class="math inline">\(R\)</span>).</li>
</ol>
<p>The figure is most useful when:</p>
<ol type="1">
<li>latent infection is substantively important,</li>
<li>the timing of peaks matters,</li>
<li>the analyst wants to distinguish observed illness from unobserved transmission stages.</li>
</ol>
<p>The reading rule is simple. Follow the lines from left to right and compare their turning points. The exposed line should typically rise before the infectious line, and the recovered line should accumulate later. That sequence is the main message of the visualization.</p>
</section>
<section id="step-1-create-a-synthetic-seir-epidemic" class="level2" data-number="62.2">
<h2 data-number="62.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-seir-epidemic"><span class="header-section-number">62.2</span> Step 1: Create a synthetic SEIR epidemic</h2>
<p>We begin with a synthetic outbreak in a closed population of 10,000 people. The model is deterministic and solved with ordinary differential equations. The purpose is not to estimate a full transmission model, but to create a smooth trajectory figure that makes the latent compartment visible.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(deSolve)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>format_numeric_table <span class="ot">&lt;-</span> <span class="cf">function</span>(df, <span class="at">digits =</span> <span class="dv">3</span>) {</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  numeric_cols <span class="ot">&lt;-</span> <span class="fu">vapply</span>(df, is.numeric, <span class="fu">logical</span>(<span class="dv">1</span>))</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  df[numeric_cols] <span class="ot">&lt;-</span> <span class="fu">lapply</span>(df[numeric_cols], round, <span class="at">digits =</span> digits)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  df</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>seir_ode <span class="ot">&lt;-</span> <span class="cf">function</span>(t, state, parms) {</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">with</span>(<span class="fu">as.list</span>(<span class="fu">c</span>(state, parms)), {</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>    N <span class="ot">&lt;-</span> S <span class="sc">+</span> E <span class="sc">+</span> I <span class="sc">+</span> R</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>    dS <span class="ot">&lt;-</span> <span class="sc">-</span>beta <span class="sc">*</span> S <span class="sc">*</span> I <span class="sc">/</span> N</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>    dE <span class="ot">&lt;-</span> beta <span class="sc">*</span> S <span class="sc">*</span> I <span class="sc">/</span> N <span class="sc">-</span> sigma <span class="sc">*</span> E</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>    dI <span class="ot">&lt;-</span> sigma <span class="sc">*</span> E <span class="sc">-</span> gamma <span class="sc">*</span> I</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>    dR <span class="ot">&lt;-</span> gamma <span class="sc">*</span> I</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>    <span class="fu">list</span>(<span class="fu">c</span>(dS, dE, dI, dR))</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>solve_seir <span class="ot">&lt;-</span> <span class="cf">function</span>(times, init, parms) {</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">as.data.frame</span>(</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>    deSolve<span class="sc">::</span><span class="fu">ode</span>(<span class="at">y =</span> init, <span class="at">times =</span> times, <span class="at">func =</span> seir_ode, <span class="at">parms =</span> parms)</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>make_seir_long <span class="ot">&lt;-</span> <span class="cf">function</span>(sol, <span class="at">scale_denominator =</span> <span class="cn">NULL</span>) {</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>  <span class="cf">if</span> (<span class="fu">is.null</span>(scale_denominator)) {</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>    scale_denominator <span class="ot">&lt;-</span> sol<span class="sc">$</span>S[<span class="dv">1</span>] <span class="sc">+</span> sol<span class="sc">$</span>E[<span class="dv">1</span>] <span class="sc">+</span> sol<span class="sc">$</span>I[<span class="dv">1</span>] <span class="sc">+</span> sol<span class="sc">$</span>R[<span class="dv">1</span>]</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>  <span class="fu">bind_rows</span>(</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(<span class="at">time =</span> sol<span class="sc">$</span>time, <span class="at">compartment =</span> <span class="st">"Susceptible"</span>, <span class="at">value =</span> sol<span class="sc">$</span>S <span class="sc">/</span> scale_denominator),</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(<span class="at">time =</span> sol<span class="sc">$</span>time, <span class="at">compartment =</span> <span class="st">"Exposed"</span>, <span class="at">value =</span> sol<span class="sc">$</span>E <span class="sc">/</span> scale_denominator),</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(<span class="at">time =</span> sol<span class="sc">$</span>time, <span class="at">compartment =</span> <span class="st">"Infectious"</span>, <span class="at">value =</span> sol<span class="sc">$</span>I <span class="sc">/</span> scale_denominator),</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(<span class="at">time =</span> sol<span class="sc">$</span>time, <span class="at">compartment =</span> <span class="st">"Recovered"</span>, <span class="at">value =</span> sol<span class="sc">$</span>R <span class="sc">/</span> scale_denominator)</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>plot_seir_trajectories <span class="ot">&lt;-</span> <span class="cf">function</span>(data, title, subtitle, y_label, palette) {</span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>(data, <span class="fu">aes</span>(<span class="at">x =</span> time, <span class="at">y =</span> value, <span class="at">color =</span> compartment)) <span class="sc">+</span></span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_line</span>(<span class="at">linewidth =</span> <span class="fl">1.15</span>) <span class="sc">+</span></span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>    <span class="fu">scale_color_manual</span>(<span class="at">values =</span> palette) <span class="sc">+</span></span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle,</span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="st">"Time"</span>,</span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> y_label,</span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="cn">NULL</span></span>
<span id="cb1-52"><a href="#cb1-52" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb1-53"><a href="#cb1-53" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb1-54"><a href="#cb1-54" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb1-55"><a href="#cb1-55" aria-hidden="true" tabindex="-1"></a>      <span class="at">legend.position =</span> <span class="st">"top"</span>,</span>
<span id="cb1-56"><a href="#cb1-56" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>()</span>
<span id="cb1-57"><a href="#cb1-57" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-58"><a href="#cb1-58" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>synthetic_init <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="at">S =</span> <span class="dv">9990</span>, <span class="at">E =</span> <span class="dv">5</span>, <span class="at">I =</span> <span class="dv">5</span>, <span class="at">R =</span> <span class="dv">0</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>synthetic_parms <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="at">beta =</span> <span class="fl">1.15</span>, <span class="at">sigma =</span> <span class="fl">0.35</span>, <span class="at">gamma =</span> <span class="fl">0.22</span>)</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>synthetic_times <span class="ot">&lt;-</span> <span class="dv">0</span><span class="sc">:</span><span class="dv">160</span></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>synthetic_sol <span class="ot">&lt;-</span> <span class="fu">solve_seir</span>(</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">times =</span> synthetic_times,</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">init =</span> synthetic_init,</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">parms =</span> synthetic_parms</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>synthetic_long <span class="ot">&lt;-</span> <span class="fu">make_seir_long</span>(synthetic_sol, <span class="at">scale_denominator =</span> <span class="dv">10000</span>)</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">quantity =</span> <span class="fu">c</span>(</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Peak exposed share"</span>,</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Peak infectious share"</span>,</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Day of exposed peak"</span>,</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Day of infectious peak"</span>,</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="st">"Final recovered share"</span></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">value =</span> <span class="fu">c</span>(</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>    <span class="fu">max</span>(synthetic_sol<span class="sc">$</span>E <span class="sc">/</span> <span class="dv">10000</span>),</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>    <span class="fu">max</span>(synthetic_sol<span class="sc">$</span>I <span class="sc">/</span> <span class="dv">10000</span>),</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>    synthetic_sol<span class="sc">$</span>time[<span class="fu">which.max</span>(synthetic_sol<span class="sc">$</span>E)],</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>    synthetic_sol<span class="sc">$</span>time[<span class="fu">which.max</span>(synthetic_sol<span class="sc">$</span>I)],</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>    <span class="fu">tail</span>(synthetic_sol<span class="sc">$</span>R <span class="sc">/</span> <span class="dv">10000</span>, <span class="dv">1</span>)</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_summary, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Key features of the synthetic SEIR trajectory"</span></span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Key features of the synthetic SEIR trajectory</caption>
<thead>
<tr class="header">
<th style="text-align: left;">quantity</th>
<th style="text-align: right;">value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Peak exposed share</td>
<td style="text-align: right;">0.231</td>
</tr>
<tr class="even">
<td style="text-align: left;">Peak infectious share</td>
<td style="text-align: right;">0.287</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Day of exposed peak</td>
<td style="text-align: right;">21.000</td>
</tr>
<tr class="even">
<td style="text-align: left;">Day of infectious peak</td>
<td style="text-align: right;">24.000</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Final recovered share</td>
<td style="text-align: right;">0.994</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-2-draw-the-synthetic-seir-trajectory-plot" class="level2" data-number="62.3">
<h2 data-number="62.3" class="anchored" data-anchor-id="step-2-draw-the-synthetic-seir-trajectory-plot"><span class="header-section-number">62.3</span> Step 2: Draw the synthetic SEIR trajectory plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>synthetic_palette <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Susceptible"</span> <span class="ot">=</span> <span class="st">"#3182bd"</span>,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Exposed"</span> <span class="ot">=</span> <span class="st">"#fd8d3c"</span>,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Infectious"</span> <span class="ot">=</span> <span class="st">"#cb181d"</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Recovered"</span> <span class="ot">=</span> <span class="st">"#31a354"</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>synthetic_plot <span class="ot">&lt;-</span> <span class="fu">plot_seir_trajectories</span>(</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  synthetic_long,</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"A compartment-trajectory plot makes the latent stage visible"</span>,</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Synthetic SEIR epidemic in a closed population of 10,000"</span>,</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">y_label =</span> <span class="st">"Share of population"</span>,</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">palette =</span> synthetic_palette</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>synthetic_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/seir-models_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure works because the exposed compartment is visually separated from the infectious compartment. A simple case curve would not show that hidden build-up at all. The timing gap between the exposed and infectious peaks is exactly the kind of structure that motivates an SEIR visualization instead of an SIR one.</p>
</section>
<section id="step-3-pair-the-figure-with-a-compact-summary-table" class="level2" data-number="62.4">
<h2 data-number="62.4" class="anchored" data-anchor-id="step-3-pair-the-figure-with-a-compact-summary-table"><span class="header-section-number">62.4</span> Step 3: Pair the figure with a compact summary table</h2>
<p>The trajectory plot is more informative when paired with a short table of turning points and endpoint quantities.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_turning_points <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">compartment =</span> <span class="fu">c</span>(<span class="st">"Exposed"</span>, <span class="st">"Infectious"</span>, <span class="st">"Recovered"</span>),</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">peak_or_final_day =</span> <span class="fu">c</span>(</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>    synthetic_sol<span class="sc">$</span>time[<span class="fu">which.max</span>(synthetic_sol<span class="sc">$</span>E)],</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>    synthetic_sol<span class="sc">$</span>time[<span class="fu">which.max</span>(synthetic_sol<span class="sc">$</span>I)],</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="fu">max</span>(synthetic_sol<span class="sc">$</span>time)</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">peak_or_final_share =</span> <span class="fu">c</span>(</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="fu">max</span>(synthetic_sol<span class="sc">$</span>E <span class="sc">/</span> <span class="dv">10000</span>),</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    <span class="fu">max</span>(synthetic_sol<span class="sc">$</span>I <span class="sc">/</span> <span class="dv">10000</span>),</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>    <span class="fu">tail</span>(synthetic_sol<span class="sc">$</span>R <span class="sc">/</span> <span class="dv">10000</span>, <span class="dv">1</span>)</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_turning_points, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Turning points highlighted by the synthetic SEIR figure"</span></span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Turning points highlighted by the synthetic SEIR figure</caption>
<thead>
<tr class="header">
<th style="text-align: left;">compartment</th>
<th style="text-align: right;">peak_or_final_day</th>
<th style="text-align: right;">peak_or_final_share</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Exposed</td>
<td style="text-align: right;">21</td>
<td style="text-align: right;">0.231</td>
</tr>
<tr class="even">
<td style="text-align: left;">Infectious</td>
<td style="text-align: right;">24</td>
<td style="text-align: right;">0.287</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Recovered</td>
<td style="text-align: right;">160</td>
<td style="text-align: right;">0.994</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The plot communicates the whole shape. The table names the peak values and peak days explicitly.</p>
</section>
<section id="step-4-create-a-real-world-seir-figure-from-a-published-outbreak" class="level2" data-number="62.5">
<h2 data-number="62.5" class="anchored" data-anchor-id="step-4-create-a-real-world-seir-figure-from-a-published-outbreak"><span class="header-section-number">62.5</span> Step 4: Create a real-world SEIR figure from a published outbreak</h2>
<p>For a real-world example, we use the famous 1978 English boarding-school influenza outbreak published in the <em>British Medical Journal</em> <span class="citation" data-cites="anonymous1978influenza">Anonymous (<a href="#ref-anonymous1978influenza" role="doc-biblioref">1978</a>)</span> and revisited by Avilov and colleagues <span class="citation" data-cites="avilov2024influenza">Avilov et al. (<a href="#ref-avilov2024influenza" role="doc-biblioref">2024</a>)</span>. The outbreak is valuable for teaching because it occurred in a relatively closed population and generated a compact daily epidemic curve. It is also a natural SEIR example because a latent period is epidemiologically plausible for influenza and affects the timing of visible illness.</p>
<p>This is a transparent partial replication rather than a full epidemiological re-estimation. We use the published daily counts of boys ill in bed as the observed series, fit a simple deterministic SEIR model by minimizing squared error in the infectious curve, and then use the fitted trajectory as the basis for a visualization. The goal is to build the figure, not to claim a definitive transmission estimate.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>boarding_outbreak <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">day =</span> <span class="dv">1</span><span class="sc">:</span><span class="dv">14</span>,</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">observed_cases =</span> <span class="fu">c</span>(<span class="dv">1</span>, <span class="dv">3</span>, <span class="dv">6</span>, <span class="dv">25</span>, <span class="dv">73</span>, <span class="dv">222</span>, <span class="dv">294</span>, <span class="dv">258</span>, <span class="dv">237</span>, <span class="dv">191</span>, <span class="dv">125</span>, <span class="dv">69</span>, <span class="dv">27</span>, <span class="dv">11</span>)</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>boarding_objective <span class="ot">&lt;-</span> <span class="cf">function</span>(theta) {</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>  beta <span class="ot">&lt;-</span> <span class="fu">exp</span>(theta[<span class="dv">1</span>])</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>  sigma <span class="ot">&lt;-</span> <span class="fu">exp</span>(theta[<span class="dv">2</span>])</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  gamma <span class="ot">&lt;-</span> <span class="fu">exp</span>(theta[<span class="dv">3</span>])</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>  sol <span class="ot">&lt;-</span> <span class="fu">solve_seir</span>(</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">times =</span> <span class="dv">0</span><span class="sc">:</span><span class="dv">14</span>,</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">init =</span> <span class="fu">c</span>(<span class="at">S =</span> <span class="dv">761</span>, <span class="at">E =</span> <span class="dv">1</span>, <span class="at">I =</span> <span class="dv">1</span>, <span class="at">R =</span> <span class="dv">0</span>),</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">parms =</span> <span class="fu">c</span>(<span class="at">beta =</span> beta, <span class="at">sigma =</span> sigma, <span class="at">gamma =</span> gamma)</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>  fitted_cases <span class="ot">&lt;-</span> <span class="fu">approx</span>(sol<span class="sc">$</span>time, sol<span class="sc">$</span>I, <span class="at">xout =</span> boarding_outbreak<span class="sc">$</span>day)<span class="sc">$</span>y</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">sum</span>((fitted_cases <span class="sc">-</span> boarding_outbreak<span class="sc">$</span>observed_cases)<span class="sc">^</span><span class="dv">2</span>)</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>boarding_fit <span class="ot">&lt;-</span> <span class="fu">optim</span>(</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">par =</span> <span class="fu">log</span>(<span class="fu">c</span>(<span class="fl">1.7</span>, <span class="fl">0.8</span>, <span class="fl">0.5</span>)),</span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>  <span class="at">fn =</span> boarding_objective,</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>  <span class="at">method =</span> <span class="st">"Nelder-Mead"</span>,</span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">control =</span> <span class="fu">list</span>(<span class="at">maxit =</span> <span class="dv">300</span>)</span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a>boarding_parms <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a>  <span class="at">beta =</span> <span class="fu">exp</span>(boarding_fit<span class="sc">$</span>par[<span class="dv">1</span>]),</span>
<span id="cb5-30"><a href="#cb5-30" aria-hidden="true" tabindex="-1"></a>  <span class="at">sigma =</span> <span class="fu">exp</span>(boarding_fit<span class="sc">$</span>par[<span class="dv">2</span>]),</span>
<span id="cb5-31"><a href="#cb5-31" aria-hidden="true" tabindex="-1"></a>  <span class="at">gamma =</span> <span class="fu">exp</span>(boarding_fit<span class="sc">$</span>par[<span class="dv">3</span>])</span>
<span id="cb5-32"><a href="#cb5-32" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-33"><a href="#cb5-33" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-34"><a href="#cb5-34" aria-hidden="true" tabindex="-1"></a>boarding_sol <span class="ot">&lt;-</span> <span class="fu">solve_seir</span>(</span>
<span id="cb5-35"><a href="#cb5-35" aria-hidden="true" tabindex="-1"></a>  <span class="at">times =</span> <span class="dv">0</span><span class="sc">:</span><span class="dv">14</span>,</span>
<span id="cb5-36"><a href="#cb5-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">init =</span> <span class="fu">c</span>(<span class="at">S =</span> <span class="dv">761</span>, <span class="at">E =</span> <span class="dv">1</span>, <span class="at">I =</span> <span class="dv">1</span>, <span class="at">R =</span> <span class="dv">0</span>),</span>
<span id="cb5-37"><a href="#cb5-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">parms =</span> boarding_parms</span>
<span id="cb5-38"><a href="#cb5-38" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-39"><a href="#cb5-39" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-40"><a href="#cb5-40" aria-hidden="true" tabindex="-1"></a>boarding_plot_df <span class="ot">&lt;-</span> <span class="fu">bind_rows</span>(</span>
<span id="cb5-41"><a href="#cb5-41" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">time =</span> boarding_sol<span class="sc">$</span>time, <span class="at">compartment =</span> <span class="st">"Exposed"</span>, <span class="at">value =</span> boarding_sol<span class="sc">$</span>E),</span>
<span id="cb5-42"><a href="#cb5-42" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">time =</span> boarding_sol<span class="sc">$</span>time, <span class="at">compartment =</span> <span class="st">"Infectious (model)"</span>, <span class="at">value =</span> boarding_sol<span class="sc">$</span>I),</span>
<span id="cb5-43"><a href="#cb5-43" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(<span class="at">time =</span> boarding_sol<span class="sc">$</span>time, <span class="at">compartment =</span> <span class="st">"Recovered"</span>, <span class="at">value =</span> boarding_sol<span class="sc">$</span>R)</span>
<span id="cb5-44"><a href="#cb5-44" aria-hidden="true" tabindex="-1"></a>) <span class="sc">|&gt;</span></span>
<span id="cb5-45"><a href="#cb5-45" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(<span class="at">compartment =</span> <span class="fu">factor</span>(compartment, <span class="at">levels =</span> <span class="fu">c</span>(<span class="st">"Exposed"</span>, <span class="st">"Infectious (model)"</span>, <span class="st">"Recovered"</span>)))</span>
<span id="cb5-46"><a href="#cb5-46" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-47"><a href="#cb5-47" aria-hidden="true" tabindex="-1"></a>boarding_compare <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-48"><a href="#cb5-48" aria-hidden="true" tabindex="-1"></a>  <span class="at">day =</span> boarding_outbreak<span class="sc">$</span>day,</span>
<span id="cb5-49"><a href="#cb5-49" aria-hidden="true" tabindex="-1"></a>  <span class="at">observed_cases =</span> boarding_outbreak<span class="sc">$</span>observed_cases,</span>
<span id="cb5-50"><a href="#cb5-50" aria-hidden="true" tabindex="-1"></a>  <span class="at">fitted_infectious =</span> <span class="fu">approx</span>(boarding_sol<span class="sc">$</span>time, boarding_sol<span class="sc">$</span>I, <span class="at">xout =</span> boarding_outbreak<span class="sc">$</span>day)<span class="sc">$</span>y</span>
<span id="cb5-51"><a href="#cb5-51" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-52"><a href="#cb5-52" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-53"><a href="#cb5-53" aria-hidden="true" tabindex="-1"></a>boarding_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-54"><a href="#cb5-54" aria-hidden="true" tabindex="-1"></a>  <span class="at">parameter =</span> <span class="fu">c</span>(<span class="st">"beta"</span>, <span class="st">"sigma"</span>, <span class="st">"gamma"</span>, <span class="st">"RMSE"</span>),</span>
<span id="cb5-55"><a href="#cb5-55" aria-hidden="true" tabindex="-1"></a>  <span class="at">value =</span> <span class="fu">c</span>(</span>
<span id="cb5-56"><a href="#cb5-56" aria-hidden="true" tabindex="-1"></a>    boarding_parms[<span class="st">"beta"</span>],</span>
<span id="cb5-57"><a href="#cb5-57" aria-hidden="true" tabindex="-1"></a>    boarding_parms[<span class="st">"sigma"</span>],</span>
<span id="cb5-58"><a href="#cb5-58" aria-hidden="true" tabindex="-1"></a>    boarding_parms[<span class="st">"gamma"</span>],</span>
<span id="cb5-59"><a href="#cb5-59" aria-hidden="true" tabindex="-1"></a>    <span class="fu">sqrt</span>(<span class="fu">mean</span>((boarding_compare<span class="sc">$</span>observed_cases <span class="sc">-</span> boarding_compare<span class="sc">$</span>fitted_infectious)<span class="sc">^</span><span class="dv">2</span>))</span>
<span id="cb5-60"><a href="#cb5-60" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-61"><a href="#cb5-61" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-62"><a href="#cb5-62" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-63"><a href="#cb5-63" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-64"><a href="#cb5-64" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(boarding_summary, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb5-65"><a href="#cb5-65" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Fitted parameters for the partial boarding-school SEIR approximation"</span></span>
<span id="cb5-66"><a href="#cb5-66" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Fitted parameters for the partial boarding-school SEIR approximation</caption>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">parameter</th>
<th style="text-align: right;">value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">beta</td>
<td style="text-align: left;">beta</td>
<td style="text-align: right;">2.742</td>
</tr>
<tr class="even">
<td style="text-align: left;">sigma</td>
<td style="text-align: left;">sigma</td>
<td style="text-align: right;">1.176</td>
</tr>
<tr class="odd">
<td style="text-align: left;">gamma</td>
<td style="text-align: left;">gamma</td>
<td style="text-align: right;">0.452</td>
</tr>
<tr class="even">
<td style="text-align: left;"></td>
<td style="text-align: left;">RMSE</td>
<td style="text-align: right;">19.103</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(boarding_compare, <span class="at">digits =</span> <span class="dv">2</span>),</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Observed and fitted daily infectious counts in the boarding-school outbreak"</span></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Observed and fitted daily infectious counts in the boarding-school outbreak</caption>
<thead>
<tr class="header">
<th style="text-align: right;">day</th>
<th style="text-align: right;">observed_cases</th>
<th style="text-align: right;">fitted_infectious</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2.54</td>
</tr>
<tr class="even">
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">6.95</td>
</tr>
<tr class="odd">
<td style="text-align: right;">3</td>
<td style="text-align: right;">6</td>
<td style="text-align: right;">18.70</td>
</tr>
<tr class="even">
<td style="text-align: right;">4</td>
<td style="text-align: right;">25</td>
<td style="text-align: right;">47.95</td>
</tr>
<tr class="odd">
<td style="text-align: right;">5</td>
<td style="text-align: right;">73</td>
<td style="text-align: right;">109.74</td>
</tr>
<tr class="even">
<td style="text-align: right;">6</td>
<td style="text-align: right;">222</td>
<td style="text-align: right;">201.50</td>
</tr>
<tr class="odd">
<td style="text-align: right;">7</td>
<td style="text-align: right;">294</td>
<td style="text-align: right;">272.42</td>
</tr>
<tr class="even">
<td style="text-align: right;">8</td>
<td style="text-align: right;">258</td>
<td style="text-align: right;">276.24</td>
</tr>
<tr class="odd">
<td style="text-align: right;">9</td>
<td style="text-align: right;">237</td>
<td style="text-align: right;">229.92</td>
</tr>
<tr class="even">
<td style="text-align: right;">10</td>
<td style="text-align: right;">191</td>
<td style="text-align: right;">170.60</td>
</tr>
<tr class="odd">
<td style="text-align: right;">11</td>
<td style="text-align: right;">125</td>
<td style="text-align: right;">118.81</td>
</tr>
<tr class="even">
<td style="text-align: right;">12</td>
<td style="text-align: right;">69</td>
<td style="text-align: right;">79.92</td>
</tr>
<tr class="odd">
<td style="text-align: right;">13</td>
<td style="text-align: right;">27</td>
<td style="text-align: right;">52.73</td>
</tr>
<tr class="even">
<td style="text-align: right;">14</td>
<td style="text-align: right;">11</td>
<td style="text-align: right;">34.42</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-5-draw-the-real-world-seir-figure" class="level2" data-number="62.6">
<h2 data-number="62.6" class="anchored" data-anchor-id="step-5-draw-the-real-world-seir-figure"><span class="header-section-number">62.6</span> Step 5: Draw the real-world SEIR figure</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a>boarding_palette <span class="ot">&lt;-</span> <span class="fu">c</span>(</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Exposed"</span> <span class="ot">=</span> <span class="st">"#fd8d3c"</span>,</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Infectious (model)"</span> <span class="ot">=</span> <span class="st">"#cb181d"</span>,</span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>  <span class="st">"Recovered"</span> <span class="ot">=</span> <span class="st">"#31a354"</span></span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a>boarding_plot <span class="ot">&lt;-</span> <span class="fu">ggplot</span>(boarding_plot_df, <span class="fu">aes</span>(<span class="at">x =</span> time, <span class="at">y =</span> value, <span class="at">color =</span> compartment)) <span class="sc">+</span></span>
<span id="cb7-8"><a href="#cb7-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(<span class="at">linewidth =</span> <span class="fl">1.15</span>) <span class="sc">+</span></span>
<span id="cb7-9"><a href="#cb7-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_point</span>(</span>
<span id="cb7-10"><a href="#cb7-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> boarding_compare,</span>
<span id="cb7-11"><a href="#cb7-11" aria-hidden="true" tabindex="-1"></a>    <span class="fu">aes</span>(<span class="at">x =</span> day, <span class="at">y =</span> observed_cases),</span>
<span id="cb7-12"><a href="#cb7-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">inherit.aes =</span> <span class="cn">FALSE</span>,</span>
<span id="cb7-13"><a href="#cb7-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#08519c"</span>,</span>
<span id="cb7-14"><a href="#cb7-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"white"</span>,</span>
<span id="cb7-15"><a href="#cb7-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">shape =</span> <span class="dv">21</span>,</span>
<span id="cb7-16"><a href="#cb7-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">stroke =</span> <span class="fl">0.9</span>,</span>
<span id="cb7-17"><a href="#cb7-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="fl">2.6</span></span>
<span id="cb7-18"><a href="#cb7-18" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb7-19"><a href="#cb7-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">scale_color_manual</span>(<span class="at">values =</span> boarding_palette) <span class="sc">+</span></span>
<span id="cb7-20"><a href="#cb7-20" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb7-21"><a href="#cb7-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"An SEIR trajectory plot can separate latent spread from observed illness"</span>,</span>
<span id="cb7-22"><a href="#cb7-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Partial boarding-school influenza reconstruction with observed daily cases overlaid as points"</span>,</span>
<span id="cb7-23"><a href="#cb7-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Day of outbreak"</span>,</span>
<span id="cb7-24"><a href="#cb7-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Number of individuals"</span>,</span>
<span id="cb7-25"><a href="#cb7-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="cn">NULL</span></span>
<span id="cb7-26"><a href="#cb7-26" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb7-27"><a href="#cb7-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb7-28"><a href="#cb7-28" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb7-29"><a href="#cb7-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">legend.position =</span> <span class="st">"top"</span>,</span>
<span id="cb7-30"><a href="#cb7-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>()</span>
<span id="cb7-31"><a href="#cb7-31" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb7-32"><a href="#cb7-32" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-33"><a href="#cb7-33" aria-hidden="true" tabindex="-1"></a>boarding_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/seir-models_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This real-world figure adds a useful layer that the synthetic example does not have: observed points. The points show the visible epidemic curve, while the model lines show the latent and cumulative compartments that are not directly observed. That is why SEIR plots can be so informative in outbreak communication.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="62.7">
<h2 data-number="62.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">62.7</span> How to read the figure carefully</h2>
<p>SEIR figures are easy to overread if the audience forgets which compartments are observed and which are inferred. In the boarding-school example, the points are observed daily illness counts, but the exposed line is not directly observed. It is a model-implied latent trajectory.</p>
<p>The figure is also sensitive to model structure. Different assumptions about the latent period, infectious period, and initial conditions can shift the trajectories visibly even when the fit to observed cases is similar. That is one reason the plot should be read as a structural summary, not as proof that the fitted parameter values are uniquely correct.</p>
<p>Finally, these figures work best when they are not overloaded. Adding too many compartments, intervention scenarios, and uncertainty bands at once can make the figure harder to interpret than the model itself. The best SEIR visualization usually emphasizes timing and shape first, then adds complexity only when it serves a real interpretive purpose.</p>
</section>
<section id="further-reading" class="level2" data-number="62.8">
<h2 data-number="62.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">62.8</span> Further reading</h2>
<p>Kermack and McKendrick remain the foundational reference for compartmental epidemic thinking <span class="citation" data-cites="kermack1927">Kermack and McKendrick (<a href="#ref-kermack1927" role="doc-biblioref">1927</a>)</span>. Hethcote provides a broad mathematical overview of infectious-disease compartment models <span class="citation" data-cites="hethcote2000">Hethcote (<a href="#ref-hethcote2000" role="doc-biblioref">2000</a>)</span>. Wearing, Rohani, and Keeling explain why latent periods and distributional assumptions matter in epidemic modeling, which is directly relevant to SEIR interpretation <span class="citation" data-cites="wearing2005">Wearing, Rohani, and Keeling (<a href="#ref-wearing2005" role="doc-biblioref">2005</a>)</span>. For the real-world outbreak used here, see the original <em>British Medical Journal</em> report and the modern revisit by Avilov and colleagues <span class="citation" data-cites="anonymous1978influenza">Anonymous (<a href="#ref-anonymous1978influenza" role="doc-biblioref">1978</a>)</span>; <span class="citation" data-cites="avilov2024influenza">Avilov et al. (<a href="#ref-avilov2024influenza" role="doc-biblioref">2024</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-andersonmay1991" class="csl-entry" role="listitem">
Anderson, Roy M., and Robert M. May. 1991. <em>Infectious Diseases of Humans: Dynamics and Control</em>. Oxford: Oxford University Press.
</div>
<div id="ref-anonymous1978influenza" class="csl-entry" role="listitem">
Anonymous. 1978. <span>"Influenza in a Boarding School."</span> <em>British Medical Journal</em> 1: 587. <a href="https://pmc.ncbi.nlm.nih.gov/articles/PMC1602702/">https://pmc.ncbi.nlm.nih.gov/articles/PMC1602702/</a>.
</div>
<div id="ref-avilov2024influenza" class="csl-entry" role="listitem">
Avilov, Nikita, Lucy van Dorp, Ian Hall, Helen Wearing, Philip O'Neill, and Matt Keeling. 2024. <span>"The 1978 English Boarding School Influenza Outbreak: Insights from a Simple Model."</span> <em>Journal of Biological Dynamics</em>. <a href="https://pubmed.ncbi.nlm.nih.gov/38837377/">https://pubmed.ncbi.nlm.nih.gov/38837377/</a>.
</div>
<div id="ref-hethcote2000" class="csl-entry" role="listitem">
Hethcote, Herbert W. 2000. <span>"The Mathematics of Infectious Diseases."</span> <em>SIAM Review</em> 42 (4): 599-653. <a href="https://doi.org/10.1137/S0036144500371907">https://doi.org/10.1137/S0036144500371907</a>.
</div>
<div id="ref-kermack1927" class="csl-entry" role="listitem">
Kermack, W. O., and A. G. McKendrick. 1927. <span>"A Contribution to the Mathematical Theory of Epidemics."</span> <em>Proceedings of the Royal Society A</em> 115 (772): 700-721. <a href="https://doi.org/10.1098/rspa.1927.0118">https://doi.org/10.1098/rspa.1927.0118</a>.
</div>
<div id="ref-wearing2005" class="csl-entry" role="listitem">
Wearing, Helen J., Pejman Rohani, and Matt J. Keeling. 2005. <span>"Appropriate Models for the Management of Infectious Diseases."</span> <em>PLoS Medicine</em> 2 (7): e174. <a href="https://doi.org/10.1371/journal.pmed.0020174">https://doi.org/10.1371/journal.pmed.0020174</a>.
</div>
</div>
</section>
