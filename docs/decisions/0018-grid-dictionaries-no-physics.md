# 0018: All spatial state lives in grid dictionaries; no physics; pathfinding knows only terrain

**Status:** Accepted · 2026-05-18

## Context

The game is a turn-based roguelike on a 16×16 tile grid. Things only ever occupy whole cells and move one cell per turn. Godot offers a physics engine (bodies, collision, areas) and an A* grid that can mark cells solid.

## Decision

- **No physics, for anything.** Positions are `Vector2i` cells.
- **Grid dictionaries:** `GridManager` keeps actors and furniture in dictionaries keyed by cell, so "who's here?" is a single O(1) lookup. `TileManager` answers terrain questions from tile custom data.
- **Pathfinding knows only static terrain.** Walls are solid in the A* grid. Moving things (actors) are never baked in; they're checked at the moment of each move with `GridManager.is_cell_available()`.

## Alternatives considered

- **Godot physics and collision:** continuous simulation a whole-cell, turn-based game doesn't need, and harder to reason about turn by turn.
- **Baking actors into the A* grid as solid cells:** the grid would have to be rebuilt every time anything moved.

## Consequences

- Every spatial question is a cell lookup, and turn resolution is deterministic and instant.
- Blocking by other actors is handled when a move is attempted (guards drop their path and re-plan), not during planning.
- Both rules are enforced in `CLAUDE.md`'s Core Conventions and Don'ts.

**Affects:** [systems/turn-and-grid.md](../systems/turn-and-grid.md), [`grid_manager.gd`](../../project/autoloads/grid_manager.gd), [`tile_manager.gd`](../../project/autoloads/tile_manager.gd)
