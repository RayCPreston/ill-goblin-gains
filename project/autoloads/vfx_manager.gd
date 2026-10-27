extends Node2D

const SmellAuraScript: GDScript = preload("res://scripts/vfx/smell_aura.gd")
const FloatingTextScript: GDScript = preload("res://scripts/vfx/floating_text.gd")

var _smell_aura: Node2D = null
var _texts_this_frame: int = 0
var _texts_frame_number: int = -1

func _ready() -> void:
	GameEvents.text_emitted.connect(_on_text_emitted)

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

func _on_text_emitted(request: FloatingTextRequest) -> void:
	if request.fov_gated and VisionManager.get_state(request.cell) != PlayerFov.VisionState.VISIBLE:
		return
	var frame: int = Engine.get_process_frames()
	if frame != _texts_frame_number:
		_texts_frame_number = frame
		_texts_this_frame = 0
	var floating_text: FloatingText = FloatingTextScript.new()
	floating_text.text = request.text
	floating_text.anchor = Constants.cell_center_to_world(request.cell) \
		- Vector2(0, _texts_this_frame * (request.font_size + 2))
	floating_text.font_size = request.font_size
	floating_text.color = request.color
	floating_text.spread_radius = request.spread_radius
	floating_text.rise_pixels = request.rise_pixels
	floating_text.duration = request.duration
	add_child(floating_text)
	_texts_this_frame += 1
