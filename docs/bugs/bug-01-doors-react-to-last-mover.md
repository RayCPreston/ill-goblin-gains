# Bug 01: Doors react only to the last mover nearby

**Severity:** player-facing

## Symptom
- A guard passing diagonally near a door closes it, even while the goblin is peeking through it or standing in it, and the goblin loses that view.
- A guard walking up orthogonally doesn't open a door the goblin is peeking.

## Cause
A door sets its state from whichever entity most recently sent it a proximity notification, not from everyone currently near it.

## Where
- `door.gd` `on_proximity_changed()`
- `GridManager.notify_entity_moved()`, which sends the notifications

## Fix direction
On any proximity change, work out the door's state from every actor currently in its cell or orthogonally next to it. Open beats peek, and peek beats closed.

## Done when
- A guard passing nearby never closes a door the goblin is peeking or standing in.
- A guard stepping next to a peeked door opens it.
- The "last mover decides" Gotcha in [doors.md](../systems/doors.md#gotchas) is removed.
