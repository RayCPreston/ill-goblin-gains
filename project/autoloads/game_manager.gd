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
		GameData.get_trait_ids_by_type("positive"), Constants.STARTING_POSITIVE_TRAIT_COUNT
	)
	loadout.negative_trait_ids = roller.roll(
		GameData.get_trait_ids_by_type("negative"), Constants.STARTING_NEGATIVE_TRAIT_COUNT
	)
	loadout.item_ids = roller.roll(GameData.get_item_ids(), Constants.STARTING_ITEM_COUNT)
	var player: Player = GridManager.get_player()
	GameData.apply_traits(loadout.all_trait_ids(), player)
	GameData.grant_items(loadout.item_ids, player)
	GameEvents.loadout_rolled.emit(loadout)

func _restart_run() -> void:
	WorldState.reset()
	RunState.reset()
	VisionManager.clear_guard_cones()
	get_tree().reload_current_scene()
