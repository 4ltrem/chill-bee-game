---
author: designer
type: style-guide
status: approved
decision: approved by the designer 2026-11-05, after the review (Biome glow and Bee roles, UI border and shop panel tokens, V2 scoped to harvest views, V5 budget provisional)
description: The rules every generated asset and text must follow, with an ID per rule. Visual rules (V) are checked by `_tools/style_check.py` and the style critic over Bob's scenes and screenshots; Voice rules (T) by Clara over William's drafts. Sources are GDD.md (Aesthetic & Tone, Technical Constraints, Accessibility, Child Safety, Glossary) and the approved specs
---
# Chill Bee Game style guide

One guide, two critics. **Visual** rules are enforced on Bob's scenes (generator: Bob; evaluator: `_tools/style_check.py` for what can be measured, then the style critic looking at the screenshots; refiner: Bob). **Voice** rules are enforced on William's text (generator: William; evaluator: Clara; refiner: William). The GDD decides; where this guide and the GDD disagree, the GDD wins and the guide gets fixed.

Each rule has an ID, a statement, **how it is checked** (`script`: measured by `style_check.py`; `critic`: judged on screenshots or text), and its source. A FAIL row always names the rule ID.

## The look in one paragraph

A cozy pocket world seen as a floating diorama: minimalist low-poly 3D, vibrant pastel greens and sky blues, warm honey golds as the one thing that glows on the farm, chunky rounded shapes, nothing sharp, cluttered or gloomy (night biomes stay soft and lantern-lit, never scary). Honey is the hero colour; everything else stays calm so the honey reads. (GDD, Aesthetic & Tone: "Minimalist 3D low-poly with vibrant pastel greens … clean isometric terrain chunks that fit together like floating diorama pieces.")

## Phases

| Phase | Applies | What changes |
|---|---|---|
| **colorbox** (now: 0.x until art lands) | V-rules marked *all* and *colorbox* | primitive meshes and shared flat materials only |
| **art** (purchased low-poly packs, GDD Art Source) | V-rules marked *all* and *art* | pack models adapted to the palette; flat-colour palette atlas |

The current phase is set in `style_check.py --phase` (default `colorbox`).

## Palette (V1)

Every material colour must sit near one of these tokens (script: distance in Lab colour space, ΔE ≤ 12 by default). Tokens (sRGB 0–1) are grouped by role; each role limits where its colours may be used (after the colon).

- **Meadow**: terrain, backdrop
  - ground (0.62, 0.84, 0.52)
  - sky (0.79, 0.91, 0.96)
- **Blossom**: flowers
  - pink (0.97, 0.66, 0.78)
  - lilac (0.78, 0.70, 0.93)
  - buttercup (1.0, 0.85, 0.30)
- **Honey** (glows): cells, honey, jars
  - capped (0.85, 0.68, 0.18)
  - uncapped (1.0, 0.80, 0.15)
  - honey (1.0, 0.75, 0.10)
  - amber (0.95, 0.65, 0.10)
  - wax (0.96, 0.92, 0.80)
- **Bee**: bees only
  - bee yellow (1.0, 0.88, 0.10)
  - bee stripe (0.22, 0.18, 0.12) *provisional*
- **Biome glow** (glows; *provisional*, confirmed when the biome is built): glowing clover patches (GDD Art Style), Enchanted Grove mushrooms only
  - clover glow (0.70, 0.95, 0.55)
  - mushroom glow (0.60, 0.90, 0.95)
- **Wood**: hive, frames, crate, truck bed
  - hive (0.85, 0.72, 0.50)
  - lid (0.60, 0.45, 0.28)
  - frame (0.55, 0.35, 0.20)
  - crate (0.50, 0.33, 0.18)
- **Metal**: centrifuge, spigot, crank arm
  - steel (0.60, 0.66, 0.74)
  - steel dark (0.45, 0.50, 0.58)
  - iron (0.33, 0.33, 0.37)
- **Glass**: bucket, jars
  - glass (0.75, 0.85, 0.90), alpha ≤ 0.35
- **Shadow** (small parts only): chassis, tyres
  - charcoal (0.25, 0.25, 0.28)
  - tyre (0.10, 0.10, 0.10)
- **Accent** (approved one by one): the truck's paint, the crank handle
  - truck red (0.75, 0.20, 0.20)
  - crank orange (0.95, 0.50, 0.20)
- **UI**: text, buttons, panels
  - ink (0.20, 0.12, 0.02)
  - gold (1.0, 0.76, 0.12)
  - gold dark (0.82, 0.58, 0.05)
  - cream (1.0, 0.96, 0.86)
  - panel (0.38, 0.34, 0.30)
  - border (0.35, 0.22, 0.05)
  - shop panel (0.30, 0.22, 0.10)

