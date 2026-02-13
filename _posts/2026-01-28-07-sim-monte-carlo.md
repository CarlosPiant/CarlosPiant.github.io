---
title: "Monte Carlo Simulation: Asking \"What If?\" 10,000 Times"
date: 2026-01-28
categories: [tutorials, codes]
tags: [Simulation Models]
summary: "In a perfect world, every model would be solved with a neat little formula:"
---
<section id="introduction-when-your-model-is-allergic-to-closed-form-solutions" class="level1">
<h1>1. Introduction: when your model is allergic to closed-form solutions</h1>
<p>In a perfect world, every model would be solved with a neat little formula:</p>
<ul>
<li>You write down some equations,</li>
<li>You do a bit of algebra,</li>
<li>Out pops the answer.</li>
</ul>
<p>In the real world (especially in HEOR), your model often looks like this:</p>
<ul>
<li>A tangle of uncertain parameters,</li>
<li>A layered decision structure,</li>
<li>A stubborn refusal to produce a closed-form solution.</li>
</ul>
<p>Enter <strong>Monte Carlo simulation</strong>, which basically says:</p>
<blockquote class="blockquote">
<p>"If I can't solve it analytically, I'll <strong>simulate it a ridiculous number of times</strong> and see what happens on average."</p>
</blockquote>
<p>Instead of one deterministic answer, you get:</p>
<ul>
<li>A distribution of possible outcomes,</li>
<li>Means, medians, quantiles,</li>
<li>Probabilities of being above/below a threshold.</li>
</ul>
<hr>
</section>
<section id="foundations-what-is-monte-carlo-simulation" class="level1">
<h1>2. Foundations: what is Monte Carlo simulation?</h1>
<section id="the-core-idea" class="level2">
<h2 class="anchored" data-anchor-id="the-core-idea">2.1. The core idea</h2>
<p>Suppose you care about some outcome <span class="math inline">\(Y\)</span> that depends on uncertain inputs <span class="math inline">\(\theta\)</span>:</p>
<p><span class="math display">\[
Y = f(\theta),
\]</span></p>
<p>where <span class="math inline">\(\theta\)</span> itself is random (e.g., parameters with uncertainty). You want:</p>
<ul>
<li><span class="math inline">\(E[Y]\)</span> (expected outcome),</li>
<li>And maybe the full <strong>distribution</strong> of <span class="math inline">\(Y\)</span>.</li>
</ul>
<p>If <span class="math inline">\(f\)</span> is complicated and <span class="math inline">\(\theta\)</span> has a non-trivial distribution, analytic solutions may be impossible.</p>
<p>Monte Carlo says:</p>
<ol type="1">
<li>Sample <span class="math inline">\(\theta^{(1)}, \theta^{(2)}, \dots, \theta^{(N)}\)</span> from the distribution of <span class="math inline">\(\theta\)</span>.</li>
<li>Compute <span class="math inline">\(Y^{(k)} = f(\theta^{(k)})\)</span> for each draw.</li>
<li>Approximate:
<ul>
<li><span class="math inline">\(E[Y] \approx \frac{1}{N} \sum_{k=1}^N Y^{(k)}\)</span>,</li>
<li>Distribution of <span class="math inline">\(Y\)</span> via the empirical distribution of <span class="math inline">\(\{Y^{(k)}\}\)</span>.</li>
</ul></li>
</ol>
<p>As <span class="math inline">\(N\)</span> gets large, these approximations converge (by the <strong>Law of Large Numbers</strong>).</p>
</section>
<section id="steps-in-a-monte-carlo-simulation" class="level2">
<h2 class="anchored" data-anchor-id="steps-in-a-monte-carlo-simulation">2.2. Steps in a Monte Carlo simulation</h2>
<p>Typical steps:</p>
<ol type="1">
<li><strong>Define the model</strong> <span class="math inline">\(f(\cdot)\)</span> (e.g., cost-effectiveness model, risk model).</li>
<li><strong>Specify distributions</strong> for uncertain inputs (e.g., beta, gamma, normal).</li>
<li><strong>Draw random samples</strong> for each parameter.</li>
<li><strong>Compute outputs</strong> (costs, QALYs, net benefit, etc.).</li>
<li><strong>Summarize results</strong> (means, quantiles, probabilities).</li>
</ol>
<p>This general structure appears in:</p>
<ul>
<li>Probabilistic sensitivity analysis (PSA),</li>
<li>Risk analysis,</li>
<li>Value-of-information analysis,</li>
<li>Complex simulation models (microsimulation, DES, etc.).</li>
</ul>
<hr>
</section>
</section>
<section id="example-in-r-monte-carlo-for-a-toy-cost-effectiveness-model" class="level1">
<h1>3. Example in R: Monte Carlo for a toy cost-effectiveness model</h1>
<p>We'll create a simple scenario with two treatments:</p>
<ul>
<li><strong>Standard care (A)</strong>,</li>
<li><strong>New treatment (B)</strong>.</li>
</ul>
<p>We assume:</p>
<ul>
<li>Costs and QALYs have parameter uncertainty,</li>
<li>We want to estimate:
<ul>
<li>Expected incremental cost and QALY,</li>
<li>Distribution of incremental net benefit,</li>
<li>Probability that B is cost-effective at a given willingness-to-pay (WTP).</li>
</ul></li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">source</span>(<span class="st">"R/theme-heor-book.R"</span>) </span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">theme_set</span>(<span class="fu">theme_heor_book</span>())</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>n_sim <span class="ot">&lt;-</span> <span class="dv">10000</span>   <span class="co"># number of Monte Carlo samples</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>lambda <span class="ot">&lt;-</span> <span class="dv">100000</span> <span class="co"># willingness-to-pay per QALY (e.g., $100,000)</span></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a><span class="co"># Assume uncertain mean costs and QALYs for each strategy:</span></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a><span class="co"># Strategy A (standard care)</span></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>costA_mean <span class="ot">&lt;-</span> <span class="dv">20000</span>; costA_sd <span class="ot">&lt;-</span> <span class="dv">3000</span></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>qalyA_mean <span class="ot">&lt;-</span> <span class="fl">3.0</span>;   qalyA_sd <span class="ot">&lt;-</span> <span class="fl">0.4</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a><span class="co"># Strategy B (new treatment)</span></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>costB_mean <span class="ot">&lt;-</span> <span class="dv">26000</span>; costB_sd <span class="ot">&lt;-</span> <span class="dv">3500</span></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>qalyB_mean <span class="ot">&lt;-</span> <span class="fl">3.4</span>;   qalyB_sd <span class="ot">&lt;-</span> <span class="fl">0.5</span></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a><span class="co"># For illustration, assume normal distributions (truncated implicitly by context)</span></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>costA <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_sim, <span class="at">mean =</span> costA_mean, <span class="at">sd =</span> costA_sd)</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>costB <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_sim, <span class="at">mean =</span> costB_mean, <span class="at">sd =</span> costB_sd)</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>qalyA <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_sim, <span class="at">mean =</span> qalyA_mean, <span class="at">sd =</span> qalyA_sd)</span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>qalyB <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_sim, <span class="at">mean =</span> qalyB_mean, <span class="at">sd =</span> qalyB_sd)</span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a><span class="co"># Incrementals</span></span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a>dC <span class="ot">&lt;-</span> costB <span class="sc">-</span> costA</span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a>dE <span class="ot">&lt;-</span> qalyB <span class="sc">-</span> qalyA</span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a><span class="co"># Incremental Net Benefit (INB)</span></span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a>inb <span class="ot">&lt;-</span> lambda <span class="sc">*</span> dE <span class="sc">-</span> dC</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
<section id="summarizing-the-monte-carlo-output" class="level2">
<h2 class="anchored" data-anchor-id="summarizing-the-monte-carlo-output">3.1. Summarizing the Monte Carlo output</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>mc_summary <span class="ot">&lt;-</span> <span class="cf">function</span>(x) {</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">c</span>(</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">mean   =</span> <span class="fu">mean</span>(x),</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">sd     =</span> <span class="fu">sd</span>(x),</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">q025   =</span> <span class="fu">quantile</span>(x, <span class="fl">0.025</span>),</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>    <span class="at">q500   =</span> <span class="fu">quantile</span>(x, <span class="fl">0.5</span>),</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">q975   =</span> <span class="fu">quantile</span>(x, <span class="fl">0.975</span>)</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>dC_summary  <span class="ot">&lt;-</span> <span class="fu">mc_summary</span>(dC)</span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>dE_summary  <span class="ot">&lt;-</span> <span class="fu">mc_summary</span>(dE)</span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>inb_summary <span class="ot">&lt;-</span> <span class="fu">mc_summary</span>(inb)</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>dC_summary</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>      mean         sd  q025.2.5%   q500.50% q975.97.5% 
  5975.243   4597.546  -2962.920   5923.559  15041.286 </code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>dE_summary</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>      mean         sd  q025.2.5%   q500.50% q975.97.5% 
 0.4002174  0.6458570 -0.8507235  0.4018326  1.6914098 </code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>inb_summary</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>      mean         sd  q025.2.5%   q500.50% q975.97.5% 
  34046.50   64682.31  -91337.61   34272.09  162712.13 </code></pre>
</div>
</div>
</section>
<section id="probability-cost-effective" class="level2">
<h2 class="anchored" data-anchor-id="probability-cost-effective">3.2. Probability cost-effective</h2>
<p>The probability that B is cost-effective at $ $ is:</p>
<p><span class="math display">\[
P(\text{INB} &gt; 0) \approx \frac{1}{N} \sum_{k=1}^N \mathbf{1}\{ \text{INB}^{(k)} &gt; 0 \}.
\]</span></p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb8"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb8-1"><a href="#cb8-1" aria-hidden="true" tabindex="-1"></a>p_ce <span class="ot">&lt;-</span> <span class="fu">mean</span>(inb <span class="sc">&gt;</span> <span class="dv">0</span>)</span>
<span id="cb8-2"><a href="#cb8-2" aria-hidden="true" tabindex="-1"></a>p_ce</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>[1] 0.701</code></pre>
</div>
</div>
</section>
<section id="visualizing-the-distribution-of-inb" class="level2">
<h2 class="anchored" data-anchor-id="visualizing-the-distribution-of-inb">3.3. Visualizing the distribution of INB</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb10"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb10-1"><a href="#cb10-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb10-2"><a href="#cb10-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb10-3"><a href="#cb10-3" aria-hidden="true" tabindex="-1"></a>inb_df <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(<span class="at">inb =</span> inb)</span>
<span id="cb10-4"><a href="#cb10-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb10-5"><a href="#cb10-5" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(inb_df, <span class="fu">aes</span>(<span class="at">x =</span> inb)) <span class="sc">+</span></span>
<span id="cb10-6"><a href="#cb10-6" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_histogram</span>(<span class="at">bins =</span> <span class="dv">50</span>, <span class="at">color =</span> <span class="st">"white"</span>) <span class="sc">+</span></span>
<span id="cb10-7"><a href="#cb10-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_vline</span>(<span class="at">xintercept =</span> <span class="dv">0</span>, <span class="at">linetype =</span> <span class="st">"dashed"</span>) <span class="sc">+</span></span>
<span id="cb10-8"><a href="#cb10-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb10-9"><a href="#cb10-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Monte Carlo Distribution of Incremental Net Benefit"</span>,</span>
<span id="cb10-10"><a href="#cb10-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"INB"</span>,</span>
<span id="cb10-11"><a href="#cb10-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Frequency"</span></span>
<span id="cb10-12"><a href="#cb10-12" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/07-sim-monte-carlo_files/figure-html/mc-plot-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Distribution of incremental net benefit (INB) from Monte Carlo simulation.</figcaption>
</figure>
</div>
</div>
</div>
<p>This tiny example mirrors what full-blown PSA does in complex health decision models.</p>
<hr>
</section>
</section>
<section id="strengths-of-monte-carlo-simulation" class="level1">
<h1>4. Strengths of Monte Carlo simulation</h1>
<ol type="1">
<li><p><strong>Handles complex models</strong><br>
Monte Carlo works even when your model is non-linear, has interactions, and has no closed-form solution. As long as you can <strong>simulate</strong> outcomes, you can approximate expectations.</p></li>
<li><p><strong>Propagates parameter uncertainty</strong><br>
By sampling from parameter distributions, you propagate uncertainty through the model to outcomes - critical for credible decision analysis.</p></li>
<li><p><strong>Flexible and modular</strong><br>
You can add new parameters, structures, or outcomes without changing the basic Monte Carlo logic. It's easy to extend models as your HEOR questions evolve.</p></li>
<li><p><strong>Naturally supports VOI and scenario analysis</strong><br>
Monte Carlo output can be reused for value-of-information analysis, scenario comparisons, and sensitivity analyses.</p></li>
</ol>
<hr>
</section>
<section id="limitations-of-monte-carlo-simulation" class="level1">
<h1>5. Limitations of Monte Carlo simulation</h1>
<ol type="1">
<li><p><strong>Computationally expensive</strong><br>
Large models with many individuals, long time horizons, or many parameters can require <strong>hundreds of thousands or millions</strong> of simulations. This can be slow or memory-intensive.</p></li>
<li><p><strong>Garbage in, garbage out</strong><br>
If your parameter distributions are poorly specified, biased, or missing key structural uncertainty, the Monte Carlo results will faithfully propagate those problems.</p></li>
<li><p><strong>Monte Carlo error</strong><br>
With finite <span class="math inline">\(N\)</span>, there is <strong>simulation noise</strong>. You need enough simulations to reduce Monte Carlo error, especially in tail probabilities or VOI calculations.</p></li>
<li><p><strong>Can obscure model structure</strong><br>
Because everything is simulated, it can be easy to forget about underlying structural assumptions. It's important to complement simulation with conceptual checks and simpler analytic approximations when possible.</p></li>
</ol>
<hr>
</section>
<section id="why-monte-carlo-matters-for-heor-and-health-policy" class="level1">
<h1>6. Why Monte Carlo matters for HEOR and health policy</h1>
<p>Monte Carlo simulation is one of the <strong>foundational tools</strong> in HEOR because:</p>
<ul>
<li>Almost all <strong>probabilistic cost-effectiveness analyses</strong> use it,</li>
<li>Complex decision models (Markov, microsimulation, DES) rely on it,</li>
<li>Policy questions often hinge on uncertainty, not just point estimates.</li>
</ul>
<p>Examples:</p>
<ol type="1">
<li><p><strong>PSA in cost-effectiveness modeling</strong><br>
Varying costs, utilities, transition probabilities, and other parameters to obtain distributions of ICERs and cost-effectiveness acceptability curves.</p></li>
<li><p><strong>Budget impact and forecasting</strong><br>
Simulating ranges of future cost and utilization under different scenarios (e.g., different uptake patterns, adherence, or price trajectories).</p></li>
<li><p><strong>Value of information</strong><br>
Estimating how much we would gain (in expected net benefit) if we could eliminate uncertainty about specific parameters or groups of parameters.</p></li>
<li><p><strong>Risk and capacity planning</strong><br>
Simulating possible demand trajectories, bed occupancy, or resource usage to assess the risk of hitting capacity thresholds.</p></li>
</ol>
<p>In short: if your HEOR or policy question involves <strong>uncertainty</strong>, there's a good chance Monte Carlo is either already in the background - or should be. 😄</p>
<hr>
</section>
<section id="further-reading" class="level1">
<h1>7. Further reading</h1>
<ol type="1">
<li><p><strong>Briggs, Claxton, &amp; Sculpher - <em>Decision Modelling for Health Economic Evaluation</em>.</strong><br>
Classic reference for Monte Carlo simulation in health economic models, including PSA.</p></li>
<li><p><strong>Doubilet et al.&nbsp;(1985). <em>Probabilistic Sensitivity Analysis Using Monte Carlo Simulation.</em> Medical Decision Making.</strong><br>
Early description of Monte Carlo-based PSA in medical decision analysis.</p></li>
<li><p><strong>O'Hagan et al.&nbsp;- <em>Uncertainty in Health Economic Evaluation.</em></strong><br>
Focuses on handling parameter and structural uncertainty in health economic models.</p></li>
<li><p><strong>Kroese et al.&nbsp;- <em>Why the Monte Carlo Method is so Important Today.</em> Wiley Interdisciplinary Reviews.</strong><br>
A broader, non-HEOR perspective on Monte Carlo's importance in modern modeling.</p></li>
</ol>


<!-- -->

</section>
