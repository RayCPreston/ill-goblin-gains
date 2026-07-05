extends Node2D

signal cell_state_changed

const COLOR_VISIBLE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_REMEMBERED: Color = Color(0.4, 0.4, 0.4, 1.0)
const COLOR_UNSEEN: Color = Color(0.0, 0.0, 0.0, 1.0)
const CONE_INNER_ALPHA: float = 0.35
const CONE_OUTER_ALPHA: float = 0.15

var _vision: Dictionary = {}
var _guard_cones: Dictionary = {}

func _ready() -> void:
	z_index = 3

func initialize_player(player: Player) -> void:
	player.vision_updated.connect(_on_vision_updated)

func initialize_guard(guard: Guard) -> void:
	guard.cone_updated.connect(
		func(inner: Array[Vector2i], outer: Array[Vector2i], color: Color, is_segmented: bool) -> void:
			_on_cone_updated(guard, inner, outer, color, is_segmented)
	)

func get_state(cell: Vector2i) -> PlayerFov.VisionState:
	return _vision.get(cell, PlayerFov.VisionState.UNSEEN)

func get_cell_color(cell: Vector2i) -> Color:
	match get_state(cell):
		PlayerFov.VisionState.UNSEEN: 
			return COLOR_UNSEEN
		PlayerFov.VisionState.REMEMBERED: 
			return COLOR_REMEMBERED
	return COLOR_VISIBLE

func _draw() -> void:
	for guard: Guard in _guard_cones:
		if not guard.visible:
			continue
		var cone: Dictionary = _guard_cones[guard]
		var inner_color: Color = Color(cone["color"].r, cone["color"].g, cone["color"].b, CONE_INNER_ALPHA)
		var outer_alpha: float = CONE_INNER_ALPHA if not cone["is_segmented"] else CONE_OUTER_ALPHA
		var outer_color: Color = Color(cone["color"].r, cone["color"].g, cone["color"].b, outer_alpha)
		for cell: Vector2i in cone["inner"]:
			if get_state(cell) == PlayerFov.VisionState.VISIBLE:
				draw_rect(_cell_rect(cell), inner_color)
		for cell: Vector2i in cone["outer"]:
			if get_state(cell) == PlayerFov.VisionState.VISIBLE:
				draw_rect(_cell_rect(cell), outer_color)

func _cell_rect(cell: Vector2i) -> Rect2:
	var tile_size: int = Constants.TILE_SIZE
	return Rect2(cell.x * tile_size, cell.y * tile_size, tile_size, tile_size)

func clear_guard_cones() -> void:
	_guard_cones.clear()

func _on_vision_updated(cells: Dictionary) -> void:
	_vision = cells
	TileManager.notify_vision_update()
	cell_state_changed.emit()

func _on_cone_updated(guard: Guard, inner: Array[Vector2i], outer: Array[Vector2i], color: Color, is_segmented: bool) -> void:
	var inner_dict: Dictionary = {}
	var outer_dict: Dictionary = {}
	for cell: Vector2i in inner:
		inner_dict[cell] = true
	for cell: Vector2i in outer:
		outer_dict[cell] = true
	_guard_cones[guard] = { "inner": inner_dict, "outer": outer_dict, "color": color, "is_segmented": is_segmented }
	TileManager.notify_vision_update()
	queue_redraw()
	cell_state_changed.emit()
