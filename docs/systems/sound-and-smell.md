# Sound and Smell

The goblin is heard as well as seen. Steps make noise, some traits add a smell or a sneeze, and any guard close enough reacts as if it had caught a glimpse. Unlike sight, sound spreads around corners. A wall between you and a guard doesn't keep you quiet, but a closed door does.

## How it works

### The flood fill

Every sound or smell is one call to `ProximityAlert.compute(origin, radius)`, which returns every cell the sound reaches ([0012](../decisions/0012-sound-floods-and-is-heard-like-a-glimpse.md)). It spreads outward from the goblin one ring of steps at a time, in all eight directions, for `radius` steps:
- **Walls and vision-blocking furniture stop it.** A closed or peeked door blocks it; an open door doesn't.
- **It can't cut corners.** A diagonal step is skipped if either of the two orthogonal cells beside it is blocked, the same rule pathfinding uses. So sound can't leak diagonally between two walls.
- **The goblin's own cell isn't included.**

So radius means *walking distance around obstacles*, not distance as the crow flies. A guard two tiles away through a solid wall may be out of earshot, while one five tiles away down an open corridor is in.

### What makes noise

| Source | When | Radius |
|---|---|---|
| **Steps** | Every completed move, plus waits with Fidgety | `Player.noise_radius`: 2 by default, 0 with Padfoot, 3 with Two Left Feet. A Clumsy stumble (1 in 5 steps) doubles it |
| **Smell** | Every move and wait | `Player.smell_radius`: 0 by default, 2 with Smelly |
| **Alert burst** (Allergies' sneeze) | A 1-in-25 chance on every turn the player spends | 10 |

A step's noise is resolved from the cell the goblin just moved *into*, during the player's turn, before any guard acts. Each source also has a visual: the `*sneak*` word, the smell haze, and the red "ACHOO!" with a shake (see [vfx-and-juice.md](vfx-and-juice.md)).

### What a guard does when it hears

Every guard standing in a reached cell calls `react_to_proximity(goblin_cell)`. That's exactly the same reaction as an outer-zone glimpse (see [guards.md](guards.md#what-a-sighting-does)):

| Guard state | Hearing the goblin |
|---|---|
| PATROL | Goes CURIOUS and heads for the goblin's cell |
| CURIOUS | Moves its point of interest to the goblin's cell |
| ALERT | Updates the shared last known position to the goblin's cell |

Hearing never triggers ALERT by itself. Only an inner-zone sighting does that.

### Listening the other way

Eavesdropper runs the same flood fill in reverse: any guard within radius 6 of the goblin, by the same around-corners rule, is shown as a `?` even through walls (see [traits-and-gamedata.md](traits-and-gamedata.md)).

## Key pieces

| Piece | Where | Role |
|---|---|---|
| `ProximityAlert` | [`util/proximity_alert.gd`](../../project/scripts/util/proximity_alert.gd) | The flood fill. Pure computation: no state, no knowledge of guards |
| `Player._emit_noise()`, `_emit_smell()`, `_emit_alert_burst()` | [`actors/player.gd`](../../project/scripts/actors/player.gd) | The three sources: each works out its radius and requests its visual |
| `Player._alert_guards_within()` | same | The one shared loop: flood, then `react_to_proximity()` on each guard reached |
| `Guard.react_to_proximity()` → `GuardStateMachine` | [`actors/guard.gd`](../../project/scripts/actors/guard.gd) | The state-dependent reaction |
| `Guard._is_eavesdropped()` | same | The reverse use, for Eavesdropper |

## Extending it

- **A new sound from the goblin** (a new trait outcome, an action): work out the radius, request its visual, and call `_alert_guards_within(radius)`. Don't add a second reaction path to guards.
- **A sound from somewhere else** (a thrown popper, an alarm clock, the corgi MacGuffin): run `ProximityAlert.compute()` from *that* cell. Notice that `react_to_proximity()` takes a source cell, so guards head for the noise, not the goblin. Today the reaction loop lives on `Player` and always uses the goblin's cell. A second noise source is the moment to move that loop into a manager that owns sound for the whole world, rather than copying it.
- **Different hearing per guard type** (dogs hear further, per the GDD): that changes who counts as "in range", so it belongs in the reaction step, not in the flood fill.

## Gotchas

- **Smell skips bump turns.** Smell is emitted from `move_to()` and `wait()`, so a turn spent bumping a wall or the chest gives off no smell. The alert burst, by contrast, fires from `end_turn()` and covers every spent turn.
- **One loud turn can stack.** A step's noise, the smell and a sneeze can all fire on the same turn. Each runs its own flood, and a guard can react more than once; each reaction just re-targets it.
- **A peeked door blocks sound.** Standing next to a door so it peeks lets you see through it, but it still blocks sound both ways.
- **Hearing gives exact positions.** Every reaction targets the goblin's exact cell, so a heard step in ALERT gives the guards a precise last known position.

## Not built yet

- **Sounds from other places:** thrown noisemakers (popper, alarm clock) and the corgi MacGuffin's barks, from the GDD. They need the world-level sound owner described above.
- **Lingering clouds:** smoke bombs and gas need a persistent, spreading and fading version of the flood fill, not a one-turn pulse.
- **Dogs' better hearing.**

---
*Last verified against code: `4822104` on 2026-10-28.*
