---
name: no-select-string
description: "Never filter output or search files with PowerShell Select-String; use the Grep tool, or read the output/file directly"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 28475ef9-e95c-4529-bb2f-7df1fc9c11f8
  modified: 2026-11-08T20:18:59.120Z
---

Don't use `Select-String` in PowerShell commands, neither to search files nor to filter a command's output.

**Why:** the designer, 2026-11-08: "dont use select-string" (after several commands piped through it).

**How to apply:** search files with the Grep tool; for a script's output, let it print in full (or `Select-Object -Last N`), or have the script write a file and Grep or Read that. Related: [[no-inline-python]], [[edit-lines-only]].
