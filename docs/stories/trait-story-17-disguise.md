# Trait Story 17: Disguise

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 16 (Slippery) for the `charge` dispatch pattern

## Trait Definition
```json
{
  "id": "disguise",
  "name": "Disguise",
  "type": "positive",
  "description": "The first time you'd be detected, you pass through undetected instead — for as long as you remain inside a guard's vision cone(s) without breaking away. One use per run.",
  "effect": {
    "kind": "charge",
    "trigger": "on_sustained_detection_window",
    "charges": 1
  }
}
```

## What This Story Does
The heaviest trait in the positive list, by design — flagged in the epic as needing its own design pass, not solved there. Unlike Slippery's single-instant consume, Disguise needs a short-lived "currently disguised" window that persists across multiple turns while the player remains inside any guard's cone, only consuming the charge once the player fully exits undetected. That state-tracking mechanism isn't designed yet; this story is where it gets designed and built, not assumed.

## Acceptance Criteria
1. A concrete state-tracking approach is designed and documented (in this file or a follow-up note) before implementation starts.
2. With Disguise active, a full pass through a guard's cone (or overlapping cones) doesn't trigger CURIOUS/ALERT, and the charge consumes only once the player is clear.
3. The charge is not consumed if the player never actually entered a cone this run (it doesn't burn on nothing).
