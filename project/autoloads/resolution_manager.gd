extends Node

func get_snapped_scale() -> float:
	var screen_size: Vector2 = Vector2(DisplayServer.screen_get_size())
	var available_width: float = screen_size.x - MapConfig.hud_margin_right
	var available_height: float = screen_size.y
	var scale_x: float = available_width / MapConfig.get_map_pixel_width()
	var scale_y: float = available_height / MapConfig.get_map_pixel_height()
	var min_scale: float = minf(scale_x, scale_y)
	return max(min_scale)
