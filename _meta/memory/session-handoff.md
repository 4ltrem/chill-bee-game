---
name: session-handoff
description: "Where work stands (2026-11-09 night): 0.2 models session DONE (fork-r4-c, gearing-r3-a, truck levels picked); next = 0.2 implementation session: write picks into spec items 3-5, designer approves, /goal + goal_agent; A6 fixes in parallel; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: f6f4c6c0-43ee-4483-9665-cc6335d16443
  modified: 2026-11-09T20:38:37.134Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Setup:** main folder on `milestone/0.2` (local `main` is stale at `ad1cae9`; fast-forward it before the next merge). Models session checkpointed as `7bc4316`; fork-r4 and the final decisions in the commit after it. End-of-day for 2026-11-09 has NOT run. No worktrees.

**0.2 models session: done (2026-11-09).** Picks (each in `game/reports/variants/<prop>-r<N>/decisions.json`):
- Uncapping fork: `game/scenes/variants/fork-r4/fork-r4-c.tscn` (cold) and `fork-r4-c-hot.tscn` (full pulse: whole metal head, tines + crossbar + ferrule, in crank orange; the handle stays wood).
- Centrifuge Gearing: `gearing-r3/gearing-r3-a1.tscn` / `-a5.tscn` (notched steel gears, dark hubs, shrinking arc, crank arm resting on Gear1; the Crank node is raised 0.095).
- Truck flames, **one look per Faster Delivery level**: L1 `truck-flames-r3/…-l1` (exhaust pipes only), L2 `truck-flames-r1/…-a`, L3 `truck-flames-r1/…-b`, L4 `truck-flames-r3/…-l4` (decals + pipes + roof flames). Rule: no flames from the exhaust at any level.
- Later: a "wider fork" upgrade (look `fork-r1-c`) is in README TBDs.

**Next: 0.2 implementation session.** `game/specs/0.2-first-automation.md` is still **status proposed**. Write the picks into items 3–5 (item 5 changes from "flames from level 1" to a look per level; Quinn's item 5 look test becomes per level, Bob's promotion per level), keep [[spec-consistency]], designer approves, then `/goal` + `goal_agent.py` builds (condition: `goal_agent.py SPEC --plan` reports nothing left and the latest unit run is green). Open for the designer before Bob promotes: STYLE_GUIDE names no role for the fork's materials (Metal/Wood/Accent lists), and V3's "each accent on one object" vs. crank orange on several parts of one prop (fork head, truck flames).

**New tooling (2026-11-09):** `_tools/compose_variant.py` builds recombination rounds with no agent ([[compose-variants]]); Milo's parts convention is in `.claude/agents/modeler.md`. `checkpoint.py` failed silently once this session (files staged, no commit); the commit was made by hand; check why before relying on it.

**UI design:** read `UI_DESIGN.md` first ([[ui-design-prefs]]). Canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca; proposal `proposals/design/ui-screens.md` (proposed). Not in any spec yet. Ask before the next UI round whether UI A/B choices move to Design Votes ([[ab-comparison-page]]).

**A5:** designer still to submit the link (due 11/15): itch link + `GOAL_AGENT.md` as the README.

**A6 fixes (due 11/22; MILESTONES says 11/12, fix it):** the course brief bans binary pass/fail and designer intervention.
- Clara (`.claude/agents/content-critic.md`) only gives PASS/FAIL: give her per-check scores 0–10 with a reason, like Vera's Scores table.
- `style_loop.py` stops for the designer on "(designer)" rows: for the graded run, the loop picks the option the guide favours, logs why, and lists the choice for review after the loop ends.

**Rules:** all scripts go to Rex ([[rex-runs-scripts]]) with the fast env vars ([[test-speed-fixes]]); [[fix-needs-commit]]; [[look-before-done]]; [[edit-lines-only]]; a fresh session per milestone ([[cost-rules]]).

**How to apply:** keep CLI replies short. At the end of each session, rewrite this file to the new current state.
