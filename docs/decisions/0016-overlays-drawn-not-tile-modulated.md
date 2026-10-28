# 0016: Colored overlays are drawn on top of tiles; tile tinting is reserved for fog of war

**Status:** Accepted · 2026-06-10

## Context

Guard cones need to color the floor (green, yellow, red) in two intensities. The obvious tool, Godot's per-tile tint (`tile_data.modulate`), was already used for fog of war. But tinting *multiplies* a tile's colors: on the mansion's dark floor tiles, a colored tint barely shows, and stacking it with the fog dimming muddies both.

## Decision

- **Fog of war is the only thing that tints tiles.** Darkening and restoring a tile is exactly what multiplying is good at.
- **Every colored overlay is drawn,** as translucent rectangles in a node's `_draw()` above the tile layers, with real transparency. Guard cones are drawn this way by `VisionManager`.

## Alternatives considered

- **Tinting tiles for cones** (`tile_data.modulate`): rejected. Multiplying breaks on dark tiles and conflicts with the fog.

## Consequences

- Cone colors and opacities read the same on any tile, and they're tuned in one place.
- Future overlays (camera sweeps, smoke, highlights) follow the same pattern. This is enforced in `CLAUDE.md`'s Don'ts.
- Overlays have to respect fog themselves, by only drawing on `VISIBLE` cells ([0017](0017-nothing-leaks-through-fog-of-war.md)).

**Affects:** [systems/vision-and-fog.md](../systems/vision-and-fog.md), [`vision_manager.gd`](../../project/autoloads/vision_manager.gd), [`tile_util.gd`](../../project/scripts/util/tiles/tile_util.gd)
