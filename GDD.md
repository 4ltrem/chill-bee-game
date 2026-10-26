# Chill Bee Game Design Document
**Working Titles:** Digibees, My Bee Hotel, Pocket Hive

---

## Executive Summary
A cozy, casual beekeeping and farming mobile-first game inspired by and the love child of *Egg, Inc.* and *Factorio* featuring wacky, satisfying progression and upgrades for your beehive. The primary gameplay objective is to make more honey and money. In the game, players can upgrade the beehive, the bees, and the native habitat—three distinct progression trees that feature synergizing effects with each other. The habitat tree measures success in biodiversity rather than honey, teaching the difference between managed honeybees and native wild bees. 

The UI is simple with no player character or avatar. The game acts as a pocket dimension on your device where players can zoom out and pan across the farm as it expands. The core gameplay loop spans three distinct phases with decreasing manual work:
* **Phase 1 (The Grinding Stage):** High manual labor. Players manually scrape/unframe and refine honeycombs through an uncapping and extraction minigame, plant and water flowers, and manually sell the product. (Players retain access to these manual interaction screens in later phases to manage tool upgrades).
* **Phase 2 (The Automation Era):** Players obtain their first few upgrades to automate harvesting, uncapping, and logistics, significantly reducing manual tasks.
* **Phase 3 (The Optimizing Stage):** The main loop comes into full swing. Players expand their biomes indefinitely on a grid, packing in denser hive and flower units. Building and charging the capstone, the Royal Honey Refinery, produces a Royal Crystal, after which players can choose to reset (Swarm Splitting / Royal Crystal Harvest): the swarm splits and leaves to restore a new pocket world. The reset is optional but encouraged, allowing players to retain persistent bonuses; players who want to compete can opt into bracketed speed-run leaderboards (see Leaderboards).

A core pillar of the project is its **Real-World Impact Integration**, where a portion of proceeds from in-game monetization (Impact Passes, rewarded ads, Adopt-a-hive) funds real-world bee conservation globally (native bee habitat restoration and managed hives), starting with Canadian conservation partners.

---

## Audience & Production Plan
* **Target Audience:** Adults and teens who play cozy games. Content is family-friendly, but the game is not marketed to children; kid mode still protects under-13 players (see Child Safety).
* **Team:** Solo developer directing AI agents in Claude Code (see AI Architecture).
* **Art Source:** Purchased low-poly asset packs, adapted and edited by the developer.
* **Timeline:** Milestone-based, with no fixed launch date. Proposed milestones:
  1. First playable (vertical slice below).
  2. Launch content complete: Sunny Meadow and Alpine Valley, grid expansion and unit tiers, Trees A–C, research, capstone, reset.
  3. Monetization, backend, kid mode, and French localization.
  4. Launch.
* **Languages:** English and French at launch.
* **Vertical Slice (First Playable):** One full rough run with placeholder art, mobile only, Sunny Meadow only: manual harvest → automation → grid expansion → capstone → reset. No monetization, leaderboards, or backend yet.
* **Launch Scope:** Mobile only; Sunny Meadow and Alpine Valley; rewarded ads and the Impact Pass; local personal-best run times; periodically updated impact totals.
* **Post-Launch:** Biomes 3–4 (Enchanted Grove, Cloud Gardens), the Patron Pass, online leaderboards, and the live Impact Dashboard.
* **Backend:** A managed game-backend service (provider TBD) for purchase receipts, cloud saves, and server time, and later for leaderboards.

### Child Safety
* **Age Gate:** Players enter their age at first launch.
* **Kid Mode (under 13):** No personalized ads, a parental gate before any purchase, and no public usernames.
* Players 13 and over get the full game.

---

## Game Mechanics

### 1. Primary Game Loop & Phase Structure
[1. Bees Forage] ──► [2. Hive Fills] ──► [3. Uncap & Extract Minigame]
▲                                                │
│                                                ▼
[5. Reinvest Profits] ◄── [4. Sell Honey at Market Stand]


