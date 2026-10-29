class_name Entity
extends Node2D

@export var entity_name: String = ""
var can_swap: bool = false
var can_overlap: bool = false
var is_interactable: bool = false
var is_furniture: bool = false
var can_be_remembered: bool = true
var can_hide_player: bool = false
var blocks_vision: bool = false
var allows_player_vision: bool = false
var tween_duration: float = 0.3

const SHAKE_STRENGTH: int = 2
const SHAKE_JOLTS: int = 6
const SHAKE_JOLT_DURATION: float = 0.04
const SLEEP_TEXT_FONT_SIZE: int = 8
const SLEEP_TEXT_COLOR: Color = Color(0.82, 0.84, 0.9, 0.9)
const SLEEP_TEXT_SPREAD: float = 3.0
const SLEEP_TEXT_RISE_PIXELS: float = 14.0
const SLEEP_TEXT_DURATION: float = 1.2
const SLEEP_TIP_ANGLE: float = PI / 2.0
const SLEEP_TIP_DURATION: float = 0.15

signal turn_ended

enum  Proximity { NONE, ADJACENT, OVERLAPPED }

var cell: Vector2i
var is_sleeping: bool:
	get:
		return _sleep_turns_remaining > 0
var _tween: Tween
var _shake_tween: Tween
var _tip_tween: Tween
var _sprite_rest: Vector2 = Vector2.ZERO
var _sprite_jolt: Vector2 = Vector2.ZERO
var _sprite_tilt: float = 0.0
var _sleep_turns_remaining: int = 0
var _sleep_text: String = ""

func _ready() -> void:
	cell = world_to_cell(position)
	var sprite: Node2D = _get_sprite()
	if sprite:
		_sprite_rest = sprite.position
	if is_furniture:
		GridManager.register_furniture(self, cell)
	else:
		GridManager.register_actor(self, cell)
	VisionManager.cell_state_changed.connect(refresh_visibility)

func _exit_tree() -> void:
	if is_furniture:
		GridManager.unregister_furniture(cell)
	else:
		GridManager.unregister_actor(cell)

func interact(_source: Entity) -> void:
	pass

func take_turn() -> void:
	pass

func on_proximity_changed(_proximity: Proximity, _entity: Entity) -> void:
	pass

func end_turn() -> void:
	turn_ended.emit()

func try_move_to(to_cell: Vector2i) -> void:
	var furniture: Entity = GridManager.get_furniture_at_cell(to_cell)
	if furniture and not furniture.can_overlap:
		if furniture.is_interactable:
			furniture.interact(self)
		end_turn()
		return
	var occupant: Entity = GridManager.get_actor_at_cell(to_cell)
	if occupant and occupant.can_swap:
		swap_with(occupant)
	elif occupant and occupant.is_interactable:
		occupant.interact(self)
	elif GridManager.is_cell_available(to_cell):
		move_to(to_cell)
	end_turn()

func wait() -> void:
	end_turn()

## Falling asleep again while already asleep never shortens the sleep.
func fall_asleep(turns: int, text: String) -> void:
	if turns <= 0:
		return
	if not is_sleeping:
		_tip_over()
	_sleep_turns_remaining = maxi(_sleep_turns_remaining, turns)
	_sleep_text = text
	_emit_sleep_text()

## Spends one turn asleep in place of acting.
func sleep_through_turn() -> void:
	_sleep_turns_remaining -= 1
	_emit_sleep_text()
	if not is_sleeping:
		_stand_up()
	wait()

func move_to(to_cell: Vector2i) -> void:
	var from_cell: Vector2i = cell
	cell = to_cell
	GridManager.move_entity(self, from_cell, to_cell)
	tweened_move(to_cell)

func swap_with(other: Entity) -> void:
	var my_cell: Vector2i = cell
	var other_cell: Vector2i = other.cell
	cell = other_cell
	other.cell = my_cell
	GridManager.swap_entities(self, other)
	other.tweened_move(my_cell)
	tweened_move(other_cell)

