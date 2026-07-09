# Trait Story 08: Camouflage

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "camouflage",
  "name": "Camouflage",
  "type": "positive",
  "description": "Guards must be closer than normal to instantly spot you. You can still be noticed at normal range — this only softens the worst case.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_inner_range",
    "operation": "delta",
    "value": -1
  }
}
```

## What This Story Does
First `detection_modifier` trait — establishes the pattern for this whole category. Adds an `inner_range_modifier() -> int` method to `PlayerTraitState`, and edits `GuardStateMachine._check_detection()` to apply it against `GuardFov.INNER_RANGE` at the point of comparison, instead of using the raw constant. Doesn't touch `GuardFov` itself — see the epic's reasoning on keeping FOV computation player-agnostic.

## Acceptance Criteria
1. `PlayerTraitState.inner_range_modifier()` exists, returns `0` when no relevant trait is active.
2. `GuardStateMachine._check_detection()` reads this modifier when evaluating inner-zone detection.
3. Applying Camouflage shrinks the effective inner range by `1`, verifiable by observing a guard needing to close one tile further before triggering ALERT.
4. No `match`/`if` chain on trait names appears in `_check_detection()` — just the one method call.
