---
session: 472d224a-a84f-4a66-bfff-00b669226a91
dates: 2026-11-05 to 2026-11-05
transcript: session.jsonl (this folder, gitignored)
description: Usage check at 86% of the 5-hour window, end of day, and a learnings-file backlog item
---
# Decisions: session 472d224a (2026-11-05 to 2026-11-05)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D92 · 2026-11-05 · Records & deliverables · A learnings file goes on the backlog
- Decided: add a learnings file to the to-do list: everything that broke, how it was noticed and how it was fixed. Not started; the rest of the day's work is saved for tomorrow.
- Why: the 5-hour window was at 86% (budget guard already blocking agents), so the designer ended the day; the breakages so far (Quinn's hour-long mutate run, the run that hit the 5-hour limit, the red 0.1.3 step b, stray Godot processes) are scattered across session logs and memories.
- Files: `_meta/memory/future-tbd.md`

### D93 · 2026-11-05 · Cost & structure · Day ended with 14% of the 5-hour window left
- Decided: end the work day instead of resuming 0.1.3 step b (Bob, then Quinn and a full test run), which waits for a fresh window tomorrow.
- Why: two agents plus 6-7 minutes of tests would likely hit the 5-hour limit partway, as a run did earlier today.

## Still open

- Unit-suite speed-up via `Engine.time_scale` (D91): brief Quinn; check against the 0.1.3 worktree first.
- Budget guard (`_tools/budget_guard.py`): the designer thinks the 80% block on the 5-hour window should be adjusted (it blocked agents with 22% left, while the end-of-day routine needs ~5%). Pick the new threshold or an end-of-day exemption.
- Session d82fcc79 changed after its end-of-day commit (re-exported today); check whether it holds decisions not yet logged.
- Review Bob's M2 layout changes before merging `milestone/m2`: the Harvest tag is 240 x 120 with 32 px text, the disabled Upgrade button is drawn shorter, the spin hint moved up, the uncapping-zoom framing shifted, and hive walls, floor and jar lid are 0.05 thick (round-3 shots in `game/reports/style/farm-0-1-2/round-3/`). They overlap the 0.1.3 scene edits.
- `content/biome-intros.md` went back to draft after the voice-loop revise (Clara's T6 check) and needs the designer's re-approval; `STYLE_GUIDE.md` also changed one word ("five checks" to "six"), which the designer has not seen.
- **0.1.3 step b is mid-build and red** in `.claude/worktrees/0.1.3` (WIP commit on `milestone/0.1.3`): Patricia's hive scale and config keys are in; Bob's layout port and Quinn's `test_layout.gd` were stopped part-way. Unit run 107/117: three old tests need the new spec values (`min_cell_px` 20, hive 1.4x), seven lid, crate and jar tests to re-check once Bob's layout is in. Resume Bob, then Quinn with `godot_run.py all --refresh`.
- 0.1.3 step c: the two camera stops, the shared lid-lean component, the second-stop HUD, and M2's open V7 row (bucket fills the bottom-right third, a wood slab cut off at the left). Then delete the `ab-centrifuge` worktree and its branch.
- Stray Godot processes from the test runs (flower-patch worktree and 0.1.3); Quinn was not allowed to stop them.
- Flower-patch tail (other session): `flower_patch.gd` blossom colour, Bob promotes B, then patch y to 0 after 0.1.3 merges.
- Merges: `milestone/m2` and `milestone/0.1.3` into `milestone/0.1` / `main` once played.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
- `content/onboarding-script.md`: narrative and onboarding come later; it needs the guide signature-lines revision and the new harvest flow.
- Guide character playtest: Melli, Pip, Lady Aura or Miel (D46).
- Harvest TBDs: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost, automation costs.
- Carried from revision 3: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- Content follow-ups: a Sunny Meadow flower for the bumble bee visitor (then Journal Entry 3); name Glowbell and Skybloom in `content/biome-intros.md`; the "sweat name" wording.
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- Push: `main` is ahead of GitHub; push only when the designer says so (D45).
- `build.py` smoke wait was raised to 100 s and is untested.
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: `git pull`, install or update the `claude` CLI, then the first "end of work day" there sets up its memory folder and the commit gate.
- Learnings file (D92): one record of everything that broke, how it was noticed and how it was fixed; decide where it lives and whether it is kept by hand or built from the decision logs.
