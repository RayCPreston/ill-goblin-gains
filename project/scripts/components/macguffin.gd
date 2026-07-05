class_name MacGuffin
extends Entity

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	is_furniture = true
	can_overlap = true
	super()
	_sprite.play("closed")

func on_proximity_changed(proximity: Proximity, entity: Entity) -> void:
	if proximity == Proximity.OVERLAPPED and entity is Player and not RunState.has_macguffin:
		RunState.has_macguffin = true
		_sprite.play("open")
		Log.info("MacGuffin acquired.")
