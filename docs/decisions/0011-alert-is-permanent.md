# 0011: Once the world goes ALERT, it stays ALERT for the rest of the run

**Status:** Accepted · 2026-06-25

## Context

The world has two states: NORMAL, and ALERT once the goblin is properly spotted (an inner-zone sighting, or anything that calls `WorldState.set_lkp()`). Something had to decide whether ALERT ever calms back down to NORMAL.

## Decision

ALERT is a one-way ratchet. Once tripped, the world and every guard stay in ALERT until the run ends, by capture or by escaping with the MacGuffin.

The reasoning, in Ray's words: it simulates reality a bit more. A real threat has been identified, so the guards stay on high alert until the threat is stopped or the goblin escapes with the loot.

## Alternatives considered

- None recorded. The GDD never described a way to de-escalate.

## Consequences

- Getting properly spotted is a real, lasting cost. The rest of the run is played against 360° red cones and guards hunting the last known position.
- There's no "wait it out" strategy for ALERT. The tension rests on losing pursuers, through predictive tracking ([0010](0010-guards-predict-player-heading.md)), and on finishing the heist.
- Anything that trips ALERT (future cameras, lasers) is equally permanent, so those systems should be designed knowing that a trip is never undone.

**Affects:** [systems/guards.md](../systems/guards.md), [`world_state.gd`](../../project/autoloads/world_state.gd), [GDD → World States](../design/game-design-doc.md#world-states)
