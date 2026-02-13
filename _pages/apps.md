---
layout: single
title: "Didactic Apps"
permalink: /apps/
author_profile: true
---

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
