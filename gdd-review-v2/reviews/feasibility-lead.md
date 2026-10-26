# Technical Feasibility Lead — Round 1

Era note: this document targets current-generation mobile (iOS/Android) with Godot 4.x and an AI-agent workflow in Claude Code. I judge it against those constraints.

## Finding 1 — Launch scope is far larger than one developer can ship in 6 months, and the economy it all rests on is mostly unspecified
**Severity: BLOCKING**

**Passage:** "Team: Solo developer directing AI agents" / "Timeline: Launch within 6 months" / "Launch Scope: Mobile only; Sunny Meadow and Alpine Valley; rewarded ads and the Impact Pass; local personal-best run times; periodically updated impact totals." / "Backend: A managed game-backend service (provider TBD) for purchase receipts, cloud saves, and server time."

**Problem:** The launch build includes two biomes with their own honey and native species, three progression trees plus automation, a prestige loop, research trees, a two-stage 3D tactile minigame, a premium currency, a monthly pass with receipt validation, rewarded ads, cloud saves, server time, an age gate and Kid Mode, English and French localization, four accessibility features, and real-money donation tracking. That is a mid-sized studio's free-to-play scope. Six months for one person is already tight before you count store review cycles, ad-network approval, and setting up charity partnerships.

The bigger issue is that the numbers every system depends on are TBD. That includes the Royal Crystal boost %, offline cap hours, automation costs (which are also the Phase 2 trigger), every Tree C value, the capstone unlock thresholds, biome milestones, biome honey values, native species and their effects, and how the research tree works ("unlock conditions, and how research differs from Trees A–C, TBD"). Only Tree A and Tree B have cost curves, and Flight Endurance has no max level. A balanced run length can't be reached until those numbers exist, and leaderboards, offline caps, pass value, and Royal Jelly pricing are all tuned against run length. The document has no milestone schedule between vertical slice and launch, and it says nothing about what gets cut if the date slips. The obvious candidates are Alpine Valley, research trees, French localization, and the Impact Pass, but none of them are flagged as cuttable.

## Finding 2 — Compliance and real-money obligations are a large, unscoped workload for a solo developer
**Severity: MAJOR**

**Passages:** "Target Audience: Families and players of all ages." / "Kid Mode (under 13): No personalized ads, a parental gate before any purchase, and no public usernames." / "a portion of proceeds ... funds real-world bee conservation" / "Each revenue stream donates one fixed, auditable percentage" / "Canadian Non-Profit Partnerships: Initial donation routing targets organizations such as..."

**Problem:** Targeting families with a self-declared age gate means the game falls under COPPA (US), Apple's Kids/mixed-audience rules, and Google Play's Families Policy. Rewarded ads in Kid Mode need a child-directed ad configuration with certified ad SDKs. The document lists only "no personalized ads", which does not cover the SDK and network restrictions. There is also no plan for data handling (cloud saves, server time, receipts) for under-13 users.

On the donation side, "auditable" per-stream percentages mean the developer must attribute revenue by stream: ad revenue arrives as aggregated network payouts, and pass revenue arrives after store fees and refunds. They also need signed partner agreements and must follow cause-marketing and charitable-solicitation rules in Canada and the US. The partners are named only as "such as", so no agreement exists yet. None of this work has an owner. No agent covers legal, compliance, or finance, and Patricia "owns backend integration" only. This work can block store submission no matter how finished the game is.

## Finding 3 — The 60 FPS target with "hundreds" of bees on low-end mobile has no rendering plan, and the C# fallback is risky on mobile
**Severity: MAJOR**

**Passages:** "Must maintain a stable 60 FPS performance target with hundreds of low-poly bees and floating diorama elements rendered simultaneously on screen." / "low-end mobile hardware" / "translucent wings with shimmer" / "C# for performance-critical grid operations and save-state serialization if required."

