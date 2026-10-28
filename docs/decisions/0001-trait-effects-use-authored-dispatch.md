# 0001: Trait effects are applied through an authored dispatch, validated at load, with no reflection

**Status:** Accepted · 2026-07-08

## Context

Trait definitions name the property they change as a string, such as `"property": "noise_radius"`. GDScript could resolve that string straight into a field (`Object.set()`, `set_indexed()`), which would make every new `stat` trait work with no code at all.

## Decision

`GameData` keeps an explicit list of known property, parameter, flag, trigger, outcome and mode names for each effect kind, and applies effects through a hand-written `match`. Definitions are checked against those lists when they load. Anything unrecognized is logged with `Log.error` and dropped, so it never enters the roll pool. No reflection is used anywhere in the trait system.

## Alternatives considered

- **Reflection (`Object.set()` / `set_indexed()`):** zero code per new trait, but it succeeds on *any* valid path, intended or not. A typo or a stray property name would quietly write to the wrong field, or a trait would quietly do nothing.

## Consequences

- Each new property, flag or trigger costs one entry in a `KNOWN_*` list plus one dispatch line. That's deliberate: only what someone explicitly wired up can be touched.
- Every typo fails the same way, at load time, in the log.
- A trait that fails validation disappears from the game rather than half-working. Check the log when a new trait never rolls.

**Affects:** [systems/traits-and-gamedata.md](../systems/traits-and-gamedata.md), [`game_data.gd`](../../project/autoloads/game_data.gd)
