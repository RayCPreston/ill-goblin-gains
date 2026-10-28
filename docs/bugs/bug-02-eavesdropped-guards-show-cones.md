# Bug 02: Eavesdropper's `?` guards still show their cones

**Severity:** player-facing

## Symptom
A guard behind a wall that shows only as a `?` still has its cone drawn on any visible tiles it covers. That gives away its state color and facing, which breaks [0017](../decisions/0017-nothing-leaks-through-fog-of-war.md).

## Cause
`VisionManager._draw()` draws a cone for every guard that's shown, and a `?` guard counts as shown.

## Where
- `VisionManager._draw()`
- `Guard.refresh_visibility()`

## Fix direction
Draw a guard's cone only when the guard itself is `VISIBLE`, not when it's only eavesdropped.

## Done when
- With Eavesdropper, a `?` guard's cone is never drawn, including on tiles the goblin can see.
- The "`?` guards show their cones" Gotcha in [vision-and-fog.md](../systems/vision-and-fog.md#gotchas) is removed.
