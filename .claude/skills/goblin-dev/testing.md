# Testing Ill Goblin Gains

Verify by running the game, not just by reading the code. All commands go through `drive-game.ps1` in this folder. Run it from the PowerShell tool:

```powershell
& ".claude/skills/goblin-dev/drive-game.ps1" <command> [arg] [-Frames N] [-Count N] [-DelayMs N] [-KeyGapMs N]
```

Screenshots and logs land in `$env:TEMP\goblin-dev\`. Open screenshots with the Read tool to see them.

## Headless: every change, first

```powershell
& ".claude/skills/goblin-dev/drive-game.ps1" headless -Frames 20
```

This runs the full scene tree (every `_ready()`, `GameData` validation) with no window, then quits. A clean run prints only the Godot version banner. Parse errors, `Log.error` output (e.g. a trait failing validation), and script errors all show up here. To check runtime state, add a temporary `Log.info(...)` tagged `TEMP-`.

## Windowed: anything visual or input-driven

| Command | Does |
|---|---|
| `launch` | Starts the game (1280x720, borderless) and records its PIDs. Fails if a tracked game is already running. |
| `keys "enter, zoomin*2, w*4, wait"` | Sends keys to the window, `-KeyGapMs` apart (default 350, long enough for a turn's tween). `name*N` repeats. |
| `shot [path]` | DPI-correct screenshot of the game window. |
| `burst w -Count 6 -DelayMs 40` | Sends one key, then takes `Count` rapid screenshots. Use it to catch motion (shakes, tweens, rising text). |
| `status` | Whether the tracked processes are alive, plus the tail of the stdout/stderr logs. Use it when the window disappears. |
| `stop` | Stops **only** the processes `launch` recorded. |

Key names:
- **Movement:** `n ne e se s sw w nw` (bound to vi keys k u l n j b h y)
- **Turn and menus:** `wait` (`;`), `enter`/`space` (confirm), `menu` (C, the traits modal)
- **View and run:** `zoomin`/`zoomout` (`=`/`-`), `restart` (R)

A run starts on the **Run Start modal**, so send `enter` before anything else. The default zoom is far out; `zoomin*2` makes sprites and text easy to read. The goblin starts at the map's east edge, where the camera doesn't center on it, so walk a few tiles west for a centered view.

## Forcing hard-to-trigger cases

Random rolls and loadouts make features hard to observe. Force them temporarily, and tag every hack `TEMP-` so it can be found:
- **Force a trait:** in `GameManager._on_level_ready()`, before `apply_traits`, add `loadout.negative_trait_ids.assign(["allergies"])  # TEMP-` (or `positive_trait_ids`).
- **Force a chance proc:** set the trait's `one_in` to `1` in `project/data/traits.json`.
- **Prove a value is data-driven:** temporarily change the data (e.g. the burst `text`) and confirm the change shows up in game.
- **Prove a log or gameplay effect:** a `Log.info("TEMP- ...")` at the call site, then check it with `status` or the stdout log.

Before reporting, revert every hack and confirm none are left:

```bash
grep -rn "TEMP-" project/ ; git diff --stat
```

## Rules

- **Never kill Godot processes by name.** Ray may have the editor open. Use `stop`, which only touches the recorded PIDs.
- **Restart after code changes.** Scripts load at launch, so `stop` and then `launch` again; the in-game `restart` key doesn't reload scripts.
- **Report unexplained crashes.** If the game exits unexpectedly, check `status` first, then try to reproduce. If you can't explain it, say so in the report rather than leaving it out.
