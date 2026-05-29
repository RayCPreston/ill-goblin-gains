extends Camera2D

func _ready() -> void:
	call_deferred("fit_camera")

func fit_camera() -> void:
	var snapped_scale: float = ResolutionManager.get_snapped_scale()
	zoom = Vector2(snapped_scale, snapped_scale)
	position = Vector2(MapConfig.get_map_pixel_width() / 2.0 - (MapConfig.hud_margin_right / 2.0) / snapped_scale, MapConfig.get_map_pixel_height() / 2.0)
