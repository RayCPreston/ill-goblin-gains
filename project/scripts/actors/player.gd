class_name Player
extends Entity

signal vision_updated(cells: Dictionary)

var fov: PlayerFov = PlayerFov.new()
var traits: PlayerTraitState = PlayerTraitState.new()
var noise_radius: int = 2
var smell_radius: int = 2
var throw_range: int = 0

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
	if UiState.modal_open:
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
	_emit_noise()
	_emit_smell()

func wait() -> void:
	_compute_fov()
	_emit_smell()
	super()

func _compute_fov() -> void:
	vision_updated.emit(fov.compute(cell))

func _emit_noise() -> void:
	GameEvents.sound_emitted.emit(cell_center_to_world(cell), float(noise_radius * Constants.TILE_SIZE))
	var alerted_cells: Array[Vector2i] = ProximityAlert.new().compute(cell, noise_radius)
	for alerted_cell: Vector2i in alerted_cells:
		var actor: Entity = GridManager.get_actor_at_cell(alerted_cell)
		if actor is Guard:
			actor.react_to_proximity(cell)

func _emit_smell() -> void:
	var smelled_cells: Array[Vector2i] = ProximityAlert.new().compute(cell, smell_radius)
	for smelled_cell: Vector2i in smelled_cells:
		var actor: Entity = GridManager.get_actor_at_cell(smelled_cell)
		if actor is Guard:
			actor.react_to_proximity(cell)

func _emit_position() -> void:
	GameEvents.player_pos_updated.emit(position)
