# Bug 03: The camera follows one step behind

**Severity:** player-facing

## Symptom
The camera's dead-zone check runs on the cell the goblin just left, so the camera trails one move behind.

## Cause
`Player` emits `GameEvents.player_pos_updated(position)` while `position` is still where the sprite was before the move animation.

## Where
- `player.gd`, the two `player_pos_updated.emit` calls
- `camera.gd` `player_pos_updated()`

## Fix direction
Emit the destination, worked out from the goblin's cell (the cell's pixel center from `Constants`), not from the sprite's current position.

## Done when
- Crossing the dead-zone edge scrolls the camera on that same move.
- The "camera follows one step behind" Gotcha in [input-and-camera.md](../systems/input-and-camera.md#gotchas) is removed.
