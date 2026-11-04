---
session: 864dbfb5-1b7c-49cd-bf94-214920851b62
dates: 2026-11-03 to 2026-11-04
transcript: session.jsonl (this folder, gitignored)
description: Prototype 0 revision 3 (the new harvest flow, Dev mode), spec-first tests, the second usage calibration
---
# Decisions: session 864dbfb5 (2026-11-03 to 2026-11-04)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D55 · 2026-11-04 · Game design · Prototype 0 revision 3 follows the new harvest flow
- Decided: the spec was rewritten from GDD §2. A fork icon starts the harvest. Uncapping is the only close-up, and it has a Back button that leaves the frame in the hive. When uncapping ends, the close-up closes and an icon above the full centrifuge starts cranking, which replaces the "Extract honey" button. The Upgrade Shop works throughout the harvest. Tapping Sell credits the money at once, and the truck's trip only delays its next load.
- Also decided: a hold counts turns at the fastest tap rate from the press, and only the spin animation ramps up. This keeps holding never slower than tapping.
- Files: `game/specs/prototype-0.md`

### D56 · 2026-11-04 · Game design · Unhurried placeholders; every tunable in the config
- Decided: the harvest placeholders were slowed: 3 s per jar, a 30 s truck trip, 40 taps per frame, at most 5 counted taps a second, and a 1.5 s spin-up. Every number a script uses lives in `game_config.gd` / `default_config.tres` and is read when used, never cached.
- Why: the designer: "honey is viscous it wouldn't take .4s per jar without a serious upgrade"; fast base values leave nothing for upgrades to improve.
- Files: `game/specs/prototype-0.md`, `game/scripts/game_config.gd`, `game/scripts/default_config.tres`, `game/CONTEXT.md`

### D57 · 2026-11-04 · Pipeline design · Every spec includes an in-game Dev mode
- Decided: a panel opened with the backquote key or a three-finger tap. It edits every config value live, has quick actions (fill hive, +$100, truck home, reset, game speed), and saves tuned values to `user://dev_config.tres`. The project setting `chill_bee/dev_mode` turns it off for store builds.
- Why: the designer tunes by feel while playing.
- Files: `game/scripts/dev_panel.gd`, `game/project.godot`, `game/CONTEXT.md` (Process step 3)

### D58 · 2026-11-04 · Pipeline design · Tests come from the spec, not the code
- Decided: Quinn writes the tests from the approved spec, in parallel with Patricia and without reading her code in progress. Every expected number is read from the config. A failing test is a finding against the code or the spec, never a reason to change the test to match the code.
- Why: the designer noticed that in the last two rounds tests written after the code broke or simply followed it.
- Result: the first spec-first round found no game bug, and five deliberate faults in a copy of the project were each caught only by the targeted tests. The questions Quinn raised were settled in the spec's Clarifications section.
- Files: `game/CONTEXT.md` (Process step 2), `game/tests/run_tests.gd`, `game/tests/play_loop.gd`, `game/specs/prototype-0.md`

### D59 · 2026-11-04 · Cost & structure · The status line logs usage by itself
- Decided: no need to ask the designer to nudge the status line before and after a batch. In the CLI it refreshes while the session works, and it appends a reading whenever usage changes.
- Why: the designer pointed it out; `_meta/usage/readings.jsonl` showed fresh readings every few minutes.
- Files: `_meta/memory/session-handoff.md`

### D60 · 2026-11-04 · Cost & structure · Second calibration: about 4.5M tokens per 1% weekly
- Decided: recorded from the revision 3 batch (4 runs, orchestrator included): weekly usage went from 28% to 31%, and the 5-hour window from 63% to 84%. That is about 4.5M total-processed tokens per 1% weekly (3.7M without the orchestrator's cache reads), and about 650k per 1% of the 5-hour window. It is not comparable with the first calibration, which used final context.
- Why: the binding limit in practice is the 5-hour window, and one prototype batch took a fifth of it.
- Files: `_meta/agent-runs.md` (Daily Budget)

### D61 · 2026-11-04 · Game design · Revision 3 play-test issues wait for revision 4
- Decided: the focus-style bug waits for revision 4, not an orchestrator fix now. The opaque focus style keeps the disabled Upgrade button gold until another button takes focus, and the same style is on Continue, the icons, OK and Back. It is counted against Bob, and the miss against Quinn.
- Files: `game/reports/2026-11-04-prototype-0-r3.md` (Open for revision 4, item 7), `_meta/team.md`

## Still open

- Prototype 0 revision 4: the designer plays the revision 3 exe first. Open items:
  - the focus style
  - the Sell icon over the hive
  - the truck crossing the shop corner
  - rcedit
  - `dev_mode` off for store builds
  - Android
- Not yet decided: whether these join revision 4. They are where the build differs from the designer's own words in the revision 2 play-test:
  - a fork or "!" icon instead of "Harvest"
  - a real camera zoom instead of a cut
  - scraped cells flying into the centrifuge (cut from the spec without asking)
  - the truck as a plain red block
- `content/onboarding-script.md`: approve after the guide signature-lines revision, which must also follow the new harvest flow.
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
- On the laptop: `git pull`, install or update the `claude` CLI, then the first "end of work day" there sets up its memory folder and the commit gate.
