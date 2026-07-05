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
- **Autoloads for all managers.** `TurnManager`, `GridManager`, `TileManager`, `VisionManager`, `WorldState`, `RunState`, `GameEvents`, `MapConfig`, `Constants`, `PlayerInput`, `CameraInput`, `Log`, `ResolutionManager`.
- **Entity base class.** All actors and furniture inherit `Entity`. Movement via `try_move_to` → `move_to` → `tweened_move`. Turn end via `end_turn()` signal.
- **Signals for upward communication.** Children emit signals, parents/autoloads connect.
- **Self-registration in `_ready()`.** Entities register themselves with managers.
- **Explicit type declarations.** No `var` type inference. Always declare types.
- **Turn order.** Player acts first, then all world entities in registration order (`TurnManager`).
- **Utility classes as RefCounted.** `GuardFov`, `GuardStateMachine`, `StateMachine`, `PlayerFov` — not Nodes, not in the scene tree.
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
- Predictive tracking — guards project POI/LKP forward along last observed player direction for ~3 turns after losing sight.
- Generic `StateMachine` utility in place — will power cameras, dogs, laser traps, etc.

### Doors
Proximity-driven open/peek/closed states. Peeked state blocks guard vision but player can see through. Guards cannot open doors yet (planned: humans can, dogs cannot).

### Session End — Fully Implemented
Capture, a placeholder MacGuffin, a win condition, and a restart loop all work end to end. See `docs/stories/session-end-definitions.md` for the full story (status: implemented).
- Capture is bidirectional via `Entity.is_interactable`/`interact()`: `Guard.interact()` and `Player.interact()` each call `RunState.lose()` when the other type is the source. `Guard.step_along_path()` lets a move through to `try_move_to()` when the blocking occupant is interactable, so a guard walking into the player triggers it too (not just the reverse).
- MacGuffin is a placeholder: the existing `chest.tscn` scene got a `macguffin.gd` script (furniture, `can_overlap = true`), sets `RunState.has_macguffin = true` on player overlap. No JSON, no on-pickup effect yet — intentionally deferred to the Trait & Equipment System below, since the GDD's MacGuffin behavior (e.g. a barking corgi) is mechanically a hook trait.
- Win is simplified: walking off the map edge (`TileManager.is_in_bounds()` check in `Player.try_move_to()`) while holding the MacGuffin triggers `RunState.win()`. No dedicated Exit entity yet — reasonable placeholder, will likely need a real exit (tied to a door/room) once procgen exists.
- `RunState` (new autoload) holds `has_macguffin`, `is_run_over`, `outcome`. `GameEvents.run_ended(won, cause)` signal drives a modal `EndScreen` (`scenes/ui/end_screen.tscn`) showing outcome + cause.
- `TurnManager` and `Player._unhandled_input` both check `RunState.is_run_over` to freeze the run.
- Restart: `restart` input action (R key) in `Level._unhandled_input()` resets `WorldState`, `RunState`, and guard cones, then reloads the scene.

## What's Next

### 1. Run Start Flow
The game currently drops straight into gameplay with no framing. Needed: main menu and a run start sequence. Traits and equipment are randomly rolled at session start (n positive, m negative — see GDD for counts and pool). A `GameData` autoload will load trait/equipment JSON and apply them to the player before the run begins.

### 2. Trait & Equipment JSON System
Two trait types have a working design:

**Property traits** — directly modify a player stat at run start:
```json
{
  "id": "soft_soled_shoes",
  "name": "Soft-soled Shoes",
  "type": "positive",
  "description": "Your noise radius is reduced by 1.",
  "property": "noise_radius",
  "delta": -1
}
```

**Hook traits** — register an effect that fires each turn via `TurnManager`:
```json
{
  "id": "smelly",
  "name": "Smelly",
  "type": "negative",
  "description": "Guards within 5 tiles are put into CURIOUS state each turn.",
  "hook": "on_turn_end",
  "params": { "radius": 5 }
}
```

Needs: JSON files authored from the GDD trait/equipment lists, schema finalized, `GameData` autoload implemented. No JSON data files or `GameData` autoload exist in the repo yet — this is greenfield.

### 3. Furniture & Hiding System
Furniture is partially modeled: `Entity.is_furniture`, `Entity.can_hide_player` (field already exists, unused), `GridManager._furniture` dict. Needs: JSON definitions with a `hideable` field, player hide/unhide action, and guard detection interaction when player is hidden. See GDD for furniture types and hiding rules.

### 4. Session End Definitions
Win/loss conditions, end-of-run screen. See GDD (win: exit building with MacGuffin; lose: captured by any guard).

## Further Out
- Dogs, cameras, laser traps (architecture supports them via generic `StateMachine`, no implementation yet)
- Patrol routes — descoped; random destinations (overridden by POI/LKP) considered sufficient
- Sound/hearing system (noise radius planned but not propagated)
- Procedural generation (`docs/procgen.md` has early design notes)
- Inventory / MacGuffin pickup
