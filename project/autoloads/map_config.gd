extends Node

const MIN_TILE_WIDTH: int = 40
const MAX_TILE_WIDTH: int = 100
const MIN_TILE_HEIGHT: int = 20
const MAX_TILE_HEIGHT: int = 60

@export var map_tile_width: int = 72
@export var map_tile_height: int = 45
@export var hud_margin_right: int = 128

func get_map_pixel_width() -> int:
	return map_tile_width * Constants.TILE_SIZE

func get_map_pixel_height() -> int:
	return map_tile_height * Constants.TILE_SIZE

func get_map_aspect_ratio() -> float:
	return float(map_tile_width) / float(map_tile_height)

func calculate_map_dimensions(available_pixels: Vector2) -> void:
	map_tile_width = clampi(int(available_pixels.x / Constants.TILE_SIZE), MIN_TILE_WIDTH, MAX_TILE_WIDTH)
	map_tile_height = clampi(int(available_pixels.y / Constants.TILE_SIZE), MIN_TILE_HEIGHT, MAX_TILE_HEIGHT)
