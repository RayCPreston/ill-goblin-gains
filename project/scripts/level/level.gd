class_name Level
extends Node2D

func _ready() -> void:
	TileManager.initialize([$"floor-layer", $"wall-layer"])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		WorldState.reset()
		RunState.reset()
		VisionManager.clear_guard_cones()
		get_tree().reload_current_scene()