* **Phase 1 (Manual Grinding):** Players actively perform uncapping swipes and centrifuge cranking, manage initial flower planting/watering, and handle sales.
* **Phase 2 (Automation):** Begins when the player buys their first automation upgrade (see Tree B: Automation), unlocking automated uncapping hubs, electric centrifuges, and auto-transport trucks. Manual screens remain accessible for upgrading tool efficiency and batch multipliers; once harvesting is automated, tool upgrades apply as flat bonuses (see Tree B).
* **Phase 3 (Prestige Reset / Optimization):** Fully charging the capstone Royal Honey Refinery (see Capstone) produces a Royal Crystal, the end-game reward. Players can then trigger an optional (but encouraged) reset. Each Royal Crystal earned:
  * Permanently adds +10% production, additive (10 Crystals = +100%, 20 = 3x, 100 = 11x). The Patron Pass +25% is applied as a separate multiplier, not added to this percentage.
  * Can also be applied to one starting upgrade for future runs, chosen from a whitelist (e.g., bigger starting frames, faster tools, starting land, starting flower or hive units). Crystals shorten Phase 1 but never skip it: automation and the capstone cannot be pre-bought.
  * Extra starting hives follow the normal Hive Balance rule and lower starting Habitat Health. A matching "starting wildflower plot" option raises it, capped at the habitat worth of Habitat Synergy level 3 (a higher start would open Alpine Valley at minute zero and mainly help the rush). The Crystal screen shows a live Habitat Health preview, and both options have a max level (TBD). See `balance/royal-crystal-balance.md`.

  Royal Crystals carry over between runs. Research trees are purchased with in-game money and do not carry over between runs. Research does three things: bee and flower genetics that multiply production, unlocking higher unit tiers (see Land, Grid & Units), and upgrades for the Royal Honey Refinery (values TBD).

* **Pests & Wild Nectar Drops:** Appear only during active play and pause while offline. Tapping them gives a small reward (cleared pests or collected nectar); ignoring them costs nothing. The Patron Golden Drone taps them automatically.

### 2. Phase 1 Uncapping & Extraction Minigame
When hive storage reaches capacity in Phase 1, players trigger a tactile, two-stage harvesting sequence. Every player has a small free overflow buffer from the start, so production continues past capacity (including while offline) until the buffer is full. The free buffer holds one extra full frame (10 jars at base, growing with Deep Frame). Overflow Storage enlarges the buffer, Auto-Sell sells overflow honey, and buying automation removes the capacity pause entirely (see Tree B).

* **Stage 1: Uncapping (Tactile Swiping)**
  * Camera zooms to a 3D wooden honeycomb frame tilted at an isometric angle.
  * Player swipes a low-poly uncapping tool (fork or heated blade) across matte yellow capped wax cells to reveal glowing golden honey underneath.
  * Supported by particle pop effects, popping audio cues, and native mobile haptic feedback.
* **Stage 2: Centrifuge Extraction (Speed Taps)**
  * The uncapped frame drops into a low-poly wooden barrel centrifuge.
  * Player taps a primary crank button or spins an on-screen handle to accelerate rotation, spraying honey streams against glass walls and filling glass jars at an open spigot.
  * Completing the batch displays a summary modal showing base honey value, tool precision bonuses, and artisanal quality multipliers.

### 3. Progression Trees & Economy Balance
Progression is split across three synergizing upgrade paths using an exponential cost model ($\text{Cost} = \text{Base} \times \text{Growth}^{\text{Level}}$):

* **Tree A: Bee Upgrades (Swarm Size & Flight Endurance)**
  * *Worker Swarm Count:* Adds active foraging bees (+15% fill rate per level, base cost $25, 1.18x growth factor, max level 10).
  * *Flight Endurance:* Increases bee movement speed between flowers and hive (+10% speed per level, base cost $15, 1.15x growth).
* **Tree B: Hive & Tool Efficiency**
  * *Heated Uncapping Fork:* Increases swipe radius by +12% per level and adds up to +5% batch bonus for clean cuts (base cost $40, 1.22x growth, max level 5).
  * *Centrifuge Gearing:* Reduces required extraction taps/spins by -15% per level (base cost $35, 1.20x growth, max level 5).
  * *Deep Frame:* Increases frame capacity from 10 jars to 25 jars per harvest (base cost $150, 1.45x growth, max level 3).
  * *Tool Upgrades After Automation:* Once harvesting is automated, or in No-Rapid-Tap Mode, the Heated Uncapping Fork applies as a flat +% yield bonus and Centrifuge Gearing as a flat −% extraction time (values TBD), so these upgrades keep their value.
  * *Overflow Storage (optional):* Enlarges the free overflow buffer, so returning players have extra frames waiting to harvest (capacity and costs TBD).
  * *Auto-Sell (optional):* Automatically sells overflow honey at a discounted price (discount and costs TBD).
  * *Automation:* Automated uncapping hubs, electric centrifuges, and auto-transport trucks, bought with in-game money. Buying the first automation upgrade moves the player into Phase 2 and removes the capacity pause (costs TBD).
  * *Artisanal Branding:* Increases base sale value per jar by +$2.50 (base cost $60, 1.25x growth, max level 10).
