# Bug 09: `swap_entities()` uses type inference

**Severity:** cleanup

## Cause
`var cell_a := ...` and `var cell_b := ...` break the explicit-types convention.

## Where
`grid_manager.gd` `swap_entities()`

## Fix direction
Declare both as `Vector2i`.

## Done when
`grid_manager.gd` has no `:=`.
