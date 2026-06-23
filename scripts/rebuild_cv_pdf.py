#!/usr/bin/env python3
"""
Rebuild the downloadable PDF CV from the website source files.

The generated CV keeps static sections from _pages/cv.md and pulls live
publication, talk, and teaching entries from their Jekyll collections.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CV_PAGE = ROOT / "_pages" / "cv.md"
PUBLICATIONS_DIR = ROOT / "_publications"
TALKS_DIR = ROOT / "_talks"
TEACHING_DIR = ROOT / "_teaching"
CV_SOURCE = ROOT / "files" / "cv" / "carlos-pineda-academic-cv.md"
CV_PDF = ROOT / "files" / "cv" / "carlos-pineda-academic-cv.pdf"


def strip_front_matter(text: str) -> str:
    return re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)


def normalize_text(text: str) -> str:
    replacements = {
        "\u2013": "-",
        "\u2014": "-",
        "\u00a0": " ",
        "<i>": "*",
        "</i>": "*",
        '\\"': '"',
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text.strip()


def parse_front_matter(path: Path) -> tuple[dict[str, str], str]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\n(.*?)\n---\n?(.*)\Z", text, flags=re.S)
    if not match:
        return {}, text

    raw_front_matter, body = match.groups()
    data: dict[str, str] = {}
    current_key: str | None = None
    current_value: list[str] = []

    def flush_current() -> None:
        nonlocal current_key, current_value
        if current_key is not None:
            data[current_key] = normalize_text(" ".join(current_value))
        current_key = None
        current_value = []

    for line in raw_front_matter.splitlines():
        if not line.strip():
            continue
        if re.match(r"^[A-Za-z_][A-Za-z0-9_-]*:", line):
            flush_current()
            key, value = line.split(":", 1)
            current_key = key.strip()
            current_value = [value.strip().strip('"').strip("'")]
        elif current_key is not None:
            current_value.append(line.strip().strip('"').strip("'"))
    flush_current()
    return data, body


def extract_underlined_section(markdown: str, title: str, next_titles: list[str]) -> str:
    pattern = rf"(?ms)^{re.escape(title)}\n=+\n(.*?)(?=^({'|'.join(map(re.escape, next_titles))})\n=+\n|\Z)"
    match = re.search(pattern, markdown)
    if not match:
        return ""
    section = match.group(1).strip()
    section = re.sub(r"\n\s*<ul>\{%.+?\{%\s*endfor\s*%\}</ul>", "", section, flags=re.S)
    return section.strip()


def front_matter_date(data: dict[str, str]) -> str:
    return data.get("date", "1900-01-01")


def sort_collection(paths: list[Path]) -> list[Path]:
    return sorted(paths, key=lambda path: front_matter_date(parse_front_matter(path)[0]), reverse=True)


def bold_author_names(text: str) -> str:
    patterns = [
        "Pineda-Antunez CJ",
        "Pineda-Antunez C",
        "Pineda-Antúnez CJ",
        "Pineda-Antúnez C",
    ]
    for pattern in patterns:
        text = text.replace(pattern, f"**{pattern}**")
    return text


def publication_items() -> str:
    items = []
    for path in sort_collection(list(PUBLICATIONS_DIR.glob("*.md"))):
        data, _ = parse_front_matter(path)
        citation = data.get("citation")
        if not citation:
            title = data.get("title", path.stem)
            venue = data.get("venue", "")
            year = front_matter_date(data)[:4]
            citation = f"{title}. *{venue}*. {year}."
        citation = bold_author_names(normalize_text(citation))
        items.append(f"- {citation}")
    return "\n".join(items)


def talk_items() -> str:
    items = []
    for path in sort_collection(list(TALKS_DIR.glob("*.md"))):
        data, _ = parse_front_matter(path)
        year = front_matter_date(data)[:4]
        title = data.get("title", path.stem.replace("-", " ").title())
        talk_type = data.get("type", "Presentation")
        venue = data.get("venue", "")
        location = data.get("location", "")
        details = ", ".join(part for part in [talk_type, venue, location] if part)
        items.append(f"- {year}. {title}. {details}.")
    return "\n".join(items)


def teaching_items() -> str:
    items = []
    for path in sort_collection(list(TEACHING_DIR.glob("*.md"))):
        data, body = parse_front_matter(path)
        year = front_matter_date(data)[:4]
        title = data.get("title", path.stem.replace("-", " ").title())
        venue = data.get("venue", "")
        location = data.get("location", "")
        body = normalize_text(strip_front_matter(body)).replace("\n", " ").strip()
        details = ", ".join(part for part in [venue, location] if part)
        suffix = f" {body}" if body else ""
        items.append(f"- {year}. **{title}**. {details}.{suffix}")
    return "\n".join(items)


def software_section() -> str:
    return """**BayCANN for CISNET colorectal cancer models**  
