# Technical Feasibility Lead — Round 1

Era context: this is a current document (Godot 4 APIs such as `PhysicsDirectSpaceState3D`, an LLM-agent pipeline built around Claude Code), so I judge it against today's constraints.

## Finding 1: No team size, timeline, milestones, or cut list for a scope this large
**Severity: BLOCKING**

**Passage / omission:** The document never says who is building this, over what timeline, or what the MVP is. Meanwhile the scope includes: three phases plus a prestige system with "deep genetic research trees"; three progression trees; a two-stage 3D tactile minigame; four biomes, each with its own hive art, flora and honey type; speed-run leaderboards; three monetization tiers (ads, a monthly subscription, the Patron Pass) plus a premium currency (Royal Jelly); a live conservation dashboard; and six platforms. The only implied "team" is the AI agent roster (Gerard, Bob, Patricia, and the rest), which suggests one developer leaning on LLM agents.

**Why it matters:** Nothing is marked as stretch or deferrable, so there is no way to judge whether this is a 6-month or a 3-year project. The likely cuts are obvious: Switch and desktop, biomes 3 and 4, the genetic research trees, and leaderboards. But the document treats all of them as committed. It needs a vertical-slice definition (Phase 1 to Phase 2 in Sunny Meadow, on mobile only) and an explicit cut order.

## Finding 2: The platform list conflicts with the chosen engine and language
**Severity: MAJOR**

**Passage:** "Target Platforms: Mobile devices (iOS & Android first), Tablets, Nintendo Switch, and Desktop (PC/Mac)" together with "combined with C# for performance-critical grid operations and save-state serialization."

**Why it matters:** Godot has no first-party console export. Switch needs a licensed third-party port (for example W4 Games or a porting house), plus Nintendo developer approval and devkits. Godot 4's C#/.NET support on mobile is still marked experimental, and console support for it is weaker still. Picking C# for core systems (saves, grid) puts the riskiest technology on the most platform-sensitive code paths. Either commit to GDScript-only (or GDExtension) for portability, or drop Switch from the plan. The document also never addresses a touch-first minigame (swipe, crank spinning, haptics) on mouse-driven desktop, or haptics on Mac.

## Finding 3: Live-service backend is required but never specified
**Severity: MAJOR**

**Passage:** "In-Game Impact Dashboard: Tracks live community restoration stats"; "competing for high scores based on completion speed"; "golden 'Patron' badge on speed-run leaderboards"; "Impact Pass (Monthly Pass)"; "daily stipend of Royal Jelly premium currency"; "extends offline idle earnings up to 24 hours".

**Why it matters:** Each of these needs server infrastructure the document never mentions. It needs:
- an aggregation backend for live stats
- leaderboards with anti-cheat (a speed-run board in an idle game that tracks offline time is trivially exploited by changing the device clock unless time is validated on the server)
- receipt validation for subscriptions on both the App Store and Google Play
- a server-authoritative daily currency grant
- cloud saves, if Patron purchases must carry across the six listed platforms

A further risk: routing a pledged percentage of proceeds to charities is a cause-marketing arrangement. It needs accounting, payout records and app-store policy review, which is engineering and operations work as well as design. The only data architecture in the document is the local honeycomb bitmask; the backend layer is missing entirely. It is also duplicated content: the "Real-World Impact Integration" section is repeated word for word under "Real-World Impact & Monetization", which suggests this area has not been worked through.

## Finding 4: The 60 FPS with "hundreds of bees" target has no rendering strategy
**Severity: MAJOR**

**Passage:** "Must maintain a stable 60 FPS performance target with hundreds of low-poly bees and floating diorama elements rendered simultaneously on screen" and "optimal performance across low-end mobile hardware", together with "translucent wings with shimmer" and "glowing" clover, mushrooms and honey.

**Why it matters:** Low vertex counts alone do not get you there. Hundreds of independently moving, individually animated bees as separate nodes will be limited by draw calls and per-node script processing on low-end Android. Translucent shimmer wings mean alpha-blended overdraw, and "glowing" usually means bloom or emissive post-processing, which is expensive on Godot's Mobile/Compatibility renderers. The document needs to commit to an approach: MultiMeshInstance3D with shader-driven (vertex) animation, flight paths simulated as data rather than one node per bee, a minimum device spec, and a fallback (lower bee count or impostors when zoomed out). Without that, either the art direction or the bee count will be cut late.

## Finding 5: The AI-agent production pipeline is underspecified and overstates what the agents can do
**Severity: MAJOR**

