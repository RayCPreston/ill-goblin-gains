# VFX and Juice

Juice is the real-time polish on top of the turn-based game: words that float off the goblin when it makes noise, a red "ACHOO!" and a shake when it sneezes, and a murky haze when it smells. It never changes gameplay, never blocks input, and never reveals anything the player couldn't otherwise see.

## How it works

The game itself resolves instantly, one turn at a time, in grid space. Juice runs separately, in real time: each effect is a short-lived node that animates over wall-clock seconds and then frees itself, regardless of what the turns are doing.

Gameplay never creates effect nodes or talks to `VfxManager` directly ([0006](../decisions/0006-gameplay-emits-vfx-requests.md)). It builds a request and emits it on the `GameEvents` bus, and `VfxManager` (the only listener) spawns the effect:

> `Player` builds a `FloatingTextRequest` → `GameEvents.text_emitted` → `VfxManager` spawns a `FloatingText`

### Floating text

`FloatingTextRequest` is the parameter object. Callers set only what they need; every field has a default.

| Field | Default | Meaning |
|---|---|---|
| `text` | `""` | The word to show |
| `cell` | `(0, 0)` | Grid cell it's anchored to |
| `font_size` | `8` | Pixels. The PixelOperator8 font stays crisp at multiples of 8 |
| `color` | Patrol-cone green, 55% opacity | |
| `spread_radius` | `6` | Pixels. How far from the anchor the word may land |
| `rise_pixels` | `10` | How far it floats up over its life |
| `duration` | `0.9` | Seconds from spawn to gone |
| `fov_gated` | `true` | Skip it entirely if `cell` isn't currently visible to the player |

Each `FloatingText` behaves like this:
- **Placement:** it anchors to the **center of the cell** (not the moving sprite), then picks a random offset within `spread_radius`. The offset is biased toward the rim, and each new word lands roughly opposite the previous one, so consecutive words don't pile up. It tilts slightly (±7°).
- **Animation:** it rises with an ease-out, holds full opacity for the first third of its life, fades, and frees itself.
- **Pixel snapping:** its position is rounded to whole pixels every frame, so the pixel font never blurs.
- **Layering:** it draws at `z_index` 25, above actors (20).
- **Stacking:** words emitted in the same frame are nudged upward by `font_size + 2`, so a step and a sneeze on one turn don't print on top of each other.

### The text effects in the game today

| Effect | When | Look |
|---|---|---|
| `*sneak*` | On 60% of the goblin's steps, if its noise radius is above 0 | Default size and color. Its scatter is the noise radius in pixels (× `NOISE_SPREAD_FACTOR`, currently 1.0), so it doubles as a rough read of how far the noise carried. Clumsy's stumbles scatter wider ([0007](../decisions/0007-noise-shown-as-floating-text.md)) |
| The alert burst text (Allergies: "ACHOO!") | When an `alert_burst` chance fires | 16px, red, 4px spread, rises 20px over 1.4s, plus a shake. The word comes from the trait data |

**Volume convention:** `*asterisks*` mean quiet and self-narrated, and no asterisks mean loud. Size, opacity and color scale with how much the moment matters.

### Shake

`Entity.shake(strength, jolts)` jolts the entity's `Sprite2D` child side to side in whole pixels, with the jolts shrinking (one every 0.04s), then settles it back. It moves the sprite, never the `Entity` itself, so it can't fight the movement tween or drag the camera. The alert burst uses 2px over 8 jolts. Any entity with a `Sprite2D` child can shake.

### Smell aura

Unlike text, the smell aura is always on. `VfxManager` creates one `SmellAura` once a player exists. Every frame, it moves the aura to the goblin's live position and sizes it to `Player.smell_radius` tiles.

At radius 0 (anyone without Smelly), it's invisible. Otherwise a shader draws a murky yellow-brown haze at about 32% opacity, with a slowly wobbling edge and drifting color. It sits at `z_index` 14: above the guard cones (3), below the actors (20).

## Key pieces

| Piece | Where | Role |
|---|---|---|
| `VfxManager` | [`autoloads/vfx_manager.gd`](../../project/autoloads/vfx_manager.gd) | Sole listener for VFX requests: applies the visibility check and same-frame stacking, spawns effects, and owns the smell aura |
| `GameEvents.text_emitted` | [`autoloads/game_events.gd`](../../project/autoloads/game_events.gd) | The floating-text request signal |
| `FloatingTextRequest` | [`vfx/floating_text_request.gd`](../../project/scripts/vfx/floating_text_request.gd) | Request parameters and defaults; `create(text, cell)` for one-line call sites |
| `FloatingText` | [`vfx/floating_text.gd`](../../project/scripts/vfx/floating_text.gd) | One word: placement, animation, pixel snapping. Feel constants live at the top of the file |
| `SmellAura` | [`vfx/smell_aura.gd`](../../project/scripts/vfx/smell_aura.gd), [`shaders/smell_aura.gdshader`](../../project/resources/shaders/smell_aura.gdshader) | The persistent haze; the look is tuned through shader uniforms |
| `Entity.shake()` | [`actors/entity.gd`](../../project/scripts/actors/entity.gd) | Sprite jolt |
| Emit sites | [`actors/player.gd`](../../project/scripts/actors/player.gd) `_emit_noise()`, `_emit_alert_burst()` | Where today's text effects are requested; the tuning constants sit at the top of the file |

## Extending it

- **A new text effect:** at the gameplay site, build a request with `FloatingTextRequest.create(text, cell)`, set the fields that differ, and emit `GameEvents.text_emitted`. Follow the volume convention. If the effect comes from a trait, put the text in the trait data, not in code.
- **A new kind of effect:** add a script-only node in `scripts/vfx/` (no `.tscn`), a request signal on `GameEvents`, and a handler in `VfxManager`. Gameplay only ever emits.
- **Shaking something else:** call `entity.shake(strength, jolts)`.
- **Another always-on aura:** follow `SmellAura`: `VfxManager` creates it lazily, then repositions and resizes it every frame from gameplay state.

## Gotchas

- **Text lands where the goblin is going, not where it was.** It anchors to the destination cell, while the sprite is still tweening there (0.3s).
- **A spread of 0 still renders.** The rule that a silent goblin shows no `*sneak*` lives in `Player._emit_noise()`, not in the VFX code. Other callers may legitimately want a word pinned exactly to its source.
- **The visibility check is real, but player text never hits it.** The goblin's own cell is always visible. It matters as soon as anything off-screen emits text (e.g. guard barks), because otherwise the text would reveal where they are. See [0017](../decisions/0017-nothing-leaks-through-fog-of-war.md).
- **Same-frame stacking only covers one frame.** Words from different frames rely on the alternating placement to stay apart.
- **The smell aura slides with the goblin; text doesn't.** The aura follows the live position, while text stays on its cell.

## Not built yet

- **Narcolepsy's z's:** small, quiet z's over whoever is sleeping. See [stories/trait-story-22-narcolepsy.md](../stories/trait-story-22-narcolepsy.md).
- **Loud stumble text for Clumsy** (e.g. `thump`): today a stumble only widens the `*sneak*` scatter.
- **Guards speaking as they pass, and the corgi MacGuffin's visible barks:** from the GDD's [Juice section](../design/game-design-doc.md#juice).
- **Pickup and trait-proc callouts.**

---
*Last verified against code: `4822104` on 2026-10-28.*
