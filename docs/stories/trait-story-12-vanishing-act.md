# Trait Story 12: Vanishing Act

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 01

## Trait Definition
```json
{
  "id": "vanishing_act",
  "name": "Vanishing Act",
  "type": "positive",
  "description": "Guards give up searching for you and return to patrol sooner once they've lost your trail.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_search_hops",
    "operation": "delta",
    "value": -1
  }
}
```

## What This Story Does
Adds a `search_hops_modifier() -> int` method to `PlayerTraitState`. Edits the search-hop logic in `GuardStateMachine._do_curious()` to apply it against `POI_SEARCH_HOPS` (currently `2`).

## Acceptance Criteria
1. `PlayerTraitState.search_hops_modifier()` exists, returns `0` by default.
2. `_do_curious()` reads this modifier instead of the raw constant.
3. Applying Vanishing Act reduces the number of search hops a CURIOUS guard takes before reverting to PATROL by `1`.
