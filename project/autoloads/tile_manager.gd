extends Node

var _layers: Array[TileMapLayer] = []
var _astar: AStarGrid2D = AStarGrid2D.new()

func initialize(layers: Array[TileMapLayer]) -> void:
	_layers = layers
	_build_pathfinding_grid()

func is_walkable(cell: Vector2i) -> bool:
	if _layers.is_empty():
		Log.warn("TileQuery: no TileMapLayers initiated.")
		return false
	var is_walkable_tile: bool = false
	for layer in _layers:
		var tile_data: TileData = layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue
		is_walkable_tile = true
		var walkable_data = tile_data.get_custom_data("is_walkable")
		if walkable_data is bool and not walkable_data:
			return false
	return is_walkable_tile

func is_opaque(cell: Vector2i) -> bool:
	if _layers.is_empty():
		return false
	for layer in _layers:
		var tile_data: TileData = layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue
		var opaque_data = tile_data.get_custom_data("is_opaque")
		if opaque_data is bool and opaque_data:
			return true
	return false

func notify_vision_update() -> void:
	for layer in _layers:
		layer.notify_runtime_tile_data_update()

func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not _astar.region.has_point(from) or not _astar.region.has_point(to):
		return []
	if _astar.is_point_solid(to):
		return []
	var raw: PackedVector2Array = _astar.get_id_path(from, to)
	var path: Array[Vector2i] = []
	for point: Vector2 in raw:
		path.append(Vector2i(point))
	if path.size() > 0 and  path[0] == from:
		path.remove_at(0)
	return path

func _build_pathfinding_grid() -> void:
	_astar.region = Rect2i(0, 0, MapConfig.map_tile_width, MapConfig.map_tile_height)
	_astar.cell_size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for x: int in range(MapConfig.map_tile_width):
		for y: int in range(MapConfig.map_tile_height):
			var cell: Vector2i = Vector2i(x, y)
			if not is_walkable(cell):
				_astar.set_point_solid(cell, true)
