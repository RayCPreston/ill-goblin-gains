# Trait Story 06: Pitcher

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "pitcher",
  "name": "Pitcher",
  "type": "positive",
  "description": "You can throw equipment up to 3 tiles further than normal range.",
  "dormant_until": "Throwing/equipment system exists",
  "effect": {
    "kind": "stat",
    "property": "throw_range",
    "operation": "delta",
    "value": 3
  }
}
```

## What This Story Does
Adds `throw_range` to the `stat` dispatch table as a new `Player` field. Nothing consumes it yet — that's expected, not a bug. This story establishes the pattern for "dormant" traits: write the value correctly, verify it's stored, don't block on the consuming system existing.

## Acceptance Criteria
1. `Player` gains a `throw_range: int` field.
2. Applying Pitcher adds `3` to it.
3. No behavior change in-game (nothing reads `throw_range` yet) — that's correct, not a gap in this story.
