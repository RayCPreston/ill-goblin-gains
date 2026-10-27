# Story: <Feature Name>

## Context
Why this exists now. Cite the GDD sections it implements or changes, and any earlier stories or decisions it builds on. Note anything Ray confirmed during the design session (numbers, names, cut ideas).

## Player Experience
The moment as the player lives it: what they see, hear, and decide. Include the turn-by-turn vignette from the design session, trimmed to what matters.

## Readability
How the play area stays clear while this is going on:
- What draws on screen, where, for how long, and at what z-order relative to actors and cones.
- What it never covers or reveals (fog of war, guard state colors).
- How it stacks with other effects that can fire on the same turn.
- The ASCII sketch of the busiest moment, if one was drawn.

## Goal
One paragraph: what is true when this ships.

## Scope

**In scope:**
- …

**Out of scope (deferred):**
- <idea> — <one-line reason it's deferred>

## Acceptance Criteria
1. Observable behaviors in the running game, each one testable by playing or by a headless check.
2. At least one criterion covering readability (e.g. "a guard's cone stays visible under the effect").

## Technical Notes
Only what keeps the implementer on the rails: which systems are involved (`GridManager`, `ProximityAlert`, `GuardStateMachine`, `FloatingTextRequest`/`VfxManager`, `GameData`/`PlayerTraitState`…), which `CLAUDE.md` conventions apply, and any tuning values that should be surfaced as constants. Don't pre-write the implementation.

## Open Questions
Things to settle after seeing it run. Feel and tuning questions belong here, not in the acceptance criteria.
