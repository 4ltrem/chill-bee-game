---
name: session-handoff
description: "Where work stands (2026-11-15): 0.1.4 merged to main and play-tested; A5 write-up (GOAL_AGENT.md) approved with the itch link; M4 / 0.2.x (A7, due 11/18) upgrades and first Journal entry built on the other machine, not pushed yet: pull first; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 024e82ee-6bf4-4dd0-9a6a-b84d6cefbdf2
  modified: 2026-11-15T23:50:00.000Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Setup:** main folder on `main`, last commit `739b51c`. No other worktrees; `milestone/0.1.4` is merged (`6e22681`) and still on origin. Uncommitted: `_meta/agent-runs.csv/.md` (one new orchestrator run row, left for end-of-day). End-of-day for 2026-11-08 ran (`fe23e98`: D170-D199, L17-L24); end-of-day for 2026-11-15 has not run ([[end-of-day-routine]]).

**0.1.4 / A5: done.** The designer play-tested 0.1.4 and it was merged into main. `GOAL_AGENT.md` (the A5 write-up: 38/38 goals, 95 calls, 23.8M tokens) was approved as the A5 README (`739b51c`). Web build is on itch: 4ltrem.itch.io/chill-bee-game (0.1.4). Whether the A5 link was submitted to the course is the designer's step, not recorded here ([[demo-link-submissions]]).

**Next: M4, 0.2.x "First automation" (A7, due 2026-11-18)** per `MILESTONES.md`: built by the M3 agent; a few Tree A/B upgrades (Flight Endurance, Centrifuge Gearing, Heated Fork) and one automation step (the self-driving truck, GDD Phase 2); plus one approved Bee Journal entry (EN/FR) in Godot's translation CSV shown in-game. 0.2.0 goes to itch ([[itch-upload-rule]]). **Built on the designer's other machine (designer, 2026-11-15): Flight Endurance, Centrifuge Gearing, Heated Fork, the truck upgrades and the first Bee Journal entry. Not pushed: `origin` has only `main` (`739b51c`) and `milestone/0.1.4` as of 2026-11-15.** Before any M4 work here, push it from the other machine and pull; don't rebuild those items. Still unknown: whether the self-driving truck (the automation step) is in, and whether 0.2.0 went to itch; check after the pull.

**M3 cap-stop summary (2026-11-15, this machine, committed on main, not pushed):** `_tools/generate.py` `cap_stop()`: on a token-cap stop the Result and console list the last verdict's open FAIL rows with owner (Ruth for a Facts source row on a researched run, else William) and the `--revise` re-run command; 2 new tests, `test_generate.py` 63/63. If the other machine also built it, keep one on the pull.

**Still open from before:** content approvals in [[pending-approvals]] (onboarding-script, biome-intros re-approval); test runs use the fast env vars ([[test-speed-fixes]]).

**Rules:** all scripts go to Rex ([[rex-runs-scripts]]); don't kill the designer's running game; [[fix-needs-commit]]; [[look-before-done]]; [[edit-lines-only]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
