---
author: orchestrator
type: ui-design
status: draft
description: The designer's UI preferences and the current state of the UI mockups (2026-11-09), so the next session starts from them; GDD.md and STYLE_GUIDE.md still decide
---
# UI design: preferences and current state

The designer's stated UI preferences, collected from the 2026-11-09 session. Each one quotes or points to what the designer said. Nothing here reaches `GDD.md` until the designer accepts `proposals/design/ui-screens.md`; `STYLE_GUIDE.md` rules (V9–V13, UI tokens) still apply and win on conflict.

**Where the work is**
- Canvas: "Chill Bee UI Screens", https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca (private; pages 0–6, below).
- Source copy: `proposals/design/ui-screens-mockup/project/` (the canvas is newer when the designer has edited on the page: read it from the canvas first).
- Proposal: `proposals/design/ui-screens.md` (status proposed; function → screen table and open decisions).
- Base screenshots: `game/reports/votes/spin/round-1/c/` (the spin-r1 pick), uploaded to the canvas as assets.

## 1. Design rules (designer's preferences)

| # | Rule | Source |
|---|---|---|
| 1 | Start from the game's real screenshots and draw only the new UI on top. Never redraw the harvest loop or any screen the build already shows. | "use the screenshots we already have and build the UI on top" |
| 2 | No navigation bar. Round icons float over the farm, each with a label, clear of the top info and the Harvest/Spin/Sell anchors. | "icons over the screen are preferred over a navigation bar" |
| 3 | Zooms hide the rest of the icon rail, but **Shop stays** (the full shop, so the player can upgrade at any time), with the Tools icon beside it (bottom-right) for the machine's own upgrades. Back (top-right) is the only exit. | 0.1.4 spec items 3, 8; canvas boards 2–3 (not yet redrawn with Shop); designer 2026-11-21: "the shop button should be available while zoomed in still so the player can upgrade at any time", then picked Shop + Tools |
| 4 | Harvest is a white circle with a honey uncapping fork; the honey meter rises behind the fork from the bottom; n/10 stays above it. | "replace harvest button with honey scrapper fork icon, white background"; "honey meter should be rising behind the fork" |
| 5 | The bottom panel is decided by play-test: A = today's quick-buy plus a Shop icon (default), B next-unlock goal, C habitat strip, D guide task strip. | "final decision to be decided by playtest, have both and also have 3 other options" |
| 6 | Icons have a clear real-world shape: Journal = a bee, Tools = a proper wrench, Settings = a toothed gear, Impact = a green leaf. | canvas comments 2026-11-09 |
| 7 | Royal Jelly = variant K: H's three-cell comb in G's style (gold cells, amber centres) turned 60°, upright crown lowered so it overlaps the comb. Values: angle 60°, crown drop 1.8, lift −2.6 (24-unit viewBox). | "need a mix of G and H"; "60 degree, just need the crown to overlap it and be lower"; "I meant K" |
| 8 | Crowns stay upright, never tilted with the object under them. | "crown to rest on top of the dipper but not on an angle" |
| 9 | In a count pill the number comes first, then the icon, then +; each is its own element. | "swap the dipper and 12 positions" |
| 10 | Mockups are organised one group per canvas page. | "organize these mockups into their respective art boards" |
| 11 | Motion is shown on interactive boards: fork meter fill with a pulse at full, sheets sliding up over the dimmed farm. | "can you do animations in this thing?" → "yes" |

## 2. Working rules for UI sessions

1. **Show, don't guess geometry.** For a shape, angle, offset or size, show three or more lettered variants on one board, and give the likely pick sliders in the Tweaks panel. Restate the chosen letter and its values before applying it (L29).
2. **Change shared parts once.** Icons live in the shared `Icons.dc.html` overlay; skins in `SkinPhone.dc.html`. Edit those, not each board.
3. **Read before every publish.** The designer edits on the page while work runs. Read the live file, diff it against the local copy, apply the change to the live version, publish (L27).
4. **Canvas markup:** every text in its own element (L26); bind whole attribute values from `renderVals()`, not holes inside SVG strings (L28).
5. **Say what wasn't seen.** Nothing on the canvas is rendered by the orchestrator; say so when reporting a visual change.
6. **On "stop" under a `/goal`,** stop, and point once to `/goal clear` (L30).

## 3. Canvas map

| Page | Boards |
|---|---|
| 0 Prototype | the designer's copy of the interactive prototype |
| 1 Farm & harvest | Farm view (slot A), shared icon overlay, first zoom, second stop, welcome back, Prototype (fork meter + Shop sheet; press Play) |
| 2 Bottom slot options | B, C, D |
| 3 Icon screens | Shop, Build, Habitat & Refinery, Royal Crystal, Bee Journal |
| 4 Meta screens | Worlds, Impact, Store, Settings, first launch |
| 5 Coverage & legend | 37-row GDD coverage table, icon legend, Royal Jelly variants A–M (K has sliders) |
| 6 Skins | five palettes (Honey Classic, Meadow Mint, Wildflower, Sky Glass, Wood & Brass) and one skin per biome |

## 4. Open decisions

1. Bottom slot A/B/C/D: by play-test.
2. Skin: one palette, or one per biome (page 6). Every palette except Honey Classic, and the Impact leaf's green, would be new UI tokens in `STYLE_GUIDE.md` (designer only).
3. K's large preview should now follow the sliders (L28): designer to confirm.
4. The seven decisions at the end of `proposals/design/ui-screens.md` (icon placement, when icons appear, Tools icon, Habitat + Refinery on one sheet, parental gate, GDD TBDs).
5. The farm-view zooms, Spin and Sell are still the 0.1.4 look; only Harvest became an icon.
