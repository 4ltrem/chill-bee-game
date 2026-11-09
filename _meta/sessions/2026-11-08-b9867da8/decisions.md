---
session: b9867da8-56c5-46c4-be16-555664edcdf8
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: an empty session (title only, no messages); nothing decided
---
# Decisions: session b9867da8 (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

No decisions were made in this session (an empty session (title only, no messages); nothing decided).

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
