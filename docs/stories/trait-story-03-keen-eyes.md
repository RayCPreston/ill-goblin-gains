# Trait Story 03: Keen Eyes

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01 (Padfoot) for `GameData`/dispatch scaffolding

## Trait Definition
```json
{
  "id": "keen_eyes",
  "name": "Keen Eyes",
  "type": "positive",
  "description": "Your vision range is increased by 3 tiles.",
  "effect": {
    "kind": "stat",
    "property": "vision_range",
    "operation": "delta",
    "value": 3
  }
}
```

## What This Story Does
Adds `vision_range` to the `stat` dispatch table from Story 01, resolving to `Player.fov.max_range` (nested under `Player.fov`, not a direct `Player` field — see `traits.md`'s Property/Parameter Reference). Proves out the `delta` operation.

## Acceptance Criteria
1. Applying Keen Eyes at run start adds `3` to `Player.fov.max_range`.
2. `PlayerFov.compute()` (already existing) reflects the wider range with no changes needed there.
