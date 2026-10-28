# Bug 04: The view doesn't update when a guard opens or closes a door

**Severity:** player-facing

## Symptom
- When a guard opens a door, the goblin can't see through it until the goblin next moves or waits.
- When a guard closes a door, the goblin keeps seeing through it.

## Cause
The player's field of view is recomputed only in `Player.move_to()` and `Player.wait()`.

## Where
- `Player._compute_fov()`
- `door.gd`

## Fix direction
When something that blocks vision changes, it tells a manager, and the manager has the player's view recomputed. The door shouldn't call the player directly.

## Done when
- A door a guard opens or closes inside the goblin's view changes what the goblin sees on that same turn.
- The "door changes don't update your view" Gotchas in [vision-and-fog.md](../systems/vision-and-fog.md#gotchas) and [doors.md](../systems/doors.md#gotchas) are removed.
