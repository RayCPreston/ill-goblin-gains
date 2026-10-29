# 0021: Map knowledge is its own vision state, `MAPPED`

**Status:** Accepted · 2026-10-29

## Context

The Blueprint shows the goblin the floor's layout without the goblin seeing it. The natural move is to mark those cells `REMEMBERED`, since remembered tiles already have the dimmed look the design asks for. But `REMEMBERED` also means "seen before": static entities on remembered cells, like furniture and the chest, are drawn dimmed where they were seen. Marking mapped cells `REMEMBERED` would put the chest on screen across the map, breaking [0017](0017-nothing-leaks-through-fog-of-war.md).

## Decision

Add a fourth vision state, `MAPPED`, between `UNSEEN` and `REMEMBERED`: the layout is known, but nothing on the cell has been seen.
- **Tiles** on mapped cells look exactly like remembered ones.
- **Entities** on mapped cells are hidden, unless they're part of the layout (`Entity.is_layout`, set by doors), which are shown dimmed.
- **Memory** treats it like `UNSEEN`: seeing a mapped cell makes it `VISIBLE`, then `REMEMBERED`. A map never downgrades a cell that's already been seen.

## Alternatives considered

- **Mark mapped cells `REMEMBERED` and check for the Blueprint when drawing entities:** rejected. It branches on an item, and the fog code would need to know which cells came from a map anyway, so the state belongs in the vision data.
- **Keep three states and add a separate "seen" set beside them:** rejected. Every reader would have to combine two lookups. A fourth state keeps one answer per cell, and the existing `match` statements show exactly where it needs handling.

## Consequences

- Anything that matches on `VisionState` has to handle `MAPPED`. Today that's `Entity.refresh_visibility()` and `VisionManager.get_cell_color()`. Checks for `== VISIBLE` (cones, floating text, guards, the door sprite freeze) need no change.
- Information traits treat a mapped cell like a never-seen one. Eavesdropper's `?` shows on a mapped cell exactly when it would on an unseen one, so a map neither reveals guards nor limits what a trait already detects (confirmed with Ray, 2026-10-29).
- Future layout features (stairs, exits) opt in with `is_layout`. Future mapping items (another floor, a partial map) reuse `PlayerFov.map()`.

**Affects:** [systems/vision-and-fog.md](../systems/vision-and-fog.md), [systems/equipment.md](../systems/equipment.md), [systems/doors.md](../systems/doors.md), [`player_fov.gd`](../../project/scripts/util/actors/player/player_fov.gd), [`entity.gd`](../../project/scripts/actors/entity.gd)
