# Items

Authored item content: the data definition of every **built** item, the schema, and the effect-kind reference. The roadmap of planned items, and the rules every item follows, live in the [Equipment epic](../stories/equipment-epic.md) until each one ships. `project/data/items.json` holds only built items, so a run never deals one that does nothing.

## Schema

```json
{
  "id": "snake_case_id",
  "name": "Display Name",
  "description": "Player-facing text, shown when the item is inspected.",
  "action": "use",
  "charges": 1,
  "effect": { "kind": "<effect kind>" }
}
```

| Key | Meaning |
|---|---|
| `action` | What Enter does on the inspected item. Shown in the inventory as `Enter: <action>`. Only `use` exists: it takes effect at once. `throw` arrives with aiming (Wave 1). |
| `charges` | How many times it can be used. At least 1. The item leaves the inventory when the last charge is spent. |
| `effect.kind` | Which authored effect runs on use, plus that kind's parameters. |

An item with an unknown `action` or `effect.kind`, or fewer than 1 charge, is logged and dropped at load ([0001](../decisions/0001-trait-effects-use-authored-dispatch.md)).

## Effect kinds

| Kind | Parameters | Does | Resolves to |
|---|---|---|---|
| `map_floor` | none | Every never-seen cell with terrain on the current floor becomes `MAPPED`: its layout shows dimmed, nothing on it is revealed ([0021](../decisions/0021-mapped-is-its-own-vision-state.md)) | `Player.map_floor()` → `PlayerFov.map()` |

## Items

| Item | Action | Charges | Effect | Description |
|---|---|---|---|---|
| Blueprint (`blueprint`) | use | 1 | `map_floor` | A floor plan of this floor. Maps every wall, room and door you haven't seen, but nothing that's in them. |

## Open items

- **Juice on use:** nothing plays today. A quiet `*unfolds map*` on the goblin, or a ~1 second wash-in of the mapped layout, are both open.
- **Charges in the list:** the inventory shows charges only on inspect. Worth revisiting once multi-charge items (Popper ×3) exist.
- **Stairs and exits** should presumably count as layout for `map_floor` once procgen places them: set `is_layout` on them.