func tweened_move(target_cell: Vector2i) -> void:
	var world_cell: Vector2 = cell_to_world(target_cell)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", world_cell, tween_duration)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)

## Jitters the `Sprite2D` child side to side in whole-pixel jolts that taper
## off. Moves the sprite rather than the Entity itself so it never fights
## tweened_move() over `position` (or drags the camera along with it).
func shake(strength: int = SHAKE_STRENGTH, jolts: int = SHAKE_JOLTS) -> void:
	if _get_sprite() == null:
		return
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	for i: int in jolts:
		var amplitude: int = maxi(1, roundi(float(strength * (jolts - i)) / float(jolts)))
		var side: int = 1 if i % 2 == 0 else -1
		var jolt: Vector2 = Vector2(side * amplitude, randi_range(-1, 0))
		_shake_tween.tween_callback(_set_sprite_jolt.bind(jolt))
		_shake_tween.tween_interval(SHAKE_JOLT_DURATION)
	_shake_tween.tween_callback(_set_sprite_jolt.bind(Vector2.ZERO))

func refresh_visibility() -> void:
	var visibility_state = VisionManager.get_state(cell)
	match visibility_state:
		PlayerFov.VisionState.VISIBLE:
			visible = true
			modulate = VisionManager.COLOR_VISIBLE
		PlayerFov.VisionState.REMEMBERED:
			if can_be_remembered:
				modulate = VisionManager.COLOR_REMEMBERED
				visible = true
			else:
				visible = false
		PlayerFov.VisionState.UNSEEN:
			visible = false
	

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Constants.world_to_cell(world_pos)

func cell_to_world(grid_pos: Vector2i) -> Vector2:
	return Constants.cell_to_world(grid_pos)

func cell_center_to_world(grid_pos: Vector2i) -> Vector2:
	return Constants.cell_center_to_world(grid_pos)

func _emit_sleep_text() -> void:
	if _sleep_text.is_empty():
		return
	var request: FloatingTextRequest = FloatingTextRequest.create(_sleep_text, cell)
	request.font_size = SLEEP_TEXT_FONT_SIZE
	request.color = SLEEP_TEXT_COLOR
	request.spread_radius = SLEEP_TEXT_SPREAD
	request.rise_pixels = SLEEP_TEXT_RISE_PIXELS
	request.duration = SLEEP_TEXT_DURATION
	GameEvents.text_emitted.emit(request)

func _tip_over() -> void:
	if _get_sprite() == null:
		return
	if _tip_tween:
		_tip_tween.kill()
	_tip_tween = create_tween()
	_tip_tween.tween_method(_set_sprite_tilt, _sprite_tilt, SLEEP_TIP_ANGLE, SLEEP_TIP_DURATION)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

func _stand_up() -> void:
	if _get_sprite() == null:
		return
	if _tip_tween:
		_tip_tween.kill()
	_set_sprite_tilt(0.0)

func _set_sprite_jolt(jolt: Vector2) -> void:
	_sprite_jolt = jolt
	_update_sprite_transform()

func _set_sprite_tilt(angle: float) -> void:
	_sprite_tilt = angle
	_update_sprite_transform()

## Shake and tilt both drive the sprite, so they're combined here rather than
## each owning `position`. Sprites are anchored at their top-left corner
## (`centered = false`), so the tilt pivots around the tile's center instead.
func _update_sprite_transform() -> void:
	var sprite: Node2D = _get_sprite()
	var half_tile: Vector2 = Vector2.ONE * (Constants.TILE_SIZE / 2.0)
	var pivot_correction: Vector2 = half_tile - half_tile.rotated(_sprite_tilt)
	sprite.rotation = _sprite_tilt
	sprite.position = (_sprite_rest + pivot_correction + _sprite_jolt).round()

func _get_sprite() -> Node2D:
	return get_node_or_null("Sprite2D") as Node2D
