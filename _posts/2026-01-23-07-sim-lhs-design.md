---
title: "Latin Hypercube Sampling (LHS) for Calibration and Emulators"
date: 2026-01-23
categories: [tutorials, codes]
tags: [Simulation Models]
summary: "When we say "let's explore the parameter space," we often start with:"
---
<section id="introduction-when-random-needs-to-be-a-bit-smarter" class="level1">
<h1>1. Introduction: when "random" needs to be a bit smarter</h1>
<p>When we say "let's explore the parameter space," we often start with:</p>
<blockquote class="blockquote">
<p>"I'll just draw some random values from each parameter range and see what happens."</p>
</blockquote>
<p>That's <strong>simple random sampling</strong>. It's easy, but:</p>
<ul>
<li>You can end up with <strong>clusters</strong> in some regions and <strong>holes</strong> in others.</li>
<li>In higher dimensions, huge parts of the parameter space may never get touched.</li>
<li>Your expensive model runs get "wasted" exploring the same area over and over.</li>
</ul>
<p>Enter <strong>Latin Hypercube Sampling (LHS)</strong>:<br>
random, <em>but with manners</em>.</p>
<p>LHS is a way to:</p>
<ul>
<li>Spread parameter samples <strong>evenly</strong> across each dimension,</li>
<li>Avoid wasting simulations in duplicate regions,</li>
<li>Get better coverage of the space with <strong>fewer</strong> model runs.</li>
</ul>
<p>In this tutorial, we'll:</p>
<ul>
<li>Describe what an LHS design is (intuitively and conceptually),</li>
<li>See how it's used in <strong>model calibration</strong>,</li>
<li>See how it's used to build <strong>emulators</strong> (surrogate models),</li>
<li>Wrap up with why this matters for HEOR and health policy modeling,</li>
<li>And give some references if you want to go full LHS nerd. 😄</li>
</ul>
<hr>
</section>
<section id="what-is-a-latin-hypercube-sampling-lhs-design" class="level1">
<h1>2. What is a Latin Hypercube Sampling (LHS) design?</h1>
<section id="the-basic-idea" class="level2">
<h2 class="anchored" data-anchor-id="the-basic-idea">2.1. The basic idea</h2>
<p>Imagine you have one parameter, say a probability that can vary from 0 to 1.</p>
<ul>
<li>If you take 10 random samples, they might all end up between 0.2 and 0.5.</li>
<li>With LHS, you <strong>force</strong> the samples to spread out.</li>
</ul>
<p>In 1D, LHS:</p>
<ol type="1">
<li>Divides the range (e.g., 0 to 1) into <span class="math inline">\(N\)</span> equal <strong>intervals</strong>.</li>
<li>In each interval, it selects <strong>one</strong> value at random.</li>
<li>This gives you <span class="math inline">\(N\)</span> samples, each in a different interval.</li>
</ol>
<p>Result: you don't get 10 samples all in the same tiny region; you get coverage across the whole range.</p>
<p>In higher dimensions (multiple parameters), LHS generalizes this idea.</p>
<p>To be more concrete, let's show how it works with a graphical example.</p>
<div class="cell">
<details class="code-fold">
<summary>Code</summary>
<div class="sourceCode cell-code" id="cb1"><pre class="sourceCode r code-with-copy"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="fu">library</span>(ggplot2)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a><span class="fu">source</span>(<span class="st">"R/theme-heor-book.R"</span>) </span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a><span class="fu">theme_set</span>(<span class="fu">theme_heor_book</span>())</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a><span class="fu">set.seed</span>(<span class="dv">123</span>)</span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>n_samples <span class="ot">&lt;-</span> <span class="dv">100</span></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a><span class="co"># Random sampling</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>random_samples <span class="ot">&lt;-</span> <span class="fu">runif</span>(n_samples, <span class="at">min =</span> <span class="dv">0</span>, <span class="at">max =</span> <span class="dv">1</span>)</span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a><span class="co"># LHS sampling</span></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>lhs_intervals <span class="ot">&lt;-</span> <span class="fu">seq</span>(<span class="dv">0</span>, <span class="dv">1</span>, <span class="at">length.out =</span> n_samples <span class="sc">+</span> <span class="dv">1</span>)</span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>lhs_samples <span class="ot">&lt;-</span> lhs_intervals[<span class="sc">-</span>(n_samples <span class="sc">+</span> <span class="dv">1</span>)] <span class="sc">+</span></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  <span class="fu">runif</span>(n_samples, <span class="at">min =</span> <span class="dv">0</span>, <span class="at">max =</span> <span class="dv">1</span> <span class="sc">/</span> n_samples)</span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>df_lhs <span class="ot">&lt;-</span> <span class="fu">data.frame</span>(</span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  <span class="at">Sample =</span> <span class="fu">c</span>(random_samples, lhs_samples),</span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  <span class="at">Method =</span> <span class="fu">rep</span>(<span class="fu">c</span>(<span class="st">"Random"</span>, <span class="st">"LHS"</span>), <span class="at">each =</span> n_samples)</span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a><span class="fu">ggplot</span>(df_lhs, <span class="fu">aes</span>(<span class="at">x =</span> Sample, <span class="at">y =</span> Method)) <span class="sc">+</span></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  <span class="fu">geom_point</span>(<span class="at">size =</span> <span class="dv">2</span>, <span class="at">alpha =</span> <span class="fl">0.6</span>) <span class="sc">+</span></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>  <span class="fu">labs</span>(</span>
<span id="cb1-20"><a href="#cb1-20" aria-hidden="true" tabindex="-1"></a>    <span class="at">title =</span> <span class="st">"Comparison of Random Sampling vs Latin Hypercube Sampling (LHS)"</span>,</span>
<span id="cb1-21"><a href="#cb1-21" aria-hidden="true" tabindex="-1"></a>    <span class="at">x =</span> <span class="st">"Parameter Value"</span>,</span>
<span id="cb1-22"><a href="#cb1-22" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> <span class="st">"Sampling Method"</span></span>
<span id="cb1-23"><a href="#cb1-23" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">+</span></span>
<span id="cb1-24"><a href="#cb1-24" aria-hidden="true" tabindex="-1"></a>  <span class="fu">theme_heor_book</span>()</span></code><button title="Copy to Clipboard" class="code-copy-button"><i class="bi"></i></button></pre></div>
</details>
<div class="cell-output-display">
<div>
<figure class="figure">
<p><img src="/tutorials/07-sim-lhs-design_files/figure-html/lhs-1d-1.png" class="img-fluid figure-img" width="768"></p>
</figure>
</div>
</div>
</div>
</section>
<section id="multiple-dimensions-the-latin-part" class="level2">
<h2 class="anchored" data-anchor-id="multiple-dimensions-the-latin-part">2.2. Multiple dimensions: the "Latin" part</h2>
<p>Suppose you have 3 parameters:</p>
<ul>
<li><span class="math inline">\(\theta_1\)</span>: transition probability,</li>
<li><span class="math inline">\(\theta_2\)</span>: hazard ratio,</li>
<li><span class="math inline">\(\theta_3\)</span>: cost multiplier.</li>
</ul>
<p>You want <span class="math inline">\(N\)</span> parameter sets (e.g., <span class="math inline">\(N = 1000\)</span>).</p>
<p>For each parameter:</p>
<ol type="1">
<li>Divide its range (or distribution) into <span class="math inline">\(N\)</span> intervals of equal probability.</li>
<li>Sample <strong>one value</strong> from each interval.</li>
</ol>
<p>Then:</p>
<ul>
<li>For <span class="math inline">\(\theta_1\)</span>, you get 1000 values, each from a different interval.</li>
<li>For <span class="math inline">\(\theta_2\)</span>, you also get 1000 values, one per interval.</li>
<li>Same for <span class="math inline">\(\theta_3\)</span>.</li>
</ul>
<p>Now you need to <strong>pair</strong> these values across parameters so that:</p>
<ul>
<li>Each of the 1000 parameter sets uses <strong>one</strong> value from each parameter's list.</li>
<li>No interval is used twice <strong>in the same dimension</strong>.</li>
</ul>
<p>This pairing is done in a way that each dimension is "filled" with one sample from each interval - like a <strong>Latin square</strong> generalization to multiple dimensions. That's why it's called <strong>Latin Hypercube</strong>.</p>
</section>
<section id="why-not-just-simple-random-sampling" class="level2">
<h2 class="anchored" data-anchor-id="why-not-just-simple-random-sampling">2.3. Why not just simple random sampling?</h2>
<p>With the same number of model runs, LHS tends to:</p>
<ul>
<li>Cover the space <strong>more uniformly</strong>,</li>
<li>Reduce the chance of "holes",</li>
<li>Give better <strong>space-filling</strong> designs.</li>
</ul>
<p>This is especially important when:</p>
<ul>
<li>Each model run is <strong>expensive</strong> (e.g., microsimulation, DES),</li>
<li>You want to explore <strong>wide parameter ranges</strong>,</li>
<li>You're building <strong>emulators</strong> based on a limited number of runs.</li>
</ul>
<hr>
</section>
</section>
<section id="how-do-we-construct-an-lhs-design-conceptually" class="level1">
<h1>3. How do we construct an LHS design? (conceptually)</h1>
<p>You don't need the exact algorithmic details to use LHS in practice (software does the heavy lifting), but conceptually:</p>
<ol type="1">
<li><strong>Decide how many samples</strong> <span class="math inline">\(N\)</span> you want.
<ul>
<li>Example: 1000 parameter sets.</li>
</ul></li>
<li>For each parameter:
<ul>
<li>Define its range or distribution.</li>
<li>Divide into <span class="math inline">\(N\)</span> strata of equal probability (quantiles).</li>
<li>Sample one value from each stratum.</li>
</ul></li>
<li>For all parameters together:
<ul>
<li>Randomly permute the order of the sampled values within each parameter.</li>
<li>Combine the permuted lists so that each row corresponds to one "Latin Hypercube" design point (one parameter set).</li>
</ul></li>
</ol>
<p>The result is an <span class="math inline">\(N \times K\)</span> matrix (for <span class="math inline">\(K\)</span> parameters) where:</p>
<ul>
<li>Each column (parameter) has good coverage of its range,</li>
<li>The combinations are randomized enough to avoid rigid patterns,</li>
<li>The design is more space-filling than simple random draws.</li>
</ul>
<p>In R, for example, packages like <code>lhs</code> can generate LHS designs directly.<br>
But the important part here is the <strong>idea</strong>: controlled randomness that spreads samples out.</p>
<hr>
</section>
<section id="lhs-in-model-calibration" class="level1">
<h1>4. LHS in model calibration</h1>
<section id="calibration-matching-the-model-to-reality" class="level2">
<h2 class="anchored" data-anchor-id="calibration-matching-the-model-to-reality">4.1. Calibration: matching the model to reality</h2>
<p>In many HEOR and decision models (e.g., cancer screening, chronic disease progression), we don't know some parameters precisely:</p>
<ul>
<li>Transition probabilities between states,</li>
<li>Incidence or progression rates,</li>
<li>Relative risks,</li>
<li>Adherence or implementation parameters.</li>
</ul>
<p>We often have:</p>
<ul>
<li><strong>Priors or plausible ranges</strong> for parameters, and</li>
<li><strong>Calibration targets</strong>: observed data (e.g., incidence, prevalence, mortality) the model should reproduce.</li>
</ul>
<p>Calibration is the process of finding parameter sets that make the model's outputs line up with these targets.</p>
</section>
<section id="why-lhs-is-useful-for-calibration" class="level2">
<h2 class="anchored" data-anchor-id="why-lhs-is-useful-for-calibration">4.2. Why LHS is useful for calibration</h2>
<p>To calibrate, we typically:</p>
<ol type="1">
<li>Generate a large set of candidate parameter vectors.</li>
<li>Run the model for each vector.</li>
<li>Compare model outputs to calibration targets using some <strong>goodness-of-fit</strong> criterion.</li>
<li>Keep, weight, or optimize toward the "best" parameter sets.</li>
</ol>
<p>LHS helps at <strong>step 1</strong>:</p>
<ul>
<li>Instead of naive random draws, we use LHS to <strong>efficiently explore</strong> the parameter space.</li>
<li>This reduces the risk that we miss regions where the model fits well.</li>
<li>For the same number of model runs, we get <strong>more informative coverage</strong>.</li>
</ul>
<p>Typical workflow:</p>
<ul>
<li>Choose ranges or distributions for each parameter (based on literature/expert opinion).</li>
<li>Use LHS to sample, say, 1000-10,000 parameter sets.</li>
<li>Simulate the model at each set.</li>
<li>Compute a fit metric (e.g., sum of squared differences, likelihood).</li>
<li>Use these to:
<ul>
<li>Select the best-fitting sets,</li>
<li>Or feed into a more formal approximate Bayesian calibration.</li>
</ul></li>
</ul>
<p>In short: LHS turns your calibration search into a <strong>structured exploration</strong> rather than a random wander.</p>
<hr>
</section>
</section>
<section id="lhs-for-emulator-surrogate-design" class="level1">
<h1>5. LHS for emulator (surrogate) design</h1>
<section id="why-emulators" class="level2">
<h2 class="anchored" data-anchor-id="why-emulators">5.1. Why emulators?</h2>
<p>Many HEOR models are:</p>
<ul>
<li><strong>Computationally expensive</strong> to run (e.g., complex microsimulations),</li>
<li>Used for <strong>PSA, VOI, calibration</strong>, or <strong>scenario analysis</strong> that may need thousands or millions of evaluations.</li>
</ul>
<p>Running the full model that many times can be <strong>impractical</strong>.</p>
<p>Enter <strong>emulators</strong> (or surrogate models):</p>
<ul>
<li>Statistical or machine learning models (e.g., Gaussian processes, random forests, neural nets),</li>
<li>Trained to approximate the outputs of the original model,</li>
<li>Much faster to evaluate once trained.</li>
</ul>
</section>
<section id="lhs-as-a-design-for-training-emulators" class="level2">
<h2 class="anchored" data-anchor-id="lhs-as-a-design-for-training-emulators">5.2. LHS as a design for training emulators</h2>
<p>To build an emulator:</p>
<ol type="1">
<li>Choose inputs (parameters, maybe some scenario variables).</li>
<li>Evaluate the original model at a set of carefully chosen input points.</li>
<li>Fit the emulator to these input-output pairs.</li>
<li>Use the emulator as a stand-in for the original model where speed is needed.</li>
</ol>
<p>LHS is a natural choice for step 2:</p>
<ul>
<li>You generate an LHS design over the input space (the parameters you want the emulator to learn).</li>
<li>Run the costly model at each LHS point.</li>
<li>The resulting dataset is a <strong>space-filling training set</strong> for the emulator.</li>
</ul>
<p>Benefits:</p>
<ul>
<li>The emulator "sees" diverse combinations of inputs and learns how the outputs change across the space.</li>
<li>LHS avoids wasting many training points in overlapping regions.</li>
<li>For a fixed number of model runs, you generally get better emulator accuracy than with naive random sampling.</li>
</ul>
</section>
<section id="using-lhs-based-emulators-in-practice" class="level2">
<h2 class="anchored" data-anchor-id="using-lhs-based-emulators-in-practice">5.3. Using LHS-based emulators in practice</h2>
<p>Once you have an emulator trained on an LHS design:</p>
<ul>
<li>You can perform <strong>PSA</strong> or <strong>VOI</strong> analyses using the emulator instead of the original model, dramatically cutting computation time.</li>
<li>You can embed the emulator inside calibration algorithms (e.g., MCMC) where repeated evaluations are needed.</li>
<li>You can explore sensitivity and scenario analyses interactively.</li>
</ul>
<p>In other words, LHS is a quiet, behind-the-scenes hero of efficient emulator design.</p>
<hr>
</section>
</section>
<section id="why-lhs-matters-in-heor-and-health-policy-modeling" class="level1">
<h1>6. Why LHS matters in HEOR and health policy modeling</h1>
<section id="efficient-use-of-expensive-simulations" class="level2">
<h2 class="anchored" data-anchor-id="efficient-use-of-expensive-simulations">6.1. Efficient use of expensive simulations</h2>
<p>Complex decision-analytic and simulation models are not cheap to run:</p>
<ul>
<li>They may simulate large virtual cohorts,</li>
<li>Track detailed histories,</li>
<li>Include stochastic elements.</li>
</ul>
<p>LHS helps you:</p>
<ul>
<li>Get more information per simulation run,</li>
<li>Avoid redundant sampling,</li>
<li>Make calibration and uncertainty analysis <strong>feasible</strong> under time and computing constraints.</li>
</ul>
</section>
<section id="better-exploration-fewer-blind-spots" class="level2">
<h2 class="anchored" data-anchor-id="better-exploration-fewer-blind-spots">6.2. Better exploration, fewer blind spots</h2>
<p>Policy-relevant questions often depend on:</p>
<ul>
<li>Extreme but plausible parameter combinations,</li>
<li>Interactions between parameters,</li>
<li>Tail behavior of outcomes (e.g., catastrophic costs, rare events).</li>
</ul>
<p>LHS improves coverage of these combinations, making it less likely that:</p>
<ul>
<li>A "good" region of parameter space is never sampled,</li>
<li>Your conclusions rely on a poorly explored neighborhood of parameters.</li>
</ul>
</section>
<section id="foundation-for-modern-workflows-calibration-emulators" class="level2">
<h2 class="anchored" data-anchor-id="foundation-for-modern-workflows-calibration-emulators">6.3. Foundation for modern workflows (calibration + emulators)</h2>
<p>Many modern HEOR workflows implicitly rely on:</p>
<ul>
<li>Calibration based on large parameter sets,</li>
<li>Emulator-based PSA and VOI,</li>
<li>Sequential or adaptive designs that start from an initial LHS design.</li>
</ul>
<p>Understanding LHS helps you:</p>
<ul>
<li>Design better calibration studies,</li>
<li>Build more reliable emulators,</li>
<li>Communicate why your set of simulations is "enough" (or not) to stakeholders.</li>
</ul>
<hr>
</section>
</section>
<section id="references-and-further-reading" class="level1">
<h1>7. References and further reading</h1>
<p>Some foundational and practical references on Latin Hypercube Sampling, calibration, and emulators:</p>
<ol type="1">
<li><p><strong>McKay, Beckman, and Conover (1979).</strong><br>
<em>A Comparison of Three Methods for Selecting Values of Input Variables in the Analysis of Output from a Computer Code.</em><br>
Technometrics 21(2): 239-245.<br>
Classic paper introducing Latin Hypercube Sampling.</p></li>
<li><p><strong>Helton and Davis (2003).</strong><br>
<em>Latin Hypercube Sampling and the Propagation of Uncertainty in Analyses of Complex Systems.</em><br>
Reliability Engineering &amp; System Safety 81(1): 23-69.<br>
Detailed discussion of LHS and uncertainty analysis in complex models.</p></li>
<li><p><strong>Santner, Williams, and Notz (2003).</strong><br>
<em>The Design and Analysis of Computer Experiments.</em><br>
Springer.<br>
Comprehensive reference on experimental design for computer models, including LHS and emulators.</p></li>
<li><p><strong>Kennedy and O'Hagan (2001).</strong><br>
<em>Bayesian Calibration of Computer Models.</em><br>
Journal of the Royal Statistical Society, Series B 63(3): 425-464.<br>
Seminal paper on calibration and emulators in the Bayesian framework.</p></li>
</ol>
<p>These will take you from "I know LHS is a smart way to sample" to "I can confidently design calibration and emulator studies like a grown-up." 😄</p>


<!-- -->

</section>
