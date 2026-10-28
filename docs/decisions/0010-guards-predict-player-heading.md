# 0010: Guards extrapolate the goblin's heading after losing sight

**Status:** Accepted · 2026-07-05

## Context

Guards headed to exactly where they'd last seen the goblin. Rounding a corner was enough to make a pursuer give up on reaching that cell, which made chases trivially easy to break.

## Decision

Every sighting records the goblin's heading. It's taken from any two sightings by the same guard, not just consecutive turns, so a single glimpse after an earlier one is enough. When sight is lost, the target keeps moving along that heading for a few turns, in two layers:
- **Each CURIOUS guard** pushes its own point of interest forward. If straight ahead is blocked, it slides along the horizontal or vertical part of the heading instead.
- **`WorldState`**, in ALERT, pushes the shared last known position forward, skipping any turn in which a guard has eyes on the goblin, because a real sighting beats a guess.

## Alternatives considered

- **Stopping at the last-seen cell** (the earlier behavior): it made breaking line of sight the whole chase.

## Consequences

- Chases carry on around corners for a few turns, and the player has to actually lose a pursuer.
- The layers are tuned separately (`GuardStateMachine.TRACKING_MEMORY` = 4, `WorldState.TRACKING_MEMORY` = 8) and, as built, differ: only the per-guard layer slides around corners and responds to Cold Trail / Persistent Trail.

**Affects:** [systems/guards.md](../systems/guards.md), [`guard_state_machine.gd`](../../project/scripts/util/actors/guard/guard_state_machine.gd), [`world_state.gd`](../../project/autoloads/world_state.gd)
