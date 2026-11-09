---
session: b89522de-aba2-47a2-852d-34d76b9bf1f3
dates: 2026-11-07 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: second 0.1.4 goal run, harvest-flow rules, items 11-15, look-before-done, the repeat-failure fixes
---
# Decisions: session b89522de (2026-11-07 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D148 · 2026-11-07 · Cost & structure · Designer overrides the budget guard in 60-minute steps to run the goal agent
- Decided: The guard paused the goal agent before C5's fix round (weekly usage 23% with 8% of the week gone, more than 10 points ahead of pace). The designer went ahead, and renewed it with `budget_guard.py --allow-for 60` when it ran out (11/7 23:37, 11/8 00:53, 01:19). Advice kept: a `!` command with a leading space reaches the assistant as a message instead of running.
- Files: `_tools/budget_guard.py`

### D149 · 2026-11-07 · Game build · Play-test: Spin goes to zoom 2; the centrifuge never spins in the farm view (items 11, 12)
- Decided: The combs do not fill the frame and a hive side is missing (a fix to item 5); the Spin button brings the camera to the second zoom stop and starts spin mode there; the centrifuge cannot spin in the farm view, and not in phase 1 of the game (the designer confirmed "stage 1" meant phase 1) or without the electric centrifuge upgrade.
- Files: `game/specs/0.1.4-ui-placement.md` items 5, 11, 12

### D150 · 2026-11-07 · Workspace & agents · `_tools/watch.py` approved: a live window in a terminal split
- Decided: Asked how to open the live window (only the status-line part existed), the designer approved adding `watch.py` to the list: one line per tool use of a running agent. Marked approved as item 5b.
- Files: `_meta/memory/future-tbd.md`

### D151 · 2026-11-07 · Cost & structure · Parallel test runs go on the list
- Decided: The designer asked why tests do not run in parallel in several game windows. The scripts were written one at a time (`godot_run.py` loops its suites; `mutate.py` reuses one game copy). Parallel runs go on the list after `watch.py`; the assistant corrected itself: mutations already take about a minute, the gain is in the 6-7 minute `all` run.
- Files: `_meta/memory/test-speed-fixes.md`

### D152 · 2026-11-07 · Game build · Item 13: the centrifuge helper text follows the centrifuge
- Decided: The helper text must stay on top of the centrifuge, not locked to a screen position (`CentrifugeLabel` was fixed at (24, 245)); it follows the centrifuge like Harvest, Spin and Sell.
- Files: `game/specs/0.1.4-ui-placement.md`

### D153 · 2026-11-07 · Pipeline design · C5 stop: tighten the loose UI-bounds test, not the game
- Decided: The goal agent stopped on C5 with one test left failing (`t_dev_show_ui_bounds` counted every visible item in the game). Of the assistant's options the designer picked 1: the test counts only the outline overlay's own items. C5 committed as 6a76e7d.
- Files: `game/tests/test_dev.gd`

### D154 · 2026-11-07 · Game build · Harvest flow: no spinning from the farm view; re-tap Spin to return
- Decided: After reviewing the harvest flow the designer decided: Spin always goes to the centrifuge view first, including a part-full bucket; leaving that view (Back or the pile running out) means tapping Spin again; Harvest stays hidden in the centrifuge view; Spin during the hive zoom leaves unscraped frames for the next Harvest ("both are fine, keep them as is").
- Files: `game/specs/0.1.4-ui-placement.md` items 11, 12

### D155 · 2026-11-08 · Workspace & agents · Live status must cover everything: script steps, `watch.py`, and a live pane
- Decided: The status line went blank while the goal agent ran its own checks (it only recorded agent calls). The designer: "I need everything visible, also the live pane". `live.json` records the scripts' own steps (test runs, mutations, shots, commits), plus `watch.py` and a side pane, all after the current run.
- Files: `_meta/memory/future-tbd.md` item 5

### D157 · 2026-11-08 · Game build · Items 14 and 15: rebuild the hive to match pick r9-a; no cranking after Back
- Decided: Play-test: backing out of the centrifuge still lets it spin, and the hive and frame models were changed. Item 14: rebuild `hive.tscn` from the picked variant (a deep box with four walls, five upright frames, the lid hinged at the back), with Bob comparing his render with the pick. Item 15: after Back from a crank, taps do not crank.
- Files: `game/specs/0.1.4-ui-placement.md` items 14, 15

### D158 · 2026-11-08 · Records & deliverables · The designer browser-checks the web build before the itch upload
- Decided: The smoke build's web screenshot is the loading spinner, so the web build is served at 127.0.0.1:8060 and the designer opens it in a browser; that check is the go-ahead for the itch upload.
- Files: `_tools/build.py`

