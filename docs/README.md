# Ill Goblin Gains: Docs

Where to look, depending on the question:

| Question | Folder |
|---|---|
| What should the game be? | [`design/`](design/) |
| How does it work today? | [`systems/`](systems/) |
| Why is it built this way? | [`decisions/`](decisions/) |
| What's being built right now? | [`stories/`](stories/) |
| What's known to be broken? | [`bugs/`](bugs/) |

## Design: intent

- [Game Design Document](design/game-design-doc.md): **source of truth** for mechanics, world, guards, security, and juice.
- [Traits](design/traits.md): every trait's data definition, the effect-kind schema, and the property reference.
- [Items](design/items.md): every built item's data definition, the item schema, and the item effect kinds.
- [Procedural generation](design/procgen.md): early notes; not implemented yet.

## Systems: current behavior

One page per system, written from the code and stamped with the commit it was last verified against. Start with the [overview](systems/README.md): which autoload owns what, the signal map, and a suggested reading order.

- [Traits and GameData](systems/traits-and-gamedata.md): loading, rolling, and applying traits; the six effect kinds; every place gameplay reads them.
- [Equipment](systems/equipment.md): rolling and holding items, the inventory screen, using an item for a turn, the Blueprint and the `MAPPED` fog state.
- [VFX and Juice](systems/vfx-and-juice.md): floating text, shake, the smell aura, and how gameplay requests effects without touching them.
- [Guards](systems/guards.md): PATROL / CURIOUS / ALERT, vision cones, what a sighting does, predictive tracking, movement and capture.
- [Sound and Smell](systems/sound-and-smell.md): the flood fill, what makes noise, how guards react to hearing, and Eavesdropper's reverse use.
- [Run Lifecycle](systems/run-lifecycle.md): level load, the reveal, play, capture and escape, the end screen, restart.
- [Vision and Fog of War](systems/vision-and-fog.md): the goblin's field of view, the four fog states, how tiles, entities and cones are drawn.
- [Turns and the Grid](systems/turn-and-grid.md): turn order, the grid managers, entity flags and moves, proximity, pathfinding.
- [Doors](systems/doors.md): closed / peeked / open, what each blocks, guards walking through, the fog-of-war sprite freeze.
- [Input and Camera](systems/input-and-camera.md): controls, who handles which key, camera zoom and dead-zone following, window, logging.

## Decisions: the why

Short numbered records: context, decision, alternatives, consequences. Decisions aren't rewritten; an overturned one is marked superseded by a newer record.

- [0001](decisions/0001-trait-effects-use-authored-dispatch.md): Trait effects are applied through an authored dispatch, validated at load, with no reflection
- [0002](decisions/0002-trait-logic-behind-narrow-accessors.md): Gameplay reads traits only through narrowly named accessors
- [0003](decisions/0003-chance-effect-kind.md): Probabilistic, recurring traits get their own effect kind, `chance`
- [0004](decisions/0004-traits-rolled-at-run-start.md): Traits are rolled fresh each run (3 positive, 2 negative) by a generic roller
- [0005](decisions/0005-turn-end-chance-rolls-every-spent-turn.md): Turn-end chance effects roll once on every turn the player spends
- [0006](decisions/0006-gameplay-emits-vfx-requests.md): Gameplay emits VFX requests; it never creates or calls effects directly
- [0007](decisions/0007-noise-shown-as-floating-text.md): Noise is shown as scattered floating text, not an expanding ring
- [0008](decisions/0008-patrol-routes-cut.md): Patrolling guards walk to random destinations, not scripted routes
- [0009](decisions/0009-sighting-checked-before-player-moves.md): Guards check for the goblin before the goblin's move resolves
- [0010](decisions/0010-guards-predict-player-heading.md): Guards extrapolate the goblin's heading after losing sight
- [0011](decisions/0011-alert-is-permanent.md): Once the world goes ALERT, it stays ALERT for the rest of the run
- [0012](decisions/0012-sound-floods-and-is-heard-like-a-glimpse.md): Sound floods around corners, and hearing is treated as an outer-zone glimpse
- [0013](decisions/0013-bumping-is-how-actors-interact.md): Bumping is how actors interact, both for capture and for picking up the MacGuffin
- [0014](decisions/0014-run-state-and-restart-by-reload.md): Run outcome lives in `RunState`; a finished run freezes; restart reloads the scene
- [0015](decisions/0015-escape-off-the-map-edge.md): For now, escaping means walking off the map edge holding the MacGuffin
- [0016](decisions/0016-overlays-drawn-not-tile-modulated.md): Colored overlays are drawn on top of tiles; tile tinting is reserved for fog of war
- [0017](decisions/0017-nothing-leaks-through-fog-of-war.md): Nothing on screen may reveal what's happening in unseen space
- [0018](decisions/0018-grid-dictionaries-no-physics.md): All spatial state lives in grid dictionaries; no physics; pathfinding knows only terrain
- [0019](decisions/0019-doors-open-by-proximity.md): Doors open and close by proximity, and the goblin can peek through them
- [0020](decisions/0020-sleeping-turns-wait-for-input.md): A sleeping goblin's turns still wait for the player's input
- [0021](decisions/0021-mapped-is-its-own-vision-state.md): Map knowledge is its own vision state, `MAPPED`

## Stories: work in flight

Specs for work being built. When a story ships, it's **harvested**: what was built goes into `systems/`, notable choices go into `decisions/`, and then the story is deleted. [stories/README.md](stories/README.md) covers the format, acceptance criteria, and lifecycle.

## Bugs: known and not yet fixed

One file per bug, named `bug-NN-<name>.md`, with severity, symptom, cause, where, fix direction, and done-when. Each is also noted in its systems page's Gotchas. Numbers are never reused.

When a bug is fixed, the same PR deletes its file and removes or updates the Gotcha.

## Maintaining these docs

- `/goblin-docs` audits the docs against the code and suggests what to write or refresh.
- `/goblin-docs <system>` writes or refreshes a systems page.
- `/goblin-docs decision <topic>` records a decision.
- `/goblin-docs harvest <story>` folds a shipped story into the docs.
- `/goblin-design` writes stories, and `/goblin-ship` offers a harvest before deleting a finished one.
