---
name: placeholder-visuals-0-3
description: "For the 0.3.0 build, goal-agent visual-number stops are resolved by me: keep the agent's placeholder values if close to UI_DESIGN.md, no Design Votes round; designer confirms at play-test"
metadata:
  node_type: memory
  type: feedback
  originSessionId: b80d1f98-5ab8-4175-855f-9399551ac79b
  modified: 2026-11-22T18:25:16.595Z
---

Designer, 2026-11-22 (on mobile, chat only): "Just take the placeholders and compare to the UI design we decided on as long as it's close enough I can confirm when I play test later."

**Why:** the 11/29 deadline, and the designer couldn't open Design Votes while away; votes would block the goal agent.

**How to apply:** when `goal_agent.py` stops on `visual numbers` during the 0.3 course build, check the change against `UI_DESIGN.md` rules (count pill order number-icon-+, icons over the farm, no nav bar, sheets/overlays over the dimmed farm, STYLE_GUIDE palette tokens). If close, resume with `--note` recording "placeholder, designer confirms at play-test". If it breaks a rule, fix it or ask. List every placeholder value in the chat summary so the play-test can check them. Overrides [[ab-comparison-page]] for this build only.
