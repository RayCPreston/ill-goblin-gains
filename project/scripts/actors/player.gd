class_name Player
extends Entity

signal vision_updated(cells: Dictionary)

var fov: PlayerFov = PlayerFov.new()
var traits: PlayerTraitState = PlayerTraitState.new()
var treasure_hound: TreasureHoundIndicator = TreasureHoundIndicator.new()
const NOISE_SPREAD_FACTOR: float = 1.0
const NOISE_TEXT: String = "*sneak*"
const NOISE_TEXT_CHANCE: float = 0.3
const ALERT_BURST_FONT_SIZE: int = 16  # PixelOperator8 stays crisp at multiples of 8
const ALERT_BURST_COLOR: Color = Color(0.9, 0.15, 0.1, 0.9)
const ALERT_BURST_SPREAD: float = 4.0
const ALERT_BURST_RISE_PIXELS: float = 20.0
const ALERT_BURST_DURATION: float = 1.4
const ALERT_BURST_SHAKE_STRENGTH: int = 2
const ALERT_BURST_SHAKE_JOLTS: int = 8

var noise_radius: int = 2
var smell_radius: int = 0
var throw_range: int = 0
var waited_last_turn: bool = false

func _ready() -> void:
	is_interactable = true
	super()
	GridManager.register_player(self)
	VisionManager.initialize_player(self)
	TurnManager.register_player(self)
	var indicator_sprites: Array[Sprite2D] = [
		$TreasureHoundIndicators/N,
		$TreasureHoundIndicators/NE,
		$TreasureHoundIndicators/E,
		$TreasureHoundIndicators/SE,
		$TreasureHoundIndicators/S,
		$TreasureHoundIndicators/SW,
		$TreasureHoundIndicators/W,
		$TreasureHoundIndicators/NW,
	]
	treasure_hound.setup(indicator_sprites)
	GameEvents.loadout_rolled.connect(_on_loadout_rolled)
	call_deferred("_compute_fov")
	call_deferred("_emit_position")

func _on_loadout_rolled(_loadout: RunLoadout) -> void:
	_update_treasure_hound_indicator()

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
	if is_sleeping:
		sleep_through_turn()
	elif action == PlayerInput.Action.WAIT:
		_begin_turn(true)
		wait()
	elif action == PlayerInput.Action.MOVE:
		_begin_turn(false)
		var direction: Vector2i = PlayerInput.get_move_direction(event)
		try_move_to(cell + direction)
	get_viewport().set_input_as_handled()

func _begin_turn(waiting: bool) -> void:
	waited_last_turn = waiting
	_check_guard_sighting()

func _check_guard_sighting() -> void:
	for entity: Entity in TurnManager.get_world_entities():
		if entity is Guard:
			entity.check_immediate_sighting(cell)

func try_move_to(to_cell: Vector2i) -> void:
	if not TileManager.is_in_bounds(to_cell):
		if RunState.has_macguffin:
			RunState.win("Escaped the mansion with the MacGuffin.")
		end_turn()
		return
	super(to_cell)
	_update_treasure_hound_indicator()

func interact(source: Entity) -> void:
	if source is Guard:
		if traits.try_consume_capture_charge():
			return
		RunState.lose("Captured by a guard.")

func move_to(to_cell: Vector2i) -> void:
	super(to_cell)
	GameEvents.player_pos_updated.emit(position)
	_compute_fov()
	_emit_noise(traits.check_on_move_chance_effects())
	_emit_smell()

func wait() -> void:
	_compute_fov()
	_emit_smell()
	if traits.emits_noise_while_waiting():
		_emit_noise()
	super()

func sleep_through_turn() -> void:
	_begin_turn(true)
	super()

func end_turn() -> void:
	if not RunState.is_run_over:
		var outcome: TurnEndChanceOutcome = traits.check_on_turn_end_chance_effects()
		_emit_alert_burst(outcome.alert_burst_radius, outcome.alert_burst_text)
		fall_asleep(outcome.sleep_turns, outcome.sleep_text)
	super()

func _compute_fov() -> void:
	vision_updated.emit(fov.compute(cell))

func _emit_noise(radius_multiplier: int = 1) -> void:
	var radius: int = noise_radius * radius_multiplier
	if radius > 0 and randf() < NOISE_TEXT_CHANCE:
		var request: FloatingTextRequest = FloatingTextRequest.create(NOISE_TEXT, cell)
		request.spread_radius = float(radius * Constants.TILE_SIZE) * NOISE_SPREAD_FACTOR
		GameEvents.text_emitted.emit(request)
	_alert_guards_within(radius)

func _emit_smell() -> void:
	_alert_guards_within(smell_radius)

## A one-off guard-alerting burst (e.g. Allergies' sneeze). A `radius` of 0
## means nothing fired this turn; an empty `text` shows no words.
func _emit_alert_burst(radius: int, text: String) -> void:
	if radius <= 0:
		return
	if not text.is_empty():
		var request: FloatingTextRequest = FloatingTextRequest.create(text, cell)
		request.font_size = ALERT_BURST_FONT_SIZE
		request.color = ALERT_BURST_COLOR
		request.spread_radius = ALERT_BURST_SPREAD
		request.rise_pixels = ALERT_BURST_RISE_PIXELS
		request.duration = ALERT_BURST_DURATION
		GameEvents.text_emitted.emit(request)
	shake(ALERT_BURST_SHAKE_STRENGTH, ALERT_BURST_SHAKE_JOLTS)
	_alert_guards_within(radius)

func _alert_guards_within(radius: int) -> void:
	var alerted_cells: Array[Vector2i] = ProximityAlert.new().compute(cell, radius)
	for alerted_cell: Vector2i in alerted_cells:
		var actor: Entity = GridManager.get_actor_at_cell(alerted_cell)
		if actor is Guard:
			actor.react_to_proximity(cell)

func _emit_position() -> void:
	GameEvents.player_pos_updated.emit(position)

func _update_treasure_hound_indicator() -> void:
	var active: bool = traits.reveals_macguffin_direction() and not RunState.has_macguffin
	treasure_hound.update(cell, RunState.macguffin_cell, active)
