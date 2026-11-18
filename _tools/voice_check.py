#!/usr/bin/env python3
"""Check the mechanical voice rules of STYLE_GUIDE.md on a content draft, before Clara: no agent call.

    python -I _tools/voice_check.py content/SLUG.md [--round N]

T5 (Sources): every GDD section the draft cites exists in GDD.md under that name, and its number
when one is given. Citations are read from the `**Sources:**` line's `GDD.md (...)` list (a quote
after a name, a sub-part after a dash and a "§N" are allowed; "A > B" checks each level) and from
"GDD §N Name" anywhere in the draft. Headings are matched without case or punctuation, so
"Land Grid & Units" matches "### 4. Land, Grid & Units".

T2 (Tone & Glossary), the word part only: terms the GDD Glossary marks **Rejected.**, and the terms
in _tools/voice_terms.json (confirmed: a FAIL row; unconfirmed: a "(minor)" row). Tone stays with Clara.

Prints a `### Script check, round N` block in Clara's verdict format (VERDICT, Checked, findings
table) and exits 1 on FAIL. generate.py calls check() each round: a FAIL goes to William without a
Clara call. Standard library only. Tests: python -I _tools/test_generate.py
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TERMS = Path(__file__).resolve().parent / "voice_terms.json"
HEADER = "| # | Check | Quote from draft | GDD section | Fix |\n|---|---|---|---|---|"


def norm(s):
    return " ".join(re.sub(r"[^a-z0-9]+", " ", s.lower()).split())


def headings(gdd):
    """(number or None, name, own) for every GDD heading and bold bullet heading (e.g. `* **Tree C: Native
    Habitat**`). A part inside a numbered section carries that section's number with own False."""
    out, current = [], (0, None)   # (level, number) of the numbered section we are in
    for line in gdd.splitlines():
        m = re.match(r"(#{1,6})\s+(?:(\d+)\.\s+)?(.+?)\s*$", line)
        if m:
            level = len(m.group(1))
            if m.group(2):
                current = (level, m.group(2))
            elif level <= current[0]:
                current = (0, None)
            out.append((m.group(2) or current[1], m.group(3), bool(m.group(2))))
            continue
        m = re.match(r"\s*[*-]\s+\*\*(.+?)\*\*\s*$", line)
        if m:
            out.append((current[1], m.group(1), False))
    return out


def split_top(s):
    """Split on commas and semicolons outside brackets."""
    parts, depth, cur = [], 0, ""
    for ch in s:
        depth += ch in "([" and 1 or ch in ")]" and -1 or 0
        if ch in ",;" and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    return parts + [cur]


def cited(text):
    """(as written, name, number or None) for each GDD section the draft cites."""
    out = []
    line = next((l for l in text.splitlines() if l.lstrip().startswith("**Sources:**")), "")
    line = re.sub(r'"[^"]*"|“[^”]*”', "", line)  # quoted GDD wording is not a section name
    m = re.search(r"GDD\.md`?\s*\(", line)
    if m:
        depth, i = 1, m.end()
        while i < len(line) and depth:
            depth += {"(": 1, ")": -1}.get(line[i], 0)
            i += 1
        for item in split_top(line[m.end():i - 1]):
            item = re.sub(r"\s+[—–-]\s+.*", "", item).strip(" :")  # "Tree C: Native Habitat — its table"
            num = re.search(r"\(?§\s?(\d+)\)?", item)
            name = re.sub(r"\(?§\s?\d+\)?", "", item).strip(" :")
            for level in name.split(">"):
                if level.strip():
                    out.append((item, level.strip(), num.group(1) if num and ">" not in name else None))
    for m in re.finditer(r"GDD(?:\.md)?`?\s*§\s?(\d+)\s+([A-Z][A-Za-z]*(?:\s+(?:&|[A-Z][A-Za-z]*|\d+\b))*)", text):
        out.append((m.group(0), m.group(2), m.group(1)))
    return out


