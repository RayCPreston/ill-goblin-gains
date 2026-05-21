class_name TileUtil

extends TileMapLayer

func _use_tile_data_runtime_update(_cell: Vector2i) -> bool:
	return true

func _tile_data_runtime_update(cell: Vector2i, tile_data: TileData) -> void:
	tile_data.modulate = VisionManager.get_cell_color(cell)
