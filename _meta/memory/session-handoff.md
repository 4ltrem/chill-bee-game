---
name: session-handoff
description: Where work stood when the designer moved from the VS Code extension to the terminal CLI (2026-11-03); read first in the next session
metadata:
  node_type: memory
  type: project
  originSessionId: fa5df4be-6365-415d-bd06-9f0be0bb573b
  modified: 2026-11-03T23:49:49.467Z
---

On 2026-11-03 the designer moved from the VS Code extension to the terminal `claude` CLI, run in VS Code's
integrated terminal and connected with `/ide`. The reason: the status line (`_tools/statusline.py`) only runs in the
CLI, and it records plan usage ([[usage-calibration]]). The old session was closed with the end-of-day routine, and
the CLI session started fresh as a new day. Plan: Claude Team, for the duration of the designer's course.

**Next up, in order:**
1. Write the Prototype 0 revision 3 spec (`game/specs/prototype-0.md`) from GDD §2 (harvest flow: fork icon, frame
   queue, centrifuge with a physical crank you tap or hold, Continue, bottling, sales truck; Long Fork is a later
   upgrade, not in this prototype). Include the 5 items under "Open for revision 3" in
   `game/reports/2026-11-03-prototype-0.md` (Bob's harvest light washing out the uncapping pop; the shop overlap;
   gold Extract button; disabled Upgrade contrast). Prototype values: 1 frame fills the centrifuge; the truck holds
   10 jars. Show the spec to the designer before any agent builds.
2. Before launching Patricia, Bob and Quinn: ask the designer to nudge the status line (any message in the CLI) so
   `_meta/usage/readings.jsonl` has a fresh reading; again after the batch; then run
   `python -I _tools/runlog.py --calibrate SINCE` and record the second calibration in `_meta/agent-runs.md`.
3. `content/onboarding-script.md` must follow the new harvest flow when it is revised ([[pending-approvals]]).

**Why:** a fresh session reloads only memory and the docs. Each orchestrator call re-reads its whole context, and
the old session had reached ~162M tokens processed.

**How to apply:** read this at the start of the next session. The designer prefers reading long replies in a
rendered panel, and the terminal renders long tables poorly: in the CLI, keep replies short and put anything long
(tables, reports, specs) in a Markdown file the designer can open in VS Code's preview. Delete this memory once
revision 3 is underway.
