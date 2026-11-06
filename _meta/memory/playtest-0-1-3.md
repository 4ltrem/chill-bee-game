---
name: playtest-0-1-3
description: "Designer's 0.1.3 play-test notes (2026-11-06): UI broken - Back inconsistent, Spin/Harvest buttons move, x5 tag overlaps top-left text; not fixed yet"
metadata:
  node_type: memory
  type: project
  originSessionId: 49ba7bdd-dbda-4adf-93f8-abf4c4364924
  modified: 2026-11-06T19:37:29.655Z
---

The designer played 0.1.3 (worktree exe, commit 59e11bd) on 2026-11-06 afternoon. Verdict: "the ui is fucked". They said **don't fix yet, just note**:

1. **Back button is inconsistent**: its position or behaviour varies between views. The Back spot at the second stop comes from a scan, not a fixed place, which is the likely cause.
2. **Spin and Harvest buttons change location** between views or stops. Spin is moved out of FarmUI at runtime by `main.gd`, and one marker height serves both views.
3. **The game-speed tag (e.g. "x5") overlaps other text in the top-left** HUD.

**Recordings of this play-test:** `%APPDATA%\Godot\app_userdata\Chill Bee Game\recordings\2026-11-06-279.json` (14:33) and `2026-11-06-280.json` (14:35, 2 MB). Replay them to reproduce the bugs. The other ~278 files there are from the 03:00 test runs. The tests write into the player's recordings folder, which is a side issue to clean up.

**Why:** these are the 0.1.3 play-test results the merge was waiting on. The designer wants them fixed later, not in this session.

**How to apply:** when the next UI or 0.1.x revision is specced, put these in it as items, with fixed HUD anchors for Back, Spin and Harvest and no overlap in the top-left. The designer decided (2026-11-06) that they do not block the merge: merge 0.1.3 now and fix these in the next revision. See [[session-handoff]].
