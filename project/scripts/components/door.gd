class_name Door
extends Entity

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
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
	_sprite.play("closed")
	blocks_vision = true
	allows_player_vision = false

func set_peeked() -> void:
	_sprite.play("peeked")
	blocks_vision = true
	allows_player_vision = true

func set_open() -> void:
	_sprite.play("open")
	blocks_vision = false
	allows_player_vision = true
