---
name: session-handoff
description: Where work stands (2026-11-05): 0.1.2 on milestone/0.1, Quinn's final run, M2 drafts awaiting approval; read first
metadata:
  node_type: memory
  type: project
  originSessionId: 864dbfb5-1b7c-49cd-bf94-214920851b62
  modified: 2026-11-04T01:03:43.220Z
---

Working in the terminal `claude` CLI inside VS Code (`/ide`). The status line (`_tools/statusline.py`) logs plan usage
by itself, so there's no need to ask the designer for a nudge ([[usage-calibration]]).

**Status (2026-11-04):** Prototype 0 revision 3 is built. It follows the new GDD §2 harvest flow and adds Dev mode.
- The spec, `game/specs/prototype-0.md`, is approved. Its Clarifications section records what was settled during
  the build.
- Quinn's report, `game/reports/2026-11-04-prototype-0-r3.md`, is a PASS: 60/60 unit tests and 1015 real-input checks.
- The build is `game/builds/windows/ChillBeeGame.exe`.
- The second calibration is recorded in `_meta/agent-runs.md`.
- Committed in 7d04bc6 (end of day 2026-11-04, decisions D55-D61).

**2026-11-04 (day 2):** 0.1 Harvest built on branch `milestone/0.1` (commits eaa8628..970f28b): Quinn's report `game/reports/2026-11-04-0.1-harvest.md` 78/78, play_loop green, 60 FPS, pop snapshot OK. Open: designer decision on the capped colour (upright pose lights it brighter than r3), intermittent play_loop fork click, the designer uploads `game/builds/chill-bee-game-0.1.0-web.zip` to itch and plays; merge to main at end of day once played. Process changes in game/CONTEXT.md 4-7 and `_tools/contract_check.py`.

**2026-11-05:** 0.1.2 (`game/specs/0.1.2-bottling-and-sale.md`) built on `milestone/0.1`; Patricia's fixes in 9514516 (104/110). Quinn's final run was launched from the previous session (fix 6 tests per the spec Clarifications, split run_tests.gd, mutations.json + mutate.py, reports/.gdignore, `godot_run.py all`, `build.py 0.1.2 --smoke`, report `game/reports/2026-11-05-0.1.2.md`). If that report is missing, his run did not finish: relaunch Quinn with the same brief. Then: review report + `python _tools/contact_sheet.py game/reports/0.1.2-shots`, rework tally rows to `_meta/team.md`, checkpoint commit, designer plays and uploads `game/builds/chill-bee-game-0.1.2-web.zip` to itch (Dev mode "Reset to defaults" once). M2: `STYLE_GUIDE.md` and `game/specs/m2-style-loop.md` are drafts awaiting the designer's approval before any build. Budget guard hook (`_tools/budget_guard.py`) is in `.claude/settings.json`.

**Next (before r4 was drafted):**
1. The designer plays the exe; Dev mode opens with the backquote key. Gather the play-test notes into revision 4.
   "Open for revision 4" in the report already lists: button focus styles painting over the disabled look (item 7), the Sell icon sits over the hive, the truck clips the shop
   corner on its way out, rcedit, `dev_mode` false for store builds, and an Android test.
2. `content/onboarding-script.md` must follow the new harvest flow when it is revised ([[pending-approvals]]).

**How to apply:** in the CLI keep replies short and put long material in Markdown files. Process rules from this
session: [[dev-mode-and-pacing]] (Dev mode in every spec, slow placeholders, tests from the spec).
