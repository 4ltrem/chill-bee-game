# proposals - agent proposals awaiting or past a design decision

One job: hold every proposal an agent writes, one file per question, shelved by role.

| Shelf | Agent | Holds |
|---|---|---|
| [design/](design/CONTEXT.md) | Gerard, the Gameplay Architect | feature concepts and rules |
| [balance/](balance/CONTEXT.md) | Terry, the Progression Tree Expert | progression maths and provisional values |
| `compliance/` | Connie, the Compliance Officer | findings and checklists (created on Connie's first run; her definition writes here) |

Every proposal starts as a copy of `../_templates/proposal.md` and carries `author`, `type`, `status` and `description` in its frontmatter. Lifecycle: `proposed` → `applied` or `rejected`; a later revision marks the earlier one `superseded`.

Paths inside proposals are written from the repository root (`GDD.md`, `proposals/balance/...`), matching how the GDD cites them.
