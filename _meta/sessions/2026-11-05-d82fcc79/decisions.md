---
session: d82fcc79-9cc5-4d4c-a928-3c60ef6b12e5
dates: 2026-11-05 to 2026-11-05
transcript: session.jsonl (this folder, gitignored)
description: 0.1.3 farm grid and camera picked on screenshots, harvest automation applied to the GDD, M2 approved after an ICM audit, Milo hired, 0.1.3 steps a and b built in a worktree
---
# Decisions: session d82fcc79 (2026-11-05 to 2026-11-05)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D75 · 2026-11-05 · Game design · Bigger hive (1.4x, 7 x 5 rack) and a 20 px cell minimum
- Decided: round 4 picked C, rack c-1: the whole hive scaled 1.4x with the 7 x 5 cells kept. STYLE_GUIDE V14 drops from 44 px to 20 px wide cells at the uncapping zoom.
- Why: no layout reached 44 px with the hive and centrifuge in one view; the designer prefers the frames bigger on screen over a smaller 5 x 4 rack.
- Rejected: A (today's rack, 17 px); c-3 (5 x 4 cells, 26.9 px).
- Files: `STYLE_GUIDE.md` (V14), `game/specs/0.1.3-next-revision.md` (item 2)

### D76 · 2026-11-05 · Game design · Two camera stops, framed on screenshots
- Decided: the first zoom always keeps the hive and centrifuge in focus at every upgrade level, with no crate or truck; round 5 picked the tight framing (3% margin, 21.8 px), and closer is fine. When the bucket is full the camera pans to the centrifuge, crate and truck with about a quarter of the hive in the upper-right corner, which moves the hive 1.25 world units up-right. The centrifuge lid reuses the hive lid's tilt-and-lean animation and takes no cell. The ground extends under the truck and no jar hangs off the crate.
- Rejected: the mid and loose first zooms; a third or half of the hive at the second stop; the round-4 pan.
- Files: `GDD.md` §2, `game/specs/0.1.3-next-revision.md`, `game/specs/0.1.3-farm-grid-layouts.md`; votes in `.claude/worktrees/ab-centrifuge/game/reports/round4-shots/` and `round5-shots/decisions.json`

### D77 · 2026-11-05 · Game design · Harvest automation split into purchases; upgrade paths without numbers
- Decided: Automation is now separate purchases: the motor (the electric centrifuge spins by itself), the auto-scraper (the Long Fork mounted on a moving gantry, after the Long Fork, which is the final fork upgrade) and Faster Delivery. The first purchase starts Phase 2; the full-hive pause ends once the motor and the auto-scraper are both owned. Auto-Sell means the truck leaves when full and sells at full price, with no discount. Deep Frames are twice as long. The jar crate has tiers 1-3 (1, 2, 3 cells) holding more jars waiting and a bigger truck load. In Phase 2 an automated unit's zoom opens from upgrade mode (UI TBD). Terry suggested the paths only; his balancing waits until the rest of the upgrades and the economy are defined.
- Why: the designer's own upgrade ideas; balancing now would be redone once the economy exists.
- Rejected: Auto-Sell as discounted overflow selling; crate tiers making bottling faster (bottling speed belongs to the centrifuge).
- Files: `GDD.md` (§1, §2, §3 Tree B, §4), `README.md` TBDs, `proposals/balance/harvest-upgrade-paths.md`

### D78 · 2026-11-05 · Workspace & agents · Dev-mode speed goes from x0.25 to x20
- Decided: the Dev panel speed row is x0.25, x0.5, x1, x2, x5, x10, x20 with `[` and `]` hotkeys and an on-screen tag; the designer asked for both x10 and x20.
- Files: `game/specs/0.1.3-next-revision.md` (item 1), `game/scripts/dev_panel.gd`

### D79 · 2026-11-05 · Records & deliverables · Upload to itch only at a new milestone number
- Decided: builds go to itch.io only at a new milestone number (0.2.0, 0.3.0); builds inside a milestone are played locally. 0.1.2 was not uploaded. The Sell icon over the money label was a wrong description: it sits above the truck as designed.
- Why: saves time while the layout is being fixed; 0.1.0 already covers the M1 web link.
- Files: `MILESTONES.md`, `_meta/memory/itch-upload-rule.md`

### D80 · 2026-11-05 · Workspace & agents · M2 approved after an ICM audit
- Decided: the M2 style-loop spec was approved once an ICM audit checked it against the workspace. It added item 10 (routing for the new scripts in `AGENTS.md`, `materials/` and `reports/style/` rows in `game/CONTEXT.md`, the critic's calibration row, the ab-compare builders moving into `_tools/compare_page.py`, Clara's pointer in `content/CONTEXT.md`) and named the shot folder. `STYLE_GUIDE.md` got its row in `AGENTS.md`.
- Files: `game/specs/m2-style-loop.md`, `AGENTS.md`

### D81 · 2026-11-05 · Workspace & agents · Milo, the Modeler: cheap colorbox variants with deterministic shots
- Decided: Martin hired Milo (Haiku) for the asset gap: a few colorbox variants per model (default 3), primitives and palette materials only, into `game/scenes/variants/<prop>/`. A script with no agent (`_tools/model_shots.py`) places each variant on a 5 x 5 test grid at the uncapping zoom and renders shots; the designer picks on the vote page and Bob promotes the pick.
- Why: the designer likes the style already made and only needs variations to pick from; Haiku is enough because every variant is checked by script and by the designer.
- Files: `.claude/agents/modeler.md`, `game/scenes/variants/CONTEXT.md`, `_meta/team.md`, `game/specs/m2-style-loop.md` (item 11)

### D82 · 2026-11-05 · Records & deliverables · One Design Votes page for every comparison
- Decided: every comparison is a new section of the one vote page, renamed "Design Votes" (https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa), with earlier questions collapsed. No separate artifact is published and nothing opens in the browser; the link is given. The V3 rim mark and flower patch pages were moved into it (flower patch B picked).
- Why: two separate pages opened in the browser during the M2 run.
- Files: `_meta/memory/ab-comparison-page.md`, `_tools/compare_page.py`, `game/reports/variants/flower-patch/decisions.json`

### D83 · 2026-11-05 · Workspace & agents · Edit only the needed lines
- Decided: files are changed with line edits only, never with scripts that read and rewrite a whole file.
- Why: the designer asked; whole-file rewrites hide what changed and can overwrite parallel edits.
- Files: `_meta/memory/edit-lines-only.md`

### D84 · 2026-11-05 · Pipeline design · 0.1.3 is speed, grid and camera, built in its own worktree
- Decided: 0.1.3 covers the speed row and the grid and camera only; crate tiers and the long Deep Frames wait for Terry's numbers. It is built in steps a, b and c in the worktree `.claude/worktrees/0.1.3` on branch `milestone/0.1.3`, started from `milestone/m2` d0ebd3e so M2's style fixes are already in; it merges into `milestone/0.1` when Quinn passes. Two sessions split the work: this one builds 0.1.3; the other does the flower-patch tail on `m2/flower-patch` and keeps out of the farm scene. `contract_check.py` now works inside a worktree.
- Why: the M2 session had uncommitted scene edits in the main checkout; separate worktrees keep the two runs from colliding.
- Files: `game/specs/0.1.3-next-revision.md`, `_tools/contract_check.py` (on `milestone/0.1.3`)

### D85 · 2026-11-05 · Records & deliverables · End of day exports every session, including cleared ones
- Decided: `export_session.py --all` exports every transcript not yet exported or changed since, and end-of-day uses it, because each `/clear` starts a new session id. The day's decision log covers every session exported that day. The designer stopped all agents and skipped Doris's doc audit this evening.
- Files: `_tools/export_session.py`, `.claude/skills/end-of-day/SKILL.md`

## Still open

- **0.1.3 step b is mid-build and red** in `.claude/worktrees/0.1.3` (WIP commit on `milestone/0.1.3`): Patricia's hive scale and config keys are in; Bob's layout port and Quinn's `test_layout.gd` were stopped part-way. Unit run 107/117: three old tests need the new spec values (`min_cell_px` 20, hive 1.4x), seven lid, crate and jar tests to re-check once Bob's layout is in. Resume Bob, then Quinn with `godot_run.py all --refresh`.
- 0.1.3 step c: the two camera stops, the shared lid-lean component, the second-stop HUD, and M2's open V7 row (bucket fills the bottom-right third, a wood slab cut off at the left). Then delete the `ab-centrifuge` worktree and its branch.
- Stray Godot processes from the test runs (flower-patch worktree and 0.1.3); Quinn was not allowed to stop them.
- The decision logs for the two M2 sessions today (452ddba6, and 1f6110f3 after `/clear`) are not written yet; that session has closed, so a subagent writes them from its transcripts and commits, from D86 (as D74 did for 5d085f00).
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
