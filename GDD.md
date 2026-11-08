# Chill Bee Game Design Document
**Working Titles:** Digibees, My Bee Hotel, Pocket Hive, Beehaven

---

## Executive Summary
A cozy, casual beekeeping and farming mobile-first game inspired by and the love child of *Egg, Inc.* and *Factorio* featuring wacky, satisfying progression and upgrades for your beehive. The primary gameplay objective is to make more honey and money. In the game, players can upgrade the beehive, the bees, and the native habitat—three distinct progression trees that feature synergizing effects with each other. The habitat tree measures success in biodiversity rather than honey, teaching the difference between managed honeybees and native wild bees. 

**Design Pillars.** Every balance and feature decision is checked against these:
| Pillar | Inspired by | In this game |
|---|---|---|
| **Optimization pays off** | *Factorio* | Better layouts, denser unit tiers, and smarter upgrade choices visibly produce more honey. A player who optimizes should always see the result. |
| **The thrill of the next unlock** | *Egg, Inc.* | New upgrades, unit tiers, biomes, honeys, and native bee species arrive often, and each one changes what the farm does. Prestige makes the early game fast so players reach new things sooner. |

The UI is simple with no player character or avatar. The game acts as a pocket dimension on your device where players can zoom out and pan across the farm as it expands. The core gameplay loop spans three distinct phases with decreasing manual work:
* **Phase 1 (The Grinding Stage):** High manual labor. Players manually scrape/unframe and refine honeycombs through an uncapping and extraction minigame, plant and water flowers, and manually sell the product. (Players retain access to these manual interaction screens in later phases to manage tool upgrades).
* **Phase 2 (The Automation Era):** Players obtain their first few upgrades to automate harvesting, uncapping, and logistics, significantly reducing manual tasks.
* **Phase 3 (The Optimizing Stage):** The main loop comes into full swing. Players expand their biomes indefinitely on a grid, packing in denser hive and flower units. Building and charging the capstone, the Royal Honey Refinery, produces a Royal Crystal, after which players can choose to reset (Swarm Splitting / Royal Crystal Harvest): the swarm splits and leaves to restore a new pocket world. The reset is optional but encouraged, allowing players to retain persistent bonuses; players who want to compete can opt into bracketed speed-run leaderboards (see Leaderboards).

A core pillar of the project is its **Real-World Impact Integration**, where a portion of proceeds from in-game monetization (Impact Passes, rewarded ads, Adopt-a-hive) funds real-world bee conservation globally (native bee habitat restoration and managed hives), starting with Canadian conservation partners.

---

## Audience & Production Plan
* **Target Audience:** Adults and teens who play cozy games. Content is family-friendly, but the game is not marketed to children; kid mode still protects under-13 players (see Child Safety).
* **Team:** Solo developer directing AI agents in Claude Code (roster in `_meta/team.md`).
* **Art Source:** Purchased low-poly asset packs, adapted and edited by the developer.
* **Build stages and versions:** prototype → vertical slice (the first playable below) → alpha (launch content complete) → beta (content locked) → 1.0 at launch. Builds are numbered `0.<milestone>.<build>` until launch; the build milestones are in `MILESTONES.md`.
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
[5. Reinvest Profits] ◄── [4. Sell Honey by Truck]


