extends Camera2D

const ZOOM_STEP: float = 1.0
const ZOOM_MIN: float = 1.0
const ZOOM_MAX: float = 4.0

var _base_scale: float = 1.0
var _current_zoom: int = 0
var _player_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	GameEvents.zoom_in_requested.connect(zoom_in)
	GameEvents.zoom_out_requested.connect(zoom_out)
	GameEvents.player_pos_updated.connect(player_pos_updated)
	call_deferred("fit_camera")

func fit_camera() -> void:
	#_base_scale = ResolutionManager.get_snapped_scale() #TODO: Support configurable resolutions
	_base_scale = 1.0
	_current_zoom = 0
	print("fit_camera - base_scale: ", _base_scale)
	apply_zoom()

func zoom_in() -> void:
	_current_zoom = mini(_current_zoom + 1, int(ZOOM_MAX - _base_scale))
	apply_zoom()

func zoom_out() -> void:
	print("in zoom_out()")
	_current_zoom = maxi(_current_zoom - 1, 0)
	apply_zoom()

func apply_zoom() -> void:
	var new_zoom: float = _base_scale + _current_zoom * ZOOM_STEP
	print("apply_zoom - base_scale: ", _base_scale, " current_zoom: ", _current_zoom, " new_zoom: ", new_zoom)
	zoom = Vector2(new_zoom, new_zoom)
	var x: float = get_x_pos(new_zoom)
	var y: float = get_y_pos()
	print("apply_zoom - position: ", Vector2(x, y))
	position = Vector2(x, y)

func get_x_pos(new_zoom: float) -> float:
	var hud_offset: float = (MapConfig.hud_margin_right / 2.0) / new_zoom
	if _current_zoom == 0:
		return MapConfig.get_map_pixel_width() / 2.0 + hud_offset
	else:
		return _player_pos.x - hud_offset

func get_y_pos() -> float:
	if _current_zoom == 0:
		return MapConfig.get_map_pixel_height() / 2.0
	else:
		return _player_pos.y

func player_pos_updated(player_pos: Vector2) -> void:
	_player_pos = player_pos
	if _current_zoom > 0:
		apply_zoom()
