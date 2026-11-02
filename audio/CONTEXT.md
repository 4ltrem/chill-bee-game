# audio - curated sound effects and music (Andrew)

One job: turn a description of a sound, environment, vibe or place into a licence-checked shortlist and the selected files.

## Inputs
- Working (this run): the designer's description (sound, screen, biome or interaction)
- Reference (every run): `../GDD.md` (Aesthetic & Tone, Accessibility, plus the biome or screen named)
- Reference (every run): `../_templates/audio-list.md`

Do NOT load: the review folders, `_meta/agent-runs.md`, proposals.

## Process
1. Search free-licence libraries (CC0 first, then CC-BY); confirm each licence on its source page.
2. Copy `../_templates/audio-list.md` to `<slug>.md` here; list 3–5 candidates per sound and mark the picks.
3. Download only the picks into `<slug>/`; never a file whose licence is unconfirmed.
4. Flag non-commercial, attribution-required or unclear licences for Connie.

## Outputs
- `<slug>.md` and `<slug>/` -> this folder, `status: draft`

## Check
The designer listens to the picks and sets `status: approved` or `rejected`. Approved files are copied into `game/assets/audio/` by the developer, and attribution lines go into the credits.
