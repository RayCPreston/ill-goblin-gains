# Trait Story 23: Far-Sighted

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "far_sighted",
  "name": "Far-Sighted",
  "type": "negative",
  "description": "Your vision doesn't start until 2 tiles away — you have a blind spot immediately around you, though you can always see the tile you're standing on.",
  "effect": {
    "kind": "stat",
    "property": "vision_min_range",
    "operation": "set",
    "value": 2
  }
}
```

## What This Story Does
Needs a new `PlayerFov.min_range` field (default `0`, meaning no blind spot) and a `row >= min_range` condition added to the existing `_memory[cell] = VisionState.VISIBLE` line in `_scan()`. Confirmed contained during design: the shadow-splitting recursion in `_scan()` is driven entirely by `is_opaque` transitions, completely independent of whether a cell gets marked `VISIBLE` — so gating visibility doesn't touch the recursion. `PlayerFov` has no connection to guard detection at all (that's `GuardFov`, a fully separate system), so this can't accidentally affect whether guards see the player. The origin cell is set `VISIBLE` unconditionally before the row-scan begins, so it's unaffected by the blind spot regardless — matching "always see the tile you're standing on."

## Acceptance Criteria
1. `PlayerFov` gains a `min_range: int` field, default `0`.
2. Cells with `row < min_range` are never marked `VISIBLE`, but still correctly participate in shadow-casting recursion (a wall inside the blind spot still blocks vision further out, same as always).
3. The player's own tile is always visible, unaffected by `min_range`.
4. Applying Far-Sighted sets `min_range` to `2`.
5. Guard detection is unaffected — verify a guard can still see/detect the player normally regardless of the player's own blind spot.
