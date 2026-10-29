# Ill Goblin Gains

Turn-based stealth roguelike in Godot 4 (GDScript). Player is a goblin infiltrating a procedurally generated mansion to steal a MacGuffin and escape. Inspired by Brogue. Short runs (5-10 minutes). No RPG elements.

## Tech Stack
- Godot 4.6, GDScript only
- 16x16 tile/sprite standard (Aseprite for pixel art)
- Map size driven by `MapConfig` (default 72x45 tiles)

## Reference Docs
- `docs/design/game-design-doc.md` — source of truth for all design questions (mechanics, traits, equipment, world/guard/security details)
- `docs/README.md` — index of all docs: `design/` (intent), `systems/` (how it works today, one page per system), `decisions/` (why), `stories/` (work in flight), `bugs/` (known bugs, not yet fixed)
- `docs/systems/README.md` — systems overview: which autoload owns what, the signal map, and one page per system
- `docs/design/procgen.md` — procedural generation design notes (not yet implemented, not blocking current work)

## Skills
Project skills live in `.claude/skills/`.
- `/goblin-design [idea]` — collaborative design session: flesh out a feature with Ray from the player's perspective, using `docs/design/game-design-doc.md` as the primary reference. Readability of the play area comes first and juice must never get in its way. The result is a story in `docs/stories/` and, with Ray's OK, GDD edits. No code in this skill.
- `/goblin-dev [story or task]` — implement to the project's engineering standards: manager-owned responsibilities, the signals-vs-method-calls rule, fully extensible solutions (no bolt-ons), self-explaining code with minimal comments. It then verifies by running the game, using `.claude/skills/goblin-dev/drive-game.ps1` (headless check, plus windowed launch/keys/screenshots).
- `/goblin-ship [PR title]` — ship finished work in two halves. First: branch if needed, commit, push, and give Ray a pre-filled PR link; Ray squash-merges on GitHub. Then, once Ray confirms the merge: verify it landed on `master`, reset local to an up-to-date `master`, and delete the stale branch. Runs preflight checks (no `TEMP-` scaffolding, clean headless run) and stops on failures or ambiguity.
- `/goblin-docs [audit | <system> | decision <topic> | harvest <story>]` — keep `docs/` current: audit the docs against the code, write a systems page from the code, record a decision, or harvest a shipped story into systems and decision docs before it's deleted.

## Core Conventions
- **No physics.** All movement, collision, and spatial queries go through `GridManager` dictionaries and `TileManager`.
- **Grid dictionary pattern.** Spatial data keyed by `Vector2i` cell positions, O(1) lookup.
- **Autoloads for all managers.** `TurnManager`, `GridManager`, `TileManager`, `VisionManager`, `WorldState`, `RunState`, `GameEvents`, `MapConfig`, `Constants`, `PlayerInput`, `CameraInput`, `Log`, `ResolutionManager`, `VfxManager`, `GameData`, `UiState`, `GameManager`.
- **Entity base class.** All actors and furniture inherit `Entity`. Movement via `try_move_to` → `move_to` → `tweened_move`. Turn end via `end_turn()` signal.
- **Signals for upward communication.** Children emit signals, parents/autoloads connect.
- **Self-registration in `_ready()`.** Entities register themselves with managers.
- **Explicit type declarations.** No `var` type inference. Always declare types.
- **Turn order.** Player acts first, then all world entities in registration order (`TurnManager`).
- **Utility classes as RefCounted.** `GuardFov`, `GuardStateMachine`, `StateMachine`, `PlayerFov`, `ProximityAlert` — not Nodes, not in the scene tree.
- **Utility class location.** `scripts/util/` for generic utilities, `scripts/util/actors/guard/` for guard-specific, `scripts/util/actors/player/` for player-specific.
- **Trait logic stays in `GameData` and `PlayerTraitState`.** Gameplay call sites make one narrowly named accessor call; nothing else branches on a trait id, effect kind, or property name, and nothing uses reflection (`docs/decisions/0001`, `0002`).

