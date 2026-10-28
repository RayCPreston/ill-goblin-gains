# 0006: Gameplay emits VFX requests; it never creates or calls effects directly

**Status:** Accepted · 2026-07-06

## Context

The first piece of juice (a ring pulsing out from each step) raised the question of how gameplay code should trigger visuals. Gameplay is turn-based and resolves instantly. Effects animate in real time over a second or so. Mixing the two makes gameplay code depend on presentation.

## Decision

Gameplay builds a request and emits it on the `GameEvents` bus (today, `text_emitted` with a `FloatingTextRequest`). `VfxManager` is the only listener. It applies presentation rules, such as the fog-of-war check and same-frame stacking, then spawns a script-only effect node that animates and frees itself. Effects never block input or wait on turns.

## Alternatives considered

- **Gameplay creating effect nodes, or calling `VfxManager`, directly:** fewer moving parts, but it breaks the project's rule that children signal upward and never reach into a manager's internals, and it ties gameplay files to every visual.

## Consequences

- Visuals can be added, restyled or removed without touching gameplay logic. When the sound ring was replaced by floating text ([0007](0007-noise-shown-as-floating-text.md)), the gameplay change was a few lines in `Player`.
- Presentation rules (fog of war, stacking) live in one place, so new effects get them automatically.
- A request carries enough data (a cell, not a node reference) for `VfxManager` to place the effect without knowing who asked.

**Affects:** [systems/vfx-and-juice.md](../systems/vfx-and-juice.md), [`vfx_manager.gd`](../../project/autoloads/vfx_manager.gd)
