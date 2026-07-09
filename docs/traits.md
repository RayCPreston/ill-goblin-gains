# Traits

Authored trait content for the Trait & Equipment JSON System (see `CLAUDE.md`'s roadmap). This is a content/data reference, not an implementation story — CC will materialize these as actual `.json` files under the project when the `GameData` autoload and trait-application code get built. Negative traits are still being refined (see the running design conversation) and will be appended below once locked, per the plan to keep positives and negatives in one document.

## Schema

```json
{
  "id": "snake_case_id",
  "name": "Display Name",
  "type": "positive | negative",
  "description": "Player-facing text.",
  "dormant_until": "optional — plain-language note on what system this needs before it does anything",
  "note": "optional — free-text implementation caveat that isn't quite a dormant-until case (e.g. Smelly's baseline-reversion requirement below)",
  "effect": { }
}
```

`dormant_until` marks traits that are fully authored but currently no-ops because the system they depend on doesn't exist yet (mirrors how Pitcher and Butterfingers were discussed — defined now, wired up later).

### Effect kinds

Six distinct shapes came out of this trait list — being honest that most of these need bespoke code at a specific call site, not one generic interpreter. JSON stays uniform; the "how" lives in code, addressed by name.

- **`stat`** — modifies a named numeric player property. Fields: `property`, `operation`, `value`.
- **`detection_modifier`** — adjusts a named guard-detection parameter as experienced by this specific player (not a global constant change). Fields: `parameter`, `operation`, `value`, optional `condition`.
- **`charge`** — grants single-use charges consumed at a named trigger point. Fields: `trigger`, `charges`.
- **`flag`** — a boolean capability switch read by specific bespoke code elsewhere. Fields: `flag`, `value`.
- **`perception`** — grants an ongoing passive sense beyond normal vision. Fields: `mode`, plus mode-specific parameters.
- **`chance`** — a probabilistic effect checked on a recurring trigger (added for Clumsy/Allergies/Narcolepsy — none of the other five kinds fit "checked repeatedly, procs occasionally"). Fields: `trigger`, `one_in` (probability 1/N each time the trigger fires), `outcome` (free-form description of what happens when it procs).

### Operations

- **`delta`** — add `value` to the current stat/parameter.
- **`set`** — override the stat/parameter to `value`, regardless of current state.
- **`suppress`** — ignore/skip a specific check entirely, optionally gated by `condition`.

## Property / Parameter Reference

Bridges each trait's data to where it actually needs to be read in code. Consolidated from the design discussion so it doesn't stay scattered across chat history.

| Name | Resolves to | Note |
|---|---|---|
| `noise_radius` | `Player.noise_radius` | Direct field (per the proximity-alert-system story) |
| `vision_range` | `Player.fov.max_range` (`PlayerFov.max_range`) | Nested under `Player.fov`, not a direct `Player` field |
| `throw_range` | `Player.throw_range` | Direct field, written by `GameData` like `noise_radius` — dormant until a throwing/equipment system reads it |
| `guard_inner_range` | `GuardFov.INNER_RANGE`, applied per-guard against this player | Belongs in `GuardStateMachine._check_detection()`, not `GuardFov` itself — keeps FOV computation player-agnostic |
| `guard_tracking_memory` | `GuardStateMachine.TRACKING_MEMORY`, per-guard against this player | Same reasoning as above |
| `guard_search_hops` | `GuardStateMachine.POI_SEARCH_HOPS`, per-guard against this player | Same reasoning as above |
| `guard_outer_zone` | The outer-zone branch of `GuardStateMachine._check_detection()` | Suppressible under a condition, not a numeric adjustment |
| `chest_opens_on_adjacent` | New `on_proximity_changed()` override on chest/treasure furniture | Baseline chests require a bump to open (blocked movement + `interact()`, same pattern as guard capture). This trait adds an `ADJACENT`-triggered auto-open path that bypasses the bump entirely — shares the same acquire logic `interact()` uses, just triggered by proximity instead of a move attempt |
| `reveals_macguffin_direction` | New HUD element | Needs the MacGuffin's cell to be queryable (currently a single hardcoded chest — fine for now, will need a general lookup once treasures are JSON-driven) |
| `on_capture` (charge trigger) | `Guard.interact()` / `Player.interact()` | Capture resolution — consume charge instead of calling `RunState.lose()` |
| `on_sustained_detection_window` (charge trigger) | `GuardStateMachine._check_detection()` | Needs a "currently disguised" window that persists across turns while inside any guard's cone — see Disguise note below |
| `hearing_through_walls` (perception mode) | New reverse `ProximityAlert` query + `?` marker rendering | Independent of `Guard`/`VisionManager`'s existing visibility state — the guard stays properly UNSEEN under normal fog-of-war; this draws an additive marker on top |
| `smell_radius` | `Player.smell_radius` | Currently hardcoded to `3` for every player as a preview (see `docs/architecture.md`'s VFX section) — needs to revert to a true baseline (likely `0`) once this is wired through `GameData`, so smell becomes something only Smelly-holders actually have |
| `vision_min_range` | New `PlayerFov.min_range` field | Doesn't exist in code yet. Needs adding, plus a `row >= min_range` condition on the existing `VisionState.VISIBLE`-marking line in `_scan()`. Contained change — the shadow-splitting recursion is driven entirely by `is_opaque` transitions, independent of the visibility-marking decision, so this doesn't touch the recursion or guard detection (a fully separate system) at all |
| `on_move` (chance trigger) | `Player.move_to()` | Same point `_emit_noise()`/`_emit_smell()` already fire from |
| `on_turn_end` (chance trigger) | `Player.move_to()` and `Player.wait()` | Both end the player's turn — fires regardless of move vs. wait |
| `sleep` (chance outcome type) | New `Entity.is_sleeping` field + turn-skip enforcement in `Player._unhandled_input()` | Deferred — see Narcolepsy's note. `is_sleeping` belongs on `Entity`, not `Player`, so a future item like sleeping darts can put a `Guard` to sleep with the same flag |
| `emits_noise_while_waiting` (flag) | `Player.wait()` | `wait()` currently never emits noise at all — this flag adds a conditional call there |

## Implementation Architecture

Full detail in `docs/stories/game-data-trait-application.md` — the short version, worth repeating here since it's a hard requirement, not a preference: no gameplay script outside `GameData` and a new `PlayerTraitState` utility should ever contain a `match`/`if` chain keyed on a trait id, effect kind, or any of the names in the reference table above. Every call site a trait touches (`GuardStateMachine._check_detection()`, `Guard.interact()`, `MacGuffin.on_proximity_changed()`, etc.) gets exactly one clean, narrowly-named method call — e.g. `player.traits.inner_range_modifier()` — never inline trait-resolution logic. Dispatch logic lives in exactly one place. Also: no `Object.set()`/`set_indexed()`/reflection anywhere in the system — the `property`/`parameter`/`flag` names above are resolved through an authored dispatch (a `match` or a `Dictionary` of `Callable`s), not blind string-to-member resolution.

## Positive Traits

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

```json
{
  "id": "keen_eyes",
  "name": "Keen Eyes",
  "type": "positive",
  "description": "Your vision range is increased by 3 tiles.",
  "effect": {
    "kind": "stat",
    "property": "vision_range",
    "operation": "delta",
    "value": 3
  }
}
```

```json
{
  "id": "camouflage",
  "name": "Camouflage",
  "type": "positive",
  "description": "Guards must be closer than normal to instantly spot you. You can still be noticed at normal range — this only softens the worst case.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_inner_range",
    "operation": "delta",
    "value": -1
  }
}
```

```json
{
  "id": "cold_trail",
  "name": "Cold Trail",
  "type": "positive",
  "description": "Guards give up tracking your projected position sooner after losing sight of you.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_tracking_memory",
    "operation": "delta",
    "value": -1
  }
}
```

```json
{
  "id": "slippery",
  "name": "Slippery",
  "type": "positive",
  "description": "The first time a guard would capture you, you slip free instead. One use per run.",
  "effect": {
    "kind": "charge",
    "trigger": "on_capture",
    "charges": 1
  }
}
```

```json
{
  "id": "disguise",
  "name": "Disguise",
  "type": "positive",
  "description": "The first time you'd be detected, you pass through undetected instead — for as long as you remain inside a guard's vision cone(s) without breaking away. One use per run.",
  "effect": {
    "kind": "charge",
    "trigger": "on_sustained_detection_window",
    "charges": 1
  }
}
```

```json
{
  "id": "pitcher",
  "name": "Pitcher",
  "type": "positive",
  "description": "You can throw equipment up to 3 tiles further than normal range.",
  "dormant_until": "Throwing/equipment system exists",
  "effect": {
    "kind": "stat",
    "property": "throw_range",
    "operation": "delta",
    "value": 3
  }
}
```

```json
{
  "id": "cat_burglar",
  "name": "Cat Burglar",
  "type": "positive",
  "description": "Chests open automatically the moment you're adjacent to them — no need to bump into them like you normally would.",
  "effect": {
    "kind": "flag",
    "flag": "chest_opens_on_adjacent",
    "value": true
  }
}
```

```json
{
  "id": "treasure_hound",
  "name": "Treasure Hound",
  "type": "positive",
  "description": "A small indicator around you points toward the MacGuffin's compass direction.",
  "effect": {
    "kind": "flag",
    "flag": "reveals_macguffin_direction",
    "value": true
  }
}
```

```json
{
  "id": "vanishing_act",
  "name": "Vanishing Act",
  "type": "positive",
  "description": "Guards give up searching for you and return to patrol sooner once they've lost your trail.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_search_hops",
    "operation": "delta",
    "value": -1
  }
}
```

```json
{
  "id": "statue",
  "name": "Statue",
  "type": "positive",
  "description": "While waiting instead of moving, guards' outer-zone detection doesn't register you — only close-range detection still applies.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_outer_zone",
    "operation": "suppress",
    "condition": "player_waited_last_turn"
  }
}
```

```json
{
  "id": "eavesdropper",
  "name": "Eavesdropper",
  "type": "positive",
  "description": "You can hear guards moving through walls within a radius. Their presence is revealed as a '?' marker — not their identity, state, or exact type.",
  "effect": {
    "kind": "perception",
    "mode": "hearing_through_walls",
    "radius": 6,
    "marker": "unknown"
  }
}
```

## Negative Traits

```json
{
  "id": "two_left_feet",
  "name": "Two Left Feet",
  "type": "negative",
  "description": "Your noise radius is increased by 1.",
  "effect": {
    "kind": "stat",
    "property": "noise_radius",
    "operation": "delta",
    "value": 1
  }
}
```

```json
{
  "id": "nearsighted",
  "name": "Nearsighted",
  "type": "negative",
  "description": "Your vision range is reduced by 3 tiles.",
  "effect": {
    "kind": "stat",
    "property": "vision_range",
    "operation": "delta",
    "value": -3
  }
}
```

```json
{
  "id": "clumsy",
  "name": "Clumsy",
  "type": "negative",
  "description": "Every time you move, there's a chance you stumble — your sound pulse fires at double radius instead of normal.",
  "effect": {
    "kind": "chance",
    "trigger": "on_move",
    "one_in": 5,
    "outcome": {
      "type": "noise_multiplier",
      "multiplier": 2
    }
  }
}
```

```json
{
  "id": "smelly",
  "name": "Smelly",
  "type": "negative",
  "description": "Your smell radius is increased by 2.",
  "note": "Player.smell_radius currently defaults to 3 for every player as a hardcoded preview, ahead of this trait existing. Once wired through GameData, that default needs to revert to 0 (or whatever the true baseline is) so only players who roll Smelly actually leak scent.",
  "effect": {
    "kind": "stat",
    "property": "smell_radius",
    "operation": "delta",
    "value": 2
  }
}
```

```json
{
  "id": "allergies",
  "name": "Allergies",
  "type": "negative",
  "description": "You have a chance to sneeze every so often, alerting guards within a radius. A juiced \"ACHOO!\" radiates out when it happens.",
  "effect": {
    "kind": "chance",
    "trigger": "on_turn_end",
    "one_in": 25,
    "outcome": {
      "type": "alert_burst",
      "radius": 10,
      "juice": "achoo_text"
    }
  }
}
```

```json
{
  "id": "narcolepsy",
  "name": "Narcolepsy",
  "type": "negative",
  "description": "You have a chance to fall asleep for a few turns every so often, unable to act.",
  "note": "Needs Entity.is_sleeping (see Property/Parameter Reference above) and turn-skip enforcement in Player input handling — a genuinely new mechanism, not just applying a stat. Flagged for its own implementation pass, same treatment as Disguise.",
  "effect": {
    "kind": "chance",
    "trigger": "on_turn_end",
    "one_in": 50,
    "outcome": {
      "type": "sleep",
      "duration": 3
    }
  }
}
```

```json
{
  "id": "butterfingers",
  "name": "Butterfingers",
  "type": "negative",
  "description": "You can only throw equipment 2 tiles less far than normal range.",
  "dormant_until": "Throwing/equipment system exists",
  "effect": {
    "kind": "stat",
    "property": "throw_range",
    "operation": "delta",
    "value": -2
  }
}
```

```json
{
  "id": "big_target",
  "name": "Big Target",
  "type": "negative",
  "description": "Guards notice you from slightly further away than normal.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_inner_range",
    "operation": "delta",
    "value": 1
  }
}
```

```json
{
  "id": "far_sighted",
  "name": "Far-Sighted",
  "type": "negative",
  "description": "Your vision doesn't start until 2 tiles away — you have a blind spot immediately around you, though you can always see the tile you're standing on.",
  "note": "Needs a new PlayerFov.min_range field and a row >= min_range gate on the existing VisionState.VISIBLE-marking line in _scan(). Contained change — the shadow-casting recursion is driven entirely by opacity checks, independent of the visibility-marking decision, so this doesn't touch guard detection or the recursion logic at all. The player's own tile is set VISIBLE unconditionally before the row-scan begins, so it's unaffected by the blind spot regardless.",
  "effect": {
    "kind": "stat",
    "property": "vision_min_range",
    "operation": "set",
    "value": 2
  }
}
```

```json
{
  "id": "persistent_trail",
  "name": "Persistent Trail",
  "type": "negative",
  "description": "Guards project your position forward for longer after losing sight of you — harder to shake a tail once spotted.",
  "effect": {
    "kind": "detection_modifier",
    "parameter": "guard_tracking_memory",
    "operation": "delta",
    "value": 2
  }
}
```

```json
{
  "id": "fidgety",
  "name": "Fidgety",
  "type": "negative",
  "description": "Waiting doesn't fully hide you — you still emit a small sound pulse even while standing still.",
  "effect": {
    "kind": "flag",
    "flag": "emits_noise_while_waiting",
    "value": true
  }
}
```

## Open Items

- Several `value`s (Cold Trail's `-1`, Vanishing Act's `-1`, Eavesdropper's `radius: 6`, and every `chance`-kind `one_in`/`outcome` value in the negative list) are reasonable starting points, not playtested numbers — treat as tunable, including alongside the underlying game constants they modify.
- Whether these become one `traits.json` array or one file per trait is an implementation choice, not specified here.
- Disguise's `on_sustained_detection_window` trigger needs a short-lived "currently disguised" state that persists across turns while inside any guard's cone, separate from the charge count itself — flagged for whoever picks up the implementation story, not solved here.
