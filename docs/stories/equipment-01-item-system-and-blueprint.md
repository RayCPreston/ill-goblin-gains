# Story: Equipment 01 — Item System and Blueprint

## Context
Wave 0 of the [Equipment epic](equipment-epic.md). It implements the GDD's "random equipment granted at the beginning of a run" and the Open Inventory / Use Equipment actions (Player Character Details → Actions, Equipment). The rules every item follows are in the epic; this story builds them, with the **Blueprint** as the first item to prove the *use* path.

Settled with Ray (2026-10-29):
- The inventory is a modal like the traits screen. **I** toggles it, a number inspects an item, and **Enter** does the item's one action. There is no throw key and no use key.
- The Blueprint has one charge and maps the current floor as REMEMBERED. Doors show closed and greyed out, as remembered doors already do. Guards, furniture, the chest and the MacGuffin stay hidden.
- Throwing and aiming are **not** in this story. They arrive with the Popper in Wave 1, so nothing gets built without an item to use it.

## Player Experience
- **Run start:** the reveal screen lists TRAITS, FLAWS and now EQUIPMENT. Today that's just the Blueprint, since it's the only built item.
- **Turn 1:** you press **I**. The inventory shows `1  Blueprint`. You press **1**: its name, description, `Charges: 1` and `Enter: use`. You press **Enter**.
- **Same turn:** the modal closes. Every unseen tile on the floor washes in as dim, remembered layout, including the walls, rooms and corridors, with doors drawn closed and grey. Your own view stays fully lit. No guards, furniture or chest appear in the remembered area. The world takes its turn.
- **Turn 2:** you press **I** again. The inventory is empty, and the Blueprint is gone. You plan a route to the far wing using the map, and it's still dark to you what's in those rooms.

## Readability
- The Blueprint uses the existing REMEMBERED look (tiles dimmed to 40%). It adds no new overlay, colors or HUD.
- Nothing in mapped-but-never-seen cells shows except tiles and doors. Guards, furniture, the chest and the MacGuffin appear only once the goblin actually sees their cell ([0017](../decisions/0017-nothing-leaks-through-fog-of-war.md)).
- Doors in mapped cells draw closed and dimmed, whatever their real state. Their sprite catches up once they're actually seen, as the door freeze already does.
- Guard cones are unaffected: they're still painted only on `VISIBLE` cells.
- Any juice on use (see Open Questions) is quiet, short, on the goblin, and finished before the next input.

```
Before                      After using the Blueprint
                            ##########.#######
                            #........+.......#
     ######                 #..####..#..###..#
     #.@..+                 #..#..#..#..#.#..#
     #....#                 ####..####..#.####
     ######                    #.@..+   ...
                            (dim: mapped layout, doors closed;
                             no guards, furniture or chest)
```

## Goal
Every run deals up to three items from the built pool, shown on the reveal screen. The player can review them at any time with **I** and use one from the modal for a turn. The Blueprint is the first item: using it maps the current floor's layout and doors, and reveals nothing that moves or that the goblin hasn't seen.

## Scope

**In scope:**
- `project/data/items.json` and its loading and validation in `GameData`, mirroring traits (unknown effect kinds are logged and dropped).
- Rolling `Constants.STARTING_ITEM_COUNT` items with `PoolRoller` into `RunLoadout`, capped at the pool size.
- An EQUIPMENT section on the reveal screen.
- The inventory modal: **I** toggles it, number keys inspect, Enter uses the inspected item, and an empty inventory says so.
- Player-side item state: held items and remaining charges. An item at 0 charges is removed.
- A use spends exactly one turn, as defined in the epic's rules.
- The Blueprint and its effect kind.

**Out of scope (deferred):**
- Throwing, aiming and throw range — Wave 1, with the Popper.
- Used items that pick a direction — Wave 1, with the Spyglass and Door Wedge.
- Every other item — later waves, see the epic.
- Mapping the other floor — two floors don't exist yet.

