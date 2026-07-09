# Epic: GameData & Trait Application System

## Context
`docs/traits.md` has 23 locked traits (12 positive, 11 negative) authored across six effect kinds (`stat`, `detection_modifier`, `charge`, `flag`, `perception`, `chance`). Nothing reads that content yet — no `GameData` autoload, no application logic, no `.json` files in the project. This epic builds the system that turns that authored content into real player state.

The functional goal is straightforward. The architectural goal is the one Ray flagged as important enough to write down everywhere: this touches several of the most sensitive files in the codebase (`GuardStateMachine._check_detection()`, `Guard.interact()`/`Player.interact()`, `MacGuffin.on_proximity_changed()`), and a sloppy implementation would mean bolting a growing `match` statement onto each of them as more traits get added. That has to not happen. See the Technical Notes below for the full reasoning; the short version is that dispatch logic belongs in exactly one place, and every gameplay call site a trait touches gets exactly one clean, narrowly-named method call — never a branch on trait names or effect-kind strings.

## Goal
`GameData` loads trait definitions and can apply a given list of trait ids to the player. Every one of the 16 traits with a real, buildable effect today (see Scope) produces its described behavior. The remaining 7 have their data correctly stored and queryable, even though nothing fully consumes them yet (some, like Allergies, are partially wired — gameplay effect works, juice doesn't). No gameplay script outside `GameData`/the new trait-state utility contains trait-specific branching logic.

## Scope

**In scope — fully wired to a real, observable effect:**
- Padfoot (`stat`, `noise_radius`)
- Keen Eyes (`stat`, `vision_range`)
- Camouflage (`detection_modifier`, `guard_inner_range`)
- Cold Trail (`detection_modifier`, `guard_tracking_memory`)
- Vanishing Act (`detection_modifier`, `guard_search_hops`)
- Statue (`detection_modifier`, `guard_outer_zone`, conditional on waiting)
- Slippery (`charge`, `on_capture`)
- Cat Burglar (`flag`, `chest_opens_on_adjacent`) — baseline chests now require a bump to open (`is_interactable`/`interact()`, shipped separately in PR #33 — the same pattern guard capture uses, already costing a turn via `try_move_to()`'s unconditional `end_turn()`). Cat Burglar bypasses that requirement: the chest also implements `on_proximity_changed()`, checking `Proximity.ADJACENT` plus this flag, and calls the same acquire logic `interact()` uses — worth extracting into one shared private method rather than duplicating it. Opens automatically as the holder passes by; no bump needed.

**Negative traits, added after the positive list was locked (source: `docs/traits.md`'s Negative Traits section):**
- Two Left Feet (`stat`, `noise_radius`) — mirrors Padfoot, inverse delta.
- Nearsighted (`stat`, `vision_range`) — mirrors Keen Eyes, inverse delta.
- Big Target (`detection_modifier`, `guard_inner_range`) — mirrors Camouflage, inverse delta.
- Persistent Trail (`detection_modifier`, `guard_tracking_memory`) — mirrors Cold Trail, inverse delta.
- Fidgety (`flag`, `emits_noise_while_waiting`) — needs `Player.wait()` to conditionally emit noise, which it currently never does at all (only `move_to()` does).
- Far-Sighted (`stat`, `vision_min_range`) — needs a new `PlayerFov.min_range` field, detailed in Technical Notes below. Small, contained change; in scope for this epic rather than deferred.
- Smelly (`stat`, `smell_radius`) — the write itself is trivial, but this trait also requires reverting `Player.smell_radius`'s hardcoded default from `3` to `0` (see Technical Notes) as part of this epic, not a separate cleanup task.
- Clumsy (`chance`, `on_move`) — requires this epic to build the new `chance` kind's dispatch (see Technical Notes below); once that exists, Clumsy just wraps the already-shipped `_emit_noise()` with a probability check.

**In scope — data stored and queryable, behavior deferred:**
- Pitcher (`stat`, `throw_range`) — writes fine, nothing reads it until throwing/equipment exists
- Disguise (`charge`, `on_sustained_detection_window`) — the charge count can be stored and consumed like Slippery's, but the actual "stay undetected for the full duration inside a cone" behavior needs multi-turn state tracking that's a meaningfully bigger problem — deferred to its own pass
- Treasure Hound (`flag`, `reveals_macguffin_direction`) — needs a HUD element that doesn't exist yet
- Eavesdropper (`perception`, `hearing_through_walls`) — needs the reverse `ProximityAlert` query and `?` marker rendering, likely paired with the juice/VFX work
- Butterfingers (`stat`, `throw_range`) — mirrors Pitcher, dormant until throwing exists
- Allergies (`chance`, `on_turn_end`) — the guard-alert gameplay effect is fully buildable once the `chance` kind's dispatch exists, reusing `ProximityAlert` (already shipped); the "ACHOO!" text juice needs its own VFX work (a text-rendering variant of the pulse foundation from the juice-sound-pulse work, not yet built)
- Narcolepsy (`chance`, `on_turn_end`, outcome `sleep`) — the chance-to-trigger can be stored and rolled like any other `chance` trait, but the actual sleep mechanism (`Entity.is_sleeping`, forced turn-skipping in `Player._unhandled_input()`) is genuinely new work — deferred to its own design pass, same treatment as Disguise

**Out of scope (deferred):**
- Random trait rolling with the GDD's *n*/*m* counts — this epic applies a fixed, hardcoded test list of trait ids to validate the system end to end; real rolling belongs to the Run Start Flow story, since it also needs the menu/UI this doesn't have yet.
- Negative traits — JSON isn't authored yet, pending the refinement pass.
- Equipment, treasures, and everything under "data-ready, behavior deferred" above.

## Acceptance Criteria
1. `GameData` autoload exists, loads trait definitions (source content: `docs/traits.md`; converting it to real `.json` file(s) is part of this epic — organization as one file or many is implementation's call).
2. At load time, `GameData` validates every trait's `property`/`parameter`/`flag`/`trigger`/`outcome.type` name against the known, authored set and logs a clear error for anything unrecognized — no silent no-ops on a typo.
3. A new `PlayerTraitState` utility (see Technical Notes) is held on `Player` and exposes one narrowly-named method per currently-defined `detection_modifier`/`flag`/`charge`/`perception`/`chance` effect — not a generic string-keyed getter.
4. `stat`-kind traits are applied via an authored dispatch (a `match` or a small `Dictionary` of `Callable`s) writing directly to `Player`'s real typed fields (`Player.noise_radius`, `Player.fov.max_range`, etc.). No `Object.set()`/`set_indexed()` or any other reflection anywhere in the trait system.
5. No file outside `GameData` and the new trait-state utility contains a `match`/`if` chain keyed on a trait id, effect kind, or property/parameter/flag/trigger name. Every consuming call site (`GuardStateMachine`, `Guard`, `Player`, `MacGuffin`) reads as a single method call.
6. Applying the 8 "fully wired" traits (individually) to the player produces their described behavior, verifiable by observation/playtesting.
7. Applying the 4 "data-ready, deferred" traits doesn't error — their values are stored and queryable via `PlayerTraitState` even though no consumer reads them yet.
8. Since there's no real Run Start Flow yet, trigger the roll-and-apply step from a placeholder integration point — `Level._ready()` is the natural fit (it already does startup wiring via `TileManager.initialize()`) — applying a fixed test list of trait ids, not random rolling.

## Technical Notes

**Why not reflection.** `Object.set()`/`set_indexed()`/`call()` can resolve a string into a real property or method — GDScript genuinely supports this. The reason not to use it here isn't that it doesn't work; it's that it succeeds on *any* valid path, intended or not. A curated dispatch (`match`, or a `Dictionary` of `Callable`s) can only do what was deliberately wired up — nothing gets touched that some line of code didn't explicitly authorize. The cost: every new `stat`-kind trait needs one new line in that dispatch, rather than being auto-supported by reflection for free. Worth it — it means every typo gets caught as "unrecognized property" at the same validation point (criterion 2) instead of two different failure modes for two different kinds of traits.

**`PlayerTraitState`.** New `RefCounted` utility, following the exact pattern `PlayerFov` already establishes (`Player.fov: PlayerFov` → likewise `Player.traits: PlayerTraitState`). Suggested location: `scripts/util/actors/player/player_trait_state.gd`. Internally it can hold whatever's convenient (small typed `Dictionary`s keyed by parameter/flag/trigger name are the obvious choice, populated once by `GameData` at run start) — the internals aren't the point. The point is the *public* surface: narrow, purpose-named methods only. Suggested shape based on the 8 wired traits:
- `inner_range_modifier() -> int`
- `tracking_memory_modifier() -> int`
- `search_hops_modifier() -> int`
- `is_outer_zone_suppressed(player_waited_last_turn: bool) -> bool`
- `try_consume_capture_charge() -> bool`
- `chest_opens_on_adjacent() -> bool`

Naming/exact signatures are a judgment call for whoever implements this — the requirement is narrow-and-named, not this exact list.

**Call-site notes, one per wired trait:**
- **Camouflage / Cold Trail / Vanishing Act** — each is a one-line change at an existing comparison: `GuardStateMachine._check_detection()` (inner range), `_tick_tracking()` (`TRACKING_MEMORY`), and the search-hop logic in `_do_curious()` (`POI_SEARCH_HOPS`), respectively. Read the modifier from `GridManager.get_player().traits`, add/apply it to the existing constant at the point of comparison.
- **Statue** — needs one small addition beyond the trait system itself: `Player` doesn't currently track whether it moved or waited last turn. A simple flag (set in `move_to()` and `wait()`) is enough; `_check_detection()`'s outer-zone branch checks it via `is_outer_zone_suppressed()`.
- **Slippery** — insert a charge check in `Guard.interact()`/`Player.interact()`, before the existing `RunState.lose()` call, per the capture logic already built in the session-end work.
- **Cat Burglar** — `MacGuffin.on_proximity_changed()` checks `chest_opens_on_adjacent()` to decide whether `Proximity.ADJACENT` (not just `OVERLAPPED`) triggers pickup.
- **Padfoot / Keen Eyes** — applied once, at run start, directly to `Player.noise_radius` / `Player.fov.max_range`. No ongoing check anywhere — this is the whole reason `stat` traits don't need `PlayerTraitState` involvement at all, only the authored dispatch at apply-time.

**The `chance` effect kind.** Six effect kinds exist now, not five — `chance` covers probabilistic, recurring effects (Clumsy, Allergies, Narcolepsy) that don't fit `stat`/`detection_modifier`/`charge`/`flag`/`perception`. Same principle as everywhere else in this doc applies: no bespoke branching in `Player`. `PlayerTraitState` should own the roll — narrow methods like `check_on_move_chance_effects()` and `check_on_turn_end_chance_effects()`, called from `Player.move_to()`/`wait()` at the same points `_emit_noise()`/`_emit_smell()` already fire, doing the RNG roll internally and returning what (if anything) procced. `Player` shouldn't know anything about probabilities, trait ids, or outcome types.

**Far-Sighted.** `PlayerFov` needs a new `min_range` field (default `0`, meaning no blind spot) and a `row >= min_range` condition added to the existing `_memory[cell] = VisionState.VISIBLE` line in `_scan()`. Confirmed contained: the shadow-splitting recursion in `_scan()` is driven entirely by `is_opaque` transitions, completely independent of whether a cell gets marked `VISIBLE` — gating visibility doesn't touch the recursion. `PlayerFov` has no connection to guard detection at all (that's `GuardFov`, a fully separate system), so this can't accidentally affect whether guards see the player. The origin cell is set `VISIBLE` unconditionally before the row-scan begins, so it's naturally unaffected by the blind spot.

**Smelly's baseline reversion.** `Player.smell_radius` currently defaults to `3` for every player, unconditionally — a deliberate preview shipped ahead of the trait system (see `docs/architecture.md`'s VFX section). Once Smelly is wired through `GameData`, this default needs to drop to `0` (or whatever true baseline gets chosen) so smell becomes something only Smelly-holders actually have, not a universal mechanic. Easy to miss since it's a reversion rather than an addition — flagging explicitly as in-scope for this epic.

**Narcolepsy's sleep mechanism (deferred, but the shape is worth recording).** `is_sleeping` belongs on `Entity`, not `Player` — Ray's direction, so a future item like sleeping darts can put a `Guard` to sleep with the same flag and whatever enforcement logic eventually gets built, rather than duplicating it later. Enforcement itself (enforcing the sleeping entity skips its turn/input for the duration) isn't designed yet.

**Placeholder run-start trigger.** No main menu exists yet (`CLAUDE.md`'s Run Start Flow item). Matching the precedent set by Session End (map-edge win in place of a real Exit entity) and the Proximity Alert work (hardcoded default radius, no trait wiring yet), this epic should call its roll-and-apply step from `Level._ready()` with a hardcoded trait id list, not attempt to build any part of the menu/rolling UI.

## Open Questions
- One `traits.json` array vs. one file per trait — implementation's call, not specified here.
- Disguise's multi-turn suppression window needs its own design pass when it's picked up — flagged, not solved here.
- Whether `PlayerTraitState` pulls from `GameData` itself or is populated externally by `GameData` reaching in and setting values — either works, implementation's call.
