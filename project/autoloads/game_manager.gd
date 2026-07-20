extends Node

func _ready() -> void:
	GameEvents.level_ready.connect(_on_level_ready)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart_run()

func _on_level_ready() -> void:
	var loadout: RunLoadout = RunState.loadout
	var roller: PoolRoller = PoolRoller.new()
	loadout.positive_trait_ids = roller.roll(
		GameData.get_ids_by_type("positive"), Constants.STARTING_POSITIVE_TRAIT_COUNT
	)
	loadout.negative_trait_ids = roller.roll(
		GameData.get_ids_by_type("negative"), Constants.STARTING_NEGATIVE_TRAIT_COUNT
	)
	GameData.apply_traits(loadout.all_trait_ids(), GridManager.get_player())
	GameEvents.loadout_rolled.emit(loadout)

func _restart_run() -> void:
	WorldState.reset()
	RunState.reset()
	VisionManager.clear_guard_cones()
	get_tree().reload_current_scene()
