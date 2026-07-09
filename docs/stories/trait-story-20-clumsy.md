# Trait Story 20: Clumsy

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "clumsy",
  "name": "Clumsy",
  "type": "negative",
  "description": "Every time you move, there's a chance you stumble — your sound pulse fires at double radius instead of normal.",
  "effect": {
    "kind": "chance",
    "trigger": "on_move",
    "one_in": 5,
    "outcome": {
      "type": "noise_multiplier",
      "multiplier": 2
    }
  }
}
```

## What This Story Does
First `chance` trait — establishes the pattern for this whole category (Allergies and Narcolepsy reuse it). Adds a `check_on_move_chance_effects()` (or similar) method to `PlayerTraitState`, doing the RNG roll internally and returning what procced, if anything. Called from `Player.move_to()` at the same point `_emit_noise()` already fires. `Player` shouldn't know about probabilities or trait ids — it just asks `PlayerTraitState` and reacts to the result.

## Acceptance Criteria
1. `PlayerTraitState.check_on_move_chance_effects()` (or equivalent) exists and is called from `Player.move_to()`.
2. With Clumsy active, roughly 1 in 5 moves fires `_emit_noise()` at double radius instead of the normal radius.
3. `Player.move_to()` contains no branching on trait ids or effect kinds — one method call, react to the result.
