# Vision and Fog of War

The goblin sees all the way around, out to 15 tiles, wherever walls allow. What's in view right now is fully lit. Places seen before stay on the map, dimmed, as memory. Places never seen are black, unless a map (the Blueprint) has shown their layout. Guards are only shown while in view, and their cones are painted over the tiles you can see.

## How it works

### What the goblin sees

`PlayerFov` uses **symmetric shadowcasting**: four quadrant scans that sweep outward row by row, splitting into narrower slices whenever an opaque cell casts a shadow.
- **Symmetric:** if the goblin can see a cell, something standing on that cell would also have line of sight back to the goblin.
- **Range:** distance counts diagonals as one step, so the visible area is roughly square:
  - 15 tiles by default (`max_range`);
  - Keen Eyes +3, Nearsighted −3;
  - Far-Sighted sets `min_range` 2, making a blind ring right around the goblin (the goblin's own cell stays visible).
- **What blocks sight:**
  - wall tiles marked opaque;
  - vision-blocking furniture: a closed door blocks it, but a peeked door doesn't, because peeking means the goblin is standing beside it.
  - The blocking cell itself is shown, so you see walls, not just the space in front of them.

Every cell is in one of four states:

| State | Means | Tiles look |
|---|---|---|
| `VISIBLE` | In view this turn | Full color |
| `REMEMBERED` | Seen before, not now | Dimmed to 40% |
| `MAPPED` | Never seen, but its layout is known from a map | Dimmed to 40% |
| `UNSEEN` | Never seen | Black |

Memory is permanent: each recompute turns last turn's `VISIBLE` cells into `REMEMBERED`, then marks the new view. `PlayerFov.map()` turns `UNSEEN` cells into `MAPPED` and never touches a cell already seen. Seeing a mapped cell later makes it `VISIBLE` as usual ([0021](../decisions/0021-mapped-is-its-own-vision-state.md), [equipment.md](equipment.md)). Vision is recomputed when the goblin **moves or waits**. Bump turns don't recompute, since the goblin hasn't moved.

### How it's drawn

- **Fog on tiles:** the floor and wall layers use `TileUtil`, which re-colors every tile from its vision state through Godot's per-tile runtime update. Tile coloring is used *only* for fog ([0016](../decisions/0016-overlays-drawn-not-tile-modulated.md)).
- **Entities:** listen for `VisionManager.cell_state_changed` and update themselves.
  - In view: shown normally.
  - Remembered: furniture is shown dimmed; guards are hidden (`can_be_remembered = false`), so you never see a guard's stale position.
  - Mapped: hidden, unless the entity is part of the layout (`is_layout`, set by doors), which is shown dimmed. Nothing on a mapped cell has actually been seen.
  - Never seen: hidden.
  - Two overrides: Eavesdropper's `?` guards ([traits-and-gamedata.md](traits-and-gamedata.md)), and doors, which freeze their sprite while out of view ([0017](../decisions/0017-nothing-leaks-through-fog-of-war.md)).
- **Guard cones:** `VisionManager` paints semi-transparent squares in its own `_draw()`, above the tiles (`z_index` 3), below doors (10) and actors (20).
  - **Color:** green, yellow or red by guard state.
  - **Opacity:** 35% in the inner zone and 15% in the outer; ALERT cones are 35% throughout.
  - **Where:** only on cells currently `VISIBLE`, and only for guards that are themselves currently shown.

### Data flow

1. `Player._compute_fov()` emits `vision_updated(cells)`.
2. `VisionManager` stores the cells, asks `TileManager` to refresh tile colors, and emits `cell_state_changed`.
3. Each guard emits `cone_updated` after every vision recompute. `VisionManager` stores the cone and redraws.

## Key pieces

| Piece | Where | Role |
|---|---|---|
| `PlayerFov` | [`util/actors/player/player_fov.gd`](../../project/scripts/util/actors/player/player_fov.gd) | Shadowcasting, memory, `max_range` / `min_range`, `map()` |
| `VisionManager` | [`autoloads/vision_manager.gd`](../../project/autoloads/vision_manager.gd) | Holds the vision states and guard cones, draws the cones, and broadcasts `cell_state_changed`. Colors and opacities are at the top |
| `TileUtil` | [`util/tiles/tile_util.gd`](../../project/scripts/util/tiles/tile_util.gd) | Script on the floor and wall layers that applies fog colors to tiles |
| `Entity.refresh_visibility()` | [`actors/entity.gd`](../../project/scripts/actors/entity.gd) | Default show/dim/hide per state; overridden by `Guard` and `Door` |
| `Guard.cone_updated` | [`actors/guard.gd`](../../project/scripts/actors/guard.gd) | Cone data for drawing; see [guards.md](guards.md) for how cones are computed |

## Extending it

- **Anything new on the map** (cameras, lasers, items) gets `refresh_visibility()` from `Entity`. Set `can_be_remembered` deliberately: `true` for static things, which you'd remember, and `false` for anything that moves, which shouldn't be shown where it used to be. Set `is_layout` only for things a floor plan would show (doors; later stairs and exits).
- **A new overlay** (camera sweeps, smoke): draw it the way cones are drawn, as translucent shapes in `_draw()` limited to `VISIBLE` cells. Never tint tiles ([0016](../decisions/0016-overlays-drawn-not-tile-modulated.md)).
- **Anything that changes what the player sees, or that animates:** ask whether it could reveal something happening in unseen space. If it could, gate it on `VISIBLE` ([0017](../decisions/0017-nothing-leaks-through-fog-of-war.md)).

## Gotchas

- **Walls inside a cone get tinted.** The cone includes the wall cell a guard's line of sight stops at, and the drawing doesn't skip walls.
- **`?` guards show their cones.** A guard revealed only as a `?` counts as shown, so its cone is drawn on any visible cells it covers. That gives away more than the `?` alone: it shows the guard's state color and facing.
- **Door changes don't update your view immediately.** When a door changes state because of a guard, your field of view isn't recomputed until you next move or wait.
- **Every vision or cone update refreshes every tile.** `TileManager.notify_vision_update()` re-runs the fog coloring over the whole layer. That's fine at the current map size; watch it if maps grow a lot.

## Not built yet

- **Security cameras' cones,** which the GDD colors by world state rather than by guard state.
- **Dogs' unsegmented cones.**

---
*Last verified against code: `f924e6c` (+ the feature/equipment-item-system branch) on 2026-10-29.*
