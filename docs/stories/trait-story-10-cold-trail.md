# Trait Story 10: Cold Trail

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "cold_trail",
  "name": "Cold Trail",
  "type": "positive",
  "description": "Guards give up tracking your projected position sooner after losing sight of you.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_tracking_memory",
    "operation": "delta",
    "value": -1
  }
}
```

## What This Story Does
Adds a `tracking_memory_modifier() -> int` method to `PlayerTraitState`. Edits `GuardStateMachine._tick_tracking()` to apply it against `TRACKING_MEMORY` (currently `4`) at the point of use.

## Acceptance Criteria
1. `PlayerTraitState.tracking_memory_modifier()` exists, returns `0` by default.
2. `_tick_tracking()` reads this modifier instead of the raw constant.
3. Applying Cold Trail reduces a guard's post-LOS-break projection window by `1` turn, verifiable by observation.
