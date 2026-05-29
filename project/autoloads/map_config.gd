extends Node

@export var map_width_tiles: int = 72
@export var map_height_tiles: int = 45
@export var tile_size: int = 16
@export var hud_margin_right: int = 128

func get_map_pixel_width() -> int:
	return map_width_tiles * tile_size

func get_map_pixel_height() -> int:
	return map_height_tiles * tile_size

func get_map_aspect_ratio() -> float:
	return float(map_width_tiles) / float(map_height_tiles)
