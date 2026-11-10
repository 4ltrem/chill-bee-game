---
name: session-handoff
description: "Where work stands (2026-11-10): 0.2.0 play-tested; 0.2.1 specced (items 9-14, 21/34 goals) and ready to build once the budget guard allows; roadmap + build-from-start-r2 proposals answered, awaiting acceptance; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 3c5a9003-bd51-4155-8369-edf76b12f3b2
  modified: 2026-11-10T06:22:03.348Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Setup:** main folder on `milestone/0.2`; end-of-day ran 2026-11-10 (D200-D212, all 11/09-10 work committed). No worktrees.

**Budget (D212):** weekly 81% at 38% of the week (reset Sat 11/14 9:00 Toronto). Done 11/10: mutation rerun (same result; cause of the crash found: `mutate.py` copies only `game/`, the Journal test needs `../_tools/journal_csv.py`), pick-match vote section added then removed at the designer's request (D217: no vote rounds for play-tested models), roadmap Q2 and Q4 answered (D214-D215), build-from-start-r2 ACCEPTED and applied to the GDD as "from 0.4" (D216; zoom 1 frames only centrifuges in the 1-2 tile close zone, camera computed at runtime). Roadmap still needs re-layering to r2 §2.8 and questions 3, 5. `mutate.py` fixed (D218, L35): Journal mutations now CAUGHT; mutation 25 (second crank dead) still MISSED, Quinn's test after the reset. The 0.2.1 build waits for the reset. A6 is due Nov 22 (designer 2026-11-10), after the reset.

**0.2.1 = 0.2.0 play-test fixes** (spec `game/specs/0.2-first-automation.md`, lint clean, `goal_agent --plan` 21/34):
- 9 Spin alone pans to the second stop (drop `_filled_in_zoom`/`_closing_to_second` pan in `main.gd`; replace the `test_camera.gd` full-bucket pan check).
- 10 fork prop hides on any release and returns into the Harvest icon (`fork_return_seconds` 0.35); cause: `honeycomb.gd` misses the release once inactive.
- 11 lid stays still; `Crank` turns on its pivot, Gear1 follows it, the rest from Gear1 (today `centrifuge.gd` rotates the whole `Lid`).
- 12 Spigot Flow shop row ($30, 1.20×, max 5, −12%/level bottling; placeholders, Terry checks before 0.3.0).
- 13 truck waits for in-flight bed jars before leaving (Sell and Auto-Sell).
- 14 shop shows all 7 rows, no scroll (reopens C1).
- Build: weekly budget ~78% at 37% of the week; the designer must run `python -I _tools/budget_guard.py --allow-for 60` first. Then `/goal` + goal_agent; version 0.2.1; itch upload of 0.2.1 as the A7 link (due 11/19).
- Designer didn't answer whether to also lower base `bottling_seconds_per_jar` (3.0); Spigot Flow was the chosen fix.

**Versions (MILESTONES, designer 2026-11-09):** 0.2.x = play-test fixes; 0.3.0 (11/24) = first UI pass for existing features (needs ui-screens decisions 2, 3, 4 and the skin first; bottom slot A with B-D in Dev) + M5 items; 0.4+ = roadmap.

**Proposals awaiting the designer's acceptance** (answers recorded in each file; GDD edits only after acceptance):
- `proposals/design/roadmap.md` (Gerard): 51 rows, layers 0.4-0.14 + post-launch. Questions 2 (number-only TBDs don't hold a milestone), 3 (watering), 5 (Connie timing) still open; question 1 answered by build-from-start. Needs re-layering to r2 (Build mode = 0.4, vertical slice moves later).
- `proposals/design/build-from-start-r2.md` (supersedes `build-from-start.md`): Build mode from the start in 0.4; start = hive + truck (queen's leftover magic), starting money builds the centrifuge, then crate; raw comb fallback; ground jars before the crate; free grid, centrifuge within bee range of a hive (range = Flight Endurance); centrifuge tiers replace in place; bee carry (FE = range+speed, Swarm = rate, no fill cost); two zones (close: cells fly to centrifuge pile; farther: hive pile + bees); split across centrifuges in range; free moving; automation per farm + flat install fee; post-launch BeeTech conveyors give freed bees a bonus. Before the 0.4 spec: Terry, Bob's zoom ceiling, William's lore text, Ruth/William raw-comb price check.

**Still open from before:** Quinn's mutation fixes + `mutate.py --since 48afcd8` rerun (mutation 25 MISSED, 45 BROKEN, crash on `_tools/journal_csv.py`); Spec Review shots to Design Votes (shop list, Journal EN/FR; pick matches for fork, gears, truck); M3 cap-stop summary in `generate.py`; A5 link (11/15); A6 fixes; UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca.

**Rules:** questions to the designer go in AskUserQuestion with a preview on every option ([[ask-with-quiz-tool]]); Gerard has no Edit and the hook blocks his rewrites, so revisions are new `-rN` files and the orchestrator rebuilds `_index.md`; [[spec-consistency]], [[rex-runs-scripts]], [[test-speed-fixes]], [[fix-needs-commit]], [[edit-lines-only]].

**How to apply:** keep CLI replies short. At the end of each session, rewrite this file to the new current state.
