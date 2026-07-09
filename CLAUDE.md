# Ill Goblin Gains

Turn-based stealth roguelike in Godot 4 (GDScript). Player is a goblin infiltrating a procedurally generated mansion to steal a MacGuffin and escape. Inspired by Brogue. Short runs (5-10 minutes). No RPG elements.

## Tech Stack
- Godot 4.6, GDScript only
- 16x16 tile/sprite standard (Aseprite for pixel art)
- Map size driven by `MapConfig` (default 72x45 tiles)

## Reference Docs
- `docs/game-design-doc.md` — source of truth for all design questions (mechanics, traits, equipment, world/guard/security details)
- `docs/architecture.md` — system design, autoload responsibilities, current implementation status
- `docs/procgen.md` — procedural generation design notes (not yet implemented, not blocking current work)

## Core Conventions
- **No physics.** All movement, collision, and spatial queries go through `GridManager` dictionaries and `TileManager`.
- **Grid dictionary pattern.** Spatial data keyed by `Vector2i` cell positions, O(1) lookup.
- **Autoloads for all managers.** `TurnManager`, `GridManager`, `TileManager`, `VisionManager`, `WorldState`, `RunState`, `GameEvents`, `MapConfig`, `Constants`, `PlayerInput`, `CameraInput`, `Log`, `ResolutionManager`, `VfxManager`, `GameData`, `UiState`.
- **Entity base class.** All actors and furniture inherit `Entity`. Movement via `try_move_to` → `move_to` → `tweened_move`. Turn end via `end_turn()` signal.
- **Signals for upward communication.** Children emit signals, parents/autoloads connect.
- **Self-registration in `_ready()`.** Entities register themselves with managers.
- **Explicit type declarations.** No `var` type inference. Always declare types.
- **Turn order.** Player acts first, then all world entities in registration order (`TurnManager`).
- **Utility classes as RefCounted.** `GuardFov`, `GuardStateMachine`, `StateMachine`, `PlayerFov`, `ProximityAlert` — not Nodes, not in the scene tree.
- **Utility class location.** `scripts/util/` for generic utilities, `scripts/util/actors/guard/` for guard-specific, `scripts/util/actors/player/` for player-specific.

## Don'ts
- Don't use Godot's physics engine for anything.
- Don't use `tile_data.modulate` for colored overlays — it's multiplicative and breaks on dark tiles. Use `_draw` with Rect2 overlays instead. `tile_data.modulate` is only for player FOV (VISIBLE/REMEMBERED/UNSEEN).
- Don't put behavioral logic directly on Entity subclasses. Extract state machines and FOV computation into utility classes.
- Don't bake dynamic obstacles into AStarGrid2D. Check at move-attempt time via `GridManager.is_cell_available`.

## Current State

### Movement & Grid
Fully grid-based, no physics. All spatial logic through `GridManager` dictionaries. Turn order: player acts first, then all world entities. Player has 360° symmetric shadowcasting FOV with fog of war (VISIBLE / REMEMBERED / UNSEEN tile states).

### Guard System — Fully Implemented
- `PATROL` — directional cone (green, segmented inner/outer zones), random destination patrol.
- `CURIOUS` — 360° vision (yellow, segmented), investigates POI, returns to patrol point if player not found.
- `ALERT` — 360° vision (red, unsegmented), converges on global Last Known Position (LKP).
- ALERT is a permanent world-level ratchet for the run — any entity can trip it.
- Predictive tracking — guards project POI/LKP forward along last observed player direction for a few turns after losing sight (`GuardStateMachine.TRACKING_MEMORY`), sliding around blocked corners instead of dead-ending on the first wall.
- Direction is captured from any two sightings, not just consecutive turns — a single glimpse is enough to give a guard a heading to chase.
- CURIOUS guards spend a short search-hop dwell (`POI_SEARCH_HOPS`/`POI_SEARCH_RADIUS`) checking nearby cells after reaching their point of interest before giving up and returning to patrol.
- `GuardStateMachine.react_to_proximity(source_cell)` (renamed from `_on_outer_detection`) is the single PATROL/CURIOUS/ALERT dispatch both vision-outer-zone sightings and the sound system below funnel through.
- Generic `StateMachine` utility in place — will power cameras, dogs, laser traps, etc.

### Proximity Alert System (Sound) — Fully Implemented
- `ProximityAlert` (`scripts/util/proximity_alert.gd`) is a generic BFS flood-fill: `compute(origin, radius) -> Array[Vector2i]`, blocked by the same opacity/vision-blocking data `GuardFov` uses, with corner-cutting prevention matching `TileManager`'s `AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES` convention. Sound propagates like a gas (wraps corners) rather than vision's straight-line LOS.
- Triggered on every completed `Player.move_to()` (not `wait()`) at `Player.noise_radius` (default 2, overridable by traits — see Trait & GameData System below).
- Every guard whose cell falls in the flood-filled area calls `react_to_proximity()`, reacting exactly as if it saw the player in its outer vision zone.
- Deliberately generic and reusable: a future "Smelly" hook trait or thrown item (smoke bomb, alarm clock) can call the same `compute()` with a different origin/radius/trigger. Smoke bombs/gases need a *persistent, evolving* version (an expanding, dissipating cloud) — a meaningfully different problem, deferred to its own story once equipment exists.

### Doors
Proximity-driven open/peek/closed states. Peeked state blocks guard vision but player can see through. Guards cannot open doors yet (planned: humans can, dogs cannot). Visual sprite state is decoupled from logical state: while a door is only `REMEMBERED` (outside current player FOV), its sprite freezes at whatever was last actually observed rather than live-updating as guards pass through it off-screen — otherwise door animation would leak guard movement through fog of war.

