# Story: Session End Definitions (Win/Loss Loop)

## Context
Every core system that makes a run interesting — guard AI, vision, doors, alert escalation — exists, but there is currently no way to end a run. There is no capture logic, no MacGuffin, no exit, no game-over/victory state. Verified against the codebase (2026-07-02): no references to capture, win, lose, game-over, or restart exist anywhere in `project/`. This story closes the loop so the game is playable end-to-end for the first time.

Per Ray's direction, the MacGuffin is scoped minimally here: a single hardcoded placeholder, no JSON, no special gameplay effect. The GDD describes the MacGuffin as eventually functioning "like an additional negative trait" (e.g. the royal corgi barking every 15 turns) — that behavior is structurally a hook trait (`hook: "on_turn_end"`, see CLAUDE.md's trait schema) and should be built once, as part of the Trait & Equipment JSON System story, not duplicated here.

## Goal
A player can lose a run by being captured by a guard, and win a run by picking up the MacGuffin and reaching the exit. The run then stops (no further input/turns processed) and a human playtester can tell what happened and start again.

## Scope

**In scope:**
- Capture (loss) detection between guards and the player.
- A single placeholder MacGuffin, hand-placed in `poc.tscn`, picked up via proximity (no JSON, no on-pickup gameplay effect beyond setting a flag).
- A single placeholder exit, hand-placed in `poc.tscn`, that ends the run in victory only if the MacGuffin has been picked up.
- Stopping turn/input processing on run end.
- A minimal, non-final way to see the outcome (console/`Log` output is sufficient; on-screen text is a nice-to-have, not required).
- A manual way to restart (e.g. reload the scene on a keypress) so playtesting doesn't require relaunching the game.

**Out of scope (deferred):**
- JSON-driven MacGuffin definitions, multiple MacGuffin types, or the on-pickup hook effect (barking corgi etc.) — bundle with the Trait & Equipment JSON System story, which will build the `on_turn_end` hook engine this needs.
- A real main menu, title screen, or polished victory/game-over UI — that's Run Start Flow's job, since it's where menu infrastructure gets built.
- Inventory system — a single boolean flag is enough for "has the MacGuffin."
- Turn counters / turn-limit loss conditions — not in the GDD's loss criteria (only capture is).
- Procedural placement of the MacGuffin or exit — still hand-placed for this story.

## Acceptance Criteria
1. If a guard's movement would place it on the player's cell, OR the player attempts to move onto a guard's cell, the run ends immediately in a loss. (GDD: "Guards can capture the player by touching a player: bumping them, *not* being adjacent them" — adjacency alone does not trigger it.)
2. A placeholder MacGuffin exists in `poc.tscn`. When the player reaches it (proximity or overlap — see technical note below), a flag is set (e.g. `has_macguffin = true`). No other gameplay effect fires.
3. A placeholder exit exists in `poc.tscn`. If the player reaches it while `has_macguffin == true`, the run ends in a win. Reaching the exit without the MacGuffin does nothing (per GDD, exiting is only a win condition once the MacGuffin is held).
4. After a win or loss, no further player input or world turns are processed — the run is frozen.
5. The outcome (win/loss) and its cause are visible somewhere a playtester can check (Log output at minimum).
6. A playtester can trigger a scene reload to start a fresh run without relaunching the game.

## Technical Notes

**The capture gotcha, and why `interact()` is the right fix:** `GridManager.is_cell_available()` (`project/autoloads/grid_manager.gd`) returns `false` whenever an actor occupies the target cell and that actor's `can_swap` is `false`. Neither `Player` nor `Guard` currently set `can_swap` or `can_overlap`, so a completed-move check (e.g. "did a guard end its turn on the player's cell") will never fire — the move never completes.

`Entity` already has the right primitive for this: `is_interactable` + `interact(source)`. `Entity.try_move_to()` (`project/scripts/actors/entity.gd`) already checks, in order: furniture blocking → occupant with `can_swap` → **occupant with `is_interactable` → `occupant.interact(self)`** → falls back to `is_cell_available()`. Nothing in the codebase currently sets `is_interactable = true` (verified — the field is unused outside `entity.gd`), so this branch is dead code today, but it's exactly the "attempted move into an occupied cell" hook capture needs. Recommended approach:
- Set `Guard.is_interactable = true` and override `Guard.interact(source)` to trigger capture when `source is Player`. This alone handles the player walking into a guard — `try_move_to()` already routes there.
- Set `Player.is_interactable = true` and override `Player.interact(source)` to trigger capture when `source is Guard`. This handles a guard walking into the player — *but only if the guard's move actually reaches `try_move_to()`.*
- That last part needs one small change: `Guard.step_along_path()` checks `GridManager.is_cell_available(next_cell)` **before** calling `try_move_to()`, and clears its path and waits if that's false — so it currently short-circuits before ever reaching the `interact()` branch. This gate needs to let the move through to `try_move_to()` when the blocking occupant is interactable (rather than treating it as a dead end to abandon), e.g. only clear-and-wait when the cell is unavailable *and* the occupant isn't interactable. Without this tweak, a guard walking toward the player will still just stop short and wait, same as today.

This is cleaner than a bespoke capture-check helper — it reuses scaffolding that's already in the base class instead of adding a new code path.

**MacGuffin placeholder:** `project/scenes/components/furniture/chest.tscn` already exists with `closed`/`open` sprite animations and an `Area2D`, but has no script attached — it's unused. This is a ready-made placeholder: attach a script following the `Door` pattern (`project/scripts/components/door.gd`) — `is_furniture = true`, react to `on_proximity_changed()`, play the `open` animation and set the pickup flag on `OVERLAPPED` (or `ADJACENT`, designer's call).

**Exit placeholder:** No exit concept exists yet — no tile flag, no entity. Two reasonable options: (a) a new furniture-style entity placed in the scene, same pattern as the chest/door, or (b) a custom tile-data flag (`is_exit`) following the precedent of `is_walkable`/`is_opaque` in `TileManager`. Recommend (a) for this story — it's editor-placeable without touching the TileSet resource, and exits will likely be structural (tied to a door/room) once procgen exists anyway, which fits the entity model better than a generic tile flag.

**Where does run-outcome state live?** `WorldState` is scoped to alert level and LKP — recommend a small new autoload (e.g. `RunState`) for `has_macguffin`, `is_run_over`, and the outcome, rather than overloading `WorldState`. Open to CC's judgment here; flagging so it's a deliberate choice, not an accident.

**Stopping the run:** `TurnManager` currently has no concept of a "frozen" state. Simplest approach is a guard clause at the top of `end_player_turn()` / `_unhandled_input()` that no-ops if `RunState.is_run_over` (or equivalent) is true.

## Open Questions
- Pickup trigger for the MacGuffin: proximity (`ADJACENT`, like a door peek) or overlap (`OVERLAPPED`, walking onto the tile)? GDD says "locate a chest," which leans toward overlap/interact rather than passive proximity.
- Restart keybind: reuse an existing input action or add a new one? `PlayerInput` currently has no menu/system actions defined.
