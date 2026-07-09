# Trait Story 01: Padfoot

**Epic:** `docs/stories/game-data-trait-application.md`
**Source:** `docs/traits.md`

This is the first trait story and carries the shared infrastructure every other trait story depends on. Build this one first — everything after it assumes this exists.

## Infrastructure (build once, here)
- `GameData` autoload: loads trait definitions (source content in `docs/traits.md`, converted to real `.json` file(s) — one array or one-per-trait is your call) and exposes a way to apply a given list of trait ids to the player.
- `PlayerTraitState` utility (`scripts/util/actors/player/player_trait_state.gd`, `RefCounted`), held as `Player.traits`, mirroring the existing `Player.fov: PlayerFov` pattern. Starts minimal — later stories add methods to it as their effect kinds need them.
- `stat`-kind dispatch: an authored `match` (or a `Dictionary` of `Callable`s) mapping property names to real `Player` fields, applying `delta`/`set` operations. No reflection (`Object.set()`/`set_indexed()`) anywhere — see the epic's "Why not reflection" note for the full reasoning.
- Load-time validation: any trait referencing an unrecognized `property`/`parameter`/`flag`/`trigger`/`outcome.type` logs a clear error via `Log`, not a silent no-op.
- Placeholder run-start trigger: call the roll-and-apply step from `Level._ready()` with a hardcoded trait id list (not real rolling — that's Run Start Flow's job later).

## Trait Definition
```json
{
  "id": "padfoot",
  "name": "Padfoot",
  "type": "positive",
  "description": "Your noise radius is set to 0 — you never emit a sound pulse.",
  "effect": {
    "kind": "stat",
    "property": "noise_radius",
    "operation": "set",
    "value": 0
  }
}
```

## What This Story Does
Applies Padfoot's `stat` effect via the new dispatch, writing directly to `Player.noise_radius`. Proves out the `set` operation specifically (see Story 02 for `delta`).

## Acceptance Criteria
1. `GameData` and `PlayerTraitState` exist per Infrastructure above.
2. Applying Padfoot at run start sets `Player.noise_radius` to `0`.
3. With Padfoot applied, `_emit_noise()` never alerts guards via sound (already-existing consumer, no changes needed there).
4. An unrecognized `property` name in a trait definition logs an error at load time (verify with a deliberately-broken test entry, then remove it).
