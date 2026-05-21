extends Node

var _layers: Array[TileMapLayer] = []

func initialize(layers: Array[TileMapLayer]) -> void:
	_layers = layers

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

func set_cell_modulate(cell: Vector2i, color: Color) -> void:
	for layer in _layers:
		if layer.get_cell_source_id(cell) != -1:
			layer.set_cell_modulate(cell, color)

func notify_vision_update() -> void:
	for layer in _layers:
		layer.notify_runtime_tile_data_update()
