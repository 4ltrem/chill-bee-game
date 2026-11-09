---
session: 4be1c5ef-c25e-4c2d-abfe-34c4dd0d641f
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: /goal fixing the latest 0.1.4 play-test notes: centrifuge text, Spin size and offset (Design Votes spin-r1), fast test runs
---
# Decisions: session 4be1c5ef (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D197 · 2026-11-08 · Game build · The centrifuge text shows only on the spin screen
- Decided: `/goal fix the bugs on the latest 0.1.4 feedback`, from the play-test note "it should apear only on the spin screen": `CentrifugeLabel` shows only at the second stop; Back from a started spin hides it, and it shows again when Spin pans back. Spec item 13's "in every view" is rewritten. Commit `b810f31`.
- Files: `game/scripts/farm_ui.gd` (`on_spin_screen`), `game/scripts/main.gd`, `game/specs/0.1.4-ui-placement.md`, `game/tests/test_crank_pause.gd`

### D198 · 2026-11-08 · Game build · Spin gets per-view values, picked on Design Votes: 60 px on the farm, 80 px lower in the first zoom (item 22)
- Decided: asked how to handle "smaller in farm view, lower in harvest view" against item 2's "no per-view offsets", the designer chose the votes page: two config values (`spin_farm_visual_px`, `spin_zoom_offset`, live in Dev mode), shots of A 88/0, B 72/40, C 60/80, and voted C for both. The touch area stays 120 x 120; item 2 names item 22 as its one exception; a new shot moment `6b-farm-spin`. Commit `044f59b`.
- Rejected: placeholder values without shots; leaving item 2 as is.
- Files: `game/scripts/game_config.gd`, `game/scripts/default_config.tres`, `game/scripts/floating_icon.gd`, `game/tests/ui_compare_shots.gd`, `game/reports/ui-compare/spin-r1-decisions.json`

### D199 · 2026-11-08 · Cost & structure · Test runs always use the fast settings
- Decided: asked "why does it take 15 minutes", the designer said yes to running tests sped up and to only the affected tests while iterating: every Rex brief names `CB_ONLY=<tests>` while fixing and `CB_TIME_SCALE=6 CB_SKIP_X1=1 ... all` at checkpoints (approved 11/6, missed today; see L17).
- Files: `_meta/memory/test-speed-fixes.md`, `_meta/learnings.md`

## Still open

- **0.1.4 play-test and itch upload (A5 due 11/15, 11:59 ET):** play both builds (exported from `044f59b`: lid close, combs and hitbox, Dev button on web, truck loading, Spin size and offset, centrifuge text), then upload `game/builds/chill-bee-game-0.1.4-web.zip` and submit the A5 link; fill the RESULTS, MANUAL and COST sections of `GOAL_AGENT.md`.
- **Web build browser check:** the smoke shot is still the loading spinner; the real-time wait fix is approved but not built.
- **Item 19 refill speed:** overflow drains back at up to twice the fill rate (the assistant's choice; the GDD is silent). Say if you want the normal rate only.
- **`main` is ahead of `milestone/0.1.4`** by `e4bfa51` and `00d0c83`; they come in on the merge. Re-run `critic_check.py` (about 100k tokens) before merging the branch's Clara into `main`.
- **Fast tests as the default (L17):** make `godot_run.py` run sped up by default with plain speed opt-in, so the rule can't be missed again.
- **Goal agent:** confirm whether `--goal` still refuses goals that are already done.
- **Build next (D168):** `live.json`, `_tools/watch.py` and the live side pane (D150, D155), then parallel test runs (D151).
- **M3 cap-stop summary and M4 content in Godot strings** (D194); `/goal` wrapping `goal_agent.py` (D195, backlog item 8).
- **spec_lint warnings:** T.1/T.2 ties; items 11, 12, 15, 20 and 22 all touch Spin in the farm view; reword or confirm.
- **Learning gaps:** L21 (orchestrator runs scripts itself) and L24 (commit to `main` from a worktree) are memory rules only, with no code guard.
- **Guide playtest briefs** (D143): briefs for Patricia (a guide switch) and Gerard; playtest Melli, Pip, Lumi, Lady Aura, Miel and Reine Maeve.
- **Onboarding guide** (D125, D144): `ONBOARDING.md` is a draft at the repo root, untracked on purpose; fill Team Tips and Get Started, or drop it.
- **Google activity analysis** (D156): waiting for your Takeout export.
- Run `style_critic_check.py` with Vera's new scores (D101).
- The farm ground is 18 x 18, so the zoom shows no sky around the diorama; about 14 x 14 would bring the floating look back.
- Session d82fcc79 changed after its end-of-day commit; check whether it holds decisions not yet logged.
- `content/biome-intros.md` back to draft after the T6 revise; needs re-approval, with the "five checks" to "six" word change in `STYLE_GUIDE.md`.
- `content/onboarding-script.md`: needs the new harvest flow (D154) and the six guides' lines from `content/guides.md`.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
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
- On the laptop: `git pull`, install or update the `claude` CLI, add D192's three read-anywhere lines to `.claude/settings.local.json`; the first "end of work day" there sets up its memory folder and the commit gate.
- Old branches kept after merging (`milestone/m2`, `milestone/0.1.3`, `m2/flower-patch`, `ab/centrifuge-by-crate`): delete them, or keep them as history?
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
