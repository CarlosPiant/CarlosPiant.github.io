---
title: "Markov Chains: When Tomorrow Depends Only on Today"
date: 2026-01-23
categories: [tutorials, codes]
tags: [Simulation Models]
summary: "Imagine a patient whose health state evolves over time:"
---
<section id="introduction-memoryless-but-in-a-useful-way" class="level1">
<h1>1. Introduction: memoryless, but in a useful way</h1>
<p>Imagine a patient whose health state evolves over time:</p>
<ul>
<li>Today: Healthy,</li>
<li>Next year: maybe Sick, maybe still Healthy,</li>
<li>Eventually: sadly, everyone ends up in the Dead state.</li>
</ul>
<p>If we want to model this as a stochastic process, one simple (and surprisingly powerful) idea is:</p>
<blockquote class="blockquote">
<p>"The future depends on the <strong>current</strong> state, not on the full path that got us here."</p>
</blockquote>
<p>This is the <strong>Markov property</strong>, and processes that satisfy it are called <strong>Markov chains</strong>.</p>
<p>A Markov chain is like a short-attention-span model of the world:</p>
<ul>
<li>It remembers only where you are <strong>now</strong>,</li>
<li>Uses a transition probability matrix to decide where you go <strong>next</strong>,</li>
<li>Repeats this step over and over.</li>
</ul>
<p>In this tutorial we'll:</p>
<ul>
<li>Introduce discrete-time Markov chains,</li>
<li>Show how to simulate a simple 3-state chain (Healthy, Sick, Dead),</li>
<li>Look at state occupancy over time,</li>
<li>Discuss strengths and limitations,</li>
<li>And connect this to <strong>Markov health decision models</strong> (which we'll expand in the next tutorial).</li>
</ul>
<hr>
</section>
<section id="foundations-discrete-time-markov-chains" class="level1">
<h1>2. Foundations: discrete-time Markov chains</h1>
<section id="states-and-transition-probabilities" class="level2">
<h2 class="anchored" data-anchor-id="states-and-transition-probabilities">2.1. States and transition probabilities</h2>
<p>A <strong>Markov chain</strong> is defined by:</p>
<ul>
<li>A set of states <span class="math inline">\(S = \{1, 2, \dots, K\}\)</span>,</li>
<li>A <strong>transition matrix</strong> <span class="math inline">\(P\)</span> of size <span class="math inline">\(K \times K\)</span> where:</li>
</ul>
<p><span class="math display">\[
P_{ij} = P(X_{t+1} = j \mid X_t = i),
\]</span></p>
<ul>
<li>Rows sum to 1,</li>
<li><span class="math inline">\(P_{ij} \ge 0\)</span> for all <span class="math inline">\(i, j\)</span>.</li>
</ul>
<p>The evolution is simple:</p>
<ul>
<li>Start in some initial distribution over states,</li>
<li>At each time step, move according to the probabilities in <span class="math inline">\(P\)</span>.</li>
</ul>
</section>
<section id="the-markov-property" class="level2">
<h2 class="anchored" data-anchor-id="the-markov-property">2.2. The Markov property</h2>
<p>The <strong>Markov property</strong> says:</p>
<p><span class="math display">\[
P(X_{t+1} = j \mid X_t = i, X_{t-1}, \dots, X_0) = P(X_{t+1} = j \mid X_t = i).
\]</span></p>
<p>In words: <strong>the future depends only on the present, not on the full past</strong>.</p>
<p>This is a strong assumption - but often a useful approximation in modeling.</p>
</section>
<section id="state-distribution-over-time" class="level2">
<h2 class="anchored" data-anchor-id="state-distribution-over-time">2.3. State distribution over time</h2>
<p>If <span class="math inline">\(\pi_t\)</span> is a row vector of probabilities over states at time <span class="math inline">\(t\)</span>:</p>
<ul>
<li><span class="math inline">\(\pi_0\)</span> is the initial distribution,</li>
<li>Then <span class="math inline">\(\pi_1 = \pi_0 P\)</span>,</li>
<li><span class="math inline">\(\pi_2 = \pi_1 P = \pi_0 P^2\)</span>,</li>
<li>In general, <span class="math inline">\(\pi_t = \pi_0 P^t\)</span>.</li>
</ul>
<p>This matrix algebra is the basis of <strong>cohort-based Markov models</strong> in HEOR.</p>
<hr>
</section>
</section>
<section id="example-in-r-simulating-a-simple-markov-chain" class="level1">
<h1>3. Example in R: simulating a simple Markov chain</h1>
<p>We'll define a toy 3-state Markov chain:</p>
<ol type="1">
<li>Healthy (H)</li>
<li>Sick (S)</li>
<li>Dead (D) - absorbing state</li>
</ol>
<p>Transition matrix (per cycle):</p>
<ul>
<li>From H:
<ul>
<li>Stay H with probability 0.85,</li>
<li>Go S with probability 0.10,</li>
<li>Go D with probability 0.05.</li>
</ul></li>
<li>From S:
<ul>
<li>Go H with probability 0.15,</li>
<li>Stay S with probability 0.70,</li>
<li>Go D with probability 0.15.</li>
</ul></li>
<li>From D:
<ul>
<li>Stay D with probability 1.0 (absorbing).</li>
</ul></li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a>states <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="st">"Healthy"</span>, <span class="st">"Sick"</span>, <span class="st">"Dead"</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>P <span class="ot">&lt;-</span> <span class="fu">matrix</span>(</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">c</span>(</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.85</span>, <span class="fl">0.10</span>, <span class="fl">0.05</span>,  <span class="co"># from Healthy</span></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.15</span>, <span class="fl">0.70</span>, <span class="fl">0.15</span>,  <span class="co"># from Sick</span></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>    <span class="fl">0.00</span>, <span class="fl">0.00</span>, <span class="fl">1.00</span>   <span class="co"># from Dead</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  ),</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  <span class="at">nrow =</span> <span class="dv">3</span>,</span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>  <span class="at">byrow =</span> <span class="cn">TRUE</span></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a><span class="fu">colnames</span>(P) <span class="ot">&lt;-</span> states</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a><span class="fu">rownames</span>(P) <span class="ot">&lt;-</span> states</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>P</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>        Healthy Sick Dead
Healthy    0.85  0.1 0.05
Sick       0.15  0.7 0.15
Dead       0.00  0.0 1.00</code></pre>
</div>
</div>
<section id="simulating-individual-trajectories" class="level2">
<h2 class="anchored" data-anchor-id="simulating-individual-trajectories">3.1. Simulating individual trajectories</h2>
<p>We simulate many individuals over multiple cycles, tracking their states over time.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a>n_ind  <span class="ot">&lt;-</span> <span class="dv">1000</span>  <span class="co"># number of individuals</span></span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a>n_cycle <span class="ot">&lt;-</span> <span class="dv">20</span>   <span class="co"># number of cycles</span></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a><span class="co"># Encode states as indices: 1 = Healthy, 2 = Sick, 3 = Dead</span></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>state_index <span class="ot">&lt;-</span> <span class="fu">setNames</span>(<span class="dv">1</span><span class="sc">:</span><span class="dv">3</span>, states)</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a><span class="co"># Initialize everyone in Healthy at time 0</span></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a>state_mat <span class="ot">&lt;-</span> <span class="fu">matrix</span>(<span class="cn">NA_integer_</span>, <span class="at">nrow =</span> n_ind, <span class="at">ncol =</span> n_cycle <span class="sc">+</span> <span class="dv">1</span>)</span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>state_mat[, <span class="dv">1</span>] <span class="ot">&lt;-</span> state_index[<span class="st">"Healthy"</span>]</span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a><span class="cf">for</span> (t <span class="cf">in</span> <span class="dv">1</span><span class="sc">:</span>n_cycle) {</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a>  <span class="cf">for</span> (i <span class="cf">in</span> <span class="dv">1</span><span class="sc">:</span>n_ind) {</span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a>    current_state <span class="ot">&lt;-</span> state_mat[i, t]</span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>    <span class="co"># Sample next state according to corresponding row in P</span></span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>    state_mat[i, t <span class="sc">+</span> <span class="dv">1</span>] <span class="ot">&lt;-</span> <span class="fu">sample</span>(</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>      <span class="at">x =</span> <span class="dv">1</span><span class="sc">:</span><span class="dv">3</span>,</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>      <span class="at">size =</span> <span class="dv">1</span>,</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>      <span class="at">prob =</span> P[current_state, ]</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb3-23"><a href="#cb3-23" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb3-24"><a href="#cb3-24" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-25"><a href="#cb3-25" aria-hidden="true" tabindex="-1"></a><span class="fu">head</span>(state_mat[, <span class="dv">1</span><span class="sc">:</span><span class="dv">5</span>])</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>     [,1] [,2] [,3] [,4] [,5]
[1,]    1    1    1    1    1
[2,]    1    1    1    1    2
[3,]    1    1    1    1    1
[4,]    1    2    1    1    1
[5,]    1    2    3    3    3
[6,]    1    1    1    1    1</code></pre>
</div>
</div>
</section>
<section id="state-occupancy-over-time" class="level2">
<h2 class="anchored" data-anchor-id="state-occupancy-over-time">3.2. State occupancy over time</h2>
<p>We compute the proportion of individuals in each state at each cycle.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb5"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a>occupancy <span class="ot">&lt;-</span> <span class="fu">matrix</span>(<span class="dv">0</span>, <span class="at">nrow =</span> n_cycle <span class="sc">+</span> <span class="dv">1</span>, <span class="at">ncol =</span> <span class="dv">3</span>)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a><span class="fu">colnames</span>(occupancy) <span class="ot">&lt;-</span> states</span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a><span class="cf">for</span> (t <span class="cf">in</span> <span class="dv">0</span><span class="sc">:</span>n_cycle) {</span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a>  <span class="cf">for</span> (s <span class="cf">in</span> <span class="dv">1</span><span class="sc">:</span><span class="dv">3</span>) {</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a>    occupancy[t <span class="sc">+</span> <span class="dv">1</span>, s] <span class="ot">&lt;-</span> <span class="fu">mean</span>(state_mat[, t <span class="sc">+</span> <span class="dv">1</span>] <span class="sc">==</span> s)</span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a>occupancy_df <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>  <span class="at">cycle =</span> <span class="dv">0</span><span class="sc">:</span>n_cycle,</span>
<span id="cb5-12"><a href="#cb5-12" aria-hidden="true" tabindex="-1"></a>  <span class="at">Healthy =</span> occupancy[, <span class="st">"Healthy"</span>],</span>
<span id="cb5-13"><a href="#cb5-13" aria-hidden="true" tabindex="-1"></a>  <span class="at">Sick    =</span> occupancy[, <span class="st">"Sick"</span>],</span>
<span id="cb5-14"><a href="#cb5-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">Dead    =</span> occupancy[, <span class="st">"Dead"</span>]</span>
<span id="cb5-15"><a href="#cb5-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb5-16"><a href="#cb5-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb5-17"><a href="#cb5-17" aria-hidden="true" tabindex="-1"></a><span class="fu">head</span>(occupancy_df)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>  cycle Healthy  Sick  Dead
1     0   1.000 0.000 0.000
2     1   0.853 0.094 0.053
3     2   0.746 0.141 0.113
4     3   0.677 0.158 0.165
5     4   0.588 0.179 0.233
6     5   0.541 0.177 0.282</code></pre>
</div>
</div>
</section>
<section id="plotting-state-occupancy-over-time" class="level2">
<h2 class="anchored" data-anchor-id="plotting-state-occupancy-over-time">3.3. Plotting state occupancy over time</h2>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb7"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(tidyr)</span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a>occupancy_long <span class="ot">&lt;-</span> occupancy_df <span class="sc">%&gt;%</span></span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">pivot_longer</span>(<span class="at">cols =</span> <span class="sc">-</span>cycle, <span class="at">names_to =</span> <span class="st">"state"</span>, <span class="at">values_to =</span> <span class="st">"prob"</span>)</span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(occupancy_long, <span class="fu">aes</span>(<span class="at">x =</span> cycle, <span class="at">y =</span> prob, <span class="at">color =</span> state)) <span class="sc">+</span></span>
<span id="cb7-8"><a href="#cb7-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>(<span class="at">size =</span> <span class="dv">1</span>) <span class="sc">+</span></span>
<span id="cb7-9"><a href="#cb7-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb7-10"><a href="#cb7-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Markov Chain State Occupancy Over Time"</span>,</span>
<span id="cb7-11"><a href="#cb7-11" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Cycle"</span>,</span>
<span id="cb7-12"><a href="#cb7-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Proportion of individuals"</span></span>
<span id="cb7-13"><a href="#cb7-13" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb7-14"><a href="#cb7-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">ylim</span>(<span class="dv">0</span>, <span class="dv">1</span>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/07-sim-markov-chains_files/figure-html/mcchain-plot-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Simulated Markov chain: proportion of individuals in each state over time.</figcaption>
</figure>
</div>
</div>
</div>
<p>This illustrates how:</p>
<ul>
<li>The Healthy proportion declines,</li>
<li>Sick fluctuates,</li>
<li>Dead gradually accumulates toward 1.</li>
</ul>
<hr>
</section>
</section>
<section id="strengths-of-markov-chains" class="level1">
<h1>4. Strengths of Markov chains</h1>
<ol type="1">
<li><p><strong>Conceptually simple</strong><br>
A small set of states and a transition matrix can describe a wide range of dynamic processes.</p></li>
<li><p><strong>Mathematically tractable</strong><br>
Many properties (state distributions, hitting times, stationary distribution) can be derived via matrix algebra.</p></li>
<li><p><strong>Useful building block</strong><br>
Markov chains form the basis of <strong>cohort Markov models</strong> in HEOR and many other stochastic processes (e.g., Markov decision processes).</p></li>
<li><p><strong>Flexible time discretization</strong><br>
You can choose the cycle length (e.g., monthly, yearly) to match the clinical process and available data.</p></li>
</ol>
<hr>
</section>
<section id="limitations-of-markov-chains" class="level1">
<h1>5. Limitations of Markov chains</h1>
<ol type="1">
<li><p><strong>Markov (memoryless) assumption may be unrealistic</strong><br>
The next state may depend on <strong>time in current state</strong>, prior history, or unobserved factors. Standard Markov chains ignore these unless extended (tunnel states, semi-Markov, etc.).</p></li>
<li><p><strong>State definitions can be tricky</strong><br>
Choosing a "good" state space is non-trivial. Too coarse → miss important dynamics; too fine → models become large and unwieldy.</p></li>
<li><p><strong>Discretization error</strong><br>
Continuous-time processes approximated in discrete cycles (e.g., annual) can introduce bias if transitions are frequent relative to the cycle length.</p></li>
<li><p><strong>Parameter uncertainty and structural uncertainty</strong><br>
As with any model, transition probabilities and structure may be uncertain or mis-specified.</p></li>
</ol>
<hr>
</section>
<section id="why-markov-chains-matter-for-heor-and-health-policy" class="level1">
<h1>6. Why Markov chains matter for HEOR and health policy</h1>
<p>Markov chains are the backbone of <strong>Markov health decision models</strong>, widely used to:</p>
<ul>
<li>Model disease progression over time,</li>
<li>Compare long-term outcomes of alternative interventions,</li>
<li>Attach costs and utilities to states and transitions.</li>
</ul>
<p>Even before adding costs and QALYs, Markov chains help you:</p>
<ol type="1">
<li><p><strong>Understand population dynamics</strong><br>
How many patients will be in each state (e.g., Healthy, Disease, Post-event, Dead) over time?</p></li>
<li><p><strong>Explore intervention effects</strong><br>
How do changes in transition probabilities (e.g., reduced progression) change long-term state occupancy?</p></li>
<li><p><strong>Support capacity planning and resource allocation</strong><br>
Knowing how many people are expected in each state can inform service provision, workforce planning, and budgets.</p></li>
</ol>
<p>In the next tutorial, we extend this to full <strong>Markov health decision models</strong> with costs and QALYs.</p>
<hr>
</section>
<section id="further-reading" class="level1">
<h1>7. Further reading</h1>
<ol type="1">
<li><p><strong>Norris - <em>Markov Chains</em>.</strong><br>
A classic mathematical introduction to Markov chains.</p></li>
<li><p><strong>Ross - <em>Introduction to Probability Models</em>.</strong><br>
Includes accessible chapters on Markov chains and applications.</p></li>
<li><p><strong>Briggs, Claxton, &amp; Sculpher - <em>Decision Modelling for Health Economic Evaluation</em>.</strong><br>
Connects Markov chains directly to health economic decision models.</p></li>
<li><p><strong>Siebert et al.&nbsp;- <em>State-Transition Modeling: A Report of the ISPOR-SMDM Modeling Good Research Practices Task Force.</em> Value in Health.</strong><br>
Guidance on state-transition (Markov) models in HEOR.</p></li>
</ol>


<!-- -->

</section>