def section_problem(name, num, heads):
    """None if the section exists; else what is wrong with the citation."""
    n = norm(name)
    named = [h for h in heads if norm(h[1]) == n]
    if named and (num is None or any(h[0] == num for h in named)):
        return None
    if num and any(h[0] == num and norm(h[1]).startswith(n + " ") for h in heads):
        return None  # "Progression Trees §3" for "### 3. Progression Trees & Economy Balance", "§2 Stage 1" for a part of §2
    at = [h[1] for h in heads if h[0] == num and h[2]] if num else []
    if named:
        return f"the section is numbered §{named[0][0]}, not §{num}" if named[0][0] else f"the section has no number §{num}"
    if at:
        return f"§{num} is \"{at[0]}\"; cite the section by its exact heading"
    return "no GDD heading has this name; cite the section by its exact heading"


def glossary_rejected(gdd):
    """The first cell of each Glossary row marked **Rejected.**"""
    gloss = gdd[gdd.find("\n## Glossary"):] if "\n## Glossary" in gdd else ""
    return [m.group(1).strip() for m in re.finditer(r"^\|\s*([^|]+?)\s*\|.*\*\*Rejected\.\*\*", gloss, re.M)]


def english(text):
    """The draft's lines without the frontmatter and the French sections (an H2 naming French, to the next H2):
    the listed terms are English words ("coin" is a corner in French)."""
    keep, french = [], False
    for line in re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S).splitlines():
        if line.startswith("## "):
            french = bool(re.search(r"fran[cç]ais|French|\(FR\)", line, re.I))
        if not french:
            keep.append(line)
    return keep


def term_rows(text, gdd, terms):
    """(check, quote, section, fix, blocking) for each line using a rejected or listed term."""
    rules = [(re.escape(t), f"{t} (Rejected)", "Glossary", f"remove \"{t}\": the GDD Glossary marks it Rejected", True)
             for t in glossary_rejected(gdd)]
    rules += [(t["pattern"], t["use"], t["section"], f"use the Glossary term \"{t['use']}\"", bool(t.get("confirmed")))
              for t in terms]
    rows = []
    for pattern, _, section, fix, blocking in rules:
        for line in english(text):
            m = re.search(rf"\b(?:{pattern})\b", line, re.I)
            if m:
                quote = line.strip()[:90].replace("|", "/")
                rows.append(("Tone & Glossary", quote, section, fix, blocking))
                break  # one row per term: William fixes every use
    return rows


def check(text, gdd, terms=None, n=1):
    """(verdict, block) for a draft: verdict PASS or FAIL, block in Clara's format with `### Script check, round n`."""
    if terms is None:
        terms = json.loads(TERMS.read_text(encoding="utf-8"))["terms"] if TERMS.is_file() else []
    heads = headings(gdd)
    rows, seen = [], []
    for written, name, num in dict.fromkeys(cited(text)):  # each citation once, however often it is repeated
        seen.append(written if written == name else f"{name} (in \"{written}\")")
        why = section_problem(name, num, heads)
        if why:
            rows.append(("Sources", written.replace("|", "/"), "GDD headings", why, True))
    rows += term_rows(text, gdd, terms)
    verdict = "FAIL" if any(r[4] for r in rows) else "PASS"
    table = "\n".join(f"| {i} | {c} | {'' if b else '(minor) '}\"{q}\" | {s} | {f} |"
                      for i, (c, q, s, f, b) in enumerate(rows, 1))
    block = (f"### Script check, round {n}\nVERDICT: {verdict}\nChecked (voice_check.py, no agent call):\n"
             f"- Sources (T5): {'; '.join(seen) or 'no GDD section cited'}\n"
             f"- Tone & Glossary (T2, terms only): {len(glossary_rejected(gdd))} Rejected Glossary term(s), "
             f"{len(terms)} listed in `_tools/voice_terms.json`\n{HEADER}" + (f"\n{table}" if table else ""))
    return verdict, block


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("draft")
    ap.add_argument("--round", type=int, default=1)
    a = ap.parse_args(argv)
    text = (ROOT / a.draft).read_text(encoding="utf-8")
    verdict, block = check(text, (ROOT / "GDD.md").read_text(encoding="utf-8"), n=a.round)
    print(block)
    return 1 if verdict == "FAIL" else 0


if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    sys.exit(main())
