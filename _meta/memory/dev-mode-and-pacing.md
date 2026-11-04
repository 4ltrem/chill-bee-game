---
name: dev-mode-and-pacing
description: Every game spec includes an in-game Dev mode for live tuning; every tunable lives in the config; prototype pacing should be unhurried
metadata:
  node_type: memory
  type: feedback
  originSessionId: 864dbfb5-1b7c-49cd-bf94-214920851b62
  modified: 2026-11-04T00:13:54.190Z
---

Designer, 2026-11-04, reviewing the Prototype 0 revision 3 spec:
- Every tunable number goes in the game's config (`game/scripts/game_config.gd` / `default_config.tres`), and every spec from now on includes a **Dev mode** so the designer can adjust values in game while playing. Recorded in `game/CONTEXT.md`, Process step 3.
- The placeholder numbers I proposed were "kinda too quick". Example: 0.4 s per jar when "honey is viscous, it wouldn't take .4s per jar without a serious upgrade".

**Why:** the designer tunes by feel during play, and fast base values leave nothing for upgrades to improve.

**How to apply:** when proposing placeholders, err slow and physical (bottling ~3 s/jar, truck trip ~30 s), and leave the speed-ups to upgrades. In every spec, add a Dev mode section and make tests read values from the config. Related: [[session-handoff]].

Also designer, 2026-11-04: **tests are written from the spec, before or alongside the code**. The last two prototype rounds broke tests that had been written after the code. Quinn runs in parallel with Patricia and doesn't read her in-progress code. Recorded in `game/CONTEXT.md`, Process step 2.
