# Trait Story 19: Eavesdropper

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "eavesdropper",
  "name": "Eavesdropper",
  "type": "positive",
  "description": "You can hear guards moving through walls within a radius. Their presence is revealed as a '?' marker — not their identity, state, or exact type.",
  "effect": {
    "kind": "perception",
    "mode": "hearing_through_walls",
    "radius": 6,
    "marker": "unknown"
  }
}
```

## What This Story Does
First (and currently only) `perception` trait. The data (radius, marker style) is easy to store and query via `PlayerTraitState`. The actual mechanic — a reverse `ProximityAlert` query run from the player's position, plus `?` marker rendering — doesn't exist yet and is the bulk of this story's real work. Deliberately independent of `Guard`/`VisionManager`'s existing visibility state: the guard stays properly UNSEEN under normal fog-of-war rules; this draws an additive marker on top, not a change to detection or rendering elsewhere.

## Acceptance Criteria
1. `PlayerTraitState` exposes the perception radius when Eavesdropper is active, `0` otherwise.
2. Each turn, guards within that radius (blocked by the same wall/door opacity `ProximityAlert` already respects) get a `?` marker rendered at their position, even outside the player's direct FOV.
3. The marker conveys presence only — no cone, no state, no guard-type information.
4. Guards outside the radius, or with no unobstructed path within it, show nothing.
