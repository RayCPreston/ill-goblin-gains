# Trait Story 09: Big Target

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 08 (Camouflage) for the `inner_range_modifier()` plumbing

## Trait Definition
```json
{
  "id": "big_target",
  "name": "Big Target",
  "type": "negative",
  "description": "Guards notice you from slightly further away than normal.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_inner_range",
    "operation": "delta",
    "value": 1
  }
}
```

## What This Story Does
Reuses the exact plumbing from Story 07 — inverse delta on the same parameter, no new code paths.

## Acceptance Criteria
1. Applying Big Target grows the effective inner range by `1`.
