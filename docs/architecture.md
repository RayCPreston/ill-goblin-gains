# Architecture Reference

## Autoloads

| Autoload | Extends | Responsibility |
|---|---|---|
| `WorldState` | Node | Global alert level (NORMAL/ALERT, one-way ratchet), LKP (last known player position), predictive tracking (projects LKP along last-seen direction after guards lose sight) |
| `TurnManager` | Node | Turn phase (PLAYER/WORLD), player ref, world entity list. Calls `WorldState.tick_tracking()` after all entities act during ALERT |
| `GridManager` | Node | `_actors` dict, `_furniture` dict (both keyed by `Vector2i`), player reference, proximity notifications |
| `TileManager` | Node | `TileMapLayer` refs, walkability/opacity queries, `AStarGrid2D` pathfinding |
| `VisionManager` | Node2D | Player FOV state, guard cone data, `_draw` cone rendering (z_index 3) |
| `GameEvents` | Node | Global signals (`player_pos_updated`, zoom, `sound_emitted`) |
| `MapConfig` | Node | Map tile dimensions, pixel size helpers |
| `Constants` | Node | `TILE_SIZE = 16`, direction vectors |
| `PlayerInput` | Node | Input action mapping |
| `CameraInput` | Node | Camera zoom/pan input |
| `Log` | Node | Logging wrapper |
| `ResolutionManager` | Node | Resolution handling |
| `VfxManager` | Node2D | Listens for VFX-trigger signals (`GameEvents.sound_emitted`), instances real-time effect nodes as children |

## Entity Hierarchy

All actors and furniture inherit `Entity`. Key fields: `cell: Vector2i`, `can_be_remembered`, `blocks_vision`, `can_overlap`, `is_furniture`.

- **Player** — Registers with `GridManager.register_player()`, `VisionManager`, and `TurnManager`. 360° symmetric shadowcasting FOV (Björn Bergström/Albert Ford algorithm).
- **Guard** — Physical entity with facing, directional FOV, and movement. Behavioral logic lives in `GuardStateMachine`. Vision computation in `GuardFov`. Public movement API: `step_along_path()`, `navigate_to()`, `choose_destination()`, `clear_path()`, `face_toward()`.
- **Door** — `is_furniture = true`. Proximity-driven open/peeked/closed states. Peeked blocks vision but `allows_player_vision = true`. Guards cannot yet open doors.

## Guard System

### Utility Classes (scripts/util/actors/guard/)

**`GuardFov`** (RefCounted) — Computes inner/outer vision zones. `compute(origin, facing, half_arc_degrees)` returns `[inner: Array[Vector2i], outer: Array[Vector2i]]`. When `half_arc_degrees >= 180.0`, arc check is skipped (full 360° vision). Uses Bresenham-style LOS sampling. Chebyshev distance for range (INNER_RANGE, OUTER_RANGE).

**`GuardStateMachine`** (RefCounted) — Owns all guard behavioral logic. Constructed with a Guard reference. `process_turn()` is called by `Guard.take_turn()`.

### State Machine

Uses generic `StateMachine` (scripts/util/state_machine.gd) — RefCounted, int-keyed (enum-friendly), with `register(state, on_execute, on_enter, on_exit)` callbacks.

**States:**

| State | Vision | Cone Color | Segmented | Behavior |
|---|---|---|---|---|
| PATROL | Directional (55° arc) | Green | Yes | Random walkable destination, full map range |
| CURIOUS | 360° | Yellow | Yes | Navigate to POI, revert to PATROL on arrival if player not found |
| ALERT | 360° | Red | No | Converge on LKP if known, short-range erratic search if cleared |