## Acceptance Criteria
1. The reveal screen lists the rolled items under EQUIPMENT. With only the Blueprint built, every run deals exactly the Blueprint, and nothing errors because the pool is smaller than `STARTING_ITEM_COUNT`.
2. **I** opens the inventory and **I** closes it. Opening and closing it spends no turn, and no guard moves.
3. Pressing an item's number shows its name, description, remaining charges, and its action (`Enter: use`). Numbers beyond the list, or Enter with nothing inspected, do nothing.
4. Pressing Enter on the inspected Blueprint closes the modal and spends exactly one turn: the world takes exactly one turn, and every guard acts once.
5. After the Blueprint is used, every floor and wall cell that was UNSEEN is REMEMBERED. Cells that were VISIBLE stay VISIBLE.
6. In cells mapped this way that the goblin hasn't actually seen, no guard, Eavesdropper `?`, furniture, chest or MacGuffin is drawn. Each appears normally once the goblin sees its cell.
7. Doors in mapped cells draw closed and dimmed, even if a guard has left one open. Once seen, they show their real state.
8. The Blueprint's turn makes no step noise and no smell. Allergies and Narcolepsy still roll on it.
9. With the Blueprint used, the inventory shows that it's empty, and the next run (after **R**) deals a Blueprint again.
10. While the goblin is asleep (Narcolepsy), the inventory opens but Enter does nothing, and no charge is spent.
11. Pressing Enter after the run is over (captured or escaped) does nothing, even with the inventory open.
12. Restarting with the inventory open gives a playable run.
13. No gameplay code outside `GameData` and the player's item state branches on an item id.

## Technical Notes
- **Mirror the trait pipeline.** Use JSON plus `GameData` validation and an authored dispatch on effect kind ([0001](../decisions/0001-trait-effects-use-authored-dispatch.md)), with narrow accessors at call sites ([0002](../decisions/0002-trait-logic-behind-narrow-accessors.md)). Player item state is a `RefCounted` in `scripts/util/actors/player/`, beside `PlayerTraitState`. Extend `RunLoadout` with `item_ids`, which `traits-and-gamedata.md → Not built yet` already anticipates.
- **Item JSON** follows the trait shape: `id`, `name`, `description`, plus `action` (`use` for now), `charges`, and an `effect` with a `kind`. Settle the exact keys in the build and record them in a design doc next to `traits.md`.
- **The modal** copies the `TraitsModal` pattern: a `CanvasLayer` that sets `UiState.modal_open`, opens on its trigger, and reads number keys directly. Add an `inventory` input action on **I**, by physical position. **I** and Enter (`confirm`) are free while no other modal is open.
- **Using an item** goes through the player's turn flow, not through a move or a wait, so smell (`move_to()`/`wait()`) and step noise don't fire and `end_turn()` still rolls the turn-end chances. Vision isn't recomputed on that turn, as on a bump.
- **The fog trap.** Today an entity on a REMEMBERED cell shows itself dimmed: furniture does, and the chest may too. The Blueprint has to make the layout REMEMBERED without making those entities appear. So the vision system needs to tell "mapped" apart from "actually seen". That distinction belongs to `VisionManager`/`PlayerFov`, not to a check for the Blueprint. Doors are the exception, shown closed and dimmed; check how that fits the door's sprite freeze.
- **"The current floor"** means the whole map for now. Keep the effect expressed as "this floor", so two floors don't change its meaning.

## Open Questions
- Juice on use: a quiet `*unfolds map*` on the goblin, or nothing? Does the mapped layout appear all at once, or wash in over about 1 second (never past the turn)?
- Should the inventory list show charges next to each name (`1  Popper ×3`), or only on inspect? It matters once Wave 1 brings multi-charge items.
- Should stairs and exits count as layout for the Blueprint once procgen places them? (Presumably yes.)
