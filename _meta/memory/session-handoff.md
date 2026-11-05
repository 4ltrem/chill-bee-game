---
name: session-handoff
description: Where work stands after Prototype 0 revision 3 was built (2026-11-04); read first in the next session
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

**Next (before r4 was drafted):**
1. The designer plays the exe; Dev mode opens with the backquote key. Gather the play-test notes into revision 4.
   "Open for revision 4" in the report already lists: button focus styles painting over the disabled look (item 7), the Sell icon sits over the hive, the truck clips the shop
   corner on its way out, rcedit, `dev_mode` false for store builds, and an Android test.
2. `content/onboarding-script.md` must follow the new harvest flow when it is revised ([[pending-approvals]]).

**How to apply:** in the CLI keep replies short and put long material in Markdown files. Process rules from this
session: [[dev-mode-and-pacing]] (Dev mode in every spec, slow placeholders, tests from the spec).
