---
title: "Random Number Generators from Uniform Draws"
date: 2026-03-21
categories: [tutorials, codes]
tags: ["Simulation Tools"]
summary: "This chapter builds a synthetic hospital-discharge dataset by generating each variable from a uniform random number and then transforming that draw into the target distribution. The point is to make the engine of..."
---
<p>This chapter builds a synthetic hospital-discharge dataset by generating each variable from a uniform random number and then transforming that draw into the target distribution. The point is to make the engine of simulation visible. Rather than calling <code>rnorm()</code>, <code>rexp()</code>, or <code>rbinom()</code> as black boxes, we will start with <code>runif()</code> and show how inverse-CDF logic creates non-uniform random variables. This is the basic architecture behind a large share of Monte Carlo simulation, including the patient-level models used in health economics and decision sciences <span class="citation" data-cites="vonneumann1951">Neumann (<a href="#ref-vonneumann1951" role="doc-biblioref">1951</a>)</span>; <span class="citation" data-cites="devroye1986">Devroye (<a href="#ref-devroye1986" role="doc-biblioref">1986</a>)</span>; <span class="citation" data-cites="stout2008">Stout and Goldie (<a href="#ref-stout2008" role="doc-biblioref">2008</a>)</span>.</p>
<p>The dataset will mimic a simple post-discharge cohort. <code>severity_score</code> will follow a normal distribution, <code>risk_group</code> will be a categorical variable with three levels, <code>waiting_days</code> will follow an exponential distribution, and <code>followup_attended</code> will be Bernoulli. These variables are not meant to reproduce one paper exactly. They are meant to reflect the kinds of ingredients that appear in applied simulation studies: latent severity, discrete risk strata, waiting times, and binary care events.</p>
<section id="why-start-from-the-uniform-distribution" class="level2" data-number="52.1">
<h2 data-number="52.1" class="anchored" data-anchor-id="why-start-from-the-uniform-distribution"><span class="header-section-number">52.1</span> Why start from the uniform distribution</h2>
<p>Pseudo-random number generators do not produce true randomness in a philosophical sense. They produce long deterministic sequences that behave enough like random draws for simulation work. Most software begins with a stream that approximates draws from the uniform distribution on the interval from 0 to 1:</p>
<p><span class="math display">\[
U \sim \text{Uniform}(0,1).
\]</span></p>
<p>The reason this is so useful is that the cumulative distribution function, or CDF, turns any random variable into a probability scale. If <code>X</code> has CDF <code>F</code>, then under regular conditions we can reverse that mapping:</p>
<p><span class="math display">\[
X = F^{-1}(U).
\]</span></p>
<p>This is the inverse-transform method. It says that if <code>U</code> is uniform on the unit interval, then applying the inverse CDF of the target distribution produces a draw from that distribution. That is the main idea of the chapter.</p>
</section>
<section id="what-variables-will-be-created" class="level2" data-number="52.2">
<h2 data-number="52.2" class="anchored" data-anchor-id="what-variables-will-be-created"><span class="header-section-number">52.2</span> What variables will be created</h2>
<p>The synthetic sample will contain four variables generated from the same underlying idea.</p>
<p><code>severity_score</code> will represent a standardized latent health-severity index and will be generated from a normal distribution with mean <span class="math inline">\(0\)</span> and standard deviation <span class="math inline">\(1\)</span>.</p>
<p><code>risk_group</code> will take the values <code>low</code>, <code>medium</code>, and <code>high</code>, with probabilities <span class="math inline">\(0.50\)</span>, <span class="math inline">\(0.35\)</span>, and <span class="math inline">\(0.15\)</span>.</p>
<p><code>waiting_days</code> will represent time until a specialist follow-up slot becomes available. It will be generated from an exponential distribution with rate <span class="math inline">\(0.08\)</span>, which implies a mean waiting time of <span class="math inline">\(12.5\)</span> days.</p>
<p><code>followup_attended</code> will be a binary indicator with success probability <span class="math inline">\(0.72\)</span>.</p>
<p>Together, these variables produce a simple but useful synthetic cohort that can be used to test models for continuous, discrete, time-to-event, and binary outcomes.</p>
</section>
<section id="the-inverse-cdf-logic" class="level2" data-number="52.3">
<h2 data-number="52.3" class="anchored" data-anchor-id="the-inverse-cdf-logic"><span class="header-section-number">52.3</span> The inverse-CDF logic</h2>
<section id="bernoulli-draws" class="level3" data-number="52.3.1">
<h3 data-number="52.3.1" class="anchored" data-anchor-id="bernoulli-draws"><span class="header-section-number">52.3.1</span> Bernoulli draws</h3>
<p>If <span class="math inline">\(Y\)</span> is Bernoulli with success probability <span class="math inline">\(p\)</span>, then its CDF jumps from <span class="math inline">\(0\)</span> to <span class="math inline">\(1 - p\)</span> at <span class="math inline">\(0\)</span>, and from <span class="math inline">\(1 - p\)</span> to <span class="math inline">\(1\)</span> at <span class="math inline">\(1\)</span>. The inverse-transform rule becomes</p>
<p><span class="math display">\[
Y =
\begin{cases}
1 &amp; \text{if } U &lt; p, \\
0 &amp; \text{otherwise.}
\end{cases}
\]</span></p>
<p>This is why thresholding a uniform draw generates a binary outcome.</p>
</section>
<section id="categorical-draws" class="level3" data-number="52.3.2">
<h3 data-number="52.3.2" class="anchored" data-anchor-id="categorical-draws"><span class="header-section-number">52.3.2</span> Categorical draws</h3>
<p>Suppose a variable has three categories with probabilities <span class="math inline">\(\pi_1\)</span>, <span class="math inline">\(\pi_2\)</span>, and <span class="math inline">\(\pi_3\)</span>. Then the unit interval is split into cumulative probability regions:</p>
<p><span class="math display">\[
[0, \pi_1), \qquad [\pi_1, \pi_1 + \pi_2), \qquad [\pi_1 + \pi_2, 1].
\]</span></p>
<p>The category is determined by where the uniform draw lands.</p>
</section>
<section id="exponential-draws" class="level3" data-number="52.3.3">
<h3 data-number="52.3.3" class="anchored" data-anchor-id="exponential-draws"><span class="header-section-number">52.3.3</span> Exponential draws</h3>
<p>If <span class="math inline">\(T\)</span> has exponential rate <span class="math inline">\(\lambda\)</span>, then</p>
<p><span class="math display">\[
F(t) = 1 - e^{-\lambda t}, \qquad t \ge 0.
\]</span></p>
<p>Set <span class="math inline">\(U = F(T)\)</span> and solve for <span class="math inline">\(T\)</span>:</p>
<p><span class="math display">\[
T = F^{-1}(U) = -\frac{\log(1 - U)}{\lambda}.
\]</span></p>
<p>Since <span class="math inline">\(1 - U\)</span> is also uniform on <span class="math inline">\((0,1)\)</span>, many implementations write this as</p>
<p><span class="math display">\[
T = -\frac{\log(U)}{\lambda}.
\]</span></p>
</section>
<section id="normal-draws" class="level3" data-number="52.3.4">
<h3 data-number="52.3.4" class="anchored" data-anchor-id="normal-draws"><span class="header-section-number">52.3.4</span> Normal draws</h3>
<p>For the normal distribution, the inverse CDF does not have a simple algebraic closed form, but the principle is exactly the same:</p>
<p><span class="math display">\[
X = \mu + \sigma \Phi^{-1}(U),
\]</span></p>
<p>where <span class="math inline">\(\Phi^{-1}\)</span> is the inverse standard normal CDF. In R, that function is <code>qnorm()</code>.</p>
</section>
</section>
<section id="step-1-generate-one-set-of-uniform-draws" class="level2" data-number="52.4">
<h2 data-number="52.4" class="anchored" data-anchor-id="step-1-generate-one-set-of-uniform-draws"><span class="header-section-number">52.4</span> Step 1: Generate one set of uniform draws</h2>
<p>We start from uniforms because that is the common input to all later transformations.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">2026</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n <span class="ot">&lt;-</span> <span class="dv">6000</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>u_severity <span class="ot">&lt;-</span> <span class="fu">runif</span>(n)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>u_risk <span class="ot">&lt;-</span> <span class="fu">runif</span>(n)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>u_waiting <span class="ot">&lt;-</span> <span class="fu">runif</span>(n)</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>u_followup <span class="ot">&lt;-</span> <span class="fu">runif</span>(n)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>uniform_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">stream =</span> <span class="fu">c</span>(<span class="st">"severity"</span>, <span class="st">"risk_group"</span>, <span class="st">"waiting_days"</span>, <span class="st">"followup_attended"</span>),</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">min_u =</span> <span class="fu">c</span>(<span class="fu">min</span>(u_severity), <span class="fu">min</span>(u_risk), <span class="fu">min</span>(u_waiting), <span class="fu">min</span>(u_followup)),</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean_u =</span> <span class="fu">c</span>(<span class="fu">mean</span>(u_severity), <span class="fu">mean</span>(u_risk), <span class="fu">mean</span>(u_waiting), <span class="fu">mean</span>(u_followup)),</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">max_u =</span> <span class="fu">c</span>(<span class="fu">max</span>(u_severity), <span class="fu">max</span>(u_risk), <span class="fu">max</span>(u_waiting), <span class="fu">max</span>(u_followup))</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>uniform_summary[, <span class="fu">c</span>(<span class="st">"min_u"</span>, <span class="st">"mean_u"</span>, <span class="st">"max_u"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(uniform_summary[, <span class="fu">c</span>(<span class="st">"min_u"</span>, <span class="st">"mean_u"</span>, <span class="st">"max_u"</span>)], <span class="dv">3</span>)</span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>  uniform_summary,</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of the independent uniform random-number streams"</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of the independent uniform random-number streams</caption>
<thead>
<tr class="header">
<th style="text-align: left;">stream</th>
<th style="text-align: right;">min_u</th>
<th style="text-align: right;">mean_u</th>
<th style="text-align: right;">max_u</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">severity</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0.497</td>
<td style="text-align: right;">1</td>
</tr>
<tr class="even">
<td style="text-align: left;">risk_group</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0.501</td>
<td style="text-align: right;">1</td>
</tr>
<tr class="odd">
<td style="text-align: left;">waiting_days</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0.499</td>
<td style="text-align: right;">1</td>
</tr>
<tr class="even">
<td style="text-align: left;">followup_attended</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0.502</td>
<td style="text-align: right;">1</td>
</tr>
</tbody>
</table>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a>uniform_plot <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">stream =</span> <span class="fu">rep</span>(<span class="fu">c</span>(<span class="st">"severity"</span>, <span class="st">"risk_group"</span>, <span class="st">"waiting_days"</span>, <span class="st">"followup_attended"</span>), <span class="at">each =</span> n),</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">u =</span> <span class="fu">c</span>(u_severity, u_risk, u_waiting, u_followup)</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(uniform_plot, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> u)) <span class="sc">+</span></span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_histogram</span>(</span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">bins =</span> <span class="dv">25</span>,</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"#6a994e"</span>,</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"white"</span></span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">facet_wrap</span>(<span class="sc">~</span> stream, <span class="at">ncol =</span> <span class="dv">2</span>) <span class="sc">+</span></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Uniform draws are the starting point for all later transformations"</span>,</span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Uniform random draw"</span>,</span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Count"</span></span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/random-number-generators_files/figure-html/unnamed-chunk-2-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
</section>
<section id="step-2-transform-uniforms-into-the-target-variables" class="level2" data-number="52.5">
<h2 data-number="52.5" class="anchored" data-anchor-id="step-2-transform-uniforms-into-the-target-variables"><span class="header-section-number">52.5</span> Step 2: Transform uniforms into the target variables</h2>
<p>Now apply the inverse-CDF rule separately to each variable.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>severity_score <span class="ot">&lt;-</span> <span class="fu">qnorm</span>(u_severity, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>)</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>risk_group <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>  u_risk <span class="sc">&lt;</span> <span class="fl">0.50</span>, <span class="st">"low"</span>,</span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ifelse</span>(u_risk <span class="sc">&lt;</span> <span class="fl">0.85</span>, <span class="st">"medium"</span>, <span class="st">"high"</span>)</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>waiting_days <span class="ot">&lt;-</span> <span class="sc">-</span><span class="fu">log</span>(<span class="dv">1</span> <span class="sc">-</span> u_waiting) <span class="sc">/</span> <span class="fl">0.08</span></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>followup_attended <span class="ot">&lt;-</span> <span class="fu">as.integer</span>(u_followup <span class="sc">&lt;</span> <span class="fl">0.72</span>)</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>synthetic_rng_data <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>  severity_score,</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">risk_group =</span> <span class="fu">factor</span>(risk_group, <span class="at">levels =</span> <span class="fu">c</span>(<span class="st">"low"</span>, <span class="st">"medium"</span>, <span class="st">"high"</span>)),</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  waiting_days,</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  followup_attended</span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>data_summary <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">variable =</span> <span class="fu">c</span>(<span class="st">"severity_score"</span>, <span class="st">"waiting_days"</span>, <span class="st">"followup_attended"</span>),</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">mean =</span> <span class="fu">c</span>(</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(synthetic_rng_data<span class="sc">$</span>severity_score),</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(synthetic_rng_data<span class="sc">$</span>waiting_days),</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(synthetic_rng_data<span class="sc">$</span>followup_attended)</span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>  <span class="at">sd =</span> <span class="fu">c</span>(</span>
<span id="cb3-27"><a href="#cb3-27" aria-hidden="true" tabindex="-1"></a>    <span class="fu">sd</span>(synthetic_rng_data<span class="sc">$</span>severity_score),</span>
<span id="cb3-28"><a href="#cb3-28" aria-hidden="true" tabindex="-1"></a>    <span class="fu">sd</span>(synthetic_rng_data<span class="sc">$</span>waiting_days),</span>
<span id="cb3-29"><a href="#cb3-29" aria-hidden="true" tabindex="-1"></a>    <span class="fu">sd</span>(synthetic_rng_data<span class="sc">$</span>followup_attended)</span>
<span id="cb3-30"><a href="#cb3-30" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb3-31"><a href="#cb3-31" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-32"><a href="#cb3-32" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-33"><a href="#cb3-33" aria-hidden="true" tabindex="-1"></a>data_summary[, <span class="fu">c</span>(<span class="st">"mean"</span>, <span class="st">"sd"</span>)] <span class="ot">&lt;-</span> <span class="fu">round</span>(data_summary[, <span class="fu">c</span>(<span class="st">"mean"</span>, <span class="st">"sd"</span>)], <span class="dv">3</span>)</span>
<span id="cb3-34"><a href="#cb3-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-35"><a href="#cb3-35" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb3-36"><a href="#cb3-36" aria-hidden="true" tabindex="-1"></a>  data_summary,</span>
<span id="cb3-37"><a href="#cb3-37" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Summary of variables created from inverse-CDF transformations"</span></span>
<span id="cb3-38"><a href="#cb3-38" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Summary of variables created from inverse-CDF transformations</caption>
<thead>
<tr class="header">
<th style="text-align: left;">variable</th>
<th style="text-align: right;">mean</th>
<th style="text-align: right;">sd</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">severity_score</td>
<td style="text-align: right;">-0.012</td>
<td style="text-align: right;">0.987</td>
</tr>
<tr class="even">
<td style="text-align: left;">waiting_days</td>
<td style="text-align: right;">12.613</td>
<td style="text-align: right;">13.003</td>
</tr>
<tr class="odd">
<td style="text-align: left;">followup_attended</td>
<td style="text-align: right;">0.714</td>
<td style="text-align: right;">0.452</td>
</tr>
</tbody>
</table>
</div>
</div>
<p>The transformation step is the heart of the chapter. Each variable began as a draw from <code>U(0,1)</code>, but the inverse-CDF mapping changed the shape of the distribution while preserving the stochastic information carried by the uniform draw.</p>
</section>
<section id="step-3-check-the-categorical-probabilities" class="level2" data-number="52.6">
<h2 data-number="52.6" class="anchored" data-anchor-id="step-3-check-the-categorical-probabilities"><span class="header-section-number">52.6</span> Step 3: Check the categorical probabilities</h2>
<p>The categorical variable does not use a smooth inverse formula. Instead, it partitions the unit interval into probability regions. The sample proportions should therefore be close to the target probabilities.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>risk_check <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb4-2"><a href="#cb4-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">risk_group =</span> <span class="fu">c</span>(<span class="st">"low"</span>, <span class="st">"medium"</span>, <span class="st">"high"</span>),</span>
<span id="cb4-3"><a href="#cb4-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_probability =</span> <span class="fu">c</span>(<span class="fl">0.50</span>, <span class="fl">0.35</span>, <span class="fl">0.15</span>),</span>
<span id="cb4-4"><a href="#cb4-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">sample_probability =</span> <span class="fu">as.numeric</span>(<span class="fu">prop.table</span>(<span class="fu">table</span>(synthetic_rng_data<span class="sc">$</span>risk_group)))</span>
<span id="cb4-5"><a href="#cb4-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb4-6"><a href="#cb4-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-7"><a href="#cb4-7" aria-hidden="true" tabindex="-1"></a>risk_check[, <span class="fu">c</span>(<span class="st">"true_probability"</span>, <span class="st">"sample_probability"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb4-8"><a href="#cb4-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(risk_check[, <span class="fu">c</span>(<span class="st">"true_probability"</span>, <span class="st">"sample_probability"</span>)], <span class="dv">3</span>)</span>
<span id="cb4-9"><a href="#cb4-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb4-10"><a href="#cb4-10" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb4-11"><a href="#cb4-11" aria-hidden="true" tabindex="-1"></a>  risk_check,</span>
<span id="cb4-12"><a href="#cb4-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Target and observed probabilities for the categorical variable"</span></span>
<span id="cb4-13"><a href="#cb4-13" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Target and observed probabilities for the categorical variable</caption>
<thead>
<tr class="header">
<th style="text-align: left;">risk_group</th>
<th style="text-align: right;">true_probability</th>
<th style="text-align: right;">sample_probability</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">low</td>
<td style="text-align: right;">0.50</td>
<td style="text-align: right;">0.506</td>
</tr>
<tr class="even">
<td style="text-align: left;">medium</td>
<td style="text-align: right;">0.35</td>
<td style="text-align: right;">0.337</td>
</tr>
<tr class="odd">
<td style="text-align: left;">high</td>
<td style="text-align: right;">0.15</td>
<td style="text-align: right;">0.157</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-4-fit-the-models-that-match-the-generating-process" class="level2" data-number="52.7">
<h2 data-number="52.7" class="anchored" data-anchor-id="step-4-fit-the-models-that-match-the-generating-process"><span class="header-section-number">52.7</span> Step 4: Fit the models that match the generating process</h2>
<p>The final step is to check whether standard estimators recover the parameters implied by the generating distributions.</p>
<p>For the normal variable, the natural estimators are the sample mean and sample standard deviation. For the exponential variable, the maximum likelihood estimator of the rate is</p>
<p><span class="math display">\[
\hat{\lambda} = \frac{1}{\bar{T}}.
\]</span></p>
<p>For the Bernoulli variable, the maximum likelihood estimator of <code>p</code> is the sample mean.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>normal_check <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">parameter =</span> <span class="fu">c</span>(<span class="st">"mean"</span>, <span class="st">"sd"</span>),</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_value =</span> <span class="fu">c</span>(<span class="dv">0</span>, <span class="dv">1</span>),</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_value =</span> <span class="fu">c</span>(</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>    <span class="fu">mean</span>(synthetic_rng_data<span class="sc">$</span>severity_score),</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>    <span class="fu">sd</span>(synthetic_rng_data<span class="sc">$</span>severity_score)</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>exponential_check <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">parameter =</span> <span class="st">"rate"</span>,</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_value =</span> <span class="fl">0.08</span>,</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_value =</span> <span class="dv">1</span> <span class="sc">/</span> <span class="fu">mean</span>(synthetic_rng_data<span class="sc">$</span>waiting_days)</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a>bernoulli_check <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>  <span class="at">parameter =</span> <span class="st">"p"</span>,</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">true_value =</span> <span class="fl">0.72</span>,</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">estimated_value =</span> <span class="fu">mean</span>(synthetic_rng_data<span class="sc">$</span>followup_attended)</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a>normal_check[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb5-23"><a href="#cb5-23" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(normal_check[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>)], <span class="dv">3</span>)</span>
<span id="cb5-24"><a href="#cb5-24" aria-hidden="true" tabindex="-1"></a>exponential_check[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb5-25"><a href="#cb5-25" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(exponential_check[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>)], <span class="dv">3</span>)</span>
<span id="cb5-26"><a href="#cb5-26" aria-hidden="true" tabindex="-1"></a>bernoulli_check[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>)] <span class="ot">&lt;-</span></span>
<span id="cb5-27"><a href="#cb5-27" aria-hidden="true" tabindex="-1"></a>  <span class="fu">round</span>(bernoulli_check[, <span class="fu">c</span>(<span class="st">"true_value"</span>, <span class="st">"estimated_value"</span>)], <span class="dv">3</span>)</span>
<span id="cb5-28"><a href="#cb5-28" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-29"><a href="#cb5-29" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb5-30"><a href="#cb5-30" aria-hidden="true" tabindex="-1"></a>  normal_check,</span>
<span id="cb5-31"><a href="#cb5-31" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Recovery of the parameters for the normal generator"</span></span>
<span id="cb5-32"><a href="#cb5-32" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Recovery of the parameters for the normal generator</caption>
<thead>
<tr class="header">
<th style="text-align: left;">parameter</th>
<th style="text-align: right;">true_value</th>
<th style="text-align: right;">estimated_value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">mean</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">-0.012</td>
</tr>
<tr class="even">
<td style="text-align: left;">sd</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0.987</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  exponential_check,</span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Recovery of the rate parameter for the exponential generator"</span></span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Recovery of the rate parameter for the exponential generator</caption>
<thead>
<tr class="header">
<th style="text-align: left;">parameter</th>
<th style="text-align: right;">true_value</th>
<th style="text-align: right;">estimated_value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">rate</td>
<td style="text-align: right;">0.08</td>
<td style="text-align: right;">0.079</td>
</tr>
</tbody>
</table>
</div>
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a>knitr<span class="sc">::</span><span class="fu">kable</span>(</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>  bernoulli_check,</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">caption =</span> <span class="st">"Recovery of the Bernoulli success probability"</span></span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<table class="caption-top table table-sm table-striped small">
<caption>Recovery of the Bernoulli success probability</caption>
<thead>
<tr class="header">
<th style="text-align: left;">parameter</th>
<th style="text-align: right;">true_value</th>
<th style="text-align: right;">estimated_value</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">p</td>
<td style="text-align: right;">0.72</td>
<td style="text-align: right;">0.714</td>
</tr>
</tbody>
</table>
</div>
</div>
</section>
<section id="step-5-visualize-the-transformed-distributions" class="level2" data-number="52.8">
<h2 data-number="52.8" class="anchored" data-anchor-id="step-5-visualize-the-transformed-distributions"><span class="header-section-number">52.8</span> Step 5: Visualize the transformed distributions</h2>
<p>The simplest diagnostic is to compare the shape of the generated variables with the shape we expect.</p>
<div class="cell">
<div class="sourceCode cell-code" id="cb8"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb8-1"><a href="#cb8-1" aria-hidden="true" tabindex="-1"></a>plot_normal <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb8-2"><a href="#cb8-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">seq</span>(<span class="sc">-</span><span class="dv">4</span>, <span class="dv">4</span>, <span class="at">length.out =</span> <span class="dv">300</span>)</span>
<span id="cb8-3"><a href="#cb8-3" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb8-4"><a href="#cb8-4" aria-hidden="true" tabindex="-1"></a>plot_normal<span class="sc">$</span>density <span class="ot">&lt;-</span> <span class="fu">dnorm</span>(plot_normal<span class="sc">$</span>x, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">1</span>)</span>
<span id="cb8-5"><a href="#cb8-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-6"><a href="#cb8-6" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(synthetic_rng_data, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> severity_score)) <span class="sc">+</span></span>
<span id="cb8-7"><a href="#cb8-7" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_histogram</span>(</span>
<span id="cb8-8"><a href="#cb8-8" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">y =</span> ..density..),</span>
<span id="cb8-9"><a href="#cb8-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">bins =</span> <span class="dv">35</span>,</span>
<span id="cb8-10"><a href="#cb8-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"#7aa874"</span>,</span>
<span id="cb8-11"><a href="#cb8-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"white"</span></span>
<span id="cb8-12"><a href="#cb8-12" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb8-13"><a href="#cb8-13" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(</span>
<span id="cb8-14"><a href="#cb8-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> plot_normal,</span>
<span id="cb8-15"><a href="#cb8-15" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> density),</span>
<span id="cb8-16"><a href="#cb8-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#1f3b2c"</span>,</span>
<span id="cb8-17"><a href="#cb8-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="dv">1</span></span>
<span id="cb8-18"><a href="#cb8-18" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb8-19"><a href="#cb8-19" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb8-20"><a href="#cb8-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Severity scores generated from the inverse normal CDF"</span>,</span>
<span id="cb8-21"><a href="#cb8-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"The histogram is the simulated sample; the line is the true density"</span>,</span>
<span id="cb8-22"><a href="#cb8-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Severity score"</span>,</span>
<span id="cb8-23"><a href="#cb8-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Density"</span></span>
<span id="cb8-24"><a href="#cb8-24" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb8-25"><a href="#cb8-25" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/random-number-generators_files/figure-html/unnamed-chunk-6-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
<div class="cell">
<div class="sourceCode cell-code" id="cb9"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb9-1"><a href="#cb9-1" aria-hidden="true" tabindex="-1"></a>plot_exponential <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb9-2"><a href="#cb9-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">seq</span>(<span class="dv">0</span>, <span class="fu">quantile</span>(synthetic_rng_data<span class="sc">$</span>waiting_days, <span class="fl">0.99</span>), <span class="at">length.out =</span> <span class="dv">300</span>)</span>
<span id="cb9-3"><a href="#cb9-3" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb9-4"><a href="#cb9-4" aria-hidden="true" tabindex="-1"></a>plot_exponential<span class="sc">$</span>density <span class="ot">&lt;-</span> <span class="fu">dexp</span>(plot_exponential<span class="sc">$</span>x, <span class="at">rate =</span> <span class="fl">0.08</span>)</span>
<span id="cb9-5"><a href="#cb9-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-6"><a href="#cb9-6" aria-hidden="true" tabindex="-1"></a>ggplot2<span class="sc">::</span><span class="fu">ggplot</span>(synthetic_rng_data, ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> waiting_days)) <span class="sc">+</span></span>
<span id="cb9-7"><a href="#cb9-7" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_histogram</span>(</span>
<span id="cb9-8"><a href="#cb9-8" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">y =</span> ..density..),</span>
<span id="cb9-9"><a href="#cb9-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">bins =</span> <span class="dv">35</span>,</span>
<span id="cb9-10"><a href="#cb9-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">fill =</span> <span class="st">"#bc6c25"</span>,</span>
<span id="cb9-11"><a href="#cb9-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"white"</span></span>
<span id="cb9-12"><a href="#cb9-12" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb9-13"><a href="#cb9-13" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">geom_line</span>(</span>
<span id="cb9-14"><a href="#cb9-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">data =</span> plot_exponential,</span>
<span id="cb9-15"><a href="#cb9-15" aria-hidden="true" tabindex="-1"></a>    ggplot2<span class="sc">::</span><span class="fu">aes</span>(<span class="at">x =</span> x, <span class="at">y =</span> density),</span>
<span id="cb9-16"><a href="#cb9-16" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"#5b3413"</span>,</span>
<span id="cb9-17"><a href="#cb9-17" aria-hidden="true" tabindex="-1"></a>    <span class="at">linewidth =</span> <span class="dv">1</span></span>
<span id="cb9-18"><a href="#cb9-18" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb9-19"><a href="#cb9-19" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">labs</span>(</span>
<span id="cb9-20"><a href="#cb9-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Waiting times generated from the inverse exponential CDF"</span>,</span>
<span id="cb9-21"><a href="#cb9-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">subtitle =</span> <span class="st">"The simulated histogram follows the true exponential density"</span>,</span>
<span id="cb9-22"><a href="#cb9-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Waiting days"</span>,</span>
<span id="cb9-23"><a href="#cb9-23" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Density"</span></span>
<span id="cb9-24"><a href="#cb9-24" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb9-25"><a href="#cb9-25" aria-hidden="true" tabindex="-1"></a>  ggplot2<span class="sc">::</span><span class="fu">theme_minimal</span>(<span class="at">base_size =</span> <span class="dv">12</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/simulation-tools/random-number-generators_files/figure-html/unnamed-chunk-7-1.png" class="img-fluid figure-img" width="672"></p>
</figure>
</div>
</div>
</div>
</section>
<section id="main-assumptions-and-practical-limits" class="level2" data-number="52.9">
<h2 data-number="52.9" class="anchored" data-anchor-id="main-assumptions-and-practical-limits"><span class="header-section-number">52.9</span> Main assumptions and practical limits</h2>
<p>The most important assumption is that the inverse CDF exists and can be evaluated accurately. For many standard distributions this is straightforward, either analytically or numerically. For other distributions, especially complicated multivariate ones, direct inverse-transform sampling may be inefficient or inconvenient.</p>
<p>Another practical point is that computers generate pseudo-random numbers, not metaphysical randomness. For most simulation work this is enough, but reproducibility depends on the generator, the seed, and the software implementation. That is why simulation code should always set a seed when exact replication matters.</p>
<p>This chapter also treats the four variables as independent. That is useful for learning, but real synthetic datasets often need correlation structures, conditional dependence, or hierarchical variation. Once that becomes necessary, inverse-transform logic is still useful, but it usually has to be combined with additional modeling ideas.</p>
</section>
<section id="further-reading" class="level2" data-number="52.10">
<h2 data-number="52.10" class="anchored" data-anchor-id="further-reading"><span class="header-section-number">52.10</span> Further reading</h2>
<p>Devroye remains one of the classic references on non-uniform random variate generation and is especially useful for readers who want to understand the computational details behind simulation algorithms <span class="citation" data-cites="devroye1986">Devroye (<a href="#ref-devroye1986" role="doc-biblioref">1986</a>)</span>. Von Neumann's early discussion of random digits is part of the historical foundation of Monte Carlo methods <span class="citation" data-cites="vonneumann1951">Neumann (<a href="#ref-vonneumann1951" role="doc-biblioref">1951</a>)</span>. For readers working in health economics, Stout and Goldie provide an applied bridge from random-number generation to patient-level disease simulation and decision modeling <span class="citation" data-cites="stout2008">Stout and Goldie (<a href="#ref-stout2008" role="doc-biblioref">2008</a>)</span>.</p>


<div id="refs" class="references csl-bib-body hanging-indent" data-entry-spacing="0" role="list">
<div id="ref-devroye1986" class="csl-entry" role="listitem">
Devroye, Luc. 1986. <em>Non-Uniform Random Variate Generation</em>. New York: Springer-Verlag.
</div>
<div id="ref-vonneumann1951" class="csl-entry" role="listitem">
Neumann, John von. 1951. <span>"Various Techniques Used in Connection with Random Digits."</span> In <em>Monte Carlo Method</em>, 36-38. National Bureau of Standards.
</div>
<div id="ref-stout2008" class="csl-entry" role="listitem">
Stout, Natasha K., and Sue J. Goldie. 2008. <span>"Keeping the Noise down: Common Random Numbers for Disease Simulation Modeling."</span> <em>Health Care Management Science</em> 11 (4): 399-406. <a href="https://doi.org/10.1007/s10729-008-9067-6">https://doi.org/10.1007/s10729-008-9067-6</a>.
</div>
</div>
</section>
