# Chill Bee Game Design Document
**Working Titles:** Digibees, My Bee Hotel, Pocket Hive

---

## Executive Summary
A cozy, casual beekeeping and farming mobile-first game inspired by and the love child of *Egg, Inc.* and *Factorio* featuring wacky, satisfying progression and upgrades for your beehive. The primary gameplay objective is to make more honey and money. In the game, players can upgrade the beehive, the bees, and the vegetation/environment—three distinct progression trees that feature synergizing effects with each other. 

The UI is simple with no player character or avatar. The game acts as a pocket dimension on your device where players can zoom out and pan across the farm as it expands. The core gameplay loop spans three distinct phases with decreasing manual work:
* **Phase 1 (The Grinding Stage):** High manual labor. Players manually scrape/unframe and refine honeycombs through an uncapping and extraction minigame, plant and water flowers, and manually sell the product. (Players retain access to these manual interaction screens in later phases to manage tool upgrades).
* **Phase 2 (The Automation Era):** Players obtain their first few upgrades to automate harvesting, uncapping, and logistics, significantly reducing manual tasks.
* **Phase 3 (The Optimizing Stage):** The main loop comes into full swing. Upon reaching the end of the progression tree, the pocket dimension resets (Swarm Splitting / Royal Jelly Harvest), allowing players to retain persistent bonuses while competing for high scores based on completion speed on bracketed leaderboards (see Leaderboards).

A core pillar of the project is its **Real-World Impact Integration**, where a portion of proceeds from in-game monetization (Impact Passes, rewarded ads, Adopt-a-hive) funds real-world bee conservation globally (native bee habitat restoration and managed hives), starting with Canadian conservation partners.

---

## Game Mechanics

### 1. Primary Game Loop & Phase Structure
[1. Bees Forage] ──► [2. Hive Fills] ──► [3. Uncap & Extract Minigame]
▲                                                │
│                                                ▼
[5. Reinvest Profits] ◄── [4. Sell Honey at Market Stand]


* **Phase 1 (Manual Grinding):** Players actively perform uncapping swipes and centrifuge cranking, manage initial flower planting/watering, and handle sales.
* **Phase 2 (Automation):** Unlocks automated uncapping hubs, electric centrifuges, and auto-transport trucks. Manual screens remain accessible for upgrading tool efficiency and batch multipliers.
* **Phase 3 (Prestige Reset / Optimization):** When hive capacity and tech trees peak, players trigger a dimension reset. This awards permanent "Queen Markers" (Royal DNA) that boost global production rates and unlock deep genetic research trees for faster run times.

### 2. Phase 1 Uncapping & Extraction Minigame
When hive storage reaches capacity in Phase 1, players trigger a tactile, two-stage harvesting sequence:

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
  * *Expanded Frame Deep:* Increases frame capacity from 10 jars to 25 jars per run (base cost $150, 1.45x growth, max level 3).
* **Tree C: Environment & Monetization**
  * *Habitat Health:* Plant and upgrade native flower patches (Clover, Lavender, Buckwheat) to raise the meadow's habitat health, which grants production multipliers across Trees A and B and attracts visible native bees to the farm (values TBD).
  * *Artisanal Branding:* Increases base sale value per jar by +$2.50 (base cost $60, 1.25x growth, max level 10).

### 4. Leaderboards
Speed-run leaderboards are bracketed so players only compete against others who used the same boosters within a given run:
* **Run-Based Brackets:** Each run is tagged with every paid booster active during that run (e.g., Impact Pass, Patron Pass). A run with no purchases ranks on the unboosted board; boosted runs rank only against runs with the same booster set.
* **Server-Side Time Validation:** Run times are validated server-side to counteract device-clock manipulation of offline earnings.
* **Rewarded Ads:** Free rewarded-ad boosts do not count as a paid booster; runs that use them stay on the unboosted board.

### 5. Onboarding & First Session
A guide character (e.g., a queen bee; name and personality TBD) walks new players through their first session:
* Explains why the meadow matters and introduces the farm.
* Guides the first manual harvest (uncapping and centrifuge extraction).
* Guides the first upgrade purchase.

---

## Environmental & Visual Identity

### Aesthetic & Tone
* **Art Style:** Minimalist 3D low-poly with vibrant pastel greens, oversized sunflowers, glowing clover patches, and clean isometric terrain chunks that fit together like floating diorama pieces.
* **Bees & Characters:** Chunky, rounded low-poly bee models with exaggerated cute features, translucent wings with shimmer, and tiny pollen backpack canisters.
* **Tone & Audio:** Playful, whimsical, and cozy. Relaxed ukulele and acoustic background music paired with tactile popping sound effects for cell uncapping.

### Progression Tiers & Biomes
1. **Sunny Meadow:** Rolling green hills, wild clover, and classic wooden Langstroth hives (*Wildflower Gold Honey*).
2. **Alpine Valley:** Pine trees, lavender fields, and Swiss-style chalet hives (*Frosted Lavender Honey*).
3. **Enchanted Grove:** Oversized glowing mushrooms, night-blooming flora, and lantern-shaped hanging hives (*Moonlight Nectar*).
4. **Cloud Gardens:** Floating low-poly sky islands, rainbow blossoms, and brass solar-powered hives (*Stardust Royal Jelly*).

