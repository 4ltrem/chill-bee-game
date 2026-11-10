---
session: 9ceb748d-2e54-44be-96d3-936a83f0e62e
dates: 2026-11-08 to 2026-11-10
transcript: session.jsonl (this folder, gitignored)
description: end-of-day log for sessions bf911259, f6f4c6c0, ae8abf50, 340506c5, 14aa3b08, 735ac206, 524a865e, 3c5a9003 and this one: 0.1.4 merge, UI design prefs, 0.2 spec, models and build, 0.2.0 play-test, 0.2.1 spec, roadmap and Build mode proposals, the week's leftover budget
---
# Decisions: session 9ceb748d (2026-11-08 to 2026-11-10)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own. This log covers every session exported on 2026-11-10 that had no log of its own (bf911259 to 3c5a9003), since end-of-day did not run for them.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D200 · 2026-11-08 · Records & deliverables · 0.1.4 merged into main after the designer's play-test; main's own commits stay
- Decided: the designer play-tested 0.1.4 and had `milestone/0.1.4` merged into `main` (`6e22681`) and pushed. The commits already on `main` are important and are never deleted or rewritten to make a merge clean.
- Files: `_meta/memory/commit-to-main.md`

### D201 · 2026-11-09 · Records & deliverables · 0.1.4 is final; next is 0.2
- Decided: 0.1.4 marked final; the itch link is unchanged and holds the A5 demo build. Work moves to 0.2 on `milestone/0.2` (`dbd1c3b`). A goal run is done when `goal_agent.py SPEC --plan` reports nothing left to build and the latest unit run is green; that line goes in the `/goal` command.
- Files: `MILESTONES.md`, `_meta/memory/session-handoff.md`

### D202 · 2026-11-09 · Pipeline design · UI is built on the real shots, with icons over the farm and no nav bar
- Decided: UI screens are drawn on the game's own screenshots, not invented screens; floating icons over the farm are preferred to a navigation bar; each board has a legend for its icons. The quick-buy slot is decided by play-test: both options plus three others (bottom slot A, with B-D behind Dev mode). The Harvest button becomes the honey-scraper fork icon on a white background, with the honey meter rising behind the fork. Royal Jelly icon is variant K (combs turned 90°, the angle adjustable, set to 60°, the crown overlapping and lower; the pill version). The preferences live in a dedicated file read before any UI work.
- Files: `UI_DESIGN.md`, `_meta/memory/ui-design-prefs.md`, `_meta/learnings.md`, UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca

### D203 · 2026-11-09 · Game build · 0.2 scope answers and a Models stage before the build
- Decided: the Journal entry can be any meadow species (Meadow Bumble Bees); the Long Fork is one continuous drag, and Heated Fork only increases the fork's reach; Auto-Sell triggers Phase 2; the UI is adjusted in a later run. Prototype models are a stage of their own: Milo joins the contract, a models session makes 3-5 variants per model for a vote on Design Votes, then a separate session implements. Gearing adds one gear per level (count follows the ratio); Faster Delivery adds hot rod flames to the truck.
- Files: `game/specs/0.2-first-automation.md` (`97874a9`, `a7bac63`, `45cba96`)

### D204 · 2026-11-09 · Cost & structure · Recombination rounds are scripted recipes
- Decided: asked how to cut tokens when a vote only moves parts of one model onto another, the designer approved `_tools/compose_variant.py`: recombination rounds are recipes run by script, Milo only for new shapes, model features kept as named groups.
- Why: most vote rounds take elements from one variant and put them on another; an agent run for that is waste.
- Files: `_tools/compose_variant.py`, `_meta/memory/compose-variants.md` (`7bc4316`)

### D205 · 2026-11-09 · Game build · Model picks and the 0.2 spec approved
- Decided: after three vote rounds the designer picked fork-r4-c (handle +0.09), gearing-r6 (pointed prism teeth, ring concentric with the lid) and the truck look per Faster Delivery level, then approved the 0.2 spec (`48afcd8`).
- Files: `game/specs/0.2-first-automation.md`, `_tools/gear_train.py`

### D206 · 2026-11-09 · Pipeline design · Goal agent briefs carry only the step's own style rows
- Decided: the designer saw Bob's prompt slice was too large on the blackboard and said patch it: `goal_agent.py` gives each step only the style rows for files it changed, ranges and sub-bullets go with their item, build calls are capped at 30 turns (`756ab90`); a test line's evidence is its own `# goal` marks (`9498556`).
- Files: `_tools/goal_agent.py`, `_meta/learnings.md`

### D207 · 2026-11-09 · Bee Journal rules · The Journal's sources are listed in the game
- Decided: asked during the 0.2 build, the designer said the Journal's sources go into the game; logged as a README TBD (`85bc9d0`).
- Files: `README.md`

