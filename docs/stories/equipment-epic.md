# Epic: Equipment

## Context
The GDD promises "random equipment granted at the beginning of a run" (Summary, Player Character Details → Equipment): every item is helpful, and the challenge is finding the right moment to use it. The groundwork exists: `Constants.STARTING_ITEM_COUNT` (3) is reserved, `PoolRoller` was kept generic for exactly this ([0004](../decisions/0004-traits-rolled-at-run-start.md)), and Pitcher and Butterfingers already write `throw_range` but nothing reads it.

Settled with Ray in the design session (2026-10-29):
- 20 candidates were narrowed to the 14 below. Cut: Ventriloquist's Whistle (repeats the Popper), Straw Dummy (unclear whether a close-up sighting should trip ALERT), Pepper Pouch (repeats the darts and muddies cone readability), Rabbit's Foot (repeats Slippery and fires on its own, so there's no decision), Grappling Hook (waits on two floors), Muffled Socks (a timed buff is bookkeeping).
- Overlap with a trait is fine (Spyglass vs Keen Eyes, Stethoscope vs Eavesdropper).
- The inventory is a **modal like the traits screen**, opened with **I**. There is no throw key and no use key; every item is used from the modal.

This epic holds the rules every item follows and the roadmap. Each wave gets its own design pass and story.

## Player Experience
You start a run and the reveal screen lists your traits and, under EQUIPMENT, up to three items. Mid-run you hit a problem: a guard parked in the hallway you need, a chaser one room behind, a corridor too long to see down. You press **I**, press the item's number to read it, and press **Enter** to use it. Using an item is your turn. The modal closes and the world moves.

Every item answers one kind of problem: pull a guard away, take a guard out of play, break line of sight, control the route, or learn more.

## The rules every item follows
- **One action per item.** An item is either *used* (takes effect at once, sometimes after choosing a direction) or *thrown* (aimed at a cell, from Wave 1 on). The inspected item shows which, and Enter does it.
- **Charges.** Each item has a charge count. An item with no charges left drops off the inventory, so there's nothing to track.
- **A use costs exactly one turn.** It's neither a move nor a wait. So: no step noise, no smell, no Fidgety pulse, no Statue protection, and the turn-end chances (Allergies, Narcolepsy) still roll, as they do on every spent turn ([0005](../decisions/0005-turn-end-chance-rolls-every-spent-turn.md)).
- **Opening the inventory is free**, like every modal.
- **A sleeping goblin can't use items.** It can still open the inventory to look.
- **Only built items are rolled.** `items.json` holds only items that are actually built. Roadmap items live in this epic until their story ships, so a run never deals a dead item.
- **No branching on item ids.** Items follow the trait conventions: data in JSON, an authored dispatch on an effect kind, validation in `GameData`, and narrow accessors at the call sites ([0001](../decisions/0001-trait-effects-use-authored-dispatch.md), [0002](../decisions/0002-trait-logic-behind-narrow-accessors.md)).
- **Juice follows the existing rules.** Each use may request floating text through `VfxManager` ([0006](../decisions/0006-gameplay-emits-vfx-requests.md), [0007](../decisions/0007-noise-shown-as-floating-text.md)). Nothing appears for an effect the player can't see ([0017](../decisions/0017-nothing-leaks-through-fog-of-war.md)).

## Roadmap

### Wave 0: the item system
Story: [equipment-01-item-system-and-blueprint.md](equipment-01-item-system-and-blueprint.md).
- **Blueprint** (use, 1 charge): every tile on the current floor becomes REMEMBERED. Doors show closed and greyed out, as remembered doors already do. Guards, furniture, the chest and the MacGuffin stay hidden. With two floors, choosing which floor to map becomes a real decision.

### Wave 1: aiming, and items that reuse what exists
Brings throwing: aiming at a cell, range from `Player.throw_range` (so Pitcher and Butterfingers start working), and a world-level sound owner moved out of `Player` ([sound-and-smell.md → Extending it](../systems/sound-and-smell.md#extending-it)). Also settles how a *used* item picks a direction.
- **Popper ×3** (throw): one noise burst where it lands; guards who hear it go CURIOUS toward it.
- **Shiny Coin** (throw): silent. A guard who *sees* it walks over to pick it up. The quiet lure.
- **Sleeping Darts ×2** (aimed at a visible guard): the guard sleeps for N turns through `Entity.fall_asleep()`. Settle: does it wake CURIOUS, and does a sleeping guard show a cone?
- **Door Wedge** (use, adjacent door): the door stays shut to guards for N turns.
- **Spyglass** (use + direction): *needs refinement.* Working idea: for one turn, sight reaches about 30 tiles in a narrow cone that way. It costs the turn and has no charges. What it shows becomes remembered layout; guards show only for that turn. Made for long hallways.
- **Stethoscope ×3** (use): *needs refinement.* Working idea: a one-turn Eavesdropper `?` pulse at radius about 10.

### Wave 2: items left on the map
Brings placed items that act each turn (entities that register like any other and refresh their own visibility).
- **Alarm Clock** (throw): rings after a turn timer you can see; guards who hear it go CURIOUS, and it rings until a guard turns it off. This changes the GDD's version (immediate, 50 tiles), which would cover most of a 72×45 floor.
- **Banana Peel** (throw): the next guard to step on it loses 2 turns.
- **Tin Can Tripwire** (throw): rattles when a guard crosses it, showing a `?` there the way Eavesdropper does.

### Wave 3: new systems
- **Smoke Bomb** (throw): a cloud that blocks sight and fades over a few turns. Needs a lingering version of the `ProximityAlert` flood (CLAUDE.md → Further Out).
- **Pet Rat** (use, released at your feet; GDD): wanders on its own; guards who see it go CURIOUS and follow. A new actor with its own state machine.

### Waiting on other systems
- **Cardboard Box** (use): hiding you carry. Comes with or after Furniture & Hiding.
- **Dog Treat** (throw): keeps a dog busy. Comes with dogs.

## Out of scope (whole epic)
- Picking up items mid-run: the loadout is dealt at run start (GDD: no gear management).
- Duplicate items in one loadout: `PoolRoller` picks distinct ids.
- A HUD strip for items: the inventory lives in its modal (HUD pillar).
- Throwing an item that isn't a throwable: one action per item.
