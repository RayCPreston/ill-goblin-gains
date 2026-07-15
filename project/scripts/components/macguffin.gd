class_name MacGuffin
extends Entity

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	is_furniture = true
	is_interactable = true
	super()
	_sprite.play("closed")

func interact(source: Entity) -> void:
	_acquire(source)

func on_proximity_changed(proximity: Proximity, entity: Entity) -> void:
	if proximity == Proximity.ADJACENT and entity is Player and GridManager.get_player().traits.chest_opens_on_adjacent():
		_acquire(entity)

func _acquire(source: Entity) -> void:
	if source is Player and not RunState.has_macguffin:
		RunState.has_macguffin = true
		_sprite.play("open")
		Log.info("MacGuffin acquired.")
