---
name: look-before-done
description: "Never report a model/scene change done on passing tests alone; compare a fresh render with the designer's picked variant first"
metadata:
  node_type: memory
  type: feedback
  originSessionId: b89522de-aba2-47a2-852d-34d76b9bf1f3
  modified: 2026-11-08T07:33:43.149Z
---

Before reporting any Bob/Milo model or scene change as done (goal agent, style loop, or by hand), take fresh shots (`ui_shots.py`) and compare them side by side with the designer's picked variant render (e.g. `game/reports/variants/<prop>-r<n>/<pick>.png`). Passing tests are not enough.

**Why:** 2026-11-08, the designer had to correct the hive/frame models "the second or third time": C5 shipped a shallow hive missing a wall with two flat frames instead of round 9 pick "a" (deep box, four walls, five upright frames), while all 150 tests passed and I reported 32/32 done. The goal agent never ran the style loop, and Vera checks style rules, not the pick.

**How to apply:** after any goal-agent run that touched `scenes/`, look at the shots before reporting; name any mismatch with the pick as a spec item. Tool fix built 2026-11-08: goal_agent runs one style-loop round on every Bob change and `_tools/pick_match.py` (live prop beside the pick, Vera judges match only) on any item naming a variant; by hand, `pick_match.py <live> <pick> --no-agent`. The first render of the live hive showed it needs `--hide=HiveLid` and a settle wait (hive.gd rescales on _ready); both are in (see [[session-handoff]], [[scripted-shots]], [[variant-shots]]).
