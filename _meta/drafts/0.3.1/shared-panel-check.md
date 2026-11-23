---
status: accepted 2026-11-23 (designer: build as part of C7; the victory waits for any open panel); goes into the 0.3.1 spec's item 7 before C7 is built
description: one "is a panel open?" check and one panel base, so C7's Settings sheet is the last panel wired by hand
---
# Shared panel check, before C7

**Trigger:** the 0.3.1 goal run analysis (2026-11-23). Remaining goals mostly repeat systems the game already has, and the agents rediscover them each step.

## The problem

"Is something covering the farm view?" is answered in four places, each with its own list:

| Where | Checks |
|---|---|
| `main.gd` `farm_view_idle()` | zoom, second stop, welcome, Shop sheet |
| `farm_ui.gd` `_toasts_blocked()` | `farm_view_idle()` + `JournalPanel` |
| `hint.gd` `_covered()` / `_shop_open()` | `set_blocked` sources, `JournalPanel`, `VictoryOverlay`, Shop sheet |
| `shop_ui.gd` `_set_hint_blocked()` | pushes the Tools sheet into the hint |

The lists already disagree: the victory doesn't wait for the Journal, but toasts do. C7's `SettingsPanel` would be the fifth panel added by hand to all four lists. Each of Journal, Shop, Welcome and Victory also has its own open/close/z-order code.

## Proposal (built by Patricia as part of C7)

1. **A `modal_panel.gd` base (`class_name ModalPanel`).** It provides `open()`, `close()`, `is_open()`, the z-order and `top_level` handling, an optional dim that closes it, a `<Name>CloseButton` lookup and translation refresh. It joins the group `modal_panels`. `SettingsPanel` is built on it. Journal moves onto it in the same step (it's the smallest, 80 lines). Shop, Welcome and Victory move later, when a spec item touches them.
2. **One check, `main.gd` `any_panel_open() -> bool`.** It returns true if any node in `modal_panels` is open. `farm_view_idle()`, `_toasts_blocked()` and the hint's `_covered()` call it instead of their own lists. The hint's `set_blocked()` stays for non-panel blockers.
3. **One test helper, `_check_panel(m, button_name, panel_name)`.** It opens the panel from its button, checks it blocks toasts and the hint, closes it with Close, and opens it again. Each panel's test is one call.

## Behaviour change to decide

With one shared list, **the victory would also wait for the Journal and Settings panels**. Today it waits only for the Shop sheet and the zooms. This is probably what you'd want, but it changes the game's behaviour, so it's your call.

## Decisions needed from the designer

1. Build 1–3 as part of C7 (recommended), as a separate item after C7, or not at all?
2. Should the victory wait for any open panel, as toasts already do?
