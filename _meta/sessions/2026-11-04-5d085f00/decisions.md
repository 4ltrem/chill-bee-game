---
session: 5d085f00-6243-4512-bc0f-e49ceead5d1b
dates: 2026-11-04 to 2026-11-05
transcript: session.jsonl (this folder, gitignored)
description: Prototype 0 closed, milestones and version numbers, the 0.1 Harvest build and its 0.1.1 and 0.1.2 revisions, pipeline cost cuts, the budget guard
---
# Decisions: session 5d085f00 (2026-11-04 to 2026-11-05)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D62 · 2026-11-04 · Records & deliverables · Prototype 0 closes at revision 3; builds are numbered 0.<milestone>.<build>
- Decided: after the prototype proved the loop, the designer asked whether to move to an alpha build. The answer was to close Prototype 0 at revision 3, call the next phase the Vertical Slice (GDD milestone 1), and number builds `0.<milestone>.<build>` (0.1.0, 0.1.1, ..., 1.0.0 at launch). The designer pasted the course syllabus, and `MILESTONES.md` was built against it and approved. A5 is due on the 15th, which fits M3's target of the 14th. The designer set up the itch.io page, and a Web export became part of the definition of done.
- Why: by the usual definitions the game is not yet alpha (alpha means every feature is in); the GDD already has milestones.
- Files: `MILESTONES.md`, `game/specs/prototype-0.md`, `game/specs/0.1-harvest.md`, `GDD.md` (Timeline line)

### D63 · 2026-11-04 · Game design · Harvest on the farm: uncapping zoom, two-piece hive and glass centrifuge
- Decided: the rack stays upright above the hive. The player may stay and uncap every frame, or tap Back (the hive closes again). When all frames are uncapped the view backs out by itself, and the player then taps the full centrifuge to crank it. Cells go into the bucket automatically. The hive and the centrifuge are both two-piece (hive: box and frames, 5 frames of 2 jars; centrifuge: a bucket for the combs and a lid with the crank). The centrifuge has glass walls and a steel lid, the combs melt into honey while it spins, and the honey is seen draining into the jars. Models that need no rebuilding, such as the truck, are kept as reusable prop scenes. The narrative and onboarding wait until later in the process.
- Why: the designer's answers to the revision 4 questions and the play-test notes; the truck model was liked as it is, with wheels that must turn the right way.
- Files: `GDD.md` §2, `game/specs/0.1-harvest.md`, `research/hive-harvest-equipment.md`, `game/scenes/props/`

### D64 · 2026-11-04 · Pipeline design · Build in small green steps on milestone branches
- Decided: asked for better ways to run the build process, the designer said "yes to all" seven changes. Milestones are built in small playable steps that each end green. Each step gets a checkpoint commit on `milestone/<version>`, and the end-of-day routine merges the branch only when the report passes and the designer has played it. `_tools/contract_check.py` checks every node a script looks up against the scenes and runs in the pre-commit gate. Patricia hands over her node-name section first so Bob starts in parallel. Bob renders one screenshot per state before Quinn runs. "Do not change" items get snapshot tests from the last approved build. The A5 agent runs this process.
- Why: the last three builds had name mismatches between scripts and scenes, and the designer's play-tests found a bug Quinn's tests missed.
- Files: `game/CONTEXT.md` (Process 4-7), `_tools/contract_check.py`, `.githooks/pre-commit`, `.claude/skills/end-of-day/SKILL.md`, `MILESTONES.md`

### D65 · 2026-11-04 · Game design · 0.1.1 look: zoom option A, hive smaller than the truck
- Decided: after four zoom framings were built on separate branches and compared on one page, the designer picked option A (whole rack at 44.3 px cells, the bucket partly in view). The hive is to be smaller than the truck (about half its size), and the centrifuge lid drops a little further so it does not clip into it. Honey glow and colour are not checked in tests. The earlier 0.1.1 feedback (lid lifts and rests on the hive at an angle, frames point bottom right, the centrifuge shows every comb that went in, a real jar model, rims on the wheels) was built before this.
- Why: the rack is the only thing the player touches, and option A keeps it whole and full size.
- Rejected: B (everything in view, but cells shrink to 33 px), C (7 x 4 rack), D (bucket closer; only the first rack fits).
- Files: `game/specs/0.1.2-bottling-and-sale.md`, `GDD.md` §2

