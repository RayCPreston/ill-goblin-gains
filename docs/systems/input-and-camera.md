# Input and Camera

The goblin is moved with vi-style keys, one key per direction. The camera starts zoomed out to show the whole mansion. Zooming in makes it follow the goblin, re-centering only when the goblin nears the edge of the screen.

## How it works

### Controls

| Action | Key | Input action |
|---|---|---|
| Move N / S / W / E | K / J / H / L | `move_n` / `move_s` / `move_w` / `move_e` |
| Move NW / NE / SW / SE | Y / U / B / N | `move_nw` / `move_ne` / `move_sw` / `move_se` |
| Wait | `;` | `wait` |
| Zoom in / out | `=` / `-` | `zoom_in` / `zoom_out` |
| Traits screen (toggle) | C | `character_menu` |
| Inventory (toggle) | I | `inventory` |
| Start the run (reveal screen); use the inspected item (inventory) | Enter or Space | `confirm` |
| Restart | R | `restart` |
| View a trait or item (its screen open) | 1–9 | Read directly from the key, not from an input action |

Keys are bound by **physical position**, so the layout stays the same on non-QWERTY keyboards. Each action has exactly one key, apart from `confirm`.

### Who handles what

Each listener handles only its own actions, in `_unhandled_input()`:

| Listener | Handles |
|---|---|
| `Player` | Move and wait, translated by `PlayerInput`. Only accepted on the player's turn, with no modal open and the run not over (see [run-lifecycle.md](run-lifecycle.md#2-play)) |
| `CameraInput` (autoload) | Zoom keys. It emits `GameEvents.zoom_in_requested` / `zoom_out_requested` and never touches the camera directly |
| `GameManager` | Restart, at any time |
| `TraitsModal` / `InventoryModal` / `RunStartModal` | C, I, the number keys, and confirm, while they're relevant |

### Camera

The camera (`scenes/levels/camera.tscn`) has four zoom levels:
- **Level 0** (the default) shows the whole 72×45 map at 1:1, centered, and doesn't follow anything.
- **Levels 1–3** magnify to 2×, 3× and 4×, and follow the goblin.

Following uses a **dead zone**, 15 × 6 tiles at 1:1, shrinking as you zoom. The camera stays still while the goblin moves inside it. When the goblin crosses its edge, the camera slides to bring the goblin back in, with room to see ahead. When zoomed in, the camera never shows beyond the map's edges. At level 0, the map is simply centered, with margins at the sides. Zoom changes and slides ease over a third of a second.

The camera learns where the goblin is from `GameEvents.player_pos_updated`, which the goblin emits after each move and once at startup.

### Window

The window is 1280×720, borderless and not resizable. Godot's integer stretch mode keeps pixels crisp by scaling only in whole-number steps.

### Logging

`Log` (autoload) wraps output with levels: `debug`, `info`, `warn`, `error`. The current level is `DEBUG`, so everything prints. Warnings and errors also go to Godot's debugger. `GameData` uses `Log.error` for traits that fail validation.

## Key pieces

| Piece | Where | Role |
|---|---|---|
| Input map | [`project.godot`](../../project/project.godot) `[input]` | Every action and its key |
| `PlayerInput` | [`autoloads/player_input.gd`](../../project/autoloads/player_input.gd) | Turns an event into MOVE / WAIT / NONE and a direction |
| `CameraInput` | [`autoloads/camera_input.gd`](../../project/autoloads/camera_input.gd) | Zoom keys → zoom requests |
| Camera | [`level/camera.gd`](../../project/scripts/level/camera.gd) | Zoom levels, dead-zone following, edge clamping. The dead zone size and speed are exported settings |
| `ResolutionManager` | [`autoloads/resolution_manager.gd`](../../project/autoloads/resolution_manager.gd) | Unused; see Gotchas |
| `Log` | [`autoloads/log.gd`](../../project/autoloads/log.gd) | Leveled logging |

## Extending it

- **A new key:** add an action to the input map. Handle it in whichever single listener owns it. If something elsewhere needs to react, emit a `GameEvents` request (as zoom does) instead of reaching across.
- **Alternate bindings** (arrow keys, numpad): add more events to the existing actions. `PlayerInput` works from action names, so nothing else changes.
- **Different screen sizes:** that's the not-yet-built resolution work below. It ties together `ResolutionManager`, `MapConfig.calculate_map_dimensions()` and the camera's base scale.

## Gotchas

- **The camera follows one step behind.** The goblin emits its position before its move animation starts, so `player_pos_updated` carries the cell it just *left*. The dead-zone check therefore runs on the previous position.
- **`ResolutionManager` would crash if called.** `get_snapped_scale()` reads `MapConfig.hud_margin_right`, which is commented out. The camera's call to it is commented out too (base scale is hard-coded to 1), so it never runs.
- **No alternate keys.** Arrow keys and the numpad do nothing.

## Not built yet

- **Configurable resolution and map size** (GDD): resolution-dependent scale, a map sized to the screen, and a HUD margin. The pieces exist but aren't wired up.
- **The minimal HUD** (GDD): a turn indicator and a world-state indicator.
- **Rebinding keys, and settings** (part of the main menu work).

---
*Last verified against code: `4822104` on 2026-10-28.*
