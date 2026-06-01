extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		GameEvents.zoom_in_requested.emit()
	elif event.is_action_pressed("zoom_out"):
		GameEvents.zoom_out_requested.emit()
