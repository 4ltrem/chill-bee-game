# design - feature proposals (Gerard)

One job: turn a design question into a concrete feature proposal with every tunable listed for Terry.

## Inputs
- Working (this run): the designer's question, plus any peer or TA feedback it quotes
- Reference (every run): `../../GDD.md` (only the sections the question touches)
- Reference (every run): `../../_templates/proposal.md`
- Reference (when cited): `../balance/_index.md`, then only the balance reports it names

Do NOT load: the review folders, `_meta/agent-runs.md`, other proposals the question does not touch.

## Process
1. If the question is unclear or contradicts the GDD, stop and say where.
2. Copy `../../_templates/proposal.md` to `<feature-slug>.md` here; fill Sources with the exact GDD sections read.
3. Give options with trade-offs, recommend one, and end with a numbered parameter list for Terry. No final numbers.
4. Rebuild the index: `python -I _tools/index.py proposals/design`.

## Outputs
- `<feature-slug>.md` -> this folder, `status: proposed`

## Check
The designer reads the proposal and records a decision. Only then are accepted parts edited into `GDD.md` and the status set to `applied` or `rejected`.
