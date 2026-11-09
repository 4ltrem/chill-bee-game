---
name: fix-needs-commit
description: Never record a bug as fixed without the commit that changed the code for it; a passing test alone is not a fix
metadata:
  node_type: memory
  type: feedback
  originSessionId: 28475ef9-e95c-4529-bb2f-7df1fc9c11f8
  modified: 2026-11-08T19:49:32.649Z
---

A fix is only "fixed" when a commit changed the code or scene that caused the bug, and the handoff names that commit. A green test, a ledger entry or the designer's impression are not enough.

**Why:** 2026-11-08 the handoff said "lid fixed (designer confirmed)", but no lid code was ever changed: Quinn's lid test (T14.3, `t_lid_closes_clear_of_walls`) passed on the unchanged build, the goal agent committed it green in `720d42d` with only comb-size changes, and the lid still clipped. Designer: "this shouldn't have happened, a fix should always be committed."

**How to apply:** before writing "fixed" in a handoff or report, `git log` the files that own the bug and cite the commit; a play-test test must fail on the current build before any fix counts. Related: [[look-before-done]], [[session-handoff]].
