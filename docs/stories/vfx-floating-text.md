# VFX Story: Floating Text System (`*sneak*` slice)

**Status:** Ready for CC · **Depends on:** nothing · **Replaces:** `SoundPulse` ring VFX

## Why

A large share of the intended game feel is *text* juice — small words that pop off the world and fade. Rather than build that ad hoc per feature, this story lands one reusable floating-text VFX and proves it on the smallest possible slice: every player step spits a subtle `*sneak*` near the goblin.

The `*sneak*` slice is deliberately trivial so the *system* gets the attention. If the foundation is right, later features (Clumsy's `thump`/`trip`/`stumble`, Allergies' `ACHOO!`, pickup and trait-proc callouts, guard barks) are one call each with different arguments.

## Scope

**In:** a `FloatingText` VFX node, a `FloatingTextRequest` data object, a `GameEvents.text_emitted` signal, `VfxManager` spawning, `Player._emit_noise()` emitting `*sneak*`, removal of the sound-pulse ring.

**Out:** any other caller. Do not wire Clumsy, Allergies, pickups, or guard barks in this story — the extension points are noted below but stay unbuilt.

---

## Design

### 1. `FloatingTextRequest` — the parameter object

`project/scripts/vfx/floating_text_request.gd`, `class_name FloatingTextRequest extends RefCounted`.

Follows the existing `RunLoadout` precedent (a `RefCounted` data object passed through a `GameEvents` signal). A parameter object rather than a long positional signature, because this list will grow as more effects use it and a 7-arg signal is unreadable at the call site.

| Field | Type | Default | Notes |
|---|---|---|---|
| `text` | `String` | `""` | The word to show. |
| `cell` | `Vector2i` | `Vector2i.ZERO` | Grid cell the text is anchored to. **Cell, not pixel position** — see §4. |
| `font_size` | `int` | `8` | Ray's requested knob. |
| `color` | `Color` | `Color(0.15, 0.15, 0.15, 0.55)` | Subtle dark translucent grey per the brief. |
| `spread_radius` | `float` | `6.0` | Pixels. Random placement disc — see §3. Callers that represent noise **derive this from the noise radius** — see §5. |
| `rise_pixels` | `float` | `10.0` | How far it floats up over its life. |
| `duration` | `float` | `0.9` | Seconds, spawn to gone. |
| `fov_gated` | `bool` | `true` | If true, suppressed when `cell` is not currently `VISIBLE`. |

Provide a static convenience constructor so simple call sites stay one line:

```gdscript
static func create(text: String, cell: Vector2i) -> FloatingTextRequest
```

Caller overrides any field it cares about afterward. Every field has a working default; a request with only `text` and `cell` set must render correctly.

### 2. `GameEvents.text_emitted(request: FloatingTextRequest)`

New signal on the `GameEvents` autoload, following the file's existing `@warning_ignore("unused_signal")` convention. Gameplay code emits; `VfxManager` is the only listener. This preserves the codebase's "signals for upward communication" rule — `Player` must not reach into `VfxManager` directly.

### 3. `FloatingText` — the VFX node

`project/scripts/vfx/floating_text.gd`, `class_name FloatingText extends Node2D`. Script-only, no `.tscn` — mirrors `SoundPulse` and `SmellAura` exactly.

Requirements:

- Owns a single `Label` child. Font: `res://assets/fonts/pixel_operator/PixelOperator8.ttf` (the 8px-native cut — it is designed for exactly this size and stays crisp where the regular cut does not). Set via `theme_override_fonts/font` + `theme_override_font_sizes/font_size` + `theme_override_colors/font_color`, matching how `end_screen.tscn` already styles labels.
- `z_index = 25`. Actors (`goblin.tscn`, `guard.tscn`) sit at 20, so the old VFX layers (14, 15) would put text *behind* the goblin. Text must draw on top of everything.
- **Random placement (the core primitive):** on `_ready()`, pick one offset within `spread_radius` and keep it for the node's whole life. Do not re-randomize per frame.
  ```gdscript
  var angle: float = randf() * TAU
  var dist: float = sqrt(randf()) * spread_radius
  var offset: Vector2 = Vector2(cos(angle), sin(angle)) * dist
  ```
  The `sqrt` makes the distribution uniform across the disc. **Ship it without the `sqrt`** (i.e. `var dist: float = randf() * spread_radius`), biasing placement toward the center: most words cluster near the goblin and only occasionally reach the rim, which reads as "the noise is mostly *here*, and carries out to *there*." Leave the `sqrt` in a comment — it is a feel knob worth trying both ways.
