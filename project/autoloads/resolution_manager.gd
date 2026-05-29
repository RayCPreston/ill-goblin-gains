extends Node

const BASE_WIDTH: int = 1280
const BASE_HEIGHT: int = 720

#func _ready() -> void:
	#get_tree().root.size_changed.connect(_on_window_resized)
	#_on_window_resized()

func _on_window_resized() -> void:
	var window: Window = get_tree().root
	var current_size: Vector2i = window.get_window().size
	print("window.size: ", window.size)
	print("screen_size: ", current_size)
	print("content_scale_factor before: ", window.content_scale_factor)
	var target_scale: float = _get_target_scale(current_size)
	print("target_scale: ", target_scale)
	var final_width: int = int(BASE_WIDTH * target_scale)
	var final_height: int = int(BASE_HEIGHT * target_scale)
	var margin_x: int = int((current_size.x - final_width) / 2.0)
	var margin_y: int = int((current_size.y - final_height) / 2.0)
	_apply(window, margin_x, margin_y, target_scale)
	print("content_scale_factor after: ", window.content_scale_factor)

func _get_target_scale(current_size: Vector2i) -> float:
	var scale_x: float = float(current_size.x) / float(BASE_WIDTH)
	var scale_y: float = float(current_size.y) / float(BASE_HEIGHT)
	var min_scale: float = minf(scale_x, scale_y)
	if min_scale >= 1.0:
		return min_scale
	else:
		return maxf(min_scale, 0.1)

func _apply(window: Window, margin_x: int, margin_y: int, target_scale: float) -> void:
	window.handle_input_locally = true
	window.gui_embed_subwindows = true
	window.content_scale_size = Vector2i(BASE_WIDTH, BASE_HEIGHT)
	window.content_scale_factor = target_scale
	window.position = Vector2i(margin_x, margin_y)
	print("content_scale_mode: ", window.content_scale_mode)
	print("content_scale_aspect: ", window.content_scale_aspect)
