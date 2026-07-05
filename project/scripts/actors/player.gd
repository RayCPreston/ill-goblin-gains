class_name Player
extends Entity

signal vision_updated(cells: Dictionary)

var fov: PlayerFov = PlayerFov.new()

func _ready() -> void:
	is_interactable = true
	super()
	GridManager.register_player(self)
	VisionManager.initialize_player(self)
	TurnManager.register_player(self)
	call_deferred("_compute_fov")
	call_deferred("_emit_position")

func _unhandled_input(event: InputEvent) -> void:
	if RunState.is_run_over:
		return
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

func try_move_to(to_cell: Vector2i) -> void:
	if not TileManager.is_in_bounds(to_cell):
		if RunState.has_macguffin:
			RunState.win("Escaped the mansion with the MacGuffin.")
		end_turn()
		return
	super(to_cell)

func interact(source: Entity) -> void:
	if source is Guard:
		RunState.lose("Captured by a guard.")

func move_to(to_cell: Vector2i) -> void:
	super(to_cell)
	GameEvents.player_pos_updated.emit(position)
	_compute_fov()

func wait() -> void:
	_compute_fov()
	super()

func _compute_fov() -> void:
	vision_updated.emit(fov.compute(cell))

func _emit_position() -> void:
	GameEvents.player_pos_updated.emit(position)
