---
title: "Motivation and Introduction"
date: 2026-02-07
categories: [tutorials, codes]
tags: [Introduction]
summary: "This tutorial is my attempt to bring together the most relevant topics I've encountered during my professional experience in Health Economics and Outcomes Research (HEOR) and during my PhD training."
---

# Why this tutorial exists (and why it's a bit of a Frankenstein)

Welcome! 

This tutorial is my attempt to bring together the most relevant topics I've
encountered during my professional experience in **Health Economics and Outcomes
Research (HEOR)** and during my PhD training.

If you've ever felt like health economics requires you to be:

- a data scientist,
- a statistician,
- a causal inference nerd,
- a decision scientist,
- a simulation modeler,
- *and* a part-time policy wonk...

...then you're exactly the kind of person this tutorial is for.

---

# A messy set of topics with surprisingly elegant connections

At first glance, the topics covered here look pretty heterogeneous:

- Data science and machine learning  
- Causal inference and study design  
- Economic evaluation and decision analysis  
- Simulation models  
- Health policy applications  
- Statistical foundations  

They each come from different traditions, use different jargon, and often live in
different courses, textbooks, and departments.

But in practice, **these areas intersect a lot**. Together, they form a network
of methods that:

- Answer related questions from different angles,
- Share common building blocks (probability, uncertainty, modeling),
- Create **bridges of knowledge** that help us move from raw data → causal
  understanding → decisions → policy.

A cost-effectiveness model might need:

- A **causal effect** from a regression or quasi-experimental design,  
- A **risk model** from machine learning,  
- A **simulation engine** to project long-term outcomes,  
- And a **policy lens** to interpret everything in context.

This tutorial tries to live right at those intersections.

---

# Interdisciplinary by design

HEOR is inherently **interdisciplinary**, and this tutorial embraces that:

- You'll see methods from **statistics**, **econometrics**, **epidemiology**,
  **computer science**, and **decision sciences**.
- The examples and motivation are grounded in **health policy** and
  **healthcare decision making**.
- The goal is not to defend any one discipline, but to give a **practical
  toolkit** for answering real research questions that do *not* respect
  disciplinary boundaries.

Think of this as a tour through the "methods neighborhood" where everyone borrows
sugar from everyone else.

---

# My motivation (a mix of self-defense and generosity)

This tutorial serves two main purposes:

1. **Rehearsal for me**  
   It's a structured way for me to review and rehearse the topics I've been
   learning in my PhD classes and during my work in HEOR. Writing things down
   forces clarity (and exposes the gaps!).

2. **A guide for others**  
   It's also meant as a guide for people who want to learn more about the core
   methodologies a **health economist** should know to tackle the many research
   questions that arise from different root problems, such as:
   - Evaluating new interventions or policies
   - Understanding real-world effectiveness and equity
   - Modeling long-term costs and outcomes
   - Translating evidence into decisions

If you're trying to figure out *"What methods should I know to work as a
modern health economist?"* - perhaps, this tutorials collection will show you 
the landscape and give you a starting point for diving deeper into specific topics.

---

# What this tutorial is *not*

This is **not** meant to be a textbook or a perfectly curated, linear course.

Instead:

- Think of it as a **toolkit** or **methods catalog**.
- Each tutorial is somewhat self-contained.
- You can jump around depending on the question you're trying to answer:
  - Need to remember how DiD works? Jump to that tutorial.
  - Need a refresher on Markov models? There's a chapter for that.
  - Need to recall how to interpret a logistic regression coefficient? There's
    something for that too.
  - Need a simple code or graph example for a class presentation? You might find one here.

Whenever possible, I'll point to **further readings and lectures** for people
who want to go deeper than these notes.

---

# About the order (spoiler: it's not perfect)

You'll probably notice that the order of topics is... let's say, **imperfectly
optimized** 

And that's okay.

Real-life research questions rarely appear in a neat sequence. Sometimes you
need simulation before you fully understand all the causal inference details.
Sometimes you need policy context before deciding which model to build.

So:

- Don't worry if the order feels weird.
- Treat this as a **modular toolkit**, not a 1-to-10 linear course.
- Use the sidebar as a menu: take what you need, when you need it.

---

# For people who "know a bit of everything but are experts in nothing"

Finally, this tutorial is also a bit of a love letter to people (like me) who
often feel like:

> "I know *something* about almost everything... but I'm not a world expert in any
> of it."

That's okay. In HEOR and health policy, being a **connector of ideas and
methods** is itself a superpower. In my experience working with amazing teams from different
institutions and Universities, I realized that we don't need to be a world-class statistician 
or a machine learning guru to make a huge impact, that comes from the team work. 
You just need to know enough to:

- Understand the tools available,
- Recognize when they're useful,
- And stitch them together in creative ways to answer important questions.

So let's treat this tutorial as:

- A place to **consolidate** what we know,
- A gentle reminder of things we've seen before but might have forgotten,
- And a launching pad for diving deeper when a particular method becomes
  central to the question we're working on.

If this helps you feel a little less lost in the methods forest - and a little
more confident stitching ideas together - then it's doing its job.
