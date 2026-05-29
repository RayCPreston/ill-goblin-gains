extends Camera2D

func _ready() -> void:
	call_deferred("fit_camera")

func fit_camera() -> void:
	var screen_size: Vector2 = Vector2(DisplayServer.screen_get_size())
	var available_width: float = screen_size.x - MapConfig.hud_margin_right
	var available_height: float = screen_size.y
	var scale_x: float = available_width / MapConfig.get_map_pixel_width()
	var scale_y: float = available_height / MapConfig.get_map_pixel_height()
	var min_scale: float = minf(scale_x, scale_y)
	
	var snapped_scale: float = roundf(min_scale * 4.0) / 4.0
	
	zoom = Vector2(snapped_scale, snapped_scale)
	_set_position(snapped_scale)
	
	print("screen_size: ", screen_size)
	print("raw scale: ", min_scale)
	print("snapped scale: ", snapped_scale)
	print("zoom: ", zoom)

func _set_position(snapped_scale: float) -> void:
	var map_pixel_width: float = MapConfig.get_map_pixel_width()
	var map_pixel_height: float = MapConfig.get_map_pixel_height()
	var hud_offset: float = MapConfig.hud_margin_right / 2.0
	position = Vector2((map_pixel_width / 2.0) - (hud_offset / snapped_scale), map_pixel_height / 2.0)
