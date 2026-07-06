extends Node2D

const SoundPulseScript: GDScript = preload("res://scripts/vfx/sound_pulse.gd")

func _ready() -> void:
	GameEvents.sound_emitted.connect(_on_sound_emitted)

func _on_sound_emitted(world_position: Vector2, pixel_radius: float) -> void:
	var pulse: Node2D = SoundPulseScript.new()
	pulse.target_radius = pixel_radius
	pulse.position = world_position
	add_child(pulse)
