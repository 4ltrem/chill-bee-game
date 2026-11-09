# Guide playtest: briefs for Patricia and Gerard (draft, not sent)

Drafted 2026-11-07 from the designer's follow-up in `content/guides.md` (Decisions 2). **Don't send these yet.** D46 puts the playtest after the first prototype, and onboarding is deferred (MILESTONES.md: "Onboarding stays deferred"). Send them when onboarding work starts. Gerard goes first, because his proposal sets what Patricia's switch must record.

Open for the designer before sending:
- **Who plays.** Friends and family, course classmates, or itch players. This decides whether the playtest is moderated (Gerard's brief) or remote with logged answers.
- **One guide per player, or all six.** Gerard is asked to recommend one, but it's the designer's call.
- **Kid mode.** If any playtesters are children, Connie checks the playtest plan first (consent, any data recorded).

---

## Brief 1: Gerard (gameplay architect), playtest design

**Goal:** a proposal in `proposals/design/` for a playtest that picks one of the six candidate guides.

**Read only:** `content/guides.md` (the six guides and their 30 signature lines per language), GDD §7 "Story Premise & Onboarding" (line 184 on), and D46 in `_meta/sessions/2026-10-31-fa5df4be/decisions.md`.

**Decide and justify:**
1. **Design:** each player meets one guide (between-subjects) or several (within-subjects, order rotated). Give the number of players each option needs to tell six guides apart, and recommend one.
2. **What gets measured:** for example, finishing the first session, time to the first sale, a liking score, recall of the guide's name, and a free-text "who would you keep". Name what the build must record, for Patricia.
3. **French:** whether FR players get a separate pass, since Miel, Reine Maëve and Dame Aura read differently in French.
4. **Cutting down:** a rule to drop guides early (for example, after a first round, keep the top three), so the full playtest needs fewer players.

**Out of scope:** writing lines (William), changing the guides, the GDD. List any parameters Terry must set.

**Stop at:** the proposal, for the designer's decision.

---

## Brief 2: Patricia (programmer), guide switch in the build

**Goal:** one build that can show any of the six guides, so playtesters meet the guide the playtest assigns them.

**Read only:** `content/guides.md` (names in EN and FR, and the signature-lines tables), GDD §7, Gerard's accepted playtest proposal (what to record), and `game/scripts/game_config.gd` and `dev_panel.gd` (how tunables and Dev mode work).

**Build:**
1. **Guide data:** the six guides (id, EN/FR name, five signature lines per language), read from one data file made from `content/guides.md`. No text typed into scripts.
2. **The switch:** a `guide_id` setting in config, shown in the Dev panel ("every spec gets an in-game Dev mode"). It can also be set from the build URL or the first-launch screen, whichever Gerard's design needs.
3. **The `[GUIDE]` placeholder:** the shared onboarding script swaps in the chosen guide's name, and each of the five moments (welcome, first harvest, first sale, first upgrade, hand-off) shows that guide's signature line.
4. **Recording:** only what Gerard's proposal lists, written locally, with nothing sent anywhere unless the designer and Connie have approved it.

**Depends on:** the onboarding script being built (it is deferred) and an approved `content/onboarding-script.md` (it waits on a re-check against `guides.md`).

**Stop at:** Quinn's report. Quinn tests that each `guide_id` shows its own name and five lines in EN and FR.
