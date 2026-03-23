#!/usr/bin/env python3
"""
Rebuild tutorial posts from Quarto source files stored in /tutorials.

This script:
1. Deletes all existing Jekyll posts categorized as tutorials.
2. Executes each tutorial .qmd file with knitr to capture code, tables, and figures.
3. Copies generated figures into /tutorials/rendered-assets/<slug>/.
4. Appends a chapter-specific References section from tutorials/references.bib.
5. Regenerates the /tutorials/ intro from tutorials/simulation-tools/index.qmd.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POSTS_DIR = ROOT / "_posts"
TUTORIALS_DIR = ROOT / "tutorials"
INTRO_INCLUDE = ROOT / "_includes" / "tutorials-index-intro.md"
REFERENCES_BIB = TUTORIALS_DIR / "references.bib"
RENDERED_ASSETS_DIR = TUTORIALS_DIR / "rendered-assets"

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


def find_citation_keys(text: str) -> list[str]:
    keys = re.findall(r"@([-A-Za-z0-9_:]+)", text)
    unique_keys = []
    seen = set()
    for key in keys:
        if key not in seen:
            seen.add(key)
            unique_keys.append(key)
    return unique_keys


def clean_body(text: str) -> str:
    text = normalize_text(text)
    text = strip_citations(text)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    return text + "\n"


def split_top_level_fields(text: str) -> list[str]:
    fields = []
    current = []
    depth = 0
    in_quotes = False
    for char in text:
        if char == '"' and (not current or current[-1] != "\\"):
            in_quotes = not in_quotes
        elif not in_quotes:
            if char == "{":
                depth += 1
            elif char == "}":
                depth = max(0, depth - 1)
            elif char == "," and depth == 0:
                field = "".join(current).strip()
                if field:
                    fields.append(field)
                current = []
                continue
        current.append(char)
    tail = "".join(current).strip()
    if tail:
        fields.append(tail)
    return fields


def parse_bibtex_entries() -> dict[str, dict[str, str]]:
    text = REFERENCES_BIB.read_text(encoding="utf-8")
    entries = {}
    i = 0
    while i < len(text):
        if text[i] != "@":
            i += 1
            continue
        entry_start = i
        brace_open = text.find("{", entry_start)
        if brace_open == -1:
            break
        entry_type = text[entry_start + 1:brace_open].strip().lower()
        depth = 1
        j = brace_open + 1
        while j < len(text) and depth > 0:
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
            j += 1
        raw_entry = text[brace_open + 1:j - 1].strip()
        if "," not in raw_entry:
            i = j
            continue
        key, raw_fields = raw_entry.split(",", 1)
        fields = {"entry_type": entry_type}
        for field in split_top_level_fields(raw_fields):
            if "=" not in field:
                continue
            name, value = field.split("=", 1)
            value = value.strip().strip(",").strip()
            if value.startswith("{") and value.endswith("}"):
                value = value[1:-1]
            elif value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            value = value.replace("{", "").replace("}", "")
            fields[name.strip().lower()] = normalize_text(value.strip())
        entries[key.strip()] = fields
        i = j
    return entries


def format_authors(author_text: str) -> str:
    if not author_text:
        return ""
    authors = [author.strip() for author in author_text.split(" and ") if author.strip()]
    return "; ".join(authors)


def format_reference(entry: dict[str, str]) -> str:
    parts = []
    authors = format_authors(entry.get("author", ""))
    if authors:
        parts.append(authors)
    if entry.get("year"):
        parts.append(f"({entry['year']}).")
    if entry.get("title"):
        parts.append(f"\"{entry['title']}.\"")

    source = entry.get("journal") or entry.get("booktitle")
    if source:
        source_text = f"*{source}*"
        volume = entry.get("volume", "")
        number = entry.get("number", "")
        pages = entry.get("pages", "")
        if volume and number:
            source_text += f", {volume}({number})"
        elif volume:
            source_text += f", {volume}"
        if pages:
            source_text += f", {pages}"
        source_text += "."
        parts.append(source_text)
    elif entry.get("publisher"):
        publisher_text = entry["publisher"]
        if entry.get("address"):
            publisher_text += f", {entry['address']}"
        publisher_text += "."
        parts.append(publisher_text)

    if entry.get("doi"):
        parts.append(f"DOI: <https://doi.org/{entry['doi']}>.")
    elif entry.get("url"):
        parts.append(f"<{entry['url']}>.")

    return " ".join(parts).strip()


def build_references_section(citation_keys: list[str], bibliography: dict[str, dict[str, str]]) -> str:
    references = []
    for key in citation_keys:
        entry = bibliography.get(key)
        if not entry:
            continue
        references.append(f"- {format_reference(entry)}")
    if not references:
        return ""
    return "\n## References\n\n" + "\n".join(references) + "\n"


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


def reset_rendered_assets() -> None:
    if RENDERED_ASSETS_DIR.exists():
        shutil.rmtree(RENDERED_ASSETS_DIR)
    RENDERED_ASSETS_DIR.mkdir(parents=True, exist_ok=True)


def cleanup_figure_dirs(paths: list[Path]) -> None:
    for path in paths:
        if path.exists():
            shutil.rmtree(path)


def execute_qmd(source_qmd: Path, slug: str) -> str:
    with tempfile.TemporaryDirectory(prefix="tutorial-knit-") as tmp_dir:
        tmp_path = Path(tmp_dir)
        output_md = tmp_path / f"{slug}.md"
        candidate_figure_dirs = [
            tmp_path / "figures",
            tmp_path / "figure",
            ROOT / "figures",
            ROOT / "figure",
        ]
        cleanup_figure_dirs(candidate_figure_dirs)
        (tmp_path / "figures").mkdir(parents=True, exist_ok=True)

        r_code = (
            "args <- commandArgs(trailingOnly=TRUE); "
            "options(knitr.graphics.auto_pdf = FALSE); "
            "knitr::opts_chunk$set(fig.path='figures/'); "
            "knitr::knit(args[1], output=args[2], quiet=TRUE)"
        )
        subprocess.run(
            ["Rscript", "-e", r_code, str(source_qmd), str(output_md)],
            check=True,
            cwd=ROOT,
        )

        asset_dir = RENDERED_ASSETS_DIR / slug
        copied_any_assets = False
        for figures_dir in candidate_figure_dirs:
            if not figures_dir.exists():
                continue
            files = [file for file in figures_dir.glob("*") if file.is_file()]
            if not files:
                continue
            asset_dir.mkdir(parents=True, exist_ok=True)
            for file in files:
                shutil.copy2(file, asset_dir / file.name)
                copied_any_assets = True

        _, body = parse_front_matter(output_md.read_text(encoding="utf-8"))
        body = clean_body(body)
        body = body.replace("](figures/", f"](/tutorials/rendered-assets/{slug}/")
        body = body.replace("](figure/", f"](/tutorials/rendered-assets/{slug}/")
        body = body.replace('src="figures/', f'src="/tutorials/rendered-assets/{slug}/')
        body = body.replace('src="figure/', f'src="/tutorials/rendered-assets/{slug}/')
        if not copied_any_assets:
            body = re.sub(
                rf"\n!\[[^\]]*\]\(/tutorials/rendered-assets/{re.escape(slug)}/[^)]+\)\n?",
                "\n",
                body,
            )
        cleanup_figure_dirs([ROOT / "figures", ROOT / "figure"])
        return body


def render_post(source_qmd: Path, bibliography: dict[str, dict[str, str]]) -> str:
    section = source_qmd.parent.name
    slug = slugify(f"{section}-{source_qmd.stem}")
    front_matter, raw_body = parse_front_matter(source_qmd.read_text(encoding="utf-8"))
    title = normalize_text(front_matter.get("title", source_qmd.stem.replace("-", " ").title()))
    subtitle = normalize_text(front_matter.get("subtitle", ""))
    citation_keys = find_citation_keys(raw_body)
    body = execute_qmd(source_qmd, slug)
    body += build_references_section(citation_keys, bibliography)
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
    bibliography = parse_bibtex_entries()
    deleted = delete_existing_tutorial_posts()
    reset_rendered_assets()
    created = 0
    for source_qmd in source_tutorial_qmd():
        post_path = build_post_path(source_qmd)
        post_path.write_text(render_post(source_qmd, bibliography), encoding="utf-8")
        created += 1
    rebuild_intro_include()
    print(f"Deleted {deleted} old tutorial posts.")
    print(f"Created {created} tutorial posts from Quarto source.")
    print(f"Updated intro include: {INTRO_INCLUDE}")
    print(f"Rendered assets: {RENDERED_ASSETS_DIR}")


if __name__ == "__main__":
    main()
