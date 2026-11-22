---
name: look-up-before-asking
description: "Never ask the designer something the workspace already answers (canvas boards, UI_DESIGN.md, TBD list, decisions); apply it and cite the file"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 85235484-765e-4628-a8d3-15ccb1da8a7b
  modified: 2026-11-22T23:32:40.889Z
---

Before asking the designer anything (AskUserQuestion, a run stop, a `(designer)` row), look for the answer in what is already built or listed: the Claude Design canvas boards (`proposals/design/ui-screens-mockup/project/`), `UI_DESIGN.md`, `README.md` Outstanding TBDs, `proposals/design/ui-screens.md`, `_meta/sessions/*/decisions.md`. If one answers it, apply that answer and cite the file. If it is a listed TBD, build the placeholder and name the TBD.

**Why:** 2026-11-22, designer: "I shouldn't have to specify something that is already built and on the todo or tbd list". The 0.3 goal run stopped on the shop layout already drawn in `Shop.dc.html`, and I then asked the same question again with AskUserQuestion.

**How to apply:** this is `LAYOUT_RULE` in `_tools/goal_agent.py` for Bob and Patricia; the same rule applies to my own questions. Where a source and the spec conflict, the spec wins; ask only when they truly conflict on something that changes the build. Related: [[ask-with-quiz-tool]], [[placeholder-visuals-0-3]], [[ui-design-prefs]].