* **Phase 1 (Manual Grinding):** Players actively perform uncapping swipes and centrifuge spinning, manage initial flower planting/watering, and handle sales.
* **Phase 2 (Automation):** Begins when the player buys their first automation upgrade (see Tree B: Automation), unlocking the centrifuge motor, the auto-scraper, Faster Delivery and Auto-Sell (the truck leaves to sell by itself when full). Manual screens remain accessible for upgrading tool efficiency and batch multipliers, but are no longer needed: once a unit is automated, its zoom screen opens from upgrade mode instead of from a harvest icon (UI TBD, with the rest of the UI); once harvesting is automated, tool upgrades apply as flat bonuses (see Tree B).
* **Phase 3 (Prestige Reset / Optimization):** Fully charging the capstone Royal Honey Refinery (see Capstone) produces a Royal Crystal, the end-game reward. Players can then trigger an optional (but encouraged) reset. Each Royal Crystal earned:
  * Permanently adds +15% production, additive (10 Crystals = +150%, 20 = 4x, 100 = 16x). The Patron Pass +25% is applied as a separate multiplier, not added to this percentage.
  * Can also be applied to one starting upgrade for future runs, chosen from a whitelist (e.g., bigger starting frames, faster tools, starting land, starting flower or hive units). Crystals shorten Phase 1 but never skip it: automation and the capstone cannot be pre-bought.
  * Extra starting hives follow the normal Hive Balance rule and lower starting Habitat Health. A matching "starting wildflower plot" option raises it, capped at the habitat worth of Habitat Synergy level 3 (a higher start would open Alpine Valley at minute zero and mainly help the rush). The Crystal screen shows a live Habitat Health preview, and both options have a max level (TBD). See `proposals/balance/royal-crystal-balance.md`.

  Royal Crystals carry over between runs. Research trees are purchased with in-game money and do not carry over between runs. Research does three things: bee and flower genetics that multiply production, unlocking higher unit tiers (see Land, Grid & Units), and upgrades for the Royal Honey Refinery (values TBD).

* **Pests & Wild Nectar Drops:** Appear only during active play and pause while offline. Tapping them gives a small reward (cleared pests or collected nectar); ignoring them costs nothing. The Patron Golden Drone taps them automatically.

### 2. Phase 1 Uncapping & Extraction Minigame
When hive storage reaches capacity in Phase 1, players trigger a tactile, three-stage harvesting sequence. Every player has a small free overflow buffer from the start, so production continues past capacity (including while offline) until the buffer is full. The free buffer holds one extra full hive (10 jars at base, growing with Deep Frame). Overflow Storage enlarges the buffer, and the capacity pause ends once no harvest step needs the player: when both the centrifuge motor and the auto-scraper are owned (see Tree B).

The farm holds the hive, a centrifuge with a spigot, a jar crate and a pickup truck (a vintage truck). The whole harvest plays on the farm; for uncapping, the camera zooms in on the hive and the centrifuge.

The hive is a body holding five frames (2 jars each at base) under a lid. The centrifuge is a glass bucket with a spigot, and a steel lid that carries the crank.

* **Start:** When the hive is full, a fork icon floats above it. Tapping it starts the harvest.
* **Stage 1: Uncapping (Tactile Swiping)**
  * Tapping the fork icon zooms the camera in on the hive and the centrifuge. This first zoom always keeps both in focus, at every upgrade level; the crate and the truck are not in it. When the bucket is full, the camera pans to the centrifuge, the crate and the truck, with the hive partly visible in the upper-right corner. The hive's lid drops to the ground beside it and the first full frame slides up out of the body, standing upright. Frames never leave the hive; they only slide up and down.
  * Every player starts with the basic uncapping fork: dragging across the matte yellow capped wax cells scrapes them off, revealing glowing golden honey underneath. Each scraped cell pops, then flies into the centrifuge's bucket. When the bucket is full, its lid with the crank drops on, and further cells pile up next to the centrifuge; the piles load into the bucket by themselves when it is next empty.
  * When a frame is fully uncapped it slides back down and the next full frame slides up, until no full frame is left; then the hive's lid goes back on and the camera zooms out. The player can leave at any time with Back: the hive closes, half-scraped frames keep their state, and the fork icon stays while any full frame remains.
  * Supported by particle pop effects, popping audio cues, and native mobile haptic feedback.
  * With the Long Fork (Tree B), tapping the fork icon hands the player the Long Fork, which uncaps the entire frame in one sweep.
