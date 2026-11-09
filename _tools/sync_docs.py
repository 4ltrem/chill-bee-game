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
frontmatter, and the run summary in `_meta/agent-runs.md` from `_meta/agent-runs.csv` (runlog.py
rewrites it whenever a run is logged). _tools/consistency.py checks the facts that cannot be generated. Standard library only.
"""
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
DOCS = ["CREW.md", "_meta/agent-runs.md"]  # files that hold generated sections
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


def run_summary(root=None):
    """Per task type: runs, and averages of each measure, by agent and phase, from the run log CSV."""
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import runlog
    rows = runlog.read(root)
    avg = lambda vals: f"{round(sum(vals) / len(vals)):,}" if vals else "—"
    ints = lambda group, k: [int(float(r[k])) for r in group if r.get(k)]
    out = [f"{len(rows)} runs in [agent-runs.csv](agent-runs.csv). Averages by agent and phase; "
           "each measure averages only the runs that have it (— where none do).", ""]
    tables = list(dict.fromkeys(r["table"] for r in rows))
    for table in tables:
        group = [r for r in rows if r["table"] == table]
        out += [f"**{table}** ({len(group)} run{'s' if len(group) != 1 else ''})", "",
                "| Agent | Phase | Runs | Final context | Total processed | Duration |", "|---|---|---|---|---|---|"]
        for key in dict.fromkeys((r["agent"] or r["run"], r["phase"]) for r in group):
            g = [r for r in group if (r["agent"] or r["run"], r["phase"]) == key]
            secs = ints(g, "duration_s")
            out.append(f"| {key[0]} | {key[1]} | {len(g)} | {avg(ints(g, 'final_context'))} | "
                       f"{avg(ints(g, 'total_processed'))} | {avg(secs) + ' s' if secs else '—'} |")
        if len(g) != len(group):  # more than one agent: the whole table's average too
            secs = ints(group, "duration_s")
            out.append(f"| **All** | | **{len(group)}** | **{avg(ints(group, 'final_context'))}** | "
                       f"**{avg(ints(group, 'total_processed'))}** | {avg(secs) + ' s' if secs else '—'} |")
        out.append("")
    return "\n".join(out)


GENERATORS = {"crew-agents": crew_agents, "run-summary": run_summary}


def sync(check=False, root=None):
    """Rewrite (or, with check, only compare) every generated section; return the stale ones."""
    root = root or ROOT
    stale = []
    for doc in DOCS:
        path = root / doc
        if not path.is_file():
            continue
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