Code to perform emulator-based Bayesian calibration for the three Colorectal Cancer CISNET models. Publication: [Medical Decision Making](https://journals.sagepub.com/doi/10.1177/0272989X241255618). Repository: [NCI-CISNET-Colorectal/baycann_cisnet_crc](https://github.com/NCI-CISNET-Colorectal/baycann_cisnet_crc).

**Cancer modeling with discrete-event simulation**  
Tutorial and open-source workflow for cancer modeling with discrete-event simulation. Publication: [PharmacoEconomics](https://link.springer.com/article/10.1007/s40273-025-01571-3). Repository: [sjpi22/tutorial_cancer_modeling_des](https://github.com/sjpi22/tutorial_cancer_modeling_des).

**ggpop**  
R package built on top of ggplot2 to simplify the creation of icon-based population charts. CRAN page: [ggpop](https://cran.r-project.org/web/packages/ggpop/index.html). Project website: [jurjoroa.github.io/ggpop](https://jurjoroa.github.io/ggpop/)."""


def render_cv_markdown() -> str:
    cv_markdown = strip_front_matter(CV_PAGE.read_text(encoding="utf-8"))
    sections = ["Education", "Professional Experience", "Skills", "Publications", "Talks", "Teaching", "Awards"]
    education = extract_underlined_section(cv_markdown, "Education", sections)
    experience = extract_underlined_section(cv_markdown, "Professional Experience", sections)
    skills = extract_underlined_section(cv_markdown, "Skills", sections)
    awards = extract_underlined_section(cv_markdown, "Awards", sections)

    updated = datetime.now().strftime("%B %Y")

    return f"""---
title: "Carlos Pineda-Antunez"
subtitle: "Curriculum Vitae"
date: "Updated {updated}"
documentclass: article
fontsize: 10.5pt
geometry: margin=0.75in
colorlinks: true
linkcolor: black
urlcolor: blue
header-includes: |
  \\usepackage{{xcolor}}
  \\usepackage{{sectsty}}
  \\definecolor{{uwblue}}{{HTML}}{{1D4E89}}
  \\sectionfont{{\\large\\color{{uwblue}}}}
  \\let\\oldsection\\section
  \\renewcommand{{\\section}}[1]{{\\oldsection{{#1}}\\vspace{{-0.55em}}{{\\color{{gray}}\\noindent\\rule{{\\linewidth}}{{0.4pt}}}}\\vspace{{0.35em}}}}
  \\let\\oldsubsection\\subsection
  \\renewcommand{{\\subsection}}[1]{{\\oldsubsection{{#1}}\\vspace{{-0.55em}}{{\\color{{gray}}\\noindent\\rule{{\\linewidth}}{{0.4pt}}}}\\vspace{{0.35em}}}}
  \\setlength{{\\parindent}}{{0pt}}
  \\setlength{{\\parskip}}{{0.35em}}
---

\\begin{{center}}
{{\\LARGE \\textbf{{Carlos Pineda-Antunez}}}}\\\\
\\vspace{{0.25em}}
PhD student in Health Economics and Outcomes Research\\\\
Comparative Health Outcomes, Policy, and Economics Institute, University of Washington\\\\
\\vspace{{0.25em}}
\\href{{mailto:cpinedaa@uw.edu}}{{cpinedaa@uw.edu}} \\quad
\\href{{https://carlospiant.github.io/}}{{carlospiant.github.io}} \\quad
\\href{{https://github.com/CarlosPiant}}{{GitHub}} \\quad
\\href{{https://www.linkedin.com/in/carlos-piant/}}{{LinkedIn}} \\quad
\\href{{https://scholar.google.com/citations?user=yO3sVGYAAAAJ&hl=en}}{{Google Scholar}} \\quad
\\href{{https://orcid.org/0000-0002-8352-7080}}{{ORCID}}
\\end{{center}}

## Research Profile

Health economist and decision scientist focused on health economics, outcomes research, decision modeling, and public health policy. My work evaluates prevention interventions, health system performance, and the value of health technologies, with applications in colorectal cancer, HIV, maternal health, mental health, and financial protection. I develop decision models, simulation tools, economic evaluations, and reproducible software workflows to support evidence-informed decision making.

## Education

{education}

## Professional Experience

{experience}

## Software Development and Published Tools

{software_section()}

## Publications

{publication_items()}

## Talks

{talk_items()}

## Teaching

{teaching_items()}

## Awards

{awards}

## Skills

{skills}
"""


def rebuild_pdf() -> None:
    if shutil.which("pandoc") is None:
        raise SystemExit("pandoc is required to render the PDF CV but was not found.")
    subprocess.run(
        [
            "pandoc",
            str(CV_SOURCE),
            "--pdf-engine=pdflatex",
            "-o",
            str(CV_PDF),
        ],
        check=True,
        cwd=ROOT,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Rebuild the generated PDF CV.")
    parser.add_argument("--no-pdf", action="store_true", help="Only regenerate the Markdown source.")
    args = parser.parse_args()

    CV_SOURCE.parent.mkdir(parents=True, exist_ok=True)
    CV_SOURCE.write_text(render_cv_markdown(), encoding="utf-8")
    if not args.no_pdf:
        rebuild_pdf()
    print(f"Updated CV source: {CV_SOURCE}")
    if not args.no_pdf:
        print(f"Updated CV PDF: {CV_PDF}")


if __name__ == "__main__":
    main()
