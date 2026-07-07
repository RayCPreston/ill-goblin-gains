extends Node2D

const SoundPulseScript: GDScript = preload("res://scripts/vfx/sound_pulse.gd")
const SmellAuraScript: GDScript = preload("res://scripts/vfx/smell_aura.gd")

var _smell_aura: Node2D = null

func _ready() -> void:
	GameEvents.sound_emitted.connect(_on_sound_emitted)

func _process(_delta: float) -> void:
	var player: Player = GridManager.get_player()
	if player == null:
		return
	if _smell_aura == null:
		_smell_aura = SmellAuraScript.new()
		add_child(_smell_aura)
		_smell_aura.set_radius(float(player.smell_radius * Constants.TILE_SIZE))
	var tile_center_offset: Vector2 = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) / 2.0
	_smell_aura.position = player.position + tile_center_offset

func _on_sound_emitted(world_position: Vector2, pixel_radius: float) -> void:
	var pulse: Node2D = SoundPulseScript.new()
	pulse.target_radius = pixel_radius
	pulse.position = world_position
	add_child(pulse)
