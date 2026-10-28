# 0019: Doors open and close by proximity, and the goblin can peek through them

**Status:** Accepted · 2026-05-23

## Context

The GDD says doors close automatically behind the player and any guards. Doors also had to interact with stealth: blocking sight while closed, and letting the goblin get through without a separate "open door" action costing turns.

## Decision

Doors have no open action. They react to grid proximity notifications:
- open while anyone stands in them;
- **peeked** when the goblin is orthogonally next to one;
- closed otherwise.

A peeked door lets the goblin see through it but still blocks guards' sight, and blocks sound.

## Alternatives considered

- None recorded. The automatic open and close comes straight from the GDD.

## Consequences

- Moving through doors costs nothing extra, and doors close behind you as the GDD intends.
- The peek gives the goblin a safe look into the next room: it can see guards beyond the door without those guards being able to see it.
- Door state follows the most recent mover nearby, rather than everyone present (see [systems/doors.md](../systems/doors.md#gotchas)).

**Affects:** [systems/doors.md](../systems/doors.md), [`door.gd`](../../project/scripts/components/door.gd)