* **Tree C: Native Habitat**
  Its own progression track, measured in biodiversity (Habitat Health and native bee species attracted) rather than honey. Upgrades are bought with in-game money (values TBD).
  * *Flower Patches:* Plant and upgrade patches of real Canadian native wildflowers to raise the biome's Habitat Health. Initial list (to be fact-checked):

    | Biome | Native wildflowers |
    |---|---|
    | Sunny Meadow | Goldenrod, wild bergamot, New England aster, black-eyed Susan |
    | Alpine Valley | Fireweed and other alpine wildflowers (TBD) |
    | Enchanted Grove, Cloud Gardens | Fictional flowers, labelled as fictional in the Bee Journal |
  * *Native Bees:* Habitat Health attracts native wild bees to the farm, separate from the managed honeybees. Native bees:
    * Pollinate flowers, speeding flower growth and Habitat Health.
    * Grant production multipliers across Trees A and B (the habitat/bee synergy); more native bees means a bigger multiplier.
  * *Hive Balance:* Managed honeybees compete with native bees for the same flowers. Placing hives on the grid without enough flowers lowers Habitat Health, so players balance hive count against planting.
  * *Habitat Synergy Level:* Each biome has a graded Habitat Synergy level, based on whether it has enough flowers for its bees to pollinate and make honey from. Synergy is money-driven: it rises as soon as flowers are placed, with no growth timers. Reaching a biome's unlock threshold opens the next biome, and the Refinery needs its host biome to stay above a minimum level (values in `balance/refinery-parameters.md`).
  * *Native Bee Species:* Launch biomes attract real Canadian native bee groups (e.g., bumble bees, mason bees, leafcutter bees, sweat bees, mining bees; per-biome assignment TBD). Biomes 3–4 attract fictional species, clearly labelled as fictional in the Bee Journal. Each species has a mechanical effect in its biome: faster hive fill rate, faster pollination (Habitat Synergy rises faster), or better honey quality (higher sale value or Refinery yield). Effects are designed by Gerard and balanced by Terry (values TBD).
  * *Bee Journal:* Each native species attracted is recorded in the Bee Journal with short real-world facts. William drafts the facts (English and French) with cited sources, and a conservation partner reviews them before launch.
  * *On Reset:* The Bee Journal is permanent; Habitat levels reset with the farm each run.
* **Capstone: Royal Honey Refinery** (full proposal: `design/capstone-machine.md`)
  * **Build:** A very expensive machine bought with in-game money and placed on the grid in one biome (its host biome).
  * **Charge:** A single slider sends a share of every biome's honey into the Refinery, which refines it into Royal Honey. Each jar adds its sale value × its biome's affinity rate, and later biomes have higher affinity, so the stacked production of all biomes charges it fastest.
  * **Habitat lock:** The Refinery only refines while its host biome stays above a minimum Habitat Synergy level. Below it, refining pauses but nothing drains.
  * **Royal Crystal:** When the charge meter is full, a Royal Crystal forms and the run is complete. The player can then choose to reset.
  * **Speedrun route:** A player can stay in Sunny Meadow, rush the top unit tiers, keep just enough flowers for the habitat minimum, and send everything into the Refinery. This route is intentionally left open. It is clearly slower than the normal route for new and low-Crystal players, and about equal (within ~5%) for veteran players with many Crystals, so they can choose either route. A maximum Refinery charging speed keeps it from ever being clearly better.
  * **Target run length:** A new player's first run, from start to the first Royal Crystal, takes about 3 days (72 hours) at launch and about 47 hours once biomes 3–4 ship. The shorter post-launch run is the price of keeping the rush equal for veterans.
  * **Charge phase:** How much of a run is spent charging the Refinery is TBD. Terry's model has about 45 of 72 hours at launch. Stacking production across biomes should speed up charging, and research can buy Refinery upgrades (effects TBD).
  * **Charging-speed cap:** Whether the cap is strict (the rush is never faster) or tolerant (up to 2% faster) is TBD, to revisit once the Refinery research upgrades exist.
  * **Provisional values:** Terry's proposed parameters are in `balance/refinery-parameters.md`. They come from a stand-in model and must be re-derived once the real economy and the per-biome setup time are measured.
  * **Content versions:** The charge target is stored per content version, so adding biomes 3–4 never changes stored run times. Each run also records the highest biome that contributed honey.
  * Parameters are set by Terry (build cost, charge target, biome affinities, Habitat Synergy minimum, maximum share sent to the Refinery, footprint).

