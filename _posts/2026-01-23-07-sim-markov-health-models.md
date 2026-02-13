---
title: "Markov Health Decision Models: Following Patients Through Health States"
date: 2026-01-23
categories: [tutorials, codes]
tags: [Simulation Models]
summary: "In the previous tutorial, we met Markov chains as a way to model how patients move between states like Healthy, Sick, and Dead over time."
---
<section id="introduction-turning-markov-chains-into-decision-tools" class="level1">
<h1>1. Introduction: turning Markov chains into decision tools</h1>
<p>In the previous tutorial, we met <strong>Markov chains</strong> as a way to model how patients move between states like Healthy, Sick, and Dead over time.</p>
<p>Now we ask a very HEOR-flavored question:</p>
<blockquote class="blockquote">
<p>"What if we attach <strong>costs</strong> and <strong>QALYs</strong> to those states, and compare two interventions?"</p>
</blockquote>
<p>That's exactly what <strong>Markov health decision models</strong> do:</p>
<ul>
<li>Use Markov chains to model disease progression and survival,</li>
<li>Combine this with costs and utilities/QALYs,</li>
<li>Calculate expected lifetime costs and effects for each strategy,</li>
<li>Support cost-effectiveness and policy decisions.</li>
</ul>
<p>In this tutorial we'll:</p>
<ul>
<li>Set up a simple cohort Markov model,</li>
<li>Compare <strong>Standard care</strong> vs <strong>New treatment</strong>,</li>
<li>Use synthetic probabilities, costs, and utilities,</li>
<li>Compute expected total costs and QALYs,</li>
<li>Discuss strengths and limitations,</li>
<li>And highlight why Markov models are central to HEOR.</li>
</ul>
<hr>
</section>
<section id="foundations-markov-state-transition-models-in-heor" class="level1">
<h1>2. Foundations: Markov state-transition models in HEOR</h1>
<section id="states-transitions-and-cycles" class="level2">
<h2 class="anchored" data-anchor-id="states-transitions-and-cycles">2.1. States, transitions, and cycles</h2>
<p>A typical health decision Markov model has:</p>
<ul>
<li>A finite set of health states (e.g., Healthy, Disease, Dead),</li>
<li>A cycle length (e.g., 1 year),</li>
<li>A transition probability matrix for each strategy,</li>
<li>An initial distribution over states (e.g., 100% Healthy at baseline).</li>
</ul>
<p>Over each cycle:</p>
<ol type="1">
<li>Patients transition between states according to the matrix,</li>
<li>Costs and QALYs accrue based on time spent in each state,</li>
<li>We (optionally) apply discounting to reflect time preference for costs and health.</li>
</ol>
</section>
<section id="cohort-vs-microsimulation" class="level2">
<h2 class="anchored" data-anchor-id="cohort-vs-microsimulation">2.2. Cohort vs microsimulation</h2>
<p>Here we focus on a <strong>cohort</strong> Markov model:</p>
<ul>
<li>We track <strong>proportions</strong> of a hypothetical cohort in each state over time,</li>
<li>Use matrix multiplication: <span class="math inline">\(\pi_{t+1} = \pi_t P\)</span>,</li>
<li>Multiply state occupancy by costs and utilities to get expected totals.</li>
</ul>
<p>Microsimulation (individual-level state transitions) is similar but simulates individuals instead of cohorts - often using the same transition probabilities.</p>
</section>
<section id="discounting" class="level2">
<h2 class="anchored" data-anchor-id="discounting">2.3. Discounting</h2>
<p>For annual cycles and discount rate <span class="math inline">\(r\)</span>:</p>
<ul>
<li>Discount factor in year <span class="math inline">\(t\)</span> (starting at <span class="math inline">\(t = 0\)</span>):</li>
</ul>
<p><span class="math display">\[
d_t = \frac{1}{(1 + r)^t}.
\]</span></p>
<p>We apply discounting to both costs and QALYs (commonly).</p>
<hr>
</section>
</section>
<section id="example-in-r-simple-3-state-markov-model" class="level1">
<h1>3. Example in R: simple 3-state Markov model</h1>
<p>We'll build a toy example:</p>
<ul>
<li>States: Healthy (H), Sick (S), Dead (D),</li>
<li>Horizon: 20 annual cycles,</li>
<li>Two strategies: Standard, New.</li>
</ul>
<section id="model-setup" class="level2">
<h2 class="anchored" data-anchor-id="model-setup">3.1. Model setup</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a>states <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="st">"Healthy"</span>, <span class="st">"Sick"</span>, <span class="st">"Dead"</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a>n_states <span class="ot">&lt;-</span> <span class="fu">length</span>(states)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>n_cycle  <span class="ot">&lt;-</span> <span class="dv">20</span>      <span class="co"># 20-year horizon</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>discount_rate <span class="ot">&lt;-</span> <span class="fl">0.03</span></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a><span class="co"># Discount factors per cycle (start at t = 0)</span></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>cycles <span class="ot">&lt;-</span> <span class="dv">0</span><span class="sc">:</span>n_cycle</span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>disc_factors <span class="ot">&lt;-</span> <span class="dv">1</span> <span class="sc">/</span> (<span class="dv">1</span> <span class="sc">+</span> discount_rate)<span class="sc">^</span>cycles</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>disc_factors</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code> [1] 1.0000000 0.9708738 0.9425959 0.9151417 0.8884870 0.8626088 0.8374843
 [8] 0.8130915 0.7894092 0.7664167 0.7440939 0.7224213 0.7013799 0.6809513
