---
session: 5fc31e3f
dates: 2026-11-22 to 2026-11-22
transcript: session.jsonl (this folder, gitignored)
description: the crew's game programming patterns guide (game/PATTERNS.md, 5fdec1b); logged after the fact on 2026-11-23 from `_tools/session_digest.py`
---
# Decisions: session 5fc31e3f (2026-11-22 to 2026-11-22)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

Logged on 2026-11-23, after D269, so the ID is later than its date (19:57 Toronto on 11/22; the folder is named by the UTC date).

## Decisions

### D283 · 2026-11-22 · Workspace & agents · The code crew reads a game programming patterns guide
- Decided: "let's upgrade the crew using this resource https://gameprogrammingpatterns.com", then "commit it": `game/PATTERNS.md` summarises the book in the workspace's own words with chapter links; Patricia reads State, Observer and Type Object (and any section her task touches, adding no pattern the spec doesn't need), Bob Flyweight and Component, Quinn State, Command, Update Method and Object Pool when profiling, Gerard Type Object and offline catch-up; `game/CONTEXT.md` lists it.
- Why: shared vocabulary for the code agents; the next goal run shows whether Patricia's code changes.
- Rejected: changing the content crew (the book is about code).
- Files: `game/PATTERNS.md`, `.claude/agents/programmer.md`, `.claude/agents/builder.md`, `.claude/agents/qa-build-engineer.md`, `.claude/agents/gameplay-architect.md`

## Still open

- None.
