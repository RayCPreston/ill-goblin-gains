# 0014: Run outcome lives in `RunState`; a finished run freezes; restart reloads the scene

**Status:** Accepted · 2026-07-05

## Context

Ending runs raised three questions: where "holding the MacGuffin" and "the run is over" should live, how to stop the game once it ends, and how to start again without relaunching. `WorldState` already existed, but it's about guards: the alert level and the last known position.

## Decision

- **A separate `RunState` autoload** holds the run's own state (`has_macguffin`, `is_run_over`, the outcome, and later the trait loadout). It keeps `WorldState` focused on guards.
- **Ending is one path:** `RunState.win()` or `lose()` marks the run over, logs the outcome, and emits `GameEvents.run_ended`.
- **Freezing is a guard check, not a new state:** `Player` input and `TurnManager`'s world turn each check `is_run_over` and do nothing once it's set. An end screen listens for `run_ended`.
- **Restart (R) reloads the scene** after resetting the autoloads that carry run state, so everything else is rebuilt fresh.

## Alternatives considered

- **Putting run state on `WorldState`:** rejected, to keep one autoload per responsibility.
- **A polished menu-driven end and restart:** deferred to the run-start and menu work. Console output was the minimum bar; a simple end screen shipped.

## Consequences

- Any new autoload that carries per-run state must be reset in `GameManager._restart_run()`, or it leaks into the next run. Scene-owned state needs nothing.
- Restarting from anywhere is one keypress, which keeps playtesting fast.

**Affects:** [systems/run-lifecycle.md](../systems/run-lifecycle.md), [`run_state.gd`](../../project/autoloads/run_state.gd), [`game_manager.gd`](../../project/autoloads/game_manager.gd)
