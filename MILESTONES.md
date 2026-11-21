---
author: designer
type: plan
status: approved
decided: 2026-11-04
decision: approved by the designer; A5 is due 2026-11-15, so M3 (target 11/14) stays after M2
description: Build milestones and version numbers for Chill Bee Game, fitted to the course deadlines (A7 ~2026-11-19, final game ~2026-11-24), then the road to the GDD's first playable
---
# Milestones

**Stages** (agreed with the designer, 2026-11-04): prototype (tests one question, thrown away or folded in) → **vertical slice** (the GDD's First Playable: one full rough run) → **alpha** (every launch feature in, GDD milestone 2) → **beta** (content locked, fixing and optimising) → **1.0** (launch).

**Version numbers:** `0.<milestone>.<build>` until launch, set in Godot's `application/config/version`; the Android version code rises by one with every exported build. Each milestone has its own specs (`game/specs/<milestone>-<feature>.md`), not one growing spec. Quinn's report names the version it tested.

| | Version | What it delivers | Course deliverable | Target |
|---|---|---|---|---|
| M0 | Prototype 0 (r1–r3) | the manual loop proven: harvest, bottle, sell, one upgrade | Assignments 1–4 already done (GDD, reviews, crew, content pipeline) | **done** 2026-11-04 |
| M1 | **0.1.x** "Harvest" | spec r4 (zoom, two-piece hive and centrifuge, flying cells, piles), the play-test fixes, and a **web export to itch.io** ([4ltrem.itch.io/chill-bee-game](https://4ltrem.itch.io/chill-bee-game)) | the playable-link pipeline, early | 2026-11-09 |
| M2 | tooling | **A6 style guide agent**: a written style guide (colorbox palette, shapes, proportions, UI rules) and a Generator → Evaluator → Refiner loop over Bob's scenes and screenshots, alongside Clara's narrative loop | Assignment 6 | 2026-11-22 |
| M3 | tooling | **A5 goal-oriented coding agent**: reads the GDD and the specs, scans `game/`, lists the missing features, scores them (value, dependencies, cost), picks an order, and runs the build process of `game/CONTEXT.md` (steps, contract check, parallel start, visual checks, snapshot tests, checkpoint commits) with fresh agent contexts, its reasoning on a blackboard | Assignment 5 | 2026-11-14 |
| M4 | **0.2.x** "First automation" | built **by the M3 agent**: a few Tree A and B upgrades (Flight Endurance, Centrifuge Gearing, Heated Fork) and one automation step (the self-driving truck, GDD Phase 2). **0.2.1** (designer, 2026-11-09): the 0.2.0 play-test fixes only, no new UI look: Spin alone pans to the second stop, the fork returns into the Harvest icon, no jar flies after a departing truck, faster jar filling, all shop rows shown with no scrolling (a stopgap until 0.3.0's Shop sheet); uploaded to itch as the A7 link | A7 deliverable 1 (playable link) and 2 (pipeline source and engine integration) | 2026-11-18 |
| — | A7 | deliverable 3: pipeline audit and cost analysis from `_meta/agent-runs.md` | **Assignment 7** | **~2026-11-19** |
| M5 | **0.3.0** "Course build" | the **first UI design pass** (`UI_DESIGN.md`, `proposals/design/ui-screens.md`), only for screens of features already in the game: floating icons over the farm with no nav bar, the Harvest fork meter, Back top-right and the Tools icon in the zooms, a Shop sheet replacing the panel, the Journal icon and screen, the new Spin and Sell look; bottom slot A with B–D switchable in Dev mode for the play-test. Needs first: the proposal's decisions 2 (icon placement), 3 (when icons appear), 4 (Tools icon) and the skin. Also adversarial QA and a balance simulation (class 11), polish, a minimal first-time hint so a grader can play unaided, the final itch.io build | **Final project** | **~2026-11-24** |
| M6 | 0.4–0.9 | after the course: grid expansion, the capstone and reset: the GDD's **vertical slice**; UI screens for features not yet built (Worlds, Royal Crystal, Store, Impact, Habitat & Refinery) arrive with their features. Placement of the rest of the GDD: Gerard's roadmap proposal (`proposals/design/roadmap.md`, requested 2026-11-09) | | no date |
| M7 | 0.10+ | alpha: Alpine Valley, Trees A–C, research, French, monetisation, backend, kid mode | | no date |

## Open
- M1: spec `game/specs/0.1-harvest.md` approved and its GDD §2 changes applied (2026-11-04).
- Uploads (designer, 2026-11-05): a build goes to itch.io only when a new milestone number is reached (0.2.0, 0.3.0); builds within a milestone are played locally. Exception (designer, 2026-11-06): an assignment's demo build also goes on itch (0.1.4 = the A5 demo).
- M1: 0.1.0 uploaded to itch.io and playing in the browser (designer, 2026-11-04); 0.1.1 play-test fixes in progress (`game/specs/0.1.1-playtest-fixes.md`).
- M2: built 2026-11-05 on `milestone/m2` from `game/specs/m2-style-loop.md` and the approved `STYLE_GUIDE.md`; write-up `STYLE_LOOP.md` approved by the designer (2026-11-05). Each assignment is submitted as a demo link, resubmitted after every milestone.
- M2 and M3 each need a new agent or tool (Martin for a style critic; a `_tools/` planner for A5); scoped when started.
- Budget: M1 and M4 are the costliest (Patricia, Bob, Quinn); check `_meta/agent-runs.md` daily.
- Assignment 3 grader's next steps (designer, 2026-11-08), scheduled:
  - **M3:** a cap-stop summary in `_tools/generate.py`. When a run stops at the token cap, the blackboard summary and the console line list the last round's open FAIL rows, the owner of each (William or Ruth) and the exact command to re-run. It is small tooling in the same scripts that M3's goal agent uses.
  - **M4 (0.2.x):** one approved Bee Journal entry (EN/FR) exported to Godot's translation CSV, loaded by `TranslationServer` and shown on one in-game screen, so "passed" becomes "in-game". This counts toward A7 deliverable 2 (engine integration).
- Assignment 4 grader's next steps (designer, 2026-11-17): **both built before the next `generate.py` content run** (any slug, new or `--revise`):
  - **Cheaper verification:** a scripted pre-pass for Clara's mechanical checks, a cheaper model for quote matching, Sonnet only for lore and tone; Ruth's fetched source quotes cached by URL and date so Clara reuses fresh ones instead of fetching every URL each round.
  - **Voice rules as hard checks:** T5 (each cited GDD section exists) and T2 (Glossary terms) checked by script before Clara, as `style_check.py` runs before Vera, so a FAIL costs no agent call. **Built 2026-11-17:** `_tools/voice_check.py`, run by `generate.py` each round; terms list `_tools/voice_terms.json` (its two seed entries, "coins" and "honey money", confirmed by the designer 2026-11-17).
- Onboarding stays deferred (designer); M5's hint is a stopgap, not the onboarding script.
