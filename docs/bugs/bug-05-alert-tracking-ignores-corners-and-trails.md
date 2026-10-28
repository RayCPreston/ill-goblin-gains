# Bug 05: ALERT tracking ignores corners and the trail traits

**Severity:** player-facing. **Needs a design call before fixing.**

## Symptom
Once the world is in ALERT:
- the guards' shared guess at the goblin's position stops dead at walls, while CURIOUS guards' guesses slide around corners;
- Cold Trail and Persistent Trail have no effect.

## Cause
`WorldState.tick_tracking()` makes its own prediction, separate from CURIOUS tracking. It doesn't slide around corners and doesn't read the trail-trait modifiers.

## Where
- `WorldState.tick_tracking()`
- CURIOUS tracking in `GuardStateMachine`, for comparison

## Open question
Should Cold Trail and Persistent Trail affect ALERT tracking, and by the same amounts as CURIOUS tracking?

## Fix direction
Share one prediction step between CURIOUS and ALERT tracking, so corner sliding and any trait modifiers apply to both the same way.

## Done when
- In ALERT, the prediction slides around corners the same way CURIOUS tracking does.
- The trail traits behave in ALERT the way the open question settles.
- The "two tracking layers behave differently" Gotcha in [guards.md](../systems/guards.md#gotchas) is removed.
