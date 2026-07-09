# Trait Story 15: Fidgety

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "fidgety",
  "name": "Fidgety",
  "type": "negative",
  "description": "Waiting doesn't fully hide you — you still emit a small sound pulse even while standing still.",
  "effect": {
    "kind": "flag",
    "flag": "emits_noise_while_waiting",
    "value": true
  }
}
```

## What This Story Does
Adds an `emits_noise_while_waiting() -> bool` method to `PlayerTraitState`. `Player.wait()` currently never emits noise at all (only `move_to()` does) — this story adds a conditional call there, checking the flag.

## Acceptance Criteria
1. `PlayerTraitState.emits_noise_while_waiting()` exists, returns `false` by default.
2. Without Fidgety, `wait()` behaves as it does today — no noise.
3. With Fidgety, `wait()` also triggers a noise emission (reuse `_emit_noise()`'s existing radius/logic — tune the exact radius separately if it should differ from movement noise).
