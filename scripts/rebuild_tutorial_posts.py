#!/usr/bin/env python3
"""
Rebuild tutorial posts from the rendered tutorial HTML stored in /tutorials.

This script:
1. Deletes all existing Jekyll posts categorized as tutorials.
2. Creates a new post for each rendered tutorial HTML file in /tutorials/*/*.html
   excluding section index pages.
3. Injects the Quarto-rendered main content into each post and rewrites local
   asset paths so figures continue to load from /tutorials/<section>/<stem>_files/.
"""

from __future__ import annotations

import html
import re
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POSTS_DIR = ROOT / "_posts"
TUTORIALS_DIR = ROOT / "tutorials"

TITLE_SUFFIX = " - Health Economics and Decision Sciences Tutorials"
MAIN_MARKER = '<main class="content" id="quarto-document-content">'

SECTION_TAGS = {
    "simulation-tools": "Simulation Tools",
    "visualization-tools": "Visualization Tools",
}


def normalize_text(text: str) -> str:
    replace_map = {
        "\u2018": "'",
        "\u2019": "'",
        "\u201c": '"',
        "\u201d": '"',
        "\u2013": "-",
        "\u2014": "-",
        "\u2026": "...",
        "\u00a0": " ",
    }
    for old, new in replace_map.items():
        text = text.replace(old, new)
    return text


def slugify(text: str) -> str:
    text = normalize_text(text).lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def extract_title(raw_html: str) -> str:
    match = re.search(r"<title>(.*?)</title>", raw_html, re.S | re.I)
    if not match:
        raise ValueError("missing <title>")
    title = html.unescape(match.group(1))
    title = title.replace("\xa0", " ")
    title = title.replace("–", "-").replace("—", "-")
    if TITLE_SUFFIX in title:
        title = title.replace(TITLE_SUFFIX, "")
    title = re.sub(r"^\s*\d+\s+", "", title).strip()
    return normalize_text(title)


def extract_main_content(raw_html: str, section: str, stem: str) -> str:
    start = raw_html.find(MAIN_MARKER)
    if start == -1:
        raise ValueError("missing tutorial content marker")
    start += len(MAIN_MARKER)
    end = raw_html.find("</main>", start)
    if end == -1:
        raise ValueError("missing closing </main>")
    content = raw_html[start:end]
    content = re.sub(r'<header id="title-block-header"[\s\S]*?</header>', "", content)
    content = re.sub(r'src="' + re.escape(stem) + r'_files/', f'src="/tutorials/{section}/{stem}_files/', content)
    content = re.sub(r'href="' + re.escape(stem) + r'_files/', f'href="/tutorials/{section}/{stem}_files/', content)
    return normalize_text(content.strip())


def extract_summary(content: str) -> str:
    paragraphs = re.findall(r"<p>(.*?)</p>", content, re.S | re.I)
    for paragraph in paragraphs:
        text = re.sub(r"<[^>]+>", "", paragraph)
        text = html.unescape(normalize_text(text))
        text = re.sub(r"\s+", " ", text).strip()
        if text:
            if len(text) <= 220:
                return text
            shortened = text[:217].rsplit(" ", 1)[0].strip()
            return f"{shortened}..."
    return "Tutorial and code example."


def tutorial_posts() -> list[Path]:
    paths = []
    for post in POSTS_DIR.glob("*.md"):
        text = post.read_text(encoding="utf-8")
        if re.search(r"categories:\s*\[.*\btutorials\b.*\]", text):
            paths.append(post)
    return sorted(paths)


def delete_existing_tutorial_posts() -> int:
    existing = tutorial_posts()
    for post in existing:
        post.unlink()
    return len(existing)


def build_post_path(source_html: Path) -> Path:
    section = source_html.parent.name
    slug = slugify(f"{section}-{source_html.stem}")
    date = datetime.fromtimestamp(source_html.stat().st_mtime).date().isoformat()
    return POSTS_DIR / f"{date}-{slug}.md"


def render_post(source_html: Path) -> str:
    section = source_html.parent.name
    stem = source_html.stem
    raw_html = source_html.read_text(encoding="utf-8", errors="ignore")
    title = extract_title(raw_html)
    content = extract_main_content(raw_html, section, stem)
    summary = extract_summary(content).replace('"', '\\"')
    tag = SECTION_TAGS.get(section, section.replace("-", " ").title())

    return (
        "---\n"
        f'title: "{title}"\n'
        f"date: {datetime.fromtimestamp(source_html.stat().st_mtime).date().isoformat()}\n"
        "categories: [tutorials, codes]\n"
        f'tags: ["{tag}"]\n'
        f'summary: "{summary}"\n'
        "---\n"
        f"{content}\n"
    )


def source_tutorial_html() -> list[Path]:
    return sorted(
        path
        for path in TUTORIALS_DIR.glob("*/*.html")
        if path.name != "index.html"
    )


def main() -> None:
    deleted = delete_existing_tutorial_posts()
    created = 0
    for source_html in source_tutorial_html():
        post_path = build_post_path(source_html)
        post_path.write_text(render_post(source_html), encoding="utf-8")
        created += 1
    print(f"Deleted {deleted} old tutorial posts.")
    print(f"Created {created} tutorial posts from rendered HTML.")


if __name__ == "__main__":
    main()