* **Stage 2: Centrifuge Extraction (Speed Taps or Hold)**
  * The bucket holds several frames' worth of cells (capacity TBD). Its lid goes on when the bucket is full, or when the player leaves the zoom with cells in it. An icon then floats above it; tapping it continues the harvest.
  * The centrifuge has a physical crank on its cylinder. The player taps or holds the crank, or anywhere on screen around it (but not on buttons such as Back), to spin it, spraying honey streams against its glass walls: as it spins, the combs inside melt into honey. Holding ramps the spin up to the fastest tap rate, so holding is never slower than tapping. There is no on-screen crank button.
  * When extraction is done, bottling starts by itself.
* **Stage 3: Bottling & Selling**
  * Empty glass jars wait in the jar crate. One at a time, a jar flies under the spigot and fills, while the honey level in the glass bucket drops until it is empty. Each full jar gets its lid and is loaded onto the truck, or back into the crate while the truck is away.
  * When the truck is full (capacity TBD), a Sell ($X) icon floats above it, showing what the load will earn. Tapping it sells the load: the truck speeds off and comes back (trip time TBD), and a summary shows the jars sold, the price per jar and the total, plus tool precision and artisanal quality bonuses once those exist. Jars bottled while it is away wait in the crate and load when it returns.

### 3. Progression Trees & Economy Balance
Progression is split across three synergizing upgrade paths using an exponential cost model ($\text{Cost} = \text{Base} \times \text{Growth}^{\text{Level}}$):

* **Tree A: Bee Upgrades (Swarm Size & Flight Endurance)**
  * *Worker Swarm Count:* Adds active foraging bees (+15% fill rate per level, base cost $25, 1.18x growth factor, max level 10).
  * *Flight Endurance:* Increases bee movement speed between flowers and hive (+10% speed per level, base cost $15, 1.15x growth).
* **Tree B: Hive & Tool Efficiency**
  * *Heated Uncapping Fork:* Increases swipe radius by +12% per level and adds up to +5% batch bonus for clean cuts (base cost $40, 1.22x growth, max level 5).
  * *Centrifuge Gearing:* Reduces required extraction taps or hold time by -15% per level (base cost $35, 1.20x growth, max level 5).
  * *Long Fork:* Makes uncapping quicker: uncap the entire frame in one sweep (tap the fork icon to take it). The final fork upgrade, a step past the Heated Uncapping Fork; it leads into the auto-scraper (unlock condition and cost TBD).
  * *Deep Frame:* Increases frame capacity from 2 jars to 5 jars per frame (10 to 25 jars per full hive). Deep frames are twice as long as standard frames, so they fill more of the screen while uncapping (base cost $150, 1.45x growth, max level 3).
  * *Tool Upgrades After Automation:* Once harvesting is automated, the Heated Uncapping Fork applies as a flat +% yield bonus and Centrifuge Gearing as a flat −% extraction time (values TBD), so these upgrades keep their value.
  * *Overflow Storage (optional):* Enlarges the free overflow buffer, so returning players have extra frames waiting to harvest (capacity and costs TBD).
  * *Auto-Sell:* The sales truck leaves by itself when full and sells at the full price (costs TBD).
  * *Automation:* Separate purchases with in-game money: the **motor** (the electric centrifuge spins by itself), the **auto-scraper** (the Long Fork mounted on a moving gantry, which uncaps frames by itself; unlocked after the Long Fork) and **Faster Delivery** (shorter truck trips). The first automation purchase moves the player into Phase 2; the capacity pause ends once the motor and the auto-scraper are both owned (costs TBD).
  * *Artisanal Branding:* Increases base sale value per jar by +$2.50 (base cost $60, 1.25x growth, max level 10).
