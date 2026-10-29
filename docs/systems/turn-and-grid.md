# Turns and the Grid

The game is a grid of 16×16 tiles, and time moves in turns: the goblin acts, then every guard acts, then it's the goblin's turn again. Everything (where things are, what blocks what, who's next to whom) is answered by looking cells up in dictionaries. There's no physics engine anywhere.

## How it works

### A turn

1. **The goblin acts.** Input is only accepted on the goblin's turn, with no modal open and the run not over. Before the action resolves, guards check whether the goblin is already in their cones ([guards.md](guards.md#order-within-a-turn)). Then the goblin either waits or tries to move one cell in one of eight directions.
2. **The action ends the turn.** Every attempt ends the turn, whether it moves, waits, bumps a wall, or interacts. `end_turn()` emits `turn_ended`.
3. **`TurnManager` runs the world turn.**
   - Every registered world entity takes its turn, in the order it registered (today that's only guards).
   - If the world is in ALERT, `WorldState` advances its last-known-position prediction.
   - Disguise's per-turn bookkeeping runs.
   - Then it's the goblin's turn again.

The whole world turn runs instantly, within the same frame as the keypress. Movement *animation* happens afterwards: each entity's sprite slides to its new cell over 0.3s, and a new move cuts any slide in progress short. So rapid keypresses are never queued behind animation.

### Sleeping

Any entity can be put to sleep for a number of turns with `fall_asleep(turns, text)`. `is_sleeping` stays true until those turns are spent. Today only Narcolepsy uses it, on the goblin.

The world still waits for the player while the goblin sleeps ([0020](../decisions/0020-sleeping-turns-wait-for-input.md)). Any move or wait input spends one slept turn (`sleep_through_turn()`) instead of doing what was pressed: the goblin stays put, the guards' pre-move sighting check runs as on any other turn, the sleep text (`*snooze*`) floats off the sleeper, and the goblin waits. A slept turn counts as waiting for Statue, and Fidgety still makes noise. The sleep text also appears the moment the goblin falls asleep, and the sprite tips onto its side until it wakes ([vfx-and-juice](vfx-and-juice.md#sleep-tip-over)). Falling asleep again mid-sleep keeps the longer count, so a sleep is never cut short.

### The grid

Positions are `Vector2i` cells. `Constants` converts between cells and pixels, including a cell's center. The map is 72×45 cells (`MapConfig`).

Two managers answer every spatial question:

| Question | Asked of | Answer comes from |
|---|---|---|
| Is this cell floor? Does it block sight? Is it on the map? | `TileManager` | The tile layers' custom data (`is_walkable`, `is_opaque`), and the map bounds |
| Who's standing here? What furniture is here? | `GridManager` | Two dictionaries keyed by cell: actors (the goblin, guards) and furniture (doors, the chest) |
| Can something step here? | `GridManager.is_cell_available()` | Walkable floor, no blocking actor, no furniture that can't be overlapped |
| How do I get there? | `TileManager.find_path()` | A* over the static terrain only |

### Entities

Everything on the grid inherits `Entity`. When it loads, it registers itself in the actor or furniture dictionary by its cell. When it's removed, it unregisters. A handful of flags describe how it behaves on the grid:

| Flag | Meaning |
|---|---|
| `is_furniture` | Lives in the furniture dictionary instead of the actor one |
| `can_overlap` | Others may step onto its cell (doors) |
| `is_interactable` | Moving into it calls its `interact()` instead of being blocked (guards, the goblin, the chest) ([0013](../decisions/0013-bumping-is-how-actors-interact.md)) |
| `can_swap` | Moving into it swaps the two (supported; nothing uses it yet) |
| `blocks_vision` / `allows_player_vision` | Sight and sound blocking (doors) |
| `can_be_remembered` | Stays drawn, dimmed, in fog of war (see [vision-and-fog.md](vision-and-fog.md)) |

A move attempt (`try_move_to`) checks the target cell in this order:
1. furniture that can't be overlapped: interact with it if it's interactable, otherwise blocked;
2. an occupant that can swap;
3. an occupant that's interactable: interact with it;
4. a free cell: move.

Whatever happens, the turn ends. A successful move updates the dictionaries, then sends **proximity notifications** to everything around both the old and new cells (`on_proximity_changed`): **overlapped**, **adjacent**, or **none**. Adjacent means orthogonal neighbors only. Doors (open, peek, close) and Cat Burglar's chest pickup run on these.

### Pathfinding

`TileManager` builds one A* grid when the level loads: walls are solid, diagonal steps are allowed only when neither orthogonal neighbor is blocked (no corner cutting), and distances use the octile heuristic. It knows only the terrain. Actors are checked at the moment of each step (`is_cell_available`), never baked into the grid. That's how guards handle each other: if the next step is occupied, they drop the path and re-plan next turn.

## Key pieces

| Piece | Where | Role |
|---|---|---|
| `TurnManager` | [`autoloads/turn_manager.gd`](../../project/autoloads/turn_manager.gd) | Turn phase, the player's turn, running the world turn in registration order |
| `GridManager` | [`autoloads/grid_manager.gd`](../../project/autoloads/grid_manager.gd) | Actor and furniture dictionaries, moves, swaps, availability, proximity notifications |
| `TileManager` | [`autoloads/tile_manager.gd`](../../project/autoloads/tile_manager.gd) | Terrain queries, bounds, the A* grid, refreshing fog on the tile layers |
| `Entity` | [`actors/entity.gd`](../../project/scripts/actors/entity.gd) | Registration, the move-attempt order, the movement tween, flags, `shake()`, sleep |
| `Constants` / `MapConfig` | [`autoloads/constants.gd`](../../project/autoloads/constants.gd), [`autoloads/map_config.gd`](../../project/autoloads/map_config.gd) | Tile size, direction vectors, cell↔pixel conversion; map dimensions |

## Extending it

- **A new thing on the map:** inherit `Entity`, set its flags in `_ready()` before calling `super()` (that's when it registers), and react to neighbors in `on_proximity_changed()`.
- **A new thing that takes turns** (cameras, dogs): register with `TurnManager.register_world_entity()` and implement `take_turn()`, ending with `end_turn()`.
- **New terrain properties** (e.g. noisy floors): add custom data to the tile set and a query on `TileManager`, the same way `is_walkable` and `is_opaque` work.
- **Never** use Godot physics, and never bake moving things into the A* grid ([0018](../decisions/0018-grid-dictionaries-no-physics.md)).

## Gotchas

- **The goblin can cut corners; guards and sound can't.** The goblin's moves only check the target cell, so it can step diagonally between two walls that touch at a corner. Guards path with A*, which forbids that, and sound's flood fill forbids it too.
- **Adjacent excludes diagonals.** Anything driven by proximity, like doors peeking or Cat Burglar, ignores diagonal neighbors.
- **Animation lags logic.** An entity's `cell` is already the new cell while its sprite is still sliding there. Anything placed by position mid-slide uses the old spot; floating text anchors to the cell for this reason.
- **The A* grid is built once per level.** Terrain that changes during a run (breakable walls, locked doors) would have to update it.

## Not built yet

- **Map size following resolution** (GDD): `MapConfig.calculate_map_dimensions()` exists, with limits from 40×20 to 100×60, but nothing calls it. The map is always 72×45.
- **Stairs and multiple floors** (GDD: two floors, stairs crossed in one turn).
- **Guards trading places** when they meet (GDD): swapping is supported by the grid, but guards just wait.
- **Sleeping guards** (e.g. a sleeping dart): sleep state and its text live on `Entity`, but only the goblin's input spends slept turns. `TurnManager` would need to call `sleep_through_turn()` instead of `take_turn()` for a sleeping guard, and its vision would need to switch off.

---
*Last verified against code: `523d19e` (+ the Narcolepsy branch) on 2026-10-28.*
