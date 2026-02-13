---
title: "Bandits & A/B Testing: Teaching Your Model to Experiment"
date: 2026-01-28
categories: [tutorials, codes]
tags: [Simulation Models]
summary: "In a lot of applications (including HEOR and health policy), we face a recurring question:"
---
<section id="introduction-when-your-model-has-commitment-issues" class="level1">
<h1>1. Introduction: when your model has commitment issues</h1>
<p>In a lot of applications (including HEOR and health policy), we face a recurring question:</p>
<blockquote class="blockquote">
<p>"Which option is better - A, B, or maybe C - and how do we <strong>learn</strong> that while still doing right by people?"</p>
</blockquote>
<p>Three related approaches show up a lot:</p>
<ul>
<li><strong>A/B testing</strong> - the classic: randomize, wait, analyze, <em>then</em> pick a winner.</li>
<li><strong>Multi-armed bandits (MAB)</strong> - adapt as you go: explore a bit, exploit a bit, repeat.</li>
<li><strong>Contextual bandits</strong> - like bandits, but with memory of <em>who</em> you're treating (covariates/context).</li>
</ul>
<p>You can think of it as:</p>
<ul>
<li>A/B testing: "Fair, clean experiment first; decisions later."</li>
<li>Multi-armed bandit: "Learn while doing; gradually play favorites."</li>
<li>Contextual bandit: "Learn while doing, but tailor choices to patient characteristics."</li>
</ul>
<p>In this tutorial we'll:</p>
<ul>
<li>Introduce each method with intuition,</li>
<li>Work through small synthetic examples in R,</li>
<li>Highlight pros and cons,</li>
<li>And briefly connect them to HEOR and health policy use cases.</li>
</ul>
<p>This will be a bit longer than other tutorials because we're packing <strong>three</strong> methods into one.</p>
<section id="successes-rewards-and-regret-quick-definitions" class="level2">
<h2 class="anchored" data-anchor-id="successes-rewards-and-regret-quick-definitions">Successes, rewards, and regret: quick definitions</h2>
<p>Before we dive too deep into algorithms, it helps to clarify three key quantities we keep tracking in bandit problems:</p>
<section id="successes" class="level3">
<h3 class="anchored" data-anchor-id="successes">Successes</h3>
<p>In a bandit setup, a <em>success</em> is simply a "good" outcome for the chosen arm.<br>
Examples:</p>
<ul>
<li>A patient <strong>attends</strong> a screening appointment,</li>
<li>A reminder <strong>improves</strong> adherence,</li>
<li>A message <strong>leads</strong> to the desired action.</li>
</ul>
<p>In code, we usually record successes as <code>1</code> and failures as <code>0</code>, and we keep a running count of how many successes each arm has accumulated over time.</p>
</section>
<section id="rewards" class="level3">
<h3 class="anchored" data-anchor-id="rewards">Rewards</h3>
<p>The <strong>reward</strong> is the numerical payoff we assign to each outcome.</p>
<ul>
<li>In simple examples, the reward is just the success indicator: 1 for success, 0 for failure.</li>
<li>In more general settings, the reward could be:
<ul>
<li>A continuous outcome (e.g., cost savings),</li>
<li>An improvement in a risk score,</li>
<li>QALYs gained.</li>
</ul></li>
</ul>
<p>Bandit algorithms are designed to <strong>maximize total reward</strong> (or its expectation) over time.</p>
</section>
<section id="regret" class="level3">
<h3 class="anchored" data-anchor-id="regret">Regret</h3>
<p><strong>Regret</strong> measures how much better we <em>could</em> have done if we had always chosen the best possible arm at each step.</p>
<ul>
<li><p><em>Instantaneous regret</em> at time <span class="math inline">\(t\)</span>:</p>
<p><span class="math display">\[
\text{regret}_t
=
\text{expected reward of the best arm}
-
\text{expected reward of the chosen arm}.
\]</span></p></li>
<li><p><em>Cumulative regret</em> up to time <span class="math inline">\(T\)</span>:</p>
<p><span class="math display">\[
\text{Cumulative regret}(T)
=
\sum_{t=1}^{T} \text{regret}_t.
\]</span></p></li>
</ul>
<p>Low cumulative regret means the algorithm quickly learns to choose near-optimal actions. High cumulative regret means it spent a lot of time pulling suboptimal arms (for example, sticking too long with a weak intervention or over-exploring ones that don't work very well).</p>
<hr>
</section>
</section>
</section>
<section id="multi-armed-bandit-mab-slot-machines-for-statisticians" class="level1">
<h1>2. Multi-Armed Bandit (MAB): slot machines for statisticians</h1>
<section id="what-is-a-multi-armed-bandit" class="level2">
<h2 class="anchored" data-anchor-id="what-is-a-multi-armed-bandit">2.1. What is a multi-armed bandit?</h2>
<p>The classic mental picture:</p>
<ul>
<li>You walk into a casino with several slot machines ("arms"),</li>
<li>Each arm pays out with an unknown probability,</li>
<li>You want to <strong>maximize total reward</strong> over time.</li>
</ul>
<p>At each time <span class="math inline">\(t\)</span>:</p>
<ul>
<li>You choose an arm <span class="math inline">\(A_t\)</span>,</li>
<li>You observe a reward <span class="math inline">\(R_t\)</span> (e.g., 1 for success, 0 for failure),</li>
<li>You update your beliefs/policy and move on.</li>
</ul>
<p>The <strong>exploration-exploitation tradeoff</strong>:</p>
<ul>
<li><strong>Explore</strong>: try different arms to learn their payoffs,</li>
<li><strong>Exploit</strong>: choose the arm that currently looks best.</li>
</ul>
<p>If you only exploit:</p>
<ul>
<li>You may get stuck on a suboptimal arm because early random luck favored it.</li>
</ul>
<p>If you only explore:</p>
<ul>
<li>You waste time pulling obviously bad arms.</li>
</ul>
<p>Multi-armed bandit algorithms are strategies to balance exploration and exploitation.</p>
<p>We'll illustrate with a simple <strong>ε-greedy</strong> algorithm.</p>
<hr>
</section>
<section id="synthetic-example-3-arm-bernoulli-bandit-with-ε-greedy" class="level2">
<h2 class="anchored" data-anchor-id="synthetic-example-3-arm-bernoulli-bandit-with-ε-greedy">2.2. Synthetic example: 3-arm Bernoulli bandit with ε-greedy</h2>
<p>Imagine three treatments (arms):</p>
<ul>
<li>Arm 1: true success probability <span class="math inline">\(p_1 = 0.30\)</span>,</li>
<li>Arm 2: true success probability <span class="math inline">\(p_2 = 0.50\)</span>,</li>
<li>Arm 3: true success probability <span class="math inline">\(p_3 = 0.60\)</span> (the best).</li>
</ul>
<p>We don't know these probabilities. We just see successes/failures.</p>
<p>The <strong>ε-greedy</strong> policy:</p>
<ul>
<li>With probability <span class="math inline">\(\epsilon\)</span> (e.g., 0.1): <strong>explore</strong> (choose a random arm),</li>
<li>With probability <span class="math inline">\(1 - \epsilon\)</span>: <strong>exploit</strong> (choose the arm with highest estimated success rate so far).</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="co"># True success probabilities for the 3 arms</span></span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>true_p <span class="ot">&lt;-</span> <span class="fu">c</span>(<span class="fl">0.30</span>, <span class="fl">0.50</span>, <span class="fl">0.60</span>)</span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>k <span class="ot">&lt;-</span> <span class="fu">length</span>(true_p)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>n_rounds <span class="ot">&lt;-</span> <span class="dv">1000</span></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>epsilon <span class="ot">&lt;-</span> <span class="fl">0.1</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a><span class="co"># Storage</span></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>arm_counts   <span class="ot">&lt;-</span> <span class="fu">rep</span>(<span class="dv">0</span>, k)   <span class="co"># how many times each arm was pulled</span></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>arm_success  <span class="ot">&lt;-</span> <span class="fu">rep</span>(<span class="dv">0</span>, k)   <span class="co"># how many successes for each arm</span></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>chosen_arm   <span class="ot">&lt;-</span> <span class="fu">integer</span>(n_rounds)</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>reward       <span class="ot">&lt;-</span> <span class="fu">numeric</span>(n_rounds)</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>optimal_arm  <span class="ot">&lt;-</span> <span class="fu">which.max</span>(true_p)</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>regret       <span class="ot">&lt;-</span> <span class="fu">numeric</span>(n_rounds) <span class="co"># instantaneous regret</span></span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
<p>Now we simulate:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb2"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="cf">for</span> (t <span class="cf">in</span> <span class="dv">1</span><span class="sc">:</span>n_rounds) {</span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Decide whether to explore or exploit</span></span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a>  <span class="cf">if</span> (<span class="fu">runif</span>(<span class="dv">1</span>) <span class="sc">&lt;</span> epsilon <span class="sc">||</span> <span class="fu">sum</span>(arm_counts) <span class="sc">==</span> <span class="dv">0</span>) {</span>
<span id="cb2-4"><a href="#cb2-4" aria-hidden="true" tabindex="-1"></a>    <span class="co"># Explore: choose an arm at random</span></span>
<span id="cb2-5"><a href="#cb2-5" aria-hidden="true" tabindex="-1"></a>    a_t <span class="ot">&lt;-</span> <span class="fu">sample</span>(<span class="dv">1</span><span class="sc">:</span>k, <span class="dv">1</span>)</span>
<span id="cb2-6"><a href="#cb2-6" aria-hidden="true" tabindex="-1"></a>  } <span class="cf">else</span> {</span>
<span id="cb2-7"><a href="#cb2-7" aria-hidden="true" tabindex="-1"></a>    <span class="co"># Exploit: choose arm with highest empirical success rate</span></span>
<span id="cb2-8"><a href="#cb2-8" aria-hidden="true" tabindex="-1"></a>    emp_rate <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(arm_counts <span class="sc">&gt;</span> <span class="dv">0</span>, arm_success <span class="sc">/</span> arm_counts, <span class="dv">0</span>)</span>
<span id="cb2-9"><a href="#cb2-9" aria-hidden="true" tabindex="-1"></a>    a_t <span class="ot">&lt;-</span> <span class="fu">which.max</span>(emp_rate)</span>
<span id="cb2-10"><a href="#cb2-10" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb2-11"><a href="#cb2-11" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-12"><a href="#cb2-12" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Generate reward from the true Bernoulli distribution</span></span>
<span id="cb2-13"><a href="#cb2-13" aria-hidden="true" tabindex="-1"></a>  r_t <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(<span class="dv">1</span>, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> true_p[a_t])</span>
<span id="cb2-14"><a href="#cb2-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-15"><a href="#cb2-15" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Update</span></span>
<span id="cb2-16"><a href="#cb2-16" aria-hidden="true" tabindex="-1"></a>  arm_counts[a_t]  <span class="ot">&lt;-</span> arm_counts[a_t] <span class="sc">+</span> <span class="dv">1</span></span>
<span id="cb2-17"><a href="#cb2-17" aria-hidden="true" tabindex="-1"></a>  arm_success[a_t] <span class="ot">&lt;-</span> arm_success[a_t] <span class="sc">+</span> r_t</span>
<span id="cb2-18"><a href="#cb2-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-19"><a href="#cb2-19" aria-hidden="true" tabindex="-1"></a>  chosen_arm[t] <span class="ot">&lt;-</span> a_t</span>
<span id="cb2-20"><a href="#cb2-20" aria-hidden="true" tabindex="-1"></a>  reward[t]     <span class="ot">&lt;-</span> r_t</span>
<span id="cb2-21"><a href="#cb2-21" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-22"><a href="#cb2-22" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Regret: difference between best possible expected reward and chosen arm's expected reward</span></span>
<span id="cb2-23"><a href="#cb2-23" aria-hidden="true" tabindex="-1"></a>  regret[t] <span class="ot">&lt;-</span> <span class="fu">max</span>(true_p) <span class="sc">-</span> true_p[a_t]</span>
<span id="cb2-24"><a href="#cb2-24" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb2-25"><a href="#cb2-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb2-26"><a href="#cb2-26" aria-hidden="true" tabindex="-1"></a><span class="co"># Cumulative reward and regret</span></span>
<span id="cb2-27"><a href="#cb2-27" aria-hidden="true" tabindex="-1"></a>cum_reward <span class="ot">&lt;-</span> <span class="fu">cumsum</span>(reward)</span>
<span id="cb2-28"><a href="#cb2-28" aria-hidden="true" tabindex="-1"></a>cum_regret <span class="ot">&lt;-</span> <span class="fu">cumsum</span>(regret)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
<section id="visualizing-learning-and-regret" class="level3">
<h3 class="anchored" data-anchor-id="visualizing-learning-and-regret">2.3. Visualizing learning and regret</h3>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb3"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(tidyr)</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(dplyr)</span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a>df_bandit <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">round =</span> <span class="dv">1</span><span class="sc">:</span>n_rounds,</span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">cum_reward =</span> cum_reward,</span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a>  <span class="at">cum_regret =</span> cum_regret</span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a>df_bandit_long <span class="ot">&lt;-</span> df_bandit <span class="sc">%&gt;%</span></span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a>  <span class="fu">pivot_longer</span>(<span class="at">cols =</span> <span class="fu">c</span>(<span class="st">"cum_reward"</span>, <span class="st">"cum_regret"</span>),</span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a>               <span class="at">names_to =</span> <span class="st">"metric"</span>, <span class="at">values_to =</span> <span class="st">"value"</span>)</span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(df_bandit_long, <span class="fu">aes</span>(<span class="at">x =</span> round, <span class="at">y =</span> value, <span class="at">color =</span> metric)) <span class="sc">+</span></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_line</span>() <span class="sc">+</span></span>
<span id="cb3-17"><a href="#cb3-17" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb3-18"><a href="#cb3-18" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Epsilon-Greedy Bandit Performance"</span>,</span>
<span id="cb3-19"><a href="#cb3-19" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Round"</span>,</span>
<span id="cb3-20"><a href="#cb3-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Value"</span>,</span>
<span id="cb3-21"><a href="#cb3-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">color =</span> <span class="st">"Metric"</span></span>
<span id="cb3-22"><a href="#cb3-22" aria-hidden="true" tabindex="-1"></a>  )</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div class="quarto-figure quarto-figure-center">
<figure class="figure">
<p><img src="/tutorials/07-sim-bandits-ab-testing_files/figure-html/mab-eps-plot-1.png" class="img-fluid figure-img" width="672"></p>
<figcaption>Epsilon-greedy bandit: cumulative reward and regret over time.</figcaption>
</figure>
</div>
</div>
</div>
<p>We can also see how often each arm was chosen:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb4"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a><span class="fu">table</span>(chosen_arm)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>chosen_arm
  1   2   3 
 74 349 577 </code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb6"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>arm_counts</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>[1]  74 349 577</code></pre>
