class_name Guard
extends Entity

signal cone_updated(inner: Array[Vector2i], outer: Array[Vector2i], color: Color, is_segmented: bool)

enum Facing { 
	NORTH = 270, 
	NORTH_EAST = 315,
	EAST = 0, 
	SOUTH_EAST = 45,
	SOUTH = 90,
	SOUTH_WEST = 135,
	WEST = 180,
	NORTH_WEST = 225
}

var facing: Facing = Facing.WEST
var destination: Vector2i
var _path: Array[Vector2i] = []
var _fov: GuardFov = GuardFov.new()
var _inner_zone: Array[Vector2i] = []
var _outer_zone: Array[Vector2i] = []
var _state: GuardStateMachine

func _ready() -> void:
	can_be_remembered = false
	is_interactable = true
	super()
	_state = GuardStateMachine.new(self)
	VisionManager.initialize_guard(self)
	TurnManager.register_world_entity(self)
	call_deferred("compute_vision")

func _exit_tree() -> void:
	super()
	TurnManager.unregister_world_entity(self)

func take_turn() -> void:
	_state.process_turn()

func react_to_proximity(source_cell: Vector2i) -> void:
	_state.react_to_proximity(source_cell)

func interact(source: Entity) -> void:
	if source is Player:
		RunState.lose("Captured by a guard.")

# -- Vision --

func get_inner_zone() -> Array[Vector2i]:
	return _inner_zone

func get_outer_zone() -> Array[Vector2i]:
	return _outer_zone

func move_to(to: Vector2i) -> void:
	super(to)
	compute_vision()

func compute_vision() -> void:
	var half_arc: float = GuardFov.HALF_ARC_DEGREES if _state.get_current_state() == GuardStateMachine.State.PATROL else 180.0
	var zones: Array[Array] = _fov.compute(cell, facing, half_arc)
	_inner_zone = zones[0]
	_outer_zone = zones[1]
	cone_updated.emit(_inner_zone, _outer_zone, _state.get_cone_color(), _state.is_segmented())

# -- Movement --

func step_along_path() -> void:
	if _path.is_empty():
		wait()
		return
	var next_cell: Vector2i = _path[0]
	var occupant: Entity = GridManager.get_actor_at_cell(next_cell)
	var occupant_interactable: bool = occupant != null and occupant.is_interactable
	if not GridManager.is_cell_available(next_cell) and not occupant_interactable:
		_path.clear()
		wait()
		return
	_path.remove_at(0)
	face_toward(next_cell)
	try_move_to(next_cell)

func navigate_to(target: Vector2i) -> void:
	var path: Array[Vector2i] = TileManager.find_path(cell, target)
	if path.is_empty():
		return
	destination = target
	_path = path

func choose_destination(max_range: int = 0) -> void:
	for i: int in range(20):
		var candidate: Vector2i
		if max_range > 0:
			candidate = Vector2i(
				clampi(cell.x + randi_range(-max_range, max_range), 0, MapConfig.map_tile_width - 1),
				clampi(cell.y + randi_range(-max_range, max_range), 0, MapConfig.map_tile_height - 1)
			)
		else:
			candidate = Vector2i(
				randi() % MapConfig.map_tile_width,
				randi() % MapConfig.map_tile_height
			)
		if candidate == cell or not TileManager.is_walkable(candidate):
			continue
		var path: Array[Vector2i] = TileManager.find_path(cell, candidate)
		if path.is_empty():
			continue
		destination = candidate
		_path = path
		return

func clear_path() -> void:
	_path.clear()

func is_path_empty() -> bool:
	return _path.is_empty()

# -- Facing --

func face_toward(target: Vector2i) -> void:
	var diff: Vector2i = target - cell
	var angle: float = rad_to_deg(atan2(float(diff.y), float(diff.x)))
	if angle < 0.0:
		angle += 360.0
	var best: Facing = Facing.EAST
	var best_delta: float = 360.0
	for dir: Facing in Facing.values():
		var delta: float = absf(angle - float(dir))
		if delta > 180.0:
			delta = 360.0 - delta
		if delta < best_delta:
			best_delta = delta
			best = dir
	facing = best
