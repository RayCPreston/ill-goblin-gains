# 0020: A sleeping goblin's turns still wait for the player's input

**Status:** Accepted · 2026-10-29

## Context

Narcolepsy puts the goblin to sleep for 3 turns. The first build spent those turns automatically, one every 0.6s, so the player watched the world move on without them. In playtesting, Ray found that this took away the one thing a sleeping player can still do: think. The guards had already moved before the player could work out what to do on waking.

## Decision

The world never moves without the player's input, asleep or not. While the goblin sleeps, any move or wait input spends one slept turn instead of doing what was pressed: the goblin stays put, a `*snooze*` floats up, and the world takes its turn. Once the sleep is spent, input works normally again. `*snooze*` also appears the moment the goblin falls asleep, so the player knows before they press anything.

A slept turn runs the same pre-move guard sighting check as a real turn and counts as a wait.

Sleep state (`is_sleeping`, the countdown, the text) lives on `Entity`, so anything can be put to sleep. Falling asleep while already asleep keeps the longer of the two counts, so a sleep never gets cut short.

## Alternatives considered

- **Automatic sleeping turns, paced by `TurnManager`** (built first): it felt dramatic, but the player lost their time to plan.
- **Spending all slept turns at once, in one frame:** the guards would jump several cells and the player would miss what happened while the goblin slept.

## Consequences

- Narcolepsy costs turns, not thinking time. The player can study the guards between presses and plan for when they wake.
- Each slept turn counts as a wait: Statue applies, and Fidgety still makes noise.
- Narcolepsy rolls on every spent turn, slept ones included ([0005](0005-turn-end-chance-rolls-every-spent-turn.md)), so a sleep can occasionally chain into another one.
- A sleeping guard (e.g. a future sleeping dart) has no input to wait for. `TurnManager` would need to call `sleep_through_turn()` instead of `take_turn()`, and guard vision would need to switch off.

**Affects:** [systems/turn-and-grid.md](../systems/turn-and-grid.md), [systems/traits-and-gamedata.md](../systems/traits-and-gamedata.md), [`player.gd`](../../project/scripts/actors/player.gd), [`entity.gd`](../../project/scripts/actors/entity.gd)
