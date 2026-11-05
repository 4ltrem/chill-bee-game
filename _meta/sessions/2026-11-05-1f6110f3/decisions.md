---
session: 1f6110f3-2e32-4646-b45d-481e3317ccea
dates: 2026-11-05 to 2026-11-05
transcript: session.jsonl (this folder, gitignored)
description: Why the 0.1.2 build lacks the 0.1.3 placement; 0.1.3 left to the other session; flower-patch B built on its own branch; handoff
---
# Decisions: session 1f6110f3 (2026-11-05 to 2026-11-05)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D88 · 2026-11-05 · Pipeline design · Flower-patch B is built on its own branch; ground placement waits for 0.1.3
- Decided: the designer asked for the M2 tail, flower patch B. It was built in the worktree `.claude/worktrees/flower-patch` on branch `m2/flower-patch` (commit fe2f237, not yet merged): `game/scenes/props/flower_patch.tscn` is variant B, `game/scripts/flower_patch.gd` colours each patch's blossoms and sizes it by radius, and the leaf green is its own `game/materials/leaf.tres`. Unit tests 110/110 and the comb-pop snapshot 12/12 passed. Putting the patches on the ground in `main.tscn`, registering Quinn's test and rendering shots wait until 0.1.3 is merged, so the two sessions do not collide in the farm scene. The designer first asked this session to build 0.1.3 as well; the other session (maigd-62) already owned it, so nothing was built here.
- Why: the 0.1.3 build edits `main.tscn` and the farm layout in its own worktree.
- Files: `game/specs/flower-patch-b.md`, `_meta/memory/flower-patch-followup.md`, `_meta/memory/session-handoff.md`

## Still open