### 4. Land, Grid & Units
* **Indefinite Expansion:** Each biome can be expanded indefinitely by buying more land with in-game money (cost growth TBD).
* **Grid Placement:** Players place each hive and flower unit on the biome's grid themselves. Space is limited, so the goal is the most honey production per tile.
* **Hive & Flower Units:** Hives and flower patches are bought and placed as units. Each unit type has tiers (e.g., Langstroth hive → stacked hive → hive tower; wild patch → raised bed → vertical garden). Higher tiers cost much more in-game money but produce more in less space. Units can be upgraded in place.
* **Biome Units:** Each biome adds new top-tier units in its own style (e.g., chalet hives in Alpine Valley, lantern hives in Enchanted Grove).
* **Unlocking Tiers:** Higher unit tiers are unlocked through research (see Phase 3).

### 5. Leaderboards
Leaderboards are opt-in: the game is cozy by default, and only players who choose to compete enter ranked runs. Online leaderboards are post-launch; at launch, players see local personal-best run times. Speed-run leaderboards are bracketed so players only compete against others who used the same boosters within a given run:
* **Player Names:** Players build their display name from preset word lists (no free text). Kid-mode players have no public username.
* **Run-Based Brackets:** Each run is tagged with every paid booster active during that run (e.g., Impact Pass, Patron Pass). A run with no purchases ranks on the unboosted board; boosted runs rank only against runs with the same booster set.
* **Royal Crystal Tiers:** Runs are also bracketed by the player's Royal Crystal count (e.g., 0, 1–5, 6–20, 21–50, 51–100, 101+; the high tiers are split because production spans about 10x above 21 Crystals; exact tiers TBD), so players race others at a similar prestige level.
* **Run Time:** Wall-clock time from the start of a run until the Royal Crystal forms in the Refinery, offline time included.
* **Server-Side Time Validation:** Run times are validated server-side to counteract device-clock manipulation of offline earnings.
* **Rewarded Ads:** Free rewarded-ad boosts do not count as a paid booster; runs that use them stay on the unboosted board.
* **Royal Jelly:** Using purchased Royal Jelly during a run counts as a paid booster. Any run that spends Royal Jelly on time skips (earned or purchased) is also tagged "time-skipped" and ranks separately, so saved-up earned Jelly can't produce record times on the unboosted board.
* **Run Tracking (from launch):** Even though online leaderboards are post-launch, the launch save format records:
  * The source of every unit of Royal Jelly (play, rewarded ad, purchase, Patron stipend).
  * Every booster active during each run, with start and end times.
  * A content version on every stored run, so times from runs with different biome content are never compared.

### 6. Currencies & Offline Earnings
| Currency | Earned From | Spent On | Carries Over Resets |
|---|---|---|---|
| In-game money | Selling honey | Land, hive and flower units, upgrades (Trees A–C), and research trees | No |
| Royal Jelly (premium) | Slowly through play and rewarded ads; purchasable with real money; Patron daily stipend | Time skips and production speed-ups | Yes |
| Royal Crystal (prestige) | Fully charging the Royal Honey Refinery (capstone) | Stacking permanent production boost + one whitelisted starting upgrade per Crystal | Yes |

* **Offline Earnings:** Players earn offline up to a cap: 4 hours for free players, 12 hours with the Impact Pass, and 24 hours with the Patron Pass.

### 7. Story Premise & Onboarding
**Premise:** The player discovers a tiny magical pocket world that needs a beekeeper to restore it.

**Reset Story:** When the player resets, the swarm splits and leaves to restore a new pocket world; the restored world is not destroyed. Each finished world is kept as its own save, which players can load and keep playing separately. Royal Crystals and Royal Jelly belong to the player and carry into each new world. In-game money stays in the world where it was earned. In kept worlds, the Refinery becomes a dormant monument, so old worlds cannot produce more Crystals.

A guide character (e.g., a queen bee; name and personality TBD) walks new players through their first session:
* Explains why the meadow matters and introduces the farm.
* Guides the first manual harvest (uncapping and centrifuge extraction).
* Guides the first upgrade purchase.