* **Tree C: Native Habitat**
  Its own progression track, measured in biodiversity (Habitat Health and native bee species attracted) rather than honey. Upgrades are bought with in-game money (values TBD).
  * *Flower Patches:* Plant and upgrade patches of real Canadian native wildflowers to raise the biome's Habitat Health. Initial list (to be fact-checked):

    | Biome | Native wildflowers |
    |---|---|
    | Sunny Meadow | Goldenrod, wild bergamot, New England aster, black-eyed Susan |
    | Alpine Valley | Fireweed and other alpine wildflowers (TBD) |
    | Enchanted Grove, Cloud Gardens | Fictional flowers, labelled as fictional in the Bee Journal: Glowbell (Enchanted Grove, night-blooming) and Skybloom (Cloud Gardens, rainbow blossoms) |
  * *Native Bees:* Habitat Health attracts native wild bees to the farm, separate from the managed honeybees. Native bees:
    * Pollinate flowers, raising Habitat Synergy (no growth timers).
    * Grant a native-bee bonus to production in Trees A and B (the habitat/bee synergy). The bonus is per biome: in each biome, species effects plus a small bonus for the number of native bees form one capped bonus that applies only in that biome. Each biome has a total ceiling and a smaller ceiling for each kind of boost (pollination speed, fill rate, sale value); Sunny Meadow's fill-rate ceiling is 0 and its sale-value ceiling is +15%. The abundance bonus (up to +5%) raises sale value only.
  * *Hive Balance:* Managed honeybees compete with native bees for the same flowers. Placing hives on the grid without enough flowers lowers Habitat Health, so players balance hive count against planting.
  * *Habitat Synergy Level:* Each biome has a graded Habitat Synergy level, based on whether it has enough flowers for its bees to pollinate and make honey from. Synergy is money-driven: it rises as soon as flowers are placed, with no growth timers. Reaching a biome's unlock threshold opens the next biome, and the Refinery needs its host biome to stay above a minimum level (values in `proposals/balance/refinery-parameters.md`).
  * *Native Bee Species:* Each species arrives when its biome's Habitat Health and flower needs are met, leaves if habitat drops, and returns when it recovers. Its effect applies only in its own biome. Full design: `proposals/design/native-species.md`; provisional values in `proposals/balance/native-species-balance.md` (Terry).

    | Biome | Species | Effect | Attracted by |
    |---|---|---|---|
    | Sunny Meadow | Sweat bees | Faster pollination (+25%) | Black-eyed Susan, goldenrod |
    | Sunny Meadow | Leafcutter bees | Better honey quality (+10% sale value) | Wild bergamot, New England aster |
    | Sunny Meadow | Bumble bees (visitor) | None; Bee Journal entry only | Meadow flowers |
    | Alpine Valley | Bumble bees | Faster hive fill rate (+20%) | Fireweed, alpine wildflowers (TBD) |
    | Alpine Valley | Mason bees | Faster pollination (+25%) | Fireweed, alpine wildflowers (TBD) |
    | Alpine Valley | Mining bees | Better honey quality (+10% sale value) | Fireweed, alpine wildflowers (TBD) |
    | Enchanted Grove | Lantern bee, Glowcap digger (fictional) | Lantern bee: faster fill rate (+20%); Glowcap digger: faster pollination (value TBD, Terry) | TBD |
    | Cloud Gardens | Drift bee, Stardust bee (fictional) | Drift bee: faster pollination (+25%); Stardust bee: +10% sale value and +10% Refinery yield | TBD |

    * Real-species assignments must be fact-checked by William and a conservation partner.
    * Sunny Meadow has no fill-rate species, so the Meadow rush can't become clearly better.
    * Quality effects raise market sale value only, not Refinery charge, except the Stardust bee in Cloud Gardens. Its +10% Refinery yield is already included in Cloud Gardens' planned affinity, so Cloud reaches its full rate only with Stardust bees.
  * *Bee Journal:* Each native species attracted is recorded in the Bee Journal with short facts. The Journal is a permanent collection and gives no production bonus.
    * *Real species* (Sunny Meadow, Alpine Valley): real-world facts only. William drafts them (English and French) with cited sources, and a conservation partner reviews them before launch.
    * *Fictional species* (Enchanted Grove, Cloud Gardens): invented, whimsical facts that sound plausible in the magical pocket world. They need no sources, are labelled as fictional, must match the species' effects in this table, and make no claims about real bees.
  * *On Reset:* The Bee Journal is permanent; Habitat levels reset with the farm each run.
