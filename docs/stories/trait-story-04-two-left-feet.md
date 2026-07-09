# Trait Story 04: Two Left Feet

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "two_left_feet",
  "name": "Two Left Feet",
  "type": "negative",
  "description": "Your noise radius is increased by 1.",
  "effect": {
    "kind": "stat",
    "property": "noise_radius",
    "operation": "delta",
    "value": 1
  }
}
```

## What This Story Does
Reuses the `noise_radius` dispatch entry from Story 01 — no new plumbing, just a new trait id pointing at an already-wired property.

## Acceptance Criteria
1. Applying Two Left Feet at run start adds `1` to `Player.noise_radius`.
