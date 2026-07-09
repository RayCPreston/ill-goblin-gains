# Trait Story 07: Butterfingers

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 06 (Pitcher) for the `throw_range` field

## Trait Definition
```json
{
  "id": "butterfingers",
  "name": "Butterfingers",
  "type": "negative",
  "description": "You can only throw equipment 2 tiles less far than normal range.",
  "dormant_until": "Throwing/equipment system exists",
  "effect": {
    "kind": "stat",
    "property": "throw_range",
    "operation": "delta",
    "value": -2
  }
}
```

## What This Story Does
Reuses the `throw_range` dispatch entry from Story 05 — inverse delta, dormant for the same reason.

## Acceptance Criteria
1. Applying Butterfingers subtracts `2` from `Player.throw_range`.
