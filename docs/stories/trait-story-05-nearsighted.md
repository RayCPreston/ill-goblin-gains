# Trait Story 05: Nearsighted

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 03 (Keen Eyes) for the `vision_range` dispatch entry

## Trait Definition
```json
{
  "id": "nearsighted",
  "name": "Nearsighted",
  "type": "negative",
  "description": "Your vision range is reduced by 3 tiles.",
  "effect": {
    "kind": "stat",
    "property": "vision_range",
    "operation": "delta",
    "value": -3
  }
}
```

## What This Story Does
Reuses the `vision_range` dispatch entry from Story 02 — inverse delta, no new plumbing.

## Acceptance Criteria
1. Applying Nearsighted at run start subtracts `3` from `Player.fov.max_range`.
