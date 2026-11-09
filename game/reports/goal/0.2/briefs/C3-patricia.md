Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C3. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Config keys of this goal (Process 3: in `scripts/game_config.gd` and `default_config.tres`, marked PLACEHOLDER, live in the Dev panel): heated_fork_radius_bonus_per_level, fork_pulse_seconds, heated_fork_max_level, heated_fork_post_auto_yield_bonus_per_level, uncap_radius.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 3 look: the fork prop follows the drag point over the combs and hides when the drag ends; with Heated Fork ≥ 1 the head's albedo tweens steel → crank orange → steel per `fork_pulse_seconds` (live in Dev), emission off. Item 4 look: Gear1..Gear(N + 1) show at Gearing N and turn with the crank, neighbours in opposite directions. Item 5 look: the truck's groups show per the item 5 table.
- The config keys above, in the Dev panel.

Spec text:
3. **Heated Uncapping Fork** (Tree B): base $40, 1.22× growth, max level 5.
   - Fork reach: the player takes the fork from its icon and drags it through the combs; each drag point uncaps every capped cell within `uncap_radius × (1 + heated_fork_radius_bonus_per_level × level)` of the hit cell (level 0 = the hit cell only, today's behaviour). Reach is the Heated Fork's only manual effect in 0.2 (designer, 2026-11-09: "heated fork increases the fork reach"; one continuous sweep is the Long Fork's job).
   - The GDD's "+5% batch bonus for clean cuts" is left out of 0.2: its rule is undefined (listed in the README's Outstanding checklist; nothing to build for it now).
   - After automation (`heated_fork_post_auto_yield_bonus_per_level` 0.04) applies only once the auto-scraper is owned, so it has no effect in 0.2; the key and its use are coded and tested with the Dev toggle "own auto-scraper".  
   - The look (designer, 2026-11-09): the game has no 3D fork yet (`ForkIcon` is a button), so 0.2 adds the uncapping fork as a prop: it appears at the drag point over the combs while the player drags, and leaves when the drag ends. Model: `scenes/variants/fork-r4/fork-r4-c.tscn` (comb fork after the Harvest icon: five round tines, rounded crossbar, ferrule, wooden capsule handle).
   - Heated (Heated Fork ≥ 1): the whole metal head (tines, crossbar, ferrule) eases steel → crank orange → steel once per `fork_pulse_seconds`, as an albedo colour tween with **no emission** (STYLE_GUIDE V2); `fork-r4-c-hot.tscn` is the peak colour. The handle stays wood. At Heated 0 the head stays steel.

Reply in at most 150 words: files changed, node names used, open questions.