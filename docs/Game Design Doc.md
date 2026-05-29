# Treasure Goblin - Game Design Document

## Table of Contents
- [Summary Description](#summary-description)
- [Run Structure](#run-structure)
- [Art](#art)
- [HUD](#hud)
- [Music](#music)
- [Player Character Details](#player-character-details)
- [World Details](#world-details)
- [Guard Details](#guard-details)
- [Security System Details](#security-system-details)
- [Engine Details](#engine-details)
- [Misc](#misc)
- [OutOfScope](#out-of-scope)

## Summary Description
The game will be a traditional roguelike in the following ways:
- Top down perspective
- Tile-based
- Simple and highly readable art
- Turn-based: player first, world second
- Procedural level generation
- Fetch a MacGuffin
- Seeded runs

The following features will make the experience unique:
- Stealth focused
- No RPG elements i.e. leveling, gear management, etc.
- Very short runs: 5-10 minutes maximum
- Random traits rolled at the beginning of a run: good and bad
- Random equipment granted at the beginning of a run
- Obtaining the MacGuffin introduces a new challenge for the back half of the gameplay loop

## Run Structure
The player will start their run on the first floor entry of a procedurally generated multi-story building.  The building will be populated by various types of patrolling guards, security cameras, laser alarms, and other security systems.

### Win conditions
The player will win the run when they locate a chest containing a mystery MacGuffin and successfully exit the building with it.

### Lose conditions
The player will lose the run when they are captured by any guard.

## Art
The art is going to be highly readable, tile-based pixel art.  Tiles are 16x16 and should focus mostly on muted and high-contrast colors.

## HUD
The HUD will be very minimal.  The player has no health and all stealth indicators are available on-screen.  The only details available will be a turn indicator and a world state indicator.

## Music
The music will be one of two soundtracks depending on world state.  

If the world state is `NORMAL` the soundtrack will just be a smooth walking bass line over simple changes.  Maybe some light piano noodling.

If the world state is `ALERT` the soundtrack will still be mostly jazzy, but will introduce more instruments, dissonance, staccato, and syncopation.

## Player Character Details
Below is a definition of details related to the player and the goblin player character.

### Movement
The player character will be able to move in the 8 cardinal directions, up stairs, and down stairs.

### Actions
The player will have the following actions available to them.
- Move in the 8 cardinal directions
- Move up and down stairs
- Wait
- Open Inventory
- Examine Traits
- Use Equipment
- Throw Equipment
- Hide*

\**Note*\*: The player character will automatically hide if they move into a square occupied by building furniture.

### Player vision
The player will only see guards and security systems that are in their active line of sight.  These tiles will be fully lit and vibrant.

The player will have a dimmed "memory" of the building layout and the last place they saw a guard when they have seen a place but it is no longer in their active line of sight.  Line of sight for the player is 360 degrees.

### Traits
When starting a new run, the player will be assigned *n* number of traits.  Most of these will be positive effects to make the game easier.  Some of them will be negative traits to add suspense, excitement, and challenge to the run.

Example positive traits:
- Slippery: you can evade guard capture 1 time
- Soft-soled shoes: Your noise radius is reduced by 1
- Pitcher: you can throw items up to 3 tiles further than normal range

Example negative traits:
- Allergies: You have a chance to sneeze every 25 turns alerting guards within 25 tiles
- Lead foot: Your noise radius is increased by 1
- Narcolepsy: You have a chance to fall asleep for 3 turns every 50 turns

### Equipment
When starting a new run, the player will have *n* items available to help them sneak past guards.  These should all be beneficial, but finding the right use-case for them should be challenging.

Example equipment:
- Pet rat: Moves in random directions.  When it enters a guards vision cone, the guard will enter the `CURIOUS` state and will follow the pet rat
- Alarm clock: Will make noise audible within 50 tiles.  All affected guards will enter the `CURIOUS` state and will move to the location until one of them touches/disables the clock
- Popper x3: Can be thrown to make a noise audible within 15 tiles.  All affected guards will enter the `CURIOUS` state and will move to the location

### Last known position (LKP)
If the player has been spotted, guards will relay a last known position.  Guards will convene on this position until at least one guard touches the tile identified.  Then they will begin to look for the player.  

Guards and security systems can all update the LKP.

## World Details
Below is a definition of details related to the world or building in which a single run takes place.

### The Setting
A run will take place in a mansion.  There will be lots of bedrooms, a kitchen, closets, bathrooms, etc.  There will be (sparse) furniture that should indicate what kind of room the player is in.

An entire run will take place in a multi-floored building with the following:
- The building will be 2 procedurally generated floors
- The building will place 1 MacGuffin
- The building will contain *x* patrolling guards
- The building will contain *y* number of static security systems
- The building will contain *n* engines
- The building will have *m* exits
- The building will have at least 1 set of stairs to connect the 2 floors
- Doors will automatically close behind the player and any guards
- Building rooms will contain furniture
  
### The MacGuffin
The initial player goal is to find the MacGuffin.  Until it is obtained, what it is is unknown.  

Once the player obtains the MacGuffin, the second part of the gameplay loop begins.  The MacGuffin will function like an additional negative trait to complicate the heist.

Example MacGuffin:
- A royal corgi: Has a chance to bark every 15 rounds; audible within 10 tiles.  All affected guards will enter the `CURIOUS` state and will move to the location

### Procedural Generation
The generation algorithm will be constrained by definitions stored as JSON.  The following rules should be defined in the JSON
- Room size with defined variance
- How many of this type of room?
- What kinds of rooms may be adjacent?
- Required flag
- Furniture constraints
- MacGuffin location
- Engine placement

Additionally, the map size will be dynamic based on the selected resolution of the player.  They can pick a smaller resolution and get a smaller heist experience.  Or they can pick a ultra-wide and get a big experience.  The minimum and maximum values will be clamped so it can't get too ridiculous.  This should also make mobile support possible.

### World States
The world state can be either `NORMAL` or `ALERT`.  

#### `NORMAL` State:
In the normal state, guards are either in the `PATROL` or `CURIOUS` state.

#### `ALERT` State:
In this state, guards are all in the `ALERT` state and are actively searching for the player character. 

### Stairs
Players and guards alike will instantly traverse stairs in one turn.  When you enter a stair tile, you will begin your next turn on the new floor on the stair tile

## Guard Details
Guards can capture the player by touching a player: bumping them, *not* being adjacent them.

There can be 2 kinds of guards: humans, dogs. They are functionally identical with a few differences.
- Humans can open doors
- Dogs have increased hearing radius and will not have a segmented vision cone (but will be the same size)

If two guards ever try to occupy the same space, one of them will either wait or they will trade places.

### Guard States
Guards have 3 possible states: `PATROL`, `CURIOUS`, `ALERT`.  These states will be represented by their vision cone's color in game with `GREEN`, `YELLOW`, and `RED`

#### `PATROL` State:
In this state, the guards will move in predictable paths.  They will not typically turn around when in a hallway and will only turn if they hit a dead end or have entered a room to sweep.  Closets and furniture are not scrutinized.

The vision cone in this state will be green with two intensities: high and low.

The part of the vision cone closest to the guard will be a less translucent green. A player detected in this cone will trigger the following:
- In the next turn, all guards will enter the `ALERT` state
- In the next turn, all the world will enter the `ALERT` state
- LKP will be updated

The part of the vision cone furthest to the guard will be more translucent green.  A player detected in this cone will trigger the following:
- Only this guard will enter the `CURIOUS` state.

#### `CURIOUS` State:
In this state, the guard will move to the location of whatever triggered the state change: sound or sight.  They will abandon normal patrol routes and will go into closets or will inspect furniture if it is the source of the state change.  The `CURIOUS` state is not contagious to other guards.

The vision cone in this state will be yellow with two intensities: high and low.

The part of the vision cone closest to the guard will be a less translucent yellow. A player detected in this cone will trigger the following:
- In the next turn all guards will enter the `ALERT` state
- In the next turn the world will enter the `ALERT` state
- LKP will be updated

The part of the vision cone furthest to the guard will be more translucent yellow.  A player detected in this cone will have the following effect:
- The guard's destination will be updated to the latest location of interest.

If a guard investigates their location of interest and doesn't find the player, they will revert to the `PATROL` state and will return to their last location and route.

#### The `ALERT` State:
In this state, guards will move to the LKP.  Once any guard clears this tile, all guards will then start investigating the building with greater intensity.  They will now check closets and furniture and will frequently change positions.

The vision cone in this state will be red with one intensity.

If a player is detected in this vision cone, the LKP is updated and made the primary destination.

## Security System Details
Security systems are static and unmoving, but can change the world and/or guard state.

### Security camera
Cameras will have a vision cone whose color reflects the world state and the vision cone will rotate as much as the walls will allow.  If world state is `NORMAL` the cone is green.  If world state is `ALERT` the cone will be red.

If the player enters the cameras vision cone the following will happen:
- In the next turn all guards will enter the `ALERT` state
- In the next turn the world will enter the `ALERT` state
- LKP will be updated.

### Other security systems may or may not be implemented

## Engine Details
An engine drives unique experiences in each run.

Examples of an engine:
- A security room that will allow the player to disconnect the camera systems, but all guards will immediately enter the `CURIOUS` state
- A balcony that will allow the player to quickly drop from the second floor to the first

## Misc.

### Juice
Polish to make the game stand out.  Most juice is visual text.

Certain player actions will be indicated by some colorful, zany text moving out from the player and not bound by the turn-based constraint.  For example, if the player sneezes due to the allergy trait, a red "\*achoo\*" may radiate out from the player shrinking into oblivion.  If they have narcolepsy some "Zzz"s can radiate out.  The royal corgi MacGuffin can have visually indicated noise.

Guards might speak to each other when they pass.

## Out of scope
1. Meta-progression
2. Multiplayer