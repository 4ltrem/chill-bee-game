---
session: {full session id}
dates: {first day} to {last day}
transcript: session.jsonl (this folder, gitignored)
description: {one line: what this session worked on}
---
# Decisions: session {first 8 of id} ({first day} to {last day})

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D{n} · {YYYY-MM-DD} · {Topic} · {Title}
- Decided: {what}
- Why: {why}
- Rejected: {alternatives turned down, or omit}
- Files: `{path}`, `{path}`

## Still open

- {each item the designer still has to decide}
