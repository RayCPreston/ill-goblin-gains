class_name SoundPulse
extends Node2D

const DURATION: float = 0.4
const COLOR: Color = Color(1.0, 1.0, 1.0, 0.8)
const LINE_WIDTH: float = 2.0

var target_radius: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	z_index = 15

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t: float = _elapsed / DURATION
	var radius: float = target_radius * t
	var alpha: float = COLOR.a * (1.0 - t)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(COLOR.r, COLOR.g, COLOR.b, alpha), LINE_WIDTH, true)
