---
title: "Motivation and Introduction"
date: 2026-02-07
categories: [tutorials, codes]
tags: [Introduction]
summary: "This tutorial is my attempt to bring together the most relevant topics I've encountered during my professional experience in Health Economics and Outcomes Research (HEOR) and during my PhD training."
---
<section id="why-this-tutorial-exists-and-why-its-a-bit-of-a-frankenstein" class="level1">
<h1>Why this tutorial exists (and why it's a bit of a Frankenstein)</h1>
<p>Welcome!</p>
<p>This tutorial is my attempt to bring together the most relevant topics I've encountered during my professional experience in <strong>Health Economics and Outcomes Research (HEOR)</strong> and during my PhD training.</p>
<p>If you've ever felt like health economics requires you to be:</p>
<ul>
<li>a data scientist,</li>
<li>a statistician,</li>
<li>a causal inference nerd,</li>
<li>a decision scientist,</li>
<li>a simulation modeler,</li>
<li><em>and</em> a part-time policy wonk...</li>
</ul>
<p>...then you're exactly the kind of person this tutorial is for.</p>
<hr>
</section>
<section id="a-messy-set-of-topics-with-surprisingly-elegant-connections" class="level1">
<h1>A messy set of topics with surprisingly elegant connections</h1>
<p>At first glance, the topics covered here look pretty heterogeneous:</p>
<ul>
<li>Data science and machine learning<br>
</li>
<li>Causal inference and study design<br>
</li>
<li>Economic evaluation and decision analysis<br>
</li>
<li>Simulation models<br>
</li>
<li>Health policy applications<br>
</li>
<li>Statistical foundations</li>
</ul>
<p>They each come from different traditions, use different jargon, and often live in different courses, textbooks, and departments.</p>
<p>But in practice, <strong>these areas intersect a lot</strong>. Together, they form a network of methods that:</p>
<ul>
<li>Answer related questions from different angles,</li>
<li>Share common building blocks (probability, uncertainty, modeling),</li>
<li>Create <strong>bridges of knowledge</strong> that help us move from raw data → causal understanding → decisions → policy.</li>
</ul>
<p>A cost-effectiveness model might need:</p>
<ul>
<li>A <strong>causal effect</strong> from a regression or quasi-experimental design,<br>
</li>
<li>A <strong>risk model</strong> from machine learning,<br>
</li>
<li>A <strong>simulation engine</strong> to project long-term outcomes,<br>
</li>
<li>And a <strong>policy lens</strong> to interpret everything in context.</li>
</ul>
<p>This tutorial tries to live right at those intersections.</p>
<hr>
</section>
<section id="interdisciplinary-by-design" class="level1">
<h1>Interdisciplinary by design</h1>
<p>HEOR is inherently <strong>interdisciplinary</strong>, and this tutorial embraces that:</p>
<ul>
<li>You'll see methods from <strong>statistics</strong>, <strong>econometrics</strong>, <strong>epidemiology</strong>, <strong>computer science</strong>, and <strong>decision sciences</strong>.</li>
<li>The examples and motivation are grounded in <strong>health policy</strong> and <strong>healthcare decision making</strong>.</li>
<li>The goal is not to defend any one discipline, but to give a <strong>practical toolkit</strong> for answering real research questions that do <em>not</em> respect disciplinary boundaries.</li>
</ul>
<p>Think of this as a tour through the "methods neighborhood" where everyone borrows sugar from everyone else.</p>
<hr>
</section>
<section id="my-motivation-a-mix-of-self-defense-and-generosity" class="level1">
<h1>My motivation (a mix of self-defense and generosity)</h1>
<p>This tutorial serves two main purposes:</p>
<ol type="1">
<li><p><strong>Rehearsal for me</strong><br>
It's a structured way for me to review and rehearse the topics I've been learning in my PhD classes and during my work in HEOR. Writing things down forces clarity (and exposes the gaps!).</p></li>
<li><p><strong>A guide for others</strong><br>
It's also meant as a guide for people who want to learn more about the core methodologies a <strong>health economist</strong> should know to tackle the many research questions that arise from different root problems, such as:</p>
<ul>
<li>Evaluating new interventions or policies</li>
<li>Understanding real-world effectiveness and equity</li>
<li>Modeling long-term costs and outcomes</li>
<li>Translating evidence into decisions</li>
</ul></li>
</ol>
<p>If you're trying to figure out <em>"What methods should I know to function as a modern health economist?"</em> - this is for you.</p>
<hr>
</section>
<section id="what-this-tutorial-is-not" class="level1">
<h1>What this tutorial is <em>not</em></h1>
<p>This is <strong>not</strong> meant to be a textbook or a perfectly curated, linear course.</p>
<p>Instead:</p>
<ul>
<li>Think of it as a <strong>toolkit</strong> or <strong>methods catalog</strong>.</li>
<li>Each tutorial is somewhat self-contained.</li>
<li>You can jump around depending on the question you're trying to answer:
<ul>
<li>Need to remember how DiD works? Jump to that tutorial.</li>
<li>Need a refresher on Markov models? There's a chapter for that.</li>
<li>Need to recall how to interpret a logistic regression coefficient? There's something for that too.</li>
</ul></li>
</ul>
<p>Whenever possible, I'll point to <strong>further readings and lectures</strong> for people who want to go deeper than these notes.</p>
<hr>
</section>
<section id="about-the-order-spoiler-its-not-perfect" class="level1">
<h1>About the order (spoiler: it's not perfect)</h1>
<p>You'll probably notice that the order of topics is... let's say, <strong>imperfectly optimized</strong></p>
<p>And that's okay.</p>
<p>Real-life research questions rarely appear in a neat sequence. Sometimes you need simulation before you fully understand all the causal inference details. Sometimes you need policy context before deciding which model to build.</p>
<p>So:</p>
<ul>
<li>Don't worry if the order feels weird.</li>
<li>Treat this as a <strong>modular toolkit</strong>, not a 1-to-10 linear course.</li>
<li>Use the sidebar as a menu: take what you need, when you need it.</li>
</ul>
<hr>
</section>
<section id="for-people-who-know-a-bit-of-everything-but-are-experts-in-nothing" class="level1">
<h1>For people who "know a bit of everything but are experts in nothing"</h1>
<p>Finally, this tutorial is also a bit of a love letter to people (like me) who often feel like:</p>
<blockquote class="blockquote">
<p>"I know <em>something</em> about almost everything... but I'm not a world expert in any of it."</p>
</blockquote>
<p>That's okay. In HEOR and health policy, being a <strong>connector of ideas and methods</strong> is itself a superpower.</p>
<p>So let's treat this tutorial as:</p>
<ul>
<li>A place to <strong>consolidate</strong> what we know,</li>
<li>A gentle reminder of things we've seen before but might have forgotten,</li>
<li>And a launching pad for diving deeper when a particular method becomes central to the question we're working on.</li>
</ul>
<p>If this helps you feel a little less lost in the methods forest - and a little more confident stitching ideas together - then it's doing its job.</p>
<p>Welcome to my toolkit.</p>


<!-- -->

</section>
