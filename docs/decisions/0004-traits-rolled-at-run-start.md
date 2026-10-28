# 0004: Traits are rolled fresh each run (3 positive, 2 negative) by a generic roller

**Status:** Accepted · 2026-07-20

## Context

The GDD calls for each run to start with random traits, mostly good and a few bad. Before this, every run applied the same hardcoded list of trait ids, a placeholder from when the trait system was first built.

## Decision

- **Counts:** 3 positive and 2 negative traits, confirmed with Ray. They're named constants (`Constants.STARTING_POSITIVE_TRAIT_COUNT` / `STARTING_NEGATIVE_TRAIT_COUNT`). A third, `STARTING_ITEM_COUNT = 3`, is reserved for equipment.
- **Rolling:** `PoolRoller` picks N distinct ids from any list and knows nothing about traits, so equipment can reuse it unchanged.
- **The pool:** every trait that passed validation ([0001](0001-trait-effects-use-authored-dispatch.md)). A trait that isn't fully supported is automatically left out, with no second hardcoded exclusion list to maintain.
- **The reveal:** a reveal screen (`RunStartModal`) shows the picks before the player can act. It's dismissed with its own `confirm` action (Enter or Space), not the gameplay `wait` key.
- **Restart:** reloads the scene, which re-rolls automatically.

## Alternatives considered

- **Rolling code written specifically for traits** (inline in `GameManager` or inside `GameData`): rejected at Ray's direction, so that item rolling later is the same call with a different pool.
- **Reusing `wait` to dismiss the reveal:** rejected to keep starting a run separate from a gameplay action.

## Consequences

- Adding a trait to `traits.json` puts it in the pool with no other changes.
- The reveal screen shows names only. Descriptions are one key away, in the **C** traits screen.
- There's no main menu yet. The game still boots straight into a run and pauses on the reveal.

**Affects:** [systems/traits-and-gamedata.md](../systems/traits-and-gamedata.md), [`game_manager.gd`](../../project/autoloads/game_manager.gd), [`pool_roller.gd`](../../project/scripts/util/pool_roller.gd)
