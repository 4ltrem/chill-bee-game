# Production/Business Analyst — Round 1

## Finding 1 — Launch scope is not achievable by a solo developer in 6 months, and there is no plan between the vertical slice and launch
**Severity: BLOCKING**

**Problem:** The vertical slice is reasonably small. The launch scope is not. Between "First Playable" and "Launch" the document adds all of the following with no milestones, sequencing or cut list:
- a second biome, with its own honey and native species
- all of Tree C
- the capstone, Royal Crystals and research trees
- Overflow Storage and Auto-Sell
- automation buildings
- two currencies plus a premium-currency store
- rewarded ads and a monthly subscription (Impact Pass)
- a managed backend for receipts, cloud saves and server time
- an age gate and Kid Mode with a parental gate
- English and French localization
- four accessibility modes
- tablet support
- a 60 FPS target with "hundreds" of bees on low-end hardware
- signed charity partnerships with auditable donation percentages

The launch date itself is "TBD", yet the timeline is fixed at 6 months. AI agents do not reduce the non-engineering work: app-store subscription review, ad-network integration, partner agreements, French QA, or device-matrix testing.

**Source:** Audience & Production Plan: "Team: Solo developer directing AI agents", "Launch within 6 months (date TBD)", "Launch Scope: ... Sunny Meadow and Alpine Valley; rewarded ads and the Impact Pass...", "Languages: English and French at launch". Also Technical Constraints: "including tablets", "60 FPS ... hundreds of low-poly bees".

**Omission:** The document has no milestone plan, no definition of launch-critical versus cuttable features, and no soft-launch or test-market phase.

**Related overhead:** Close to a third of the document describes the AI pipeline, including "Martin, the Hiring Manager", an agent whose only job is to write more agents. This is production tooling, not game scope. It signals that effort is going into process that a solo 6-month project cannot afford.

---

## Finding 2 — The document is trying to be three games: a cozy family idler, a competitive speed-runner, and an educational conservation title
**Severity: MAJOR**

**Problem:** The stated tone is "cozy, casual ... playful, whimsical" for "families and players of all ages". But Phase 3 is framed around "competing for high scores based on completion speed on bracketed leaderboards". This competitive layer comes with heavy machinery: booster-set brackets, Royal Crystal tiers, server-side time validation, and anti-cheat for device-clock manipulation.

Run time is "wall-clock time ... offline time included". Combined with "production pauses at capacity until the player harvests, including while offline", this rewards checking in compulsively. That is the opposite of the cozy, put-it-down positioning.

The pitch line "love child of *Egg, Inc.* and *Factorio*" also overstates the design. Nothing in the document has Factorio's defining traits: no spatial logistics layout, no production chains, no building placement. Automation is a purchasable upgrade line with "costs TBD". The comparison tells players and press to expect a factory game the design does not contain.

**Source:** Executive Summary, Phase 3, Leaderboards ("Run Time", "Server-Side Time Validation"), Section 2 (pause at capacity), Aesthetic & Tone.

**Recommendation:** Pick one primary fantasy. Either:
- cozy restoration idler, with personal bests as a light layer, or
- competitive prestige-racer.

Remove or rewrite the Factorio comp.

---

## Finding 3 — The detail is inverted: the differentiator is unspecified, while decorative and post-launch features are fully detailed
**Severity: MAJOR**

**Problem:** The game's stated reason to exist is the habitat and biodiversity layer, plus the real-world impact pillar. That is what separates it from every other idle farm. It is also the least specified part of the document:
- Tree C: "values TBD"
- native species and effects: "TBD"
- Habitat Health threshold for the capstone: "TBD"
- donation percentages for every revenue stream: "TBD"
- partners: listed only as "organizations such as...", with no agreement implied

Meanwhile, features that are post-launch or purely cosmetic get full specification:
- leaderboard bracket rules (online leaderboards are post-launch)
- player-name word lists
- the Patron Pass hive skin "engraved mahogany & brass ... with a custom nameplate displaying real-world restoration coordinates" (Patron Pass is post-launch)
- full art direction for Biomes 3–4 (post-launch)

Tree B, by contrast, has exact cost curves.

**Source:** Tree C ("values TBD"), Progression Tiers & Biomes, Conservation Partnerships ("Donation Commitments ... values TBD"), Leaderboards, Patron Pass "Visual Prestige", Post-Launch list.

