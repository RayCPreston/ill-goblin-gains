# 0017: Nothing on screen may reveal what's happening in unseen space

**Status:** Accepted · 2026-07-05

## Context

Fog of war is the core of stealth: the player has to reason about where guards might be. Several features could quietly undermine it, even though none of them shows a guard directly:
- **Doors:** a door that animates when a guard walks through it off-screen.
- **Cones:** a cone painted into rooms the goblin can't see.
- **Text:** floating text spawned somewhere out of view.

## Decision

Anything shown on screen must be explainable by what the goblin can currently see, or remembers seeing. Concretely:
- **Guards aren't remembered.** They're hidden the moment their cell leaves view, never shown where they used to be.
- **Doors out of view freeze their sprite** at the last state actually seen, even while guards open and close them unseen.
- **Guard cones are drawn only on currently visible cells.**
- **Floating text is skipped when its cell isn't visible** (`fov_gated`, on by default).

## Alternatives considered

- **Showing true, live state everywhere and relying on the dimmed fog to hide it:** rejected, because animation and color in remembered space read as information.

## Consequences

- Every new visual has to ask whether it can reveal unseen activity, and if it can, gate it on `VISIBLE`. `/goblin-design`'s readability checklist and `/goblin-dev`'s standards both carry this rule.
- Deliberate exceptions are traits that grant information, like Eavesdropper's `?` markers. They should reveal only what the trait promises. Today, a `?` guard's cone still draws on visible cells, which shows a little more than that.

**Affects:** [systems/vision-and-fog.md](../systems/vision-and-fog.md), [systems/vfx-and-juice.md](../systems/vfx-and-juice.md), [`door.gd`](../../project/scripts/components/door.gd), [`vision_manager.gd`](../../project/autoloads/vision_manager.gd)