New token: proposed in a FAIL row's Fix and added here by the designer, never by an agent.

## Visual rules

| ID | Rule | Check | Phase | Source |
|---|---|---|---|---|
| V1 | Every material colour is within ΔE 12 of a palette token, in a role allowed for that object. | script | all | GDD Art Style; this palette |
| V2 | Only Honey-role and Biome-glow-role materials emit light, and Biome glow only on its own flora. In a harvest view, only honey glows. | script | all | GDD Art Style (glowing clover), §2 (glowing honey), Biomes (glowing mushrooms); spec 0.1 |
| V3 | **Accents are rare:** at most 2 accent-role colours per screen, each on one object. | script (count) + critic | all | the calm-palette rule above |
| V4 | Primitive meshes only (`BoxMesh`, `CylinderMesh`, `SphereMesh`, `PlaneMesh`, `PrismMesh`, `CapsuleMesh`); no imported meshes; no textures. | script | colorbox | spec 0.1, Look: colorbox |
| V5 | Low-poly: no mesh above the vertex budget (default 2,000 per mesh, *provisional*: the GDD says only "low vertex counts"; Terry or the profiler sets it), flat-colour atlas only. | script | art | GDD Technical Constraints |
| V6 | Shapes are chunky and rounded in feel: no thin spikes or knife edges facing the camera; nothing thinner than 0.05 units unless it is a rim or a handle. | critic (+ script for size) | all | GDD Bees & Characters ("chunky, rounded") |
| V7 | The scene reads as a calm diorama: one clear focal object per view (the honey's step in the loop), no clutter, nothing important cut off by the screen edge. | critic | all | GDD Art Style |
| V8 | Honey is the hero: in any harvest view, the brightest, most saturated thing on screen is honey (cells, honey level, jars). | critic | all | this guide |
| V9 | Information never relies on colour alone: states differ in shape, height, size or label too. | critic | all | GDD Accessibility, Colour-Blind Support |
| V10 | UI text contrast ≥ 4.5:1 against its background, including disabled buttons. | script (scene colours) + critic (screenshot) | all | GDD Accessibility; spec r3 |
| V11 | Touch targets ≥ 120 × 120 px at 720 × 1280; icons may look smaller (`icon_visual_px`), their touch area may not. | script | all | GDD One-Handed Play; spec 0.1 |
| V12 | Text sizes: body ≥ 28 px, buttons ≥ 32 px at 720 × 1280; UI fonts use the ink outline. | script | all | farm UI (r3) |
| V13 | No farm prop, icon or modal sits under the shop panel or the top info; icons may overlap props. | critic (screenshot) | all | spec 0.1 |
| V14 | Cells at the uncapping zoom are ≥ 20 px wide on screen (was 44 px; the 5 × 5 farm with the hive at 1.4× measures 21.6 px). | script (Quinn's measure) | all | spec 0.1.1; designer 2026-11-05 (round 4, c-1) |
| V15 | Glass reads as glass: see-through (alpha ≤ 0.35, back faces drawn), honey visible through it. | script + critic | all | GDD §2 (glass walls); spec 0.1 |

## Voice rules (Clara)

These restate Clara's five checks (`.claude/agents/content-critic.md`) so both critics share one guide; her definition stays the authority on how she checks them.

| ID | Rule | Source |
|---|---|---|
| T1 | **Lore:** nothing contradicts or invents beyond the GDD; TBDs are offered as options, never filled in. | GDD |
| T2 | **Tone & Glossary:** playful, whimsical and cozy; the Glossary's main term (an "Also called" term is acceptable). | GDD Aesthetic & Tone, Glossary |
| T3 | **Child safety & spending:** no fear, guilt or pressure to spend; a purchase or donation never measures the player's worth. | GDD Child Safety, Monetization Architecture |
| T4 | **Facts & French:** every real-world statement is true and sourced from a Ruth brief, or clearly in-world; French matches the English. | GDD Bee Journal; research/CONTEXT.md |
| T5 | **Sources:** every GDD section cited exists under that name. | GDD |
| T6 | **Look and words agree:** text that describes an object (the glass bucket, the hive's frames, the truck) matches how the game shows it. | this guide; GDD §2 |

## Out of scope
Audio (Andrew and Connie check licences; tone follows GDD Aesthetic & Tone); animation feel (tested by Quinn's snapshot tests, and judged by the designer playing).
