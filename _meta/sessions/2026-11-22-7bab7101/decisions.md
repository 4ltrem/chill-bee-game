---
session: 7bab7101-7147-4af4-9b37-f588cab77889
dates: 2026-11-22 to 2026-11-22
transcript: session.jsonl (this folder, gitignored)
description: A7 brief and new course dates; spec item 15 (Shop in both zooms) built, its tests diagnosed and fixed, C15/T15.1 accepted on a green full suite
---
# Decisions: session 7bab7101 (2026-11-22 to 2026-11-22)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D257 · 2026-11-22 · Records & deliverables · A7 is due 11/29 with a run video and a 20-page audit; the final moves to 11/29
- Decided: the designer pasted the A7 assignment text. A7 is due 2026-11-29 at 11:59 PM ET (10 points), not ~11/19: (1) a playable link a stranger can play within 2 minutes with no setup (a missing or broken link caps the whole assignment at 50%); (2) the pipeline repository, a screen-recorded pipeline run video, the engine (Godot) and how agent output lands in a scene without manual reformatting; (3) a pipeline audit and cost analysis of more than 20 pages. The final project also moves to 2026-11-29 (designer). A6 was submitted on 11/22.
- Why: MILESTONES.md had A7 at ~11/19 and no video or page count; the 2-minute gate puts weight on a first-time hint.
- Files: `MILESTONES.md` (A7 row, final row, Open "A7 brief"), `_meta/memory/course-milestones.md`

### D258 · 2026-11-22 · Cost & structure · The budget guard was overridden for one hour to build item 15
- Decided: the designer ran `budget_guard.py --allow-for 60` so Patricia and Quinn could run, after the guard paused the run (week at 26% with 9% gone, more than 10 points ahead of pace).
- Why: item 15 is the last open feature of 0.2 before the A7 build.
- Files: `_tools/budget_guard.py`

### D259 · 2026-11-22 · Pipeline design · After two failed fix rounds the orchestrator diagnoses before another round
- Decided: when goal_agent stopped `waiting-designer` on T15.1 (2 of 3 tests red, both agents guessing), the designer chose "I diagnose, then 1 fix" over two more automatic rounds, then "one more diagnosis" over accepting the gap or dropping the zoom-end exit. The orchestrator read the code, briefed Quinn on one cause (stray `_mk_main()`), made the two timing fixes in `game/tests/test_shop_zoom.gd` itself, and used a one-line `diag:` failure message to find the last cause. Recorded with `goal_agent.py --accept T15.1` (L47).
- Why: the fix rounds' replies said "I'm guessing" and ran nothing; reading the state machine (`main.gd` Zoom enum, `honeycomb.gd` `_check_frame_done`) was cheaper than another 800k-token round.
- Rejected: rerun goal_agent's automatic rounds; accept with the zoom-end exit unverified; drop that exit from the test.
- Files: `game/tests/test_shop_zoom.gd` (`f42034a`, `7616d20`), `game/scripts/main.gd` (`back()` closes the sheet first), `_meta/learnings.md` L47

### D260 · 2026-11-22 · Pipeline design · C15 accepted on the green checkpoint suite
- Decided: C15 (Shop in both zooms) accepted with `goal_agent.py --accept C15` after `godot_run.py all --time-scale 6 --skip-x1` passed (unit 209, play 246, measure 18, snapshot 12, ui 13, touch 4, start PASS).
- Why: goal_agent leaves a built change at "waits on tests" until the full suite is green, as with C14.
- Files: `game/reports/_runs/20261122-011146/`, `game/reports/goal/0.2/blackboard.md` (`9aadc61`)

## Still open

- **A7 (due 11/29, with the final):** 0.2.1 build and itch upload (each needs a yes) passing the 2-minute stranger gate (a first-time hint?); the pipeline run video (the designer records it); the audit of more than 20 pages from `_meta/agent-runs.md`, `_meta/learnings.md` and the write-ups (M4 rows can come from `_meta/drafts/0.2/`). Tag `v0.2.1` once played.
- **Play-test item 15:** open the Shop in the first zoom and at the second stop, buy, leave the zoom with the sheet open.
- **`godot_run.py` `start` suite** prints PASS but exits 1: the runner reports "no total line" for it (`game/reports/_runs/20261122-011146/`).
- **L47 prevention:** fix-round briefs to ask for a `diag:` line instead of a guess; `checkpoint.py` labels "(unit green)" from the last full run even when the newest run is red.
- **C14** still shows "partial (built, waits on tests)" in the goal scan though it was accepted on 11/21.
- **`t_icons_never_overlap`** now only asserts 0 icons at the second stop (D240): confirm, or ask Quinn for a stronger check.
- **Operator items still open:** item 7's tail (only `ui_compare_shots.gd` reads `--set` overrides; `run_tests.gd` and the windowed suites don't); item 23's plan count (C14, CFG and T.1 not listed).
- **The side pane** (`claude --plugin-dir _tools/live-pane`) has not been loaded in a real session.
- **Roadmap** (`proposals/design/roadmap.md`): questions 3 (watering) and 5 (Connie timing) open; re-layer to build-from-start r2.
- **0.3.0 UI pass:** ui-screens decisions 2-4 and the skin; canvas boards 2-3 redrawn for Shop + Tools.
- **First `/dream` pass** (D231): the six preferences (A1), the memory cleanup (A2), the `rex-runs-scripts` wording.
- **Operator, Phase 5 proper:** one real multi-step job through `claude --agent operator`, compared with an Opus session (D233).
- **Mutation 25** (second crank dead) still missed: a test for Quinn.
- **Transcripts of 11/20-11/21** were exported but not re-read for that log; D234-D248 come from the handoff.
- **Fast tests as the default (L17):** whether plain speed becomes opt-in is not decided.
- **GitHub repo visibility for A5/A7:** if `4ltrem/chill-bee-game` is private, the grader needs access.
- **Web build browser check:** the smoke shot is still the loading spinner; the real-time wait fix is approved but not built.
- **Item 19 refill speed:** overflow drains back at up to twice the fill rate (the assistant's choice; the GDD is silent). Say if you want the normal rate only.
- **spec_lint warnings** in `0.1.4-ui-placement.md`: T.1/T.2/T.3 ties; reword or confirm.
- **Guide playtest briefs** (D143): briefs for Patricia (a guide switch) and Gerard; playtest Melli, Pip, Lumi, Lady Aura, Miel and Reine Maeve.
- **Onboarding guide** (D125, D144): `ONBOARDING.md` is a draft at the repo root, untracked on purpose; fill Team Tips and Get Started, or drop it.
- **Google activity analysis** (D156): waiting for your Takeout export.
- Run `style_critic_check.py` with Vera's new scores (D101).
- The farm ground is 18 x 18, so the zoom shows no sky around the diorama; about 14 x 14 would bring the floating look back.
- `content/biome-intros.md` (re-run 3 passed) and `content/onboarding-script.md` need the designer's approval; onboarding needs the new harvest flow (D154) and the six guides' lines.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
- Harvest TBDs: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost, automation costs.
- Carried from revision 3: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: add D192's three read-anywhere lines to `.claude/settings.local.json`.
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
