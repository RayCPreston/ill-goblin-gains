# 0003: Probabilistic, recurring traits get their own effect kind, `chance`

**Status:** Accepted · 2026-07-20

## Context

Clumsy (stumbles while moving), Allergies (sneezes) and Narcolepsy (falls asleep) all work the same way: something is checked over and over, and occasionally it fires. None of the original five kinds (`stat`, `detection_modifier`, `flag`, `charge`, `perception`) describes "checked repeatedly, fires occasionally".

## Decision

A sixth kind, `chance`, with three fields:
- `trigger`: when it's checked (`on_move`, `on_turn_end`);
- `one_in`: the odds each time it's checked;
- `outcome`: what happens when it fires (`noise_multiplier`, `alert_burst`, and later `sleep`).

`PlayerTraitState` owns the dice roll and returns only the result (e.g. a noise multiplier, or a burst radius). `Player` calls it once at the matching trigger point and never sees odds, trait ids, or outcome types.

## Alternatives considered

- **Forcing them into an existing kind** (e.g. a `flag` plus odds): every kind would grow special cases, which is the scattering [0002](0002-trait-logic-behind-narrow-accessors.md) exists to prevent.

## Consequences

- A new chance trait with an existing trigger and outcome is data only.
- A new trigger or outcome needs its name in the known lists, a dispatch line, and a check method on `PlayerTraitState`.
- Each `check_on_<trigger>_chance_effects()` currently returns one value. Narcolepsy will be the first case where one trigger has more than one outcome type, so that return shape will need to grow then.

**Affects:** [systems/traits-and-gamedata.md](../systems/traits-and-gamedata.md)
