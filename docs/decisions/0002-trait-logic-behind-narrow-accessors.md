# 0002: Gameplay reads traits only through narrowly named accessors

**Status:** Accepted · 2026-07-08

## Context

Traits touch many systems: guard vision, detection, capture, MacGuffin pickup, noise. Without a rule, each of those places would grow its own `if player has trait X` checks, and trait logic would end up scattered across the codebase.

## Decision

All trait resolution lives in `GameData` (applying effects) and `PlayerTraitState` (holding them). Every gameplay call site makes exactly one call to a purpose-named method, such as `inner_range_modifier()`, `try_consume_capture_charge()` or `check_on_turn_end_chance_effects()`, and gets back a plain value. Nothing outside those two files branches on a trait id, effect kind or property name.

## Alternatives considered

- **A generic string-keyed getter** (`traits.get("guard_inner_range")`): one method instead of many, but call sites would be passing trait vocabulary around, and typos would only surface at runtime.
- **Checking trait ids at call sites:** simplest for the first trait, unmaintainable by the twentieth.

## Consequences

- Adding a behavior means adding an accessor, which keeps every trait touchpoint discoverable from `PlayerTraitState`.
- Call sites stay readable as gameplay ("how far can this guard see clearly?") rather than as trait bookkeeping.
- `PlayerTraitState` grows one small method per behavior. That's accepted as the cost.

**Affects:** [systems/traits-and-gamedata.md](../systems/traits-and-gamedata.md), [`player_trait_state.gd`](../../project/scripts/util/actors/player/player_trait_state.gd)
