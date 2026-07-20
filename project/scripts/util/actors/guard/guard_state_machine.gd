class_name GuardStateMachine extends RefCounted

enum State { PATROL, CURIOUS, ALERT }

const COLOR_GREEN: Color = Color.LIME
const COLOR_YELLOW: Color = Color.YELLOW
const COLOR_RED: Color = Color.RED
const ALERT_SEARCH_RANGE: int = 8
const TRACKING_MEMORY: int = 4
const POI_SEARCH_HOPS: int = 2
const POI_SEARCH_RADIUS: int = 3

var poi: Vector2i
var patrol_target: Vector2i
var _sm: StateMachine = StateMachine.new()
var _guard: Guard
var _last_seen_direction: Vector2i = Vector2i.ZERO
var _last_player_cell: Vector2i = Vector2i.ZERO
var _has_prior_sighting: bool = false
var _tracking_turns: int = 0
var _search_hops_remaining: int = 0

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
	_guard.compute_vision()

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
	if not check_immediate_sighting(player_cell):
		_tick_tracking()

## Tests a specific cell against this guard's current vision zones and reacts
## immediately if it overlaps. Callable ahead of the guard's own turn (see
## Player._check_guard_sighting()) so a player caught in a cone can't dodge
## detection just by moving away before this guard's process_turn() runs.
## Returns true if the cell was seen.
func check_immediate_sighting(player_cell: Vector2i) -> bool:
	var player: Player = GridManager.get_player()
	var in_inner: bool = player_cell in _guard.get_inner_zone()
	var in_outer: bool = player_cell in _guard.get_outer_zone()
	if in_outer and not in_inner and player.traits.is_outer_zone_suppressed(player.waited_last_turn):
		in_outer = false
	if not (in_inner or in_outer):
		return false
	if WorldState.alert_level != WorldState.AlertLevel.ALERT and player.traits.has_disguise_charge():
		player.traits.mark_seen_this_turn()
		return true
	if _has_prior_sighting and player_cell != _last_player_cell:
		_last_seen_direction = _step_direction(player_cell - _last_player_cell)
	_last_player_cell = player_cell
	_has_prior_sighting = true
	_tracking_turns = TRACKING_MEMORY + player.traits.tracking_memory_modifier()
	_search_hops_remaining = POI_SEARCH_HOPS + player.traits.search_hops_modifier()
	if in_inner:
		_on_inner_detection(player_cell)
	else:
		react_to_proximity(player_cell)
	return true

func _step_direction(delta: Vector2i) -> Vector2i:
	return Vector2i(signi(delta.x), signi(delta.y))

func _tick_tracking() -> void:
	if _tracking_turns <= 0 or _last_seen_direction == Vector2i.ZERO:
		return
	_tracking_turns -= 1
	if _sm.current_state != State.CURIOUS:
		return
	var projected: Vector2i = _resolve_projection(poi, _last_seen_direction)
	if projected == poi:
		_tracking_turns = 0
		return
	poi = projected
	_guard.clear_path()

func _resolve_projection(from: Vector2i, direction: Vector2i) -> Vector2i:
	var straight: Vector2i = from + direction
	if TileManager.is_walkable(straight):
		return straight
	if direction.x != 0:
		var horizontal: Vector2i = from + Vector2i(direction.x, 0)
		if TileManager.is_walkable(horizontal):
			return horizontal
	if direction.y != 0:
		var vertical: Vector2i = from + Vector2i(0, direction.y)
		if TileManager.is_walkable(vertical):
			return vertical
	return from

func _on_inner_detection(player_cell: Vector2i) -> void:
	WorldState.set_lkp(player_cell, _last_seen_direction)
	_sm.transition(State.ALERT)

func react_to_proximity(source_cell: Vector2i) -> void:
	match _sm.current_state:
		State.PATROL:
			poi = source_cell
			patrol_target = _guard.cell
			_sm.transition(State.CURIOUS)
		State.CURIOUS:
			poi = source_cell
			_guard.clear_path()
		State.ALERT:
			WorldState.set_lkp(source_cell, _last_seen_direction)
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
			if _search_hops_remaining > 0:
				_search_hops_remaining -= 1
				poi = _pick_search_point(poi)
				_guard.navigate_to(poi)
				if _guard.is_path_empty():
					_search_hops_remaining = 0
			else:
				_sm.transition(State.PATROL)
				_guard.navigate_to(patrol_target)
				_guard.step_along_path()
				return
		else:
			_guard.navigate_to(poi)
			if _guard.is_path_empty():
				_sm.transition(State.PATROL)
				return
	_guard.step_along_path()

func _pick_search_point(origin: Vector2i) -> Vector2i:
	for i in range(20):
		var candidate: Vector2i = origin + Vector2i(
			randi_range(-POI_SEARCH_RADIUS, POI_SEARCH_RADIUS),
			randi_range(-POI_SEARCH_RADIUS, POI_SEARCH_RADIUS)
		)
		if candidate == origin or not TileManager.is_walkable(candidate):
			continue
		return candidate
	return origin

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