### D66 · 2026-11-04 · Game design · Bottling starts by itself; the summary comes after Sell
- Decided: empty jars lie in the crate and fly under the spigot, and bottling starts by itself after cranking, with no Continue press. Leftover honey that does not fill a jar needs no extra cranking. The batch summary moves to after the player taps Sell and drops the tool and upgrade bonus lines (they stay in the design and appear once they exist). The 0.1.2 spec also carries the unfinished 0.1.1 fixes so one test and export cycle covers both.
- Files: `game/specs/0.1.2-bottling-and-sale.md`, `GDD.md` §2

### D67 · 2026-11-04 · Cost & structure · Pipeline cost cuts: scripts before tokens
- Decided: after a review of the day's run log (Quinn's 0.1 run alone used 22.7M tokens), the designer said "yes build the tools now". Four tools were built: `_tools/godot_run.py` (runs suites, prints a short summary, raw logs to `reports/_runs`), `_tools/build.py` (version, Windows and Web export with retry, zip, browser smoke test), `_tools/mutate.py` (named breakages in `game/tests/mutations.json` replace hand-made broken copies) and `_tools/contact_sheet.py` (one image per shot set). Nine rules went into the process and the agent definitions: scripts before tokens, split test files, briefs that name only the needed spec sections, 150-word replies, sweeps done by script, and a fresh session per milestone.
- Why: raw Godot logs, hand-run exports and one 3,000-line test file dominated agent spend.
- Files: `_tools/godot_run.py`, `_tools/build.py`, `_tools/mutate.py`, `_tools/contact_sheet.py`, `game/tests/mutations.json`, `game/CONTEXT.md` (Process 8), `.claude/agents/qa-build-engineer.md`, `.claude/agents/programmer.md`, `.claude/agents/builder.md`, `_tools/test_generate.py`

### D68 · 2026-11-05 · Cost & structure · Budget guard blocks new agents near the limit
- Decided: an agent hit the 5-hour limit mid-task, and the designer asked that it never happen again. A PreToolUse hook, `_tools/budget_guard.py`, blocks new agents at 80% of the 5-hour window or 90% of the week, and warns at 65%. The designer can lift it with `--allow-for N` minutes. A test was added.
- Files: `_tools/budget_guard.py`, `.claude/settings.json`, `_tools/test_generate.py`

### D69 · 2026-11-05 · Game design · Dev-mode game speed goes into the next revision
- Decided: the designer asked for a way to speed up time or one animation for play-testing, for the next revision. The draft 0.1.3 spec proposes one game-wide speed row (x0.25 to x10), an on-screen tag when the speed is not x1, hotkeys `[` and `]`, a reset to x1 that is never saved, and a test that every animation follows the speed. It is a draft and nothing is built from it.
- Rejected: a separate per-animation speed control (each animation's duration is already editable in the panel).
- Files: `game/specs/0.1.3-next-revision.md`

## Still open

- 0.1.2 play-test: the designer plays the 0.1.2 build, uploads `game/builds/chill-bee-game-0.1.2-web.zip` to itch (press "Reset to defaults" in Dev mode once), and gives notes for 0.1.3. Check the Sell icon over the top-left money label.
- 0.1.3 Dev-mode speed: x10 as the top speed, or x20?
- M2 drafts: approve `STYLE_GUIDE.md` and `game/specs/m2-style-loop.md` before any build (kept as drafts for a final read).
- Carried from revision 3, still to check in the 0.1 line: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- `content/onboarding-script.md`: the designer said the narrative and onboarding come later in the process; it also needs the guide signature-lines revision and the new harvest flow.
- Guide character playtest: Melli, Pip, Lady Aura or Miel (D46).
- Harvest TBDs in the GDD: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost (Terry). The prototype values are placeholders, tunable in Dev mode.
- Content follow-ups:
  - a Sunny Meadow flower for the bumble bee visitor (then Journal Entry 3)
  - name Glowbell and Skybloom in `content/biome-intros.md`
  - the "sweat name" wording
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
