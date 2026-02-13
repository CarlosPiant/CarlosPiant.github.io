---
title: "Event-Study Designs in R: Watching Policy Effects Over Time"
date: 2025-12-14
categories: [tutorials, codes]
tags: [Causal Inference]
summary: "Difference-in-differences (DiD) is great when you want a single number:"
---
<section id="introduction-when-you-want-more-than-a-beforeafter-selfie" class="level1">
<h1>1. Introduction: when you want more than a before/after selfie</h1>
<p>Difference-in-differences (DiD) is great when you want a <strong>single number</strong>:</p>
<blockquote class="blockquote">
<p>"On average, the policy changed the outcome by X units."</p>
</blockquote>
<p>But sometimes that's not enough. You (or a reviewer 😅) might ask:</p>
<ul>
<li>Did the effect <strong>grow over time</strong>?</li>
<li>Did it <strong>fade out</strong> after a few years?</li>
<li>Were there <strong>anticipation effects</strong> <em>before</em> the policy started?</li>
<li>Did something weird happen in one specific year?</li>
</ul>
<p>An event-study design basically says:</p>
<blockquote class="blockquote">
<p>"Let's not just compare <em>before vs after</em> - let's estimate the effect at each time point <strong>relative to when the policy started</strong>."</p>
</blockquote>
<p>So instead of a single DiD coefficient, we get a <strong>series of coefficients</strong>:</p>
<ul>
<li>One for each period <em>before</em> the policy (leads),</li>
<li>One for each period <em>after</em> the policy (lags),</li>
<li>All relative to a chosen <strong>reference period</strong> (often the year just before treatment).</li>
</ul>
<p>This gives us a dynamic picture:</p>
<ul>
<li>Great for checking the <strong>parallel trends</strong> assumption,</li>
<li>Great for telling a richer story about how the effect unfolds.</li>
</ul>
<p>In this tutorial we will:</p>
<ul>
<li>Show how event-study designs extend DiD,</li>
<li>Simulate data with a policy that has <strong>dynamic effects</strong>,</li>
<li>Estimate an event-study regression in R,</li>
<li>Plot the event-time coefficients with confidence intervals,</li>
<li>Reflect on why this matters in HEOR and health policy,</li>
<li>Point you to further reading.</li>
</ul>
<hr>
</section>
<section id="from-did-to-event-study" class="level1">
<h1>2. From DiD to event-study</h1>
<section id="basic-setup" class="level2">
<h2 class="anchored" data-anchor-id="basic-setup">2.1. Basic setup</h2>
<p>We'll again imagine:</p>
<ul>
<li>Units <span class="math inline">\(i\)</span> (e.g., hospitals, regions, individuals),</li>
<li>Time periods <span class="math inline">\(t\)</span> (e.g., years),</li>
<li>A policy that starts at a certain time <span class="math inline">\(t = 0\)</span> for treated units,</li>
<li>A comparison group that never receives the policy.</li>
</ul>
<p>We define <strong>event time</strong>:</p>
<ul>
<li><span class="math inline">\(k = t - T_i\)</span>, where <span class="math inline">\(T_i\)</span> is the time when unit <span class="math inline">\(i\)</span> is treated.</li>
<li>For units never treated, <span class="math inline">\(T_i\)</span> is undefined; we handle them a bit differently (more on that below).</li>
</ul>
<p>In the simplest case, all treated units get the policy at the same time, so <span class="math inline">\(T_i\)</span> is the same for all treated units.</p>
</section>
<section id="event-study-regression-with-leads-and-lags" class="level2">
<h2 class="anchored" data-anchor-id="event-study-regression-with-leads-and-lags">2.2. Event-study regression with leads and lags</h2>
<p>A common event-study specification (with a single treated cohort) is:</p>
<p><span class="math display">\[
Y_{it} = \alpha_i + \lambda_t
+ \sum_{k \neq -1} \beta_k \, \mathbf{1}\{\text{EventTime}_{it} = k\}
+ \varepsilon_{it},
\]</span></p>
<p>where:</p>
<ul>
<li><span class="math inline">\(Y_{it}\)</span> is the outcome,</li>
<li><span class="math inline">\(\alpha_i\)</span> are <strong>unit fixed effects</strong> (e.g., hospital-specific),</li>
<li><span class="math inline">\(\lambda_t\)</span> are <strong>time fixed effects</strong> (common shocks over time),</li>
<li><span class="math inline">\(\mathbf{1}\{\text{EventTime}_{it} = k\}\)</span> is an indicator that unit <span class="math inline">\(i\)</span> is <span class="math inline">\(k\)</span> periods away from treatment at time <span class="math inline">\(t\)</span>,</li>
<li>We omit <span class="math inline">\(k = -1\)</span> as the <strong>reference period</strong> (often the last pre-treatment period),</li>
<li><span class="math inline">\(\beta_k\)</span> is the <strong>average effect</strong> at event time <span class="math inline">\(k\)</span>.</li>
</ul>
<p>Interpretation:</p>
<ul>
<li>For <span class="math inline">\(k &lt; 0\)</span> (leads): we expect <span class="math inline">\(\beta_k \approx 0\)</span> if parallel trends holds.</li>
<li>For <span class="math inline">\(k \ge 0\)</span> (lags): <span class="math inline">\(\beta_k\)</span> traces out how the policy effect evolves over time.</li>
</ul>
<hr>
</section>
</section>
<section id="example-in-r-synthetic-event-study-data" class="level1">
<h1>3. Example in R: synthetic event-study data</h1>
<p>We'll simulate a simplified scenario:</p>
<ul>
<li>200 units (e.g., hospitals),</li>
<li>10 time periods (labeled -4, -3, ..., 4, 5), where 0 is the first period with the policy,</li>
<li>Half of the units are <strong>treated</strong> starting at time 0,</li>
<li>Half are <strong>never treated</strong> and act as a comparison group,</li>
<li>The effect of the policy grows over time for treated units.</li>
</ul>
<p>Think of the outcome as something like:</p>
<ul>
<li>Average monthly admissions per hospital,</li>
<li>Average cost per patient,</li>
<li>A quality score.</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="co"># Number of units and time periods</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>n_units <span class="ot">&lt;-</span> <span class="dv">200</span></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>time_points <span class="ot">&lt;-</span> <span class="sc">-</span><span class="dv">4</span><span class="sc">:</span><span class="dv">5</span>  <span class="co"># event time, where 0 is first treated period</span></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>T <span class="ot">&lt;-</span> <span class="fu">length</span>(time_points)</span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a><span class="co"># Half treated, half never-treated</span></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>id <span class="ot">&lt;-</span> <span class="dv">1</span><span class="sc">:</span>n_units</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>treated_ids <span class="ot">&lt;-</span> id[<span class="dv">1</span><span class="sc">:</span>(n_units <span class="sc">/</span> <span class="dv">2</span>)]</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>control_ids <span class="ot">&lt;-</span> id[(n_units <span class="sc">/</span> <span class="dv">2</span> <span class="sc">+</span> <span class="dv">1</span>)<span class="sc">:</span>n_units]</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a><span class="co"># Create panel data structure</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>es_data <span class="ot">&lt;-</span> <span class="fu">expand.grid</span>(</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">id   =</span> id,</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>  <span class="at">time =</span> time_points</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>es_data<span class="sc">$</span>treat <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(es_data<span class="sc">$</span>id <span class="sc">%in%</span> treated_ids, <span class="dv">1</span>, <span class="dv">0</span>)</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a><span class="co"># Unit fixed effects</span></span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>unit_fe <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(n_units, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">5</span>)</span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a><span class="co"># Time fixed effects (common shocks)</span></span>
<span id="cb1-25"><a href="#cb1-25" aria-hidden="true" tabindex="-1"></a>time_fe <span class="ot">&lt;-</span> <span class="fu">rnorm</span>(T, <span class="at">mean =</span> <span class="dv">0</span>, <span class="at">sd =</span> <span class="dv">2</span>)</span>
<span id="cb1-26"><a href="#cb1-26" aria-hidden="true" tabindex="-1"></a><span class="fu">names</span>(time_fe) <span class="ot">&lt;-</span> <span class="fu">as.character</span>(time_points)</span>
<span id="cb1-27"><a href="#cb1-27" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-28"><a href="#cb1-28" aria-hidden="true" tabindex="-1"></a><span class="co"># True dynamic treatment effects for treated units (lags)</span></span>
<span id="cb1-29"><a href="#cb1-29" aria-hidden="true" tabindex="-1"></a><span class="co"># k = 0, 1, 2, 3, 4, 5</span></span>
<span id="cb1-30"><a href="#cb1-30" aria-hidden="true" tabindex="-1"></a>true_effects <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="st">"0"</span> <span class="ot">=</span> <span class="dv">2</span>, <span class="st">"1"</span> <span class="ot">=</span> <span class="dv">4</span>, <span class="st">"2"</span> <span class="ot">=</span> <span class="dv">6</span>, <span class="st">"3"</span> <span class="ot">=</span> <span class="dv">7</span>, <span class="st">"4"</span> <span class="ot">=</span> <span class="dv">7</span>, <span class="st">"5"</span> <span class="ot">=</span> <span class="dv">7</span>)</span>
<span id="cb1-31"><a href="#cb1-31" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-32"><a href="#cb1-32" aria-hidden="true" tabindex="-1"></a><span class="co"># Baseline level (e.g., average outcome)</span></span>
<span id="cb1-33"><a href="#cb1-33" aria-hidden="true" tabindex="-1"></a>baseline <span class="ot">&lt;-</span> <span class="dv">50</span></span>
<span id="cb1-34"><a href="#cb1-34" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-35"><a href="#cb1-35" aria-hidden="true" tabindex="-1"></a><span class="co"># Generate outcome</span></span>
<span id="cb1-36"><a href="#cb1-36" aria-hidden="true" tabindex="-1"></a>es_data<span class="sc">$</span>Y <span class="ot">&lt;-</span> <span class="cn">NA_real_</span></span>
<span id="cb1-37"><a href="#cb1-37" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-38"><a href="#cb1-38" aria-hidden="true" tabindex="-1"></a><span class="cf">for</span> (i <span class="cf">in</span> <span class="fu">seq_len</span>(<span class="fu">nrow</span>(es_data))) {</span>
<span id="cb1-39"><a href="#cb1-39" aria-hidden="true" tabindex="-1"></a>  this_id   <span class="ot">&lt;-</span> es_data<span class="sc">$</span>id[i]</span>
<span id="cb1-40"><a href="#cb1-40" aria-hidden="true" tabindex="-1"></a>  this_time <span class="ot">&lt;-</span> es_data<span class="sc">$</span>time[i]</span>
<span id="cb1-41"><a href="#cb1-41" aria-hidden="true" tabindex="-1"></a>  this_treat <span class="ot">&lt;-</span> es_data<span class="sc">$</span>treat[i]</span>
<span id="cb1-42"><a href="#cb1-42" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-43"><a href="#cb1-43" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Unit and time components</span></span>
<span id="cb1-44"><a href="#cb1-44" aria-hidden="true" tabindex="-1"></a>  mu_unit <span class="ot">&lt;-</span> unit_fe[this_id]</span>
<span id="cb1-45"><a href="#cb1-45" aria-hidden="true" tabindex="-1"></a>  mu_time <span class="ot">&lt;-</span> time_fe[<span class="fu">as.character</span>(this_time)]</span>
<span id="cb1-46"><a href="#cb1-46" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-47"><a href="#cb1-47" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Dynamic treatment effect: only for treated units and time &gt;= 0</span></span>
<span id="cb1-48"><a href="#cb1-48" aria-hidden="true" tabindex="-1"></a>  effect <span class="ot">&lt;-</span> <span class="dv">0</span></span>
<span id="cb1-49"><a href="#cb1-49" aria-hidden="true" tabindex="-1"></a>  <span class="cf">if</span> (this_treat <span class="sc">==</span> <span class="dv">1</span> <span class="sc">&amp;&amp;</span> this_time <span class="sc">&gt;=</span> <span class="dv">0</span>) {</span>
<span id="cb1-50"><a href="#cb1-50" aria-hidden="true" tabindex="-1"></a>    k <span class="ot">&lt;-</span> <span class="fu">as.character</span>(this_time)</span>
<span id="cb1-51"><a href="#cb1-51" aria-hidden="true" tabindex="-1"></a>    effect <span class="ot">&lt;-</span> true_effects[k]</span>
<span id="cb1-52"><a href="#cb1-52" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb1-53"><a href="#cb1-53" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-54"><a href="#cb1-54" aria-hidden="true" tabindex="-1"></a>  es_data<span class="sc">$</span>Y[i] <span class="ot">&lt;-</span> baseline <span class="sc">+</span> mu_unit <span class="sc">+</span> mu_time <span class="sc">+</span> effect <span class="sc">+</span> <span class="fu">rnorm</span>(<span class="dv">1</span>, <span class="dv">0</span>, <span class="dv">5</span>)</span>
<span id="cb1-55"><a href="#cb1-55" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb1-56"><a href="#cb1-56" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-57"><a href="#cb1-57" aria-hidden="true" tabindex="-1"></a><span class="fu">head</span>(es_data)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>  id time treat        Y
1  1   -4     1 52.19147
2  2   -4     1 54.46517
3  3   -4     1 68.35354
4  4   -4     1 52.16984
5  5   -4     1 50.08152
6  6   -4     1 71.35143</code></pre>
</div>
</div>
<hr>
<section id="event-time-variable-and-reference-period" class="level2">
<h2 class="anchored" data-anchor-id="event-time-variable-and-reference-period">3.1. Event-time variable and reference period</h2>
<p>Here, <code>time</code> is already <strong>event time</strong> (relative to the policy start), so we can treat it as such:</p>
<ul>
<li>Negative values: leads,</li>
<li>Zero and positive values: lags.</li>
</ul>
<p>We will construct a factor for event time and choose <strong>-1</strong> as the reference period (the last pre-treatment period).</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a><span class="co"># Event time is just the 'time' variable</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>es_data<span class="sc">$</span>event_time <span class="ot">&lt;-</span> es_data<span class="sc">$</span>time</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a><span class="co"># Make a factor for event time, dropping the reference period (-1)</span></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>es_data<span class="sc">$</span>event_time_f <span class="ot">&lt;-</span> <span class="fu">factor</span>(es_data<span class="sc">$</span>event_time)</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a><span class="co"># We'll define the reference period as -1 (last pre-policy period)</span></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a><span class="co"># For convenience, we keep all levels but will interpret coefficients</span></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a><span class="co"># relative to event_time = -1.</span></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a><span class="fu">levels</span>(es_data<span class="sc">$</span>event_time_f)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code> [1] "-4" "-3" "-2" "-1" "0"  "1"  "2"  "3"  "4"  "5" </code></pre>
</div>
</div>
<hr>
</section>
<section id="estimating-an-event-study-regression" class="level2">
<h2 class="anchored" data-anchor-id="estimating-an-event-study-regression">3.2. Estimating an event-study regression</h2>
<p>We now estimate:</p>
<p><span class="math display">\[
Y_{it} = \alpha_i + \lambda_t
+ \sum_{k \neq -1} \beta_k \big(\mathbf{1}\{\text{event\_time}_{it} = k\} \times \text{treat}_i\big)
+ \varepsilon_{it}.
\]</span></p>
<p>In R, we can approximate this via:</p>
<ul>
<li>Including <strong>unit fixed effects</strong> via <code>factor(id)</code>,</li>
<li>Including <strong>time fixed effects</strong> via <code>factor(time)</code>,</li>
<li>Interacting <code>treat</code> with the event-time factor (excluding the reference period).</li>
</ul>
<p>We will:</p>
<ol type="1">
<li>Drop observations at event_time = -1 when interacting (so this is the reference),</li>
<li>Fit the model with <code>lm()</code>.</li>
</ol>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a><span class="co"># Create a factor for event_time with -1 as an explicit level</span></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a>es_data<span class="sc">$</span>event_time_f <span class="ot">&lt;-</span> <span class="fu">factor</span>(es_data<span class="sc">$</span>event_time)</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a><span class="co"># We'll keep event_time_f as is, but create a version that excludes -1</span></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a><span class="co"># for the interaction, so that event_time = -1 is the omitted reference.</span></span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>es_data <span class="ot">&lt;-</span> es_data <span class="sc">%&gt;%</span></span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">event_time_f_no_ref =</span> <span class="fu">ifelse</span>(event_time <span class="sc">==</span> <span class="sc">-</span><span class="dv">1</span>, <span class="cn">NA</span>, <span class="fu">as.character</span>(event_time))</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>es_data<span class="sc">$</span>event_time_f_no_ref <span class="ot">&lt;-</span> <span class="fu">factor</span>(es_data<span class="sc">$</span>event_time_f_no_ref)</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a><span class="co"># Fit event-study regression:</span></span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a><span class="co"># Y ~ unit FE + time FE + treat: event_time dummies (excluding reference period)</span></span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a>es_fit <span class="ot">&lt;-</span> <span class="fu">lm</span>(</span>
<span id="cb5-18"><a href="#cb5-18" aria-hidden="true" tabindex="-1"></a>  Y <span class="sc">~</span> <span class="fu">factor</span>(id) <span class="sc">+</span> <span class="fu">factor</span>(time) <span class="sc">+</span> treat<span class="sc">:</span>event_time_f_no_ref,</span>
<span id="cb5-19"><a href="#cb5-19" aria-hidden="true" tabindex="-1"></a>  <span class="at">data =</span> es_data</span>
<span id="cb5-20"><a href="#cb5-20" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-21"><a href="#cb5-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-22"><a href="#cb5-22" aria-hidden="true" tabindex="-1"></a><span class="fu">summary</span>(es_fit)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>
Call:
lm(formula = Y ~ factor(id) + factor(time) + treat:event_time_f_no_ref, 
    data = es_data)

Residuals:
     Min       1Q   Median       3Q      Max 
-13.8862  -3.0381   0.1373   3.0802  16.3496 

Coefficients: (1 not defined because of singularities)
                             Estimate Std. Error t value Pr(&gt;|t|)    
(Intercept)                  60.39893    1.82553  33.086  &lt; 2e-16 ***
factor(id)2                   1.32975    2.29996   0.578 0.563235    
factor(id)3                   9.94477    2.29996   4.324 1.63e-05 ***
factor(id)4                   0.56392    2.29996   0.245 0.806345    
factor(id)5                   0.27065    2.29996   0.118 0.906338    
factor(id)6                   7.56285    2.29996   3.288 0.001030 ** 
factor(id)7                   0.74714    2.29996   0.325 0.745337    
factor(id)8                  -6.72644    2.29996  -2.925 0.003498 ** 
factor(id)9                  -3.52886    2.29996  -1.534 0.125152    
factor(id)10                 -0.62235    2.29996  -0.271 0.786740    
factor(id)11                  5.78952    2.29996   2.517 0.011926 *  
factor(id)12                  6.33891    2.29996   2.756 0.005917 ** 
factor(id)13                  5.18779    2.29996   2.256 0.024231 *  
factor(id)14                  3.30892    2.29996   1.439 0.150436    
factor(id)15                 -4.99398    2.29996  -2.171 0.030054 *  
factor(id)16                 11.37493    2.29996   4.946 8.39e-07 ***
factor(id)17                  3.81064    2.29996   1.657 0.097752 .  
factor(id)18                 -6.43353    2.29996  -2.797 0.005216 ** 
factor(id)19                  6.02790    2.29996   2.621 0.008854 ** 
factor(id)20                 -1.00308    2.29996  -0.436 0.662803    
factor(id)21                 -6.52088    2.29996  -2.835 0.004638 ** 
factor(id)22                 -1.63353    2.29996  -0.710 0.477657    
factor(id)23                 -5.66588    2.29996  -2.463 0.013866 *  
factor(id)24                 -4.37870    2.29996  -1.904 0.057115 .  
factor(id)25                 -5.24682    2.29996  -2.281 0.022665 *  
factor(id)26                -11.38263    2.29996  -4.949 8.25e-07 ***
factor(id)27                  3.52968    2.29996   1.535 0.125064    
factor(id)28                  5.30205    2.29996   2.305 0.021280 *  
factor(id)29                 -4.70414    2.29996  -2.045 0.040989 *  
factor(id)30                  7.51218    2.29996   3.266 0.001113 ** 
factor(id)31                 -0.17988    2.29996  -0.078 0.937671    
factor(id)32                  0.36894    2.29996   0.160 0.872576    
factor(id)33                  6.70819    2.29996   2.917 0.003588 ** 
factor(id)34                  5.52484    2.29996   2.402 0.016414 *  
factor(id)35                  5.58149    2.29996   2.427 0.015344 *  
factor(id)36                  3.79983    2.29996   1.652 0.098706 .  
factor(id)37                  0.25568    2.29996   0.111 0.911498    
factor(id)38                 -2.39339    2.29996  -1.041 0.298209    
factor(id)39                  0.39642    2.29996   0.172 0.863178    
factor(id)40                 -2.69659    2.29996  -1.172 0.241192    
factor(id)41                 -4.29268    2.29996  -1.866 0.062168 .  
factor(id)42                  1.02076    2.29996   0.444 0.657237    
factor(id)43                 -1.80525    2.29996  -0.785 0.432625    
factor(id)44                 12.51661    2.29996   5.442 6.09e-08 ***
factor(id)45                  9.39541    2.29996   4.085 4.63e-05 ***
factor(id)46                 -7.54472    2.29996  -3.280 0.001059 ** 
factor(id)47                  0.15957    2.29996   0.069 0.944698    
factor(id)48                  0.47643    2.29996   0.207 0.835921    
factor(id)49                  6.52366    2.29996   2.836 0.004620 ** 
factor(id)50                 -2.07773    2.29996  -0.903 0.366463    
factor(id)51                  5.13098    2.29996   2.231 0.025827 *  
factor(id)52                  0.54980    2.29996   0.239 0.811098    
factor(id)53                  2.93406    2.29996   1.276 0.202249    
factor(id)54                  7.89900    2.29996   3.434 0.000609 ***
factor(id)55                 -1.21734    2.29996  -0.529 0.596681    
factor(id)56                  9.74482    2.29996   4.237 2.40e-05 ***
factor(id)57                 -7.21416    2.29996  -3.137 0.001740 ** 
factor(id)58                  5.36868    2.29996   2.334 0.019707 *  
factor(id)59                  1.37725    2.29996   0.599 0.549380    
factor(id)60                  5.42873    2.29996   2.360 0.018378 *  
factor(id)61                  5.13796    2.29996   2.234 0.025626 *  
factor(id)62                 -0.92557    2.29996  -0.402 0.687423    
factor(id)63                 -2.37924    2.29996  -1.034 0.301074    
factor(id)64                 -7.26472    2.29996  -3.159 0.001615 ** 
factor(id)65                 -4.22325    2.29996  -1.836 0.066511 .  
factor(id)66                  0.29857    2.29996   0.130 0.896729    
factor(id)67                  6.55402    2.29996   2.850 0.004434 ** 
factor(id)68                 -2.52557    2.29996  -1.098 0.272331    
factor(id)69                  3.69380    2.29996   1.606 0.108467    
factor(id)70                 10.58518    2.29996   4.602 4.51e-06 ***
factor(id)71                 -1.51402    2.29996  -0.658 0.510453    
factor(id)72                -10.29562    2.29996  -4.476 8.13e-06 ***
factor(id)73                  6.92332    2.29996   3.010 0.002652 ** 
factor(id)74                 -4.89795    2.29996  -2.130 0.033360 *  
factor(id)75                 -4.06429    2.29996  -1.767 0.077401 .  
factor(id)76                  5.41195    2.29996   2.353 0.018741 *  
factor(id)77                 -1.72238    2.29996  -0.749 0.454045    
factor(id)78                 -7.05698    2.29996  -3.068 0.002189 ** 
factor(id)79                  1.39809    2.29996   0.608 0.543358    
factor(id)80                 -2.73601    2.29996  -1.190 0.234385    
factor(id)81                  3.34735    2.29996   1.455 0.145757    
factor(id)82                  3.50355    2.29996   1.523 0.127880    
factor(id)83                  0.03415    2.29996   0.015 0.988157    
factor(id)84                  5.75451    2.29996   2.502 0.012449 *  
factor(id)85                 -1.57550    2.29996  -0.685 0.493435    
factor(id)86                  2.81080    2.29996   1.222 0.221848    
factor(id)87                  7.18871    2.29996   3.126 0.001807 ** 
factor(id)88                  2.52509    2.29996   1.098 0.272422    
factor(id)89                  0.61601    2.29996   0.268 0.788860    
factor(id)90                  7.31500    2.29996   3.180 0.001499 ** 
factor(id)91                  4.75190    2.29996   2.066 0.038983 *  
factor(id)92                  1.36117    2.29996   0.592 0.554054    
factor(id)93                 -1.42331    2.29996  -0.619 0.536110    
factor(id)94                 -0.95605    2.29996  -0.416 0.677701    
factor(id)95                  7.62489    2.29996   3.315 0.000936 ***
factor(id)96                 -3.19893    2.29996  -1.391 0.164462    
factor(id)97                  9.16084    2.29996   3.983 7.11e-05 ***
factor(id)98                  6.43486    2.29996   2.798 0.005207 ** 
factor(id)99                 -0.21389    2.29996  -0.093 0.925917    
factor(id)100                -0.69092    2.29996  -0.300 0.763906    
factor(id)101                -7.60725    2.39019  -3.183 0.001487 ** 
factor(id)102                -4.75404    2.39019  -1.989 0.046875 *  
factor(id)103                -6.43565    2.39019  -2.693 0.007166 ** 
factor(id)104                -8.05838    2.39019  -3.371 0.000766 ***
factor(id)105                -9.70223    2.39019  -4.059 5.16e-05 ***
factor(id)106                -4.87573    2.39019  -2.040 0.041526 *  
factor(id)107               -10.74406    2.39019  -4.495 7.46e-06 ***
factor(id)108               -16.96122    2.39019  -7.096 1.93e-12 ***
factor(id)109                -5.76644    2.39019  -2.413 0.015954 *  
factor(id)110                -1.65977    2.39019  -0.694 0.487528    
factor(id)111               -10.86167    2.39019  -4.544 5.93e-06 ***
factor(id)112                -5.34937    2.39019  -2.238 0.025356 *  
factor(id)113               -14.25392    2.39019  -5.964 3.04e-09 ***
factor(id)114                -5.73495    2.39019  -2.399 0.016538 *  
factor(id)115                -2.92562    2.39019  -1.224 0.221129    
factor(id)116                -1.32954    2.39019  -0.556 0.578118    
factor(id)117                -4.24149    2.39019  -1.775 0.076165 .  
factor(id)118               -11.13540    2.39019  -4.659 3.45e-06 ***
factor(id)119               -10.16724    2.39019  -4.254 2.23e-05 ***
factor(id)120               -12.68450    2.39019  -5.307 1.27e-07 ***
factor(id)121                -2.38738    2.39019  -0.999 0.318033    
factor(id)122               -11.35892    2.39019  -4.752 2.19e-06 ***
factor(id)123               -10.63015    2.39019  -4.447 9.30e-06 ***
factor(id)124                -6.08461    2.39019  -2.546 0.011001 *  
factor(id)125                 2.21367    2.39019   0.926 0.354510    
factor(id)126               -11.69794    2.39019  -4.894 1.09e-06 ***
factor(id)127                -4.78074    2.39019  -2.000 0.045654 *  
factor(id)128                -5.89900    2.39019  -2.468 0.013692 *  
factor(id)129               -11.26106    2.39019  -4.711 2.68e-06 ***
factor(id)130                -8.07092    2.39019  -3.377 0.000751 ***
factor(id)131                 3.05406    2.39019   1.278 0.201525    
factor(id)132                -4.09777    2.39019  -1.714 0.086649 .  
factor(id)133                -4.36320    2.39019  -1.825 0.068119 .  
factor(id)134                -7.73126    2.39019  -3.235 0.001243 ** 
factor(id)135               -15.75299    2.39019  -6.591 5.94e-11 ***
factor(id)136                -2.74525    2.39019  -1.149 0.250914    
factor(id)137               -15.21118    2.39019  -6.364 2.57e-10 ***
factor(id)138                -1.75794    2.39019  -0.735 0.462154    
factor(id)139                 3.67421    2.39019   1.537 0.124443    
factor(id)140               -11.74237    2.39019  -4.913 9.91e-07 ***
factor(id)141                -1.04703    2.39019  -0.438 0.661408    
factor(id)142                -9.27863    2.39019  -3.882 0.000108 ***
factor(id)143               -14.15604    2.39019  -5.923 3.88e-09 ***
factor(id)144               -12.21627    2.39019  -5.111 3.59e-07 ***
factor(id)145               -10.90415    2.39019  -4.562 5.46e-06 ***
factor(id)146                -8.50759    2.39019  -3.559 0.000383 ***
factor(id)147               -13.77327    2.39019  -5.762 9.95e-09 ***
factor(id)148                -4.91795    2.39019  -2.058 0.039796 *  
factor(id)149                -0.83791    2.39019  -0.351 0.725963    
factor(id)150                -9.88662    2.39019  -4.136 3.71e-05 ***
factor(id)151                -3.22401    2.39019  -1.349 0.177576    
factor(id)152                -0.47581    2.39019  -0.199 0.842236    
factor(id)153                -4.91644    2.39019  -2.057 0.039857 *  
factor(id)154                -9.62097    2.39019  -4.025 5.96e-05 ***
factor(id)155                -7.85033    2.39019  -3.284 0.001044 ** 
factor(id)156                -9.40081    2.39019  -3.933 8.75e-05 ***
factor(id)157                -0.17372    2.39019  -0.073 0.942068    
factor(id)158                -8.05170    2.39019  -3.369 0.000774 ***
factor(id)159                -1.48761    2.39019  -0.622 0.533781    
factor(id)160                -6.35044    2.39019  -2.657 0.007966 ** 
factor(id)161                 0.81185    2.39019   0.340 0.734157    
factor(id)162               -15.41099    2.39019  -6.448 1.50e-10 ***
factor(id)163               -12.66401    2.39019  -5.298 1.33e-07 ***
factor(id)164                 8.94022    2.39019   3.740 0.000190 ***
factor(id)165               -12.28031    2.39019  -5.138 3.12e-07 ***
factor(id)166                -1.03303    2.39019  -0.432 0.665657    
factor(id)167                -3.72891    2.39019  -1.560 0.118938    
factor(id)168                -9.40155    2.39019  -3.933 8.74e-05 ***
factor(id)169                -5.71724    2.39019  -2.392 0.016874 *  
factor(id)170                -5.33787    2.39019  -2.233 0.025672 *  
factor(id)171                -6.35430    2.39019  -2.658 0.007928 ** 
factor(id)172                -4.86337    2.39019  -2.035 0.042045 *  
factor(id)173                -7.92612    2.39019  -3.316 0.000933 ***
factor(id)174                 2.83089    2.39019   1.184 0.236441    
factor(id)175               -10.08143    2.39019  -4.218 2.61e-05 ***
factor(id)176               -12.38937    2.39019  -5.183 2.46e-07 ***
factor(id)177                -6.25014    2.39019  -2.615 0.009010 ** 
factor(id)178                -5.18715    2.39019  -2.170 0.030141 *  
factor(id)179                -3.95825    2.39019  -1.656 0.097911 .  
factor(id)180                -9.90343    2.39019  -4.143 3.60e-05 ***
factor(id)181               -15.19929    2.39019  -6.359 2.65e-10 ***
factor(id)182                -1.14184    2.39019  -0.478 0.632914    
factor(id)183                -4.20602    2.39019  -1.760 0.078651 .  
factor(id)184               -11.63819    2.39019  -4.869 1.23e-06 ***
factor(id)185                -8.01945    2.39019  -3.355 0.000812 ***
factor(id)186                -6.31554    2.39019  -2.642 0.008316 ** 
factor(id)187                -1.20685    2.39019  -0.505 0.613687    
factor(id)188                -4.64204    2.39019  -1.942 0.052299 .  
factor(id)189                -3.38489    2.39019  -1.416 0.156925    
factor(id)190                -7.65467    2.39019  -3.203 0.001389 ** 
factor(id)191                -4.60217    2.39019  -1.925 0.054353 .  
factor(id)192                -9.84453    2.39019  -4.119 4.01e-05 ***
factor(id)193                -5.59493    2.39019  -2.341 0.019366 *  
factor(id)194               -10.08977    2.39019  -4.221 2.57e-05 ***
factor(id)195               -10.64771    2.39019  -4.455 8.99e-06 ***
factor(id)196                 3.43837    2.39019   1.439 0.150479    
factor(id)197                -3.14678    2.39019  -1.317 0.188183    
factor(id)198               -10.57896    2.39019  -4.426 1.03e-05 ***
factor(id)199                -9.30153    2.39019  -3.892 0.000104 ***
factor(id)200               -12.86614    2.39019  -5.383 8.43e-08 ***
factor(time)-3               -1.70944    0.68999  -2.477 0.013334 *  
factor(time)-2               -3.80312    0.68999  -5.512 4.14e-08 ***
factor(time)0                -4.88558    0.68999  -7.081 2.15e-12 ***
factor(time)1                -5.29199    0.68999  -7.670 2.99e-14 ***
factor(time)2                -5.57170    0.68999  -8.075 1.32e-15 ***
factor(time)3                -5.33489    0.68999  -7.732 1.87e-14 ***
factor(time)4                -0.55566    0.68999  -0.805 0.420756    
factor(time)5                -4.81789    0.68999  -6.983 4.25e-12 ***
treat:event_time_f_no_ref-2  -8.65085    0.97579  -8.865  &lt; 2e-16 ***
treat:event_time_f_no_ref-3  -6.38242    0.97579  -6.541 8.24e-11 ***
treat:event_time_f_no_ref-4  -6.42990    0.97579  -6.589 5.99e-11 ***
treat:event_time_f_no_ref0   -4.61319    0.97579  -4.728 2.47e-06 ***
treat:event_time_f_no_ref1   -3.06607    0.97579  -3.142 0.001708 ** 
treat:event_time_f_no_ref2   -0.54765    0.97579  -0.561 0.574716    
treat:event_time_f_no_ref3    0.36479    0.97579   0.374 0.708570    
treat:event_time_f_no_ref4    0.00674    0.97579   0.007 0.994490    
treat:event_time_f_no_ref5         NA         NA      NA       NA    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 4.879 on 1584 degrees of freedom
  (200 observations deleted due to missingness)
Multiple R-squared:  0.6432,    Adjusted R-squared:  0.5947 
F-statistic: 13.28 on 215 and 1584 DF,  p-value: &lt; 2.2e-16</code></pre>
</div>
</div>
<p>The coefficients on <code>treat:event_time_f_no_refk</code> (for k != -1) are the estimated event-study effects <span class="math inline">\(\hat{\beta}_k\)</span> relative to event time -1.</p>
<hr>
</section>
<section id="extracting-and-plotting-event-time-coefficients" class="level2">
<h2 class="anchored" data-anchor-id="extracting-and-plotting-event-time-coefficients">3.3. Extracting and plotting event-time coefficients</h2>
<p>We can use <code>broom</code> and <code>ggplot2</code> to extract and visualize the <span class="math inline">\(\hat{\beta}_k\)</span>.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(broom)</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>tidy_es <span class="ot">&lt;-</span> broom<span class="sc">::</span><span class="fu">tidy</span>(es_fit)</span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a><span class="co"># Keep only the treat:event_time terms</span></span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a>tidy_es_events <span class="ot">&lt;-</span> tidy_es <span class="sc">%&gt;%</span></span>
<span id="cb7-8"><a href="#cb7-8" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">filter</span>(<span class="fu">grepl</span>(<span class="st">"^treat:event_time_f_no_ref"</span>, term))</span>
<span id="cb7-9"><a href="#cb7-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-10"><a href="#cb7-10" aria-hidden="true" tabindex="-1"></a>tidy_es_events <span class="ot">&lt;-</span> tidy_es_events <span class="sc">%&gt;%</span></span>
<span id="cb7-11"><a href="#cb7-11" aria-hidden="true" tabindex="-1"></a>  dplyr<span class="sc">::</span><span class="fu">mutate</span>(</span>
<span id="cb7-12"><a href="#cb7-12" aria-hidden="true" tabindex="-1"></a>    <span class="co"># Extract the event time k from the term name</span></span>
<span id="cb7-13"><a href="#cb7-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">event_time =</span> <span class="fu">as.numeric</span>(<span class="fu">gsub</span>(<span class="st">"treat:event_time_f_no_ref"</span>, <span class="st">""</span>, term)),</span>
<span id="cb7-14"><a href="#cb7-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">conf_low   =</span> estimate <span class="sc">-</span> <span class="fl">1.96</span> <span class="sc">*</span> std.error,</span>
<span id="cb7-15"><a href="#cb7-15" aria-hidden="true" tabindex="-1"></a>    <span class="at">conf_high  =</span> estimate <span class="sc">+</span> <span class="fl">1.96</span> <span class="sc">*</span> std.error</span>
<span id="cb7-16"><a href="#cb7-16" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb7-17"><a href="#cb7-17" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-18"><a href="#cb7-18" aria-hidden="true" tabindex="-1"></a>tidy_es_events</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code># A tibble: 9 × 8
  term      estimate std.error statistic   p.value event_time conf_low conf_high
  &lt;chr&gt;        &lt;dbl&gt;     &lt;dbl&gt;     &lt;dbl&gt;     &lt;dbl&gt;      &lt;dbl&gt;    &lt;dbl&gt;     &lt;dbl&gt;
1 treat:ev... -8.65        0.976  -8.87     2.01e-18         -2   -10.6      -6.74
2 treat:ev... -6.38        0.976  -6.54     8.24e-11         -3    -8.29     -4.47
3 treat:ev... -6.43        0.976  -6.59     5.99e-11         -4    -8.34     -4.52
4 treat:ev... -4.61        0.976  -4.73     2.47e- 6          0    -6.53     -2.70
5 treat:ev... -3.07        0.976  -3.14     1.71e- 3          1    -4.98     -1.15
6 treat:ev... -0.548       0.976  -0.561    5.75e- 1          2    -2.46      1.36
7 treat:ev...  0.365       0.976   0.374    7.09e- 1          3    -1.55      2.28
8 treat:ev...  0.00674     0.976   0.00691  9.94e- 1          4    -1.91      1.92
9 treat:ev... NA          NA      NA       NA                 5    NA        NA   </code></pre>
</div>
</div>
<p>Now we plot the coefficients by event time, including pre- and post-periods, with <span class="math inline">\(-1\)</span> as the reference (shown as a horizontal zero line).</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb9"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb9-1"><a href="#cb9-1" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(tidy_es_events, <span class="fu">aes</span>(<span class="at">x =</span> event_time, <span class="at">y =</span> estimate)) <span class="sc">+</span></span>
<span id="cb9-2"><a href="#cb9-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_hline</span>(<span class="at">yintercept =</span> <span class="dv">0</span>, <span class="at">linetype =</span> <span class="st">"dashed"</span>, <span class="at">color =</span> <span class="st">"gray40"</span>) <span class="sc">+</span></span>
<span id="cb9-3"><a href="#cb9-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_ribbon</span>(<span class="fu">aes</span>(<span class="at">ymin =</span> conf_low, <span class="at">ymax =</span> conf_high), <span class="at">alpha =</span> <span class="fl">0.2</span>) <span class="sc">+</span></span>
<span id="cb9-4"><a href="#cb9-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_point</span>(<span class="at">size =</span> <span class="dv">2</span>) <span class="sc">+</span></span>
<span id="cb9-5"><a href="#cb9-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>() <span class="sc">+</span></span>
<span id="cb9-6"><a href="#cb9-6" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb9-7"><a href="#cb9-7" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Event time (relative to policy start; -1 is reference)"</span>,</span>
<span id="cb9-8"><a href="#cb9-8" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Estimated effect (relative to event time -1)"</span>,</span>
<span id="cb9-9"><a href="#cb9-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Event-Study Estimates of Policy Effect"</span></span>
<span id="cb9-10"><a href="#cb9-10" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/04-ci-event-study_files/figure-html/es-plot-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Event-study estimates of the policy effect over event time (relative to period -1).</figcaption>
</figure>
</div>
</div>
</div>
<p>Interpretation:</p>
<ul>
<li>For <span class="math inline">\(k &lt; -1\)</span> (leads), we hope the coefficients are around zero (no pre-trends).</li>
<li>For <span class="math inline">\(k \ge 0\)</span> (lags), we should see a pattern similar to the <strong>true effects</strong> we simulated:
<ul>
<li>Small at <span class="math inline">\(k = 0\)</span>,</li>
<li>Growing at <span class="math inline">\(k = 1, 2, 3\)</span>,</li>
<li>Plateauing at later periods.</li>
</ul></li>
</ul>
<hr>
</section>
</section>
<section id="why-event-study-matters-beyond-looking-cool-in-graphs" class="level1">
<h1>4. Why event-study matters (beyond "looking cool in graphs")</h1>
<p>Event-study designs add several important layers to DiD in HEOR and health policy.</p>
<section id="visual-check-of-parallel-trends" class="level2">
<h2 class="anchored" data-anchor-id="visual-check-of-parallel-trends">4.1. Visual check of parallel trends</h2>
<p>DiD relies heavily on the <strong>parallel trends</strong> assumption. Event-study:</p>
<ul>
<li>Estimates pre-treatment coefficients for <span class="math inline">\(k &lt; 0\)</span>,</li>
<li>Allows you to <strong>plot</strong> these pre-policy coefficients with confidence intervals,</li>
<li>Helps to visually check whether pre-trends seem flat (supporting the assumption) or drifting (raising concerns).</li>
</ul>
<p>While not a formal proof, this is a powerful diagnostic and communication tool.</p>
</section>
<section id="dynamic-treatment-effects" class="level2">
<h2 class="anchored" data-anchor-id="dynamic-treatment-effects">4.2. Dynamic treatment effects</h2>
<p>Policies rarely have instantaneous, constant effects. With event-study you can see:</p>
<ul>
<li>Whether the effect builds gradually as implementation ramps up,</li>
<li>Whether it decays as attention or funding wanes,</li>
<li>Whether there are "one-time shocks" versus persistent changes.</li>
</ul>
<p>For HEOR questions like:</p>
<ul>
<li>"Does the policy have lasting impact on utilization?"</li>
<li>"Does the effect on costs stabilize over time?"</li>
</ul>
<p>...the shape of the event-study curve can be as important as the average effect.</p>
</section>
<section id="timing-and-anticipation" class="level2">
<h2 class="anchored" data-anchor-id="timing-and-anticipation">4.3. Timing and anticipation</h2>
<p>Event-study can reveal:</p>
<ul>
<li><strong>Anticipation</strong>: if effects appear <strong>before</strong> the official policy start date, maybe people started reacting earlier (or something else changed).</li>
<li><strong>Delayed effects</strong>: if nothing moves at <span class="math inline">\(k = 0\)</span> but large changes appear at <span class="math inline">\(k = 2\)</span> or <span class="math inline">\(3\)</span>, you have a more realistic story about implementation lags.</li>
</ul>
<p>These timing details matter a lot when planning:</p>
<ul>
<li>Budgeting,</li>
<li>Staffing,</li>
<li>Evaluating whether a policy "failed" or just took time to work.</li>
</ul>
</section>
<section id="communication-with-policymakers-and-stakeholders" class="level2">
<h2 class="anchored" data-anchor-id="communication-with-policymakers-and-stakeholders">4.4. Communication with policymakers and stakeholders</h2>
<p>Event-study graphs are relatively easy to explain:</p>
<ul>
<li>X-axis: time relative to policy adoption,</li>
<li>Y-axis: estimated effect,</li>
<li>Horizontal line at 0,</li>
<li>Pre-period points (hopefully near 0),</li>
<li>Post-period points showing how the effect changes.</li>
</ul>
<p>This makes it simpler to:</p>
<ul>
<li>Convey uncertainty,</li>
<li>Discuss dynamic impacts,</li>
<li>Avoid oversimplifying complex policies to a single "average effect."</li>
</ul>
<hr>
</section>
</section>
<section id="further-reading" class="level1">
<h1>5. Further reading</h1>
<p>If you want to go deeper on event-study and modern DiD methods (especially with staggered treatment timing), here are four solid references:</p>
<ol type="1">
<li><p><strong>Sun &amp; Abraham (2021). <em>Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects.</em></strong><br>
Journal of Econometrics. A key paper highlighting problems with "naive" event-study DiD when treatment timing varies, and proposing alternative estimators.</p></li>
<li><p><strong>Callaway &amp; Sant'Anna (2021). <em>Difference-in-Differences with Multiple Time Periods.</em></strong><br>
Journal of Econometrics. Provides a general framework and estimators for DiD with multiple periods and staggered adoption.</p></li>
<li><p><strong>Roth (2022). <em>Pretest with Caution: Event-Study Estimates after Testing for Parallel Trends.</em></strong><br>
American Economic Review (P&amp;P). Discusses issues with "testing parallel trends" and then proceeding as if nothing happened.</p></li>
<li><p><strong>Roth et al.&nbsp;(2023). <em>What's Trending in Difference-in-Differences? A Synthesis of the Recent Econometrics Literature.</em></strong><br>
Annual Review-style overview of the modern DiD/event-study literature; very helpful for seeing the big picture.</p></li>
</ol>
<p>With DiD and event-study tools in your toolkit, you can not only say <strong>whether</strong> a policy had an impact, but also <strong>when</strong> and <strong>how</strong> that impact unfolded - which is exactly the kind of nuance health policy and HEOR often demand. 😄</p>


<!-- -->

</section>
