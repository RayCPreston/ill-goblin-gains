# Trait Story 18: Statue

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 08 (Camouflage) for the `detection_modifier` dispatch pattern

## Trait Definition
```json
{
  "id": "statue",
  "name": "Statue",
  "type": "positive",
  "description": "While waiting instead of moving, guards' outer-zone detection doesn't register you — only close-range detection still applies.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_outer_zone",
    "operation": "suppress",
    "condition": "player_waited_last_turn"
  }
}
```

## What This Story Does
First use of the `suppress` operation (as opposed to `delta`/`set`). Needs one small addition beyond the trait system itself: `Player` doesn't currently track whether it moved or waited last turn — add a flag (set in `move_to()` and `wait()`). Adds an `is_outer_zone_suppressed(player_waited_last_turn: bool) -> bool` method to `PlayerTraitState`. `GuardStateMachine._check_detection()`'s outer-zone branch checks it before reacting.

## Acceptance Criteria
1. `Player` tracks whether its last action was a move or a wait.
2. `PlayerTraitState.is_outer_zone_suppressed()` exists, returns `false` by default.
3. With Statue active and the player having waited last turn, outer-zone sightings don't trigger CURIOUS.
4. Inner-zone (ALERT) detection is unaffected regardless of Statue or wait state.
