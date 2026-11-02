#!/usr/bin/env python3
"""Rewrite the generated sections of the docs from their source of truth.

    python -I _tools/sync_docs.py           rewrite every generated section
    python -I _tools/sync_docs.py --check   change nothing; exit 1 if any section is out of date

A generated section sits between two markers in a Markdown file:

    <!-- generated: crew-agents (python -I _tools/sync_docs.py; do not edit by hand) -->
    ...
    <!-- /generated: crew-agents -->

Facts that live in code or config are written here instead of being copied by hand, so a doc
cannot drift from them: each agent's model and tools come from its `.claude/agents/<slug>.md`
frontmatter. _tools/consistency.py checks the facts that cannot be generated. Standard library only.
"""
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
DOCS = ["CREW.md"]  # files that hold generated sections
BLOCK = re.compile(r"(<!-- generated: ([\w-]+)[^>]*-->\n)(.*?)(<!-- /generated: \2 -->)", re.S)
CREW = ["research-assistant", "writer", "content-critic"]  # generate.py's RESEARCHER, WRITER, CRITIC


def agent(slug, root=None):
    """name, role, model, tools and summary from an agent definition's frontmatter."""
    text = ((root or ROOT) / ".claude" / "agents" / f"{slug}.md").read_text(encoding="utf-8")
    front = text.split("\n---", 1)[0]
    field = lambda k: (re.search(rf"^{k}:\s*(.+)$", front, re.M) or [None, ""])[1].strip()
    desc = field("description")
    m = re.match(r"([^,]+), the ([^.]+)\.\s*(.*?\.)(?:\s|$)", desc)
    name, role, summary = (m.groups() if m else (slug, slug, desc))
    return {"slug": slug, "name": name, "role": role, "summary": summary,
            "model": field("model").capitalize(), "tools": field("tools")}


def crew_agents(root=None):
    rows = ["| Agent | Model | Tools | What it does |", "|---|---|---|---|"]
    for slug in CREW:
        a = agent(slug, root)
        rows.append(f"| **{a['name']}**, {a['role']} ([definition](.claude/agents/{slug}.md)) | {a['model']} | "
                    f"{a['tools']} | {a['summary']} |")
    rows.append("| `generate.py` (orchestrator) | — | — | Runs the loop, controls the blackboard, logs every call and keeps each call's transcript. |")
    return "\n".join(rows) + "\n"


GENERATORS = {"crew-agents": crew_agents}


def sync(check=False, root=None):
    """Rewrite (or, with check, only compare) every generated section; return the stale ones."""
    root = root or ROOT
    stale = []
    for doc in DOCS:
        path = root / doc
        text = path.read_text(encoding="utf-8")

        def fill(m):
            name = m.group(2)
            if name not in GENERATORS:
                raise SystemExit(f"{doc}: unknown generated section '{name}'")
            new = GENERATORS[name](root)
            if new != m.group(3):
                stale.append(f"{doc}: generated section '{name}' is out of date")
            return m.group(1) + new + m.group(4)

        updated = BLOCK.sub(fill, text)
        if not check and updated != text:
            path.write_text(updated, encoding="utf-8", newline="\n")
    return stale


def main():
    check = "--check" in sys.argv[1:]
    stale = sync(check)
    for line in stale:
        print(line)
    if check and stale:
        sys.exit("run: python -I _tools/sync_docs.py")
    if not check:
        print(f"rewrote {len(stale)} section(s)" if stale else "generated sections already up to date")


if __name__ == "__main__":
    main()