- **Horizontal centering must be measured, not deferred.** A `Label`'s `size` is not valid until it has been laid out, so `position -= size / 2` on the spawn frame silently does nothing. Measure the string directly instead:
  ```gdscript
  var measured: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
  ```
  and offset by half the measured width. This is the single most likely thing to be quietly wrong; verify the text is actually centered over the goblin, not hanging off to the right.
- **Animation:** rise `rise_pixels` upward and fade alpha to 0 over `duration`, then `queue_free()`. Use a `Tween` (`create_tween().set_parallel()`), not `_process` accumulation — `SoundPulse` uses `_process` only because it needs `queue_redraw()` per frame for `_draw`; a Label does not. Ease out on the rise, and hold full alpha for roughly the first third before fading, so short words stay readable.
- **Pixel snapping:** the game runs `window/stretch/scale_mode="integer"` at 1280x720 with a 16px grid. A tweened float position puts the pixel font on a subpixel boundary and it goes soft. Round the final rendered position to whole pixels every frame (e.g. tween a float `_rise` value and assign `position = Vector2(round(base.x + offset.x), round(base.y + offset.y - _rise))` in `_process`). Sub-pixel blur on a pixel font is obvious and is the difference between this reading as intentional or as a bug.

### 4. `VfxManager` — spawning and gating

`VfxManager` connects `GameEvents.text_emitted` in `_ready()` and handles it:

1. **FOV gate.** If `request.fov_gated` and `VisionManager.get_state(request.cell) != PlayerFov.VisionState.VISIBLE`, return without spawning. This exists for the same reason the door system decouples sprite state from logical state — text rendering off-screen events would leak guard movement through fog of war. For the `*sneak*` slice the gate is always satisfied (the player's own cell is by definition visible), so it will not be exercised by this story's happy path; see the manual test in AC 7 for how to actually prove it works rather than shipping untested branch.
2. **Position from cell, not from `player.position`.** `Entity.tweened_move` animates `position` over `tween_duration` (0.3s), so anchoring to the live node position makes the text drift along with the goblin mid-step. Anchor to the *destination cell center*, computed from `request.cell`.
   `Entity` already has `cell_center_to_world()` but `VfxManager` is not an `Entity`. **Lift `world_to_cell` / `cell_to_world` / `cell_center_to_world` onto `Constants`** as plain static-style helpers and have `Entity`'s existing methods delegate to them. Do not duplicate the arithmetic — `Constants.TILE_SIZE` math is already open-coded in six places and this is a chance to stop the spread, not add to it.
3. **Same-frame overlap nudge.** Two requests in one turn (which Clumsy will produce: a step plus a stumble) would otherwise land on top of each other and read as one garbled word. Keep a small counter of texts spawned this frame and offset each additional one upward by ~`font_size + 2` pixels, resetting the counter each frame. Five lines; prevents the most obvious failure mode without building a real queue. A full stagger/queue is explicitly deferred.

### 5. Emitting `*sneak*`

`Player._emit_noise()` already fires on every completed `move_to()` and knows the noise radius. Add the text emit there:

```gdscript
if radius > 0:
    var request: FloatingTextRequest = FloatingTextRequest.create("*sneak*", cell)
    request.spread_radius = float(radius * Constants.TILE_SIZE) * NOISE_SPREAD_FACTOR
    GameEvents.text_emitted.emit(request)
```

**Radius 0 emits nothing at all.** Padfoot makes the goblin *silent*, and silence should render as silence — no word, no indicator. This matches what the pulse ring already did (a `draw_arc` of radius 0 drew nothing), so it preserves existing behavior rather than inventing new behavior. It is also the stronger read: a player with Padfoot notices the absence of the word they have seen on every other step, which sells the trait better than a centered `*sneak*` would.

**Put this guard at the emit site in `Player`, not in `VfxManager` or `FloatingText`.** A global "`spread_radius == 0` means do not render" rule would be wrong — other callers legitimately want zero scatter *and* want to be seen (a pickup callout or trait proc pinned exactly to its source). Only *noise* text is suppressed at zero, because only noise text is standing in for a radius.

**The scatter is the radius indicator.** This is the design decision that replaces the deleted pulse ring (§6). `radius` here is the already-computed effective noise radius, so the spread falls out of the mechanics for free:

| Case | `noise_radius` | Result |
|---|---|---|
| Padfoot | 0 | **No text at all.** Silent goblin, silent screen. |
| Default | 2 | Modest scatter around the goblin. |
| Clumsy step | 2 x multiplier | Visibly wider scatter. |

`NOISE_SPREAD_FACTOR` is a `const` on `Player` (start at `0.6`). At `1.0` a default step can throw the word two full tiles out, which reads as disconnected from the goblin rather than as *its* noise; damping keeps the relative read while holding the text visually attached.

**Extension point, do not build:** `_emit_noise(radius_multiplier)` already receives Clumsy's multiplier from `traits.check_on_move_chance_effects()`. When Clumsy's juice lands, a `radius_multiplier > 1` step is exactly where a bigger, louder `thump`/`trip`/`stumble` request replaces or accompanies the `*sneak*` — larger `font_size`, higher `duration`, less transparent `color`. Leave the seam clean; write no branch for it now.

### 6. Removing the sound pulse

Delete `project/scripts/vfx/sound_pulse.gd` (+ `.uid`), remove `VfxManager._on_sound_emitted` and its connection, and remove `GameEvents.sound_emitted` and its emit in `Player._emit_noise()`. The signal has no other listener, so leaving it in place would be dead code.

**Decision made — the ring is not coming back.** It read as off-putting, and a permanent expanding circle on every single step is visual noise in a game where the player takes hundreds of steps per run. The radius information it carried is preserved *approximately* by the scatter width in §5: Padfoot centers the word on the goblin, a normal step scatters modestly, a Clumsy step scatters wide. That is a less exact representation than a measured ring and it is a deliberate trade — the text is doing double duty as flavor and as a soft radius read, and being read at a glance matters more here than being read precisely.

---

## Acceptance Criteria

1. `FloatingTextRequest` exists as a `RefCounted` with all fields and defaults in §1, plus a static `create(text, cell)`. A request with only `text` and `cell` set renders correctly.
2. `GameEvents.text_emitted(request: FloatingTextRequest)` exists; `VfxManager` is its only listener; no gameplay script references `VfxManager` directly.
3. Every player **move** shows a small dark translucent `*sneak*` near the goblin. `wait()` does not produce one (it does not call `_emit_noise` unless a trait makes it, and that path should behave identically if it does).
4. Placement is randomized within `spread_radius` each time, biased toward the center, fixed for the life of that instance — successive steps visibly land the word in different spots, and a single word does not jitter while rising.
5. Scatter width tracks noise radius, and **radius 0 shows nothing**. Verify all three by temporarily setting `Player.noise_radius`: at 0 no text appears on any step; at the default 2 it scatters modestly; at a doubled radius it scatters visibly wider. The suppression lives in `Player._emit_noise()`, not in `VfxManager` or `FloatingText` — a request with `spread_radius == 0` from any other caller must still render.
6. The text is horizontally centered over its anchor point, rises, fades, and frees itself. No orphan nodes accumulate: after ~50 steps, `VfxManager`'s child count is back to baseline.
7. Text is crisp at every point in the animation — no subpixel blur on the pixel font.
8. `fov_gated` demonstrably works. Because the player's own cell is always visible, prove it with a throwaway check rather than assuming: temporarily emit a request anchored to a cell known to be outside FOV (e.g. offset the cell by +20 on one axis) with `fov_gated = true` and confirm nothing spawns, then with `fov_gated = false` and confirm it does. Remove the temporary code before finishing.
9. Two requests emitted in the same frame do not render on top of each other.
10. `sound_pulse.gd`, `GameEvents.sound_emitted`, and `VfxManager._on_sound_emitted` are gone; no references remain.
11. `Constants` owns the cell/world conversion helpers and `Entity` delegates to them; behavior is unchanged.

## Conventions Checklist

- Explicit type declarations everywhere — no inferred `var`.
- `RefCounted` utilities are not Nodes and not in the scene tree (`FloatingTextRequest`); `FloatingText` **is** a Node because it renders.
- VFX scripts live in `scripts/vfx/`, script-only, no `.tscn`, following `SoundPulse`/`SmellAura`.
- No physics, no reflection, no `match` on effect kinds outside `GameData`/`PlayerTraitState`.
- Signals for upward communication.

## Tuning Values to Surface

Put the feel knobs where Ray can find them without reading the whole file — as `const` at the top of `FloatingText`, as `FloatingTextRequest` defaults, or as `Player.NOISE_SPREAD_FACTOR`. He will iterate on all of these:

`NOISE_SPREAD_FACTOR` · `rise_pixels` · `duration` · `color` alpha · `font_size` · center-biased-vs-uniform distribution.

## Style Convention Worth Holding

`*sneak*` wraps the word in asterisks — that reads as quiet, internal, self-narrated. Louder events should drop them (`thump`, `stumble`, `ACHOO!`). Keeping asterisks-means-quiet consistent gives the text system a cheap volume dial that costs nothing to implement and is legible without a legend.

## Open Questions for Ray (answer after seeing it run)

1. Is `NOISE_SPREAD_FACTOR` at `0.6` the right damping, or does the word need to stay tighter to the goblin?
2. Is `*sneak*` on *every* step too much once you have played twenty turns of it? If so the fix is probability (show it 1 turn in N) rather than removing it — worth trying before redesigning.
