---
layout: single
title: "How to Update This Site"
permalink: /update/
author_profile: true
---

This guide explains how to update publications, talks, teaching, tutorials, and the CV.

## Publications

Location: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/_publications/`

Each publication is one Markdown file. Use this template:

```yaml
---
title: "Your paper title"
collection: publications
category: journal   # or preprint
permalink: /publication/2026-01-15-your-paper-slug
excerpt: "Plain-language summary for the publications page."
date: 2026-01-15
venue: "Journal Name"
paperurl: "https://doi.org/..."
citation: "Authors (2026). Title. <i>Journal</i>. Volume(Issue):pages."
---
Plain-language summary for the publication detail page.
```

Notes:
- Use `category: journal` or `category: preprint` so it appears under the correct heading.
- The `excerpt` is what shows on the Publications list. Keep it simple and public-facing.

## Talks

Location: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/_talks/`

Template:

```yaml
---
title: "Talk title"
collection: talks
type: "Conference presentation"
permalink: /talks/2026-03-01-talk-title
venue: "Conference name"
date: 2026-03-01
location: "City, Country"
excerpt: "Short public-facing summary shown in the Talks list page."
slidesurl: "/files/talks/2026-03-01-talk-title.pdf"
---
Optional short note (award, invited, etc).

**Brief summary**: 1-2 sentence summary in plain language.

## Abstract

Paste the talk abstract text here.
```

Talk PDFs:
- Store talk/poster PDFs in `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/files/talks/`
- Use a stable filename that matches the talk page slug when possible.
- `slidesurl` links to the PDF and is shown on the Talks page.

Abstracts and descriptions:
- If you have a Word abstract, paste the abstract text into the talk page body under `## Abstract`.
- If you do not have a Word abstract, use the poster PDF/title information to write a short description.
- Keep `excerpt` short and public-facing. The full abstract goes in the page body.

## Teaching

Location: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/_teaching/`

Template:

```yaml
---
title: "Role or course title"
collection: teaching
type: "Teaching assistant"   # or Workshop, Committee service, etc.
permalink: /teaching/2026-01-01-role-title
venue: "Institution"
date: 2026-01-01
location: "City, Country"
---
Optional short note.
```

## Tutorials & Codes

Location:
- Posts: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/_posts/`
- Quarto source files: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/tutorials/`

Tutorials are stored as Jekyll posts, but each post is rebuilt from the Quarto `.qmd` source files stored in `tutorials/`.

### Recommended workflow

1. Update or replace the Quarto `.qmd` files inside:
   `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/tutorials/`
2. Rebuild the tutorial posts from the Quarto source:
   ```bash
   python3 /Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/scripts/rebuild_tutorial_posts.py
   ```

This will:
- Delete the current tutorial posts in `_posts/`
- Create one new post per Quarto source file in `tutorials/*/*.qmd`
- Skip `index.qmd` files when creating tutorial posts
- Execute the code chunks so figures and tables are included in the generated pages
- Copy generated figures into `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/tutorials/rendered-assets/`
- Update the `/tutorials/` intro from `tutorials/simulation-tools/index.qmd`

### Front matter (generated automatically)

```yaml
---
title: "Tutorial title"
date: 2026-02-15
categories: [tutorials, codes]
tags: ["Simulation Tools"]   # derived from the tutorial folder name
summary: "Short plain-language summary used in the Tutorials list."
excerpt: "Optional subtitle from the .qmd front matter"
---
```

Tips:
- The Tutorials page filters by `tags`, and the script currently derives them from the folder name (for example `simulation-tools` becomes `Simulation Tools`).
- If you rename a tutorial group folder, rerun the rebuild script so the new tag appears on `/tutorials/`.
- The `/tutorials/` landing page intro is generated from `tutorials/simulation-tools/index.qmd`.
- If a tutorial generates plots, keep the source code inside executable chunks so the rebuild script can regenerate the images automatically.

## Software Development

Apps are stored in two places:

- App pages: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/_apps/`
- App code: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/apps/`

To add a new app:

1. Copy your Shiny app folder into `apps/<app-name>/` (include `app.R`).
2. Create a page in `_apps/` with front matter like:

```yaml
---
title: "App title"
collection: apps
permalink: /apps/app-name/
subtitle: "Short subtitle"
description: "One or two sentences about what the app does."
app_url: "https://your-deployed-app-url"
---
```

3. In the app page, add:
- A short description
- Instructions for use
- Local run instructions
- A code section (copy `app.R` into a fenced code block)

The app will appear automatically in the "Software Development" tab under Educational Apps.

Published software-related work is listed directly in:
`/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/_pages/apps.md`

To add a new published software item, add another card under the "Published Work" section with:
- Title
- Short description
- Link to the publication or package page
- Link to the repository or project website

## CV Page

Location: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/_pages/cv.md`

Update these sections directly:
- Education
- Professional Experience
- Skills
- Awards

Publications, Talks, and Teaching on the CV are generated from their folders above, so keep those updated.

Downloadable PDF CV:
- Generated source file: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/files/cv/carlos-pineda-academic-cv.md`
- PDF file: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/files/cv/carlos-pineda-academic-cv.pdf`
- Generator script: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/scripts/rebuild_cv_pdf.py`

The PDF CV is generated from:
- Static CV sections in `_pages/cv.md`
- Publications in `_publications/`
- Talks in `_talks/`
- Teaching activities in `_teaching/`

After updating the site locally, rebuild the PDF CV with:

```bash
python3 /Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/scripts/rebuild_cv_pdf.py
```

On GitHub, the "Rebuild PDF CV" workflow automatically regenerates and commits the PDF after pushes that change `_pages/cv.md`, `_publications/`, `_talks/`, `_teaching/`, or the generator script.

## Profile Sidebar (Contact + Bio)

Location: `/Users/carlospineda/Documents/GitHub/CarlosPiant.github.io/_config.yml`

Update fields under `author:` such as:
- `bio`
- `email`
- `googlescholar`
- `orcid`
- `pubmed`
- `github`
- `linkedin`

## Publish Updates

1. Save the changes.
2. Commit and push to GitHub.
3. Wait 1-5 minutes for GitHub Pages to rebuild.

If you want, I can also add a shortcut to this page in the navigation.
