class_name GuardStateMachine extends RefCounted

enum State { PATROL, CURIOUS, ALERT }

const COLOR_GREEN: Color = Color.LIME
const COLOR_YELLOW: Color = Color.YELLOW
const COLOR_RED: Color = Color.RED
const ALERT_SEARCH_RANGE: int = 8
const TRACKING_MEMORY: int = 5

var poi: Vector2i
var patrol_target: Vector2i
var _sm: StateMachine = StateMachine.new()
var _guard: Guard
var _last_seen_direction: Vector2i = Vector2i.ZERO
var _last_player_cell: Vector2i = Vector2i.ZERO
var _player_visible_last_turn: bool = false
var _tracking_turns: int = 0

func _init(guard: Guard) -> void:
	_guard = guard
	_sm.register(State.PATROL, _do_patrol)
	_sm.register(State.CURIOUS, _do_curious, _enter_repath)
	_sm.register(State.ALERT, _do_alert, _enter_repath)
	_sm.start(State.PATROL)

func process_turn() -> void:
	_check_world_escalation()
	_guard.compute_vision()
	_check_detection()
	_sm.execute()

func get_current_state() -> int:
	return _sm.current_state

func get_cone_color() -> Color:
	match _sm.current_state:
		State.PATROL:
			return COLOR_GREEN
		State.CURIOUS:
			return COLOR_YELLOW
		State.ALERT:
			return COLOR_RED
	return COLOR_GREEN

func is_segmented() -> bool:
	return _sm.current_state != State.ALERT

# -- State escalation --

func _check_world_escalation() -> void:
	if _sm.current_state != State.ALERT and WorldState.alert_level == WorldState.AlertLevel.ALERT:
		_sm.transition(State.ALERT)

func _check_detection() -> void:
	var player_cell: Vector2i = GridManager.get_player().cell
	var in_inner: bool = player_cell in _guard.get_inner_zone()
	var in_outer: bool = player_cell in _guard.get_outer_zone()
	var can_see: bool = in_inner or in_outer
	if can_see:
		if _player_visible_last_turn and player_cell != _last_player_cell:
			_last_seen_direction = player_cell - _last_player_cell
		_last_player_cell = player_cell
		_player_visible_last_turn = true
		_tracking_turns = TRACKING_MEMORY
		if in_inner:
			_on_inner_detection(player_cell)
		else:
			_on_outer_detection(player_cell)
	else:
		_player_visible_last_turn = false
		_tick_tracking()

func _tick_tracking() -> void:
	if _tracking_turns <= 0 or _last_seen_direction == Vector2i.ZERO:
		return
	_tracking_turns -= 1
	if _sm.current_state == State.CURIOUS:
		var projected: Vector2i = poi + _last_seen_direction
		if TileManager.is_walkable(projected):
			poi = projected
			_guard.clear_path()
		else:
			_tracking_turns = 0

func _on_inner_detection(player_cell: Vector2i) -> void:
	WorldState.set_lkp(player_cell, _last_seen_direction)
	_sm.transition(State.ALERT)

func _on_outer_detection(player_cell: Vector2i) -> void:
	match _sm.current_state:
		State.PATROL:
			poi = player_cell
			patrol_target = _guard.cell
			_sm.transition(State.CURIOUS)
		State.CURIOUS:
			poi = player_cell
			_guard.clear_path()
		State.ALERT:
			WorldState.set_lkp(player_cell, _last_seen_direction)
			_guard.clear_path()

# -- Enter callbacks --

func _enter_repath() -> void:
	_guard.clear_path()

# -- State behaviors --

func _do_patrol() -> void:
	if _guard.is_path_empty():
		_guard.choose_destination()
	_guard.step_along_path()

func _do_curious() -> void:
	if _guard.is_path_empty():
		if _guard.cell == poi:
			_sm.transition(State.PATROL)
			_guard.navigate_to(patrol_target)
			_guard.step_along_path()
			return
		_guard.navigate_to(poi)
		if _guard.is_path_empty():
			_sm.transition(State.PATROL)
	_guard.step_along_path()

func _do_alert() -> void:
	if WorldState.has_lkp:
		if _guard.cell == WorldState.lkp:
			WorldState.clear_lkp()
			_guard.clear_path()
		elif _guard.is_path_empty() or _guard.destination != WorldState.lkp:
			_guard.navigate_to(WorldState.lkp)
	else:
		if _guard.is_path_empty():
			_guard.choose_destination(ALERT_SEARCH_RANGE)
	_guard.step_along_path()
