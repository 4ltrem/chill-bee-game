#!/usr/bin/env python3
"""Build the decision timeline page from every session's decision log.

    python -I _tools/decision_page.py

Reads each _meta/sessions/<date>-<id>/decisions.md (format: one `### D<n> · <YYYY-MM-DD> · <Topic> ·
<Title>` heading per decision, then `- Label: text` bullets, and a `## Still open` list) and writes
_meta/sessions/decision-comb.html from the template _templates/decision-page.html. The page is one
cumulative timeline across sessions and machines, newest day first; "Still open" comes from the
newest session's log. Publish the result with the Artifact tool to the link kept in
.claude/skills/end-of-day/SKILL.md. Standard library only.
"""
import json
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
SESSIONS = Path("_meta") / "sessions"
TEMPLATE = Path("_templates") / "decision-page.html"
PAGE = SESSIONS / "decision-comb.html"
HEADING = re.compile(r"^### (D\d+) · (\d{4}-\d\d-\d\d) · ([^·]+?) · (.+)$")
FIELD = re.compile(r"^- ([A-Z][\w' -]{0,30}): (.*)$")


def parse(path):
    """(decisions, still-open items) from one decisions.md."""
    decisions, still_open, section, current = [], [], "", None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            section, current = line[3:].strip().lower(), None
            continue
        m = HEADING.match(line)
        if m:
            did, date, topic, title = (s.strip() for s in m.groups())
            current = {"id": did, "date": date, "topic": topic, "title": title, "fields": [],
                       "session": path.parent.name}
            decisions.append(current)
            continue
        if section.startswith("still open") and line.startswith("- "):
            still_open.append(line[2:].strip())
            continue
        f = FIELD.match(line)
        if f and current:
            current["fields"].append([f.group(1), f.group(2).strip()])
        elif line.startswith("  ") and current and current["fields"]:  # wrapped bullet
            current["fields"][-1][1] += " " + line.strip()
    return decisions, still_open


def letters(topics):
    """One distinct capital letter per topic, from its own name where possible."""
    out, used = {}, set()
    for t in topics:
        pick = next((c.upper() for c in t if c.isalpha() and c.upper() not in used), None)
        pick = pick or next(chr(c) for c in range(65, 91) if chr(c) not in used)
        out[t], _ = pick, used.add(pick)
    return out


def build(root=None):
    root = root or ROOT
    logs = sorted((root / SESSIONS).glob("*/decisions.md"))
    decisions, still_open, newest = [], [], (-1, "")
    for log in logs:
        d, o = parse(log)
        decisions += d
        # the newest session's list wins: newest = highest decision ID (IDs are global and in order;
        # folder names sort by date and then a random session id, so same-day sessions sort wrongly)
        key = (max((int(x["id"][1:]) for x in d), default=-1), log.parent.name)
        if o and key > newest:
            still_open, newest = o, key
    decisions.sort(key=lambda d: (d["date"], int(d["id"][1:])))
    for a, b in zip(decisions, decisions[1:]):
        if int(b["id"][1:]) < int(a["id"][1:]):
            print(f"warning: {b['id']} ({b['date']}) is numbered below {a['id']} ({a['date']}); "
                  "number decisions in date order", file=sys.stderr)
    topics = list(dict.fromkeys(d["topic"] for d in decisions))
    data = {"decisions": decisions, "open": still_open, "sessions": len(logs), "letters": letters(topics)}
    payload = json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
    html = (root / TEMPLATE).read_text(encoding="utf-8").replace("/*__DATA__*/null", payload)
    (root / PAGE).write_text(html, encoding="utf-8", newline="\n")
    return data


def main():
    data = build()
    days = len({d["date"] for d in data["decisions"]})
    print(f"wrote {PAGE.as_posix()}: {len(data['decisions'])} decisions over {days} day(s) from "
          f"{data['sessions']} session(s), {len(data['open'])} still open")


if __name__ == "__main__":
    main()
