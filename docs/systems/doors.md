# Doors

Doors open by themselves when someone steps into them and close behind them. The goblin gets one extra trick: standing beside a closed door **peeks** it, so the goblin can see through while guards on the other side still can't see out.

## How it works

A door is furniture that anyone can walk onto (`can_overlap`). It has three states, each with its own sprite:

| State | When | Guards see through | Goblin sees through | Sound passes |
|---|---|---|---|---|
| **Closed** | Default; when someone moves away | No | No | No |
| **Peeked** | The goblin steps orthogonally next to it | No | **Yes** | No |
| **Open** | Anyone is standing in it | Yes | Yes | Yes |

The switching is driven by grid proximity notifications ([turn-and-grid.md](turn-and-grid.md#entities)), with no separate open action ([0019](../decisions/0019-doors-open-by-proximity.md)). Whenever something moves near a door, the door is told how close that mover now is:
- overlapping, so it opens;
- orthogonally adjacent, so it peeks if the mover is the goblin, and otherwise stays as it was;
- anything else, so it closes.

Guards walk through doors like any open floor. A closed door only blocks their *sight* (and sound), not their path.

### Out of sight, frozen

While a door is out of the goblin's view, its logical state keeps changing as guards pass through, but its **sprite doesn't**. It stays frozen at the last state the goblin actually saw. When the door comes back into view, the sprite catches up. Without this, a door swinging in a remembered corridor would reveal a guard you can't see ([0017](../decisions/0017-nothing-leaks-through-fog-of-war.md)). Doors are furniture, so out of view they stay drawn, dimmed, like other remembered map features.

## Key pieces

| Piece | Where | Role |
|---|---|---|
| `Door` | [`components/door.gd`](../../project/scripts/components/door.gd) | The state switches (`set_closed` / `set_peeked` / `set_open`), the proximity reaction, the sprite freeze |
| Door scene | [`components/furniture/door.tscn`](../../project/scenes/components/furniture/door.tscn) | `closed` / `peeked` / `open` animations; `z_index` 10 |
| `GridManager.notify_entity_moved()` | [`autoloads/grid_manager.gd`](../../project/autoloads/grid_manager.gd) | Sends proximity updates to everything around a mover's old and new cells |
| Sight and sound checks | `PlayerFov._is_opaque()`, `GuardFov._has_los()`, `ProximityAlert._is_blocked()` | Read `blocks_vision` and `allows_player_vision` |

## Extending it

- **Doors that stop some movers** (the GDD says humans can open doors and dogs can't): give the door a say over who may enter. That's a check at move time, consistent with [0018](../decisions/0018-grid-dictionaries-no-physics.md), not a rebuild of the pathfinding grid. Guards' paths would then need to treat those doors as blocked for them.
- **Locked or one-way doors:** extend `Door`'s state and its proximity reaction. Keep sprite changes going through `_set_animation()` so the fog-of-war freeze still applies.
- **Other proximity-driven furniture:** follow the same pattern, reacting in `on_proximity_changed()`.

## Gotchas

- **The last mover decides.** A door reacts to whichever entity most recently moved near it, not to everyone currently nearby. A guard walking past diagonally sends the door "too far away", so it **closes**, even while the goblin is peeking it or standing in it. Likewise, a guard walking up orthogonally doesn't open a door the goblin is peeking. If the goblin is standing in a door that closes this way, the door *shows* closed, but nothing changes in play: none of the sight or sound checks treat the cell you're standing on as blocking, so the goblin still sees out and can still be seen and heard.
- **Diagonal neighbors don't count.** Standing diagonally next to a door doesn't peek it, because adjacency is orthogonal only.
- **Peeking blocks sound.** A peeked door blocks sound like a closed one, so peeking is quiet in both directions.
- **Your view doesn't update when a guard opens a door.** Your field of view is recomputed only on your own move or wait ([vision-and-fog.md](vision-and-fog.md#gotchas)).

## Not built yet

- **Doors that dogs can't open:** dogs don't exist yet, so today every guard walks through.
- **Locked doors, keys, one-way doors.**
- **Doors tied to procedurally generated rooms,** and possibly the real exit ([0015](../decisions/0015-escape-off-the-map-edge.md)).

---
*Last verified against code: `4822104` on 2026-10-28.*
