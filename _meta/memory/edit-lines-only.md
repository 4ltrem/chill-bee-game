---
name: edit-lines-only
description: "Change files by editing only the needed lines (Edit tool), never by scripts that read and rewrite the whole file"
metadata:
  node_type: memory
  type: feedback
  originSessionId: d82fcc79-9cc5-4d4c-a928-3c60ef6b12e5
  modified: 2026-11-06T04:58:10.136Z
---

Modify only the lines that need changing, with the Edit tool. Do not use Python or sed scripts that read a whole file
and write it back, even when the resulting diff is small.

**Why:** the designer asked for it on 2026-11-05 after watching whole-file rewrite scripts for GDD, README, spec and
STYLE_GUIDE edits. Whole-file rewrites hide what changed, can flip line endings, and overwrite edits made in parallel
(agents, the other machine).

**How to apply:** use Edit (old/new string) for every doc and spec change, one call per change, in parallel when they're independent.
No `sed -i` or `cat >>` either (I slipped on 2026-11-05). Since 2026-11-05 the rule is also rule 5 in `_meta/team.md` and in the definitions of Bob, Patricia, Quinn, Milo and Martin; `.gitattributes` forces LF so tools stop flipping files to CRLF. Brief agents with line ranges to read.
Generated files are rebuilt by their own scripts (`index.py`, `sync_docs.py`) as before. Related: [[session-handoff]].
