---
name: french-house-style
description: "French UI text addresses the player as \"vous\"; Bee Journal = \"Carnet des abeilles\", Shop = \"boutique\", Sell = \"Vendre\""
metadata:
  node_type: memory
  type: feedback
  originSessionId: b80d1f98-5ab8-4175-855f-9399551ac79b
  modified: 2026-11-23T17:28:57.956Z
---

All French UI text uses formal "vous" (designer, 2026-11-22, course-ending-text). The Bee Journal's French name is "Carnet des abeilles". The Shop is "la boutique" and Sell is "Vendre" (designer approved `content/first-time-hint.md` as written, 2026-11-23); the harvest tool is "la fourche". Prices in French put the number first ("Vendre %d $", Canadian order); Settings = "Paramètres"; "Coming soon" = "À venir" (`content/ui-labels.md`, approved 2026-11-23).

**Why:** the designer picked one house style over William's "tu" draft; no French Journal name existed before.

**How to apply:** brief William with both rules on any French content run; check older FR strings (e.g. `game/translations/journal.csv`) for "tu" before the next build. Related: [[pending-approvals]].
