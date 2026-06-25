extends Node

enum AlertLevel { NORMAL, ALERT }

const TRACKING_MEMORY: int = 8

var alert_level: AlertLevel = AlertLevel.NORMAL
var lkp: Vector2i = Vector2i.ZERO
var has_lkp: bool = false
var _last_seen_direction: Vector2i = Vector2i.ZERO
var _tracking_turns: int = 0
var _has_eyes_on: bool = false

func set_lkp(cell: Vector2i, direction: Vector2i = Vector2i.ZERO) -> void:
	lkp = cell
	has_lkp = true
	alert_level = AlertLevel.ALERT
	_has_eyes_on = true
	if direction != Vector2i.ZERO:
		_last_seen_direction = direction
	_tracking_turns = TRACKING_MEMORY

func clear_lkp() -> void:
	has_lkp = false

func tick_tracking() -> void:
	if _has_eyes_on:
		_has_eyes_on = false
		return
	if not has_lkp or _tracking_turns <= 0 or _last_seen_direction == Vector2i.ZERO:
		return
	_tracking_turns -= 1
	var projected: Vector2i = lkp + _last_seen_direction
	if TileManager.is_walkable(projected):
		lkp = projected
	else:
		_tracking_turns = 0

func reset() -> void:
	alert_level = AlertLevel.NORMAL
	lkp = Vector2i.ZERO
	has_lkp = false
	_last_seen_direction = Vector2i.ZERO
	_tracking_turns = 0
	_has_eyes_on = false