**Impact:** The game cannot be positioned or marketed on its pillar until a partner is actually signed and the donation numbers exist. Without them, the "Real-World Impact Integration" pillar is a marketing claim with nothing behind it. The document itself says cause marketing must wait for those values.

---

## Finding 4 — The audience is undefined, and the kids/monetization/cause-marketing mix is under-scoped for compliance
**Severity: MAJOR**

**Problem:** "Families and players of all ages" does not identify an audience. It does not tell us:
- the primary buyer (the parent paying? an adult idle-game player?)
- the core player
- the comparable titles' actual demographics. Egg, Inc. skews toward adult idle players; Factorio toward PC enthusiasts.

Monetization is built on recurring subscriptions (Impact Pass, Patron Pass), a purchasable premium currency, and rewarded ads "explicitly tied to native habitat funding". Charity framing that nudges children toward ads and purchases is a sensitive combination.

Kid Mode covers only three things: no personalized ads, a parental gate, and no public usernames. The document does not address:
- app-store family or kids program requirements
- self-declared age-gate reliability
- children's privacy law for the chosen backend and ad SDK (COPPA, and Canadian/Quebec privacy rules given the Canadian partners and French launch)
- regulations on commercial co-ventures and charitable sales promotions that govern "a portion of proceeds" claims

**Source:** Target Audience; Child Safety; Monetization Architecture ("Non-Predatory Rewarded Ads ... explicitly tied to native habitat funding"); Executive Summary impact pillar.

**Impact:** If "families" really means kids are a core audience, the ad and subscription strategy may need to change materially. This has to be decided before backend and ad-provider selection (both currently TBD), not after.

---

## Finding 5 — Launch monetization and economy surface are internally inconsistent
**Severity: MINOR**

**Problem:**
- **Royal Jelly:** The Launch Scope lists only "rewarded ads and the Impact Pass". But the Store screen sells "Royal Jelly and passes", the currency table says Royal Jelly is "purchasable with real money", and the leaderboard rules treat purchased Royal Jelly as a booster. It is unclear whether Royal Jelly IAP ships at launch. That decision determines the launch revenue model.
- **Research trees:** "Deep genetic research trees" are a fourth progression system, bought with the same in-game money. Their unlock and purpose are "TBD", and they are missing from the UI & Screens list, whose Upgrade Shop covers only Trees A–C, automation and the capstone. This feature is either creep or unplanned work.
- **Title:** Four candidate names ("Chill Bee", "Digibees", "My Bee Hotel", "Pocket Hive") with different tones. "Digibees" implies digital or virtual pets. "My Bee Hotel" evokes the real-world native-bee "bee hotel". No name means no store-listing, search or trademark work can start inside a 6-month window.

**Source:** Launch Scope; UI & Screens (Store, Upgrade Shop); Currencies table; Phase 3 research-tree paragraph; title block.

## Round 2 — Cross-examination

### A. Systems Designer

**CONFLICT — SD-1 (economy runs out) and SD-5 both suggest fixes that add scope.** SD-1 asks for "a sink structure where effects multiply (or tiers reopen per biome)", and SD-5 for per-biome trees and run-time versioning. I accept the diagnosis: the math checks out and is the strongest evidence in the review. I disagree with the fix as phrased. Reopening tiers per biome means a second full cost table and a second balance pass for each biome, and the launch scope already does not fit in 6 months (my F1, FL-1). The cheaper fix is to retune numbers that already exist: raise the max levels and the growth rates, and make the native-bee multiplier (already "a multiplier", per Tree C) the main way effects compound. That fixes the curve without adding a new system. My recommendation to the board is to fix by tuning before fixing by adding.

**CONNECTION — SD-1 + my F3 (detail is inverted).** In Round 1 I said the differentiator was unspecified while lesser systems got exact numbers. SD-1 shows that the one fully specified system (Trees A/B) is also wrong, because it runs out within a few harvests. So the document has no economy that works yet, specified or not. That changes how Alpine Valley should be judged from a business view. If Trees A–C are shared per run, SD-5 shows the second biome only raises the sale price on an upgrade set that is already maxed. That makes it the most decorative item in the launch scope and the obvious first cut. It also expands the content-heavy part of scope: art, species and honey.

