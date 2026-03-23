---
title: "Bland-Altman Plot"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a Bland-Altman plot for comparing two quantitative methods. The figure is useful because agreement is not the same thing as association. Two methods can be highly correlated and still disagree in..."
---
<p>This chapter creates a Bland-Altman plot for comparing two quantitative methods. The figure is useful because agreement is not the same thing as association. Two methods can be highly correlated and still disagree in ways that matter clinically or operationally. Bland and Altman made this point forcefully in their classic papers on method-comparison analysis <span class="citation" data-cites="bland1986">Bland and Altman (<a href="#ref-bland1986" role="doc-biblioref">1986</a>)</span>; <span class="citation" data-cites="bland1999">Bland and Altman (<a href="#ref-bland1999" role="doc-biblioref">1999</a>)</span>.</p>
<p>The figure is especially valuable in health research because new devices, assays, and prediction tools are often evaluated against existing ones. A scatterplot can show whether two methods move together, but it cannot show the average disagreement clearly or reveal whether the disagreement changes across the measurement range. A Bland-Altman plot is designed to answer exactly those questions.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="66.1">
<h2 data-number="66.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">66.1</span> What the visualization is showing</h2>
<p>We will build a Bland-Altman plot for two quantitative methods. The figure will show:</p>
<ol type="1">
<li>the average of the two methods on the horizontal axis,</li>
<li>the difference between the two methods on the vertical axis,</li>
<li>a horizontal line for the mean difference, often called the bias,</li>
<li>upper and lower limits of agreement.</li>
</ol>
<p>The standard limits of agreement are</p>
<p><span class="math display">\[
\bar{d} \pm 1.96 s_d,
\]</span></p>
<p>where <span class="math inline">\(\bar{d}\)</span> is the mean difference and <span class="math inline">\(s_d\)</span> is the standard deviation of the differences. If the differences are approximately Normal, about 95% of future paired differences should lie inside those limits.</p>
<p>The plot should be read with three questions in mind:</p>
<ol type="1">
<li>Is there systematic bias, meaning is the average difference far from 0?</li>
<li>Are the limits of agreement narrow enough to be acceptable for the application?</li>
<li>Does disagreement change with the size of the measurement, suggesting proportional bias or heteroskedasticity?</li>
</ol>
</section>
<section id="step-1-create-a-synthetic-paired-measurement-example" class="level2" data-number="66.2">
<h2 data-number="66.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-paired-measurement-example"><span class="header-section-number">66.2</span> Step 1: Create a synthetic paired-measurement example</h2>
<p>We will start with a synthetic example comparing a manual and an automated systolic blood pressure measurement taken on the same patients. The automated device is designed to be close to the manual reading but not identical. To make the plot informative, we build in a small positive bias and slightly wider disagreement at higher blood pressure values.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(MASS)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>n_patients <span class="ot">&lt;-</span> <span class="dv">180</span></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>true_sbp <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">132</span>, <span class="at">sd =</span> <span class="dv">16</span>)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>manual_sbp <span class="ot">&lt;-</span> true_sbp <span class="sc">+</span> <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="fl">4.5</span>)</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>automated_sbp <span class="ot">&lt;-</span> true_sbp <span class="sc">+</span> <span class="fl">2.0</span> <span class="sc">+</span> <span class="fl">0.03</span> <span class="sc">*</span> (true_sbp <span class="sc">-</span> <span class="fu">mean</span>(true_sbp)) <span class="sc">+</span></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rnorm</span>(n_patients, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="fl">5.5</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<p>Next we create a small helper that computes the quantities needed for the figure and for the summary table.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>prepare_bland_altman <span class="ot">&lt;-</span> <span class="cf">function</span>(method_a, method_b, label_a, label_b) {</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  plot_df <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">method_a =</span> method_a,</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">method_b =</span> method_b</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">|&gt;</span></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>      <span class="at">mean_measurement =</span> (method_a <span class="sc">+</span> method_b) <span class="sc">/</span> <span class="dv">2</span>,</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>      <span class="at">difference =</span> method_a <span class="sc">-</span> method_b</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  bias <span class="ot">&lt;-</span> <span class="fu">mean</span>(plot_df<span class="sc">$</span>difference)</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  sd_difference <span class="ot">&lt;-</span> <span class="fu">sd</span>(plot_df<span class="sc">$</span>difference)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>  upper_limit <span class="ot">&lt;-</span> bias <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> sd_difference</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  lower_limit <span class="ot">&lt;-</span> bias <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> sd_difference</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  summary_df <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">comparison =</span> <span class="fu">paste</span>(label_a, <span class="st">"minus"</span>, label_b),</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">sample_size =</span> <span class="fu">nrow</span>(plot_df),</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">mean_method_a =</span> <span class="fu">mean</span>(method_a),</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">mean_method_b =</span> <span class="fu">mean</span>(method_b),</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">bias =</span> bias,</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">sd_difference =</span> sd_difference,</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower_limit =</span> lower_limit,</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper_limit =</span> upper_limit,</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">proportion_outside =</span> <span class="fu">mean</span>(</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>      plot_df<span class="sc">$</span>difference <span class="sc">&lt;</span> lower_limit <span class="sc">|</span> plot_df<span class="sc">$</span>difference <span class="sc">&gt;</span> upper_limit</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">plot_df =</span> plot_df,</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>    <span class="at">summary_df =</span> summary_df,</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>    <span class="at">bias =</span> bias,</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>    <span class="at">lower_limit =</span> lower_limit,</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">upper_limit =</span> upper_limit,</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>    <span class="at">label_a =</span> label_a,</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>    <span class="at">label_b =</span> label_b</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>build_bland_altman_plot <span class="ot">&lt;-</span> <span class="cf">function</span>(ba_obj, title, subtitle, point_color) {</span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ggplot</span>(ba_obj<span class="sc">$</span>plot_df, <span class="fu">aes</span>(<span class="at">x =</span> mean_measurement, <span class="at">y =</span> difference)) <span class="sc">+</span></span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>    <span class="fu">annotate</span>(</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>      <span class="st">"rect"</span>,</span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>      <span class="at">xmin =</span> <span class="sc">-</span><span class="cn">Inf</span>,</span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a>      <span class="at">xmax =</span> <span class="cn">Inf</span>,</span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a>      <span class="at">ymin =</span> ba_obj<span class="sc">$</span>lower_limit,</span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>      <span class="at">ymax =</span> ba_obj<span class="sc">$</span>upper_limit,</span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a>      <span class="at">fill =</span> <span class="st">"#d9e6f2"</span>,</span>
<span id="cb2-50"><a href="#cb2-50" aria-hidden="true" tabindex="-1"></a>      <span class="at">alpha =</span> <span class="fl">0.55</span></span>
<span id="cb2-51"><a href="#cb2-51" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-52"><a href="#cb2-52" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_hline</span>(</span>
<span id="cb2-53"><a href="#cb2-53" aria-hidden="true" tabindex="-1"></a>      <span class="at">yintercept =</span> <span class="dv">0</span>,</span>
<span id="cb2-54"><a href="#cb2-54" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#7f7f7f"</span>,</span>
<span id="cb2-55"><a href="#cb2-55" aria-hidden="true" tabindex="-1"></a>      <span class="at">linetype =</span> <span class="st">"dotted"</span>,</span>
<span id="cb2-56"><a href="#cb2-56" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.6</span></span>
<span id="cb2-57"><a href="#cb2-57" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-58"><a href="#cb2-58" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_hline</span>(</span>
<span id="cb2-59"><a href="#cb2-59" aria-hidden="true" tabindex="-1"></a>      <span class="at">yintercept =</span> ba_obj<span class="sc">$</span>bias,</span>
<span id="cb2-60"><a href="#cb2-60" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#8c2d04"</span>,</span>
<span id="cb2-61"><a href="#cb2-61" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.9</span></span>
<span id="cb2-62"><a href="#cb2-62" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-63"><a href="#cb2-63" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_hline</span>(</span>
<span id="cb2-64"><a href="#cb2-64" aria-hidden="true" tabindex="-1"></a>      <span class="at">yintercept =</span> <span class="fu">c</span>(ba_obj<span class="sc">$</span>lower_limit, ba_obj<span class="sc">$</span>upper_limit),</span>
<span id="cb2-65"><a href="#cb2-65" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#1f4e79"</span>,</span>
<span id="cb2-66"><a href="#cb2-66" aria-hidden="true" tabindex="-1"></a>      <span class="at">linetype =</span> <span class="st">"dashed"</span>,</span>
<span id="cb2-67"><a href="#cb2-67" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.8</span></span>
<span id="cb2-68"><a href="#cb2-68" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-69"><a href="#cb2-69" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_point</span>(</span>
<span id="cb2-70"><a href="#cb2-70" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> point_color,</span>
<span id="cb2-71"><a href="#cb2-71" aria-hidden="true" tabindex="-1"></a>      <span class="at">alpha =</span> <span class="fl">0.75</span>,</span>
<span id="cb2-72"><a href="#cb2-72" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="dv">2</span></span>
<span id="cb2-73"><a href="#cb2-73" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-74"><a href="#cb2-74" aria-hidden="true" tabindex="-1"></a>    <span class="fu">geom_smooth</span>(</span>
<span id="cb2-75"><a href="#cb2-75" aria-hidden="true" tabindex="-1"></a>      <span class="at">method =</span> <span class="st">"loess"</span>,</span>
<span id="cb2-76"><a href="#cb2-76" aria-hidden="true" tabindex="-1"></a>      <span class="at">se =</span> <span class="cn">FALSE</span>,</span>
<span id="cb2-77"><a href="#cb2-77" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#2f2f2f"</span>,</span>
<span id="cb2-78"><a href="#cb2-78" aria-hidden="true" tabindex="-1"></a>      <span class="at">linewidth =</span> <span class="fl">0.7</span></span>
<span id="cb2-79"><a href="#cb2-79" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-80"><a href="#cb2-80" aria-hidden="true" tabindex="-1"></a>    <span class="fu">annotate</span>(</span>
<span id="cb2-81"><a href="#cb2-81" aria-hidden="true" tabindex="-1"></a>      <span class="st">"text"</span>,</span>
<span id="cb2-82"><a href="#cb2-82" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="fu">max</span>(ba_obj<span class="sc">$</span>plot_df<span class="sc">$</span>mean_measurement),</span>
<span id="cb2-83"><a href="#cb2-83" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> ba_obj<span class="sc">$</span>bias,</span>
<span id="cb2-84"><a href="#cb2-84" aria-hidden="true" tabindex="-1"></a>      <span class="at">label =</span> <span class="fu">sprintf</span>(<span class="st">"Bias = %.2f"</span>, ba_obj<span class="sc">$</span>bias),</span>
<span id="cb2-85"><a href="#cb2-85" aria-hidden="true" tabindex="-1"></a>      <span class="at">hjust =</span> <span class="fl">1.05</span>,</span>
<span id="cb2-86"><a href="#cb2-86" aria-hidden="true" tabindex="-1"></a>      <span class="at">vjust =</span> <span class="sc">-</span><span class="fl">0.8</span>,</span>
<span id="cb2-87"><a href="#cb2-87" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.5</span>,</span>
<span id="cb2-88"><a href="#cb2-88" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#8c2d04"</span></span>
<span id="cb2-89"><a href="#cb2-89" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-90"><a href="#cb2-90" aria-hidden="true" tabindex="-1"></a>    <span class="fu">annotate</span>(</span>
<span id="cb2-91"><a href="#cb2-91" aria-hidden="true" tabindex="-1"></a>      <span class="st">"text"</span>,</span>
<span id="cb2-92"><a href="#cb2-92" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="fu">max</span>(ba_obj<span class="sc">$</span>plot_df<span class="sc">$</span>mean_measurement),</span>
<span id="cb2-93"><a href="#cb2-93" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> ba_obj<span class="sc">$</span>upper_limit,</span>
<span id="cb2-94"><a href="#cb2-94" aria-hidden="true" tabindex="-1"></a>      <span class="at">label =</span> <span class="fu">sprintf</span>(<span class="st">"Upper LOA = %.2f"</span>, ba_obj<span class="sc">$</span>upper_limit),</span>
<span id="cb2-95"><a href="#cb2-95" aria-hidden="true" tabindex="-1"></a>      <span class="at">hjust =</span> <span class="fl">1.05</span>,</span>
<span id="cb2-96"><a href="#cb2-96" aria-hidden="true" tabindex="-1"></a>      <span class="at">vjust =</span> <span class="sc">-</span><span class="fl">0.8</span>,</span>
<span id="cb2-97"><a href="#cb2-97" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.4</span>,</span>
<span id="cb2-98"><a href="#cb2-98" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#1f4e79"</span></span>
<span id="cb2-99"><a href="#cb2-99" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-100"><a href="#cb2-100" aria-hidden="true" tabindex="-1"></a>    <span class="fu">annotate</span>(</span>
<span id="cb2-101"><a href="#cb2-101" aria-hidden="true" tabindex="-1"></a>      <span class="st">"text"</span>,</span>
<span id="cb2-102"><a href="#cb2-102" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="fu">max</span>(ba_obj<span class="sc">$</span>plot_df<span class="sc">$</span>mean_measurement),</span>
<span id="cb2-103"><a href="#cb2-103" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> ba_obj<span class="sc">$</span>lower_limit,</span>
<span id="cb2-104"><a href="#cb2-104" aria-hidden="true" tabindex="-1"></a>      <span class="at">label =</span> <span class="fu">sprintf</span>(<span class="st">"Lower LOA = %.2f"</span>, ba_obj<span class="sc">$</span>lower_limit),</span>
<span id="cb2-105"><a href="#cb2-105" aria-hidden="true" tabindex="-1"></a>      <span class="at">hjust =</span> <span class="fl">1.05</span>,</span>
<span id="cb2-106"><a href="#cb2-106" aria-hidden="true" tabindex="-1"></a>      <span class="at">vjust =</span> <span class="fl">1.4</span>,</span>
<span id="cb2-107"><a href="#cb2-107" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="fl">3.4</span>,</span>
<span id="cb2-108"><a href="#cb2-108" aria-hidden="true" tabindex="-1"></a>      <span class="at">color =</span> <span class="st">"#1f4e79"</span></span>
<span id="cb2-109"><a href="#cb2-109" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-110"><a href="#cb2-110" aria-hidden="true" tabindex="-1"></a>    <span class="fu">labs</span>(</span>
<span id="cb2-111"><a href="#cb2-111" aria-hidden="true" tabindex="-1"></a>      <span class="at">title =</span> title,</span>
<span id="cb2-112"><a href="#cb2-112" aria-hidden="true" tabindex="-1"></a>      <span class="at">subtitle =</span> subtitle,</span>
<span id="cb2-113"><a href="#cb2-113" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="st">"Mean of the two methods"</span>,</span>
<span id="cb2-114"><a href="#cb2-114" aria-hidden="true" tabindex="-1"></a>      <span class="at">y =</span> <span class="fu">paste</span>(ba_obj<span class="sc">$</span>label_a, <span class="st">"minus"</span>, ba_obj<span class="sc">$</span>label_b)</span>
<span id="cb2-115"><a href="#cb2-115" aria-hidden="true" tabindex="-1"></a>    ) <span class="sc">+</span></span>
<span id="cb2-116"><a href="#cb2-116" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb2-117"><a href="#cb2-117" aria-hidden="true" tabindex="-1"></a>    <span class="fu">theme</span>(</span>
<span id="cb2-118"><a href="#cb2-118" aria-hidden="true" tabindex="-1"></a>      <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>()</span>
<span id="cb2-119"><a href="#cb2-119" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb2-120"><a href="#cb2-120" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>synthetic_ba <span class="ot">&lt;-</span> <span class="fu">prepare_bland_altman</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">method_a =</span> automated_sbp,</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">method_b =</span> manual_sbp,</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_a =</span> <span class="st">"Automated SBP"</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_b =</span> <span class="st">"Manual SBP"</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> synthetic_ba<span class="sc">$</span>summary_df <span class="sc">|&gt;</span></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">across</span>(<span class="fu">where</span>(is.numeric), <span class="sc">~</span> <span class="fu">round</span>(.x, <span class="dv">3</span>))</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>  synthetic_summary,</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary statistics for the synthetic Bland-Altman example"</span></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary statistics for the synthetic Bland-Altman example</caption>
<colgroup>
<col style="width: 23%">
<col style="width: 8%">
<col style="width: 10%">
<col style="width: 10%">
<col style="width: 4%">
<col style="width: 10%">
<col style="width: 8%">
<col style="width: 8%">
<col style="width: 14%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">comparison</th>
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">mean_method_a</th>
<th style="text-align: right;">mean_method_b</th>
<th style="text-align: right;">bias</th>
<th style="text-align: right;">sd_difference</th>
<th style="text-align: right;">lower_limit</th>
<th style="text-align: right;">upper_limit</th>
<th style="text-align: right;">proportion_outside</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Automated SBP minus Manual SBP</td>
<td style="text-align: right;">180</td>
<td style="text-align: right;">134.188</td>
<td style="text-align: right;">132.113</td>
<td style="text-align: right;">2.075</td>
<td style="text-align: right;">7.552</td>
<td style="text-align: right;">-12.727</td>
<td style="text-align: right;">16.877</td>
<td style="text-align: right;">0.05</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The summary already says something important. The average automated reading is slightly higher than the manual one, so the bias is positive. The limits of agreement show how wide the method-to-method differences can be even when the average bias is modest.</p>
</section>
<section id="step-2-draw-the-synthetic-bland-altman-plot" class="level2" data-number="66.3">
<h2 data-number="66.3" class="anchored" data-anchor-id="step-2-draw-the-synthetic-bland-altman-plot"><span class="header-section-number">66.3</span> Step 2: Draw the synthetic Bland-Altman plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_plot <span class="ot">&lt;-</span> <span class="fu">build_bland_altman_plot</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  synthetic_ba,</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Bland-Altman plot for synthetic systolic blood pressure measurements"</span>,</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"The shaded band marks the 95% limits of agreement; the smooth curve helps reveal trend"</span>,</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">point_color =</span> <span class="st">"#2a6f97"</span></span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>synthetic_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/bland-altman-plot_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure should be interpreted point by point. Each point is one patient. If the point lies above 0, the automated device reads higher than the manual method for that patient. If it lies below 0, the automated device reads lower. The dashed lines show the empirical limits of agreement, and the solid line shows the average bias.</p>
<p>Notice that the smooth curve is not flat. That signals a mild tendency for disagreement to become more positive at higher blood pressure values. The plot therefore shows not just average disagreement, but how disagreement behaves across the range of measurements.</p>
</section>
<section id="step-3-create-a-real-world-bland-altman-plot-from-a-public-prediction-dataset" class="level2" data-number="66.4">
<h2 data-number="66.4" class="anchored" data-anchor-id="step-3-create-a-real-world-bland-altman-plot-from-a-public-prediction-dataset"><span class="header-section-number">66.4</span> Step 3: Create a real-world Bland-Altman plot from a public prediction dataset</h2>
<p>For a real-world example, we will use the public <code>Pima.tr</code> and <code>Pima.te</code> diabetes datasets from <code>MASS</code>, linked to the diabetes-classification study by Smith and colleagues <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>. We will fit two probability models in the training sample, logistic regression and linear discriminant analysis, then compare their predicted diabetes risks in the test sample using a Bland-Altman plot.</p>
<p>This is a transparent partial application. The original Smith paper was not published with a Bland-Altman figure, and the two fitted models below are a teaching adaptation. But the public data provide a clear real-world setting for comparing two quantitative methods that estimate the same underlying quantity: patient-level diabetes risk.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.tr"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.te"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>pima_logit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  type <span class="sc">~</span> npreg <span class="sc">+</span> glu <span class="sc">+</span> bp <span class="sc">+</span> skin <span class="sc">+</span> bmi <span class="sc">+</span> ped <span class="sc">+</span> age,</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> Pima.tr,</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>pima_lda <span class="ot">&lt;-</span> MASS<span class="sc">::</span><span class="fu">lda</span>(</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>  type <span class="sc">~</span> npreg <span class="sc">+</span> glu <span class="sc">+</span> bp <span class="sc">+</span> skin <span class="sc">+</span> bmi <span class="sc">+</span> ped <span class="sc">+</span> age,</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> Pima.tr</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>logit_prob <span class="ot">&lt;-</span> <span class="fu">predict</span>(pima_logit, <span class="at">newdata =</span> Pima.te, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>lda_prob <span class="ot">&lt;-</span> <span class="fu">predict</span>(pima_lda, <span class="at">newdata =</span> Pima.te)<span class="sc">$</span>posterior[, <span class="st">"Yes"</span>]</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>real_ba <span class="ot">&lt;-</span> <span class="fu">prepare_bland_altman</span>(</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">method_a =</span> logit_prob,</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">method_b =</span> lda_prob,</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_a =</span> <span class="st">"Logistic risk"</span>,</span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">label_b =</span> <span class="st">"LDA risk"</span></span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>real_summary <span class="ot">&lt;-</span> real_ba<span class="sc">$</span>summary_df <span class="sc">|&gt;</span></span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>    dplyr<span class="sc">::</span><span class="fu">across</span>(<span class="fu">where</span>(is.numeric), <span class="sc">~</span> <span class="fu">round</span>(.x, <span class="dv">3</span>))</span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-30"><a href="#cb5-30" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-31"><a href="#cb5-31" aria-hidden="true" tabindex="-1"></a>  real_summary,</span>
<span id="cb5-32"><a href="#cb5-32" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Agreement summary for logistic and LDA diabetes-risk predictions in the public Pima test sample"</span></span>
<span id="cb5-33"><a href="#cb5-33" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Agreement summary for logistic and LDA diabetes-risk predictions in the public Pima test sample</caption>
<colgroup>
<col style="width: 21%">
<col style="width: 9%">
<col style="width: 10%">
<col style="width: 10%">
<col style="width: 4%">
<col style="width: 10%">
<col style="width: 9%">
<col style="width: 9%">
<col style="width: 14%">
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">comparison</th>
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">mean_method_a</th>
<th style="text-align: right;">mean_method_b</th>
<th style="text-align: right;">bias</th>
<th style="text-align: right;">sd_difference</th>
<th style="text-align: right;">lower_limit</th>
<th style="text-align: right;">upper_limit</th>
<th style="text-align: right;">proportion_outside</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Logistic risk minus LDA risk</td>
<td style="text-align: right;">332</td>
<td style="text-align: right;">0.337</td>
<td style="text-align: right;">0.328</td>
<td style="text-align: right;">0.009</td>
<td style="text-align: right;">0.025</td>
<td style="text-align: right;">-0.041</td>
<td style="text-align: right;">0.059</td>
<td style="text-align: right;">0.06</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>real_plot <span class="ot">&lt;-</span> <span class="fu">build_bland_altman_plot</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  real_ba,</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">title =</span> <span class="st">"Bland-Altman plot for two diabetes-risk prediction methods"</span>,</span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">subtitle =</span> <span class="st">"Predicted probabilities from logistic regression and linear discriminant analysis on the public Pima test sample"</span>,</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">point_color =</span> <span class="st">"#287271"</span></span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>real_plot</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/bland-altman-plot_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This real-world plot answers a different question from discrimination plots such as ROC curves. It does not ask which model ranks patients better. It asks whether the two methods give similar probability estimates for the same patients. If the bias is near 0 but the limits of agreement are still wide, then the models agree on average but can disagree materially for individual patients.</p>
<p>In this example, the methods tend to agree reasonably well in the middle of the risk range but can diverge more at higher average predicted risk. That pattern matters if the probabilities will be used for decision thresholds, risk communication, or clinical triage.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="66.5">
<h2 data-number="66.5" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">66.5</span> How to read the figure carefully</h2>
<p>A Bland-Altman plot is most useful when the reader already has some idea of what difference is substantively tolerable. Statistical limits alone do not say whether agreement is good enough. A difference of 5 units might be trivial for one application and unacceptable for another.</p>
<p>The plot should also be read for structure, not just for the width of the band. Three patterns are especially important:</p>
<ol type="1">
<li>a nonzero mean difference, which signals systematic bias,</li>
<li>a trend in the smooth curve, which suggests proportional bias,</li>
<li>a widening spread, which suggests heteroskedastic disagreement.</li>
</ol>
<p>When those patterns appear, the analyst may need a transformation, a different comparison scale, or a model that allows disagreement to vary with the level of the measurement.</p>
</section>
<section id="further-reading" class="level2" data-number="66.6">
<h2 data-number="66.6" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">66.6</span> Further reading</h2>
<p>Bland and Altman's original papers remain the essential starting point because they explain both the logic of the plot and the difference between agreement and correlation <span class="citation" data-cites="bland1986">Bland and Altman (<a href="#ref-bland1986" role="doc-biblioref">1986</a>)</span>; <span class="citation" data-cites="bland1999">Bland and Altman (<a href="#ref-bland1999" role="doc-biblioref">1999</a>)</span>. The Pima diabetes dataset comes from the work of Smith and colleagues and provides a convenient public setting for illustrating agreement between quantitative prediction methods <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-bland1986" class="csl-entry" role="listitem">
Bland, J. Martin, and Douglas G. Altman. 1986. <span>"Statistical Methods for Assessing Agreement Between Two Methods of Clinical Measurement."</span> <em>The Lancet</em> 327 (8476): 307-10. <a href="https://doi.org/10.1016/S0140-6736(86)90837-8">https://doi.org/10.1016/S0140-6736(86)90837-8</a>.
</div>
<div id="ref-bland1999" class="csl-entry" role="listitem">
---. 1999. <span>"Measuring Agreement in Method Comparison Studies."</span> <em>Statistical Methods in Medical Research</em> 8 (2): 135-60. <a href="https://doi.org/10.1177/096228029900800204">https://doi.org/10.1177/096228029900800204</a>.
</div>
<div id="ref-smith1988" class="csl-entry" role="listitem">
Smith, J. W., J. E. Everhart, W. C. Dickson, W. C. Knowler, and R. S. Johannes. 1988. <span>"Using the <span>ADAP</span> Learning Algorithm to Forecast the Onset of Diabetes Mellitus."</span> In <em>Proceedings of the Symposium on Computer Applications in Medical Care</em>, 261-65.
</div>
</div>
</section>