---

## Real-World Impact Integration

* **In-Game Impact Dashboard:** Tracks live community restoration stats (e.g., total square meters of bee habitat restored).
* **Canadian Non-Profit Partnerships:** Initial donation routing targets organizations such as Pollinator Partnership Canada, Wildlife Preservation Canada, and local provincial native bee societies.

## Real-World Impact & Monetization

### Conservation Partnerships
* **In-Game Impact Dashboard:** Tracks live community restoration stats (e.g., total square meters of bee habitat restored).
* **Canadian Non-Profit Partnerships:** Initial donation routing targets organizations such as Pollinator Partnership Canada, Wildlife Preservation Canada, and local provincial native bee societies.

### Monetization Architecture
* **Non-Predatory Rewarded Ads:** Optional 2x production boosts explicitly tied to native habitat funding.
* **Impact Pass (Monthly Pass):** Offers mid-tier quality-of-life perks (auto-tap helpers, extended offline production) with 25–50% of proceeds pledged to conservation partners.
* **Top-Tier Monetization: Adopt-a-Hive ("Patron Pass", Monthly Subscription)**
  * *Concept:* The premier monetization tier (highest cost / highest real-world impact). All Patron bonuses are active only while the subscription is active and stop when the player stops paying. A significant portion of proceeds directly funds both managed hives and native bee habitat restoration with conservation partners.
  * *Visual Prestige:* Unlocks an engraved mahogany & brass hive skin with a custom nameplate displaying real-world restoration coordinates, plus a golden "Patron" badge on speed-run leaderboards.
  * *Automation & QoL:* Grants the "Golden Drone" auto-collector (automatically collects wild nectar drops and handles pest events) and extends offline idle earnings up to 24 hours.
  * *Subscription Boosts:* +25% global honey value multiplier (persists across Phase 3 resets while subscribed) and a daily stipend of Royal Jelly premium currency.

---

## AI Architecture

### Token Budgets
Token budget allocation per agent task: $\text{Usage Limit} \div 7$.

### API Constraints
API usage is divided into modular execution pipelines, ensuring individual agent calls remain constrained to their designated token windows to prevent context overlap.

### Actionable Strategy Formalized from Agent Role Definitions
Each specialized agent functions as a dedicated module in the development workflow, executing discrete tasks triggered by developer inputs and producing structured outputs.

### Agent Roles

#### Gerard, the Gameplay Architect
* **Role:** This agent analyzes the proposed feature against the existing gameplay system when the user proposes a new feature, and the player sees a structured representation of how the feature will affect the others.

#### Bob, the Builder
* **Role:** This agent builds levels in the editor when the user proposes a level outline or design, and the player sees the finished level, following the specs of the outline.

#### Patricia, the Programmer
* **Role:** This agent creates modular components and code for the game engine when a list of features is given, and the player sees the completed components and/or script.

#### William, the Writer
* **Role:** This agent writes the story outline when the user gives an idea for a story point, lesson, or goal, and the player sees a completed outline.

#### Andrew, the Audiophile
* **Role:** This agent searches and curates audio sound effects and music tracks when given a description of a sound, environment, vibe, or place, and the player sees the curated structured list and accompanying folder with the selected audio files.

#### Terry, the Progression Tree Expert
* **Role:** This agent analyzes the balance of the progression tree, such as efficiency rating, cost, speed, space requirement, and other metrics available which can be found in the progression file when provided with a suggested upgrade/progression, and the player sees a detailed report/outline comparing the suggestion against existing upgrades/progressions if possible.

#### Martin, the Hiring Manager
* **Role:** This agent creates agent descriptions following the template in the Agent Roles section of `GDD.md` when the lead architect notices there's a skill gap within the team, and the player sees a git diff of the new agent(s) proposed inside the agent roles section.

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
  * *Honeycomb Grid Data:* Represented as a 2D Array or Bitmask in GDScript tracking individual cell status (`0 = Capped`, `1 = Uncapped`, `2 = Extracted`).
  * *Input Raycasting:* `PhysicsDirectSpaceState3D` raycasting maps touch/mouse drag vectors onto the 3D frame collision shape to slice open cells.
  * *Haptic Feedback Interface:* Platform-native wrapper calling OS vibration APIs (`Input.vibrate_handheld()`) on cell state transitions.

---

## Technical Constraints

* **Target Platforms:** Mobile devices (iOS & Android, including tablets) at launch. Nintendo Switch and Desktop (PC/Mac) are post-launch options, each requiring its own business model and input scheme.
* **Art Style Constraints:** Low-poly 3D art style utilizing flat-color palette texture atlases and low vertex counts to ensure optimal performance across low-end mobile hardware.
* **Performance Targets:** Must maintain a stable 60 FPS performance target with hundreds of low-poly bees and floating diorama elements rendered simultaneously on screen.