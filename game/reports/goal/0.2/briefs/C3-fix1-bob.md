Goal agent run `0.2`, fix round 1 for goal C3 of `game/specs/0.2-first-automation.md`, branch `milestone/0.2`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scenes/ and materials/

You alone work this round. If the cause is in Patricia (scripts/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). A `pick match` row means the live prop must match the designer's picked variant: open both shots and the variant's .tscn, and rebuild what differs. A style row whose Fix ends `(designer)` is not yours: leave it and list it in your reply.

style:
Style board `game/reports/style/goal-0-2-c3-r0/blackboard.md`, Result:

Still FAIL after round 1 (max rounds 1 or the token cap). Open rows:

| # | Rule | Where | Finding | Fix |
|---|---|---|---|---|
| 1 | V4 | `scenes/props/honey_cell.tscn:5` | `ArrayMesh` `Mesh_cell` is not a primitive mesh | use BoxMesh, CylinderMesh, SphereMesh, PlaneMesh, PrismMesh or CapsuleMesh |
| 1 | V13 | 06-truck-away.png | The truck drives off to the bottom right and its rear and wheels sit under the shop panel (y≈940–1080, over the panel top edge). | Stop the truck's away path above the panel's top edge (y<1080), or keep it fully out of frame before it reaches the panel. |
| 2 | V10 | 01-farm-start.png | The disabled Harvest button has grey-cream text on olive green (about 2:1). The "Dev" label is also faint on green. | Give disabled buttons ink text on a lighter fill, or cream text on a dark fill, at ≥4.5:1. Give "Dev" cream text with the ink outline. |
| 3 | V7 | 03-zoom-uncapping.png | The hive's right wall is cut off by the right edge and the crate is cut off at the bottom edge. The centrifuge also sits left under the "Dev" button, so the frame is not the clear focal object. | Re-centre the zoom camera so the whole hive and the frame fit with a margin. Move the crate and jars out of the zoom frame or shrink them. |
| 4 | V15 | 01-farm-start.png | The 9 jars on the crate are almost invisible pale ghosts, with no honey visible through them and no rim or edge. | Raise the jar glass's contrast with a slightly darker tint (still alpha ≤0.35) and put visible honey fill inside the jars. |

Transcripts: `_meta/sessions/runs/2026-11-09-style-goal-0-2-c3-r0/`

| Call | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|
| Vera, round 1 | 51,052 | 25,238 | 9 | 23 s |
| **Total** | **51,052** | | | |

Spec text:
3. **Heated Uncapping Fork** (Tree B): base $40, 1.22× growth, max level 5.
   - Fork reach: the player takes the fork from its icon and drags it through the combs; each drag point uncaps every capped cell within `uncap_radius × (1 + heated_fork_radius_bonus_per_level × level)` of the hit cell (level 0 = the hit cell only, today's behaviour). Reach is the Heated Fork's only manual effect in 0.2 (designer, 2026-11-09: "heated fork increases the fork reach"; one continuous sweep is the Long Fork's job).
   - The GDD's "+5% batch bonus for clean cuts" is left out of 0.2: its rule is undefined (listed in the README's Outstanding checklist; nothing to build for it now).
   - After automation (`heated_fork_post_auto_yield_bonus_per_level` 0.04) applies only once the auto-scraper is owned, so it has no effect in 0.2; the key and its use are coded and tested with the Dev toggle "own auto-scraper".  
   - The look (designer, 2026-11-09): the game has no 3D fork yet (`ForkIcon` is a button), so 0.2 adds the uncapping fork as a prop: it appears at the drag point over the combs while the player drags, and leaves when the drag ends. Model: `scenes/variants/fork-r4/fork-r4-c.tscn` (comb fork after the Harvest icon: five round tines, rounded crossbar, ferrule, wooden capsule handle).
   - Heated (Heated Fork ≥ 1): the whole metal head (tines, crossbar, ferrule) eases steel → crank orange → steel once per `fork_pulse_seconds`, as an albedo colour tween with **no emission** (STYLE_GUIDE V2); `fork-r4-c-hot.tscn` is the peak colour. The handle stays wood. At Heated 0 the head stays steel.

Reply in at most 150 words.