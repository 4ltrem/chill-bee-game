---
session: 4ccf1614-06de-4d77-a86f-48a1fbf341b4
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: 0.1.4 play-test items 16-21, budget guard on average cost, repo-only becomes write-only
---
# Decisions: session 4ccf1614 (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D187 · 2026-11-08 · Cost & structure · Budget guard uses each agent's average cost; the heavy line stays at 10%
- Decided: "change budget guard to check average token count run not highest" (`budget_guard.py --costs` prints the averages: Patricia 6%, Quinn 5%, Bob 4%); "no don't lower it", so only general-purpose (10%) and Workflow (40%) count as heavy.
- Files: `_tools/budget_guard.py`, `_tools/test_generate.py`

### D190 · 2026-11-08 · Game build · Dev mode saves only edited values (item 16)
- Decided: "the windows build I played is an old version the combs are small": the Dev snapshot (`frame_scale = 0.85`) overrode the new default. "yes both": the old file renamed to `dev_config.old.tres`, and the panel saves only edited values.
- Files: `game/specs/0.1.4-ui-placement.md` (item 16), commit `b385d39`

### D191 · 2026-11-08 · Game build · Comb hitbox scaled to the drawn cell (item 17)
- Decided: "the combs look right now, the hitbox seems off tho": a drag over a drawn cell uncaps it and never its neighbour, with a thin collider scaled with the mesh.
- Files: `game/specs/0.1.4-ui-placement.md` (item 17), `game/scenes/props/honey_cell.tscn`

### D192 · 2026-11-08 · Workspace & agents · Repo-only becomes write-only; reads outside the repo no longer prompt
- Decided: "cant we just replace the cantreadoutsidework with cant writeoutsidework rule?" and "update the hook too so reads outside don't prompt". Writes outside stay blocked; moving or deleting outside files needs a yes. Replaces D127's read limit. The laptop needs the same three settings lines.
- Files: `_meta/memory/repo-only.md`, `.claude/settings.local.json`

### D193 · 2026-11-08 · Game build · Web Dev panel: physical key plus an on-screen Dev button (item 18)
- Decided: the Dev panel didn't open in the web build ("tried in operagx and edge"); it now opens on the physical key and from a small Dev button at the left edge (Dev mode only). Local server stopped ("stop the web server for now").
- Files: `game/specs/0.1.4-ui-placement.md` (item 18), `_tools/build.py` (`--serve`)

### D196 · 2026-11-08 · Game build · Items 19–21: frames empty after harvest, Spin moves down, truck loads whenever home
- Decided: play-test: frames full after going down, Harvest too high when Spin shows, honey left on the crate. For the overlapping buttons the designer chose "Spin moves down": Harvest holds its anchor, Spin yields down by `button_gap_px` (8). Commit `948a49e`.
- Files: `game/specs/0.1.4-ui-placement.md` (items 19–21)

## Still open

- See the newest log, `_meta/sessions/2026-11-09-4be1c5ef/decisions.md`.