**REVISION — research trees (my F5).** I called "deep genetic research trees" probable creep. SD-1 shows that the economy has no long-run sink, and research is the only system that is designed as an in-game-money sink ("for faster run times ... do not carry over"). It may be the load-bearing system that fixes SD-1, not decoration. I am withdrawing the "creep" label. The finding is now: research is either the economy's main sink, and then must be specified before the first balance pass, or it should be cut. It cannot stay at "TBD", and it should not be the item cut first.

### B. Feasibility Lead

**CONFLICT — FL-1's cut candidates.** FL-1 names "Alpine Valley, research trees, French localization, and the Impact Pass" as obvious cuts. I agree on Alpine Valley. I disagree on the other three:
- **Research:** see the revision above.
- **French:** the game is positioned on Canadian conservation partners ("starting with Canadian conservation partners"). French support is likely expected, and may be legally relevant, for distribution and marketing in Quebec. Cutting it weakens the one market where the cause pitch is most credible. It is cheaper to keep French and reduce the text volume (Bee Journal facts) than to drop the language.
- **Impact Pass:** see connection C1 below. It is the only recurring revenue at launch, and the cause pillar is funded from it.

The cut list should be built around the pillar: keep what funds or shows conservation, and cut the second biome, accessibility parity on competitive features (moot if the competitive layer goes; see E), and server time validation for a launch that only has local PBs.

**CONNECTION — FL-4 (no art producer) + my F1 and F3.** FL-4 changes my scope estimate from "too many features" to "too many features with no source for half the assets". It also sharpens F3. The document gives full art direction for Biomes 3–4 and the Patron "engraved mahogany & brass" skin. These are art-heavy, post-launch items, specified in a pipeline that has no way to make art. Effort is going into describing assets that nobody can make.

**REVISION — my F1 "related overhead" paragraph (Martin, AI pipeline).** Partly withdrawn. I said the pipeline section shows too much process. FL-4 shows the opposite problem: the roster is missing roles that are needed (3D art, animation, VFX, localization, legal/finance). The issue is not too much pipeline but a pipeline aimed at the wrong gaps. A writer agent (William) has no story slots to fill (NC-3), while no agent can make a bee model. F1 itself stays BLOCKING, now with stronger evidence.

**CONNECTION — FL-2 + my F4.** We agree on compliance. Combining the two shows a revenue problem as well. If families/kids are core, Kid Mode requires child-directed, non-personalized ads, which earn a fraction of standard rewarded-ad revenue. Rewarded ads are one of only two launch revenue streams. A kids-forward audience therefore cuts launch ad revenue and the donation pool that the pillar promises.

### C. Player Psychologist

**C1. CONNECTION — PP-1 + SD-3 + my F5 (launch monetization): the launch subscription sells a benefit that does nothing in the early game.** The Impact Pass is sold on "auto-tap helpers, extended offline production" (Monetization). PP-1 and SD-3 show that in Phase 1 the frame capacity pause stops production long before any offline-hours cap. A new subscriber in their first days pays for extended offline production and gets nothing from it. This is the conversion window, when a new player is most likely to subscribe. That is a refund and review-score risk, and a cause-marketing risk ("pay to help bees" for a perk that does nothing). I am raising the launch-monetization part of my F5 from MINOR to MAJOR: the launch revenue model is either unclear (Royal Jelly IAP) or empty in Phase 1 (Impact Pass offline perk).

**CONFLICT — PP-2's fix adds a feature.** PP-2 is right that Phase 2 has no active purpose. Its recommendation should be limited to systems that already exist: biome milestones, Journal entries and habitat targets, which PP-2 also lists. It should not lead to a new Phase 2 minigame. The board should explicitly rule out "add a new activity" as the fix, because that is how a 6-month solo scope grows.

**AGREE WITH A DIFFERENCE — PP-4 (wall-clock pressure).** PP-4 suggests making run time a hideable "pace" stat. That is the cozy option from my F2, and I support it. But PP-4 treats it as a presentation fix. From the business side it also means the competitive machinery (brackets, server validation, booster tags) loses its reason to be in launch architecture. See E.

### D. Narrative Critic

