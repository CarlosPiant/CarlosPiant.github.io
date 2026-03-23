---
title: "Variable Importance"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter builds a variable-importance plot rather than a regression-coefficient plot or a partial-dependence plot. The purpose is to show which predictors matter most for a model's predictive performance and to..."
---
<p>This chapter builds a variable-importance plot rather than a regression-coefficient plot or a partial-dependence plot. The purpose is to show which predictors matter most for a model's predictive performance and to communicate that ranking in a visually clean, academically formatted way. Variable-importance plots are especially useful when a flexible model captures nonlinearities and interactions that are not easy to summarize with one coefficient per predictor. Greenwell and Boehmke give a broad overview of variable-importance plotting and explain why the plotting choices matter for interpretation <span class="citation" data-cites="greenwell2020variable">Greenwell and Boehmke (<a href="#ref-greenwell2020variable" role="doc-biblioref">2020</a>)</span>.</p>
<p>The specific figure we will build is a horizontal lollipop chart of permutation importance. This choice is deliberate. A lollipop chart is easier to read than a crowded bar chart when variable names are long, and permutation importance has a direct performance-based interpretation: it measures how much the model worsens when a predictor is disrupted. Breiman's random forest paper made this style of performance-based variable importance widely influential in applied predictive modeling <span class="citation" data-cites="breiman2001">Breiman (<a href="#ref-breiman2001" role="doc-biblioref">2001</a>)</span>.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="71.1">
<h2 data-number="71.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">71.1</span> What the visualization is showing</h2>
<p>A variable-importance plot ranks predictors from most to least important according to a chosen importance measure. In this chapter, importance is defined as the increase in out-of-sample log loss after randomly permuting one predictor while leaving the model itself fixed.</p>
<p>This figure is useful when:</p>
<ol type="1">
<li>a predictive model contains many candidate predictors,</li>
<li>the reader needs a fast summary of which variables matter most,</li>
<li>the analyst wants a model-based ranking rather than only descriptive summaries.</li>
</ol>
<p>The key interpretation rule is simple: variables farther to the right are more important because permuting them harms predictive performance more. Values close to zero indicate variables that contribute little incremental predictive information in the fitted model. Negative values can occur in finite samples and usually mean that the variable has little stable predictive value under the chosen metric.</p>
</section>
<section id="step-1-create-a-synthetic-prediction-example" class="level2" data-number="71.2">
<h2 data-number="71.2" class="anchored" data-anchor-id="step-1-create-a-synthetic-prediction-example"><span class="header-section-number">71.2</span> Step 1: Create a synthetic prediction example</h2>
<p>We begin with a synthetic hospital readmission example. The outcome is 30-day readmission, and the predictors include age, baseline severity, prior admissions, comorbidity burden, creatinine, follow-up status, and sex. We fit a random forest and compute permutation importance on a held-out test set.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(knitr)</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(randomForest)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>format_numeric_table <span class="ot">&lt;-</span> <span class="cf">function</span>(df, <span class="at">digits =</span> <span class="dv">3</span>) {</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  numeric_cols <span class="ot">&lt;-</span> <span class="fu">vapply</span>(df, is.numeric, <span class="fu">logical</span>(<span class="dv">1</span>))</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  df[numeric_cols] <span class="ot">&lt;-</span> <span class="fu">lapply</span>(df[numeric_cols], round, <span class="at">digits =</span> digits)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  df</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>log_loss <span class="ot">&lt;-</span> <span class="cf">function</span>(actual, prob_yes, <span class="at">eps =</span> <span class="fl">1e-6</span>) {</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  y <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(actual <span class="sc">==</span> <span class="st">"Yes"</span>)</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  p <span class="ot">&lt;-</span> <span class="fu">pmin</span>(<span class="fu">pmax</span>(prob_yes, eps), <span class="dv">1</span> <span class="sc">-</span> eps)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="sc">-</span><span class="fu">mean</span>(y <span class="sc">*</span> <span class="fu">log</span>(p) <span class="sc">+</span> (<span class="dv">1</span> <span class="sc">-</span> y) <span class="sc">*</span> <span class="fu">log</span>(<span class="dv">1</span> <span class="sc">-</span> p))</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>permutation_importance <span class="ot">&lt;-</span> <span class="cf">function</span>(model, data, outcome, <span class="at">reps =</span> <span class="dv">20</span>, <span class="at">seed =</span> <span class="dv">2026</span>) {</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">set.seed</span>(seed)</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  baseline_prob <span class="ot">&lt;-</span> <span class="fu">predict</span>(model, <span class="at">newdata =</span> data, <span class="at">type =</span> <span class="st">"prob"</span>)[, <span class="st">"Yes"</span>]</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  baseline_loss <span class="ot">&lt;-</span> <span class="fu">log_loss</span>(data[[outcome]], baseline_prob)</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  predictors <span class="ot">&lt;-</span> <span class="fu">setdiff</span>(<span class="fu">names</span>(data), outcome)</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a>  importance_df <span class="ot">&lt;-</span> <span class="fu">lapply</span>(predictors, <span class="cf">function</span>(v) {</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>    increases <span class="ot">&lt;-</span> <span class="fu">replicate</span>(reps, {</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>      permuted <span class="ot">&lt;-</span> data</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a>      permuted[[v]] <span class="ot">&lt;-</span> <span class="fu">sample</span>(permuted[[v]])</span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>      permuted_prob <span class="ot">&lt;-</span> <span class="fu">predict</span>(model, <span class="at">newdata =</span> permuted, <span class="at">type =</span> <span class="st">"prob"</span>)[, <span class="st">"Yes"</span>]</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>      <span class="fu">log_loss</span>(data[[outcome]], permuted_prob) <span class="sc">-</span> baseline_loss</span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a>    })</span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a>    <span class="fu">data.frame</span>(</span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a>      <span class="at">variable =</span> v,</span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>      <span class="at">importance =</span> <span class="fu">mean</span>(increases),</span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a>      <span class="at">sd_importance =</span> <span class="fu">sd</span>(increases)</span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  })</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>  <span class="fu">bind_rows</span>(importance_df)</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>n <span class="ot">&lt;-</span> <span class="dv">1200</span></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>age <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n, <span class="at">mean =</span> <span class="dv">67</span>, <span class="at">sd =</span> <span class="dv">10</span>)</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>severity <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n)</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>prior_adm <span class="ot">&lt;-</span> <span class="fu">rpois</span>(n, <span class="at">lambda =</span> <span class="fu">exp</span>(<span class="sc">-</span><span class="fl">0.1</span> <span class="sc">+</span> <span class="fl">0.9</span> <span class="sc">*</span> severity))</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>charlson <span class="ot">&lt;-</span> <span class="fu">pmax</span>(<span class="fu">round</span>(<span class="fl">1.5</span> <span class="sc">+</span> <span class="fl">1.4</span> <span class="sc">*</span> severity <span class="sc">+</span> <span class="fu">rnorm</span>(n, <span class="dv">0</span>, <span class="fl">0.7</span>)), <span class="dv">0</span>)</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>creatinine <span class="ot">&lt;-</span> <span class="fu">exp</span>(<span class="fu">rnorm</span>(n, <span class="fl">0.15</span> <span class="sc">+</span> <span class="fl">0.35</span> <span class="sc">*</span> severity, <span class="fl">0.25</span>))</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>followup <span class="ot">&lt;-</span> <span class="fu">factor</span>(<span class="fu">rbinom</span>(n, <span class="dv">1</span>, <span class="fu">plogis</span>(<span class="fl">0.2</span> <span class="sc">-</span> <span class="fl">0.9</span> <span class="sc">*</span> severity)), <span class="at">labels =</span> <span class="fu">c</span>(<span class="st">"No"</span>, <span class="st">"Yes"</span>))</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>sex <span class="ot">&lt;-</span> <span class="fu">factor</span>(<span class="fu">rbinom</span>(n, <span class="dv">1</span>, <span class="fl">0.48</span>), <span class="at">labels =</span> <span class="fu">c</span>(<span class="st">"Female"</span>, <span class="st">"Male"</span>))</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>linear_predictor <span class="ot">&lt;-</span></span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>  <span class="sc">-</span><span class="fl">4.4</span> <span class="sc">+</span></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.045</span> <span class="sc">*</span> age <span class="sc">+</span></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  <span class="fl">1.45</span> <span class="sc">*</span> severity <span class="sc">+</span></span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.24</span> <span class="sc">*</span> prior_adm <span class="sc">+</span></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.30</span> <span class="sc">*</span> charlson <span class="sc">+</span></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.65</span> <span class="sc">*</span> <span class="fu">log</span>(creatinine) <span class="sc">-</span></span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.95</span> <span class="sc">*</span> (followup <span class="sc">==</span> <span class="st">"Yes"</span>) <span class="sc">+</span></span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a>  <span class="fl">0.05</span> <span class="sc">*</span> (sex <span class="sc">==</span> <span class="st">"Male"</span>)</span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>readmit <span class="ot">&lt;-</span> <span class="fu">factor</span>(</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ifelse</span>(<span class="fu">runif</span>(n) <span class="sc">&lt;</span> <span class="fu">plogis</span>(linear_predictor), <span class="st">"Yes"</span>, <span class="st">"No"</span>),</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a>  <span class="at">levels =</span> <span class="fu">c</span>(<span class="st">"No"</span>, <span class="st">"Yes"</span>)</span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>synthetic_df <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-29"><a href="#cb2-29" aria-hidden="true" tabindex="-1"></a>  <span class="at">age =</span> age,</span>
<span id="cb2-30"><a href="#cb2-30" aria-hidden="true" tabindex="-1"></a>  <span class="at">severity =</span> severity,</span>
<span id="cb2-31"><a href="#cb2-31" aria-hidden="true" tabindex="-1"></a>  <span class="at">prior_adm =</span> prior_adm,</span>
<span id="cb2-32"><a href="#cb2-32" aria-hidden="true" tabindex="-1"></a>  <span class="at">charlson =</span> charlson,</span>
<span id="cb2-33"><a href="#cb2-33" aria-hidden="true" tabindex="-1"></a>  <span class="at">creatinine =</span> creatinine,</span>
<span id="cb2-34"><a href="#cb2-34" aria-hidden="true" tabindex="-1"></a>  <span class="at">followup =</span> followup,</span>
<span id="cb2-35"><a href="#cb2-35" aria-hidden="true" tabindex="-1"></a>  <span class="at">sex =</span> sex,</span>
<span id="cb2-36"><a href="#cb2-36" aria-hidden="true" tabindex="-1"></a>  <span class="at">readmit =</span> readmit</span>
<span id="cb2-37"><a href="#cb2-37" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-38"><a href="#cb2-38" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-39"><a href="#cb2-39" aria-hidden="true" tabindex="-1"></a>train_index <span class="ot">&lt;-</span> <span class="fu">sample.int</span>(n, <span class="at">size =</span> <span class="fu">round</span>(<span class="fl">0.7</span> <span class="sc">*</span> n))</span>
<span id="cb2-40"><a href="#cb2-40" aria-hidden="true" tabindex="-1"></a>synthetic_train <span class="ot">&lt;-</span> synthetic_df[train_index, ]</span>
<span id="cb2-41"><a href="#cb2-41" aria-hidden="true" tabindex="-1"></a>synthetic_test <span class="ot">&lt;-</span> synthetic_df[<span class="sc">-</span>train_index, ]</span>
<span id="cb2-42"><a href="#cb2-42" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-43"><a href="#cb2-43" aria-hidden="true" tabindex="-1"></a>synthetic_rf <span class="ot">&lt;-</span> <span class="fu">randomForest</span>(readmit <span class="sc">~</span> ., <span class="at">data =</span> synthetic_train, <span class="at">ntree =</span> <span class="dv">700</span>)</span>
<span id="cb2-44"><a href="#cb2-44" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-45"><a href="#cb2-45" aria-hidden="true" tabindex="-1"></a>synthetic_importance <span class="ot">&lt;-</span> <span class="fu">permutation_importance</span>(</span>
<span id="cb2-46"><a href="#cb2-46" aria-hidden="true" tabindex="-1"></a>  <span class="at">model =</span> synthetic_rf,</span>
<span id="cb2-47"><a href="#cb2-47" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> synthetic_test,</span>
<span id="cb2-48"><a href="#cb2-48" aria-hidden="true" tabindex="-1"></a>  <span class="at">outcome =</span> <span class="st">"readmit"</span>,</span>
<span id="cb2-49"><a href="#cb2-49" aria-hidden="true" tabindex="-1"></a>  <span class="at">reps =</span> <span class="dv">20</span>,</span>
<span id="cb2-50"><a href="#cb2-50" aria-hidden="true" tabindex="-1"></a>  <span class="at">seed =</span> <span class="dv">2026</span></span>
<span id="cb2-51"><a href="#cb2-51" aria-hidden="true" tabindex="-1"></a>) <span class="sc">|&gt;</span></span>
<span id="cb2-52"><a href="#cb2-52" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(importance))</span>
<span id="cb2-53"><a href="#cb2-53" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-54"><a href="#cb2-54" aria-hidden="true" tabindex="-1"></a>synthetic_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-55"><a href="#cb2-55" aria-hidden="true" tabindex="-1"></a>  <span class="at">training_n =</span> <span class="fu">nrow</span>(synthetic_train),</span>
<span id="cb2-56"><a href="#cb2-56" aria-hidden="true" tabindex="-1"></a>  <span class="at">test_n =</span> <span class="fu">nrow</span>(synthetic_test),</span>
<span id="cb2-57"><a href="#cb2-57" aria-hidden="true" tabindex="-1"></a>  <span class="at">test_accuracy =</span> <span class="fu">mean</span>(<span class="fu">predict</span>(synthetic_rf, synthetic_test) <span class="sc">==</span> synthetic_test<span class="sc">$</span>readmit),</span>
<span id="cb2-58"><a href="#cb2-58" aria-hidden="true" tabindex="-1"></a>  <span class="at">baseline_log_loss =</span> <span class="fu">log_loss</span>(</span>
<span id="cb2-59"><a href="#cb2-59" aria-hidden="true" tabindex="-1"></a>    synthetic_test<span class="sc">$</span>readmit,</span>
<span id="cb2-60"><a href="#cb2-60" aria-hidden="true" tabindex="-1"></a>    <span class="fu">predict</span>(synthetic_rf, synthetic_test, <span class="at">type =</span> <span class="st">"prob"</span>)[, <span class="st">"Yes"</span>]</span>
<span id="cb2-61"><a href="#cb2-61" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-62"><a href="#cb2-62" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-63"><a href="#cb2-63" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-64"><a href="#cb2-64" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-65"><a href="#cb2-65" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_summary, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb2-66"><a href="#cb2-66" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Synthetic random-forest setup for the variable-importance plot"</span></span>
<span id="cb2-67"><a href="#cb2-67" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Synthetic random-forest setup for the variable-importance plot</caption>
<thead>
<tr class="header">
<th style="text-align: right;">training_n</th>
<th style="text-align: right;">test_n</th>
<th style="text-align: right;">test_accuracy</th>
<th style="text-align: right;">baseline_log_loss</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">840</td>
<td style="text-align: right;">360</td>
<td style="text-align: right;">0.833</td>
<td style="text-align: right;">0.417</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(synthetic_importance, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Permutation importance values in the synthetic readmission example"</span></span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Permutation importance values in the synthetic readmission example</caption>
<thead>
<tr class="header">
<th style="text-align: left;">variable</th>
<th style="text-align: right;">importance</th>
<th style="text-align: right;">sd_importance</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">severity</td>
<td style="text-align: right;">0.160</td>
<td style="text-align: right;">0.014</td>
</tr>
<tr class="even">
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.032</td>
<td style="text-align: right;">0.015</td>
</tr>
<tr class="odd">
<td style="text-align: left;">charlson</td>
<td style="text-align: right;">0.029</td>
<td style="text-align: right;">0.014</td>
</tr>
<tr class="even">
<td style="text-align: left;">prior_adm</td>
<td style="text-align: right;">0.022</td>
<td style="text-align: right;">0.009</td>
</tr>
<tr class="odd">
<td style="text-align: left;">creatinine</td>
<td style="text-align: right;">0.019</td>
<td style="text-align: right;">0.010</td>
</tr>
<tr class="even">
<td style="text-align: left;">followup</td>
<td style="text-align: right;">0.015</td>
<td style="text-align: right;">0.006</td>
</tr>
<tr class="odd">
<td style="text-align: left;">sex</td>
<td style="text-align: right;">0.001</td>
<td style="text-align: right;">0.003</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The table is useful, but the plot is the real goal. We will build a horizontal lollipop chart with a zero reference line and importance labels ordered from smallest to largest so the rank is visually obvious.</p>
</section>
<section id="step-2-build-the-synthetic-variable-importance-plot" class="level2" data-number="71.3">
<h2 data-number="71.3" class="anchored" data-anchor-id="step-2-build-the-synthetic-variable-importance-plot"><span class="header-section-number">71.3</span> Step 2: Build the synthetic variable-importance plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>synthetic_plot_df <span class="ot">&lt;-</span> synthetic_importance <span class="sc">|&gt;</span></span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(<span class="at">variable =</span> <span class="fu">factor</span>(variable, <span class="at">levels =</span> <span class="fu">rev</span>(variable)))</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(synthetic_plot_df, <span class="fu">aes</span>(<span class="at">x =</span> importance, <span class="at">y =</span> variable)) <span class="sc">+</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_segment</span>(<span class="fu">aes</span>(<span class="at">x =</span> <span class="dv">0</span>, <span class="at">xend =</span> importance, <span class="at">y =</span> variable, <span class="at">yend =</span> variable),</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>               <span class="at">linewidth =</span> <span class="fl">1.2</span>, <span class="at">color =</span> <span class="st">"#9ecae1"</span>) <span class="sc">+</span></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_point</span>(<span class="at">size =</span> <span class="fl">3.4</span>, <span class="at">color =</span> <span class="st">"#08519c"</span>) <span class="sc">+</span></span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="dv">0</span>, <span class="at">linetype =</span> <span class="dv">2</span>, <span class="at">color =</span> <span class="st">"#7f2704"</span>) <span class="sc">+</span></span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"A variable-importance plot ranks predictors by performance loss after permutation"</span>,</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Synthetic readmission model using held-out log-loss increase"</span>,</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Increase in test-set log loss after permutation"</span>,</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="cn">NULL</span></span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid.major.y =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>()</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/variable-importance_files/figure-html/unnamed-chunk-3-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This figure is easy to read because it preserves both rank and magnitude. Severity is the most important predictor, followed by age and comorbidity burden, while sex contributes almost nothing to held-out performance. That is the core value of the plot: it turns a model's internal ranking into a figure that a reader can scan in seconds.</p>
</section>
<section id="step-3-pair-the-figure-with-a-short-ranked-table" class="level2" data-number="71.4">
<h2 data-number="71.4" class="anchored" data-anchor-id="step-3-pair-the-figure-with-a-short-ranked-table"><span class="header-section-number">71.4</span> Step 3: Pair the figure with a short ranked table</h2>
<p>As with several figures in this section, it is often useful to pair the plot with a compact top-predictor table.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>top_synthetic_predictors <span class="ot">&lt;-</span> synthetic_importance <span class="sc">|&gt;</span></span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">slice_head</span>(<span class="at">n =</span> <span class="dv">5</span>)</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(top_synthetic_predictors, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Top predictors in the synthetic variable-importance ranking"</span></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Top predictors in the synthetic variable-importance ranking</caption>
<thead>
<tr class="header">
<th style="text-align: left;">variable</th>
<th style="text-align: right;">importance</th>
<th style="text-align: right;">sd_importance</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">severity</td>
<td style="text-align: right;">0.160</td>
<td style="text-align: right;">0.014</td>
</tr>
<tr class="even">
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.032</td>
<td style="text-align: right;">0.015</td>
</tr>
<tr class="odd">
<td style="text-align: left;">charlson</td>
<td style="text-align: right;">0.029</td>
<td style="text-align: right;">0.014</td>
</tr>
<tr class="even">
<td style="text-align: left;">prior_adm</td>
<td style="text-align: right;">0.022</td>
<td style="text-align: right;">0.009</td>
</tr>
<tr class="odd">
<td style="text-align: left;">creatinine</td>
<td style="text-align: right;">0.019</td>
<td style="text-align: right;">0.010</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The figure gives the pattern. The table names the values precisely. Together they make the result easier to report in text and easier to inspect critically.</p>
</section>
<section id="step-4-create-a-real-world-variable-importance-plot-from-a-public-scientific-dataset" class="level2" data-number="71.5">
<h2 data-number="71.5" class="anchored" data-anchor-id="step-4-create-a-real-world-variable-importance-plot-from-a-public-scientific-dataset"><span class="header-section-number">71.5</span> Step 4: Create a real-world variable-importance plot from a public scientific dataset</h2>
<p>For a real-world example, we use the public Pima diabetes data distributed with <code>MASS</code>, linked to the prediction problem studied by Smith and colleagues <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>. The original paper used the ADAP learning algorithm to forecast diabetes status. We do not reproduce that algorithm here. Instead, this is a transparent partial application built on the same public prediction task and dataset.</p>
<p>We train a random forest on <code>Pima.tr</code>, evaluate it on <code>Pima.te</code>, and compute held-out permutation importance for each predictor. This keeps the scientific setting grounded in a published health-prediction problem while focusing the chapter on the visualization itself.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.tr"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.te"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>pima_rf <span class="ot">&lt;-</span> <span class="fu">randomForest</span>(type <span class="sc">~</span> ., <span class="at">data =</span> Pima.tr, <span class="at">ntree =</span> <span class="dv">700</span>)</span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>pima_importance <span class="ot">&lt;-</span> <span class="fu">permutation_importance</span>(</span>
<span id="cb6-7"><a href="#cb6-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">model =</span> pima_rf,</span>
<span id="cb6-8"><a href="#cb6-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> Pima.te,</span>
<span id="cb6-9"><a href="#cb6-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">outcome =</span> <span class="st">"type"</span>,</span>
<span id="cb6-10"><a href="#cb6-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">reps =</span> <span class="dv">20</span>,</span>
<span id="cb6-11"><a href="#cb6-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">seed =</span> <span class="dv">2026</span></span>
<span id="cb6-12"><a href="#cb6-12" aria-hidden="true" tabindex="-1"></a>) <span class="sc">|&gt;</span></span>
<span id="cb6-13"><a href="#cb6-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">arrange</span>(<span class="fu">desc</span>(importance))</span>
<span id="cb6-14"><a href="#cb6-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-15"><a href="#cb6-15" aria-hidden="true" tabindex="-1"></a>pima_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb6-16"><a href="#cb6-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">training_n =</span> <span class="fu">nrow</span>(Pima.tr),</span>
<span id="cb6-17"><a href="#cb6-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">test_n =</span> <span class="fu">nrow</span>(Pima.te),</span>
<span id="cb6-18"><a href="#cb6-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">test_accuracy =</span> <span class="fu">mean</span>(<span class="fu">predict</span>(pima_rf, Pima.te) <span class="sc">==</span> Pima.te<span class="sc">$</span>type),</span>
<span id="cb6-19"><a href="#cb6-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">baseline_log_loss =</span> <span class="fu">log_loss</span>(</span>
<span id="cb6-20"><a href="#cb6-20" aria-hidden="true" tabindex="-1"></a>    Pima.te<span class="sc">$</span>type,</span>
<span id="cb6-21"><a href="#cb6-21" aria-hidden="true" tabindex="-1"></a>    <span class="fu">predict</span>(pima_rf, Pima.te, <span class="at">type =</span> <span class="st">"prob"</span>)[, <span class="st">"Yes"</span>]</span>
<span id="cb6-22"><a href="#cb6-22" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb6-23"><a href="#cb6-23" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb6-24"><a href="#cb6-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb6-25"><a href="#cb6-25" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-26"><a href="#cb6-26" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(pima_summary, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb6-27"><a href="#cb6-27" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Public Pima diabetes prediction setup for the real-world variable-importance plot"</span></span>
<span id="cb6-28"><a href="#cb6-28" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Public Pima diabetes prediction setup for the real-world variable-importance plot</caption>
<thead>
<tr class="header">
<th style="text-align: right;">training_n</th>
<th style="text-align: right;">test_n</th>
<th style="text-align: right;">test_accuracy</th>
<th style="text-align: right;">baseline_log_loss</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">200</td>
<td style="text-align: right;">332</td>
<td style="text-align: right;">0.765</td>
<td style="text-align: right;">0.484</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">format_numeric_table</span>(pima_importance, <span class="at">digits =</span> <span class="dv">3</span>),</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Held-out permutation importance values in the public Pima diabetes example"</span></span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Held-out permutation importance values in the public Pima diabetes example</caption>
<thead>
<tr class="header">
<th style="text-align: left;">variable</th>
<th style="text-align: right;">importance</th>
<th style="text-align: right;">sd_importance</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">glu</td>
<td style="text-align: right;">0.110</td>
<td style="text-align: right;">0.016</td>
</tr>
<tr class="even">
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.026</td>
<td style="text-align: right;">0.013</td>
</tr>
<tr class="odd">
<td style="text-align: left;">bmi</td>
<td style="text-align: right;">0.023</td>
<td style="text-align: right;">0.010</td>
</tr>
<tr class="even">
<td style="text-align: left;">ped</td>
<td style="text-align: right;">0.010</td>
<td style="text-align: right;">0.012</td>
</tr>
<tr class="odd">
<td style="text-align: left;">npreg</td>
<td style="text-align: right;">0.009</td>
<td style="text-align: right;">0.008</td>
</tr>
<tr class="even">
<td style="text-align: left;">skin</td>
<td style="text-align: right;">-0.002</td>
<td style="text-align: right;">0.004</td>
</tr>
<tr class="odd">
<td style="text-align: left;">bp</td>
<td style="text-align: right;">-0.008</td>
<td style="text-align: right;">0.006</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-5-draw-the-real-world-variable-importance-plot" class="level2" data-number="71.6">
<h2 data-number="71.6" class="anchored" data-anchor-id="step-5-draw-the-real-world-variable-importance-plot"><span class="header-section-number">71.6</span> Step 5: Draw the real-world variable-importance plot</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb8"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb8-1"><a href="#cb8-1" aria-hidden="true" tabindex="-1"></a>pima_plot_df <span class="ot">&lt;-</span> pima_importance <span class="sc">|&gt;</span></span>
<span id="cb8-2"><a href="#cb8-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(<span class="at">variable =</span> <span class="fu">factor</span>(variable, <span class="at">levels =</span> <span class="fu">rev</span>(variable)))</span>
<span id="cb8-3"><a href="#cb8-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-4"><a href="#cb8-4" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(pima_plot_df, <span class="fu">aes</span>(<span class="at">x =</span> importance, <span class="at">y =</span> variable)) <span class="sc">+</span></span>
<span id="cb8-5"><a href="#cb8-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_segment</span>(<span class="fu">aes</span>(<span class="at">x =</span> <span class="dv">0</span>, <span class="at">xend =</span> importance, <span class="at">y =</span> variable, <span class="at">yend =</span> variable),</span>
<span id="cb8-6"><a href="#cb8-6" aria-hidden="true" tabindex="-1"></a>               <span class="at">linewidth =</span> <span class="fl">1.2</span>, <span class="at">color =</span> <span class="st">"#c7e9c0"</span>) <span class="sc">+</span></span>
<span id="cb8-7"><a href="#cb8-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_point</span>(<span class="at">size =</span> <span class="fl">3.4</span>, <span class="at">color =</span> <span class="st">"#238b45"</span>) <span class="sc">+</span></span>
<span id="cb8-8"><a href="#cb8-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="dv">0</span>, <span class="at">linetype =</span> <span class="dv">2</span>, <span class="at">color =</span> <span class="st">"#7f2704"</span>) <span class="sc">+</span></span>
<span id="cb8-9"><a href="#cb8-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb8-10"><a href="#cb8-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Glucose dominates the variable-importance ranking in the public Pima diabetes task"</span>,</span>
<span id="cb8-11"><a href="#cb8-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Held-out permutation importance from a random forest linked to Smith et al. (1988)"</span>,</span>
<span id="cb8-12"><a href="#cb8-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Increase in test-set log loss after permutation"</span>,</span>
<span id="cb8-13"><a href="#cb8-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="cn">NULL</span></span>
<span id="cb8-14"><a href="#cb8-14" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb8-15"><a href="#cb8-15" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb8-16"><a href="#cb8-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme</span>(</span>
<span id="cb8-17"><a href="#cb8-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid.major.y =</span> <span class="fu">element_blank</span>(),</span>
<span id="cb8-18"><a href="#cb8-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid.minor =</span> <span class="fu">element_blank</span>()</span>
<span id="cb8-19"><a href="#cb8-19" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/variable-importance_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>The real-world ranking is easy to interpret. Plasma glucose is the dominant predictor in this model, followed by age and body mass index. Some variables have near-zero or slightly negative importance values. That does not mean the variables are biologically irrelevant. It means that, in this particular fitted model and held-out test split, permuting those variables does not materially worsen predictive performance.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="71.7">
<h2 data-number="71.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">71.7</span> How to read the figure carefully</h2>
<p>Variable-importance plots are useful, but they are not causal diagrams. A highly ranked variable is not necessarily a causal driver. It is a predictor that matters for the fitted model's performance under the chosen importance metric.</p>
<p>It is also important to remember that importance is model specific. A variable can be very important in a random forest and less important in a logistic regression, or vice versa. Correlated predictors complicate interpretation further. If two variables carry similar information, permuting one may not hurt performance much because the model can lean on the other.</p>
<p>That is why permutation importance is often preferable to impurity-based importance for communication. It has a clearer performance interpretation, but it still requires caution. The figure is best understood as a ranking of model reliance, not a ranking of causal importance or policy priority.</p>
</section>
<section id="how-this-figure-complements-the-rest-of-the-book" class="level2" data-number="71.8">
<h2 data-number="71.8" class="anchored" data-anchor-id="how-this-figure-complements-the-rest-of-the-book"><span class="header-section-number">71.8</span> How this figure complements the rest of the book</h2>
<p>Variable-importance plots fit naturally beside the machine-learning and prediction chapters. They complement ROC curves by explaining which variables helped the classifier discriminate, and they complement partial-dependence plots by telling the reader which variables deserve closer inspection on a response surface.</p>
<p>They are also useful outside machine learning. A health-services model predicting readmission, a risk-adjustment model predicting spending, or a disease-screening model predicting diagnosis can all benefit from a concise ranked summary of which predictors carry the most predictive signal.</p>
</section>
<section id="further-reading" class="level2" data-number="71.9">
<h2 data-number="71.9" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">71.9</span> Further reading</h2>
<p>Breiman's random forest article remains a central reference for importance measures in tree-based models <span class="citation" data-cites="breiman2001">Breiman (<a href="#ref-breiman2001" role="doc-biblioref">2001</a>)</span>. Greenwell and Boehmke provide an accessible overview of importance plotting choices and why they matter for interpretation <span class="citation" data-cites="greenwell2020variable">Greenwell and Boehmke (<a href="#ref-greenwell2020variable" role="doc-biblioref">2020</a>)</span>. For the public health-prediction problem used here, Smith and colleagues remain the original source behind the Pima diabetes application <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-breiman2001" class="csl-entry" role="listitem">
Breiman, Leo. 2001. <span>"Random Forests."</span> <em>Machine Learning</em> 45 (1): 5-32. <a href="https://doi.org/10.1023/A:1010933404324">https://doi.org/10.1023/A:1010933404324</a>.
</div>
<div id="ref-greenwell2020variable" class="csl-entry" role="listitem">
Greenwell, Brandon M., and Bradley C. Boehmke. 2020. <span>"Variable Importance Plots-an Introduction to the Vip Package."</span> <em>The R Journal</em> 12 (1): 343-66. <a href="https://doi.org/10.32614/RJ-2020-013">https://doi.org/10.32614/RJ-2020-013</a>.
</div>
<div id="ref-smith1988" class="csl-entry" role="listitem">
Smith, J. W., J. E. Everhart, W. C. Dickson, W. C. Knowler, and R. S. Johannes. 1988. <span>"Using the <span>ADAP</span> Learning Algorithm to Forecast the Onset of Diabetes Mellitus."</span> In <em>Proceedings of the Symposium on Computer Applications in Medical Care</em>, 261-65.
</div>
</div>
</section>
