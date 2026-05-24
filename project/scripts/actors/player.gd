class_name Player
extends Entity

signal vision_updated(cells: Dictionary)

var fov: PlayerFov = PlayerFov.new()

func _ready() -> void:
	super()
	TurnManager.register_player(self)
	call_deferred("_compute_fov")

func _unhandled_input(event: InputEvent) -> void:
	if not TurnManager.is_player_turn():
		return
	var action: PlayerInput.Action = PlayerInput.get_input_action(event)
	if action == PlayerInput.Action.NONE:
		return
	elif action == PlayerInput.Action.WAIT:
		wait()
	elif action == PlayerInput.Action.MOVE:
		var direction: Vector2i = PlayerInput.get_move_direction(event)
		try_move_to(cell + direction)
	get_viewport().set_input_as_handled()

func move_to(to_cell: Vector2i) -> void:
	super(to_cell)
	_compute_fov()

func wait() -> void:
	_compute_fov()
	super()

func _compute_fov() -> void:
	vision_updated.emit(fov.compute(cell))