### 8. Accessibility
* **No-Rapid-Tap Mode:** Replaces speed taps and crank spinning with hold-to-crank or a single tap.
* **Haptics & Sound Toggles:** Vibration, sound effects, and music can each be turned on or off.
* **Colour-Blind Support:** Information never relies on colour alone (e.g., capped and uncapped cells also differ in shape or texture).
* **Text Size & One-Handed Play:** Adjustable text size, and all UI reachable with one thumb.

### 9. UI & Screens
* **Farm View (Main Screen):** The pannable, zoomable pocket-dimension farm, including a build mode for buying land and placing hive and flower units on the grid.
* **Upgrade Shop:** Trees A–C, automation, research, and the capstone.
* **Worlds:** Load and switch between saved pocket worlds.
* **Harvest Minigame:** The uncapping and centrifuge extraction screens.
* **Impact & Leaderboards:** Impact totals, personal-best run times, and (post-launch) online leaderboards.
* **Store:** Royal Jelly and passes, behind the parental gate in kid mode.
* **Settings:** Accessibility options and language.

---

## Environmental & Visual Identity

### Aesthetic & Tone
* **Art Style:** Minimalist 3D low-poly with vibrant pastel greens, oversized sunflowers, glowing clover patches, and clean isometric terrain chunks that fit together like floating diorama pieces.
* **Bees & Characters:** Chunky, rounded low-poly bee models with exaggerated cute features, translucent wings with shimmer, and tiny pollen backpack canisters.
* **Tone & Audio:** Playful, whimsical, and cozy. Relaxed ukulele and acoustic background music paired with tactile popping sound effects for cell uncapping.

### Progression Tiers & Biomes
Biomes are stages within a single run, played in order. A biome's Habitat Synergy threshold (enough flowers for its bees to pollinate and make honey from) unlocks the next biome. Earlier biomes keep producing at full rate and can still be expanded and upgraded, so production stacks across biomes. A reset starts a new pocket world in Sunny Meadow. Each biome:
* Produces its own honey, each more sought after (higher sale value) than the last (values TBD). Alpine Valley honey must sell for less than 2× Sunny Meadow honey, or it would charge the Refinery less per jar than Meadow honey (see `balance/refinery-parameters.md`).
* Attracts its own local native bee species, each with different effects (species and effects TBD), recorded in the Bee Journal.

1. **Sunny Meadow:** Rolling green hills, wild clover, and classic wooden Langstroth hives (*Wildflower Gold Honey*).
2. **Alpine Valley:** Pine trees, fireweed meadows, and Swiss-style chalet hives (*Frosted Fireweed Honey*).
3. **Enchanted Grove:** Oversized glowing mushrooms, night-blooming flora, and lantern-shaped hanging hives (*Moonlight Nectar*).
4. **Cloud Gardens:** Floating low-poly sky islands, rainbow blossoms, and brass solar-powered hives (*Stardust Honey*).

---

## Real-World Impact & Monetization

### Conservation Partnerships
* **In-Game Impact Dashboard:** Tracks live community restoration stats (e.g., total square meters of bee habitat restored).
* **Canadian Non-Profit Partnerships:** Initial donation routing targets organizations such as Pollinator Partnership Canada, Wildlife Preservation Canada, and local provincial native bee societies.
* **Donation Commitments:** Each revenue stream donates one fixed, auditable percentage, stated as a single number rather than a range (values TBD before any cause marketing).

### Monetization Architecture
* **Non-Predatory Rewarded Ads:** Optional 2x production boosts explicitly tied to native habitat funding, with a fixed percentage of ad revenue donated (TBD).
* **Impact Pass (Monthly Pass):** Offers mid-tier quality-of-life perks (auto-tap helpers, extended offline production) with a fixed percentage of proceeds pledged to conservation partners (TBD).
* **Top-Tier Monetization: Adopt-a-Hive ("Patron Pass", Monthly Subscription)**
  * *Concept:* The premier monetization tier (highest cost / highest real-world impact). All Patron bonuses are active only while the subscription is active and stop when the player stops paying. A fixed percentage of proceeds (TBD) directly funds both managed hives and native bee habitat restoration with conservation partners.
  * *Visual Prestige:* Unlocks an engraved mahogany & brass hive skin with a custom nameplate displaying real-world restoration coordinates, plus a golden "Patron" badge on speed-run leaderboards.
  * *Automation & QoL:* Grants the "Golden Drone" auto-collector (automatically collects wild nectar drops and handles pest events) and extends offline idle earnings up to 24 hours.
  * *Subscription Boosts:* +25% global honey value multiplier (persists across Phase 3 resets while subscribed) and a daily stipend of Royal Jelly, the premium currency, which speeds up progression (values TBD once progression numbers are decided; upgrades and research are purchased with in-game money).