**Problem:** Hundreds of bees each pathing between flowers and the hive, with translucent shimmering wings (alpha blending causes overdraw, which is costly on mobile GPUs), on a zoomable farm that keeps growing, will not hold 60 FPS on low-end Android with naive per-node scenes. The document doesn't mention instancing (MultiMeshInstance3D), LOD, culling when zoomed out, a cap on simulated bees versus visual bees, or which Godot renderer it uses (Mobile vs Compatibility). It also defines no low-end target device.

The C# hedge is backwards. Godot 4's .NET export for Android and iOS is still marked experimental, which adds export and build risk. Meanwhile the "performance-critical grid" is a single frame of cells stored at 2 bits each, which GDScript handles easily. The real performance risk is bee simulation and rendering, and the document has no plan for it. Quinn profiles "against the 60 FPS target" but has no device matrix to profile on.

## Finding 4 — The AI agent roster has no producer of 3D art, animation, VFX, UI, or localization
**Severity: MAJOR**

**Passages:** Agent Roles (Gerard, Bob, Patricia, William, Andrew, Terry, Martin, Quinn) / "Bob ... assembles biome dioramas and terrain chunks as Godot scene files (.tscn)" / "Andrew ... searches and curates audio" / "Languages: English and French at launch."

**Problem:** Bob assembles scenes, but nothing in the pipeline creates the assets he assembles. There are no low-poly models for bees, hives, flowers, the four distinct hive styles, the centrifuge, or the honeycomb frame. There are no rigs or animations, no shaders (wing shimmer, glowing honey), no particles, no UI art, and no texture atlases. A text-based coding agent can't produce shipping-quality 3D models, so these must come from asset packs, outsourcing, or the solo developer. That cost and schedule time appear nowhere.

French localization at launch also has no owner, and neither does the French text for the Bee Journal's real-world facts. Andrew "searches and curates" audio, but the document doesn't address licensing for commercial use. Martin exists to fill skill gaps, but the gaps above are known now and should be budgeted now. The token budget ("Weekly Usage Limit ÷ 7") is split evenly across days with no prioritization. That works against crunch periods such as store submission.

## Finding 5 — Feature dependencies will force save-data and balance rework when post-launch features arrive
**Severity: MAJOR**

**Passages:** "Royal Jelly: Using purchased Royal Jelly during a run counts as a paid booster; Royal Jelly earned through play does not." / currency table listing a single Royal Jelly currency / "Biomes are stages within a single run, played in order" / "Post-Launch: Biomes 3–4 ..., the Patron Pass, online leaderboards" / "Run Time: Wall-clock time ... offline time included."

**Problem:**
- Royal Jelly is defined as one fungible currency. Leaderboard bracketing needs to know whether jelly spent in a run was purchased or earned, which requires separate ledgers that are tracked on the server. The launch save schema and backend must be built that way from day one, or the post-launch online leaderboards can't classify old runs. The document doesn't call this out.
- The capstone is "the very last upgrade in the progression tree", and biomes are sequential stages within a run. Adding Biomes 3–4 after launch therefore either moves the capstone, which makes every run longer, breaks all launch personal bests, and changes the Royal Crystal economy, or it leaves the new biomes after the run's end. The document doesn't choose.
- Run time includes offline time, and offline caps differ by pass. The bracketing by booster partly absorbs this, but it ties leaderboard fairness to offline-cap numbers that are still TBD.
- The Patron Golden Drone and the Patron leaderboard badge are written into launch systems (pests and drops, leaderboards), but the Patron Pass is post-launch.

These features depend on each other more than the phased plan admits. Each post-launch addition reaches back into launch data structures.

## Round 2 — Cross-examination

Before writing this I re-checked the GDD on the points I rely on below: §2 limits the capacity pause to "Phase 1"; §4 requires "Server-Side Time Validation"; the §5 currency table makes Royal Jelly "purchasable with real money"; the Store sells "Royal Jelly and passes"; the Target Platforms line says "including tablets".

### Systems Designer