**Passage:** "Token budget allocation per agent task: Usage Limit ÷ 7"; "Bob, the Builder... builds levels in the editor... and the player sees the finished level"; "Andrew, the Audiophile... searches and curates audio... accompanying folder with the selected audio files"; "Patricia... creates modular components and code for the game engine."

**Why it matters:** If the agents are the team (see Finding 1), this is the production plan, and it does not hold up:
- **Bob:** An LLM cannot drive the Godot editor GUI. "Builds levels" would actually mean generating `.tscn` text scenes, which is fragile for 3D layout. And this game has "no levels" in the usual sense: it is a single expanding diorama with four biomes.
- **Andrew:** Sourcing audio files raises licensing and provenance questions with no process to check them.
- **Token budget:** "Usage Limit ÷ 7" has no defined usage limit and no per-task sizing. A fixed split also gives Martin, the Hiring Manager, the same budget as Patricia, the Programmer.
- **Integration:** No human review, testing, or integration step is defined.
- **Wording:** The section keeps saying "the player sees". It means the developer, which shows the roles were drafted from a template without being adapted.

The biggest feasibility gap is that no agent or person owns QA, platform builds, backend, or performance profiling, which are exactly the risks in Findings 2 to 4.

## Round 2 — Cross-examination

### Conflicts

