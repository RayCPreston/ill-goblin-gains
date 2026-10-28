# Systems Overview

How the game works today, one page per system. Start here for the map of who owns what, then follow the links.

## Reading order

New to the code? Read [turn-and-grid](turn-and-grid.md), then [guards](guards.md) and [vision-and-fog](vision-and-fog.md). Those three are the core loop. The rest build on them.

| Page | Covers |
|---|---|
| [Turns and the Grid](turn-and-grid.md) | Turn order, grid lookups, `Entity` and moving, proximity, pathfinding |
| [Guards](guards.md) | PATROL / CURIOUS / ALERT, cones, sightings, tracking, capture |
| [Vision and Fog of War](vision-and-fog.md) | The goblin's view, fog states, drawing tiles, entities and cones |
| [Sound and Smell](sound-and-smell.md) | The flood fill, what makes noise, how guards react |
| [Doors](doors.md) | Closed / peeked / open, guards walking through, the sprite freeze |
| [Traits and GameData](traits-and-gamedata.md) | Loading, rolling, applying traits; the six effect kinds |
| [Run Lifecycle](run-lifecycle.md) | Load → reveal → play → capture or escape → restart |
| [VFX and Juice](vfx-and-juice.md) | Floating text, shake, the smell aura |
| [Input and Camera](input-and-camera.md) | Controls, the camera, the window, logging |

## Autoloads

Every manager is an autoload. Each one owns one responsibility, and the other code asks or tells it rather than doing its job. They're listed in load order (`project.godot`), which is the order their `_ready()` runs in.

| Autoload | Owns | Page |
|---|---|---|
| `Constants` | Tile size, direction vectors, cell↔pixel conversion, starting loadout counts | [turn-and-grid](turn-and-grid.md) |
| `GridManager` | Who and what is in each cell; moves, swaps, proximity notifications | [turn-and-grid](turn-and-grid.md) |
| `TurnManager` | Turn phase, running the world turn | [turn-and-grid](turn-and-grid.md) |
| `PlayerInput` | Turning key events into move / wait | [input-and-camera](input-and-camera.md) |
| `Log` | Leveled logging | [input-and-camera](input-and-camera.md) |
| `TileManager` | Terrain queries, bounds, the A* grid | [turn-and-grid](turn-and-grid.md) |
| `VisionManager` | Fog states, guard cones and their drawing | [vision-and-fog](vision-and-fog.md) |
| `MapConfig` | Map dimensions | [turn-and-grid](turn-and-grid.md) |
| `ResolutionManager` | Resolution scaling (unused for now) | [input-and-camera](input-and-camera.md) |
| `CameraInput` | Zoom keys → zoom requests | [input-and-camera](input-and-camera.md) |
| `GameEvents` | The global signal bus (no logic) | below |
| `WorldState` | World alert level, last known position, world-level tracking | [guards](guards.md) |
| `RunState` | MacGuffin held, run over and its outcome, the loadout | [run-lifecycle](run-lifecycle.md) |
| `VfxManager` | Spawning visual effects; the smell aura | [vfx-and-juice](vfx-and-juice.md) |
| `GameData` | Trait definitions: loading, validating, applying | [traits-and-gamedata](traits-and-gamedata.md) |
| `UiState` | Whether a modal is blocking input | [run-lifecycle](run-lifecycle.md) |
| `GameManager` | Run setup on level load, restart | [run-lifecycle](run-lifecycle.md) |

## Signals

**`GameEvents`** (global, for broadcasts where the sender doesn't know who's listening):

| Signal | Sent by | Heard by |
|---|---|---|
| `level_ready` | `Level` | `GameManager` |
| `loadout_rolled(loadout)` | `GameManager` | `RunStartModal`, `Player` |
| `run_ended(won, cause)` | `RunState` | `EndScreen` |
| `text_emitted(request)` | `Player` | `VfxManager` |
| `player_pos_updated(pos)` | `Player` | Camera |
| `zoom_in_requested` / `zoom_out_requested` | `CameraInput` | Camera |

**Entity signals** (an entity announcing its own change to the manager that tracks it):

| Signal | Sent by | Heard by |
|---|---|---|
| `turn_ended` | Every `Entity` | `TurnManager` (the player's) |
| `vision_updated(cells)` | `Player` | `VisionManager` |
| `cone_updated(...)` | `Guard` | `VisionManager` |
| `cell_state_changed` | `VisionManager` | Every `Entity` (to re-check its own visibility) |

The rules for choosing between a signal and a direct call are in the `/goblin-dev` skill.

---
*Last verified against code: `4822104` on 2026-10-28.*
