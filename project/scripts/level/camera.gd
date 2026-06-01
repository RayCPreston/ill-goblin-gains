extends Camera2D

const ZOOM_STEP: float = 1.0
const ZOOM_MIN: float = 1.0
const ZOOM_MAX: float = 4.0

@export var smooth_speed: float = 3.0
@export var tile_deadzone_x: int = 15
@export var tile_deadzone_y: int = 6

var _base_scale: float = 1.0
var _current_zoom: int = 0
var _player_pos: Vector2 = Vector2.ZERO
var _target_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	GameEvents.zoom_in_requested.connect(zoom_in)
	GameEvents.zoom_out_requested.connect(zoom_out)
	GameEvents.player_pos_updated.connect(player_pos_updated)
	call_deferred("fit_camera")

func _process(delta: float) -> void:
	if _current_zoom > 0:
		position = position.lerp(_target_pos, smooth_speed * delta)
		var half_w: float = (get_viewport_rect().size.x / 2.0) / zoom.x
		var half_h: float = (get_viewport_rect().size.y / 2.0) / zoom.y
		position.x = clampf(position.x, half_w, MapConfig.get_map_pixel_width() - half_w)
		position.y = clampf(position.y, half_h, MapConfig.get_map_pixel_height() - half_h)

func fit_camera() -> void:
	#_base_scale = ResolutionManager.get_snapped_scale() #TODO: Support configurable resolutions
	_base_scale = 1.0
	_current_zoom = 0
	apply_zoom()
	_target_pos = position

func zoom_in() -> void:
	_current_zoom = mini(_current_zoom + 1, int(ZOOM_MAX - _base_scale))
	apply_zoom()

func zoom_out() -> void:
	print("in zoom_out()")
	_current_zoom = maxi(_current_zoom - 1, 0)
	apply_zoom()

func apply_zoom() -> void:
	var new_zoom: float = _base_scale + _current_zoom * ZOOM_STEP
	zoom = Vector2(new_zoom, new_zoom)
	var x: float = get_x_pos(new_zoom)
	var y: float = get_y_pos()
	position = Vector2(x, y)
	_target_pos = position

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
		_apply_deadzone()

func _apply_deadzone() -> void:
	var deadzone_x: float = tile_deadzone_x * Constants.TILE_SIZE / zoom.x
	var deadzone_y: float = tile_deadzone_y * Constants.TILE_SIZE / zoom.y
	var screen_pos: Vector2 = _player_pos - position
	print("player: ", _player_pos, " cam: ", position, " screen_pos: ", screen_pos, " dz_y: ", deadzone_y)
	if abs(screen_pos.x) > deadzone_x + 0.5:
		_target_pos.x = _player_pos.x - (sign(screen_pos.x) * (deadzone_x - Constants.TILE_SIZE * 4))
	if abs(screen_pos.y) > deadzone_y + 0.5:
		print("Y triggered - moving camera")
		_target_pos.y = _player_pos.y - (sign(screen_pos.y) * (deadzone_y - Constants.TILE_SIZE * 4))
