#!/usr/bin/env python3
"""
Sync Quarto-rendered tutorials into this Jekyll site.

Steps performed:
1) Copy *_files asset folders from <quarto_project>/_book to <site>/tutorials/
2) For each tutorial post in <site>/_posts, replace body with the HTML inside
   <main id="quarto-document-content"> from the corresponding _book HTML.
3) Rewrite asset paths to /tutorials/<stem>_files/...

Usage:
  python3 scripts/sync_tutorials_from_quarto.py /path/to/HEOR_Tutorials
"""

import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POSTS_DIR = ROOT / "_posts"
TUTORIALS_DIR = ROOT / "tutorials"


def slugify(s: str) -> str:
    s = s.strip().lower()
    s = s.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ñ", "n")
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def parse_quarto_chapters(quarto_yml: Path):
    lines = quarto_yml.read_text(encoding="utf-8").splitlines()
    part_map = {}
    current_part = None
    in_chapters = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("chapters:"):
            in_chapters = True
            continue
        if not in_chapters:
            continue
        if stripped.startswith("- part:"):
            part_title = stripped.split(":", 1)[1].strip().strip('"').strip("'")
            part_title = re.sub(r"^\\s*\\d+\\.?\\s*", "", part_title).strip()
            current_part = part_title
            continue
        if stripped.startswith("- ") and stripped.endswith(".qmd"):
            qmd_file = stripped[2:].strip()
            stem = Path(qmd_file).stem
            if stem == "index":
                part_map[stem] = "Overview"
            else:
                part_map[stem] = current_part or "Overview"
            continue
    return part_map


def normalize_punct(text: str) -> str:
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
    for k, v in replace_map.items():
        text = text.replace(k, v)
    return text


def copy_assets(book_dir: Path):
    TUTORIALS_DIR.mkdir(parents=True, exist_ok=True)
    for asset_dir in book_dir.glob("*_files"):
        dest = TUTORIALS_DIR / asset_dir.name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(asset_dir, dest)


def sync_posts(book_dir: Path, slug_to_stem):
    front_matter_re = re.compile(r"\\A---\\n(.*?)\\n---\\n", re.S)
    updated = 0
    skipped = []
    for post in POSTS_DIR.glob("*.md"):
        text = post.read_text(encoding="utf-8")
        m = front_matter_re.match(text)
        if not m:
            continue
        fm = m.group(1)
        if "tutorials" not in fm:
            continue
        parts = post.stem.split("-", 3)
        if len(parts) < 4:
            continue
        slug = parts[3]
        stem = slug_to_stem.get(slug)
        if not stem:
            continue
        html_path = book_dir / f"{stem}.html"
        if not html_path.exists():
            skipped.append(stem)
            continue
        html = html_path.read_text(encoding="utf-8", errors="ignore")
        main_start = html.find('<main class="content" id="quarto-document-content">')
        if main_start == -1:
            skipped.append(stem)
            continue
        main_start += len('<main class="content" id="quarto-document-content">')
        main_end = html.find("</main>", main_start)
        if main_end == -1:
            skipped.append(stem)
            continue
        content = html[main_start:main_end]
        content = re.sub(r'<header id="title-block-header"[\\s\\S]*?</header>', "", content)
        content = re.sub(r'src="' + re.escape(stem) + r'_files/', f'src="/tutorials/{stem}_files/', content)
        content = re.sub(r'href="' + re.escape(stem) + r'_files/', f'href="/tutorials/{stem}_files/', content)
        content = normalize_punct(content)
        new_text = "---\n" + fm + "\n---\n" + content.strip() + "\n"
        post.write_text(new_text, encoding="utf-8")
        updated += 1
    return updated, skipped


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 scripts/sync_tutorials_from_quarto.py /path/to/HEOR_Tutorials")
        sys.exit(1)

    project_dir = Path(sys.argv[1]).expanduser().resolve()
    quarto_yml = project_dir / "_quarto.yml"
    book_dir = project_dir / "_book"

    if not quarto_yml.exists():
        print("ERROR: _quarto.yml not found in", project_dir)
        sys.exit(1)
    if not book_dir.exists():
        print("ERROR: _book not found. Run 'quarto render' first in", project_dir)
        sys.exit(1)

    part_map = parse_quarto_chapters(quarto_yml)
    slug_to_stem = {slugify(stem): stem for stem in part_map.keys()}

    copy_assets(book_dir)
    updated, skipped = sync_posts(book_dir, slug_to_stem)

    print(f"Updated {updated} tutorial posts.")
    if skipped:
        print("Skipped (no matching HTML):")
        for s in skipped:
            print("-", s)


if __name__ == "__main__":
    main()
