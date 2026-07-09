# Trait Story 02: Traits Modal (Character Screen)

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01 (Padfoot) for `GameData`/`PlayerTraitState`

## What This Story Does
Not a trait itself — this is the UI for reviewing whichever traits the player currently has, the concrete realization of the GDD's "Examine Traits" player action. Ray's spec:
- Pressing `C` ("character") toggles a modal open.
- The modal lists the player's currently-applied traits, each mapped to a number `1`–`n`.
- Pressing the corresponding number shows that trait's name, description, and effect.

This sits right after Padfoot rather than at the end of the list because it doesn't need every trait's *effect* wired up to work — it only needs the applied trait id list and each trait's `name`/`description` text, both of which exist as soon as Story 01 lands (`GameData` loads the definitions; `PlayerTraitState`/the run-start trigger holds which ids are applied). Building it early also means every later trait story has a real screen to verify itself against, instead of `Log.info()` output.

## Technical Notes

**Input.** No "character menu" input action exists yet. Add one (e.g. `character_menu`, bound to `C`) in `project.godot`, following the same pattern as the existing `restart` action (`R`).

**Blocking gameplay while open.** The modal shouldn't consume a player turn, and movement/wait input shouldn't pass through while it's open — similar in spirit to how `RunState.is_run_over` already gates `Player._unhandled_input()`, but this is a toggleable UI state, not an end-of-run state. Needs a small piece of new state (owned by the modal scene, or a lightweight UI-state autoload if more menus are coming) that `Player._unhandled_input()` checks and defers to while open.

**Scene shape.** Follow the `EndScreen` precedent (`scenes/ui/end_screen.tscn`, a `CanvasLayer` that's shown/hidden rather than instanced fresh each time) rather than inventing a new pattern.

**Data source.** Reads `Player.traits` (`PlayerTraitState`) for the applied trait id list, and the loaded `GameData` definitions for each trait's display text. No new copywriting — pull `name`/`description` straight from the JSON already authored in `docs/traits.md`.

**Numbering stability.** `1`–`n` should probably stay stable across opens within a run (e.g. sorted by roll order or alphabetically) rather than re-shuffling each time the modal opens — implementation's call unless Ray has a preference when this gets built.

## Acceptance Criteria
1. Pressing `C` opens a modal listing the player's currently-applied traits, numbered `1` through `n`.
2. Pressing a number key shows that trait's name, description, and effect summary.
3. While the modal is open, movement/wait input doesn't pass through to the player, and no turn is consumed.
4. Dismissing the modal (pressing `C` again, at minimum) returns control to the player.

## Open Questions
- Exact dismiss key(s) — `C` again, `Escape`, or both.
- Numbering stability approach (roll order vs. alphabetical).