### D208 · 2026-11-09 · Records & deliverables · Version numbers: 0.2.x play-test fixes, 0.3.0 first UI pass
- Decided: play-test revisions step the patch number (0.2.0 play-test fixes = 0.2.1). 0.3.0 (11/24) is the first UI design pass, for features already in the game only, after the ui-screens decisions 2-4 and the skin; 0.4 and later follow Gerard's roadmap.
- Files: `MILESTONES.md`

### D209 · 2026-11-09 · Game build · 0.2.1 = the 0.2.0 play-test fixes (spec items 9-14)
- Decided: from the designer's play-test: Spin alone pans to the second stop (9); the fork returns into the Harvest icon on any release (10); the lid stays still, the crank turns and Gear1 follows it, the rest from Gear1 (11); a Spigot Flow shop row moved into 0.2 to fix the bottling bottleneck (12; GDD §3 line); the truck waits for jars in flight (13); the shop shows all 7 rows, no scroll (14).
- Rejected: lowering base `bottling_seconds_per_jar` (not answered; Spigot Flow was the chosen fix).
- Files: `game/specs/0.2-first-automation.md`, `GDD.md`, `README.md`

### D210 · 2026-11-09 · Pipeline design · Gerard places the rest of the GDD on a roadmap; Build mode from the start
- Decided: the designer wants the rest of the GDD placed in versions: Gerard's `proposals/design/roadmap.md` (goal-agent style ranking used for the order, both asked). The grid gate goes: Build mode is open from the start and the centrifuge is the first build, proposed in `proposals/design/build-from-start-r2.md` (bee carry range from Flight Endurance, two zones, BeeTech conveyors post-launch), after a comparison with Factorio and Egg Inc. Both await acceptance; no GDD edit yet.
- Files: `proposals/design/roadmap.md`, `proposals/design/build-from-start.md`, `proposals/design/build-from-start-r2.md`, `proposals/design/_index.md`

### D211 · 2026-11-09 · Workspace & agents · Questions to the designer go in the quiz tool
- Decided: whenever answers are needed, ask with AskUserQuestion, a preview on every option, never a text list.
- Files: `_meta/memory/ask-with-quiz-tool.md`

### D212 · 2026-11-10 · Cost & structure · The week's last 19% skips the 0.2.1 build
- Decided: with weekly usage at 81% and 38% of the week gone (reset Sat 11/14, 9:00 Toronto), the designer agreed: commit the uncommitted days first, then cheap work only (Rex mutation rerun, scripted Spec Review shots, answers on the two proposals); the full 0.2.1 build (about 15-20% by the 0.2.0 build's cost) waits for the reset. A5 and A7 fall after it.
- Why: the 0.2.0 build took about 34 points for 21 goals; design talk alone ran 2-3 points an hour on 11/09-10.

## Still open

- **A6 due date:** the assignment text pasted on 11/09 says due Nov 22; `MILESTONES.md` M2 and memory say 11/12. Which is right?
- **0.2.1 build** after the weekly reset: `budget_guard.py --allow-for 60`, `/goal` + goal_agent, version 0.2.1, itch upload as the A7 link (~11/19).
- **Proposals to accept:** `roadmap.md` (questions 2, 3, 5 open; re-layer to r2) and `build-from-start-r2.md` (then mark `build-from-start.md` superseded). Before the 0.4 spec: Terry, Bob's zoom ceiling, William's lore text, Ruth/William raw-comb price check.
- **Spigot Flow numbers** are placeholders; Terry checks before 0.3.0.
- **Mutation fixes:** Quinn's fixes and `mutate.py --since 48afcd8` rerun (25 MISSED, 45 BROKEN, crash on `_tools/journal_csv.py`).
- **Spec Review shots** to Design Votes (shop list, Journal EN/FR; pick matches for fork, gears, truck).
- **0.3.0 UI pass** needs ui-screens decisions 2, 3 and 4 and the skin first.
- **Web build browser check:** the smoke shot is still the loading spinner; the real-time wait fix is approved but not built.
- **Item 19 refill speed:** overflow drains back at up to twice the fill rate (the assistant's choice; the GDD is silent). Say if you want the normal rate only.
- Re-run `critic_check.py` (about 100k tokens) for the merged Clara on `main`.
- **Fast tests as the default (L17):** make `godot_run.py` run sped up by default with plain speed opt-in.
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
- On the laptop: `git pull`, install or update the `claude` CLI, add D192's three read-anywhere lines to `.claude/settings.local.json`.
- Old branches kept after merging (`milestone/m2`, `milestone/0.1.3`, `milestone/0.1.4`, `m2/flower-patch`, `ab/centrifuge-by-crate`): delete them, or keep them as history?
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
