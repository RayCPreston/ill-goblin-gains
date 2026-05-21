class_name Entity
extends Node2D

@export var is_passable: bool = false
@export var is_interactable: bool = false
@export var entity_name: String = ""
@export var hide_if_not_visible = true
@export var tween_duration: float = 0.1

signal turn_ended

var cell: Vector2i
var _tween: Tween

func _ready() -> void:
	cell = world_to_cell(position)
	GridManager.register(self, cell)
	VisionManager.cell_state_changed.connect(refresh_visibility)

func _exit_tree() -> void:
	GridManager.unregister(cell)

func interact(_source: Entity) -> void:
	pass

func take_turn() -> void:
	pass

func end_turn() -> void:
	turn_ended.emit()

func try_move_to(to_cell: Vector2i) -> void:
	var occupant: Entity = GridManager.get_entity_at_cell(to_cell)
	if occupant and occupant.is_passable:
		swap_with(occupant)
	elif occupant and occupant.is_interactable:
		occupant.interact(self)
	elif GridManager.is_cell_available(to_cell):
		move_to(to_cell)
	else:
		pass
	end_turn()

func wait() -> void:
	end_turn()

func move_to(to_cell: Vector2i) -> void:
	GridManager.move_entity(self, cell, to_cell)
	cell = to_cell
	tweened_move(to_cell)

func swap_with(other: Entity) -> void:
	var other_cell: Vector2i = other.cell
	GridManager.swap_entities(self, other)
	other.cell = cell
	other.tweened_move(cell)
	cell = other_cell
	tweened_move(other_cell)

func tweened_move(target_cell: Vector2i) -> void:
	var world_cell: Vector2 = cell_to_world(target_cell)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", world_cell, tween_duration)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)

func refresh_visibility() -> void:
	if not hide_if_not_visible:
		return
	var visibility_state = VisionManager.get_state(cell)
	match visibility_state:
		PlayerFov.VisionState.VISIBLE:
			visible = true
			modulate = VisionManager.COLOR_VISIBLE
		PlayerFov.VisionState.REMEMBERED, PlayerFov.VisionState.UNSEEN:
			visible = false
	

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(world_pos / Constants.TILE_SIZE)

func cell_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos * Constants.TILE_SIZE)
