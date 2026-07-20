# Story: Run Start Trait Rolling

## Context
`GameManager._on_level_ready()` currently applies a fixed, hardcoded list of trait ids to every run (see `docs/stories/level-cleanup-game-manager.md`). This was always a placeholder — `docs/stories/game-data-trait-application.md` and `CLAUDE.md`'s Run Start Flow item both call out that traits (and eventually equipment) should be randomly rolled at run start instead: *n* positive, *m* negative.

This story builds that roll, applies it exactly like today's hardcoded list already does, and adds a brief pre-run reveal so the player sees what they got before the run becomes controllable. It does **not** build equipment rolling or a full main menu — see Scope.

Counts, confirmed with Ray: `n = 3` positive traits, `m = 2` negative traits. A third count, `x = 3` items, is recorded now for the future equipment pass (see Scope) but nothing rolls or displays items yet — there is no equipment content or inventory system in the project today (no `items.json`-equivalent, no use/throw mechanics; the GDD lists exactly two illustrative examples, not an authored pool).

Ray's direction: build the rolling mechanism as a generic, reusable base rather than trait-specific one-off code, so that when equipment content exists, item rolling is a small addition rather than a redesign.

## Goal
At the start of every run (including restarts), the player is dealt a fresh random trait loadout — 3 positive, 2 negative, drawn from the pool of traits `GameData` currently has fully loaded — applied via the existing `GameData.apply_traits()` path, and shown a brief reveal screen before they can act. The rolling mechanism itself (pick N distinct ids from a pool) is a generic utility with no trait-specific knowledge, so it can be pointed at an item pool later without changes.

## Scope

