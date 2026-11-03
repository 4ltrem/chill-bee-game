---
name: guide-playtest
description: "Later: playtest four onboarding guide characters (Melli, Pip, Lady Aura, Miel) instead of choosing one; parked 2026-11-03 for the first prototype"
metadata:
  node_type: memory
  type: project
  originSessionId: fa5df4be-6365-415d-bd06-9f0be0bb573b
  modified: 2026-11-03T21:26:35.308Z
---

The designer wants to keep several guide characters and let playtests pick (2026-11-03). Parked until after the
first prototype. Suggested shortlist, one per distinct personality, v1 names where the drafts overlap:
Melli (warm queen; absorbs v2's Queenie), Pip (excitable scout; absorbs Bixby), Lady Aura (regal, dry wit; v1 only),
Miel (poetic elder drone, name works in French; v2 only). v1 options are in
`content/_runs/onboarding-script-v1/draft.md`, v2 in `content/onboarding-script.md` (Decisions needed).

**Why:** both drafts share one `[GUIDE]` script, so the characters only differ by name; a playtest needs each to have
their own signature lines (welcome, first harvest, first sale, first upgrade, hand-off, EN + FR).

**How to apply:** when the designer returns to onboarding, offer: a `generate.py onboarding-script --revise` run for
signature lines (~250-400k tokens), a GDD line "four candidate guides, chosen by playtest" (designer's call), a
guide switch in the build (Patricia), and optionally Gerard for the playtest design. Approve the onboarding script
only after that revision. Related: [[pending-approvals]].