* **Capstone: Royal Honey Refinery** (full proposal: `proposals/design/capstone-machine.md`)
  * **Build:** A very expensive machine bought with in-game money and placed on the grid in one biome (its host biome).
  * **Charge:** A single slider sends a share of every biome's honey into the Refinery, which refines it into Royal Honey. Each jar adds its sale value × its biome's affinity rate, and later biomes have higher affinity, so the stacked production of all biomes charges it fastest.
  * **Habitat lock:** The Refinery only refines while its host biome stays above a minimum Habitat Synergy level. Below it, refining pauses but nothing drains.
  * **Royal Crystal:** When the charge meter is full, a Royal Crystal forms and the run is complete. The player can then choose to reset.
  * **Speedrun route:** A player can stay in Sunny Meadow, rush the top unit tiers, keep just enough flowers for the habitat minimum, and send everything into the Refinery. This route is intentionally left open. It is clearly slower than the normal route for new and low-Crystal players, and about equal (within ~5%) for veteran players with many Crystals, so they can choose either route. A maximum Refinery charging speed keeps it from ever being clearly better.
  * **Target run length:** A new player's first run, from start to the first Royal Crystal, takes about 66 hours at launch and about 43 hours once biomes 3–4 ship (post-launch charge target lowered from 83 to 78 so all routes stay within the 5% goal). The designer accepted the shorter launch run that native-bee bonuses cause, rather than raising costs to hold 72 hours. The shorter post-launch run is the price of keeping the rush equal for veterans.
  * **Charge phase:** How much of a run is spent charging the Refinery is TBD. Terry's model, before native bees, had about 45 of 72 hours at launch. Stacking production across biomes should speed up charging, and research can buy Refinery upgrades (see the charging-speed cap).
  * **Charging-speed cap:** Tolerant. For veterans, the rush and the normal route only need to stay within about 5% of each other in either direction; strict "never faster" equality is not required, because the routes rank on separate leaderboard categories (see Leaderboards). The cap starts low and Refinery research raises it in steps (launch: 7 → 10 → 13 → 16 → 20 × J_ref jars/h; post-launch: 10 → 13 → 16 → 17.5). Players who buy the research lose under 2% to the cap; veterans who skip it are 29–49% slower, so optimizing the Refinery pays off. Research costs are placeholders (0.5 / 1 / 1.5 / 2 base-hours, cheaper with more Crystals). The ladder was sized for +12% Crystals and must be re-checked for +15% (`proposals/balance/progression-levers.md`).
  * **Provisional values:** Terry's proposed parameters are in `proposals/balance/refinery-parameters.md`. They come from a stand-in model and must be re-derived once the real economy and the per-biome setup time are measured.
  * **Content versions:** The charge target is stored per content version, so adding biomes 3–4 never changes stored run times. Each run also records the highest biome that contributed honey.
  * Parameters are set by Terry (build cost, charge target, biome affinities, Habitat Synergy minimum, maximum share sent to the Refinery, footprint).

### 4. Land, Grid & Units
* **Indefinite Expansion:** Each biome can be expanded indefinitely by buying more land with in-game money (cost growth TBD).
* **Grid Placement:** Players place each hive and flower unit on the biome's grid themselves. Space is limited, so the goal is the most honey production per tile.
* **Hive & Flower Units:** Hives and flower patches are bought and placed as units. Each unit type has tiers (e.g., Langstroth hive → stacked hive → hive tower; wild patch → raised bed → vertical garden). Higher tiers cost much more in-game money but produce more in less space. Units can be upgraded in place.
* **Jar Crate Tiers:** The jar crate has three tiers, each larger on the grid: tier 1 (a half crate, 1 cell), tier 2 (2 cells), tier 3 (3 cells in a row). Each tier holds more jars waiting and makes a bigger truck load (values TBD).
* **Biome Units:** Each biome adds new top-tier units in its own style (e.g., chalet hives in Alpine Valley, lantern hives in Enchanted Grove).
* **Unlocking Tiers:** Higher unit tiers are unlocked through research (see Phase 3).

