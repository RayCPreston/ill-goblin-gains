# Trait Story 11: Persistent Trail

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 10 (Cold Trail) for the `tracking_memory_modifier()` plumbing

## Trait Definition
```json
{
  "id": "persistent_trail",
  "name": "Persistent Trail",
  "type": "negative",
  "description": "Guards project your position forward for longer after losing sight of you — harder to shake a tail once spotted.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_tracking_memory",
    "operation": "delta",
    "value": 2
  }
}
```

## What This Story Does
Reuses Story 09's plumbing — positive delta on the same parameter.

## Acceptance Criteria
1. Applying Persistent Trail increases a guard's post-LOS-break projection window by `2` turns.
