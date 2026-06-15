class_name Guard
extends Entity

signal cone_updated(inner: Array[Vector2i], outer: Array[Vector2i], color: Color, is_segmented: bool)

enum Facing { NORTH = 270, EAST = 0, SOUTH = 90, WEST = 180 }

const COLOR_GREEN: Color = Color.LIME
const COLOR_YELLOW: Color = Color.YELLOW
const COLOR_RED: Color = Color.RED
const INTENSITY_HIGH: float = 0.8
const INTENSITY_LOW: float = 0.5

var facing: Facing = Facing.WEST
var destination: Vector2i
var poi: Vector2i
var patrol_target: Vector2i
var _path: Array[Vector2i] = []
var _fov: GuardFov = GuardFov.new()

func _ready() -> void:
	can_be_remembered = false
	super()
	VisionManager.initialize_guard(self)
	TurnManager.register_world_entity(self)
	call_deferred("compute_vision")

func take_turn() -> void:
	if _path.is_empty():
		_choose_destination()
	if _path.is_empty():
		wait()
		return
	var next_cell: Vector2i = _path[0]
	if not GridManager.is_cell_available(next_cell):
		_path.clear()
		wait()
		return
	_path.remove_at(0)
	_face_toward(next_cell)
	try_move_to(next_cell)

func move_to(to: Vector2i) -> void:
	super(to)
	compute_vision()

func compute_vision() -> void:
	var zones: Array[Array] = _fov.compute(cell, facing)
	cone_updated.emit(zones[0], zones[1], _get_cone_color(), true)

func _get_cone_color() -> Color:
	return COLOR_GREEN

func _face_toward(target: Vector2i) -> void:
	var diff: Vector2i = target - cell
	if absi(diff.x) >= absi(diff.y):
		facing = Facing.EAST if diff.x > 0 else Facing.WEST
	else:
		facing = Facing.NORTH if diff.y < 0 else Facing.SOUTH

func _choose_destination() -> void:
	for i: int in range(20):
		var candidate: Vector2i = Vector2i(
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
