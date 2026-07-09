# Trait Story 14: Treasure Hound

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 13 (Cat Burglar) for the `flag` dispatch pattern

## Trait Definition
```json
{
  "id": "treasure_hound",
  "name": "Treasure Hound",
  "type": "positive",
  "description": "A small indicator around you points toward the MacGuffin's compass direction.",
  "effect": {
    "kind": "flag",
    "flag": "reveals_macguffin_direction",
    "value": true
  }
}
```

## What This Story Does
Adds a `reveals_macguffin_direction() -> bool` method to `PlayerTraitState`. The flag itself is easy to wire; the HUD element that reads it (a compass indicator around the player) doesn't exist yet — this story delivers the flag correctly stored and queryable, and the HUD piece is a separate follow-up once minimal HUD work is scoped.

## Acceptance Criteria
1. `PlayerTraitState.reveals_macguffin_direction()` exists, returns `false` by default.
2. Applying Treasure Hound sets it to `true`.
3. No visual change yet — HUD consumption is out of scope for this story.