### D159 · 2026-11-08 · Critic quality · Look before done: a model change is not done on tests alone
- What broke: The hive and frame models were changed wrongly for the second or third time, and the tests and style loop passed.
- How noticed: The designer played the build ("the style loop should've caught this").
- Decided: Never call a model change done on tests alone: compare a fresh shot with the picked variant before reporting.
- Files: `_meta/memory/look-before-done.md`

### D160 · 2026-11-08 · Pipeline design · Eight repeat-failure fixes, the first job of the next session
- Decided: Asked whether anything else could stop these failures repeating, the designer answered "all": pick match (a spec item naming a picked variant renders the result beside it and Vera judges only the match), one style round per Bob change, a failing-first test for every play-test fix, and tests that prove more (the Back-at-left-edge mutation could never fail). Also saved: check the spec for contradictions before adding a play-test item.
- Files: `_meta/memory/spec-consistency.md`, `_meta/memory/session-handoff.md`

### D164 · 2026-11-08 · Workspace & agents · Closing a session is not "end of work day"
- Decided: The designer said "time to close this session"; the assistant started the end-of-day routine, the designer stopped it: not done working, just moving to the next task. Nothing was logged, published or committed. Only "end of work day" runs the routine.
- Files: `_meta/memory/end-of-day-routine.md`

## Still open

- **A5 (due 11/15, 11:59 ET):** upload 0.1.4 to itch as the demo and submit the link; fill the RESULTS, MANUAL and COST sections of `GOAL_AGENT.md` for the later runs.
- **Goal agent bugs (block item 14 align):** `goal_agent` counts a new Quinn test line done when any test under the same item passes, because line IDs are positional (a new line takes T14.3 and pushes the lid test to T14.4); and `--goal` refuses goals that are already done.
- **Web smoke shot is black** (loading spinner only, even with the real-time wait): you browser-check the web build (`game/builds/chill-bee-game-0.1.4-web.zip`) before the A5 upload; the fix (a real-time wait) is approved but not built.
- **Comb hexes meet point to point** instead of side to side: likely the CylinderMesh corners on the ±Z axis against `honeycomb.gd`'s `cell_position`; the item 14 align rule (D169) and its test line are written, the build is not done.
- **spec_lint warnings:** `T.1` and `T.2` tie (no item named), and a REVIEW pair: items 11, 12 and 15 all touch Spin in the farm view; reword or confirm.
- **Build next (approved D168):** fix briefs that say "don't run the suite, the goal agent runs the checks" and a `--max-turns 15` cap on fix rounds, then `live.json` written by the scripts' own steps, `_tools/watch.py`, and the live side pane (D150, D155).
- **Parallel test runs** (D151): several Godot windows at once; after `watch.py`.
- **The eight repeat-failure fixes (D160):** pick match and one style round per Bob change are built (D163); the rest (failing-first tests, tests that prove more) are the first job of a later session.
- **Does the rebuilt hive match pick r9-a?** Compare `game/reports/ui-compare/0.1.4/3-zoom-hive.png` with `hive-frames-r9-a.png`; raised-frame comb size and the lid are item 14.
- **Guide playtest briefs** (D143): prepare the briefs for Patricia (a guide switch) and Gerard; see Decision 2 in `content/guides.md`. Playtest Melli, Pip, Lumi, Lady Aura, Miel and Reine Maeve.
- **Onboarding guide** (D125, D144): `ONBOARDING.md` is a draft at the repo root, untracked on purpose; fill Team Tips and Get Started, or drop it.
- **Google activity analysis** (D156): waiting for your Takeout export (2 GB, NotebookLM plus My Activity: Gemini, Search, YouTube) in Downloads.
- Run `style_critic_check.py` with Vera's new scores (D101).
- The farm ground is 18 x 18, so the zoom shows no sky around the diorama; about 14 x 14 would bring the floating look back.
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
- Budget guard: it holds heavy agents when weekly usage runs more than 10 points ahead of pace, and you have overridden it with `--allow-for` five times (D148, D167); decide whether the threshold is right.
- Session d82fcc79 changed after its end-of-day commit; check whether it holds decisions not yet logged.
- `content/biome-intros.md` back to draft after the T6 revise; needs re-approval, with the "five checks" to "six" word change in `STYLE_GUIDE.md`.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
- `content/onboarding-script.md`: needs the new harvest flow (D154) and the six guides' lines from `content/guides.md`.
- Harvest TBDs: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost, automation costs.
- Carried from revision 3: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- Push: `main` is ahead of GitHub; push only when the designer says so (D45).
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: `git pull`, install or update the `claude` CLI, then the first "end of work day" there sets up its memory folder and the commit gate.
- Learnings file (D92): one record of everything that broke, how it was noticed and how it was fixed; decide where it lives. Worked examples: D114 and D159.
- Old branches kept after merging (`milestone/m2`, `milestone/0.1.3`, `m2/flower-patch`, `ab/centrifuge-by-crate`): delete them, or keep them as history?
- Round 8's variant scenes were overwritten by round 9 before they were committed; only the renders survive (D166 prevents it from now on).