---

## AI Architecture

### Token Budgets
All agents draw from one shared daily pool (no per-agent caps). The developer is on the Claude Pro plan, which has a rolling 5-hour limit and a weekly limit shared across Claude and Claude Code, including subagents. Anthropic does not publish a token count for these limits, so the absolute budget is calibrated:
1. Run a known task (e.g., one design-review round, about 250k tokens) and note the weekly usage percentage in `/usage` before and after.
2. Tokens per 1% of the weekly limit = tokens used ÷ percentage change.
3. **Daily budget** = 14.3% of the weekly limit (1/7) × tokens per 1% = **TBD tokens/day** (filled in after calibration).

**Per-task estimates** (measured from agent runs; full log in `ai/agent-runs.md`):

| Agent | Tokens per task | Runtime per task | Basis |
|---|---|---|---|
| Gerard | 59,822 | ~2 min | Measured (1 run) |
| Terry | 121,361 | ~19 min | Measured (average of 3 runs; 54.5k–174k) |
| Connie | ~42,000 | ~1 min | Estimated from document-review runs (not yet run) |
| William | ~60,000 | ~2 min | Estimated from Gerard's design-writing run (not yet run) |
| Bob, Patricia, Andrew, Martin, Quinn | TBD | TBD | No similar runs yet |

### API Constraints
All agents run through Claude Code, using different models depending on the task. API usage is divided into modular execution pipelines, ensuring individual agent calls remain constrained to their designated token windows to prevent context overlap.

### Actionable Strategy Formalized from Agent Role Definitions
Each specialized agent functions as a dedicated module in the development workflow, executing discrete tasks triggered by developer inputs and producing structured outputs.

### Agent Roles

#### Gerard, the Gameplay Architect
* **Role:** This agent analyzes the proposed feature against the existing gameplay system when the user proposes a new feature, and the developer sees a structured representation of how the feature will affect the others.

#### Bob, the Builder
* **Role:** This agent assembles biome dioramas and terrain chunks as Godot scene files (`.tscn`) when the user proposes a layout description, and the developer sees the finished scene, following the specs of the layout.

#### Patricia, the Programmer
* **Role:** This agent creates modular components and code for the game engine when a list of features is given, and the developer sees the completed components and/or script. Also owns backend integration.

#### William, the Writer
* **Role:** This agent writes the story outline when the user gives an idea for a story point, lesson, or goal, and the developer sees a completed outline. Also drafts the Bee Journal's real-world facts in English and French, with cited sources, for review by a conservation partner.

#### Andrew, the Audiophile
* **Role:** This agent searches and curates audio sound effects and music tracks when given a description of a sound, environment, vibe, or place, and the developer sees the curated structured list and accompanying folder with the selected audio files.

#### Terry, the Progression Tree Expert
* **Role:** This agent analyzes the balance of the progression tree, such as efficiency rating, cost, speed, space requirement, and other metrics available which can be found in the progression file when provided with a suggested upgrade/progression, and the developer sees a detailed report/outline comparing the suggestion against existing upgrades/progressions if possible.

#### Martin, the Hiring Manager
* **Role:** This agent creates agent descriptions following the template in the Agent Roles section of `GDD.md` when the lead architect notices there's a skill gap within the team, and the developer sees a git diff of the new agent(s) proposed inside the agent roles section.

#### Connie, the Compliance Officer
* **Role:** This agent reviews features for child-safety (kid mode, COPPA, app-store kids and families rules, ad SDK settings), charity and cause-marketing (donation disclosures, partner agreements), privacy and data (PIPEDA, Quebec Law 25, privacy policy), and app-store policy (subscriptions, premium currency, rewarded ads, donations) risks when a feature touches those areas or before store submission, and the developer sees a findings report and checklist in `compliance/`, citing official sources, with items needing lawyer or partner sign-off marked. Defined as a runnable Claude Code agent in `.claude/agents/compliance-officer.md`.

#### Quinn, the QA & Build Engineer
* **Role:** This agent writes and runs tests, produces mobile builds, and profiles performance against the 60 FPS target when a feature or build is ready for testing, and the developer sees a test report, build output, and performance profile.

