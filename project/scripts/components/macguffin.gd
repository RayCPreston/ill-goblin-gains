class_name MacGuffin
extends Entity

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	is_furniture = true
	is_interactable = true
	super()
	_sprite.play("closed")

func interact(source: Entity) -> void:
	if source is Player and not RunState.has_macguffin:
		RunState.has_macguffin = true
		_sprite.play("open")
		Log.info("MacGuffin acquired.")