**In scope:**
- `PoolRoller` (`scripts/util/pool_roller.gd`, `RefCounted`) — one method, random-sample-without-replacement over a list of ids. No knowledge of traits, items, or effects; just "pick N distinct ids from this list."
- `RunLoadout` (`scripts/util/run_loadout.gd`, `RefCounted`) — holds what got rolled for the current run. For this story: `positive_trait_ids: Array[String]`, `negative_trait_ids: Array[String]`. Held as `RunState.loadout`, following the exact pattern `Player.fov`/`Player.traits` already establish for `RefCounted` utilities hung off a Node. Reset alongside the rest of `RunState.reset()`.
- `GameData.get_ids_by_type(type: String) -> Array[String]` — returns the ids of every successfully-loaded, validated trait definition matching `type` (`"positive"`/`"negative"`). Traits that fail `GameData._validate()` today (as of writing: `treasure_hound`, `eavesdropper`, `narcolepsy`, `allergies` — each blocked on work called out in `docs/stories/game-data-trait-application.md`) never enter `_definitions`, so they're automatically excluded from the rollable pool. This exclusion is dynamic, not a second hardcoded list — it stays correct as more trait stories land and validation starts accepting them.
- Roll counts as named constants on `Constants` (not buried in `GameManager` logic): `STARTING_POSITIVE_TRAIT_COUNT = 3`, `STARTING_NEGATIVE_TRAIT_COUNT = 2`, and `STARTING_ITEM_COUNT = 3` (reserved for the future equipment story — unused by any code in this story, just recorded so the number isn't re-litigated later).
- `GameManager._on_level_ready()` rolls the loadout via `PoolRoller` + `GameData.get_ids_by_type()`, stores it on `RunState.loadout`, applies it via the existing `GameData.apply_traits()` call (same call as today, just fed rolled ids instead of the hardcoded array), then shows the new reveal modal.
- New `RunStartModal` (`scenes/ui/run_start_modal.tscn` / `scripts/ui/run_start_modal.gd`, `CanvasLayer`) — follows the `EndScreen`/`TraitsModal` precedent exactly (backdrop + centered panel; see `scenes/ui/end_screen.tscn` for the scene structure to copy). Shown automatically once the roll is applied. Lists the rolled positive traits and negative traits by name (via `GameData.get_definition(id)`, same lookup `TraitsModal` already uses), grouped so good/bad is visually distinct. Sets `UiState.modal_open = true` on show — this already blocks `Player._unhandled_input()`, so no new turn-freeze logic is needed. Closes on a confirm input, setting `UiState.modal_open = false`.
- A new `confirm` input action (suggest binding Enter/Space — implementer's call) to dismiss `RunStartModal`. Don't overload `wait` — keep run-start confirmation distinct from the gameplay wait action.
- Restarting (`R`) re-rolls a fresh loadout and re-shows the modal, since `_on_level_ready()` runs again on scene reload — no special-case restart logic needed beyond what already exists in `GameManager._restart_run()`.
- Update `docs/architecture.md` and `CLAUDE.md`'s Run Start Flow section to reflect that trait rolling + reveal now exist, and that a full main menu (title/continue/settings) is still the only remaining piece of that roadmap item.

**Out of scope (deferred):**
- Rolling, displaying, or applying items. `STARTING_ITEM_COUNT` is recorded but unused — there's no equipment content or inventory/use/throw system to roll from yet. When that content exists, item rolling should reuse `PoolRoller` and extend `RunLoadout` with `item_ids`, not introduce a parallel system.
- A full main menu (title screen, continue, settings). `RunStartModal` is the "run start sequence" half of `CLAUDE.md`'s Run Start Flow item, not the "main menu" half — the game still boots directly into a run, it just pauses on the reveal before the player can act.
- Any change to how traits are applied once rolled (`GameData.apply_traits()`, `PlayerTraitState`, per-trait dispatch) — all untouched, this story only changes what list of ids gets fed in.
- Re-rolling or choosing traits interactively (e.g. a "reroll" button) — the roll is final once shown; only a fresh restart produces a new one.

## Acceptance Criteria
1. `PoolRoller.roll(ids: Array[String], count: int) -> Array[String]` exists, returns `count` distinct ids sampled from `ids` with no domain-specific logic, and clamps gracefully if `count > ids.size()`.
2. `RunLoadout` exists as a `RefCounted` utility, held as `RunState.loadout`, exposing `positive_trait_ids`/`negative_trait_ids`, and is reset whenever `RunState.reset()` runs.
3. `GameData.get_ids_by_type(type: String) -> Array[String]` exists and returns only ids present in `_definitions` (i.e. traits that already pass validation) matching the given type.
4. `Constants.STARTING_POSITIVE_TRAIT_COUNT`, `Constants.STARTING_NEGATIVE_TRAIT_COUNT`, and `Constants.STARTING_ITEM_COUNT` exist with values `3`, `2`, `3`.
5. `GameManager._on_level_ready()` no longer contains a hardcoded trait id list. It rolls 3 positive + 2 negative ids, stores them on `RunState.loadout`, and applies them via `GameData.apply_traits()`.
6. `RunStartModal` appears automatically at the start of every run (including after restart), lists the rolled traits' names grouped by positive/negative, blocks player input while open (`UiState.modal_open`), and dismisses on the `confirm` input, after which the run is playable exactly as it is today.
7. Restarting produces a newly rolled set of ids (verify across a few restarts that the list isn't static) and re-shows the modal.
8. `docs/architecture.md` and `CLAUDE.md` reflect the new autoload/utility surface and updated Run Start Flow status.

## Technical Notes

**Why `PoolRoller` is separate from anything trait-specific.** The whole point of this story, per Ray's direction, is that when equipment rolling gets built later, it's `PoolRoller.roll(GameData.get_item_ids_by_type(...), Constants.STARTING_ITEM_COUNT)` — the same function, a different pool. If roll logic gets written inline in `GameManager` or baked into `GameData`, that reuse doesn't happen for free. Keep `PoolRoller` ignorant of what an "id" even represents.

**Suggested `PoolRoller`:**
```gdscript
class_name PoolRoller
extends RefCounted

func roll(ids: Array[String], count: int) -> Array[String]:
    var pool: Array[String] = ids.duplicate()
    pool.shuffle()
    return pool.slice(0, mini(count, pool.size()))
```

**Suggested `RunLoadout`:**
```gdscript
class_name RunLoadout
extends RefCounted

var positive_trait_ids: Array[String] = []
var negative_trait_ids: Array[String] = []

func reset() -> void:
    positive_trait_ids = []
    negative_trait_ids = []

func all_trait_ids() -> Array[String]:
    var ids: Array[String] = []
    ids.append_array(positive_trait_ids)
    ids.append_array(negative_trait_ids)
    return ids
```
Held as `RunState.loadout: RunLoadout = RunLoadout.new()`; `RunState.reset()` calls `loadout.reset()` alongside its existing field resets.

**`GameData.get_ids_by_type()`:**
```gdscript
func get_ids_by_type(type: String) -> Array[String]:
    var ids: Array[String] = []
    for id: String in _definitions:
        if _definitions[id].get("type", "") == type:
            ids.append(id)
    return ids
```

**Suggested `GameManager._on_level_ready()`:**
```gdscript
func _on_level_ready() -> void:
    var loadout: RunLoadout = RunState.loadout
    loadout.positive_trait_ids = PoolRoller.new().roll(
        GameData.get_ids_by_type("positive"), Constants.STARTING_POSITIVE_TRAIT_COUNT
    )
    loadout.negative_trait_ids = PoolRoller.new().roll(
        GameData.get_ids_by_type("negative"), Constants.STARTING_NEGATIVE_TRAIT_COUNT
    )
    GameData.apply_traits(loadout.all_trait_ids(), GridManager.get_player())
    _run_start_modal.open(loadout)
```
`GameManager` needs a reference to the `RunStartModal` instance — simplest is adding it as a child scene of whatever node `GameManager` lives under, or instancing it in code the same way `VfxManager` instances its effect nodes. Exact wiring is an implementation call; the requirement is that the modal opens after traits are applied and blocks input until confirmed.

**`RunStartModal` scene structure** — copy `scenes/ui/end_screen.tscn`'s layout (`CanvasLayer` → `Backdrop` `ColorRect` → `CenterContainer` → `PanelContainer` → `MarginContainer` → `VBoxContainer`), swapping the label content for two grouped lists (positive/negative trait names via `GameData.get_definition(id).get("name", id)`) and a "press [confirm] to start" hint, mirroring `EndScreen`'s "Press R to Restart" hint label.

**Ordering note.** `_on_level_ready()` already fires after the player is registered (see `docs/stories/level-cleanup-game-manager.md`'s Technical Notes on why `GameEvents.level_ready` exists at all) — that guarantee still holds here, no new timing concerns introduced.

## Open Questions
- Exact keybinding for `confirm` — Enter and/or Space are the obvious choices; not locked here.
- Whether `RunStartModal`'s trait descriptions (not just names) should show on the reveal screen, or just names with detail deferred to the in-run `TraitsModal` (`C` key) — left as an implementation/UX call; either is consistent with this story's acceptance criteria.
- Whether `GameData.get_ids_by_type()` should also expose a count (e.g. for a settings/debug display of pool size) — not needed by this story, flagging in case it's convenient to add now.
