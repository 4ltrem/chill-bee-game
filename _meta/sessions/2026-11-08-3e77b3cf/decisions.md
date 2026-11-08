---
session: 3e77b3cf-93fb-4a53-bd86-3ad67358f941
dates: 2026-11-07 to 2026-11-07
transcript: session.jsonl (this folder, gitignored)
description: 0.1.4 play-test findings, Round 8 and 9 answers, the six guides in content/guides.md, Clara's Completeness check
---
# Decisions: session 3e77b3cf (2026-11-07 to 2026-11-07)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D131 · 2026-11-07 · Game build · C7: after a pour in spin mode the pile reloads and the text stays
- Decided: Play-test: the bucket pours, loads the pile, then asks to press Spin again though spin mode is on. It must keep its text while it loads again; if there is no pile it exits spin mode.
- Files: `game/specs/0.1.4-ui-placement.md`

### D132 · 2026-11-07 · Game build · Play-test: meter clipped to the button; production-paused text above the upgrades (items 1, 9)
- Decided: The meter fill must sit behind the button label and be clipped to its rounded shape (Quinn tests that no fill pixel lies outside at half fill). The wrapping "production paused" message moves above the upgrade section at the bottom (new item 9); the x5 tag displays correctly, so it stays.
- Files: `game/specs/0.1.4-ui-placement.md`

### D133 · 2026-11-07 · Workspace & agents · Gradual animations are shot at several points
- Decided: For animations that are gradual (a meter filling, a pile loading), screenshots are taken at several points, not one.
- Files: `_meta/memory/scripted-shots.md`

### D134 · 2026-11-07 · Game build · Item 10: comb cells show on frames while still in the hive
- Decided: "The honeycombs aren't shown until the frame pops out", and the designer believes this is a regression. Combs show on every frame in the hive and fill as the hive fills; Quinn shoots empty, half and full. Built with the C5 redo.
- Files: `game/specs/0.1.4-ui-placement.md`

### D135 · 2026-11-07 · Workspace & agents · Allow list built from the transcripts, with the Godot test variables
- Decided: The fewer-permission-prompts skill scanned 25 sessions and added four read-only rules to `.claude/settings.json` (it had no allow list); the designer approved and asked to include the variables and arguments, so the exact `CB_TIME_SCALE=6 CB_SKIP_X1=1 ... godot_run.py` forms were added. More rules followed on request.
- Files: `.claude/settings.json`

### D136 · 2026-11-07 · Game build · C5: fewer cells per row are allowed (7 to 5 at about 1.35x)
- Decided: Asked whether dropping to 5 cells per row counts as changing the frame, the designer: "fewer cells are ok". The hive model stays unchanged. Milo redid the variants; frames cannot get taller, so the bigger cells ended up as 2 rows (10, 8 or 6 cells per frame instead of 35).
- Files: `game/specs/0.1.4-ui-placement.md`, `game/scenes/variants/hive-frames/`

### D137 · 2026-11-07 · Bee Journal rules · The guides live side by side in one file, `content/guides.md`
- Decided: "The characters should be put in a separate file to make it easier to compare." The four guides and their signature lines go in one content file, compiled from `onboarding-script.md`, `onboarding-regression.md` and `biome-intros.md` (all William's existing text, empty slots marked for him).
- Why: No earlier decision covered it; comparing voices needs them side by side.
- Files: `content/guides.md`, `_meta/memory/guide-playtest.md`

### D138 · 2026-11-07 · Bee Journal rules · Generic flower names, the sweat-y name, and a Meadow flower for the bumble bee
- Decided: "Keep the generic names for the flowers, and go with the sweat-y name": the English sweat bee line reads "that is exactly how they got their sweat-y name!". For the bumble bee visitor: "just meadow flower for now", so the GDD species table and Journal Entry 3 (EN and FR "Fleurs des pres") say Meadow flowers.
- Files: `content/bee-journal-real.md`, `GDD.md`, `content/biome-intros.md`

### D139 · 2026-11-07 · Bee Journal rules · Six guides: Pip the scout bee, the sprite, Queen Maeve, Dame Aura; Wren is out
- Decided: Pip is the scout bee; the sprite idea is kept and, with Queen Maeve, is added to the guide playtest; Lady Aura is Dame Aura in French. The file has six guides (Melli, Pip, Lady Aura, Miel, Queen Maeve, the sprite, who gets a name other than Pip). The GDD's "name and personality TBD" now says six candidate guides share one script.
- Files: `content/guides.md`, `GDD.md`, `_meta/memory/guide-playtest.md`

### D140 · 2026-11-07 · Game build · Round 9 pick: variant a (5 x 2 cells, real models)
- Decided: The designer picked variant a of Round 9 for C5 with a note: more space between the hexes (smaller cells are fine), and the pile and bucket cells match the frame cells. The goal agent builds C5 from that.
- Files: `game/specs/0.1.4-ui-placement.md` item 5, `game/reports/variants/hive-frames-r9/`

### D141 · 2026-11-07 · Bee Journal rules · Guide names Lumi and Reine Maeve; Glowbell and Skybloom stay
- Decided: "Lumi is a good name, Irish French, Maeve is good": Lumi and Reine Maeve are approved. Glowbell and Skybloom (the designer asked what "plain names" meant) stay as the invented flowers' names in `biome-intros.md`; that follow-up is closed. The designer was unsure the onboarding page from another session is needed.
- Files: `content/guides.md`, `content/biome-intros.md`, `GDD.md`

### D142 · 2026-11-07 · Critic quality · Clara gets a seventh check: Completeness
- Decided: Some characters had no voice and Lady Aura and the French table had gaps; the designer: Clara should have caught this. Clara's definition now reads the whole draft every round and checks every requested slot is filled (check 7, after the six Voice rules T1-T6). William's reruns passed with the gaps filled.
- Files: `.claude/agents/content-critic.md`, `STYLE_GUIDE.md`, `content/CONTEXT.md`

### D143 · 2026-11-07 · Bee Journal rules · `content/guides.md` approved; playtest briefs go on the to-do list
- Decided: Decision 1 in the file: approved. Decision 2: add to the to-do list the briefs for Patricia and Gerard (a guide switch in the build, and the question in the file).
- Files: `content/guides.md`, `_meta/memory/guide-playtest.md`

### D144 · 2026-11-07 · Records & deliverables · `ONBOARDING.md` stays untracked; commit the rest
- Decided: The assistant did not know where `ONBOARDING.md` came from (another session's onboarding tool). The designer: leave it untracked and commit the rest (commit 840a021).
- Files: `ONBOARDING.md`

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
