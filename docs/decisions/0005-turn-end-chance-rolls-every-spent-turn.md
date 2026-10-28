# 0005: Turn-end chance effects roll once on every turn the player spends

**Status:** Accepted · 2026-10-27

## Context

Allergies is the first `on_turn_end` trait ([0003](0003-chance-effect-kind.md)). Its story said to roll from `Player.move_to()` and `Player.wait()`. But a turn can also be spent by bumping a wall, opening the chest, walking into a guard, or stepping off the map edge without the MacGuffin, and none of those go through `move_to()` or `wait()`.

## Decision

The roll happens in `Player.end_turn()`, which every spent turn passes through exactly once. It's skipped once the run is over, so you can't sneeze on the turn you're caught or escape.

## Alternatives considered

- **Rolling in `move_to()` and `wait()`** (the original spec): bump and interact turns would never roll, so "on turn end" would quietly mean "on most turns".

## Consequences

- `on_turn_end` means exactly what it says, for every future trait that uses it (Narcolepsy next).
- Anything else that should happen "once per player turn" has a single, obvious home.

**Affects:** [systems/traits-and-gamedata.md](../systems/traits-and-gamedata.md), [`player.gd`](../../project/scripts/actors/player.gd)
