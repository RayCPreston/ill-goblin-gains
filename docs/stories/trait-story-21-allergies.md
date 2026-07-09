# Trait Story 21: Allergies

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 20 (Clumsy) for the `chance` dispatch pattern

## Trait Definition
```json
{
  "id": "allergies",
  "name": "Allergies",
  "type": "negative",
  "description": "You have a chance to sneeze every so often, alerting guards within a radius. A juiced \"ACHOO!\" radiates out when it happens.",
  "effect": {
    "kind": "chance",
    "trigger": "on_turn_end",
    "one_in": 25,
    "outcome": {
      "type": "alert_burst",
      "radius": 10,
      "juice": "achoo_text"
    }
  }
}
```

## What This Story Does
Reuses Story 19's `chance` dispatch, but on the `on_turn_end` trigger (fires from both `move_to()` and `wait()`, unlike Clumsy's `on_move`-only). The gameplay effect (guard alert burst) is fully buildable now, reusing `ProximityAlert` directly. The "ACHOO!" text juice is a separate piece — a text-rendering variant of the sound-pulse VFX foundation — and can ship after if it's not ready; the gameplay effect doesn't depend on the juice existing.

## Acceptance Criteria
1. `PlayerTraitState` exposes an `on_turn_end` chance check, called from both `move_to()` and `wait()`.
2. With Allergies active, roughly 1 in 25 turns triggers a guard-alerting burst at radius `10` via `ProximityAlert`, identical in effect to a sound/smell pulse.
3. "ACHOO!" text juice may ship separately — its absence doesn't block this story's gameplay acceptance.