**CONFLICT — NC-4 offers framing speed in the fiction ("the world is in decline and time matters").** That turns the game toward the racing fantasy, which is the wrong choice for the stated audience and for the comps. It also makes compulsive check-ins part of the story for a game marketed to families. I support NC-4's other option (reframe the success metric) and oppose the in-fiction urgency option.

**CONFLICT — NC-1's fix (restored worlds persist as a visitable collection).** This is a good fix for the fiction and a bad one for scope: each past run becomes a saved, renderable world, with save-schema and performance cost (FL-3, FL-5). The cheap version gives the same emotional result: a static snapshot or diorama card in the Bee Journal for each completed run (PP-5 already suggests "a gallery or a hive skin"). Launch should use the snapshot, and the visitable worlds can be a post-launch item.

**CONNECTION — NC-2 + my F4 (cause-marketing exposure).** NC-2 shows that the systems teach "native bees matter because they raise honey profit", and that the paid Patron perk is "+25% global honey value". From a positioning view this is a regulatory and PR risk, not only a theme problem. A product that markets itself to families as educational and conservation-funding, while its mechanics reward the managed-honeybee pressure the real conservation partners campaign against, can be picked apart by those partners or by press. It also makes partner sign-off harder, and partner sign-off is a precondition for the pillar (my F3). The habitat/biodiversity score should count toward the run's success metric before any partner pitch.

**CONNECTION — NC-5 + my F3.** The two biomes with the most art direction (Enchanted Grove, Cloud Gardens) are the two that can't carry real-world species facts. The most detailed content works against the educational claim, which is the main thing setting the game apart in the market.

### E. Adversarial QA

**CONNECTION — AQA-1, AQA-3, AQA-4, SD-4, FL-5 + my F2: the competitive layer is the root cause behind the largest group of findings on this board.** Counting across reviews, the speed-run/bracket layer is the source of AQA-1 (BLOCKING), AQA-3, AQA-4 (the accessibility mode as a competitive exploit), SD-4, FL-5 (ledger and save-schema lock-in), PP-4 and NC-4. That is seven findings from five reviewers, all caused by one feature that is post-launch online and conflicts with the stated audience. AQA-4 is the clearest example: an accessibility mode, which is good for a family audience, becomes a bug only because a competitive board exists. My lens can see what the others can't. This is not a set of edge cases to patch. It is one positioning decision that, once made, closes most of them.

**REVISION — upgrade my F2 from MAJOR to BLOCKING.** The "three games at once" problem now has measurable downstream cost across the whole board, and it has to be resolved before the save schema and backend are chosen (FL-5). My recommendation: cut ranked, booster-bracketed speed-running from the design. Keep run time as an optional personal stat. Treat online leaderboards as a separate future decision, not a launch architecture requirement. If the designer insists on the competitive layer, AQA-1's per-source jelly ledger becomes a launch requirement, not a nice-to-have.

**CONFLICT (minor) — AQA-1 Patron stipend edge cases.** These are valid but premature. The Patron Pass is post-launch, and Royal Jelly IAP may not ship at launch (my F5). The launch-relevant part is only the ledger schema (FL-5). The stipend rules should be deferred with the Patron Pass, not designed now. Designing them now repeats the pattern from my F3 of detailing post-launch features.

**CONNECTION — AQA-2 (unbounded Crystal "any starting upgrade") + my F1.** Every open-ended rule like this ("any one starting upgrade") multiplies QA and balance cases for a team with no QA owner other than one profiling agent. A whitelist is a design fix and also a scope control.

### Round 2 severity summary (my findings)
- F1 Scope: **BLOCKING, unchanged.** Evidence is stronger (FL-1, FL-4). The "AI pipeline overhead" sub-point is revised: the problem is the wrong roles, not too much process.
- F2 Three games at once: **MAJOR → BLOCKING.** It is the root cause of about seven findings across five reviewers.
- F3 Inverted detail: **MAJOR, unchanged.** Broadened by SD-1: even the specified economy fails.
- F4 Audience/compliance: **MAJOR, unchanged.** Now includes the effect of Kid Mode ad restrictions on revenue and the native-bee/honey mixed message (NC-2).
- F5: **split.** The launch-monetization part goes **MINOR → MAJOR** (the Impact Pass offline perk does nothing in Phase 1). The research-tree "creep" label is **withdrawn**: research must be specified as the main sink or cut. The title point stays MINOR.