**Transitions:**
- PATROL → CURIOUS: outer cone detects player. Saves `poi` (player cell) and `patrol_target` (guard's current cell).
- CURIOUS → PATROL: reaches POI, player not found. Returns to `patrol_target`. Also triggers if POI unreachable.
- Any → ALERT: inner cone detection (sets LKP via `WorldState.set_lkp()`), OR `WorldState.alert_level` is already ALERT (another entity triggered it).
- ALERT is permanent for the run. Never reverts.

**World escalation:** Every guard checks `WorldState.alert_level` at the top of each turn. If the world is ALERT, the guard transitions to ALERT regardless of current state.

### Detection

Detection runs after vision is computed each turn. Checks if player cell is in inner or outer zone arrays.

- Inner detection → `WorldState.set_lkp(player_cell, direction)`, guard enters ALERT.
- Outer detection in PATROL → guard enters CURIOUS, sets POI.
- Outer detection in CURIOUS → updates POI, clears path.
- Outer detection in ALERT → updates LKP with direction.

### Predictive Tracking

Two layers prevent guards from instantly abandoning pursuit when the player rounds a corner:

**Guard-level (CURIOUS):** Each guard records the player's movement direction while it has eyes on. On LOS break, projects `poi` forward along that vector once per turn for `TRACKING_MEMORY` turns (default 3). Stops early if projection hits an unwalkable tile.

**WorldState-level (ALERT):** Guards pass direction to `set_lkp()`. After all guards run, `TurnManager` calls `WorldState.tick_tracking()`. If any guard saw the player this turn (`_has_eyes_on` flag), tracking skips — real sighting data beats projection. Otherwise, projects `lkp` forward one cell per turn for `TRACKING_MEMORY` turns.

### LKP Convergence

When `WorldState.has_lkp` is true, all ALERT guards navigate toward `WorldState.lkp`. If LKP changes (player re-spotted), guards repath automatically (`destination != WorldState.lkp` check). First guard to reach LKP clears it. After clearing, guards switch to short-range random destinations (`ALERT_SEARCH_RANGE = 8` Chebyshev distance) for erratic searching behavior. Other guards mid-path toward the old LKP finish walking there before searching.

## Vision Rendering

### Player FOV
`tile_data.modulate` applies VISIBLE/REMEMBERED/UNSEEN states. Multiplicative blending works here because it's darkening/restoring tile appearance, not adding color.

### Guard Cones
`VisionManager` extends `Node2D`. `_draw()` paints `Rect2` overlays with real alpha compositing on top of tiles. `_guard_cones` dictionary keyed by Guard reference, values: `{ "inner": Dictionary, "outer": Dictionary, "color": Color, "is_segmented": bool }`. Inner/outer are cell dictionaries (keyed by `Vector2i`, value `true`) for O(1) lookup.

- Cones only render on VISIBLE tiles (not through fog of war).
- Wall tiles excluded from cone tint (presentation-only; cone data still includes walls for detection queries).
- When `is_segmented` is false (ALERT), outer alpha matches inner — uniform intensity.

## VFX (Juice)

Real-time, turn-independent presentation layer — distinct from every other system, which resolves instantly in tile/turn space. Nodes animate over wall-clock seconds via `_process(delta)` rather than `RefCounted` calculate-and-return utilities.

- **Trigger:** gameplay code emits a `GameEvents` signal (e.g. `sound_emitted(world_position, pixel_radius)`) alongside its instant gameplay resolution — never instances VFX nodes directly, keeping presentation decoupled from gameplay.
- **`VfxManager`** (autoload, `Node2D`) listens for those signals and instances the corresponding effect script as a child at the given world position. Also owns a single persistent `SmellAura` (see below), lazily created once a player exists and repositioned every frame to the player's current world position — smell isn't event-triggered, it's just always there.
- **`SoundPulse`** (`scripts/vfx/sound_pulse.gd`, `Node2D`) — grows a ring from radius 0 to a target over `DURATION` seconds, fading alpha alongside, via `_draw()`; frees itself on completion. Spawned on every completed player move at `Player.noise_radius * Constants.TILE_SIZE`. Multiple concurrent pulses are expected and independent (no debouncing).
- **`SmellAura`** (`scripts/vfx/smell_aura.gd`, `Node2D`) — a `ColorRect` + `ShaderMaterial` (`resources/shaders/smell_aura.gdshader`) rendering a constant, subtle orange haze plus a handful of wavy "stink lines" radiating outward, sized to `Player.smell_radius * Constants.TILE_SIZE`. The fragment shader works in polar coordinates (angle/distance from center): picks the nearest of `line_count` evenly-spaced arm angles, perturbs each arm sideways with a `sin(dist * frequency + TIME * speed)` wave for the wobble, and fades each line in near the center and out before the edge so it reads as organic wisps rather than a rigid starburst. Both the haze and line alphas are kept low by design — this is meant to be noticeable but not distracting.
- **Smell as a stat, not a trait (yet):** `Player.smell_radius` (default `4`) exists the same way `noise_radius` did before any trait system — a hardcoded stat driving both the visual above and a gameplay hook, `Player._emit_smell()`, which runs the same `ProximityAlert` BFS as `_emit_noise()` but fires every turn (`move_to()` and `wait()`), not just on movement, matching the GDD's `on_turn_end` hook-trait shape. No `Smelly` trait exists yet to gate this — it's always on, purely to preview the mechanic and art direction ahead of the Trait & Equipment System.

## Pathfinding

`AStarGrid2D` on `TileManager`, built once after layers are set. `DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES` prevents squeezing through wall corners. `HEURISTIC_OCTILE` for 8-direction grids. `find_path(from, to)` returns `Array[Vector2i]` with origin stripped.

## Facing

8-direction `Facing` enum on Guard (not Entity — player has no facing). Values are degree angles used directly by `GuardFov._in_arc`:

```
NORTH=270, NORTH_EAST=315, EAST=0, SOUTH_EAST=45,
SOUTH=90, SOUTH_WEST=135, WEST=180, NORTH_WEST=225
```

`face_toward()` uses `atan2` → iterate all Facing values → pick closest by angular delta.

## What's Not Yet Implemented
- Guard state machine for dogs (same Guard class, no segmented cone, increased hearing radius, can't open doors)
- Patrol routes — removed from scope; random destinations (overridden by POI in CURIOUS and LKP/range-clamped destinations in ALERT) are working well and considered sufficient
- WorldState.ALERT driven by non-guard entities (cameras, laser traps — architecture supports it, no entities exist yet)
- Procedural generation (design in `docs/procgen.md`, not blocking current work)
- Inventory / MacGuffin pickup (placeholder only — see `CLAUDE.md`)
