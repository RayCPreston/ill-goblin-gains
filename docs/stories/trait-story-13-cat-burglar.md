# Trait Story 13: Cat Burglar

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "cat_burglar",
  "name": "Cat Burglar",
  "type": "positive",
  "description": "Chests open automatically the moment you're adjacent to them — no need to bump into them like you normally would.",
  "effect": {
    "kind": "flag",
    "flag": "chest_opens_on_adjacent",
    "value": true
  }
}
```

## What This Story Does
First `flag` trait — establishes the pattern. Adds a `chest_opens_on_adjacent() -> bool` method to `PlayerTraitState`. Baseline chests currently require a bump to open (`is_interactable`/`interact()`, shipped in PR #33 — already costs a turn via `try_move_to()`'s unconditional `end_turn()`). This trait adds an `on_proximity_changed()` override to the chest/treasure furniture, checking `Proximity.ADJACENT` plus this flag, calling the same acquire logic `interact()` uses — worth extracting into one shared private method on the furniture script rather than duplicating it.

## Acceptance Criteria
1. `PlayerTraitState.chest_opens_on_adjacent()` exists, returns `false` by default.
2. Chest/treasure furniture implements `on_proximity_changed()`, triggering the same acquire logic as `interact()` when `Proximity.ADJACENT` and the flag is set.
3. Without Cat Burglar, chests still require a bump (unchanged, existing behavior).
4. With Cat Burglar, walking adjacent to a chest opens it with no bump needed.
