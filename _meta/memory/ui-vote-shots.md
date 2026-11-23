---
name: ui-vote-shots
description: "UI vote shots run with --set ui_bounds=true (and show_hint=false); icon overlap is judged on the drawn circles, not the 120 px touch rects"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 385322cc-1787-4260-a67d-1d43a99c3e18
  modified: 2026-11-23T23:20:56.266Z
---

Every `ui_shots.py` run for a UI Design Votes section passes `--set ui_bounds=true` (the Dev "Show UI bounds" overlay, wired in `game/tests/ui_compare_shots.gd`) and `--set show_hint=false` so the first-time hint does not cover the icons. When two floating icons are checked for overlap, compare their drawn circles (`FloatingIcon.visible_global_rect()`), not their touch rects; other HUD controls are still checked against the touch rect.

**Why:** designer, 2026-11-23 (spin-farm vote): "when comparing overlap compare visual not touch area, perhaps that rule needs to be revised"; "for UI votes make sure the ui bounds is turned on when taking the shots". The touch-rect rule (0.1.4 item 20) pushed Spin down onto the centrifuge lid where it was hard to see.

**How to apply:** add both `--set` flags to every UI vote shot command; in specs and tests, word icon-vs-icon overlap as drawn shapes. Related: [[ab-comparison-page]], [[ui-design-prefs]], [[scripted-shots]].
