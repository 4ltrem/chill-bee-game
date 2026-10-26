# balance - progression and economy reports (Terry)

One job: model the numbers a design question needs and propose provisional values with their assumptions stated.

## Inputs
- Working (this run): the designer's question, and the design proposal it answers (in `../design/`)
- Reference (every run): `../../GDD.md` (only the sections the question touches)
- Reference (every run): `../../_templates/proposal.md`
- Reference (when reused): `refinery-parameters.md` (§2, the stand-in run model)

Do NOT load: the review folders, `_meta/agent-runs.md`, superseded reports.

## Process
1. If an input number is missing from the GDD and the design proposal, stop and list it rather than inventing it.
2. Copy `../../_templates/proposal.md` to `<topic>-balance.md` here (or revise in place and mark the earlier revision superseded).
3. State every assumption, show the model, give provisional values, and say what must be re-derived once the reference sims exist.
4. Rebuild the index: `python -I _tools/index.py proposals/balance`.

## Outputs
- `<topic>-balance.md` -> this folder, `status: proposed`

## Check
The designer reads the report and records a decision. Only then are accepted values edited into `GDD.md` and the status set to `applied` or `rejected`.
