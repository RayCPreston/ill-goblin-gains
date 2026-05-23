class_name PlayerFov

enum VisionState { UNSEEN, REMEMBERED, VISIBLE }

var max_range = 50
var _memory: Dictionary = {}

func compute(origin: Vector2i) -> Dictionary:
	for cell in _memory:
		if _memory[cell] == VisionState.VISIBLE:
			_memory[cell] = VisionState.REMEMBERED
	_memory[origin] = VisionState.VISIBLE
	for quadrant in range(4):
		_scan(origin, quadrant, 1, -1.0, 1.0)
	return _memory

func get_state(cell: Vector2i) -> VisionState:
	return _memory.get(cell, VisionState.UNSEEN)

func is_visible(cell: Vector2i) -> bool:
	return get_state(cell) == VisionState.VISIBLE

func _transform(origin: Vector2i, quadrant: int, row: int, col: int) -> Vector2i:
	match quadrant:
		0: return Vector2i(origin.x + col, origin.y - row) #N
		1: return Vector2i(origin.x + row, origin.y + col) #E
		2: return Vector2i(origin.x + col, origin.y + row) #S
		3: return Vector2i(origin.x - row, origin.y + col) #W
	return origin

func _slope(row: int, col: int) -> float:
	return float(2 * col - 1) / float(2 * row)

func _is_symmetric(origin: Vector2i, quadrant: int, row: int, col: int, start_slope: float, end_slope: float) -> bool:
	var world_cell: Vector2i = _transform(origin, quadrant, row, col)
	var dist: int = maxi(abs(world_cell.x - origin.x), abs(world_cell.y - origin.y))
	return dist <= max_range \
		and float(col) >= float(row) * start_slope \
		and float(col) <= float(row) * end_slope

func _is_opaque(cell: Vector2i) -> bool:
	if TileManager.is_opaque(cell):
		return true
	var furniture: Entity = GridManager.get_furniture_at_cell(cell)
	if not furniture:
		return false
	if furniture.allows_player_vision:
		return false
	return furniture.blocks_vision

func _scan(origin: Vector2i, quadrant: int, row: int, start_slope: float, end_slope: float) -> void:
	if row > max_range:
		return
	if start_slope >= end_slope:
		return
	var min_col: int = int(floor(float(row) * start_slope + 0.5))
	var max_col: int = int(ceil(float(row) * end_slope - 0.5))
	var prev_was_opaque: bool = false
	for col in range(min_col, max_col + 1):
		var cell: Vector2i = _transform(origin, quadrant, row, col)
		var is_opaque: bool = _is_opaque(cell)
		var is_symmetric: bool = _is_symmetric(origin, quadrant, row, col, start_slope, end_slope)
		if is_opaque or is_symmetric:
			_memory[cell] = VisionState.VISIBLE
		if prev_was_opaque and not is_opaque:
			start_slope = _slope(row, col)
		if not prev_was_opaque and is_opaque:
			var next_end: float = _slope(row, col)
			_scan(origin, quadrant, row + 1, start_slope, next_end)
		prev_was_opaque = is_opaque
	if not prev_was_opaque:
		_scan(origin, quadrant, row + 1, start_slope, end_slope)
