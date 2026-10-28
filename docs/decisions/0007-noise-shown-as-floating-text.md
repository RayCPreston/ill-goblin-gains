# 0007: Noise is shown as scattered floating text, not an expanding ring

**Status:** Accepted · 2026-10-27

## Context

Every step drew a ring expanding to the goblin's noise radius. It measured the radius exactly, but it read as off-putting, and over the hundreds of steps in a run it was constant visual noise in a game whose screen has to stay readable.

## Decision

The ring is gone. A step now emits a small `*sneak*` floating word instead:
- **Scatter shows the radius:** the word lands at a random spot within the noise radius (in pixels, × `NOISE_SPREAD_FACTOR`), so a normal step scatters modestly and a Clumsy stumble scatters wide.
- **A silent goblin shows nothing:** at noise radius 0 (e.g. Padfoot), no word appears. That rule lives in `Player._emit_noise()`, not in the VFX code.
- **Not on every step:** the word appears on 60% of steps (`NOISE_TEXT_CHANCE`), so it stays flavor rather than a metronome.
- **Volume convention:** asterisks mark quiet, self-narrated text. Loud events drop them (`ACHOO!`).

## Alternatives considered

- **Keeping the ring:** exact, but too noisy for every step.
- **Text on every step:** the original plan. Throttling by probability was the fix the story itself suggested, if every step felt like too much.

## Consequences

- The radius reads approximately rather than exactly. That's a deliberate trade for a calmer screen.
- The floating-text system it required became the foundation for all text juice (`ACHOO!` today, Narcolepsy's z's next).

**Affects:** [systems/vfx-and-juice.md](../systems/vfx-and-juice.md), [`player.gd`](../../project/scripts/actors/player.gd)
