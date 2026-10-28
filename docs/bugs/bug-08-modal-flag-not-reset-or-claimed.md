# Bug 08: Restart doesn't reset `UiState`, and the end screen doesn't claim the modal flag

**Severity:** latent, plus one small visible symptom.

## Symptom
- Restarting with the traits screen open leaves `modal_open` set. It only works because the reveal screen sets and then clears the flag on the next run.
- The traits screen (C) can be opened over the end screen.

## Cause
- `GameManager._restart_run()` doesn't reset `UiState`.
- `EndScreen` doesn't set `modal_open` while it's showing.

## Where
- `game_manager.gd` `_restart_run()`
- `ui_state.gd`
- `end_screen.gd`

## Fix direction
- Give `UiState` a `reset()` and call it from `_restart_run()` alongside the other autoload resets.
- Have the end screen hold the modal flag while it's showing.

## Done when
- A restart leaves `modal_open` false, whatever was open.
- C does nothing while the end screen is up.
- The `UiState` and end-screen Gotchas in [run-lifecycle.md](../systems/run-lifecycle.md#gotchas) are removed.