### Session End — Fully Implemented
Capture, a placeholder MacGuffin, a win condition, and a restart loop all work end to end.
- Capture is bidirectional via `Entity.is_interactable`/`interact()`: `Guard.interact()` and `Player.interact()` each call `RunState.lose()` when the other type is the source. `Guard.step_along_path()` lets a move through to `try_move_to()` when the blocking occupant is interactable, so a guard walking into the player triggers it too (not just the reverse).
- MacGuffin is a placeholder: the existing `chest.tscn` scene got a `macguffin.gd` script (furniture, `is_interactable = true`, blocks movement). Picked up via the same bump-interact pattern as guard capture (`interact()`, triggered when `try_move_to()` finds an interactable occupant at the target cell) — bumping it already costs a turn like any other action, via the existing unconditional `end_turn()`. No JSON, no on-pickup effect yet — intentionally deferred to the Trait & Equipment System below, since the GDD's MacGuffin behavior (e.g. a barking corgi) is mechanically a hook trait.
- Win is simplified: walking off the map edge (`TileManager.is_in_bounds()` check in `Player.try_move_to()`) while holding the MacGuffin triggers `RunState.win()`. No dedicated Exit entity yet — reasonable placeholder, will likely need a real exit (tied to a door/room) once procgen exists.
- `RunState` (autoload) holds `has_macguffin`, `is_run_over`, `outcome`. `GameEvents.run_ended(won, cause)` signal drives a modal `EndScreen` (`scenes/ui/end_screen.tscn`) showing outcome + cause.
- `TurnManager` and `Player._unhandled_input` both check `RunState.is_run_over` to freeze the run.
- Restart: `restart` input action (R key) in `Level._unhandled_input()` resets `WorldState`, `RunState`, and guard cones, then reloads the scene.

## What's Next

### 1. Trait & GameData System — In Progress
Being built incrementally, one trait story at a time, per `docs/stories/game-data-trait-application.md` (the epic) and `docs/stories/trait-story-NN-*.md` (per-trait stories, deleted from the repo as each lands). Full trait content (23 traits, six effect kinds: `stat`, `detection_modifier`, `charge`, `flag`, `perception`, `chance`) is authored in `docs/traits.md`.

**Architecture landed (Story 01):**
- `GameData` autoload (`project/autoloads/game_data.gd`) loads trait definitions from `project/data/traits.json`, validates each definition's effect kind/property against an authored known-set at load time (logs via `Log.error` and drops anything unrecognized — no silent no-ops on a typo), and applies effects to the player through an authored dispatch (`match` on property name, currently `stat`-kind only). No reflection (`Object.set()`/`set_indexed()`) anywhere.
- `PlayerTraitState` (`project/scripts/util/actors/player/player_trait_state.gd`, `RefCounted`), held as `Player.traits`, mirrors the `Player.fov: PlayerFov` pattern. Holds `applied_ids`; will grow narrow, purpose-named accessor methods (one per `detection_modifier`/`flag`/`charge`/`perception`/`chance` effect) as later stories need them.
- Hard architectural rule, enforced from here on: every gameplay call site a trait touches (`GuardStateMachine._check_detection()`, `Guard.interact()`, `MacGuffin.on_proximity_changed()`, etc.) gets exactly one clean, narrowly-named method call — never a `match`/`if` chain on a trait id/effect kind/property name outside `GameData` and `PlayerTraitState`.
- Placeholder run-start trigger lives in `Level._ready()` (`GameData.apply_traits([...], GridManager.get_player())`, hardcoded id list) until the real Run Start Flow below exists.

**Padfoot** (`stat`, sets `Player.noise_radius` to 0) is the only trait wired end-to-end so far. Remaining traits land one PR at a time, in the order listed in the epic.

**Traits modal (character screen) — landed (Story 02):** `C` (`character_menu` input action) toggles `TraitsModal` (`scenes/ui/traits_modal.tscn` / `scripts/ui/traits_modal.gd`, a shown/hidden `CanvasLayer` following the `EndScreen` precedent), listing the player's applied traits numbered 1–n; pressing a number shows that trait's name/description via `GameData.get_definition(id)`. New `UiState` autoload (`modal_open: bool`) blocks `Player._unhandled_input()` while any modal is open, without consuming a turn — the same pattern `RunState.is_run_over` already uses.

### 2. Run Start Flow
The game currently drops straight into gameplay with no framing. Needed: main menu and a run start sequence. Traits and equipment are randomly rolled at session start (n positive, m negative — see GDD for counts and pool), replacing the hardcoded id list `Level._ready()` uses today.

### 3. Furniture & Hiding System
Furniture is partially modeled: `Entity.is_furniture`, `Entity.can_hide_player` (field already exists, unused), `GridManager._furniture` dict. Needs: JSON definitions with a `hideable` field, player hide/unhide action, and guard detection interaction when player is hidden. See GDD for furniture types and hiding rules.

## Further Out
- Dogs, cameras, laser traps (architecture supports them via generic `StateMachine`, no implementation yet)
- Patrol routes — descoped; random destinations (overridden by POI/LKP) considered sufficient
- Smoke bombs, alarm clocks, and other thrown items — need a persistent/evolving version of `ProximityAlert` (expanding, dissipating cloud), not just a one-shot pulse
- Procedural generation (`docs/procgen.md` has early design notes)
- Inventory / MacGuffin pickup
