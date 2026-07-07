class_name SmellAura
extends Node2D

const SHADER: Shader = preload("res://resources/shaders/smell_aura.gdshader")
const PADDING_FACTOR: float = 1.3

var _rect: ColorRect
var _material: ShaderMaterial

func _ready() -> void:
	z_index = 14
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)

func set_radius(pixel_radius: float) -> void:
	var half_extent: float = pixel_radius * PADDING_FACTOR
	var size: Vector2 = Vector2(half_extent, half_extent) * 2.0
	_rect.size = size
	_rect.position = -size / 2.0
	_material.set_shader_parameter("rect_size", size)
	_material.set_shader_parameter("radius", pixel_radius)
