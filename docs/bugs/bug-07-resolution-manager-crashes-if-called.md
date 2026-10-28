# Bug 07: `ResolutionManager.get_snapped_scale()` would crash

**Severity:** latent. Nothing calls it today; the first caller will crash.

## Cause
It reads `MapConfig.hud_margin_right`, which is commented out.

## Where
- `resolution_manager.gd` `get_snapped_scale()`
- `map_config.gd`, the commented-out `hud_margin_right`

## Fix direction
Either restore the HUD margin as a real config value, or take the margin out of the calculation until a HUD exists.

## Done when
- `get_snapped_scale()` runs without error.
- The "`ResolutionManager` would crash" Gotcha in [input-and-camera.md](../systems/input-and-camera.md#gotchas) is removed.
