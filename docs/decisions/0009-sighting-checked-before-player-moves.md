# 0009: Guards check for the goblin before the goblin's move resolves

**Status:** Accepted · 2026-07-09

## Context

The player acts first each turn, then the guards. Guards only looked for the goblin during their own turn, so a goblin standing inside a cone could step out of it on its turn and never be seen, even though it had been in plain view all along.

## Decision

Before the player's action resolves, `Player._check_guard_sighting()` asks every guard to test the goblin's *current* cell against that guard's current cones (`check_immediate_sighting()`). A hit reacts exactly as a sighting during the guard's own turn would. Guards still check again during their turn.

## Alternatives considered

- **Checking only during the guard's turn** (the original behavior): it let the goblin dodge sightings it was already in.

## Consequences

- Standing in a cone at the end of the world turn means you're seen. Moving away doesn't undo it.
- Each guard checks for the goblin up to twice per turn: once before the player's move, once during its own turn. Effects that track "seen this turn", like Disguise, account for both.
- Waiting is checked the same way, which is what makes Statue's "ignored while waiting" meaningful.

**Affects:** [systems/guards.md](../systems/guards.md), [`player.gd`](../../project/scripts/actors/player.gd), [`guard_state_machine.gd`](../../project/scripts/util/actors/guard/guard_state_machine.gd)