## Don'ts
- Don't use Godot's physics engine for anything.
- Don't use `tile_data.modulate` for colored overlays — it's multiplicative and breaks on dark tiles. Use `_draw` with Rect2 overlays instead. `tile_data.modulate` is only for player FOV (VISIBLE/REMEMBERED/UNSEEN). (`docs/decisions/0016`)
- Don't put behavioral logic directly on Entity subclasses. Extract state machines and FOV computation into utility classes.
- Don't bake dynamic obstacles into AStarGrid2D. Check at move-attempt time via `GridManager.is_cell_available`.

## Current State

### Turns and the Grid
Turn order, `GridManager`/`TileManager`, `Entity` flags and the move-attempt order, proximity notifications, A* pathfinding: `docs/systems/turn-and-grid.md` (decision: `docs/decisions/0018`). Player FOV and fog of war: `docs/systems/vision-and-fog.md` (nothing may leak through fog: `docs/decisions/0017`).

### Guard System
PATROL / CURIOUS / ALERT state machine, cones, detection, predictive tracking, LKP convergence, capture: `docs/systems/guards.md`. Key decisions: patrol routes cut (`docs/decisions/0008`), sighting checked before the player moves (`0009`), heading extrapolation (`0010`), ALERT is permanent for the run (`0011`).

### Sound and Smell
`ProximityAlert` flood fill, what makes noise (steps, smell, alert bursts), how guards react, Eavesdropper's reverse use: `docs/systems/sound-and-smell.md`. Key decision: sound floods around corners and is heard like an outer-zone glimpse (`docs/decisions/0012`).

### Doors
Closed / peeked / open by proximity, the goblin-only peek, guards walking through, the fog-of-war sprite freeze: `docs/systems/doors.md` (decision: `docs/decisions/0019`).

### Run Lifecycle
Level load → trait roll and reveal → play → capture or escape → end screen → restart (R reloads the scene): `docs/systems/run-lifecycle.md`. Key decisions: bumping is how actors interact, for capture and MacGuffin pickup (`docs/decisions/0013`); `RunState` plus freeze plus restart-by-reload (`0014`); escaping off the map edge is a placeholder until procgen places exits (`0015`).

### Traits
All 23 traits are shipped. Loading, rolling, applying, the six effect kinds, and every gameplay touchpoint: `docs/systems/traits-and-gamedata.md`. Key decisions: authored dispatch, no reflection (`docs/decisions/0001`); narrow accessors (`0002`); the `chance` kind (`0003`); turn-end chances roll every spent turn (`0005`). Sleep (`Entity.fall_asleep()`, Narcolepsy) is in `docs/systems/turn-and-grid.md`; a sleeping goblin's turns still wait for input (`0020`).

## What's Next

### 1. Run Start Flow — Main Menu Still Missing
The game boots straight into a run. Trait rolling and the reveal modal exist (see the traits systems page); a main menu (title, continue, settings) doesn't. Equipment rolling waits on item content: `Constants.STARTING_ITEM_COUNT` is reserved, and items should reuse `PoolRoller`.

### 2. Furniture & Hiding System
Furniture is partially modeled: `Entity.is_furniture`, `Entity.can_hide_player` (field already exists, unused), `GridManager._furniture` dict. Needs: JSON definitions with a `hideable` field, player hide/unhide action, and guard detection interaction when player is hidden. See GDD for furniture types and hiding rules.

## Further Out
- Dogs, cameras, laser traps (architecture supports them via generic `StateMachine`, no implementation yet)
- Patrol routes — descoped; random destinations (overridden by POI/LKP) considered sufficient
- Smoke bombs, alarm clocks, and other thrown items — need a persistent/evolving version of `ProximityAlert` (expanding, dissipating cloud), not just a one-shot pulse
- Procedural generation (`docs/design/procgen.md` has early design notes)
- Inventory / MacGuffin pickup