[15] 0.6611178 0.6418619 0.6231669 0.6050164 0.5873946 0.5702860 0.5536758</code></pre>
</div>
</div>
</section>
<section id="transition-matrices" class="level2">
<h2 class="anchored" data-anchor-id="transition-matrices">3.2. Transition matrices</h2>
<p>We define separate transition matrices for Standard and New strategies.</p>
<ul>
<li>Standard care: higher risk of moving from Healthy → Sick and Sick → Dead.</li>
<li>New treatment: slightly reduces progression and mortality.</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a><span class="co"># Rows: from state, Columns: to state</span></span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a>P_standard <span class="ot">&lt;-</span> <span class="fu">matrix</span>(</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">c</span>(</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.88</span>, <span class="fl">0.08</span>, <span class="fl">0.04</span>,  <span class="co"># from Healthy</span></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.10</span>, <span class="fl">0.75</span>, <span class="fl">0.15</span>,  <span class="co"># from Sick</span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.00</span>, <span class="fl">0.00</span>, <span class="fl">1.00</span>   <span class="co"># from Dead</span></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">nrow =</span> <span class="dv">3</span>,</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">byrow =</span> <span class="cn">TRUE</span></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a><span class="fu">colnames</span>(P_standard) <span class="ot">&lt;-</span> states</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a><span class="fu">rownames</span>(P_standard) <span class="ot">&lt;-</span> states</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>P_new <span class="ot">&lt;-</span> <span class="fu">matrix</span>(</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>  <span class="fu">c</span>(</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.90</span>, <span class="fl">0.07</span>, <span class="fl">0.03</span>,  <span class="co"># from Healthy (slightly lower progression and death)</span></span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.12</span>, <span class="fl">0.78</span>, <span class="fl">0.10</span>,  <span class="co"># from Sick (slightly better survival)</span></span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.00</span>, <span class="fl">0.00</span>, <span class="fl">1.00</span></span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>  <span class="at">nrow =</span> <span class="dv">3</span>,</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>  <span class="at">byrow =</span> <span class="cn">TRUE</span></span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a><span class="fu">colnames</span>(P_new) <span class="ot">&lt;-</span> states</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a><span class="fu">rownames</span>(P_new) <span class="ot">&lt;-</span> states</span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-26"><a href="#cb3-26" aria-hidden="true" tabindex="-1"></a>P_standard</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>        Healthy Sick Dead
Healthy    0.88 0.08 0.04
Sick       0.10 0.75 0.15
Dead       0.00 0.00 1.00</code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>P_new</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>        Healthy Sick Dead
Healthy    0.90 0.07 0.03
Sick       0.12 0.78 0.10
Dead       0.00 0.00 1.00</code></pre>
</div>
</div>
</section>
<section id="state-costs-and-utilities" class="level2">
<h2 class="anchored" data-anchor-id="state-costs-and-utilities">3.3. State costs and utilities</h2>
<p>We assign annual cost and utility (QALY weight) to each state, per strategy.</p>
<p>For simplicity:</p>
<ul>
<li>State costs same across strategies, but New has an additional <strong>treatment cost</strong> while alive.</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a><span class="co"># Base state costs (per year)</span></span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a>cost_H <span class="ot">&lt;-</span> <span class="dv">500</span>    <span class="co"># Healthy</span></span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a>cost_S <span class="ot">&lt;-</span> <span class="dv">4000</span>   <span class="co"># Sick</span></span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>cost_D <span class="ot">&lt;-</span> <span class="dv">0</span>      <span class="co"># Dead</span></span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a><span class="co"># Utilities (QALY weights)</span></span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a>util_H <span class="ot">&lt;-</span> <span class="fl">0.9</span></span>
<span id="cb7-8"><a href="#cb7-8" aria-hidden="true" tabindex="-1"></a>util_S <span class="ot">&lt;-</span> <span class="fl">0.6</span></span>
<span id="cb7-9"><a href="#cb7-9" aria-hidden="true" tabindex="-1"></a>util_D <span class="ot">&lt;-</span> <span class="fl">0.0</span></span>
<span id="cb7-10"><a href="#cb7-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-11"><a href="#cb7-11" aria-hidden="true" tabindex="-1"></a><span class="co"># Strategy-specific extra costs per year (e.g., treatment cost)</span></span>
<span id="cb7-12"><a href="#cb7-12" aria-hidden="true" tabindex="-1"></a>extra_cost_standard <span class="ot">&lt;-</span> <span class="dv">0</span></span>
<span id="cb7-13"><a href="#cb7-13" aria-hidden="true" tabindex="-1"></a>extra_cost_new      <span class="ot">&lt;-</span> <span class="dv">1500</span>  <span class="co"># extra cost while alive (H or S)</span></span>
<span id="cb7-14"><a href="#cb7-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-15"><a href="#cb7-15" aria-hidden="true" tabindex="-1"></a>state_costs_standard <span class="ot">&lt;-</span> <span class="fu">c</span>(cost_H, cost_S, cost_D)</span>
<span id="cb7-16"><a href="#cb7-16" aria-hidden="true" tabindex="-1"></a>state_costs_new      <span class="ot">&lt;-</span> <span class="fu">c</span>(cost_H <span class="sc">+</span> extra_cost_new,</span>
<span id="cb7-17"><a href="#cb7-17" aria-hidden="true" tabindex="-1"></a>                          cost_S <span class="sc">+</span> extra_cost_new,</span>
<span id="cb7-18"><a href="#cb7-18" aria-hidden="true" tabindex="-1"></a>                          cost_D)</span>
<span id="cb7-19"><a href="#cb7-19" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-20"><a href="#cb7-20" aria-hidden="true" tabindex="-1"></a>state_utils <span class="ot">&lt;-</span> <span class="fu">c</span>(util_H, util_S, util_D)</span>
<span id="cb7-21"><a href="#cb7-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-22"><a href="#cb7-22" aria-hidden="true" tabindex="-1"></a>state_costs_standard</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>[1]  500 4000    0</code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb9"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb9-1"><a href="#cb9-1" aria-hidden="true" tabindex="-1"></a>state_costs_new</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>[1] 2000 5500    0</code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb11"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb11-1"><a href="#cb11-1" aria-hidden="true" tabindex="-1"></a>state_utils</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>[1] 0.9 0.6 0.0</code></pre>
</div>
</div>
</section>
<section id="cohort-markov-model-function" class="level2">
<h2 class="anchored" data-anchor-id="cohort-markov-model-function">3.4. Cohort Markov model function</h2>
<p>We write a small helper function to run the cohort model for a given strategy.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb13"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb13-1"><a href="#cb13-1" aria-hidden="true" tabindex="-1"></a>run_markov_cohort <span class="ot">&lt;-</span> <span class="cf">function</span>(P, state_costs, state_utils,</span>
<span id="cb13-2"><a href="#cb13-2" aria-hidden="true" tabindex="-1"></a>                              n_cycle, <span class="at">disc_rate =</span> <span class="fl">0.03</span>) {</span>
<span id="cb13-3"><a href="#cb13-3" aria-hidden="true" tabindex="-1"></a>  states <span class="ot">&lt;-</span> <span class="fu">length</span>(state_costs)</span>
<span id="cb13-4"><a href="#cb13-4" aria-hidden="true" tabindex="-1"></a>  cycles <span class="ot">&lt;-</span> <span class="dv">0</span><span class="sc">:</span>n_cycle</span>
<span id="cb13-5"><a href="#cb13-5" aria-hidden="true" tabindex="-1"></a>  disc_factors <span class="ot">&lt;-</span> <span class="dv">1</span> <span class="sc">/</span> (<span class="dv">1</span> <span class="sc">+</span> disc_rate)<span class="sc">^</span>cycles</span>
<span id="cb13-6"><a href="#cb13-6" aria-hidden="true" tabindex="-1"></a>  </span>
<span id="cb13-7"><a href="#cb13-7" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Initial distribution: all Healthy at t = 0</span></span>
<span id="cb13-8"><a href="#cb13-8" aria-hidden="true" tabindex="-1"></a>  dist_mat <span class="ot">&lt;-</span> <span class="fu">matrix</span>(<span class="dv">0</span>, <span class="at">nrow =</span> n_cycle <span class="sc">+</span> <span class="dv">1</span>, <span class="at">ncol =</span> states)</span>
<span id="cb13-9"><a href="#cb13-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">colnames</span>(dist_mat) <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="st">"Healthy"</span>, <span class="st">"Sick"</span>, <span class="st">"Dead"</span>)</span>
<span id="cb13-10"><a href="#cb13-10" aria-hidden="true" tabindex="-1"></a>  dist_mat[<span class="dv">1</span>, <span class="st">"Healthy"</span>] <span class="ot">&lt;-</span> <span class="fl">1.0</span></span>
<span id="cb13-11"><a href="#cb13-11" aria-hidden="true" tabindex="-1"></a>  </span>
<span id="cb13-12"><a href="#cb13-12" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Evolve the cohort</span></span>
<span id="cb13-13"><a href="#cb13-13" aria-hidden="true" tabindex="-1"></a>  <span class="cf">for</span> (t <span class="cf">in</span> <span class="dv">1</span><span class="sc">:</span>n_cycle) {</span>
<span id="cb13-14"><a href="#cb13-14" aria-hidden="true" tabindex="-1"></a>    dist_mat[t <span class="sc">+</span> <span class="dv">1</span>, ] <span class="ot">&lt;-</span> dist_mat[t, ] <span class="sc">%*%</span> P</span>
<span id="cb13-15"><a href="#cb13-15" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb13-16"><a href="#cb13-16" aria-hidden="true" tabindex="-1"></a>  </span>
<span id="cb13-17"><a href="#cb13-17" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Costs and QALYs per cycle (undiscounted)</span></span>
<span id="cb13-18"><a href="#cb13-18" aria-hidden="true" tabindex="-1"></a>  cost_per_cycle <span class="ot">&lt;-</span> dist_mat <span class="sc">%*%</span> state_costs</span>
<span id="cb13-19"><a href="#cb13-19" aria-hidden="true" tabindex="-1"></a>  qaly_per_cycle <span class="ot">&lt;-</span> dist_mat <span class="sc">%*%</span> state_utils</span>
<span id="cb13-20"><a href="#cb13-20" aria-hidden="true" tabindex="-1"></a>  </span>
<span id="cb13-21"><a href="#cb13-21" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Apply discounting</span></span>
<span id="cb13-22"><a href="#cb13-22" aria-hidden="true" tabindex="-1"></a>  disc_costs <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(cost_per_cycle) <span class="sc">*</span> disc_factors</span>
<span id="cb13-23"><a href="#cb13-23" aria-hidden="true" tabindex="-1"></a>  disc_qalys <span class="ot">&lt;-</span> <span class="fu">as.numeric</span>(qaly_per_cycle) <span class="sc">*</span> disc_factors</span>
<span id="cb13-24"><a href="#cb13-24" aria-hidden="true" tabindex="-1"></a>  </span>
<span id="cb13-25"><a href="#cb13-25" aria-hidden="true" tabindex="-1"></a>  <span class="fu">list</span>(</span>
<span id="cb13-26"><a href="#cb13-26" aria-hidden="true" tabindex="-1"></a>    <span class="at">dist_mat         =</span> dist_mat,</span>
<span id="cb13-27"><a href="#cb13-27" aria-hidden="true" tabindex="-1"></a>    <span class="at">cost_per_cycle   =</span> <span class="fu">as.numeric</span>(cost_per_cycle),</span>
<span id="cb13-28"><a href="#cb13-28" aria-hidden="true" tabindex="-1"></a>    <span class="at">qaly_per_cycle   =</span> <span class="fu">as.numeric</span>(qaly_per_cycle),</span>
<span id="cb13-29"><a href="#cb13-29" aria-hidden="true" tabindex="-1"></a>    <span class="at">disc_costs       =</span> disc_costs,</span>
<span id="cb13-30"><a href="#cb13-30" aria-hidden="true" tabindex="-1"></a>    <span class="at">disc_qalys       =</span> disc_qalys,</span>
<span id="cb13-31"><a href="#cb13-31" aria-hidden="true" tabindex="-1"></a>    <span class="at">total_cost       =</span> <span class="fu">sum</span>(disc_costs),</span>
<span id="cb13-32"><a href="#cb13-32" aria-hidden="true" tabindex="-1"></a>    <span class="at">total_qaly       =</span> <span class="fu">sum</span>(disc_qalys)</span>
<span id="cb13-33"><a href="#cb13-33" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb13-34"><a href="#cb13-34" aria-hidden="true" tabindex="-1"></a>}</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
</section>
<section id="running-the-model-for-both-strategies" class="level2">
<h2 class="anchored" data-anchor-id="running-the-model-for-both-strategies">3.5. Running the model for both strategies</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb14"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb14-1"><a href="#cb14-1" aria-hidden="true" tabindex="-1"></a>res_standard <span class="ot">&lt;-</span> <span class="fu">run_markov_cohort</span>(</span>
<span id="cb14-2"><a href="#cb14-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">P =</span> P_standard,</span>
<span id="cb14-3"><a href="#cb14-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">state_costs =</span> state_costs_standard,</span>
<span id="cb14-4"><a href="#cb14-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">state_utils =</span> state_utils,</span>
<span id="cb14-5"><a href="#cb14-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">n_cycle =</span> n_cycle,</span>
<span id="cb14-6"><a href="#cb14-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">disc_rate =</span> discount_rate</span>
<span id="cb14-7"><a href="#cb14-7" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb14-8"><a href="#cb14-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb14-9"><a href="#cb14-9" aria-hidden="true" tabindex="-1"></a>res_new <span class="ot">&lt;-</span> <span class="fu">run_markov_cohort</span>(</span>
<span id="cb14-10"><a href="#cb14-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">P =</span> P_new,</span>
<span id="cb14-11"><a href="#cb14-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">state_costs =</span> state_costs_new,</span>
<span id="cb14-12"><a href="#cb14-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">state_utils =</span> state_utils,</span>
<span id="cb14-13"><a href="#cb14-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">n_cycle =</span> n_cycle,</span>
<span id="cb14-14"><a href="#cb14-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">disc_rate =</span> discount_rate</span>
<span id="cb14-15"><a href="#cb14-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb14-16"><a href="#cb14-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb14-17"><a href="#cb14-17" aria-hidden="true" tabindex="-1"></a><span class="fu">c</span>(<span class="at">Standard_total_cost =</span> res_standard<span class="sc">$</span>total_cost,</span>
<span id="cb14-18"><a href="#cb14-18" aria-hidden="true" tabindex="-1"></a>  <span class="at">New_total_cost       =</span> res_new<span class="sc">$</span>total_cost)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>Standard_total_cost      New_total_cost 
           12010.32            30158.75 </code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb16"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb16-1"><a href="#cb16-1" aria-hidden="true" tabindex="-1"></a><span class="fu">c</span>(<span class="at">Standard_total_qaly =</span> res_standard<span class="sc">$</span>total_qaly,</span>
<span id="cb16-2"><a href="#cb16-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">New_total_qaly       =</span> res_new<span class="sc">$</span>total_qaly)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>Standard_total_qaly      New_total_qaly 
           8.115045            9.350440 </code></pre>
</div>
</div>
<p>We can compute incremental outcomes:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb18"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb18-1"><a href="#cb18-1" aria-hidden="true" tabindex="-1"></a>dC <span class="ot">&lt;-</span> res_new<span class="sc">$</span>total_cost <span class="sc">-</span> res_standard<span class="sc">$</span>total_cost</span>
<span id="cb18-2"><a href="#cb18-2" aria-hidden="true" tabindex="-1"></a>dE <span class="ot">&lt;-</span> res_new<span class="sc">$</span>total_qaly <span class="sc">-</span> res_standard<span class="sc">$</span>total_qaly</span>
<span id="cb18-3"><a href="#cb18-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb18-4"><a href="#cb18-4" aria-hidden="true" tabindex="-1"></a>ICER <span class="ot">&lt;-</span> dC <span class="sc">/</span> dE</span>
<span id="cb18-5"><a href="#cb18-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb18-6"><a href="#cb18-6" aria-hidden="true" tabindex="-1"></a><span class="fu">c</span>(<span class="at">Incremental_cost =</span> dC,</span>
<span id="cb18-7"><a href="#cb18-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">Incremental_qaly =</span> dE,</span>
<span id="cb18-8"><a href="#cb18-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">ICER             =</span> ICER)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>Incremental_cost Incremental_qaly             ICER 
    18148.434857         1.235395     14690.389659 </code></pre>
</div>
</div>
</section>
<section id="visualizing-state-occupancy" class="level2">
<h2 class="anchored" data-anchor-id="visualizing-state-occupancy">3.6. Visualizing state occupancy</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb20"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb20-1"><a href="#cb20-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb20-2"><a href="#cb20-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(tidyr)</span>
<span id="cb20-3"><a href="#cb20-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb20-4"><a href="#cb20-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb20-5"><a href="#cb20-5" aria-hidden="true" tabindex="-1"></a>df_std <span class="ot">&lt;-</span> <span class="fu">as.data.frame</span>(res_standard<span class="sc">$</span>dist_mat)</span>
<span id="cb20-6"><a href="#cb20-6" aria-hidden="true" tabindex="-1"></a>df_std<span class="sc">$</span>cycle <span class="ot">&lt;-</span> <span class="dv">0</span><span class="sc">:</span>n_cycle</span>
<span id="cb20-7"><a href="#cb20-7" aria-hidden="true" tabindex="-1"></a>df_std<span class="sc">$</span>strategy <span class="ot">&lt;-</span> <span class="st">"Standard"</span></span>
<span id="cb20-8"><a href="#cb20-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb20-9"><a href="#cb20-9" aria-hidden="true" tabindex="-1"></a>df_new <span class="ot">&lt;-</span> <span class="fu">as.data.frame</span>(res_new<span class="sc">$</span>dist_mat)</span>
<span id="cb20-10"><a href="#cb20-10" aria-hidden="true" tabindex="-1"></a>df_new<span class="sc">$</span>cycle <span class="ot">&lt;-</span> <span class="dv">0</span><span class="sc">:</span>n_cycle</span>
<span id="cb20-11"><a href="#cb20-11" aria-hidden="true" tabindex="-1"></a>df_new<span class="sc">$</span>strategy <span class="ot">&lt;-</span> <span class="st">"New"</span></span>
<span id="cb20-12"><a href="#cb20-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb20-13"><a href="#cb20-13" aria-hidden="true" tabindex="-1"></a>occ_all <span class="ot">&lt;-</span> <span class="fu">bind_rows</span>(df_std, df_new) <span class="sc">%&gt;%</span></span>
<span id="cb20-14"><a href="#cb20-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">pivot_longer</span>(<span class="at">cols =</span> <span class="fu">c</span>(<span class="st">"Healthy"</span>, <span class="st">"Sick"</span>, <span class="st">"Dead"</span>),</span>
<span id="cb20-15"><a href="#cb20-15" aria-hidden="true" tabindex="-1"></a>               <span class="at">names_to =</span> <span class="st">"state"</span>, <span class="at">values_to =</span> <span class="st">"prob"</span>)</span>
<span id="cb20-16"><a href="#cb20-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb20-17"><a href="#cb20-17" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(occ_all, <span class="fu">aes</span>(<span class="at">x =</span> cycle, <span class="at">y =</span> prob, <span class="at">color =</span> state, <span class="at">linetype =</span> strategy)) <span class="sc">+</span></span>
<span id="cb20-18"><a href="#cb20-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(<span class="at">size =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb20-19"><a href="#cb20-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb20-20"><a href="#cb20-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"State Occupancy Over Time by Strategy"</span>,</span>
<span id="cb20-21"><a href="#cb20-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Cycle"</span>,</span>
<span id="cb20-22"><a href="#cb20-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Proportion of cohort"</span></span>
<span id="cb20-23"><a href="#cb20-23" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb20-24"><a href="#cb20-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ylim</span>(<span class="dv">0</span>, <span class="dv">1</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/07-sim-markov-health-models_files/figure-html/markov-health-plot-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Cohort Markov model: state occupancy over time for Standard vs New.</figcaption>
</figure>
</div>
</div>
</div>
<p>This simple model gives:</p>
<ul>
<li>Lifetime discounted costs and QALYs for each strategy,</li>
<li>State occupancy trajectories,</li>
<li>An ICER for decision making.</li>
</ul>
<hr>
</section>
</section>
<section id="strengths-of-markov-health-decision-models" class="level1">
<h1>4. Strengths of Markov health decision models</h1>
<ol type="1">
<li><p><strong>Natural framework for chronic diseases</strong><br>
Many chronic conditions involve progression through discrete states over time. Markov models capture this in a structured way.</p></li>
<li><p><strong>Transparent and relatively easy to explain</strong><br>
The state-transition structure (with a diagram) is intuitive for clinicians and policymakers: "Patients move between these health states with these probabilities."</p></li>
<li><p><strong>Flexible for time horizons and strategies</strong><br>
You can extend the horizon, add states, and compare multiple strategies relatively easily in a Markov framework.</p></li>
<li><p><strong>Compatible with PSA and VOI</strong><br>
Markov models can be embedded in Monte Carlo simulation to propagate parameter uncertainty, produce CEACs, and support VOI analysis.</p></li>
</ol>
<hr>
</section>
<section id="limitations-of-markov-health-decision-models" class="level1">
<h1>5. Limitations of Markov health decision models</h1>
<ol type="1">
<li><p><strong>Markov assumption and memoryless structure</strong><br>
Without extensions, the model assumes future transitions depend only on the current state, not on how long you've been there or your previous history (which may be unrealistic).</p></li>
<li><p><strong>State explosion with detailed history</strong><br>
Trying to encode more history (e.g., number of previous events, time since last event) can lead to large state spaces and complex models.</p></li>
<li><p><strong>Cycle length and discretization</strong><br>
Choosing annual vs monthly cycles affects accuracy and complexity. Too long a cycle can introduce bias in capturing event timing and mortality.</p></li>
<li><p><strong>Parameter and structural uncertainty</strong><br>
Transition probabilities and state definitions are often uncertain or based on limited data. Structural assumptions (which states, which transitions) can strongly influence results.</p></li>
</ol>
<hr>
</section>
<section id="why-markov-decision-models-matter-for-heor-and-health-policy" class="level1">
<h1>6. Why Markov decision models matter for HEOR and health policy</h1>
<p>Markov models are one of the <strong>workhorses</strong> of health economic evaluation. They're used to:</p>
<ol type="1">
<li><p><strong>Evaluate chronic disease interventions</strong><br>
E.g., screening programs, preventive treatments, chronic disease management - where long-term benefits and costs accumulate over years or decades.</p></li>
<li><p><strong>Support reimbursement and coverage decisions</strong><br>
Health technology assessment (HTA) bodies often see Markov models in submissions for new drugs, devices, and prevention programs.</p></li>
<li><p><strong>Plan population-level strategies</strong><br>
Markov models can be scaled or combined with population data to predict the impact of policies (e.g., vaccination programs, treatment guidelines) on population health and budgets.</p></li>
<li><p><strong>Integrate with more complex simulations</strong><br>
Markov models are often a starting point or a backbone for more complex microsimulation or discrete event simulation models, especially when more detail is required.</p></li>
</ol>
<p>For a health economist, being comfortable with Markov models means:</p>
<ul>
<li>You can translate verbal clinical stories ("patients progress from mild to severe disease...") into formal analytic structures,</li>
<li>You can attach costs and QALYs and produce standard decision metrics (ICERs, CEACs),</li>
<li>You can communicate results transparently to clinicians, HTA bodies, and policymakers.</li>
</ul>
<hr>
</section>
<section id="further-reading" class="level1">
<h1>7. Further reading</h1>
<ol type="1">
<li><p><strong>Briggs, Claxton, &amp; Sculpher - <em>Decision Modelling for Health Economic Evaluation</em>.</strong><br>
Core reference for Markov models, PSA, and economic evaluation.</p></li>
<li><p><strong>Siebert et al.&nbsp;- <em>State-Transition Modeling: A Report of the ISPOR-SMDM Modeling Good Research Practices Task Force.</em> Value in Health.</strong><br>
Detailed guidance on best practices for Markov and state-transition models.</p></li>
<li><p><strong>Sonnenberg &amp; Beck (1993). <em>Markov Models in Medical Decision Making: A Practical Guide.</em> Medical Decision Making.</strong><br>
Classic paper introducing Markov models for medical decision analysis.</p></li>
<li><p><strong>Karnon et al.&nbsp;- <em>A Review and Critique of Modelling in NICE Technology Appraisals.</em> Health Technology Assessment.</strong><br>
Discusses Markov models (among others) in the context of real-world HTA submissions.</p></li>
</ol>


<!-- -->

</section>
