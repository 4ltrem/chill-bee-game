#!/usr/bin/env python3
"""Ruth's checked source quotes, reused by URL and date so Clara does not re-fetch them (A4 grader item a).

    python -I _tools/source_cache.py content/SLUG.md     # print the quotes Clara would get for a draft

Every research brief (research/*.md, template _templates/research-brief.md) has a Findings table with
the claim, the verbatim quote, the URL and the date Ruth checked it. generate.py gives the critic the
rows whose URL the draft cites, so she compares the draft's claim with the quote instead of calling
WebFetch on that URL. A row older than MAX_AGE_DAYS, or from a rejected brief, is not used: that URL
is fetched as before. Standard library only. Tests: python -I _tools/test_generate.py
"""
import datetime
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAX_AGE_DAYS = 180
URL = re.compile(r"https?://[^\s|)>\]`\"']+")


def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def findings(brief_text, source=""):
    """Each Findings row of one brief as a dict: claim, quote, url, date, brief."""
    if re.search(r"^status:\s*rejected", brief_text.split("\n---", 1)[0], re.M):
        return []
    rows, cols = [], None
    for line in brief_text.splitlines():
        if not line.lstrip().startswith("|"):
            cols = None
            continue
        c = cells(line)
        if cols is None:
            low = [x.lower() for x in c]
            if any("quote" in x for x in low) and "url" in low:
                # "Claim (as narrow as the quote)" names the quote too: the quote column is the one without "claim"
                hit = {k: [i for i, x in enumerate(low) if k in x and (k != "quote" or "claim" not in x)]
                       for k in ("claim", "quote", "url", "date")}
                cols = {k: v[0] for k, v in hit.items() if v}
            continue
        if set("".join(c)) <= set("-: ") or "url" not in cols or len(c) <= cols["url"]:
            continue
        m = URL.search(c[cols["url"]])
        if m:
            rows.append({"claim": c[cols["claim"]] if "claim" in cols else "", "quote": c[cols["quote"]],
                         "url": m.group(0).rstrip(".,;"), "date": c[cols["date"]] if "date" in cols else "",
                         "brief": source})
    return rows


def load(root=None):
    """All usable rows of every brief under research/, keyed by URL."""
    folder = (root or ROOT) / "research"
    out = {}
    for p in sorted(folder.glob("*.md")) if folder.is_dir() else []:
        if p.name in ("CONTEXT.md", "_index.md"):
            continue
        for r in findings(p.read_text(encoding="utf-8"), p.relative_to(root or ROOT).as_posix()):
            out.setdefault(r["url"], []).append(r)
    return out


def fresh(date, today=None):
    try:
        d = datetime.date.fromisoformat(date.strip()[:10])
    except ValueError:
        return False
    return ((today or datetime.date.today()) - d).days <= MAX_AGE_DAYS


def for_draft(text, root=None, today=None):
    """The prompt section for the critic: the cached quotes for each URL the draft cites, or "" if none."""
    cache = load(root)
    lines = []
    for url in dict.fromkeys(u.rstrip(".,;") for u in URL.findall(text)):
        for r in cache.get(url, []):
            if fresh(r["date"], today):
                lines.append(f"- {url} (checked {r['date']}, `{r['brief']}`): claim \"{r['claim']}\"; "
                             f"quote {r['quote']}")
    if not lines:
        return ""
    return ("Checked source quotes (Ruth's briefs; use these instead of WebFetch for these URLs: a claim citing one "
            "is confirmed only if its quote supports it, narrowed as the quote is):\n" + "\n".join(lines))


if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    print(for_draft((ROOT / sys.argv[1]).read_text(encoding="utf-8")) or "no cached quotes for this draft")
