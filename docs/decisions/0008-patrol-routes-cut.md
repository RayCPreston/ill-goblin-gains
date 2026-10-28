# 0008: Patrolling guards walk to random destinations, not scripted routes

**Status:** Accepted · 2026-07-05

## Context

The GDD describes patrolling guards moving "in predictable paths", sweeping rooms and only turning at dead ends. Meanwhile, guards were already picking random reachable destinations, with curiosity (a point of interest) and alarm (the last known position) overriding them.

## Decision

Scripted patrol routes are cut from scope. A patrolling guard walks to a random reachable cell anywhere on the map, then picks another. CURIOUS and ALERT override that with their own targets.

## Alternatives considered

- **Scripted patrol routes** (the GDD's original model): more predictable to read and plan around, but they add authoring work and complexity, especially once maps are procedurally generated, for no meaningful gameplay gain in a 5–10 minute run.

## Consequences

- Guard movement emerges from random wandering plus the curiosity and alarm overrides, and in practice it reads well enough.
- Patrols are less predictable than the GDD's description, and a patrolling guard can cross the whole map. Stealth relies on reading cones in the moment rather than learning routes.
- Don't propose patrol routes as future work unless this is revisited with a new record.

**Affects:** [systems/guards.md](../systems/guards.md), [GDD → PATROL state](../design/game-design-doc.md#patrol-state)
