---
title: "Calibration Plots"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a calibration plot for a binary risk-prediction model. The point of the figure is not to ask whether a model separates cases from non-cases well, but whether the probabilities it reports are..."
---
<p>This chapter creates a calibration plot for a binary risk-prediction model. The point of the figure is not to ask whether a model separates cases from non-cases well, but whether the probabilities it reports are numerically trustworthy. A model that predicts a 30% risk should produce events in roughly 30% of similar observations. That is the basic idea of calibration, and it is one of the most important but most frequently neglected parts of predictive modeling <span class="citation" data-cites="vancalster2019">Van Calster et al. (<a href="#ref-vancalster2019" role="doc-biblioref">2019</a>)</span>. The example here uses the Pima diabetes data distributed with <code>MASS</code>, which originate from the diabetes-prediction application described by Smith and coauthors <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>.</p>
<p>The visualization we will build combines two complementary elements. First, it shows grouped observed-versus-predicted risks across bins of predicted probability. Second, it overlays a smooth calibration curve and the 45-degree ideal line. Together, these pieces tell the reader whether the model is systematically underpredicting or overpredicting risk.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="64.1">
<h2 data-number="64.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">64.1</span> What the visualization is showing</h2>
<p>We will fit a logistic regression model in the training data and then evaluate calibration in a separate test set. The x-axis of the plot will show predicted risk. The y-axis will show the observed event frequency. Perfect calibration would place every point on the 45-degree line.</p>
</section>
<section id="step-1-fit-a-prediction-model-and-obtain-test-set-probabilities" class="level2" data-number="64.2">
<h2 data-number="64.2" class="anchored" data-anchor-id="step-1-fit-a-prediction-model-and-obtain-test-set-probabilities"><span class="header-section-number">64.2</span> Step 1: Fit a prediction model and obtain test-set probabilities</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.tr"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.te"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>calibration_fit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>  type <span class="sc">~</span> npreg <span class="sc">+</span> glu <span class="sc">+</span> bp <span class="sc">+</span> skin <span class="sc">+</span> bmi <span class="sc">+</span> ped <span class="sc">+</span> age,</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> Pima.tr,</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>predicted_risk <span class="ot">&lt;-</span> <span class="fu">predict</span>(calibration_fit, <span class="at">newdata =</span> Pima.te, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>observed_outcome <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(Pima.te<span class="sc">$</span>type <span class="sc">==</span> <span class="st">"Yes"</span>)</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>calibration_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">predicted_risk =</span> predicted_risk,</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">observed_outcome =</span> observed_outcome</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>summary_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(calibration_data),</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">event_rate =</span> <span class="fu">mean</span>(calibration_data<span class="sc">$</span>observed_outcome),</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_predicted_risk =</span> <span class="fu">mean</span>(calibration_data<span class="sc">$</span>predicted_risk),</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">brier_score =</span> <span class="fu">mean</span>((calibration_data<span class="sc">$</span>predicted_risk <span class="sc">-</span> calibration_data<span class="sc">$</span>observed_outcome)<span class="sc">^</span><span class="dv">2</span>)</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>summary_table[, <span class="fu">c</span>(<span class="st">"event_rate"</span>, <span class="st">"mean_predicted_risk"</span>, <span class="st">"brier_score"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(summary_table[, <span class="fu">c</span>(<span class="st">"event_rate"</span>, <span class="st">"mean_predicted_risk"</span>, <span class="st">"brier_score"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>  summary_table,</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the prediction sample used for the calibration plot"</span></span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the prediction sample used for the calibration plot</caption>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">event_rate</th>
<th style="text-align: right;">mean_predicted_risk</th>
<th style="text-align: right;">brier_score</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">332</td>
<td style="text-align: right;">0.328</td>
<td style="text-align: right;">0.337</td>
<td style="text-align: right;">0.139</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The Brier score is not itself a calibration plot, but it is a useful companion number because it summarizes probabilistic accuracy in a single value <span class="citation" data-cites="brier1950">Brier (<a href="#ref-brier1950" role="doc-biblioref">1950</a>)</span>.</p>
</section>
<section id="step-2-build-grouped-calibration-points" class="level2" data-number="64.3">
<h2 data-number="64.3" class="anchored" data-anchor-id="step-2-build-grouped-calibration-points"><span class="header-section-number">64.3</span> Step 2: Build grouped calibration points</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>rank_id <span class="ot">&lt;-</span> <span class="fu">rank</span>(calibration_data<span class="sc">$</span>predicted_risk, <span class="at">ties.method =</span> <span class="st">"first"</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>calibration_data<span class="sc">$</span>bin <span class="ot">&lt;-</span> <span class="fu">cut</span>(</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  rank_id,</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">breaks =</span> <span class="fu">quantile</span>(rank_id, <span class="at">probs =</span> <span class="fu">seq</span>(<span class="dv">0</span>, <span class="dv">1</span>, <span class="fl">0.1</span>)),</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">include.lowest =</span> <span class="cn">TRUE</span></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>grouped_calibration <span class="ot">&lt;-</span> <span class="fu">aggregate</span>(</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">cbind</span>(predicted_risk, observed_outcome) <span class="sc">~</span> bin,</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> calibration_data,</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">FUN =</span> mean</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>grouped_calibration<span class="sc">$</span>count <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(<span class="fu">table</span>(calibration_data<span class="sc">$</span>bin))</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>grouped_calibration<span class="sc">$</span>predicted_risk <span class="ot">&lt;-</span> <span class="fu">round</span>(grouped_calibration<span class="sc">$</span>predicted_risk, <span class="dv">3</span>)</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>grouped_calibration<span class="sc">$</span>observed_outcome <span class="ot">&lt;-</span> <span class="fu">round</span>(grouped_calibration<span class="sc">$</span>observed_outcome, <span class="dv">3</span>)</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>  grouped_calibration,</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Grouped calibration table by deciles of predicted risk"</span></span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Grouped calibration table by deciles of predicted risk</caption>
<thead>
<tr class="header">
<th style="text-align: left;">bin</th>
<th style="text-align: right;">predicted_risk</th>
<th style="text-align: right;">observed_outcome</th>
<th style="text-align: right;">count</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">[1,34.1]</td>
<td style="text-align: right;">0.029</td>
<td style="text-align: right;">0.000</td>
<td style="text-align: right;">34</td>
</tr>
<tr class="even">
<td style="text-align: left;">(34.1,67.2]</td>
<td style="text-align: right;">0.057</td>
<td style="text-align: right;">0.030</td>
<td style="text-align: right;">33</td>
</tr>
<tr class="odd">
<td style="text-align: left;">(67.2,100]</td>
<td style="text-align: right;">0.094</td>
<td style="text-align: right;">0.030</td>
<td style="text-align: right;">33</td>
</tr>
<tr class="even">
<td style="text-align: left;">(100,133]</td>
<td style="text-align: right;">0.136</td>
<td style="text-align: right;">0.182</td>
<td style="text-align: right;">33</td>
</tr>
<tr class="odd">
<td style="text-align: left;">(133,166]</td>
<td style="text-align: right;">0.191</td>
<td style="text-align: right;">0.121</td>
<td style="text-align: right;">33</td>
</tr>
<tr class="even">
<td style="text-align: left;">(166,200]</td>
<td style="text-align: right;">0.276</td>
<td style="text-align: right;">0.364</td>
<td style="text-align: right;">33</td>
</tr>
<tr class="odd">
<td style="text-align: left;">(200,233]</td>
<td style="text-align: right;">0.399</td>
<td style="text-align: right;">0.424</td>
<td style="text-align: right;">33</td>
</tr>
<tr class="even">
<td style="text-align: left;">(233,266]</td>
<td style="text-align: right;">0.548</td>
<td style="text-align: right;">0.515</td>
<td style="text-align: right;">33</td>
</tr>
<tr class="odd">
<td style="text-align: left;">(266,299]</td>
<td style="text-align: right;">0.733</td>
<td style="text-align: right;">0.727</td>
<td style="text-align: right;">33</td>
</tr>
<tr class="even">
<td style="text-align: left;">(299,332]</td>
<td style="text-align: right;">0.901</td>
<td style="text-align: right;">0.882</td>
<td style="text-align: right;">34</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>Grouped calibration points are easy to explain because they average predictions and outcomes within risk bins. They are simple and intuitive, though they should not be mistaken for the full story.</p>
</section>
<section id="step-3-add-a-smooth-calibration-curve" class="level2" data-number="64.4">
<h2 data-number="64.4" class="anchored" data-anchor-id="step-3-add-a-smooth-calibration-curve"><span class="header-section-number">64.4</span> Step 3: Add a smooth calibration curve</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>smooth_grid <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">predicted_risk =</span> <span class="fu">seq</span>(</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>    <span class="fu">min</span>(calibration_data<span class="sc">$</span>predicted_risk),</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    <span class="fu">max</span>(calibration_data<span class="sc">$</span>predicted_risk),</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">length.out =</span> <span class="dv">200</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>loess_fit <span class="ot">&lt;-</span> <span class="fu">loess</span>(</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>  observed_outcome <span class="sc">~</span> predicted_risk,</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> calibration_data,</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">span =</span> <span class="fl">0.75</span></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>smooth_grid<span class="sc">$</span>observed_risk <span class="ot">&lt;-</span> <span class="fu">pmin</span>(</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">pmax</span>(<span class="fu">predict</span>(loess_fit, <span class="at">newdata =</span> smooth_grid), <span class="dv">0</span>),</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  <span class="dv">1</span></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>() <span class="sc">+</span></span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_abline</span>(</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">intercept =</span> <span class="dv">0</span>,</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">slope =</span> <span class="dv">1</span>,</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#8b5e34"</span>,</span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.8</span></span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(</span>
<span id="cb3-29"><a href="#cb3-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> smooth_grid,</span>
<span id="cb3-30"><a href="#cb3-30" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">y =</span> observed_risk),</span>
<span id="cb3-31"><a href="#cb3-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#264653"</span>,</span>
<span id="cb3-32"><a href="#cb3-32" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="dv">1</span></span>
<span id="cb3-33"><a href="#cb3-33" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-34"><a href="#cb3-34" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_point</span>(</span>
<span id="cb3-35"><a href="#cb3-35" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> grouped_calibration,</span>
<span id="cb3-36"><a href="#cb3-36" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> predicted_risk, <span class="at">y =</span> observed_outcome, <span class="at">size =</span> count),</span>
<span id="cb3-37"><a href="#cb3-37" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#2a9d8f"</span>,</span>
<span id="cb3-38"><a href="#cb3-38" aria-hidden="true" tabindex="-1"></a>    <span class="at">alpha =</span> <span class="fl">0.85</span></span>
<span id="cb3-39"><a href="#cb3-39" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-40"><a href="#cb3-40" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb3-41"><a href="#cb3-41" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Calibration plot for diabetes risk predictions"</span>,</span>
<span id="cb3-42"><a href="#cb3-42" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"The dashed line is perfect calibration; points show grouped risks and the solid line shows a smooth calibration curve"</span>,</span>
<span id="cb3-43"><a href="#cb3-43" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Predicted probability"</span>,</span>
<span id="cb3-44"><a href="#cb3-44" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Observed event frequency"</span>,</span>
<span id="cb3-45"><a href="#cb3-45" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="st">"Bin size"</span></span>
<span id="cb3-46"><a href="#cb3-46" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-47"><a href="#cb3-47" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">coord_cartesian</span>(<span class="at">xlim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>), <span class="at">ylim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb3-48"><a href="#cb3-48" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/calibration-plots_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This is the core figure of the chapter. If the points and the smooth line stay close to the dashed diagonal, the model is well calibrated. If they drift below the line, the model is overpredicting risk. If they drift above the line, it is underpredicting risk.</p>
</section>
<section id="step-4-summarize-calibration-intercept-and-slope" class="level2" data-number="64.5">
<h2 data-number="64.5" class="anchored" data-anchor-id="step-4-summarize-calibration-intercept-and-slope"><span class="header-section-number">64.5</span> Step 4: Summarize calibration intercept and slope</h2>
<p>Two short numerical summaries often accompany the plot. The calibration intercept measures whether predictions are systematically too low or too high overall. The calibration slope measures whether the spread of predictions is too extreme or too conservative.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>clipped_risk <span class="ot">&lt;-</span> <span class="fu">pmin</span>(<span class="fu">pmax</span>(calibration_data<span class="sc">$</span>predicted_risk, <span class="fl">1e-6</span>), <span class="dv">1</span> <span class="sc">-</span> <span class="fl">1e-6</span>)</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>logit_risk <span class="ot">&lt;-</span> <span class="fu">qlogis</span>(clipped_risk)</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>calibration_intercept_fit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  observed_outcome <span class="sc">~</span> <span class="fu">offset</span>(logit_risk),</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> calibration_data,</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>calibration_slope_fit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  observed_outcome <span class="sc">~</span> logit_risk,</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> calibration_data,</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>calibration_metrics <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">metric =</span> <span class="fu">c</span>(<span class="st">"Calibration intercept"</span>, <span class="st">"Calibration slope"</span>),</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimate =</span> <span class="fu">c</span>(</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coef</span>(calibration_intercept_fit)[<span class="dv">1</span>],</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>    <span class="fu">coef</span>(calibration_slope_fit)[<span class="dv">2</span>]</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>calibration_metrics<span class="sc">$</span>estimate <span class="ot">&lt;-</span> <span class="fu">round</span>(calibration_metrics<span class="sc">$</span>estimate, <span class="dv">3</span>)</span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>  calibration_metrics,</span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Calibration intercept and slope"</span></span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Calibration intercept and slope</caption>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">metric</th>
<th style="text-align: right;">estimate</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">(Intercept)</td>
<td style="text-align: left;">Calibration intercept</td>
<td style="text-align: right;">-0.065</td>
</tr>
<tr class="even">
<td style="text-align: left;">logit_risk</td>
<td style="text-align: left;">Calibration slope</td>
<td style="text-align: right;">0.953</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="64.6">
<h2 data-number="64.6" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">64.6</span> How to read the figure carefully</h2>
<p>Calibration is sample-dependent. A model can be well calibrated in one dataset and poorly calibrated in another if the case mix, prevalence, or measurement process changes. That is one reason calibration should usually be checked in data separate from the model-development sample.</p>
<p>Grouped points can also be visually helpful but statistically unstable in small samples or extreme-risk regions. The smooth curve helps, but it too depends on the chosen smoothing settings. That is why a good calibration section usually combines a plot with a few clear numerical summaries rather than relying on one graphic alone.</p>
</section>
<section id="further-reading" class="level2" data-number="64.7">
<h2 data-number="64.7" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">64.7</span> Further reading</h2>
<p>Van Calster and coauthors provide one of the clearest modern discussions of why calibration deserves more attention in predictive analytics <span class="citation" data-cites="vancalster2019">Van Calster et al. (<a href="#ref-vancalster2019" role="doc-biblioref">2019</a>)</span>. Smith and coauthors provide the real-world diabetes-prediction setting that motivates the example dataset used here <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>. Brier's classic paper is still useful for understanding why probability forecasts should be judged as probabilities rather than as hard classifications <span class="citation" data-cites="brier1950">Brier (<a href="#ref-brier1950" role="doc-biblioref">1950</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-brier1950" class="csl-entry" role="listitem">
Brier, Glenn W. 1950. <span>"Verification of Forecasts Expressed in Terms of Probability."</span> <em>Monthly Weather Review</em> 78 (1): 1-3. <a href="https://doi.org/10.1175/1520-0493(1950)078<0001:VOFEIT>2.0.CO;2">https://doi.org/10.1175/1520-0493(1950)078&lt;0001:VOFEIT&gt;2.0.CO;2</a>.
</div>
<div id="ref-smith1988" class="csl-entry" role="listitem">
Smith, J. W., J. E. Everhart, W. C. Dickson, W. C. Knowler, and R. S. Johannes. 1988. <span>"Using the <span>ADAP</span> Learning Algorithm to Forecast the Onset of Diabetes Mellitus."</span> In <em>Proceedings of the Symposium on Computer Applications in Medical Care</em>, 261-65.
</div>
<div id="ref-vancalster2019" class="csl-entry" role="listitem">
Van Calster, Ben, David J. McLernon, Maarten van Smeden, Laure Wynants, and Ewout W. Steyerberg. 2019. <span>"Calibration: The Achilles Heel of Predictive Analytics."</span> <em>BMC Medicine</em> 17 (1): 230. <a href="https://doi.org/10.1186/s12916-019-1466-7">https://doi.org/10.1186/s12916-019-1466-7</a>.
</div>
</div>
</section>