### 5. Leaderboards
Leaderboards are opt-in: the game is cozy by default, and only players who choose to compete enter ranked runs. Online leaderboards are post-launch; at launch, players see local personal-best run times. Speed-run leaderboards are bracketed so players only compete against others who used the same boosters within a given run:
* **Player Names:** Players build their display name from preset word lists (no free text). Kid-mode players have no public username.
* **Run-Based Brackets:** Each run is tagged with every paid booster active during that run (e.g., Impact Pass, Patron Pass). A run with no purchases ranks on the unboosted board; boosted runs rank only against runs with the same booster set.
* **Royal Crystal Tiers:** Runs are also bracketed by the player's Royal Crystal count (e.g., 0, 1–5, 6–20, 21–50, 51–100, 101+; the high tiers are split because production spans about 10x above 21 Crystals; exact tiers TBD, with the high split moved near ~92 Crystals, where the rush comes within 5% of the normal route at +15% per Crystal), so players race others at a similar prestige level.
* **Route Categories:** Like speedrun "any%" and "100%" categories, runs are split by the highest biome that contributed honey to the Refinery (e.g., Meadow-only vs full route), so the rush and the normal route never compete directly.
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
* **Hold Instead of Tapping:** Holding the centrifuge crank (or the screen around it) ramps it up to the fastest tap rate, so no harvest step needs rapid tapping. It is built in for every player, so there is no separate toggle.
* **Haptics & Sound Toggles:** Vibration, sound effects, and music can each be turned on or off.
* **Colour-Blind Support:** Information never relies on colour alone (e.g., capped and uncapped cells also differ in shape or texture).
* **Text Size & One-Handed Play:** Adjustable text size, and all UI reachable with one thumb.

### 9. UI & Screens
* **Farm View (Main Screen):** The pannable, zoomable pocket-dimension farm, including a build mode for buying land and placing hive and flower units on the grid.
* **Upgrade Shop:** Trees A–C, automation, research, and the capstone.
* **Worlds:** Load and switch between saved pocket worlds.
* **Harvest Minigame:** The uncapping zoom on the hive and the centrifuge. Extraction, bottling and the sales truck play on the Farm View.
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
* Produces its own honey, each more sought after (higher sale value) than the last (values TBD). Alpine Valley honey must sell for less than 1.92× Sunny Meadow honey, or it would charge the Refinery less per jar than Meadow honey (the Alpine affinity was lowered from 2.0 to 1.92 to account for Alpine bumble bees; see `proposals/balance/native-species-balance.md`).
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
The agent roster (roles, models and the rules every agent follows) is in `_meta/team.md`. Token costs and the daily budget are in `_meta/agent-runs.md`.

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

Terms used in this document and in the design and balance reports (`proposals/design/`, `proposals/balance/`).

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
| Equal for veterans | Loose design goal: for players with many Crystals, the rush gap stays within about 0.95–1.05 (within 5% either way). The routes rank on separate leaderboard categories, so exact equality isn't required. | 1.03 at 100 Crystals. |
| Crossover | The Crystal count at which the rush would become faster than the normal route. Balance keeps the rush from becoming more than about 5% faster. | — |
| M | A player's total production multiplier. | +15% per Crystal: M = 1 + 0.15 × Crystals. |
| M(n) | M at n Crystals. | M(60) = 10.0. |
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
| Royal Crystal | Prestige reward from the Refinery: +15% production (additive), plus one whitelisted starting upgrade. Account-wide. |
| Starting upgrade | A head start for future runs bought with a Crystal, such as starting land, faster tools, extra starting hives or a starting wildflower plot. |
| Free overflow buffer | Extra storage of one full hive, so production continues while the hive is full. |
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
