---
session: 81c6a13d-f79a-4428-bc66-986f58e5b2ff
dates: 2026-11-07 to 2026-11-07
transcript: session.jsonl (this folder, gitignored)
description: M3 goal agent built and run on 0.1.4; votes rule, live-view idea, play-test feedback into the spec
---
# Decisions: session 81c6a13d (2026-11-07 to 2026-11-07)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D117 · 2026-11-07 · Pipeline design · Build M3 (the goal agent) now and run it on 0.1.4
- Decided: The designer set the goal "implement m3 and what is in the session handoff". `_tools/goal_agent.py` was built with its fixture tests, `--plan` and `--dry-run`, then run on the 0.1.4 spec: the handoff goal first, then the changes and Quinn's test lines, stopping on questions that need the designer (C5 frame size).
- Why: 0.1.4 is the A5 demo, and the goal agent is the demo's subject (the designer later called it "the next demo I'll allow").
- Files: `_tools/goal_agent.py`, `_tools/test_goal_agent.py`, `GOAL_AGENT.md`, `game/specs/m3-goal-agent.md`

### D118 · 2026-11-07 · Records & deliverables · Every numerical visual change gets a section on the Design Votes page
- Decided: For any visual change decided by a number (scale, offset, margin, size) the designer needs a picture to judge, so it becomes its own section of the one Design Votes page, built by the existing scripts (`ui_shots.py` or `model_shots.py`, then `compare_page.py add`). Recorded in the handoff for a later session.
- Why: "It's hard for me as a human to decide without a visual."
- Files: `_meta/memory/ab-comparison-page.md`, `_meta/memory/session-handoff.md`

### D120 · 2026-11-07 · Workspace & agents · A live view of headless agents goes on the future upgrades list
- Decided: Since the orchestrator scripts run agents headless, the designer can no longer see which are running. Of the assistant's three options (a `live.json` shown in the status line, live per-agent logs, a side panel) the designer asked to note them on the future upgrades list, in that order, to build after the shared board format lands.
- Files: `_meta/memory/future-tbd.md`

### D121 · 2026-11-07 · Game build · 0.1.4 item 8: the instruction text moves below Back
- Decided: Play-test feedback: Back overlaps the instruction text at the top. The text (`HintLabel`) is lowered below Back's rect in the first zoom and at the second stop; Back stays in the top-right corner. Written as item 8 with a line for Bob and a test line for Quinn.
- Files: `game/specs/0.1.4-ui-placement.md`

### D122 · 2026-11-07 · Records & deliverables · The Design Votes contact sheet takes the full row and opens at full size
- Decided: The combined "sheet" image on the votes page was too small (a shared 9:16 card box squeezed it). It keeps its own proportions, takes the full row width and opens full size in the lightbox; older pages are upgraded by `add`.
- Files: `_tools/compare_page.py`, `_tools/compare_page_head.html`

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
