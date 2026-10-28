# 0015: For now, escaping means walking off the map edge holding the MacGuffin

**Status:** Accepted (placeholder) · 2026-07-05

## Context

The win condition is to find the MacGuffin and leave the building with it. The session-end story planned a placeholder exit, either a furniture-style entity or an "is exit" tile flag, hand-placed in the test map.

## Decision

There's no exit object. Walking off any edge of the map while holding the MacGuffin wins the run. Walking off without it just spends the turn.

## Alternatives considered

- **An exit entity, or an exit tile flag** (the story's plan): deferred. Where exits sit, and what they look like, is tied to rooms and doors, and that will be decided by procedural generation.

## Consequences

- Any edge is an exit, which makes escape easier than a single real exit would. That's acceptable while the map is a hand-built test level.
- Replacing it is contained: one check in `Player.try_move_to()` becomes an exit that calls `RunState.win()`.
- Revisit this together with procedural generation, and record the real exit as a new decision that supersedes this one.

**Affects:** [systems/run-lifecycle.md](../systems/run-lifecycle.md), [`player.gd`](../../project/scripts/actors/player.gd)
