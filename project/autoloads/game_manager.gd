extends Node

func _ready() -> void:
	GameEvents.level_ready.connect(_on_level_ready)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart_run()

func _on_level_ready() -> void:
	var starting_traits: Array[String] = ["padfoot", "keen_eyes", "two_left_feet", "nearsighted", "pitcher", "butterfingers", "camouflage", "big_target", "cold_trail", "vanishing_act", "persistent_trail", "cat_burglar", "fidgety", "slippery", "disguise", "statue"]
	GameData.apply_traits(starting_traits, GridManager.get_player())

func _restart_run() -> void:
	WorldState.reset()
	RunState.reset()
	VisionManager.clear_guard_cones()
	get_tree().reload_current_scene()