**CONNECTION (this changes my Finding 1).** In Round 1 I said "Only Tree A and Tree B have cost curves," which implied that part of the economy was settled. Systems Designer Finding 1 shows it isn't. I checked their arithmetic (for example, Worker Swarm totals 25 × (1.18^10 − 1)/0.18 ≈ $588), and the whole capped tree comes to about $3,840 with linear effects. So the numbers the GDD does give are numbers that will have to be thrown away. For scheduling, the real state is "no economy exists yet," not "the economy is partly specified." That matters for the timeline in a specific way. Economy design is serial work that sits on the critical path. Leaderboard brackets, offline caps, pass value, Jelly pricing, and the capstone gate can't be tuned until it's done, and AI agents can't run it in parallel, because each tuning pass needs playtest time on real devices. The six-month plan has no slot for it.

**CONFLICT (cost of the fix).** Systems Designer proposes multiplicative effects "or tiers reopen per biome," and Finding 5 asks whether trees are per-biome or per-run. I agree with the diagnosis, but per-biome trees would double the content to tune and the UI states to build for the launch biomes, and quadruple them once Biomes 3–4 ship. The feasible version is to keep one shared tree, express its effects as multipliers, and have each biome raise level caps on the same nodes through data rows. That needs no new upgrade art, no new strings to translate, and no new screens. I'd ask the board to recommend that specific shape rather than leaving "per-biome or per-run" open.

**CONNECTION.** Systems Designer Finding 3 points out that the capacity pause is stated only for Phase 1, and automation's behaviour at capacity is undefined. Adversarial QA Finding 3 says the same. For me this also leaves the offline-earnings code path undefined. That path runs on server time (§4 "Server-Side Time Validation") and feeds the pass perks the business model sells, so the backend contract can't be written until this rule exists.

### Player Psychologist

**CONFLICT (scope creep from recommendations).** Finding 3 adds five new guided beats plus a persistent capstone checklist. Finding 5 adds a reset-preview screen that shows an estimated speed-up, plus a gallery or keepsake of past farms. Every one of these has merit. Together they amount to a second onboarding system, and the "estimated speed-up" can't be built until the economy exists (see above). My counter-proposal is to ship three things: the capstone checklist (one panel, and it also covers the hidden-wall problem), a single warning before a habitat-harming purchase, and a static reset-preview that lists what is kept and what is lost, with no estimate. Defer the gallery. Also, the "warning before buying a hive" assumes a hive purchase exists. Systems Designer Finding 2 and QA Finding 5 both note that it doesn't.

**CONNECTION.** Finding 2 (Phase 2 has no signature activity, and the stretch from first automation to the capstone is most of a run) combines with the production plan to create a schedule risk nobody has stated. The vertical slice runs "from the Phase 1 manual minigame through the first automation upgrades." It stops exactly where the weakest part of the game begins. The slice will therefore validate the best-specified, most fun stretch and leave the riskiest one (retention through Phase 2, Tree C, the second biome) untested until after the slice, inside a timeline that has no milestones for that stretch. I recommend extending the slice's exit criterion: one complete, ugly run from start to capstone to reset, with placeholder art, before any monetization, backend, or localization work.

**AGREEMENT WITH A COST NOTE.** Finding 1 recommends a small free overflow from the start. That simplifies the build. It removes the "paused offline" state for new players and makes the offline cap the single rule. I support it partly because it reduces the number of cases to test.

### Adversarial QA

**CONNECTION (backend scope).** QA Finding 1 (track Jelly by source, decide what happens to stipend Jelly after cancellation) and Finding 3 (how a booster that lapses mid-run is tagged) together mean the backend needs more than a Jelly balance. It needs a per-run event ledger: which boosters were active at what times, and how many units of each Jelly source were spent. My Round 1 Finding 5 called this "separate ledgers" but understated it. A ledger is a different backend shape from "receipts, cloud saves, and server time," and it has to exist from the first launch save, even though online leaderboards come later, or launch-era runs can never be classified. This is cheap if it is decided now and costly to retrofit.

**CONNECTION (doubling test work).** QA Finding 4 (No-Rapid-Tap may beat the default input) is also a test-matrix problem. Two input paths × Gearing levels × Fork precision bonuses × phone/tablet must all produce equal value. The cheapest robust fix is architectural, not tuning. Have the minigame produce a value from a single "effort completed" signal, and treat the input mode only as a way of producing that signal. Gearing and precision would then be defined against that signal. Otherwise every balance pass has to be checked twice.

