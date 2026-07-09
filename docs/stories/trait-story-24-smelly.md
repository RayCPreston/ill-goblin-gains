# Trait Story 24: Smelly

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "smelly",
  "name": "Smelly",
  "type": "negative",
  "description": "Your smell radius is increased by 2.",
  "effect": {
    "kind": "stat",
    "property": "smell_radius",
    "operation": "delta",
    "value": 2
  }
}
```

## What This Story Does
The write itself is trivial — reuses the `stat` dispatch from Story 01. The real work is a reversion: `Player.smell_radius` currently defaults to `3` for every player, unconditionally, shipped as a preview of the mechanic ahead of the trait system (see `docs/architecture.md`'s VFX section). This story must change that default to `0` (or whatever true baseline gets chosen) so smell becomes something only Smelly-holders actually have — not a universal mechanic. Easy to miss since it's a subtraction, not an addition. Verify this explicitly rather than assuming Story 01's general dispatch work covers it.

## Acceptance Criteria
1. `Player.smell_radius` defaults to `0` (not `3`) for players without Smelly.
2. Applying Smelly adds `2`, resulting in a smell radius of `2` for that run.
3. `_emit_smell()`, `SmellAura`, and any other existing consumer correctly reflect the new baseline — verify the always-on preview visual is gone for non-Smelly runs.
