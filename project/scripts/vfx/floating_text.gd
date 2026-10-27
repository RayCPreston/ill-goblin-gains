class_name FloatingText
extends Node2D

const FONT: FontFile = preload("res://assets/fonts/pixel_operator/PixelOperator8.ttf")
const HOLD_FRACTION: float = 1.0 / 3.0
const MAX_TILT_DEGREES: float = 7.0
const DISTANCE_EXPONENT: float = 0.25  # 1.0 center-biased, 0.5 uniform across the disc, lower hugs the rim
const HEMISPHERE_SPREAD: float = PI / 2.0  # wobble around the antipode; PI/2 lands anywhere in the hemisphere opposite the last word

## Shared by every instance so each word can lean away from the one before it.
static var _last_angle: float = 0.0

var text: String = ""
var anchor: Vector2 = Vector2.ZERO
var font_size: int = 8
var color: Color = Color(0.0, 1.0, 0.0, 0.55)
var spread_radius: float = 6.0
var rise_pixels: float = 10.0
var duration: float = 0.9

var _offset: Vector2 = Vector2.ZERO
var _rise: float = 0.0
var _label: Label

func _ready() -> void:
	z_index = 25

	var angle: float = _last_angle + PI + randf_range(-HEMISPHERE_SPREAD, HEMISPHERE_SPREAD)
	_last_angle = fposmod(angle, TAU)
	var dist: float = pow(randf(), DISTANCE_EXPONENT) * spread_radius
	_offset = Vector2(cos(angle), sin(angle)) * dist
	rotation = deg_to_rad(randf_range(-MAX_TILT_DEGREES, MAX_TILT_DEGREES))

	_label = Label.new()
	_label.text = text
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", color)
	var measured: Vector2 = FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	_label.position = Vector2(-measured.x / 2.0, -measured.y / 2.0)
	add_child(_label)

	_update_position()

	var tween: Tween = create_tween().set_parallel()
	tween.tween_method(_set_rise, 0.0, rise_pixels, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_alpha, 1.0, 0.0, duration * (1.0 - HOLD_FRACTION))\
		.set_delay(duration * HOLD_FRACTION)
	tween.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	_update_position()

func _update_position() -> void:
	position = Vector2(round(anchor.x + _offset.x), round(anchor.y + _offset.y - _rise))

func _set_rise(value: float) -> void:
	_rise = value

func _set_alpha(value: float) -> void:
	_label.modulate.a = value
