#!/usr/bin/env python3
"""
Rebuild tutorial posts from Quarto source files stored in /tutorials.

This script:
1. Deletes all existing Jekyll posts categorized as tutorials.
2. Creates a new post for each tutorial .qmd file in /tutorials/* excluding
   section index pages.
3. Generates the /tutorials/ page intro from tutorials/simulation-tools/index.qmd.
"""

from __future__ import annotations

import re
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POSTS_DIR = ROOT / "_posts"
TUTORIALS_DIR = ROOT / "tutorials"
INTRO_INCLUDE = ROOT / "_includes" / "tutorials-index-intro.md"

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


def parse_front_matter(text: str) -> tuple[dict[str, str], str]:
    match = re.match(r"\A---\n(.*?)\n---\n(.*)\Z", text, re.S)
    if not match:
        return {}, text

    front_matter = {}
    raw_front_matter, body = match.groups()
    for line in raw_front_matter.splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        front_matter[key.strip()] = value.strip().strip('"').strip("'")
    return front_matter, body


def strip_citations(text: str) -> str:
    text = re.sub(r"[ \t]+@[-A-Za-z0-9_:]+", "", text)
    text = re.sub(r";[ \t]*(?=[\.\)])", "", text)
    text = re.sub(r"\([ \t]*\)", "", text)
    text = re.sub(r"[ \t]+([,.;:])", r"\1", text)
    text = re.sub(r"[ \t]{2,}", " ", text)
    return text


def normalize_code_fences(text: str) -> str:
    text = re.sub(r"```+\{r[^}]*\}", "```r", text)
    return text


def clean_body(text: str) -> str:
    text = normalize_text(text)
    text = strip_citations(text)
    text = normalize_code_fences(text)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    return text + "\n"


def extract_summary(text: str) -> str:
    blocks = [block.strip() for block in text.split("\n\n")]
    for block in blocks:
        if not block or block.startswith("#") or block.startswith("```") or block.startswith("$$"):
            continue
        one_line = re.sub(r"\s+", " ", block).strip()
        if len(one_line) <= 220:
            return one_line
        shortened = one_line[:217].rsplit(" ", 1)[0].strip()
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


def source_tutorial_qmd() -> list[Path]:
    return sorted(
        path
        for path in TUTORIALS_DIR.glob("*/*.qmd")
        if path.name != "index.qmd"
    )


def build_post_path(source_qmd: Path) -> Path:
    section = source_qmd.parent.name
    slug = slugify(f"{section}-{source_qmd.stem}")
    date = datetime.fromtimestamp(source_qmd.stat().st_mtime).date().isoformat()
    return POSTS_DIR / f"{date}-{slug}.md"


def render_post(source_qmd: Path) -> str:
    section = source_qmd.parent.name
    front_matter, raw_body = parse_front_matter(source_qmd.read_text(encoding="utf-8"))
    title = normalize_text(front_matter.get("title", source_qmd.stem.replace("-", " ").title()))
    subtitle = normalize_text(front_matter.get("subtitle", ""))
    body = clean_body(raw_body)
    summary = extract_summary(body).replace('"', '\\"')
    tag = SECTION_TAGS.get(section, section.replace("-", " ").title())
    date = datetime.fromtimestamp(source_qmd.stat().st_mtime).date().isoformat()

    lines = [
        "---",
        f'title: "{title}"',
        f"date: {date}",
        "categories: [tutorials, codes]",
        f'tags: ["{tag}"]',
        f'summary: "{summary}"',
    ]
    if subtitle:
        lines.append(f'excerpt: "{subtitle.replace(chr(34), r"\\\"")}"')
    lines.extend(["---", body.rstrip(), ""])
    return "\n".join(lines)


def rebuild_intro_include() -> None:
    source_qmd = TUTORIALS_DIR / "simulation-tools" / "index.qmd"
    front_matter, raw_body = parse_front_matter(source_qmd.read_text(encoding="utf-8"))
    title = normalize_text(front_matter.get("title", "Simulation Tools"))
    body = clean_body(raw_body)
    intro = f"## {title}\n\n{body}"
    INTRO_INCLUDE.write_text(intro, encoding="utf-8")


def main() -> None:
    deleted = delete_existing_tutorial_posts()
    created = 0
    for source_qmd in source_tutorial_qmd():
        post_path = build_post_path(source_qmd)
        post_path.write_text(render_post(source_qmd), encoding="utf-8")
        created += 1
    rebuild_intro_include()
    print(f"Deleted {deleted} old tutorial posts.")
    print(f"Created {created} tutorial posts from Quarto source.")
    print(f"Updated intro include: {INTRO_INCLUDE}")


if __name__ == "__main__":
    main()
