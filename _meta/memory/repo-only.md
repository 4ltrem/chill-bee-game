---
name: repo-only
description: "Write only inside the repo (hook-enforced); reading outside it is fine (designer 2026-11-08, replaced the read-only-inside rule)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 4ccf1614-06de-4d77-a86f-48a1fbf341b4
  modified: 2026-11-09T01:05:25.050Z
---

Write, edit and create files only inside the MAIGD repo. Reading outside it (game user data in `%APPDATA%/Godot/app_userdata/Chill Bee Game/`, logs, tool output) is allowed without asking first.

**Why:** the designer, 2026-11-08: "cant we just replace the cantreadoutsidework with cant writeoutsidework rule?". The rule before (2026-11-07, "don't need to read outside this repo unless you can explain to me why") made me stop and explain before reading the game's saved `dev_config.tres`, which turned out to be the cause of a play-test bug.

**How to apply:** `.claude/settings.local.json` allows `Read`, `Grep` and `Glob` everywhere, so outside reads don't prompt. Read outside freely when it helps, and say what I read in the reply. Writes outside stay blocked by `_tools/guard_shell.py` (drafts-folder rule: no Write/Edit outside the repo except plan files). Moving or deleting a file outside (as with the stale `dev_config.tres`) still needs the designer's yes. "analyze the last sessions" still means `_meta/sessions/`, the handoff, drafts and git. For Design Votes, build from `game/reports/ui-compare/design-votes.html` ([[ab-comparison-page]]).

**In Bash:** use repo-relative paths for repo files. No `cd` prefix and no `C:\Users\...` paths into the repo; `guard_shell.py` refuses both, because the permission check counts absolute paths as outside the repo. Edit files with Edit ([[edit-lines-only]]).
