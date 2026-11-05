---
name: itch-upload-rule
description: "Upload to itch.io only when a new milestone number is reached (0.2.0, 0.3.0); builds inside a milestone are played locally"
metadata:
  node_type: memory
  type: feedback
  originSessionId: d82fcc79-9cc5-4d4c-a928-3c60ef6b12e5
  modified: 2026-11-05T17:42:26.846Z
---

Upload a build to itch.io (4ltrem.itch.io/chill-bee-game) only when the version reaches a new milestone number
(0.2.0, 0.3.0). Builds within a milestone (0.1.2, 0.1.3 ...) are played locally from `game/builds/`. Recorded in
MILESTONES.md.

**Why:** the designer said so on 2026-11-05 to save time while the layout is being fixed. 0.1.0 is already on itch,
which covers M1's web-export deliverable.

**How to apply:** don't list "upload to itch" as a step after each build; raise it at the first build of a new
milestone, and for the final course build (M5). Related: [[course-milestones]], [[session-handoff]].
