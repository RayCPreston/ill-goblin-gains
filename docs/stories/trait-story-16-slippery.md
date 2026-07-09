# Trait Story 16: Slippery

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "slippery",
  "name": "Slippery",
  "type": "positive",
  "description": "The first time a guard would capture you, you slip free instead. One use per run.",
  "effect": {
    "kind": "charge",
    "trigger": "on_capture",
    "charges": 1
  }
}
```

## What This Story Does
First `charge` trait — establishes the pattern. Adds a `try_consume_capture_charge() -> bool` method to `PlayerTraitState` (decrements and returns `true` if a charge was available, `false` otherwise). Insert a check in `Guard.interact()`/`Player.interact()`, before the existing `RunState.lose()` call.

## Acceptance Criteria
1. `PlayerTraitState.try_consume_capture_charge()` exists, returns `false` when no charge is available.
2. With Slippery active, the first capture attempt is negated (no `RunState.lose()`) and the charge is consumed.
3. The second capture attempt in the same run proceeds normally — the charge is gone.
