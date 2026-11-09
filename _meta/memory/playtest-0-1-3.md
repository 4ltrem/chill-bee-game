---
name: playtest-0-1-3
description: "Designer's 0.1.3 play-test notes (2026-11-06): UI broken - Back inconsistent, Spin/Harvest buttons move, x5 tag overlaps top-left text; not fixed yet"
metadata:
  node_type: memory
  type: project
  originSessionId: 49ba7bdd-dbda-4adf-93f8-abf4c4364924
  modified: 2026-11-06T20:38:49.989Z
---

The designer played 0.1.3 (worktree exe, commit 59e11bd) on 2026-11-06 afternoon. Verdict: "the ui is fucked". They said **don't fix yet, just note**:

1. **Back button is inconsistent**: its position or behaviour varies between views. The Back spot at the second stop comes from a scan, not a fixed place, which is the likely cause.
2. **Spin and Harvest buttons change location** between views or stops. Spin is moved out of FarmUI at runtime by `main.gd`, and one marker height serves both views.
3. **The game-speed tag (e.g. "x5") overlaps other text in the top-left** HUD.

**UI direction from the Round 7 vote (2026-11-06, `game/reports/ui-compare/decisions.json`):** 0.1.3's layout won (yes); ab-A and ab-B got no. For the next revision:
- Make the hive frames and combs bigger, to match the pile size.
- Move the honey meter into the Harvest button: its background fills up slowly. Put the hive count ("5/10") just above the button.
- Bees and money stay at the top.
- Place Harvest lower. In the farm view it goes just above the hive lid; at the second stop it can sit on the lid.
- Spin goes just above the centrifuge lid.
- Sell sits lower; ab-A's Sell placement is the known good one.

**Merged-build play-test (11/6, later):** at the second stop, after the centrifuge fills and pours, the player has to tap Spin again before the pile loads. It should load on its own in every view. This is item 7 of `game/specs/0.1.4-ui-placement.md`.

**Recordings of this play-test:** `%APPDATA%\Godot\app_userdata\Chill Bee Game\recordings\2026-11-06-279.json` (14:33) and `2026-11-06-280.json` (14:35, 2 MB). Replay them to reproduce the bugs. The other ~278 files there are from the 03:00 test runs. The tests write into the player's recordings folder, which is a side issue to clean up.

**Why:** these are the 0.1.3 play-test results the merge was waiting on. The designer wants them fixed later, not in this session.

**How to apply:** when the next UI or 0.1.x revision is specced, put these in it as items, with fixed HUD anchors for Back, Spin and Harvest and no overlap in the top-left. The designer decided (2026-11-06) that they do not block the merge: merge 0.1.3 now and fix these in the next revision. See [[session-handoff]].
