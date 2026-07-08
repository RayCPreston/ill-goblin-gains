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

signal turn_ended

enum  Proximity { NONE, ADJACENT, OVERLAPPED }

var cell: Vector2i
var _tween: Tween

func _ready() -> void:
	cell = world_to_cell(position)
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
	return Vector2i(world_pos / Constants.TILE_SIZE)

func cell_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos * Constants.TILE_SIZE)

func cell_center_to_world(grid_pos: Vector2i) -> Vector2:
	return cell_to_world(grid_pos) + Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) / 2.0
