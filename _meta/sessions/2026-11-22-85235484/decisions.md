---
session: 85235484
dates: 2026-11-22 to 2026-11-22
transcript: session.jsonl (this folder, gitignored)
description: why development slowed: the edit-only rule kept, four goal-agent stops made defaults (61dec0a), layout from the Claude Design canvas; the A7 audit draft; logged after the fact on 2026-11-23 from `_tools/session_digest.py`
---
# Decisions: session 85235484 (2026-11-22 to 2026-11-22)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

Logged on 2026-11-23, after D269, so these IDs are later than their dates.

## Decisions

### D279 · 2026-11-22 · Pipeline design · Goal-agent stops that need no decision become defaults
- Decided: the designer asked whether the edit-only rule slowed development (answer: no, it prevents hidden rewrites; the stops do), then "yes, make all four changes": placeholder mode for visual numbers (`visuals: placeholder` in a spec), V11/V12 minimums applied without asking, no stop on a `(designer)` row with no question, and mutation `--since` from the ledger with stale `find` strings as a warning. Also: "for the layout design question I told it to use the design we made in claude design": briefs take placement from the canvas boards (`LAYOUT_RULE`), asking only when no board covers it. Built in `61dec0a`; about 9 of that day's 17 stops would have defaulted.
- Why: designer stops, not tool limits, were what slowed the build.
- Rejected: loosening the edit-only rule.
- Files: `_tools/goal_agent.py`, `_tools/test_goal_agent.py`

### D280 · 2026-11-22 · Pipeline design · The local Shop board follows the canvas as drawn
- Decided: "yes, refresh the shop board from the canvas"; asked whether 0.3's Shop follows the board (sheet 84 px below the top, five tabs) or the T4.1 note (full height, 8 rows), the designer picked "Board as drawn". The tabs were left to 0.3.1 so the live 0.3 run kept its spec (D262).
- Files: `proposals/design/ui-screens-mockup/project/Shop.dc.html`, `_meta/drafts/0.3/spec-edits-after-run.md`

## Still open

- None from this session; the A7 audit draft it started is tracked in D267-D268.
