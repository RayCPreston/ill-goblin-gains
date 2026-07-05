class_name Door
extends Entity

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _current_animation: StringName = &"closed"

func _ready() -> void:
	is_furniture = true
	blocks_vision = true
	can_overlap = true
	super()
	_sprite.play("closed")

func on_proximity_changed(proximity: Proximity, entity: Entity) -> void:
	match proximity:
		Proximity.NONE:
			set_closed()
		Proximity.ADJACENT:
			if entity is Player:
				set_peeked()
		Proximity.OVERLAPPED:
			set_open()

func set_closed() -> void:
	blocks_vision = true
	allows_player_vision = false
	_set_animation(&"closed")

func set_peeked() -> void:
	blocks_vision = true
	allows_player_vision = true
	_set_animation(&"peeked")

func set_open() -> void:
	blocks_vision = false
	allows_player_vision = true
	_set_animation(&"open")

func refresh_visibility() -> void:
	super()
	if VisionManager.get_state(cell) == PlayerFov.VisionState.VISIBLE:
		_sprite.play(_current_animation)

func _set_animation(anim: StringName) -> void:
	_current_animation = anim
	if VisionManager.get_state(cell) == PlayerFov.VisionState.VISIBLE:
		_sprite.play(anim)
