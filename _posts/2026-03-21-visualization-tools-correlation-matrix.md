---
title: "Visualizing a Correlation Matrix"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Visualization Tools"]
summary: "This chapter creates a correlation-matrix heatmap for clinical predictors in the Pima Indian diabetes dataset distributed with MASS. The figure is designed to show which variables move together, which ones are nearly..."
---
<p>This chapter creates a correlation-matrix heatmap for clinical predictors in the Pima Indian diabetes dataset distributed with <code>MASS</code>. The figure is designed to show which variables move together, which ones are nearly unrelated, and where clusters of overlap may create modeling challenges such as multicollinearity. In practice, this kind of figure is often one of the first visual checks before fitting regression models, regularized models, or risk-prediction systems. The underlying dataset comes from the diabetes-prediction application described by Smith and coauthors <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>.</p>
<p>The figure we will build is a reordered correlation matrix shown as a heatmap. Each cell represents the correlation between two variables. The sign tells us the direction of the association, and the magnitude tells us how strong the linear relationship is. The clustering step is important because it places similar variables near each other, which makes the visual pattern much easier to read than a matrix left in arbitrary column order.</p>
<section id="what-the-visualization-is-showing" class="level2" data-number="58.1">
<h2 data-number="58.1" class="anchored" data-anchor-id="what-the-visualization-is-showing"><span class="header-section-number">58.1</span> What the visualization is showing</h2>
<p>We will use the numeric predictors in the <code>Pima.tr</code> data:</p>
<p><code>npreg</code> is the number of pregnancies. <code>glu</code> is plasma glucose concentration. <code>bp</code> is diastolic blood pressure. <code>skin</code> is triceps skin-fold thickness. <code>bmi</code> is body mass index. <code>ped</code> is the diabetes pedigree function. <code>age</code> is age in years.</p>
<p>The correlation matrix will summarize how these variables relate to each other pairwise. The diagonal will always be 1 because each variable is perfectly correlated with itself. Off-diagonal cells are the interesting part. A positive value near 1 indicates that two variables rise together strongly. A value near 0 indicates weak linear association. A negative value indicates that one variable tends to rise as the other falls.</p>
</section>
<section id="step-1-load-the-data-and-keep-the-numeric-predictors" class="level2" data-number="58.2">
<h2 data-number="58.2" class="anchored" data-anchor-id="step-1-load-the-data-and-keep-the-numeric-predictors"><span class="header-section-number">58.2</span> Step 1: Load the data and keep the numeric predictors</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">data</span>(<span class="st">"Pima.tr"</span>, <span class="at">package =</span> <span class="st">"MASS"</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>pima_numeric <span class="ot">&lt;-</span> Pima.tr[, <span class="fu">c</span>(<span class="st">"npreg"</span>, <span class="st">"glu"</span>, <span class="st">"bp"</span>, <span class="st">"skin"</span>, <span class="st">"bmi"</span>, <span class="st">"ped"</span>, <span class="st">"age"</span>)]</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>pima_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_size =</span> <span class="fu">nrow</span>(pima_numeric),</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">variables =</span> <span class="fu">ncol</span>(pima_numeric),</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_glucose =</span> <span class="fu">mean</span>(pima_numeric<span class="sc">$</span>glu),</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_bmi =</span> <span class="fu">mean</span>(pima_numeric<span class="sc">$</span>bmi),</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_age =</span> <span class="fu">mean</span>(pima_numeric<span class="sc">$</span>age)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>pima_summary[, <span class="fu">c</span>(<span class="st">"mean_glucose"</span>, <span class="st">"mean_bmi"</span>, <span class="st">"mean_age"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(pima_summary[, <span class="fu">c</span>(<span class="st">"mean_glucose"</span>, <span class="st">"mean_bmi"</span>, <span class="st">"mean_age"</span>)], <span class="dv">2</span>)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>  pima_summary,</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the variables used in the correlation heatmap"</span></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the variables used in the correlation heatmap</caption>
<thead>
<tr class="header">
<th style="text-align: right;">sample_size</th>
<th style="text-align: right;">variables</th>
<th style="text-align: right;">mean_glucose</th>
<th style="text-align: right;">mean_bmi</th>
<th style="text-align: right;">mean_age</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">200</td>
<td style="text-align: right;">7</td>
<td style="text-align: right;">123.97</td>
<td style="text-align: right;">32.31</td>
<td style="text-align: right;">32.11</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This is a small step, but it matters. Correlation matrices require numeric variables, and it is good practice to be explicit about which variables are going into the figure.</p>
</section>
<section id="step-2-compute-the-correlation-matrix" class="level2" data-number="58.3">
<h2 data-number="58.3" class="anchored" data-anchor-id="step-2-compute-the-correlation-matrix"><span class="header-section-number">58.3</span> Step 2: Compute the correlation matrix</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>cor_mat <span class="ot">&lt;-</span> <span class="fu">cor</span>(pima_numeric, <span class="at">use =</span> <span class="st">"pairwise.complete.obs"</span>)</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>cor_mat <span class="ot">&lt;-</span> <span class="fu">round</span>(cor_mat, <span class="dv">2</span>)</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>  cor_mat,</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Correlation matrix for the Pima diabetes predictors"</span></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Correlation matrix for the Pima diabetes predictors</caption>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: right;">npreg</th>
<th style="text-align: right;">glu</th>
<th style="text-align: right;">bp</th>
<th style="text-align: right;">skin</th>
<th style="text-align: right;">bmi</th>
<th style="text-align: right;">ped</th>
<th style="text-align: right;">age</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">npreg</td>
<td style="text-align: right;">1.00</td>
<td style="text-align: right;">0.17</td>
<td style="text-align: right;">0.25</td>
<td style="text-align: right;">0.11</td>
<td style="text-align: right;">0.06</td>
<td style="text-align: right;">-0.12</td>
<td style="text-align: right;">0.60</td>
</tr>
<tr class="even">
<td style="text-align: left;">glu</td>
<td style="text-align: right;">0.17</td>
<td style="text-align: right;">1.00</td>
<td style="text-align: right;">0.27</td>
<td style="text-align: right;">0.22</td>
<td style="text-align: right;">0.22</td>
<td style="text-align: right;">0.06</td>
<td style="text-align: right;">0.34</td>
</tr>
<tr class="odd">
<td style="text-align: left;">bp</td>
<td style="text-align: right;">0.25</td>
<td style="text-align: right;">0.27</td>
<td style="text-align: right;">1.00</td>
<td style="text-align: right;">0.26</td>
<td style="text-align: right;">0.24</td>
<td style="text-align: right;">-0.05</td>
<td style="text-align: right;">0.39</td>
</tr>
<tr class="even">
<td style="text-align: left;">skin</td>
<td style="text-align: right;">0.11</td>
<td style="text-align: right;">0.22</td>
<td style="text-align: right;">0.26</td>
<td style="text-align: right;">1.00</td>
<td style="text-align: right;">0.66</td>
<td style="text-align: right;">0.10</td>
<td style="text-align: right;">0.25</td>
</tr>
<tr class="odd">
<td style="text-align: left;">bmi</td>
<td style="text-align: right;">0.06</td>
<td style="text-align: right;">0.22</td>
<td style="text-align: right;">0.24</td>
<td style="text-align: right;">0.66</td>
<td style="text-align: right;">1.00</td>
<td style="text-align: right;">0.19</td>
<td style="text-align: right;">0.13</td>
</tr>
<tr class="even">
<td style="text-align: left;">ped</td>
<td style="text-align: right;">-0.12</td>
<td style="text-align: right;">0.06</td>
<td style="text-align: right;">-0.05</td>
<td style="text-align: right;">0.10</td>
<td style="text-align: right;">0.19</td>
<td style="text-align: right;">1.00</td>
<td style="text-align: right;">-0.07</td>
</tr>
<tr class="odd">
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.60</td>
<td style="text-align: right;">0.34</td>
<td style="text-align: right;">0.39</td>
<td style="text-align: right;">0.25</td>
<td style="text-align: right;">0.13</td>
<td style="text-align: right;">-0.07</td>
<td style="text-align: right;">1.00</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The table is useful, but a table becomes hard to scan once the number of variables grows. That is why the heatmap is valuable. It turns the matrix into a pattern that the eye can read quickly.</p>
</section>
<section id="step-3-reorder-the-variables-by-similarity" class="level2" data-number="58.4">
<h2 data-number="58.4" class="anchored" data-anchor-id="step-3-reorder-the-variables-by-similarity"><span class="header-section-number">58.4</span> Step 3: Reorder the variables by similarity</h2>
<p>To make the heatmap easier to interpret, we reorder the variables using hierarchical clustering based on correlation similarity. Variables with similar correlation profiles will appear close to each other in the final plot.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>distance_mat <span class="ot">&lt;-</span> <span class="fu">as.dist</span>(<span class="dv">1</span> <span class="sc">-</span> <span class="fu">abs</span>(<span class="fu">cor</span>(pima_numeric, <span class="at">use =</span> <span class="st">"pairwise.complete.obs"</span>)))</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>cluster_order <span class="ot">&lt;-</span> <span class="fu">hclust</span>(distance_mat)<span class="sc">$</span>order</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>ordered_names <span class="ot">&lt;-</span> <span class="fu">colnames</span>(pima_numeric)[cluster_order]</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>cor_ordered <span class="ot">&lt;-</span> cor_mat[ordered_names, ordered_names]</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>cor_long <span class="ot">&lt;-</span> <span class="fu">as.data.frame</span>(<span class="fu">as.table</span>(cor_ordered))</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a><span class="fu">names</span>(cor_long) <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="st">"var_x"</span>, <span class="st">"var_y"</span>, <span class="st">"correlation"</span>)</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>cor_long<span class="sc">$</span>var_x <span class="ot">&lt;-</span> <span class="fu">factor</span>(cor_long<span class="sc">$</span>var_x, <span class="at">levels =</span> ordered_names)</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>cor_long<span class="sc">$</span>var_y <span class="ot">&lt;-</span> <span class="fu">factor</span>(cor_long<span class="sc">$</span>var_y, <span class="at">levels =</span> <span class="fu">rev</span>(ordered_names))</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</div>
<p>This step does not change any correlation values. It only changes the order in which they appear. That distinction is important. Clustering is a display tool here, not a new statistical estimate.</p>
</section>
<section id="step-4-create-the-heatmap" class="level2" data-number="58.5">
<h2 data-number="58.5" class="anchored" data-anchor-id="step-4-create-the-heatmap"><span class="header-section-number">58.5</span> Step 4: Create the heatmap</h2>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  cor_long,</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> var_x, <span class="at">y =</span> var_y, <span class="at">fill =</span> correlation)</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>) <span class="sc">+</span></span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_tile</span>(<span class="at">color =</span> <span class="st">"white"</span>, <span class="at">linewidth =</span> <span class="fl">0.6</span>) <span class="sc">+</span></span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_text</span>(</span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">label =</span> <span class="fu">sprintf</span>(<span class="st">"%.2f"</span>, correlation)),</span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">size =</span> <span class="fl">3.2</span>,</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"black"</span></span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">scale_fill_gradient2</span>(</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">low =</span> <span class="st">"#6b7a8f"</span>,</span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">mid =</span> <span class="st">"#f7f4ed"</span>,</span>
<span id="cb4-14"><a href="#cb4-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">high =</span> <span class="st">"#0b5d4b"</span>,</span>
<span id="cb4-15"><a href="#cb4-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">midpoint =</span> <span class="dv">0</span>,</span>
<span id="cb4-16"><a href="#cb4-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">limits =</span> <span class="fu">c</span>(<span class="sc">-</span><span class="dv">1</span>, <span class="dv">1</span>)</span>
<span id="cb4-17"><a href="#cb4-17" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-18"><a href="#cb4-18" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb4-19"><a href="#cb4-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Correlation matrix of diabetes risk predictors"</span>,</span>
<span id="cb4-20"><a href="#cb4-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"Pima Indian diabetes data, reordered by hierarchical clustering"</span>,</span>
<span id="cb4-21"><a href="#cb4-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="cn">NULL</span>,</span>
<span id="cb4-22"><a href="#cb4-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="cn">NULL</span>,</span>
<span id="cb4-23"><a href="#cb4-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"Correlation"</span></span>
<span id="cb4-24"><a href="#cb4-24" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb4-25"><a href="#cb4-25" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>) <span class="sc">+</span></span>
<span id="cb4-26"><a href="#cb4-26" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme</span>(</span>
<span id="cb4-27"><a href="#cb4-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">panel.grid =</span> ggplot2<span class="sc">::</span><span class="fu">element_blank</span>(),</span>
<span id="cb4-28"><a href="#cb4-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">axis.text.x =</span> ggplot2<span class="sc">::</span><span class="fu">element_text</span>(<span class="at">angle =</span> <span class="dv">45</span>, <span class="at">hjust =</span> <span class="dv">1</span>),</span>
<span id="cb4-29"><a href="#cb4-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">aspect.ratio =</span> <span class="dv">1</span></span>
<span id="cb4-30"><a href="#cb4-30" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/visualization-tools/correlation-matrix_files/figure-html/unnamed-chunk-4-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<p>This is the main figure of the chapter. It is academically useful because it combines exact values with visual structure. The color scale tells the reader whether a relationship is weak or strong, and the clustering helps reveal variable groups that share similar association patterns.</p>
</section>
<section id="step-5-highlight-the-strongest-pairwise-relationships" class="level2" data-number="58.6">
<h2 data-number="58.6" class="anchored" data-anchor-id="step-5-highlight-the-strongest-pairwise-relationships"><span class="header-section-number">58.6</span> Step 5: Highlight the strongest pairwise relationships</h2>
<p>Sometimes the most useful written companion to a correlation heatmap is a short ranked table of the strongest off-diagonal relationships.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>upper_index <span class="ot">&lt;-</span> <span class="fu">upper.tri</span>(cor_ordered, <span class="at">diag =</span> <span class="cn">FALSE</span>)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>strong_pairs <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">var_1 =</span> <span class="fu">rownames</span>(cor_ordered)[<span class="fu">row</span>(cor_ordered)[upper_index]],</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">var_2 =</span> <span class="fu">colnames</span>(cor_ordered)[<span class="fu">col</span>(cor_ordered)[upper_index]],</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">correlation =</span> cor_ordered[upper_index]</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>strong_pairs<span class="sc">$</span>abs_correlation <span class="ot">&lt;-</span> <span class="fu">abs</span>(strong_pairs<span class="sc">$</span>correlation)</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>strong_pairs <span class="ot">&lt;-</span> strong_pairs[<span class="fu">order</span>(strong_pairs<span class="sc">$</span>abs_correlation, <span class="at">decreasing =</span> <span class="cn">TRUE</span>), ]</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>strong_pairs<span class="sc">$</span>correlation <span class="ot">&lt;-</span> <span class="fu">round</span>(strong_pairs<span class="sc">$</span>correlation, <span class="dv">2</span>)</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">head</span>(strong_pairs[, <span class="fu">c</span>(<span class="st">"var_1"</span>, <span class="st">"var_2"</span>, <span class="st">"correlation"</span>)], <span class="dv">6</span>),</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Strongest pairwise correlations in the Pima data"</span></span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Strongest pairwise correlations in the Pima data</caption>
<thead>
<tr class="header">
<th style="text-align: left;"></th>
<th style="text-align: left;">var_1</th>
<th style="text-align: left;">var_2</th>
<th style="text-align: right;">correlation</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">1</td>
<td style="text-align: left;">skin</td>
<td style="text-align: left;">bmi</td>
<td style="text-align: right;">0.66</td>
</tr>
<tr class="even">
<td style="text-align: left;">21</td>
<td style="text-align: left;">npreg</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.60</td>
</tr>
<tr class="odd">
<td style="text-align: left;">19</td>
<td style="text-align: left;">bp</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.39</td>
</tr>
<tr class="even">
<td style="text-align: left;">18</td>
<td style="text-align: left;">glu</td>
<td style="text-align: left;">age</td>
<td style="text-align: right;">0.34</td>
</tr>
<tr class="odd">
<td style="text-align: left;">6</td>
<td style="text-align: left;">glu</td>
<td style="text-align: left;">bp</td>
<td style="text-align: right;">0.27</td>
</tr>
<tr class="even">
<td style="text-align: left;">4</td>
<td style="text-align: left;">skin</td>
<td style="text-align: left;">bp</td>
<td style="text-align: right;">0.26</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>This table is especially helpful in methods sections or appendices where the reader may want a compact summary of the strongest dependencies without reading every tile in the matrix.</p>
</section>
<section id="how-to-read-the-figure-carefully" class="level2" data-number="58.7">
<h2 data-number="58.7" class="anchored" data-anchor-id="how-to-read-the-figure-carefully"><span class="header-section-number">58.7</span> How to read the figure carefully</h2>
<p>A correlation heatmap is descriptive, not causal. If two variables are strongly correlated, that does not tell us that one causes the other. It only tells us that they move together linearly in the observed sample.</p>
<p>It is also important to remember that Pearson correlation measures linear association. If two variables are related in a strongly nonlinear but monotonic way, the heatmap may understate the real relationship. In those settings, a Spearman correlation matrix can be a useful alternative. Missing data handling matters too. In this example we used pairwise complete observations, which is convenient, but different missing-data strategies can produce slightly different matrices.</p>
<p>Finally, correlation is scale-free but sample-dependent. A pattern seen in one clinical sample may not carry over cleanly to another population. That is why a correlation matrix is best treated as an exploratory and reporting tool rather than as a final inferential result.</p>
</section>
<section id="how-this-figure-helps-the-rest-of-the-book" class="level2" data-number="58.8">
<h2 data-number="58.8" class="anchored" data-anchor-id="how-this-figure-helps-the-rest-of-the-book"><span class="header-section-number">58.8</span> How this figure helps the rest of the book</h2>
<p>This kind of figure is useful almost everywhere in the tutorial collection. Before linear or logistic regression, it helps reveal overlapping predictors. Before lasso or ridge, it helps show why shrinkage may be needed. Before simulation work, it can suggest realistic dependence structures. In health economics and decision sciences, it is often one of the simplest ways to communicate the internal structure of a dataset before moving to a more formal model.</p>
<p>Once the template is clear, it can be adapted easily. You can switch from Pearson to Spearman correlation, display only the lower triangle, add clustering dendrograms, use significance masking, or apply the same visual logic to covariance matrices or similarity matrices.</p>
</section>
<section id="further-reading" class="level2" data-number="58.9">
<h2 data-number="58.9" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">58.9</span> Further reading</h2>
<p>For the real-world prediction problem underlying the dataset used here, Smith and coauthors provide the original diabetes application <span class="citation" data-cites="smith1988">Smith et al. (<a href="#ref-smith1988" role="doc-biblioref">1988</a>)</span>. A natural next step after this chapter is to compare Pearson and Spearman correlation heatmaps on the same data, or to build a clustered correlation matrix for one of the larger clinical or claims-based datasets used elsewhere in the book.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-smith1988" class="csl-entry" role="listitem">
Smith, J. W., J. E. Everhart, W. C. Dickson, W. C. Knowler, and R. S. Johannes. 1988. <span>"Using the <span>ADAP</span> Learning Algorithm to Forecast the Onset of Diabetes Mellitus."</span> In <em>Proceedings of the Symposium on Computer Applications in Medical Care</em>, 261-65.
</div>
</div>
</section>