---

## Prompt Constraints
Dedicated section for defining agent prompt constraints to ensure consistent, repeatable outputs from every model in the pipeline:
1. **Scope Boundary:** Agents must only output deliverables strictly within their role domain (e.g., Patricia handles GDScript/C#, Terry handles numeric balance matrices).
2. **Deterministic Formatting:** Output formats must follow predefined Markdown schemas or JSON data structures for seamless agent-to-agent communication.
3. **No Hallucinated Systems:** All suggestions must ground themselves within the existing 3-phase progression model and low-poly 3D constraint set.

---

## Engine Integration

### Engine Selected: Godot Engine
* **Integration Strategy:** Selected for its open-source architecture, lightweight footprint, and seamless integration with CLI-based developer workflows (such as Claude Code).
* **Scripting Language:** GDScript for rapid UI/gameplay iterations, combined with C# for performance-critical grid operations and save-state serialization if required.
* **Data Structure Architecture (Cell Grid & Uncapping):**
  * *Honeycomb Grid Data:* Represented as a 2D Array or byte array (2 bits per cell) in GDScript tracking individual cell status (`0 = Capped`, `1 = Uncapped`, `2 = Extracted`).
  * *Input Raycasting:* `PhysicsDirectSpaceState3D` raycasting maps touch/mouse drag vectors onto the 3D frame collision shape to slice open cells.
  * *Haptic Feedback Interface:* Platform-native wrapper calling OS vibration APIs (`Input.vibrate_handheld()`) on cell state transitions.

---

## Technical Constraints

* **Target Platforms:** Mobile devices (iOS & Android, including tablets) at launch. Nintendo Switch and Desktop (PC/Mac) are post-launch options, each requiring its own business model and input scheme.
* **Art Style Constraints:** Low-poly 3D art style utilizing flat-color palette texture atlases and low vertex counts to ensure optimal performance across low-end mobile hardware.
* **Performance Targets:** Must maintain a stable 60 FPS performance target with hundreds of low-poly bees and floating diorama elements rendered simultaneously on screen.
* **Bee Rendering Plan:** Production is calculated from a bee count, which can grow without limit. Only a capped crowd of bees is drawn, using instanced rendering (Godot `MultiMeshInstance3D`), with simpler visuals when zoomed out. Swarm size is shown with a counter and denser flight trails, so upgrades still look like they did something (visual cap TBD after profiling).
* **Test Devices:** Quinn profiles on one low-end, one mid-range and one high-end phone each for Android and iOS, plus one tablet (exact models TBD).

---

## Glossary

Terms used in this document and in the design and balance reports (`design/`, `balance/`).

### Runs & Routes
| Term | Also called | Meaning |
|---|---|---|
| Run | Playthrough | One playthrough from a fresh pocket world until a Royal Crystal forms in the Refinery. |
| Reset | Swarm Splitting, Royal Crystal Harvest | Optional action after a Crystal forms: the swarm leaves to restore a new pocket world, and the old world is kept as its own save. |
| Normal route | Full route | Unlock and play through every biome in order, then charge the Refinery with their combined honey. |
| Rush | Meadow rush, first-biome rush, speedrun route, shortcut | Stay in Sunny Meadow, never unlock later biomes, and build and charge the Refinery there. Intentionally allowed. |
| Alpine stop / Grove stop | Partial shortcut | Unlock some biomes but stop at Alpine Valley or Enchanted Grove instead of reaching the last biome. |
| Content version | — | How many biomes existed when a run was played (launch = 2, post-launch = 4). Run times from different versions are never compared. |

### Comparing Routes
| Term | Meaning | Example |
|---|---|---|
| Rush gap | Rush run time ÷ normal-route run time. Above 1.00 means the rush is slower. | 1.20 = the rush takes 20% longer. |
| Equal for veterans | Design goal: the rush gap shrinks to about 1.00–1.05 for players with many Crystals, but never drops below 1.00. | 1.03 at 100 Crystals. |
| Crossover | The Crystal count at which the rush would become faster than the normal route. Balance keeps this from happening. | — |
| M | A player's total production multiplier. | +10% per Crystal: M = 1 + 0.10 × Crystals. |
| M(n) | M at n Crystals. | M(60) = 7.0. |
| M\* | The multiplier at which the crossover would happen. "M\* ≥ M(60)" means the rush can't win before 60 Crystals. | — |
| Fixed setup time | F (route), ΔF (per biome). The part of a run that more production can't speed up, such as unlocking and setting up each biome. The rush skips biomes, so it has less fixed time. | Terry assumes ΔF = 1 h per biome. |
| Stacking | Earlier biomes keep producing while you build later ones, so total production adds up across biomes. | — |

### Royal Honey Refinery (Capstone)
| Term | Parameter | Meaning |
|---|---|---|
| Host biome | — | The biome where the Refinery is placed. Only its Habitat Synergy must stay above the minimum. |
| Build cost | `CAP_BUILD_COST` | In-game money needed to build the Refinery. |
| Footprint | `CAP_FOOTPRINT` | Grid tiles the Refinery occupies. |
| Charge | — | How full the Refinery is with Royal Honey. |
| Charge target | `CAP_CHARGE_TARGET[content_version]` | Royal Honey needed for the Crystal to form, stored per content version. |
| Divert | — | The slider share of each biome's honey sent to the Refinery instead of being sold. |
| Divert max | `CAP_DIVERT_MAX` | The highest divert share allowed. |
| Affinity | `AFFINITY[biome]` | Charge one jar of a biome's honey gives. Later biomes have higher affinity. |
| Throughput cap | `CAP_THROUGHPUT_MAX` (κ, "kappa", in Terry's math) | Maximum charging speed: the most honey jars per hour the Refinery accepts. Keeps the rush from ever beating the normal route. |
| Yield | Y | Royal Honey per jar from a biome, relative to Sunny Meadow (Meadow = 1). |
| Synergy minimum | `CAP_SYNERGY_MIN[biome]` | Habitat Synergy level the host biome must stay above for refining to continue. |
| Unlock condition | `CAP_UNLOCK_CONDITION` | What must happen before the Refinery can be built. |
| Rush gap target | `RUSH_GAP_TARGET` | The rush gap values balance aims for at each Crystal count. |
| Frontier bonus | — | **Rejected.** Extra affinity for whichever biome is currently last. |

### Habitat
| Term | Meaning |
|---|---|
| Habitat Health | Tree C's measure of a biome's habitat. It is raised by flowers and lowered by hives that lack enough flowers. |
| Hive Balance | The rule that managed honeybees compete with native bees: hives without enough flowers lower Habitat Health. |
| Habitat Synergy level | A biome's graded habitat score: whether it has enough flowers for its bees. It is money-driven and rises as soon as flowers are placed. |
| Unlock threshold | The Habitat Synergy level that opens the next biome. |
| Native bees | Wild bees attracted by habitat. They pollinate, multiply honey production, and are recorded in the Bee Journal. |

### Currencies & Prestige
| Term | Meaning |
|---|---|
| In-game money | Earned by selling honey. Spent on land, units, upgrades and research. Stays in its world. |
| Royal Jelly | Premium currency, earned or bought, spent on time skips. Account-wide. |
| Royal Crystal | Prestige reward from the Refinery: +10% production (additive), plus one whitelisted starting upgrade. Account-wide. |
| Starting upgrade | A head start for future runs bought with a Crystal, such as starting land, faster tools, extra starting hives or a starting wildflower plot. |
| Free overflow buffer | Extra storage of one full frame, so production continues while the hive is full. |
| Offline cap | Hours of offline earnings: 4 h free, 12 h Impact Pass, 24 h Patron Pass. |

### Leaderboards (opt-in)
| Term | Meaning |
|---|---|
| Booster | A paid advantage active during a run, such as the Impact Pass, the Patron Pass or purchased Royal Jelly. |
| Booster set | All boosters active during a run. Runs only compete against runs with the same set. |
| Unboosted board | Runs with no purchases. Free rewarded ads are allowed. |
| Time-skipped tag | Marks runs that spent Royal Jelly on time skips, earned or bought. They rank separately. |
| Crystal tier | Groups by Royal Crystal count (e.g., 0, 1–5, 6–20, 21–50, 51–100, 101+). |
| Run time | Wall-clock time from the start of a run until the Crystal forms, offline time included. |

### Agents
| Agent | Role | Agent file |
|---|---|---|
| Gerard | Gameplay Architect | — |
| Bob | Builder | — |
| Patricia | Programmer | — |
| William | Writer | — |
| Andrew | Audiophile | — |
| Terry | Progression Tree Expert | — |
| Martin | Hiring Manager | — |
| Connie | Compliance Officer | `.claude/agents/compliance-officer.md` |
| Quinn | QA & Build Engineer | — |
