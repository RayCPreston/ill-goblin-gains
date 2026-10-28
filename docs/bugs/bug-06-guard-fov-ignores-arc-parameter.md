# Bug 06: `GuardFov` ignores its arc parameter

**Severity:** latent. Nothing goes wrong today because only 55° and 360° cones exist, but a dog or camera passing a different arc would still get 55°.

## Cause
`_in_arc()` compares against the `HALF_ARC_DEGREES` constant instead of the `half_arc_degrees` passed to `compute()`.

## Where
`guard_fov.gd` `_in_arc()`

## Fix direction
Pass `half_arc_degrees` through to `_in_arc()`.

## Done when
- `compute()` with a non-default arc produces a cone of that width.
- The "arc parameter" Gotcha in [guards.md](../systems/guards.md#gotchas) is removed.
