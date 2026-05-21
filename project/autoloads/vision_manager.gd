extends Node

signal cell_state_changed

const COLOR_VISIBLE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_REMEMBERED: Color = Color(0.4, 0.4, 0.4, 1.0)
const COLOR_UNSEEN: Color = Color(0.0, 0.0, 0.0, 1.0)

var _vision: Dictionary = {}

func initialize(player: Player) -> void:
	player.vision_updated.connect(_on_vision_updated)

func get_state(cell: Vector2i) -> PlayerFov.VisionState:
	return _vision.get(cell, PlayerFov.VisionState.UNSEEN)

func get_cell_color(cell: Vector2i) -> Color:
	match get_state(cell):
		PlayerFov.VisionState.VISIBLE: return COLOR_VISIBLE
		PlayerFov.VisionState.REMEMBERED: return COLOR_REMEMBERED
		_: return COLOR_UNSEEN

func _on_vision_updated(cells: Dictionary) -> void:
	_vision = cells
	TileManager.notify_vision_update()
	cell_state_changed.emit()