**MILD CONFLICT.** QA Finding 3 recommends versioning "leaderboards and personal bests by content set." I agree, but only local PBs ship at launch, so the launch cost should be one integer (a content-version field on every stored run), not a bracket system. I'd keep the board from turning this into launch-scope leaderboard work.

### Business Analyst

**CONFLICT (where the overhead really is).** Finding 1 treats the agent pipeline, and Martin in particular, as overhead that shows effort going into process. I partly disagree. The pipeline text costs nothing to build. What it costs is that it hides the real gap. As my Finding 4 says, no agent produces 3D models, rigs, shaders, VFX, or UI art. The BA's scope list also leaves out art production. In my view art, not process, is the largest unbudgeted line in the launch scope. Cutting Martin saves almost nothing. Budgeting asset-pack purchases or outsourcing changes the plan.

**CONNECTION.** Finding 2 recommends picking one fantasy. From the build side, dropping the competitive layer doesn't remove the backend. Royal Jelly sells time skips (§5), and offline earnings are pass perks, so server time and receipt validation are needed anyway to stop clock-manipulation fraud. What the cozy option does remove is the bracket logic, the per-run booster ledger (QA's issue), and content-version bracketing. So the cozy choice saves real engineering time, but less than the board might assume.

**CONNECTION.** Finding 5 points out that Royal Jelly IAP may not be in the launch scope, while the Store and currency table say it is. If Jelly IAP is cut from launch, my Finding 5 ledger issue goes away for launch only if the save format still tags Jelly by source. That's one field, and I recommend it whichever way the decision goes.

### Narrative Critic

**CONFLICT (cost of the fix).** Finding 1 suggests restored worlds stay on "as a visitable collection." Technically that means keeping N complete farm states and making them renderable, which multiplies save size, raises cloud-save sync and migration risk, and adds a scene-loading path, all on low-end devices that already struggle with the 60 FPS target (my Finding 3). A Journal page per completed run (snapshot image plus stats) delivers the same fiction at about 5% of the cost. I'd push the board toward that version.

**CONNECTION.** Finding 5 (real facts versus fantasy species) adds work to my Finding 4. Every Journal fact needs fact-checking and French translation, and the pipeline has an owner for neither. A family/educational title that ships an inaccurate fact in French with nobody responsible for it is a reputational risk as well as a schedule one.

### Revisions to my Round 1

- **Finding 1 (scope), BLOCKING, reinforced.** Upgraded in substance: the specified economy numbers are themselves non-viable (Systems Designer Finding 1), so the economy-design critical path is longer than I stated.
- **Finding 2 (compliance), upgrade MAJOR → BLOCKING.** BA Finding 4 shows that the audience decision determines ad-SDK and backend vendor selection, both TBD and both early on the critical path. Rewarded ads "explicitly tied to native habitat funding," shown to children, also sharpen the cause-marketing exposure. This is no longer just a submission-time risk. It gates architecture choices in month one.
- **Finding 3 (performance), stays MAJOR, but I'm softening the C# point.** The rendering and instancing plan and the missing device matrix are the substance. The C# hedge is a secondary risk that can be removed simply by not using it. Tablets (in the Target Platforms line, and noted by BA) widen the device matrix and should be added to it.
- **Finding 4 (art/localization), stays MAJOR.** Reinforced by Narrative Critic Finding 5.
- **Finding 5 (dependencies), stays MAJOR and is narrowed.** Systems Designer Findings 4–5 and QA Findings 1 and 3 reached the same Jelly and biome issues on their own. My distinct contribution is the cost asymmetry. Source-tagged Jelly, a per-run booster log, and a content-version field cost almost nothing if they're in the first launch save schema. Retrofitting them after launch means classifying runs that were never logged. I'm withdrawing the Patron Golden Drone and badge bullet as low-impact: it's dead code that can stay unused, not a structural dependency.
