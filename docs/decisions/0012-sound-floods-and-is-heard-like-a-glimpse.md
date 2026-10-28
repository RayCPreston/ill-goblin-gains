# 0012: Sound floods around corners, and hearing is treated as an outer-zone glimpse

**Status:** Accepted · 2026-07-05

## Context

The goblin needed to be audible, not just visible: footsteps first, then smell and sneezes. Two questions came with that. How does sound travel through a mansion of walls and doors? And what does a guard do when it hears something?

## Decision

- **Propagation:** sound spreads like a gas. `ProximityAlert` flood-fills outward from the source for `radius` steps in eight directions, wrapping around corners. It's stopped by the same walls and vision-blocking furniture (closed or peeked doors) that stop sight, and it can't squeeze diagonally between two walls. It's generic: an origin, a radius, and the cells reached.
- **Reaction:** a guard in a reached cell reacts exactly as if it had glimpsed the goblin in its outer zone, through the single `react_to_proximity()` dispatch: PATROL goes CURIOUS, CURIOUS re-targets, ALERT updates the last known position. Hearing alone never triggers ALERT.

## Alternatives considered

- **Vision-style straight lines for sound:** it would make a wall a perfect silencer, which isn't how sound behaves, and it would make noise redundant with sight.

## Consequences

- Noise is a separate threat from sight: you can be heard around a corner you can't be seen past, and closed doors matter for both.
- Every source (steps, smell, sneezes, and later thrown items and the corgi) shares one flood fill and one reaction path. New sources are a radius and a call, not new guard logic.
- Smell, sneezes and Eavesdropper's reverse listening all reuse the same flood fill.

**Affects:** [systems/sound-and-smell.md](../systems/sound-and-smell.md), [systems/guards.md](../systems/guards.md), [`proximity_alert.gd`](../../project/scripts/util/proximity_alert.gd)
