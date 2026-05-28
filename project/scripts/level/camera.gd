extends Camera2D

func _ready() -> void:
	fit_camera()

func fit_camera() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var available_width: float = viewport_size.x - MapConfig.hud_margin_right
	var available_height: float = viewport_size.y
	print("Viewport: ", viewport_size)
	print("Map pixels: ", MapConfig.get_map_pixel_width(), " x ", MapConfig.get_map_pixel_height())
	
	
	var scale_x: float = available_width / MapConfig.get_map_pixel_width()
	var scale_y: float = available_height / MapConfig.get_map_pixel_height()
	var min_scale: float = min(scale_x, scale_y)
	zoom = Vector2(min_scale, min_scale)
	position = Vector2(MapConfig.get_map_pixel_width() / 2.0, MapConfig.get_map_pixel_height() / 2.0)
	print("Zoom: ", zoom)
	print("Camera position: ", position)