**C1. Fixing the leaderboard by segmenting it, versus cutting it (vs. Systems Designer #2, Adversarial QA #1–2, Business Analyst #1).**
Four of us flag the Patron +25% as pay-to-win on the speed-run board. The fixes on offer add work, though. Systems Designer suggests "split or normalize" the boards. QA suggests brackets by prestige level, plus ad caps and boost exclusions. Each of those is extra backend and anti-cheat work stacked on a feature that is already the hardest to build (my Finding 3).

The basic problem comes before fairness: this is an idle game with offline progress, so "completion speed" is mostly wall-clock time on the device. You cannot verify it without server-authoritative time, and probably server-side replay of the economy. A board you cannot verify is unfair to everyone, Patron or not.

My position: **cut speed-run leaderboards from launch**. Replace them with personal-best run times stored locally, which cost almost nothing to build. That also settles the cozy-vs-competitive split that Business Analyst #1, Narrative #3 and Psychologist #2 raise. The cheapest fix and the best design fix are the same thing here. If the board is kept, its normalization rules have to be written before backend work starts, not added later.

**C2. The minigame is not the feature to cut (vs. Business Analyst #5).**
Business Analyst calls the Phase 1 minigame the "costliest content" and suggests cutting its scope. On the technical side I disagree. It is the one bounded, well-specified feature in the document:
- a single frame mesh
- a cell-state array
- one raycast query
- particles
- a haptics call

A small team can build it in weeks, and it is the obvious core of the vertical slice from my Finding 1. The expensive content is the four biome art sets (each with its own hive, flora and honey), the live backend, and the platform ports. My agreement with BA is on *reuse*: their proposal to keep the minigame useful later (artisanal batches) is cheap, because the code already exists. Cutting the minigame saves little. Cutting biomes 3–4 and the extra platforms saves a lot.

**C3. Narrative and psychology fixes that add systems (vs. Narrative #1, #3, #5; Psychologist #2).**
Several of the proposed fixes are good but add scope to a project with no scope limit:
- Narrative #1 wants native-pollinator and habitat health in the loop.
- Narrative #5 wants pests as a base-game threat.
- Narrative #3 and Psychologist #2 want the old hive to stay visible after a reset.

I accept them only if they **replace** something rather than add to the pile:
- **Habitat health:** Flora Synergy is an empty slot with no numbers (Systems Designer #4). It should become the habitat or native-bee tree, at zero net cost to scope.
- **Pests:** they must exist in the base game anyway, because the Golden Drone already "handles" them (QA #4, Psychologist #5). Specifying them is required, not optional.
- **Post-reset memory:** this has to be a cosmetic snapshot (one baked static mesh or a trophy object), not a live, simulated second diorama. A live one doubles the save state and the render load against the 60 FPS target.

### Connections

**X1. The document's gaps make its own AI pipeline unable to work (Systems Designer #1, #5 + Narrative #4 + my Finding 5).**
Prompt Constraint 3 says "No Hallucinated Systems... ground themselves within the existing 3-phase progression model." Systems Designer shows that the model is largely missing:
- the automation unlocks have no tree or cost
- Queen Markers have no formula
- Flora Synergy has no numbers
- there is no income side at all

So the agents either refuse to work or invent systems, in direct violation of the constraint. Each agent hits this:
- **Patricia** cannot implement the Phase 1→2 gate.
- **Terry** is told to read "the progression file," which does not exist. Without base income (Systems Designer #5) there is nothing to balance against.
- **William** has no story canon (Narrative #4).

This upgrades my Finding 5. The agent pipeline is not just underspecified. **With the GDD in its current state it cannot run as designed.** Filling the design gaps is a prerequisite for the pipeline, and the order in which that happens should appear in the production plan.

**X2. The per-batch "seed contribution" modal is a backend feature in disguise (Narrative #2, Adversarial QA #5, Business Analyst #3 + my Finding 3).**
Three colleagues treat the modal as a trust or compliance problem. Technically there are only two options:
1. If per-harvest contributions are real, every free player's harvests have to be counted on the server, protected against tampering (offline and clock-shifted harvests), and reconciled with partner payouts. That is a ledger system.
2. If they are not real, the modal is a false claim.

The cheap and honest option is to show a **community-level** figure in the modal, fetched from the same aggregate endpoint the Impact Dashboard needs, and to stop implying any per-batch attribution. That also cuts one feature from the backend list.

**X3. Offline earnings plus a hive cap means the paid perks may do nothing (Adversarial QA #4, Systems Designer #3 + my Finding 3).**
Production fills the hive and then waits for a manual harvest. So in Phase 1, the "extended offline production" (Impact Pass) and the "24h offline earnings" (Patron) are worth zero, unless offline time quietly auto-harvests.

That makes the subscription's value depend on a rule nobody has written. It also determines the offline-progress code: whether it is a simple capped accumulation or a closed-form simulation of automated harvest cycles. The offline calculation is also where device-clock exploits live (my Finding 3). The hive-full rule needs to be settled **before** any offline or subscription code is written.

**X4. Business Analyst #4 and my Finding 2 together make Switch and desktop impossible to defend.**
I argued that Switch is a porting and licensing cost. BA shows those platforms also have no revenue path, since rewarded ads and the subscription model do not carry over. Taken together: high cost, no revenue model, and no input scheme (QA #5). Switch and desktop should move from "target" to "post-launch investigation".

### Revisions

- **Finding 1 (scope/cut list): kept BLOCKING, cut order revised.** I had listed "the genetic research trees" as an easy cut. Systems Designer #1 and #5 show that prestige *is* the stated main loop, and the regular trees max out at about $3,840 total. That means the base content is short, and the meta layer is what gives the game length. Cutting it removes the endgame altogether. Revised order:
  1. speed-run leaderboards
  2. Switch and desktop
  3. biomes 3–4
  4. live dashboard (replaced by periodically updated static figures)
  5. Patron Pass (ship the Impact Pass only)

  A minimal prestige layer (one reset formula, a small meta tree) moves *into* the vertical slice.
- **Finding 2 (engine/language): downgraded in part.** On re-reading, C# is "for performance-critical grid operations and save-state serialization **if required**". It is conditional, not committed, so I overstated it. The only "grid" in the document is a single minigame frame, and GDScript handles that easily. Recommendation: GDScript-only, and drop the C# clause. The platform half stays MAJOR (see X4). A small correctness note: the cell model has three states (0, 1, 2), so it is not a 1-bit "bitmask"; it needs 2 bits per cell or a byte array.
- **Finding 3 (backend): upgraded to BLOCKING for launch.** With X2 and BA #3 included, the backend carries the game's differentiating pillar: dashboard data, donation accounting, subscription receipts and the stipend. It also carries a compliance surface: cause-marketing rules, and Apple's guideline on charitable contributions inside apps. That surface has to be resolved before store submission, not after.
- **Finding 4 (60 FPS / bees): downgraded to MINOR.** Systems Designer #5 shows that the simulated economy is small: Worker Swarm caps at 10 levels and is expressed as a fill-rate percentage. So "hundreds of bees" is a presentation choice, separate from the simulation. MultiMesh rendering plus a cap on visible bees is a standard, low-uncertainty fix. The remaining real risk is the art direction (alpha-blended shimmer wings and bloom on the Mobile renderer). It should be prototyped early but does not block anything.
- **Finding 5 (AI pipeline): kept MAJOR, reframed via X1.** I agree with Business Analyst #2 that it belongs in a separate production document. Moving it there does not remove the risk, though: it is still the stand-in for the team, and with no owner for QA, builds, backend or profiling it remains the largest production gap.
