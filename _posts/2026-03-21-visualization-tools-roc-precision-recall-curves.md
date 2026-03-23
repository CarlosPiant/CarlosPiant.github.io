---
title: "ROC and Precision-Recall Curves"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds two closely related prediction-performance figures: the ROC curve and the precision-recall curve. Both are designed to show how a binary prediction model behaves as the classification threshold..."
---
<p>This chapter builds two closely related prediction-performance figures: the ROC curve and the precision-recall curve. Both are designed to show how a binary prediction model behaves as the classification threshold changes, but they emphasize different aspects of performance. The ROC curve focuses on sensitivity and false-positive tradeoffs, while the precision-recall curve focuses on the relationship between recall and positive predictive value. In applied health prediction, both are useful, but they answer slightly different questions <span class="citation" data-cites="fawcett2006">Fawcett (<a href="#ref-fawcett2006" role="doc-biblioref">2006</a>)</span>; <span class="citation" data-cites="saito2015">Saito and Rehmsmeier (<a href="#ref-saito2015" role="doc-biblioref">2015</a>)</span>. The example again uses the Pima diabetes data from Smith and coauthors <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>.</p>
<p>The main idea is simple. A model that outputs probabilities can be turned into many different classifiers depending on where the threshold is set. ROC and precision-recall plots summarize that whole threshold range instead of committing to a single cutpoint.</p>
<section id="what-the-visualizations-are-showing" class="level2" data-number="73.1">
<h2 data-number="73.1" class="anchored" data-anchor-id="what-the-visualizations-are-showing"><span class="header-section-number">73.1</span> What the visualizations are showing</h2>
<p>The ROC curve plots true positive rate against false positive rate. The precision-recall curve plots precision against recall. Both curves are built from the same predicted probabilities, but they emphasize different failure modes. The precision-recall curve often becomes more informative when events are relatively uncommon.</p>
</section>
<section id="step-1-fit-the-prediction-model-and-create-test-set-probabilities" class="level2" data-number="73.2">
<h2 data-number="73.2" class="anchored" data-anchor-id="step-1-fit-the-prediction-model-and-create-test-set-probabilities"><span class="header-section-number">73.2</span> Step 1: Fit the prediction model and create test-set probabilities</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.tr"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.te"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>roc_fit <span class="ot">&lt;-</span> <span class="fu">glm</span>(</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>  type <span class="sc">~</span> npreg <span class="sc">+</span> glu <span class="sc">+</span> bp <span class="sc">+</span> skin <span class="sc">+</span> bmi <span class="sc">+</span> ped <span class="sc">+</span> age,</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> Pima.tr,</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">family =</span> <span class="fu">binomial</span>()</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>predicted_risk <span class="ot">&lt;-</span> <span class="fu">predict</span>(roc_fit, <span class="at">newdata =</span> Pima.te, <span class="at">type =</span> <span class="st">"response"</span>)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>observed_outcome <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(Pima.te<span class="sc">$</span>type <span class="sc">==</span> <span class="st">"Yes"</span>)</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>performance_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">predicted_risk =</span> predicted_risk,</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">observed_outcome =</span> observed_outcome</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
</section>
<section id="step-2-compute-performance-across-thresholds" class="level2" data-number="73.3">
<h2 data-number="73.3" class="anchored" data-anchor-id="step-2-compute-performance-across-thresholds"><span class="header-section-number">73.3</span> Step 2: Compute performance across thresholds</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>thresholds <span class="ot">&lt;-</span> <span class="fu">sort</span>(<span class="fu">unique</span>(<span class="fu">c</span>(<span class="dv">1</span>, performance_data<span class="sc">$</span>predicted_risk, <span class="dv">0</span>)), <span class="at">decreasing =</span> <span class="cn">TRUE</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>curve_points <span class="ot">&lt;-</span> <span class="fu">lapply</span>(thresholds, <span class="cf">function</span>(threshold) {</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>  predicted_class <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(performance_data<span class="sc">$</span>predicted_risk <span class="sc">&gt;=</span> threshold)</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  tp <span class="ot">&lt;-</span> <span class="fu">sum</span>(predicted_class <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> performance_data<span class="sc">$</span>observed_outcome <span class="sc">==</span> <span class="dv">1</span>)</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  fp <span class="ot">&lt;-</span> <span class="fu">sum</span>(predicted_class <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> performance_data<span class="sc">$</span>observed_outcome <span class="sc">==</span> <span class="dv">0</span>)</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  tn <span class="ot">&lt;-</span> <span class="fu">sum</span>(predicted_class <span class="sc">==</span> <span class="dv">0</span> <span class="sc">&amp;</span> performance_data<span class="sc">$</span>observed_outcome <span class="sc">==</span> <span class="dv">0</span>)</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>  fn <span class="ot">&lt;-</span> <span class="fu">sum</span>(predicted_class <span class="sc">==</span> <span class="dv">0</span> <span class="sc">&amp;</span> performance_data<span class="sc">$</span>observed_outcome <span class="sc">==</span> <span class="dv">1</span>)</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  tpr <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(tp <span class="sc">+</span> fn <span class="sc">==</span> <span class="dv">0</span>, <span class="dv">0</span>, tp <span class="sc">/</span> (tp <span class="sc">+</span> fn))</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  fpr <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(fp <span class="sc">+</span> tn <span class="sc">==</span> <span class="dv">0</span>, <span class="dv">0</span>, fp <span class="sc">/</span> (fp <span class="sc">+</span> tn))</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>  precision <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(tp <span class="sc">+</span> fp <span class="sc">==</span> <span class="dv">0</span>, <span class="dv">1</span>, tp <span class="sc">/</span> (tp <span class="sc">+</span> fp))</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  recall <span class="ot">&lt;-</span> tpr</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">data.frame</span>(</span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">threshold =</span> threshold,</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">tpr =</span> tpr,</span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">fpr =</span> fpr,</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">precision =</span> precision,</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">recall =</span> recall</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>})</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>curve_data <span class="ot">&lt;-</span> <span class="fu">do.call</span>(rbind, curve_points)</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>roc_data <span class="ot">&lt;-</span> curve_data[<span class="fu">order</span>(curve_data<span class="sc">$</span>fpr, curve_data<span class="sc">$</span>tpr), ]</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>pr_data <span class="ot">&lt;-</span> curve_data[<span class="fu">order</span>(curve_data<span class="sc">$</span>recall, curve_data<span class="sc">$</span>precision), ]</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>roc_auc <span class="ot">&lt;-</span> <span class="fu">sum</span>(<span class="fu">diff</span>(roc_data<span class="sc">$</span>fpr) <span class="sc">*</span> (<span class="fu">head</span>(roc_data<span class="sc">$</span>tpr, <span class="sc">-</span><span class="dv">1</span>) <span class="sc">+</span> <span class="fu">tail</span>(roc_data<span class="sc">$</span>tpr, <span class="sc">-</span><span class="dv">1</span>)) <span class="sc">/</span> <span class="dv">2</span>)</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>pr_data_unique <span class="ot">&lt;-</span> pr_data[<span class="sc">!</span><span class="fu">duplicated</span>(pr_data<span class="sc">$</span>recall), ]</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>average_precision <span class="ot">&lt;-</span> <span class="fu">sum</span>(<span class="fu">diff</span>(pr_data_unique<span class="sc">$</span>recall) <span class="sc">*</span> <span class="fu">tail</span>(pr_data_unique<span class="sc">$</span>precision, <span class="sc">-</span><span class="dv">1</span>))</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>summary_table <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">metric =</span> <span class="fu">c</span>(<span class="st">"Event prevalence"</span>, <span class="st">"ROC AUC"</span>, <span class="st">"Average precision"</span>),</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">value =</span> <span class="fu">c</span>(</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(performance_data<span class="sc">$</span>observed_outcome),</span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>    roc_auc,</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>    average_precision</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a>summary_table<span class="sc">$</span>value <span class="ot">&lt;-</span> <span class="fu">round</span>(summary_table<span class="sc">$</span>value, <span class="dv">3</span>)</span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a>  summary_table,</span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary performance metrics for the diabetes prediction model"</span></span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary performance metrics for the diabetes prediction model</caption>
<thead>
<tr class="header">
<th style="text-align: left;">metric</th>
<th style="text-align: right;">value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Event prevalence</td>
<td style="text-align: right;">0.328</td>
</tr>
<tr class="even">
<td style="text-align: left;">ROC AUC</td>
<td style="text-align: right;">0.866</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Average precision</td>
<td style="text-align: right;">0.718</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The AUC summarizes the ROC curve in one number, while average precision summarizes the precision-recall curve. Neither replaces the plot, but both are useful anchors.</p>
</section>
<section id="step-3-build-the-roc-curve" class="level2" data-number="73.4">
<h2 data-number="73.4" class="anchored" data-anchor-id="step-3-build-the-roc-curve"><span class="header-section-number">73.4</span> Step 3: Build the ROC curve</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(roc_data, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> fpr, <span class="at">y =</span> tpr)) <span class="sc">+</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(<span class="at">color =</span> <span class="st">"#3d5a80"</span>, <span class="at">linewidth =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_abline</span>(</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">intercept =</span> <span class="dv">0</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">slope =</span> <span class="dv">1</span>,</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#8b5e34"</span>,</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.8</span></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"ROC curve for diabetes prediction"</span>,</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="fu">sprintf</span>(<span class="st">"Area under the curve = %.3f"</span>, roc_auc),</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"False positive rate"</span>,</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"True positive rate"</span></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">coord_equal</span>(<span class="at">xlim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>), <span class="at">ylim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/roc-precision-recall-curves_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The diagonal line represents random guessing. The further the curve bows toward the upper-left corner, the better the model discriminates between cases and non-cases.</p>
</section>
<section id="step-4-build-the-precision-recall-curve" class="level2" data-number="73.5">
<h2 data-number="73.5" class="anchored" data-anchor-id="step-4-build-the-precision-recall-curve"><span class="header-section-number">73.5</span> Step 4: Build the precision-recall curve</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>baseline_precision <span class="ot">&lt;-</span> <span class="fu">mean</span>(performance_data<span class="sc">$</span>observed_outcome)</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(pr_data_unique, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> recall, <span class="at">y =</span> precision)) <span class="sc">+</span></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(<span class="at">color =</span> <span class="st">"#bc6c25"</span>, <span class="at">linewidth =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_hline</span>(</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">yintercept =</span> baseline_precision,</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">linetype =</span> <span class="dv">2</span>,</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#8b5e34"</span>,</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="fl">0.8</span></span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Precision-recall curve for diabetes prediction"</span>,</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="fu">sprintf</span>(<span class="st">"Average precision = %.3f; dashed line marks event prevalence"</span>, average_precision),</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Recall"</span>,</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Precision"</span></span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">coord_equal</span>(<span class="at">xlim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>), <span class="at">ylim =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>)) <span class="sc">+</span></span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/roc-precision-recall-curves_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The dashed horizontal line marks the event prevalence. A good precision-recall curve should stay well above that baseline across a meaningful range of recall values.</p>
</section>
<section id="step-5-compare-threshold-specific-operating-points" class="level2" data-number="73.6">
<h2 data-number="73.6" class="anchored" data-anchor-id="step-5-compare-threshold-specific-operating-points"><span class="header-section-number">73.6</span> Step 5: Compare threshold-specific operating points</h2>
<p>Sometimes readers also need a few concrete threshold examples rather than a full curve alone.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>selected_thresholds <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="fl">0.20</span>, <span class="fl">0.40</span>, <span class="fl">0.60</span>)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>operating_points <span class="ot">&lt;-</span> <span class="fu">do.call</span>(</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  rbind,</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">lapply</span>(selected_thresholds, <span class="cf">function</span>(threshold) {</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>    predicted_class <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(performance_data<span class="sc">$</span>predicted_risk <span class="sc">&gt;=</span> threshold)</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>    tp <span class="ot">&lt;-</span> <span class="fu">sum</span>(predicted_class <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> performance_data<span class="sc">$</span>observed_outcome <span class="sc">==</span> <span class="dv">1</span>)</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>    fp <span class="ot">&lt;-</span> <span class="fu">sum</span>(predicted_class <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;</span> performance_data<span class="sc">$</span>observed_outcome <span class="sc">==</span> <span class="dv">0</span>)</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>    tn <span class="ot">&lt;-</span> <span class="fu">sum</span>(predicted_class <span class="sc">==</span> <span class="dv">0</span> <span class="sc">&amp;</span> performance_data<span class="sc">$</span>observed_outcome <span class="sc">==</span> <span class="dv">0</span>)</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>    fn <span class="ot">&lt;-</span> <span class="fu">sum</span>(predicted_class <span class="sc">==</span> <span class="dv">0</span> <span class="sc">&amp;</span> performance_data<span class="sc">$</span>observed_outcome <span class="sc">==</span> <span class="dv">1</span>)</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>      <span class="at">threshold =</span> threshold,</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>      <span class="at">sensitivity =</span> tp <span class="sc">/</span> (tp <span class="sc">+</span> fn),</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>      <span class="at">specificity =</span> tn <span class="sc">/</span> (tn <span class="sc">+</span> fp),</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>      <span class="at">precision =</span> <span class="fu">ifelse</span>(tp <span class="sc">+</span> fp <span class="sc">==</span> <span class="dv">0</span>, <span class="dv">1</span>, tp <span class="sc">/</span> (tp <span class="sc">+</span> fp))</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>operating_points[, <span class="fu">c</span>(<span class="st">"sensitivity"</span>, <span class="st">"specificity"</span>, <span class="st">"precision"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(operating_points[, <span class="fu">c</span>(<span class="st">"sensitivity"</span>, <span class="st">"specificity"</span>, <span class="st">"precision"</span>)], <span class="dv">3</span>)</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>  operating_points,</span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Selected threshold-specific operating characteristics"</span></span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Selected threshold-specific operating characteristics</caption>
<thead>
<tr class="header">
<th style="text-align: right;">threshold</th>
<th style="text-align: right;">sensitivity</th>
<th style="text-align: right;">specificity</th>
<th style="text-align: right;">precision</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">0.2</td>
<td style="text-align: right;">0.917</td>
<td style="text-align: right;">0.646</td>
<td style="text-align: right;">0.559</td>
</tr>
<tr class="even">
<td style="text-align: right;">0.4</td>
<td style="text-align: right;">0.716</td>
<td style="text-align: right;">0.825</td>
<td style="text-align: right;">0.667</td>
</tr>
<tr class="odd">
<td style="text-align: right;">0.6</td>
<td style="text-align: right;">0.550</td>
<td style="text-align: right;">0.928</td>
<td style="text-align: right;">0.789</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="how-to-read-the-figures-carefully" class="level2" data-number="73.7">
<h2 data-number="73.7" class="anchored" data-anchor-id="how-to-read-the-figures-carefully"><span class="header-section-number">73.7</span> How to read the figures carefully</h2>
<p>The ROC curve is threshold-agnostic and prevalence-invariant, which makes it useful for general discrimination summaries. But that same property can make it less sensitive to the practical consequences of false positives in low-prevalence settings. That is one reason precision-recall curves are often a better companion when the positive class is relatively rare or when precision matters directly.</p>
<p>Neither curve says whether the predicted probabilities are well calibrated. A model can discriminate well and still produce misleading absolute risks. That is why ROC and precision-recall plots work best when read alongside a calibration plot rather than instead of one.</p>
</section>
<section id="further-reading" class="level2" data-number="73.8">
<h2 data-number="73.8" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">73.8</span> Further reading</h2>
<p>Fawcett gives a clear introduction to the logic and interpretation of ROC analysis <span class="citation" data-cites="fawcett2006">Fawcett (<a href="#ref-fawcett2006" role="doc-biblioref">2006</a>)</span>. Saito and Rehmsmeier explain why precision-recall curves deserve more attention in imbalanced settings <span class="citation" data-cites="saito2015">Saito and Rehmsmeier (<a href="#ref-saito2015" role="doc-biblioref">2015</a>)</span>. Smith and coauthors provide the original applied context for the diabetes dataset used in this example <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-fawcett2006" class="csl-entry" role="listitem">
Fawcett, Tom. 2006. <span>"An Introduction to ROC Analysis."</span> <em>Pattern Recognition Letters</em> 27 (8): 861-74. <a href="https://doi.org/10.1016/j.patrec.2005.10.010">https://doi.org/10.1016/j.patrec.2005.10.010</a>.
</div>
<div id="ref-saito2015" class="csl-entry" role="listitem">
Saito, Takaya, and Marc Rehmsmeier. 2015. <span>"The Precision-Recall Plot Is More Informative Than the ROC Plot When Evaluating Binary Classifiers on Imbalanced Datasets."</span> <em>PLOS ONE</em> 10 (3): e0118432. <a href="https://doi.org/10.1371/journal.pone.0118432">https://doi.org/10.1371/journal.pone.0118432</a>.
</div>
<div id="ref-smith1988" class="csl-entry" role="listitem">
Smith, J. W., J. E. Everhart, W. C. Dickson, W. C. Knowler, and R. S. Johannes. 1988. <span>"Using the <span>ADAP</span> Learning Algorithm to Forecast the Onset of Diabetes Mellitus."</span> In <em>Proceedings of the Symposium on Computer Applications in Medical Care</em>, 261-65.
</div>
</div>
</section>
