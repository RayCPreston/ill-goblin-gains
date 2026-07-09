# Trait Story 22: Narcolepsy

**Epic:** `docs/stories/game-data-trait-application.md` · **Depends on:** Story 20 (Clumsy) for the `chance` dispatch pattern

## Trait Definition
```json
{
  "id": "narcolepsy",
  "name": "Narcolepsy",
  "type": "negative",
  "description": "You have a chance to fall asleep for a few turns every so often, unable to act.",
  "effect": {
    "kind": "chance",
    "trigger": "on_turn_end",
    "one_in": 50,
    "outcome": {
      "type": "sleep",
      "duration": 3
    }
  }
}
```

## What This Story Does
The heaviest negative trait, by design — flagged in the epic as needing its own pass. Two genuinely new pieces: an `is_sleeping: bool` field on `Entity` (not `Player` — so a future item like sleeping darts can put a `Guard` to sleep with the same flag, no duplication) and turn-skip enforcement in `Player._unhandled_input()` (input ignored, an automatic `wait()` substituted, for the sleep's duration). Juice (little Z's, a sawing-log animation) is a nice-to-have, not required for this story's acceptance.

## Acceptance Criteria
1. `Entity` gains an `is_sleeping: bool` field (and whatever turn-countdown state is needed).
2. `Player._unhandled_input()` ignores real input and auto-waits while `is_sleeping` is true, counting down each turn.
3. With Narcolepsy active, roughly 1 in 50 turns triggers `is_sleeping` for `3` turns.
4. The player regains control automatically once the duration elapses — no manual intervention needed.
5. Juice (Z's/sawing log) is out of scope for this story's acceptance; note it as a follow-up if not included.
