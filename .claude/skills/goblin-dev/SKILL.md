---
name: goblin-dev
description: Implement a story, feature, fix, or refactor in Ill Goblin Gains (Godot 4.6 / GDScript) to the project's engineering standards — manager-owned responsibilities, the signals-vs-method-calls rule, fully extensible solutions with no bolt-ons, and self-explaining code with minimal comments — then verify it by actually running the game. Use when Ray invokes /goblin-dev, hands over a story in docs/stories/, or asks to build, fix, or refactor game code. The implementation counterpart to /goblin-design.
argument-hint: "[story file, feature, or bug]"
---

# Goblin Dev

You're implementing work in **Ill Goblin Gains**. The target: **$ARGUMENTS**

If that's a story in `docs/stories/` or a bug in `docs/bugs/`, it's the spec; a bug's "Done when" is the bar for verification. If it's a feature with no story and the design isn't settled, suggest `/goblin-design` first rather than making design calls in code. Bugs and small, well-understood changes can go straight ahead.

## Before writing code

1. Read the story end to end, including Scope, Out of scope, and Acceptance Criteria.
2. Read `CLAUDE.md` (Core Conventions, Don'ts, Current State). Its conventions are binding and this skill builds on them. Read `docs/systems/README.md` and the systems pages for what you'll touch, and `docs/design/game-design-doc.md` when you need the design intent behind something.
3. Read the code you'll change and its neighbors. Match what's there.
4. Find the owner. For each new responsibility, decide which manager owns it (table below) before writing anything.

## Managers own responsibilities

Every concern has exactly one owning autoload. Entities don't do a manager's job and don't reach into other entities' state. **They tell the appropriate manager what needs doing.**

| Manager | Owns |
|---|---|
| `GameManager` | Run lifecycle: level-ready setup, loadout rolling, restart |
| `TurnManager` | Turn order: player phase, then world entities in registration order |
| `GridManager` | Who occupies which cell (actors, furniture), moves, swaps, proximity notifications |
| `TileManager` | Terrain: walkability, bounds, opacity, pathfinding |
| `VisionManager` | Player vision state (VISIBLE/REMEMBERED/UNSEEN), guard cone rendering |
| `WorldState` | World alert level (the ALERT ratchet) and last known position (LKP) |
| `RunState` | Current run: outcome, MacGuffin held, loadout |
| `GameData` | Data definitions loaded from `data/*.json`, validation, trait application dispatch |
| `VfxManager` | Spawning visual effects (floating text, auras) |
| `UiState` | Modal/UI state that gates input |
| `GameEvents` | The global event bus (declares signals, owns no logic) |

If no manager owns a new responsibility, don't scatter it across entities. Propose a new manager or an extension of an existing one, and check with Ray when it's a new autoload.

## Signals vs method calls

Pick by direction and by who needs to know:

- **Method call: commands and queries to the one owner.** When the caller needs an answer or is telling the single owner to do something, call it directly: `GridManager.is_cell_available(cell)`, `GridManager.move_entity(...)`, `RunState.lose(cause)`. Managers also call *down* into entities they drive: `TurnManager` → `entity.take_turn()`.
- **Entity-local signal: an entity announcing a change to its own state.** Declare it on the entity. The owning manager connects to it when the entity registers: `turn_ended` ↔ `TurnManager.register_player()`, `vision_updated`/`cone_updated` ↔ `VisionManager.initialize_*()`. Children never call up into parents.
- **`GameEvents` signal: a game-wide happening.** Use it when there could be zero or many listeners and the emitter shouldn't know who they are, especially gameplay → presentation/UI (`run_ended`, `level_ready`, `loadout_rolled`, `text_emitted`). Gameplay code never references `VfxManager` or UI nodes directly; it emits, and they listen.

Naming and payloads:
- Signals state facts in the past tense (`run_ended`, `loadout_rolled`). Use `*_requested` for input intents (`zoom_in_requested`). Methods are imperative commands or queries (`move_entity`, `lose`, `is_cell_available`).
- Type every signal parameter. Once a payload passes about three fields or is likely to grow, pass a `RefCounted` parameter object instead (`FloatingTextRequest`, `RunLoadout`).
- Don't use a signal to fake a return value, and don't emit a signal that exactly one known receiver handles when a direct call to that owner says it more plainly.

## Fully extensible, no bolt-ons

Build the general mechanism, then express the specific case as data or configuration on top of it. Precedents to follow:
- `PoolRoller` (rolls any id pool),
- `ProximityAlert` (any origin and radius),
- `FloatingTextRequest`/`text_emitted` (any text effect),
- the generic `StateMachine`,
- trait JSON with `GameData`'s authored dispatch,
- Allergies' burst text coming from data instead of code.

Bolt-on smells, which should be refactored, not shipped:
- Branching on a trait id, effect kind, or content name outside `GameData`/`PlayerTraitState`.
- A one-off flag or field on `Entity`/`Player` that only one case uses, when a general concept fits (`is_sleeping` on `Entity`, not on `Player`).
- Copy-pasted logic with small tweaks. Extract the shared part (e.g. `_alert_guards_within()` replacing three `ProximityAlert` loops).
- Content in code: strings, chances, radii, or colors that belong in `data/*.json` or as named constants.
- Special-casing player vs guard when `Entity` can cover both (`Entity.shake()`).
- Wrapping a workaround around existing code instead of fixing the code itself.

The test: *if a second one of these arrived tomorrow (another trait, item, guard type, security system, floor), would it be a data entry or one call, or another branch?* It should be the former.

Extend along the axes the GDD already promises (more traits, items, guard types, security systems, floors, procgen rooms). Don't invent axes nobody has asked for. When the right fix means refactoring existing code, do it as part of the change and say so in the report. For a large refactor, check with Ray first.

## Self-explaining code, minimal comments

- **The default is no comment.** Names say *what*, structure says *how*. Before writing a comment, try extracting a well-named function, variable, or constant instead.
- **Comment only the *why* the code can't carry**: a non-obvious constraint, a fog-of-war leak guard, a workaround for engine behavior (e.g. a `Label`'s `size` isn't valid on its spawn frame), the reason behind a tuning value.
- **Performance beats prose in hot paths.** In shadowcasting, BFS floods, and per-frame `_process`/`_draw`, keep the fast inline form and leave a short comment rather than adding call overhead.
- **`##` doc comments** only on public methods whose contract isn't obvious from the name and signature.
- **Never** write comments that restate the code, history or changelog notes ("renamed from…", "added for Story 12"), or story/ticket references in code.
- **Tuning knobs** are named `UPPER_SNAKE` constants at the top of the file. A short trailing comment is fine when the unit or meaning isn't in the name.
- **Existing comments:** the codebase is comment-heavy from before this standard. Trim redundant comments in code you're already changing. Don't run unrelated comment-stripping passes.

## GDScript conventions

On top of `CLAUDE.md`:
- **Explicit types everywhere:** variables, constants, parameters, returns, and loop variables (`for guard: Guard in guards`). Never use `:=` inference.
- **Naming:** `_leading_underscore` for private members. `class_name` on reusable types. snake_case files.
- **File layout:** signals, then constants, then exported and public vars, then private vars, then `_ready`, then public methods, then private methods.
- **Where things live:** `RefCounted` utilities in `scripts/util/` (actor-specific ones under `actors/guard|player/`). Script-only VFX nodes in `scripts/vfx/`.
- **Visual work:**
  - Round rendered positions to whole pixels.
  - Use PixelOperator8 font sizes in multiples of 8.
  - Animate a child `Sprite2D`, never the `Entity` node's `position` (`tweened_move` owns that).
  - Nothing may leak information through fog of war.

## Verify by running the game

Launch the game and observe the result before reporting. Don't hand verification off to Ray when you can do it yourself. See [testing.md](testing.md) for the headless check, the windowed launch/screenshot/keypress helper ([drive-game.ps1](drive-game.ps1)), and how to force a hard-to-trigger case. Every acceptance criterion that can be observed gets observed. Remove all `TEMP-` test scaffolding, and grep to confirm, before you report.

## Workflow and git

- **One item at a time.** Finish, verify, report, then **stop**. Don't start the next story in a sequence until Ray says so.
- **Branching:** branch off an up-to-date `master`. Name it `feature/<name>`; trait stories use `feature/trait-<name>`. Never commit to `master`.
- **Commit or push only when Ray asks.** Keep the implementation commit separate from the "Delete completed <name> story" commit. Write messages to a file and use `git commit -F <file>`. Never chain heredocs with `&&`, which has mangled messages before.
- **GitHub access:** pass the deploy key on each command and never put it in git config: `git -c core.sshCommand="ssh -i ~/.ssh/id_ed25519_claude_treasure_goblin -o IdentitiesOnly=yes -o BatchMode=yes" fetch|push ...`.
- **Story docs** are deleted only when the work is done and Ray asks, and only after `/goblin-docs harvest` has folded the story into `docs/systems/` and `docs/decisions/`.
- **Docs:** when you change architecture surface (a new manager, utility, signal, or data kind), update the affected `docs/systems/` page in the same change, using `/goblin-docs <system>`. Keep `docs/systems/README.md`'s autoload and signal tables current too. Record any non-obvious choice you made with `/goblin-docs decision`. Trait work also updates `docs/design/traits.md`'s reference table.
- **Line endings:** some files are CRLF and some LF. Preserve whatever a file already uses.

## Reporting

Keep it short:
- **What changed:** grouped by intent, with file links.
- **How you verified it:** what you ran and saw. Be honest about anything unexplained.
- **Tuning knobs** Ray will likely want to adjust.
- **Concerns or follow-ups**, including deviations from the story and why.

Don't claim "done" past what you observed.
