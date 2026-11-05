---
session: 4297b6fb-4f37-489e-a81b-e6e820fcf5da
dates: 2026-11-05 to 2026-11-05
transcript: session.jsonl (this folder, gitignored)
description: Why the tests and mutate.py were slow; mutate.py now runs only each mutation's tests, test tools show progress and timings
---
# Decisions: session 4297b6fb (2026-11-05 to 2026-11-05)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D89 · 2026-11-05 · Cost & structure · mutate.py runs only each mutation's expected tests
- Decided: `_tools/mutate.py` passes `CB_ONLY=<expect list>` to the unit suite, so each mutation runs only the tests meant to catch it (full suite still runs when `expect` is empty), and each mutation keeps its own log. A full mutate run went from about an hour to about 36 s, 8 of 8 caught.
- Why: the latest revision's agents waited over an hour on mutate.py, which reran all 110 unit tests (~3.5 min, longer when broken tests wait out their timeouts) for each of 8 mutations.
- Rejected: the designer's first guess, moving test values from .md files into config: the tests already read `game/scripts/default_config.tres`; the .md files are only named in comments.
- Files: `_tools/mutate.py`, `_tools/godot_run.py`, `_tools/test_generate.py`

### D90 · 2026-11-05 · Cost & structure · Test runs show progress and per-test time
- Decided: `godot_run.py` prints each suite's start and finish with elapsed time, `mutate.py` prints each mutation's verdict and time, and `game/tests/run_tests.gd` adds the milliseconds to every PASS/FAIL line.
- Why: a full run is 6-7 minutes of silence and looked stalled; the timings showed three zoom tests take 80 of the unit suite's ~210 s.
- Files: `_tools/godot_run.py`, `_tools/mutate.py`, `game/tests/run_tests.gd`

### D91 · 2026-11-05 · Cost & structure · Faster unit tests deferred to Quinn
- Decided: running the unit suite at a higher `Engine.time_scale` (about 4x) is deferred to the next working day, as a Quinn brief.
- Why: timing tests (`t_bottling_timing`, `t_pop_tween_unchanged`) may need adjusting, it may clash with the 0.1.3 build, and the 5-hour window had about 22% left.
- Files: `_meta/memory/test-speed-fixes.md`

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
