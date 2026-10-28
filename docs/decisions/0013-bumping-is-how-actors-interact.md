# 0013: Bumping is how actors interact, both for capture and for picking up the MacGuffin

**Status:** Accepted · 2026-07-05

## Context

Runs needed a way to end. The GDD says guards capture the goblin by *touching*, meaning bumping, not just standing adjacent. And it says the goblin has to *locate a chest* to get the MacGuffin. Two things stood in the way:
- **Occupied cells are blocked.** Guards and the goblin can never occupy the same cell, so "touching" had nowhere to happen.
- **Guards checked before they stepped.** A guard checked whether its next cell was free before stepping, and gave up if it wasn't.

## Decision

Both use the interaction hook already in `Entity`: an occupant marked `is_interactable` gets `interact(source)` called when something tries to move into it. The attempt costs the mover's turn either way.
- **Capture is two-way.** `Guard.interact()` ends the run when the goblin walks into a guard. `Player.interact()` ends it when a guard walks into the goblin. Guards are allowed to step toward an occupied cell when the occupant is interactable, so their bump reaches `interact()`.
- **The MacGuffin is picked up by bumping its chest,** which settles the story's open question of "adjacent vs. overlapping" in favor of interacting.

## Alternatives considered

- **A separate capture check** (a helper testing positions every turn): rejected in favor of reusing scaffolding already in the base class.
- **Picking up the MacGuffin when passing nearby:** this became a trait (Cat Burglar) rather than the baseline.

## Consequences

- Adjacency alone never captures. Being next to a guard is safe until one of you moves into the other.
- Future interactions (switches, terminals, hiding spots) can use the same hook.
- Slippery's "escape a capture" hangs off the same two `interact()` methods.

**Affects:** [systems/run-lifecycle.md](../systems/run-lifecycle.md), [systems/guards.md](../systems/guards.md), [`entity.gd`](../../project/scripts/actors/entity.gd)
