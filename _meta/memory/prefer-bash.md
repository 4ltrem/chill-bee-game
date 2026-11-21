---
name: prefer-bash
description: "Run shell work in the Bash tool with Linux tools (grep, tail, head, git), not PowerShell cmdlets"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 28475ef9-e95c-4529-bb2f-7df1fc9c11f8
  modified: 2026-11-17T21:02:33.487Z
---

Use the Bash tool (Git Bash) and Linux tools for shell work: `tail -n`, `head`, `grep`, `wc`, `git`, `env VAR=x cmd`. Don't reach for PowerShell cmdlets (`Select-String`, `Get-Content`, `Select-Object`, `$env:` assignments).

**Why:** the designer, 2026-11-08: "prefer linux tools over powershell" (right after "dont use select-string").

**How to apply:** default to Bash; repo-relative paths only (guard_shell rule 3); no `VAR=value` prefixes: pass settings as script flags (`python -I _tools/godot_run.py unit --time-scale 6`, render.gd `-- --scene … --out …`); PowerShell only for something Bash can't do on Windows. File searches still go through the Grep tool. Related: [[no-select-string]], [[no-inline-python]].
