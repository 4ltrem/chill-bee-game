#!/usr/bin/env python3
"""Turn a Markdown document into a print-ready PDF with headless Edge, and count its pages.

    python -I _tools/md_to_pdf.py _meta/drafts/a7/audit.md [--min-pages 20]

Writes <name>.html and <name>.pdf next to the source (relative images such as charts/x.svg keep working). The
front matter is dropped; the Markdown library (tables, fenced code) does the conversion; a print stylesheet sets
A4 pages, page numbers, tables that don't split rows, and each top-level section on a new page. Exit 1 when the
PDF is missing or shorter than --min-pages. Needs Edge (the path in EDGE below) and the `Markdown` package.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

try:
    import markdown
except ImportError:   # `python -I` drops the user site-packages, where `pip install --user` put Markdown
    import site
    sys.path.append(site.getusersitepackages())
    import markdown

EDGE = Path("C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe")
CSS = """
@page { size: A4; margin: 18mm 16mm 20mm; @bottom-center { content: counter(page); font-size: 9pt; color: #52514e; } }
body { font-family: "Segoe UI", Inter, Arial, sans-serif; font-size: 10.5pt; line-height: 1.5; color: #0b0b0b;
       background: #fff; max-width: 100%; margin: 0; }
h1 { font-size: 22pt; margin: 0 0 6pt; }
h2 { font-size: 15pt; margin: 18pt 0 6pt; break-before: page; border-bottom: 1px solid #e4e3df; padding-bottom: 3pt; }
h2:first-of-type { break-before: auto; }
h3 { font-size: 12pt; margin: 14pt 0 4pt; break-after: avoid; }
p, li { orphans: 3; widows: 3; }
table { border-collapse: collapse; width: 100%; margin: 6pt 0 10pt; font-size: 9pt; }
th, td { border: 1px solid #e4e3df; padding: 3pt 5pt; text-align: left; vertical-align: top; }
th { background: #f3f2ee; }
tr { break-inside: avoid; }
code { font-family: Consolas, monospace; font-size: 9pt; background: #f3f2ee; padding: 0 2pt; border-radius: 2pt; }
pre { background: #f3f2ee; padding: 6pt; overflow-wrap: anywhere; white-space: pre-wrap; }
img { max-width: 100%; display: block; margin: 8pt auto; break-inside: avoid; }
a { color: #1c5cab; text-decoration: none; }
"""


def to_html(md_text, title):
    body = re.sub(r"\A---\n.*?\n---\n", "", md_text, flags=re.S)
    html = markdown.markdown(body, extensions=["tables", "fenced_code", "sane_lists", "toc"])   # toc: headings get ids
    return (f'<!doctype html><html lang="en"><head><meta charset="utf-8"><title>{title}</title>'
            f"<style>{CSS}</style></head><body>{html}</body></html>")


def pages(pdf):
    data = pdf.read_bytes()
    return len(re.findall(rb"/Type\s*/Page(?![s\w])", data))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("source")
    ap.add_argument("--min-pages", type=int, default=0)
    a = ap.parse_args(argv)
    src = Path(a.source).resolve()
    text = src.read_text(encoding="utf-8")
    title = (re.search(r"^# (.+)$", text, re.M) or [None, src.stem])[1]
    html, pdf = src.with_suffix(".html"), src.with_suffix(".pdf")
    html.write_text(to_html(text, title), encoding="utf-8")
    if not EDGE.exists():
        print(f"md_to_pdf: wrote {html.name}; Edge not found at {EDGE}, no PDF")
        return 1
    if pdf.exists():
        pdf.unlink()
    subprocess.run([str(EDGE), "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    f"--print-to-pdf={pdf}", html.as_uri()], capture_output=True, timeout=120)
    if not pdf.exists():
        print(f"md_to_pdf: wrote {html.name}; Edge made no PDF")
        return 1
    n = pages(pdf)
    ok = n >= a.min_pages
    print(f"md_to_pdf: {pdf.name}, {n} pages ({pdf.stat().st_size // 1024} KB)"
          + ("" if not a.min_pages else (" >= " if ok else " < ") + f"{a.min_pages} required"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
