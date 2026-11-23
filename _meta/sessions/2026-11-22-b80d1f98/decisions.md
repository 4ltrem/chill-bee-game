---
session: b80d1f98
dates: 2026-11-22 to 2026-11-22
transcript: session.jsonl (this folder, gitignored)
description: the 0.3.0 course build: welcome and victory screens, Habitat Health, patches, bumble bee, skip icon; Terry's numbers, the FR house style, the goal run with placeholders and budget overrides, the export templates; logged after the fact on 2026-11-23 from `_tools/session_digest.py`
---
# Decisions: session b80d1f98 (2026-11-22 to 2026-11-22)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

Logged on 2026-11-23, after D269, so these IDs are later than their dates. The per-file decisions are in `proposals/design/course-ending.md`, `proposals/balance/course-ending-balance.md` and `content/course-ending-text.md`; this log keeps the process.

## Decisions

### D273 · 2026-11-22 · Records & deliverables · The 0.2.1 build waits on Godot's export templates
- Decided: the designer picked "Build 0.2.1 + itch"; both exports failed at once because `%APPDATA%\Godot\export_templates` had been empty since 2023 (earlier builds came from the other machine). The designer installed the 4.2.1-stable templates through the editor (outside the repo, "ok the export templates were downloaded"); 0.3.0 was then the first build made here.
- Why: templates live outside the repo, so installing them was the designer's step.
- Rejected: Claude downloading the `.tpz` itself (a write outside the repo).

### D274 · 2026-11-22 · Pipeline design · 0.3.0 is the course ending: option B, save-free, with a skip icon
- Decided: "a few things to add before turning it in for A7 … a welcome screen and a victory screen". From Gerard's proposal: B (Habitat Health meter + wildflower patches + the bumble bee visitor); patches raise Habitat Health only, not honey; the game stays save-free (every launch shows the welcome screen); graders reach the ending with a visible skip, a small icon on the farm view; the welcome title is "Chill Bee Game" (title + Play only); no victory summary; William drafts the victory text and Clara checks it.
- Why: MILESTONES' A7 gate needs a start and an end a stranger can reach.
- Rejected: options A and C; patches boosting honey; a save system for 0.3.0; skip on the welcome screen; a summary of patches and jars.
- Files: `proposals/design/course-ending.md`

### D275 · 2026-11-22 · Pipeline design · Terry's ending numbers, William's text, and French in "vous"
- Decided: accepted Terry's values (Health starts 10, +15 per patch, thriving 100, 6 slots, $40 × 1.25 per patch, about 25 min to victory, range 20-38) with no gate on later patches, though rushing patches wins in about 16.5 min; approved William's English as written; French UI addresses the player as "vous", and the Bee Journal is "Carnet des abeilles" (house style, saved as a memory). The orchestrator added the Play button's French, "Jouer".
- Rejected: locking patches behind Auto-Sell; "tu".
- Files: `proposals/balance/course-ending-balance.md`, `content/course-ending-text.md`, `_meta/memory/french-house-style.md`

### D276 · 2026-11-22 · Cost & structure · The 0.3 spec approved and built at once, on budget overrides
- Decided: "Approve, build now" for `game/specs/0.3-course-build.md` (6 items); the budget guard held the goal agent (week 31% with 17% gone), and the designer allowed 60 min, then 3 hours, then 2 more hours to finish 14/14 goals.
- Why: 0.3.0 is due 11/29 and the build was about 1.5 goal-agent days.
- Files: `game/specs/0.3-course-build.md`, `game/reports/goal/0.3/blackboard.md`

### D277 · 2026-11-22 · Pipeline design · Visual numbers stay placeholders until the play-test
- Decided: away from the computer, the designer kept Bob's welcome-screen sizes as placeholders, then: "Just take the placeholders and compare to the UI design we decided on as long as it's close enough I can confirm when I play test later". This became goal_agent's placeholder mode (`visuals: placeholder`, D279) and the play-test list in the handoff.
- Rejected: a Design Votes round per size while the designer can only read the chat.

### D278 · 2026-11-22 · Game build · 0.3 layout: the Shop may cover the icons; style minimums win
- Decided: "the shop screen can overlap any harvest, sell or spin icons as it takes most of the screen"; V11 (120 px touch) and V12 (28 px text) beat the earlier 64 px / 24 px votes; the pill's flower is a flat circle and Blossom joins the STYLE_GUIDE UI tokens; with 120 px rows the open Shop covers the whole screen; the Habitat pill goes beside the money.
- Why: the style check failed the smaller sizes and the gradient (V4).
- Rejected: keeping the voted 64 px rows; the pill stacked under the money (it met the hive count).
- Files: `game/specs/0.3-course-build.md`, `STYLE_GUIDE.md`

### D281 · 2026-11-22 · Workspace & agents · One session drives the 0.3 build
- Decided: with two sessions editing the 0.3 build (this one and 85235484, which committed goal-agent changes), the designer chose this one to drive; it told the other session to keep off `game/`, the specs, `goal_agent.py` and Godot scripts.
- Why: two writers on one run risk conflicting edits.

### D282 · 2026-11-22 · Game build · Fix the four weak 0.3 mutations while the build runs
- Decided: "fix the four weak tests while the build runs": Quinn and the orchestrator made all four caught (`830416b`).
- Files: `game/tests/`, `game/tests/mutations.json`

## Still open

- The play-test of the placeholders (sizes, skip icon position, minutes to victory): in the session handoff.
