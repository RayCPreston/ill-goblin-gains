I'm not sure what the best way to procgen.  I want the heist building to feel like a real building.  Some bedrooms.  A big space for a kitchen.  A building should have n plus/minus m number of rooms.  A room is defined as x plus/minus 5 pixels by y plus/minus 5 pixels.  A closet will have a definition.  At least one staircase.  Define a list of features: an indoor balcony to drop down, a big showroom with lots of spotlights, a surveillance room to cut cameras but has lasers, etc.  Then give my proc gen rules for how this should come together?  A lot of the definitions can live as json in my project.  This is what I have in my head.4:51 PMClaude responded: This is a really solid design instinct.This is a really solid design instinct. What you're describing is called template-driven procgen — you define the vocabulary of the building in data (JSON), and the generator assembles it according to rules. It's the right approach for a heist game because it gives you architectural plausibility without hand-crafting every map.
Here's how I'd structure it:

Three layers of data in JSON
Room definitions — the vocabulary
json{
  "bedroom": { "w": [8,14], "h": [8,14], "tags": ["private", "upstairs"] },
  "kitchen":  { "w": [16,24], "h": [12,18], "tags": ["ground", "utility"] },
  "closet":   { "w": [4,6],  "h": [4,6],  "tags": ["any", "adjacent_to:bedroom"] },
  "showroom": { "w": [24,32], "h": [20,28], "tags": ["ground", "feature"] },
  "surveillance": { "w": [8,10], "h": [8,10], "tags": ["any", "feature", "has_lasers"] }
}
Building templates — the rules
json{
  "mansion": {
    "rooms": { "min": 8, "max": 14 },
    "required": ["kitchen", "surveillance", "staircase"],
    "pool": ["bedroom:2-4", "closet:1-3", "showroom:0-1", "balcony:0-2"],
    "MacGuffin_room_tags": ["private", "upstairs"]
  }
}
Feature definitions — special overlays placed inside rooms
json{
  "spotlight_array": { "requires_room": "showroom", "density": 0.3 },
  "laser_grid":      { "requires_room": "surveillance" },
  "indoor_balcony":  { "min_room_h": 20, "drops_to": "ground" }
}

The generation pipeline
This is the key insight — you don't generate geometry first. You generate intent first, then resolve it into geometry:
1. PLAN    → pick building template, roll room list from pool
2. ARRANGE → place rooms using constraint rules (adjacency, floor level)
3. CONNECT → corridor pass, place doors between adjacent rooms
4. FURNISH → place features inside rooms per their rules
5. PLACE   → MacGuffin, guards, exit, player start
6. RENDER  → convert grid to tile indices via neighbor check

The arrangement step is the hardest — here's a practical approach
Rather than full BSP (which produces maze-like layouts), use anchor-and-grow:

Place the largest required room first (showroom, kitchen) — these are your anchors
Attach other rooms to the perimeter of existing rooms, preferring shared walls
Enforce tag constraints as you place (e.g. closets must be adjacent to a bedroom)
Staircases go at the boundary between floor levels

This naturally produces building-like layouts because large rooms anchor the shape and smaller rooms cluster around them — just like real architecture.

What stays in GDScript vs JSON
JSONGDScriptRoom sizes, tags, countsAnchor-and-grow placement logicBuilding templatesConstraint validatorFeature definitionsNeighbor-check tile resolverMacGuffin placement rulesGuard path generation
The JSON is your designer brain. The GDScript is just the engine that respects it. This means you can tune the feel of buildings — add a new building type, tweak room ratios — without touching code.

The one thing I'd add: give each room a role tag that your guard AI and camera systems can read directly. A guard in a "private" room behaves differently than one in a "showroom". Since the room definitions already carry tags, this comes for free.
Want me to sketch the GDScript class structure for the pipeline, or flesh out the JSON schema further?