</div>
</div>
<p>Over time, the algorithm should:</p>
<ul>
<li>Pull the best arm (Arm 3) more often,</li>
<li>Accumulate relatively low regret,</li>
<li>Still occasionally explore other arms.</li>
</ul>
<hr>
</section>
</section>
<section id="multi-armed-bandit-pros-and-cons" class="level2">
<h2 class="anchored" data-anchor-id="multi-armed-bandit-pros-and-cons">2.4. Multi-armed bandit: pros and cons</h2>
<p><strong>Pros</strong></p>
<ol type="1">
<li><p><strong>Adaptive learning</strong><br>
Learns while acting: arms with better observed performance get more weight, potentially improving average outcomes during the learning phase.</p></li>
<li><p><strong>Efficient use of data</strong><br>
Observations are concentrated on better-performing arms over time, which can be more efficient than fixed designs in some settings.</p></li>
<li><p><strong>Natural framework for online decision-making</strong><br>
Ideal when decisions are sequential and you can update as new data arrive.</p></li>
<li><p><strong>Multiple algorithms available</strong><br>
ε-greedy, UCB, Thompson sampling, etc., with different theoretical guarantees and practical behavior.</p></li>
</ol>
<p><strong>Cons</strong></p>
<ol type="1">
<li><p><strong>Complexity vs classic trials</strong><br>
More complex to design, analyze, and explain compared to simple A/B tests or RCTs.</p></li>
<li><p><strong>Bias in estimation</strong><br>
Because assignment probabilities depend on past outcomes, naive estimators for treatment effects can be biased.</p></li>
<li><p><strong>Ethical / operational constraints</strong><br>
In healthcare, continuously changing assignment probabilities may raise ethical, operational, or regulatory questions.</p></li>
<li><p><strong>Context ignored (in basic MAB)</strong><br>
Standard multi-armed bandits treat all users/patients as exchangeable, ignoring covariates - which can be a big limitation in health settings.</p></li>
</ol>
<hr>
</section>
</section>
<section id="contextual-bandit-personalization-meets-bandits" class="level1">
<h1>3. Contextual Bandit: personalization meets bandits</h1>
<section id="what-is-a-contextual-bandit" class="level2">
<h2 class="anchored" data-anchor-id="what-is-a-contextual-bandit">3.1. What is a contextual bandit?</h2>
<p>A <strong>contextual bandit</strong> extends multi-armed bandits by including <strong>features of the current situation</strong> (context):</p>
<ul>
<li>Patient-level covariates (age, comorbidities, risk scores),</li>
<li>Time-varying characteristics (season, clinic, etc.).</li>
</ul>
<p>At each step:</p>
<ol type="1">
<li>Observe context <span class="math inline">\(x_t\)</span>,</li>
<li>Choose an action (arm) <span class="math inline">\(A_t\)</span>,</li>
<li>Observe reward <span class="math inline">\(R_t\)</span>,</li>
<li>Update a <strong>context-dependent</strong> policy (e.g., a model for reward given context and arm).</li>
</ol>
<p>The goal is still to maximize cumulative reward, but:</p>
<ul>
<li>The best arm <strong>depends on the context</strong>.</li>
</ul>
<p>This is like "personalized bandits" or "online contextual policy learning."</p>
<hr>
</section>
<section id="synthetic-example-simple-contextual-ε-greedy-with-two-patient-types" class="level2">
<h2 class="anchored" data-anchor-id="synthetic-example-simple-contextual-ε-greedy-with-two-patient-types">3.2. Synthetic example: simple contextual ε-greedy with two patient types</h2>
<p>To keep things simple, suppose:</p>
<ul>
<li><p>2 arms: Treatment A and Treatment B,</p></li>
<li><p>Patients have a binary context: <code>high_risk</code> vs <code>low_risk</code>,</p></li>
<li><p>True success probabilities:</p>
<ul>
<li>For low-risk patients:
<ul>
<li>A: 0.8</li>
<li>B: 0.6</li>
</ul></li>
<li>For high-risk patients:
<ul>
<li>A: 0.4</li>
<li>B: 0.7</li>
</ul></li>
</ul></li>
</ul>
<p>So:</p>
<ul>
<li>Low-risk patients do better with A,</li>
<li>High-risk patients do better with B.</li>
</ul>
<p>We'll use a very simple contextual policy:</p>
<ul>
<li>For each arm and context, estimate success rate separately,</li>
<li>Use ε-greedy <strong>within context</strong>.</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb8"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb8-1"><a href="#cb8-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb8-2"><a href="#cb8-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-3"><a href="#cb8-3" aria-hidden="true" tabindex="-1"></a>n_rounds <span class="ot">&lt;-</span> <span class="dv">2000</span></span>
<span id="cb8-4"><a href="#cb8-4" aria-hidden="true" tabindex="-1"></a>epsilon  <span class="ot">&lt;-</span> <span class="fl">0.1</span></span>
<span id="cb8-5"><a href="#cb8-5" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-6"><a href="#cb8-6" aria-hidden="true" tabindex="-1"></a><span class="co"># Context: high_risk (1) or low_risk (0)</span></span>
<span id="cb8-7"><a href="#cb8-7" aria-hidden="true" tabindex="-1"></a><span class="co"># We'll simulate a mix of 60% low-risk, 40% high-risk</span></span>
<span id="cb8-8"><a href="#cb8-8" aria-hidden="true" tabindex="-1"></a>context <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(n_rounds, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> <span class="fl">0.4</span>)  <span class="co"># 1 = high risk</span></span>
<span id="cb8-9"><a href="#cb8-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-10"><a href="#cb8-10" aria-hidden="true" tabindex="-1"></a><span class="co"># True success probabilities as a function of context and arm</span></span>
<span id="cb8-11"><a href="#cb8-11" aria-hidden="true" tabindex="-1"></a>true_p_context <span class="ot">&lt;-</span> <span class="cf">function</span>(ctx, arm) {</span>
<span id="cb8-12"><a href="#cb8-12" aria-hidden="true" tabindex="-1"></a>  <span class="cf">if</span> (ctx <span class="sc">==</span> <span class="dv">0</span>) { <span class="co"># low-risk</span></span>
<span id="cb8-13"><a href="#cb8-13" aria-hidden="true" tabindex="-1"></a>    <span class="cf">if</span> (arm <span class="sc">==</span> <span class="dv">1</span>) <span class="fu">return</span>(<span class="fl">0.8</span>) <span class="cf">else</span> <span class="fu">return</span>(<span class="fl">0.6</span>)</span>
<span id="cb8-14"><a href="#cb8-14" aria-hidden="true" tabindex="-1"></a>  } <span class="cf">else</span> {        <span class="co"># high-risk</span></span>
<span id="cb8-15"><a href="#cb8-15" aria-hidden="true" tabindex="-1"></a>    <span class="cf">if</span> (arm <span class="sc">==</span> <span class="dv">1</span>) <span class="fu">return</span>(<span class="fl">0.4</span>) <span class="cf">else</span> <span class="fu">return</span>(<span class="fl">0.7</span>)</span>
<span id="cb8-16"><a href="#cb8-16" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb8-17"><a href="#cb8-17" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb8-18"><a href="#cb8-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-19"><a href="#cb8-19" aria-hidden="true" tabindex="-1"></a>k <span class="ot">&lt;-</span> <span class="dv">2</span>  <span class="co"># two arms</span></span>
<span id="cb8-20"><a href="#cb8-20" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-21"><a href="#cb8-21" aria-hidden="true" tabindex="-1"></a><span class="co"># Track counts and successes by context and arm</span></span>
<span id="cb8-22"><a href="#cb8-22" aria-hidden="true" tabindex="-1"></a><span class="co"># rows: context (0,1), cols: arm (1,2)</span></span>
<span id="cb8-23"><a href="#cb8-23" aria-hidden="true" tabindex="-1"></a>counts <span class="ot">&lt;-</span> <span class="fu">matrix</span>(<span class="dv">0</span>, <span class="at">nrow =</span> <span class="dv">2</span>, <span class="at">ncol =</span> k)</span>
<span id="cb8-24"><a href="#cb8-24" aria-hidden="true" tabindex="-1"></a>success <span class="ot">&lt;-</span> <span class="fu">matrix</span>(<span class="dv">0</span>, <span class="at">nrow =</span> <span class="dv">2</span>, <span class="at">ncol =</span> k)</span>
<span id="cb8-25"><a href="#cb8-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb8-26"><a href="#cb8-26" aria-hidden="true" tabindex="-1"></a>chosen_arm <span class="ot">&lt;-</span> <span class="fu">integer</span>(n_rounds)</span>
<span id="cb8-27"><a href="#cb8-27" aria-hidden="true" tabindex="-1"></a>reward     <span class="ot">&lt;-</span> <span class="fu">numeric</span>(n_rounds)</span>
<span id="cb8-28"><a href="#cb8-28" aria-hidden="true" tabindex="-1"></a>optimal    <span class="ot">&lt;-</span> <span class="fu">integer</span>(n_rounds)</span>
<span id="cb8-29"><a href="#cb8-29" aria-hidden="true" tabindex="-1"></a>regret     <span class="ot">&lt;-</span> <span class="fu">numeric</span>(n_rounds)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
<p>Simulation:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb9"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb9-1"><a href="#cb9-1" aria-hidden="true" tabindex="-1"></a><span class="cf">for</span> (t <span class="cf">in</span> <span class="dv">1</span><span class="sc">:</span>n_rounds) {</span>
<span id="cb9-2"><a href="#cb9-2" aria-hidden="true" tabindex="-1"></a>  ctx <span class="ot">&lt;-</span> context[t]       <span class="co"># 0 or 1</span></span>
<span id="cb9-3"><a href="#cb9-3" aria-hidden="true" tabindex="-1"></a>  row_idx <span class="ot">&lt;-</span> ctx <span class="sc">+</span> <span class="dv">1</span>      <span class="co"># map 0-&gt;1, 1-&gt;2 for matrix indexing</span></span>
<span id="cb9-4"><a href="#cb9-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-5"><a href="#cb9-5" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Epsilon-greedy within context</span></span>
<span id="cb9-6"><a href="#cb9-6" aria-hidden="true" tabindex="-1"></a>  <span class="cf">if</span> (<span class="fu">runif</span>(<span class="dv">1</span>) <span class="sc">&lt;</span> epsilon <span class="sc">||</span> <span class="fu">sum</span>(counts[row_idx, ]) <span class="sc">==</span> <span class="dv">0</span>) {</span>
<span id="cb9-7"><a href="#cb9-7" aria-hidden="true" tabindex="-1"></a>    a_t <span class="ot">&lt;-</span> <span class="fu">sample</span>(<span class="dv">1</span><span class="sc">:</span>k, <span class="dv">1</span>)</span>
<span id="cb9-8"><a href="#cb9-8" aria-hidden="true" tabindex="-1"></a>  } <span class="cf">else</span> {</span>
<span id="cb9-9"><a href="#cb9-9" aria-hidden="true" tabindex="-1"></a>    emp_rate <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(counts[row_idx, ] <span class="sc">&gt;</span> <span class="dv">0</span>,</span>
<span id="cb9-10"><a href="#cb9-10" aria-hidden="true" tabindex="-1"></a>                       success[row_idx, ] <span class="sc">/</span> counts[row_idx, ],</span>
<span id="cb9-11"><a href="#cb9-11" aria-hidden="true" tabindex="-1"></a>                       <span class="dv">0</span>)</span>
<span id="cb9-12"><a href="#cb9-12" aria-hidden="true" tabindex="-1"></a>    a_t <span class="ot">&lt;-</span> <span class="fu">which.max</span>(emp_rate)</span>
<span id="cb9-13"><a href="#cb9-13" aria-hidden="true" tabindex="-1"></a>  }</span>
<span id="cb9-14"><a href="#cb9-14" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-15"><a href="#cb9-15" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Generate reward</span></span>
<span id="cb9-16"><a href="#cb9-16" aria-hidden="true" tabindex="-1"></a>  p_true <span class="ot">&lt;-</span> <span class="fu">true_p_context</span>(ctx, a_t)</span>
<span id="cb9-17"><a href="#cb9-17" aria-hidden="true" tabindex="-1"></a>  r_t <span class="ot">&lt;-</span> <span class="fu">rbinom</span>(<span class="dv">1</span>, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> p_true)</span>
<span id="cb9-18"><a href="#cb9-18" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-19"><a href="#cb9-19" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Update</span></span>
<span id="cb9-20"><a href="#cb9-20" aria-hidden="true" tabindex="-1"></a>  counts[row_idx, a_t]  <span class="ot">&lt;-</span> counts[row_idx, a_t] <span class="sc">+</span> <span class="dv">1</span></span>
<span id="cb9-21"><a href="#cb9-21" aria-hidden="true" tabindex="-1"></a>  success[row_idx, a_t] <span class="ot">&lt;-</span> success[row_idx, a_t] <span class="sc">+</span> r_t</span>
<span id="cb9-22"><a href="#cb9-22" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-23"><a href="#cb9-23" aria-hidden="true" tabindex="-1"></a>  chosen_arm[t] <span class="ot">&lt;-</span> a_t</span>
<span id="cb9-24"><a href="#cb9-24" aria-hidden="true" tabindex="-1"></a>  reward[t]     <span class="ot">&lt;-</span> r_t</span>
<span id="cb9-25"><a href="#cb9-25" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-26"><a href="#cb9-26" aria-hidden="true" tabindex="-1"></a>  <span class="co"># Optimal arm for this context</span></span>
<span id="cb9-27"><a href="#cb9-27" aria-hidden="true" tabindex="-1"></a>  p_arm1 <span class="ot">&lt;-</span> <span class="fu">true_p_context</span>(ctx, <span class="dv">1</span>)</span>
<span id="cb9-28"><a href="#cb9-28" aria-hidden="true" tabindex="-1"></a>  p_arm2 <span class="ot">&lt;-</span> <span class="fu">true_p_context</span>(ctx, <span class="dv">2</span>)</span>
<span id="cb9-29"><a href="#cb9-29" aria-hidden="true" tabindex="-1"></a>  best_p <span class="ot">&lt;-</span> <span class="fu">max</span>(p_arm1, p_arm2)</span>
<span id="cb9-30"><a href="#cb9-30" aria-hidden="true" tabindex="-1"></a>  regret[t] <span class="ot">&lt;-</span> best_p <span class="sc">-</span> p_true</span>
<span id="cb9-31"><a href="#cb9-31" aria-hidden="true" tabindex="-1"></a>}</span>
<span id="cb9-32"><a href="#cb9-32" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb9-33"><a href="#cb9-33" aria-hidden="true" tabindex="-1"></a>cum_reward_cb <span class="ot">&lt;-</span> <span class="fu">cumsum</span>(reward)</span>
<span id="cb9-34"><a href="#cb9-34" aria-hidden="true" tabindex="-1"></a>cum_regret_cb <span class="ot">&lt;-</span> <span class="fu">cumsum</span>(regret)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
</div>
<section id="comparing-contextual-vs-non-contextual-policies-sketch" class="level3">
<h3 class="anchored" data-anchor-id="comparing-contextual-vs-non-contextual-policies-sketch">3.3. Comparing contextual vs non-contextual policies (sketch)</h3>
<p>For brevity, we won't fully simulate a non-contextual bandit here, but conceptually:</p>
<ul>
<li>A <strong>non-contextual</strong> bandit would try to find one best arm for <strong>everyone</strong>,</li>
<li>But in our setup, the best arm <strong>depends on patient type</strong>,</li>
<li>A contextual bandit can adapt treatment choices to context and achieve higher overall reward (success rate) and lower regret.</li>
</ul>
<p>You could implement a non-contextual ε-greedy policy on the same data and compare cumulative regret across the two policies.</p>
</section>
<section id="pros-and-cons-of-contextual-bandits" class="level3">
<h3 class="anchored" data-anchor-id="pros-and-cons-of-contextual-bandits">3.4. Pros and cons of contextual bandits</h3>
<p><strong>Pros</strong></p>
<ol type="1">
<li><p><strong>Personalization</strong><br>
Can tailor treatment/decisions to patient covariates, potentially improving overall outcomes compared to one-size-fits-all policies.</p></li>
<li><p><strong>More realistic for health applications</strong><br>
In HEOR and policy, context (risk profile, comorbidities, clinic, time) is almost always important.</p></li>
<li><p><strong>Bridges to supervised learning</strong><br>
Many contextual bandit algorithms (e.g., linear models, generalized linear models, neural networks) look like supervised learning with an exploration component.</p></li>
<li><p><strong>Data efficiency</strong><br>
Can share information across similar contexts, improving learning speed in rich covariate spaces.</p></li>
</ol>
<p><strong>Cons</strong></p>
<ol type="1">
<li><p><strong>More complex modeling</strong><br>
Requires modeling reward as a function of context and action, which can be statistically and computationally more demanding.</p></li>
<li><p><strong>Risk of model misspecification</strong><br>
If the reward model is wrong or too rigid, the policy may learn suboptimal treatment rules.</p></li>
<li><p><strong>Fairness and subgroup issues</strong><br>
If not designed carefully, contextual bandits can reinforce disparities by under-exploring certain subgroups.</p></li>
<li><p><strong>Implementation burden</strong><br>
Requires infrastructure to collect covariates in real time, run the policy, and log data - non-trivial in many health systems.</p></li>
</ol>
<hr>
</section>
</section>
</section>
<section id="ab-testing-the-old-but-reliable-workhorse" class="level1">
<h1>4. A/B Testing: the old but reliable workhorse</h1>
<section id="what-is-ab-testing" class="level2">
<h2 class="anchored" data-anchor-id="what-is-ab-testing">4.1. What is A/B testing?</h2>
<p><strong>A/B testing</strong> (or controlled trials with two arms) is the classic:</p>
<ol type="1">
<li>Randomize individuals to A or B,</li>
<li>Collect outcomes,</li>
<li>Run a statistical test (e.g., difference in means/proportions),</li>
<li>Decide which arm is better (if any).</li>
</ol>
<p>Key features:</p>
<ul>
<li>Assignment probabilities are usually fixed (e.g., 50/50),</li>
<li>No adaptation over time,</li>
<li>Analysis is usually done <strong>after</strong> data collection stops.</li>
</ul>
<p>This is conceptually simple and aligns well with:</p>
<ul>
<li>Classical statistics,</li>
<li>Regulatory standards,</li>
<li>Many HEOR and clinical trial practices.</li>
</ul>
<hr>
</section>
<section id="synthetic-example-simple-ab-test-on-binary-outcomes" class="level2">
<h2 class="anchored" data-anchor-id="synthetic-example-simple-ab-test-on-binary-outcomes">4.2. Synthetic example: simple A/B test on binary outcomes</h2>
<p>We'll use a very similar setup as the bandit example:</p>
<ul>
<li>Treatment A: true success probability 0.5,</li>
<li>Treatment B: true success probability 0.6.</li>
</ul>
<p>We'll:</p>
<ul>
<li>Randomize 1,000 patients 50/50 A vs B,</li>
<li>Observe outcomes,</li>
<li>Perform a simple proportion test.</li>
</ul>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb10"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb10-1"><a href="#cb10-1" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb10-2"><a href="#cb10-2" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb10-3"><a href="#cb10-3" aria-hidden="true" tabindex="-1"></a>n_total <span class="ot">&lt;-</span> <span class="dv">1000</span></span>
<span id="cb10-4"><a href="#cb10-4" aria-hidden="true" tabindex="-1"></a>p_A <span class="ot">&lt;-</span> <span class="fl">0.5</span></span>
<span id="cb10-5"><a href="#cb10-5" aria-hidden="true" tabindex="-1"></a>p_B <span class="ot">&lt;-</span> <span class="fl">0.6</span></span>
<span id="cb10-6"><a href="#cb10-6" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb10-7"><a href="#cb10-7" aria-hidden="true" tabindex="-1"></a><span class="co"># Randomize 50/50</span></span>
<span id="cb10-8"><a href="#cb10-8" aria-hidden="true" tabindex="-1"></a>treatment <span class="ot">&lt;-</span> <span class="fu">sample</span>(<span class="fu">c</span>(<span class="st">"A"</span>, <span class="st">"B"</span>), <span class="at">size =</span> n_total, <span class="at">replace =</span> <span class="cn">TRUE</span>)</span>
<span id="cb10-9"><a href="#cb10-9" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb10-10"><a href="#cb10-10" aria-hidden="true" tabindex="-1"></a><span class="co"># Generate outcomes</span></span>
<span id="cb10-11"><a href="#cb10-11" aria-hidden="true" tabindex="-1"></a>outcome <span class="ot">&lt;-</span> <span class="fu">ifelse</span>(</span>
<span id="cb10-12"><a href="#cb10-12" aria-hidden="true" tabindex="-1"></a>  treatment <span class="sc">==</span> <span class="st">"A"</span>,</span>
<span id="cb10-13"><a href="#cb10-13" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rbinom</span>(n_total, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> p_A),</span>
<span id="cb10-14"><a href="#cb10-14" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rbinom</span>(n_total, <span class="at">size =</span> <span class="dv">1</span>, <span class="at">prob =</span> p_B)</span>
<span id="cb10-15"><a href="#cb10-15" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb10-16"><a href="#cb10-16" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb10-17"><a href="#cb10-17" aria-hidden="true" tabindex="-1"></a><span class="fu">table</span>(treatment, outcome)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>         outcome
treatment   0   1
        A 241 265
        B 202 292</code></pre>
</div>
</div>
<p>We can estimate success rates and run a simple test:</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb12"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb12-1"><a href="#cb12-1" aria-hidden="true" tabindex="-1"></a>prop_A <span class="ot">&lt;-</span> <span class="fu">mean</span>(outcome[treatment <span class="sc">==</span> <span class="st">"A"</span>])</span>
<span id="cb12-2"><a href="#cb12-2" aria-hidden="true" tabindex="-1"></a>prop_B <span class="ot">&lt;-</span> <span class="fu">mean</span>(outcome[treatment <span class="sc">==</span> <span class="st">"B"</span>])</span>
<span id="cb12-3"><a href="#cb12-3" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb12-4"><a href="#cb12-4" aria-hidden="true" tabindex="-1"></a><span class="fu">c</span>(</span>
<span id="cb12-5"><a href="#cb12-5" aria-hidden="true" tabindex="-1"></a>  <span class="at">prop_A =</span> prop_A,</span>
<span id="cb12-6"><a href="#cb12-6" aria-hidden="true" tabindex="-1"></a>  <span class="at">prop_B =</span> prop_B,</span>
<span id="cb12-7"><a href="#cb12-7" aria-hidden="true" tabindex="-1"></a>  <span class="at">diff  =</span> prop_B <span class="sc">-</span> prop_A</span>
<span id="cb12-8"><a href="#cb12-8" aria-hidden="true" tabindex="-1"></a>)</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>   prop_A    prop_B      diff 
0.5237154 0.5910931 0.0673777 </code></pre>
</div>
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb14"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb14-1"><a href="#cb14-1" aria-hidden="true" tabindex="-1"></a><span class="co"># 2-sample proportion test (approximate)</span></span>
<span id="cb14-2"><a href="#cb14-2" aria-hidden="true" tabindex="-1"></a>tab <span class="ot">&lt;-</span> <span class="fu">table</span>(treatment, outcome)</span>
<span id="cb14-3"><a href="#cb14-3" aria-hidden="true" tabindex="-1"></a><span class="fu">prop.test</span>(<span class="at">x =</span> <span class="fu">c</span>(tab[<span class="st">"A"</span>, <span class="st">"1"</span>], tab[<span class="st">"B"</span>, <span class="st">"1"</span>]),</span>
<span id="cb14-4"><a href="#cb14-4" aria-hidden="true" tabindex="-1"></a>          <span class="at">n =</span> <span class="fu">c</span>(<span class="fu">sum</span>(treatment <span class="sc">==</span> <span class="st">"A"</span>), <span class="fu">sum</span>(treatment <span class="sc">==</span> <span class="st">"B"</span>)))</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output cell-output-stdout">
<pre><code>
    2-sample test for equality of proportions with continuity correction

data:  c(tab["A", "1"], tab["B", "1"]) out of c(sum(treatment == "A"), sum(treatment == "B"))
X-squared = 4.3299, df = 1, p-value = 0.03745
alternative hypothesis: two.sided
95 percent confidence interval:
 -0.13080449 -0.00395091
sample estimates:
   prop 1    prop 2 
0.5237154 0.5910931 </code></pre>
</div>
</div>
<p>The test tells us whether the difference is statistically significant at some alpha level.</p>
<hr>
</section>
<section id="pros-and-cons-of-ab-testing" class="level2">
<h2 class="anchored" data-anchor-id="pros-and-cons-of-ab-testing">4.3. Pros and cons of A/B testing</h2>
<p><strong>Pros</strong></p>
<ol type="1">
<li><p><strong>Simple and well-understood</strong><br>
Easy to explain, design, and analyze. Aligns with classical statistics and clinical trial paradigms.</p></li>
<li><p><strong>Unbiased estimation</strong><br>
Fixed randomization and no adaptation make standard estimators for treatment effects unbiased under usual assumptions.</p></li>
<li><p><strong>Regulatory familiarity</strong><br>
Regulators and ethics boards are very familiar with RCT-style A/B designs.</p></li>
<li><p><strong>Clear stopping rule</strong><br>
Pre-defined sample size and analysis plan simplify interpretation and avoid multiple-testing pitfalls (if adhered to).</p></li>
</ol>
<p><strong>Cons</strong></p>
<ol type="1">
<li><p><strong>No adaptation during the trial</strong><br>
Potentially many people receive suboptimal treatment while the trial continues.</p></li>
<li><p><strong>Inefficient for long-running online settings</strong><br>
In ongoing systems (e.g., continuous patient inflows), repeated static A/B tests may be suboptimal compared to more adaptive learning strategies.</p></li>
<li><p><strong>Does not naturally use covariates for decision-making</strong><br>
Although you can stratify and adjust, standard A/B tests don't adapt treatment by context during the experiment.</p></li>
<li><p><strong>Wasteful if one arm is clearly inferior early on</strong><br>
The design doesn't automatically reduce assignment to inferior arms as evidence accumulates.</p></li>
</ol>
<hr>
</section>
</section>
<section id="bandits-vs-ab-testing-who-does-what-better" class="level1">
<h1>5. Bandits vs A/B Testing: who does what better?</h1>
<p>Here's a high-level comparison:</p>
<ul>
<li><strong>Objective</strong>:
<ul>
<li>A/B testing: estimate treatment effects accurately and test hypotheses.</li>
<li>Bandits: maximize cumulative reward (or minimize regret) while learning.</li>
</ul></li>
<li><strong>Ethical stance</strong>:
<ul>
<li>A/B: fixed randomization, may treat many with inferior option.</li>
<li>Bandits: shift probability toward better arm(s) over time, potentially improving average outcomes.</li>
</ul></li>
<li><strong>Inference</strong>:
<ul>
<li>A/B: standard tools (t-tests, regression, etc.) apply directly.</li>
<li>Bandits: more complex; need specialized methods to get unbiased effect estimates.</li>
</ul></li>
<li><strong>Context</strong>:
<ul>
<li>A/B: typically not adaptive to context during the trial.</li>
<li>Contextual bandits: explicitly leverage covariates for personalization.</li>
</ul></li>
</ul>
<p>In HEOR and policy settings:</p>
<ul>
<li>A/B testing is still the default for <strong>formal evaluation</strong> and causal claims.</li>
<li>Bandits (especially contextual) are more attractive for <strong>ongoing operational decisions</strong> (e.g., which outreach message, which reminder, which low-risk intervention) where we care about performance during learning.</li>
</ul>
<hr>
</section>
<section id="why-these-methods-matter-for-heor-and-health-policy" class="level1">
<h1>6. Why these methods matter for HEOR and health policy</h1>
<section id="multi-armed-bandits" class="level2">
<h2 class="anchored" data-anchor-id="multi-armed-bandits">6.1. Multi-armed bandits</h2>
<p>Use cases:</p>
<ol type="1">
<li><p><strong>Adaptive outreach strategies</strong><br>
Choosing among multiple outreach methods (SMS, call, letter) to maximize screening uptake or adherence.</p></li>
<li><p><strong>Choosing among "good enough" options</strong><br>
When all options are acceptable and we want to learn which works best in practice (e.g., behavioral nudges).</p></li>
<li><p><strong>Resource allocation in pilots</strong><br>
Allocating limited resources among several interventions while learning which yields higher returns.</p></li>
</ol>
</section>
<section id="contextual-bandits" class="level2">
<h2 class="anchored" data-anchor-id="contextual-bandits">6.2. Contextual bandits</h2>
<p>Use cases:</p>
<ol type="1">
<li><p><strong>Personalized adherence interventions</strong><br>
Tailoring reminders or support intensity based on risk profile and past behavior.</p></li>
<li><p><strong>Targeted case management</strong><br>
Choosing which patients receive high-touch vs low-touch care management.</p></li>
<li><p><strong>Adaptive clinical decision support (within constraints)</strong><br>
Suggesting different options for low vs high-risk patients, updating over time as more data accumulate.</p></li>
</ol>
</section>
<section id="ab-testing" class="level2">
<h2 class="anchored" data-anchor-id="ab-testing">6.3. A/B testing</h2>
<p>Use cases:</p>
<ol type="1">
<li><p><strong>Formal evaluation of interventions</strong><br>
Classic RCT-style questions: "Does this policy or program improve outcomes compared to usual care?"</p></li>
<li><p><strong>Pricing, benefit design, or informational changes</strong><br>
Evaluating different copay levels, benefit designs, or communications in controlled pilots.</p></li>
<li><p><strong>Baseline evidence before scaling</strong><br>
Running a clean A/B test before adopting a new program system-wide.</p></li>
</ol>
<p>A realistic HEOR toolkit will include <strong>all three</strong>:</p>
<ul>
<li>A/B tests for clear causal evidence,</li>
<li>Multi-armed bandits for online optimization without context,</li>
<li>Contextual bandits for personalization when context matters.</li>
</ul>
<hr>
</section>
</section>
<section id="further-reading" class="level1">
<h1>7. Further reading</h1>
<ol type="1">
<li><p><strong>Lattimore &amp; Szepesvári - <em>Bandit Algorithms</em>.</strong><br>
Comprehensive, theory-heavy but excellent modern reference on multi-armed and contextual bandits.</p></li>
<li><p><strong>Scott - <em>A Modern Bayesian Look at the Multi-Armed Bandit</em>.</strong><br>
A shorter, accessible introduction to bandits with a Bayesian flavor.</p></li>
<li><p><strong>Dimakopoulou et al.&nbsp;- <em>Estimation Considerations in Contextual Bandits</em>.</strong><br>
Discusses how to estimate treatment effects and policies in contextual bandit settings.</p></li>
<li><p><strong>Kohavi et al.&nbsp;- <em>Online Controlled Experiments at Large Scale</em>.</strong><br>
Focuses on A/B testing in industry; useful for thinking about how experiments are run in complex systems and what bandit-like alternatives exist.</p></li>
</ol>
<p>Together, these give you enough intuition and code to start playing with bandits and A/B tests - and to think about how they might help answer HEOR and health policy questions in adaptive, data-driven ways. 😄</p>


<!-- -->

</section>
