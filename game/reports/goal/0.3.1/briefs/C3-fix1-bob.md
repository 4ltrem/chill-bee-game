Goal agent run `0.3.1`, fix round 1 for goal C3 of `game/specs/0.3.1-playtest-fixes.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scenes/ and materials/

You alone work this round. If the cause is in Patricia (scripts/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. STYLE_GUIDE minimums are approved values, not votes: raise a touch target below 120 px to 120 and a font below 28 px to 28 without asking, and say so in your reply. Where a panel sits, how it opens and what fits on screen come from the designer's Claude Design canvas: read `UI_DESIGN.md` and the matching board in `proposals/design/ui-screens-mockup/project/` for the look and placement of what the spec item asks for. Build only what the spec asks (a board part it does not name, like tabs, waits for a later revision); where the spec text differs, the spec wins. Before writing any `(designer)` row, look for the answer in `UI_DESIGN.md`, the canvas boards, `README.md` (Outstanding TBDs), `proposals/design/ui-screens.md` and `_meta/sessions/*/decisions.md`: if one answers it, apply that answer and cite the file. If the topic is already a listed TBD, build the placeholder, name the TBD and go on; it is not a question. Ask only when none of them covers it. This spec's visuals are placeholders (front matter `visuals: placeholder`): you may set a size, offset, font size or margin when a failing row needs it. Keep it close to the canvas board, change only the numbers the row needs, and list each as `placeholder: <file>: <old> -> <new>`; the designer confirms them at play-test. A `pick match` row means the live prop must match the designer's picked variant: open both shots and the variant's .tscn, and rebuild what differs. A style row whose Fix ends `(designer)` is not yours: leave it and list it in your reply.

style:
Style board `game/reports/style/0.3.1-goal-c3/run-1/blackboard.md`, Result:

Still FAIL after round 1 (max rounds 1 or the token cap). Open rows:

| # | Rule | Where | Finding | Fix |
|---|---|---|---|---|
| 1 | V12 | `scenes/main.tscn:515` | Button `TabBees` font size 28 px < 32 | set `theme_override_font_sizes/font_size = 32` or more |
| 2 | V12 | `scenes/main.tscn:535` | Button `TabHive` font size 28 px < 32 | set `theme_override_font_sizes/font_size = 32` or more |
| 3 | V12 | `scenes/main.tscn:554` | Button `TabHabitat` font size 28 px < 32 | set `theme_override_font_sizes/font_size = 32` or more |
| 4 | V12 | `scenes/main.tscn:573` | Button `TabResearch` font size 28 px < 32 | set `theme_override_font_sizes/font_size = 32` or more |
| 5 | V12 | `scenes/main.tscn:592` | Button `TabRefinery` font size 28 px < 32 | set `theme_override_font_sizes/font_size = 32` or more |

The game was not changed, and the sandbox has no changes to propose.

Transcripts: `_meta/sessions/runs/2026-11-23-style-0.3.1-goal-c3-run-1/`

|---|---|---|---|---|

(5 older row(s) about files this step did not change were left out: not yours this round, change nothing for them.)

Spec text:
3. **The Shop sheet as drawn on the canvas, with tabs.** Supersedes 0.3 item 3's sentence from "With 120 px buttons (V11) the eight rows" through "stay on screen at 720 × 1280." With `shop_layout = 1` (the sheet), the open Shop follows `Shop.dc.html`: the farm dimmed behind (`ShopDim`); a sheet from 168 px below the top of the screen to the bottom, with rounded top corners; a header (`ShopHeader`) with the title "Shop" (`ShopTitle`), the money (`ShopMoney`) and a round Close button (`ShopCloseButton`); a row of five tabs (`ShopTabs`: `TabBees`, `TabHive`, `TabHabitat`, `TabResearch`, `TabRefinery`; keys `shop_tab_bees` "Bees" / "Abeilles", `shop_tab_hive` "Hive" / "Ruche", `shop_tab_habitat` "Habitat" / "Habitat", `shop_tab_research` "Research" / "Recherche", `shop_tab_refinery` "Refinery" / "Raffinerie"), one selected; then the selected tab's rows, each with its name, its effect line with the level, and its Buy button (greyed when you can't afford it, a lock when locked). Rows by GDD §3 tree:
   - **Bees** (Tree A): Swarm, Flight Endurance.
   - **Hive** (Tree B, Hive & Tool Efficiency): Heated Fork, Centrifuge Gearing, Spigot Flow, Faster Delivery, Auto-Sell.
   - **Habitat** (Tree C): Plant wildflower patch.
   - **Research** and **Refinery**: no rows yet; selecting either shows one greyed line `shop_coming_soon` ("Coming soon" / "À venir", `content/ui-labels.md`, designer 2026-11-23).
   The Shop opens on Bees the first time and on the last selected tab after that (until the farm resets). The money in the header follows purchases. Close and a tap on the dimmed farm (the strip above the sheet included) return to the farm view. The Shop opens from the farm view only: this supersedes 0.2 item 15 ("Shop stays available in both zooms") and the 2026-11-21 answer to `ui-screens.md` decision 4 (designer, 2026-11-23: "Tools only, no Shop … respect the canvas design"). The `ShopButton` hides in the first zoom and at the second stop, where item 8's Tools icon holds the machine's upgrades. Rows don't overlap each other; every row of the selected tab, the header and the tabs stay on screen at 720 × 1280 (the Hive tab's five rows the most). Tabs are 120 px tall (V11), fonts 28 px (V12). With `shop_layout = 0` (compact panel) nothing changes: one list of the eight rows, no tabs. Sizes are placeholders the designer confirms at play-test.

Reply in at most 150 words.