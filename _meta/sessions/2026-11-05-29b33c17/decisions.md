---
session: 29b33c17-4567-4c61-8723-d7a6df6b5c05
dates: 2026-11-05 to 2026-11-06
transcript: session.jsonl (this folder, gitignored)
description: 0.1.3 steps b and c, round-6 framing, play-test fixes, input recorder; QA speed-up, edit and wait rules, Vera's scores
---
# Decisions: session 29b33c17 (2026-11-05 to 2026-11-06)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own. 0.1.3 build decisions are also recorded in the spec's "Clarifications (0.1.3c)".

## Decisions

### D98 · 2026-11-05 · Pipeline design · 0.1.3 lids and crate
- Decided: the crate may be 1.4 deep (jars must not clip or hang off); the hive lid keeps its 0.1.2 rest pose (Bob's step-b move behind the hive clipped), and the 0.1.1 rule becomes "not toward the centrifuge"; the centrifuge lid opens and leans to the screen upper-left.
- Files: `game/specs/0.1.3-next-revision.md`, `game/scenes/props/hive.tscn`, `game/scenes/props/centrifuge.tscn`

### D99 · 2026-11-05 · Pipeline design · Camera flow: finish, then pan; Spin in the zoom
- Decided: the camera stays on the first zoom while uncapping and pans to the second stop afterwards; after the play-test, closing the zoom with a full bucket (Back included) pans, and with the centrifuge full the Spin icon shows in the first zoom and a tap ends the zoom, pans and starts the crank.
- Why: the default hive has 5 frames and the bucket holds 2, so Back after 2 frames never panned in play.
- Rejected: pan the moment the bucket fills; Spin as a reminder only.
- Files: `game/scripts/main.gd`, `game/specs/0.1.3-next-revision.md`

### D100 · 2026-11-06 · Pipeline design · Round 6: first zoom exactly A
- Decided: the hive sits on its layout-C cell; the first zoom is exactly round-6 A (zoom_size 6.966, framed on hive + centrifuge); the second stop keeps centrifuge, crate and truck whole with the hive partly visible upper-right (the 15–35% band dropped).
- Why: the designer's vote on the Design Votes page; the orchestrator's reading of "zoom in even more" as 4.8 cropped the hive and was withdrawn.
- Files: `game/scenes/main.tscn`, `game/scripts/default_config.tres`, `game/specs/0.1.3-next-revision.md`

### D101 · 2026-11-05 · Pipeline design · Ground under the truck, barrel ease
- Decided: the ground plane grows to 18 × 18 and the test checks the whole truck footprint; before the centrifuge lid opens the barrel eases to a quarter-turn stop over `barrel_stop_seconds`, no snap.
- Files: `game/scenes/main.tscn`, `game/scripts/centrifuge.gd`

### D102 · 2026-11-06 · Pipeline design · Icons anchored in the game world
- Decided: Fork, Spin and Sell stay screen buttons (≥ 120 px touch) placed only by 3D markers directly above their props, screen_offset 0; a guard test checks no icon overlaps another, the labels, the shop panel or the props in every camera state.
- Rejected: true 3D sprite icons (the touch area would shrink with the zoom).
- Files: `game/scenes/props/*.tscn`, `game/tests/test_second_stop.gd`

### D103 · 2026-11-06 · Pipeline design · Input recorder and replayer
- Decided: in Dev mode the game records every input with game-time stamps, config and seed (F8 or the Dev panel; from launch by default) to `user://recordings/`; `tests/replay.gd` (`CB_REPLAY=<file>`) replays it headless at 720 × 1280 and prints state lines; randomness goes through one seeded `GameRng`.
- Why: agents can reproduce the designer's play-tests instead of guessing the path.
- Files: `game/scripts/input_recorder.gd`, `game/scripts/game_rng.gd`, `game/tests/replay.gd`

### D104 · 2026-11-06 · Cost & structure · Faster QA
- Decided: unit tests run at `CB_TIME_SCALE=6` on a game clock, with real-time tests listed in `X1_TESTS`; `CB_SKIP_X1=1` skips them and the designer checks real-time behaviour by playing; Quinn writes tests and runs only his own with `CB_ONLY`, Rex runs full suites, builds and mutate; `mutate.py --since <commit>` runs only new or changed mutations; a milestone worktree takes `_tools/` fixes from its parent branch.
- Why: QA rounds took up to an hour; the hour-long mutate run came from a worktree holding an old `mutate.py` that ran the whole suite per mutation. A checkpoint now takes 6–9 minutes and changed mutations about a minute.
- Files: `game/tests/run_tests.gd`, `game/tests/test_base.gd`, `_tools/mutate.py`, `.claude/agents/qa-build-engineer.md`, `game/CONTEXT.md`

### D105 · 2026-11-06 · Workspace & agents · Edit lines, wait by running, LF
- Decided: every agent changes existing files only with Edit (team rule 5; Quinn and Milo given the Edit tool); agents run scripts in the foreground with a long timeout and never `sleep` (team rule 6; the Monitor tool is not given to them); `.gitattributes` forces LF for text files; run outputs go to `game/reports/_runs/` and the stale `tests/snapshots/r4` frames were removed; the agent who designs comparison shots writes the script and Rex runs it.
- Why: whole-file rewrites and CRLF flips made diffs look like mass deletions; blocked `sleep` calls wasted turns.
- Files: `_meta/team.md`, `.claude/agents/*.md`, `.gitattributes`

### D106 · 2026-11-05 · Critic quality · Vera scores every asset
- Decided: under her findings table Vera scores each prop and UI element 0–10 with a one-line reason, on the look words (cozy, whimsical, chunky/round, calm, pastel) and her rules that apply; a score below 6 is a blocking row. `style_critic_check.py` is rerun on the fixtures after 0.1.3c.
- Files: `.claude/agents/style-critic.md`, `STYLE_LOOP.md`

## Still open

- Play 0.1.3 (`.claude/worktrees/0.1.3/game/builds/windows/ChillBeeGame.exe`, commit 59e11bd) with the recorder on (it starts at launch in Dev mode; F8 toggles); check the icons above the props, the Back spot at the second stop (found by a scan, not a fixed place), Spin in the zoom, and the real-time behaviour the tests now skip (speed row and hotkeys, ×N tag, pan timing, pop, jar fill).
- Merges once played: `milestone/m2` and `milestone/0.1.3` into `milestone/0.1`, then `main`; then delete the `ab-centrifuge` worktree and branch.
- Run `style_critic_check.py` with Vera's new scores (D106).
- The Spin node is moved out of FarmUI at runtime by `main.gd`; Bob should move it in `main.tscn`.
- Spin sits about 270 px above the centrifuge at the first zoom (one marker height serves both views); a per-view height is a small change if the designer wants it.
- The farm ground is 18 × 18, so the zoom shows no sky around the diorama; about 14 × 14 would bring the floating look back.
- `build.py`'s web smoke test: the 100 s wait still shows the loading spinner; the web build is unconfirmed (only matters for itch at 0.2.0).
- Patricia's Edit tool still writes CRLF into `main.gd` in the worktree; git normalises it on commit.
- Budget guard: reworked on 2026-11-05 (D95); confirm the 80% complaint is resolved.
- Session d82fcc79 changed after its end-of-day commit; check whether it holds decisions not yet logged.
- Review Bob's M2 layout changes before merging `milestone/m2` (Harvest tag, Upgrade button, spin hint, walls 0.05 thick).
- `content/biome-intros.md` back to draft after the T6 revise; needs re-approval, with the "five checks" → "six" word change in `STYLE_GUIDE.md`.
- Flower-patch tail (other session): `flower_patch.gd` blossom colour, Bob promotes B, then patch y to 0 after 0.1.3 merges.
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
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: `git pull`, install or update the `claude` CLI, then the first "end of work day" there sets up its memory folder and the commit gate.
- Learnings file (D92): one record of everything that broke, how it was noticed and how it was fixed; decide where it lives and whether it is kept by hand or built from the decision logs.
- A5 prep (due 11/15).
