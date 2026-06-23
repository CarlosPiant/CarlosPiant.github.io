---
layout: single
title: "Software Development"
permalink: /apps/
author_profile: true
---

This section brings together software, reproducible tools, and educational applications connected to my work in health economics, outcomes research, simulation modeling, and data visualization.

## Published Work

<div class="app-grid software-work-grid">
  <div class="app-card software-work-card">
    <h2 class="app-title">Cancer modeling with discrete-event simulation</h2>
    <div class="app-subtitle">Tutorial and open-source modeling workflow</div>
    <p class="app-description">This work presents a practical tutorial for cancer modeling using discrete-event simulation. It is connected to the DESCIPHR framework, an open-source pipeline designed to support transparent and reproducible simulation models for cancer interventions and population health.</p>
    <div class="software-links">
      <a class="app-link" href="https://link.springer.com/article/10.1007/s40273-025-01571-3">Published article</a>
      <a class="app-link" href="https://github.com/sjpi22/tutorial_cancer_modeling_des">GitHub repository</a>
    </div>
  </div>

  <div class="app-card software-work-card">
    <h2 class="app-title">BayCANN for the CISNET colorectal cancer models</h2>
    <div class="app-subtitle">Code for emulator-based Bayesian calibration</div>
    <p class="app-description">This repository provides code to perform BayCANN for the three Colorectal Cancer CISNET models. The work supports emulator-based Bayesian calibration, helping researchers calibrate complex cancer simulation models more efficiently while preserving transparent and reproducible workflows.</p>
    <div class="software-links">
      <a class="app-link" href="https://journals.sagepub.com/doi/10.1177/0272989X241255618">Published article</a>
      <a class="app-link" href="https://github.com/NCI-CISNET-Colorectal/baycann_cisnet_crc">GitHub repository</a>
    </div>
  </div>

  <div class="app-card software-work-card">
    <h2 class="app-title">ggpop</h2>
    <div class="app-subtitle">R package for icon-based population charts</div>
    <p class="app-description">ggpop is an R package built on top of ggplot2 that simplifies the creation of icon-based population charts. It helps users communicate population proportions and group comparisons with intuitive visual displays while staying within the familiar ggplot2 grammar.</p>
    <div class="software-links">
      <a class="app-link" href="https://cran.r-project.org/web/packages/ggpop/index.html">CRAN publication</a>
      <a class="app-link" href="https://jurjoroa.github.io/ggpop/">Project website</a>
    </div>
  </div>
</div>

## Educational Apps

These interactive Shiny apps are designed to make complex concepts easier to explore. Each app includes a short description, instructions, and the full source code so you can learn by doing.

{% if site.apps %}
<div class="app-grid">
  {% assign apps_sorted = site.apps | sort: "title" %}
  {% for app in apps_sorted %}
    <div class="app-card">
      <h2 class="app-title"><a href="{{ app.url }}">{{ app.title }}</a></h2>
      {% if app.subtitle %}<div class="app-subtitle">{{ app.subtitle }}</div>{% endif %}
      {% if app.description %}<p class="app-description">{{ app.description }}</p>{% endif %}
      <a class="app-link" href="{{ app.url }}">Open app page</a>
    </div>
  {% endfor %}
</div>
{% else %}
<p>No apps have been added yet.</p>
{% endif %}
