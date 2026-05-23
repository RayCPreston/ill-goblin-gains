extends Node

var _actors: Dictionary = {}
var _furniture: Dictionary = {}

func register(entity: Entity, cell: Vector2i) -> void:
	if entity.is_furniture:
		_furniture[cell] = entity
	else:
		_actors[cell] = entity

func unregister(cell: Vector2i) -> void:
	_actors.erase(cell)
	_furniture.erase(cell)

func move_entity(entity: Entity, from_cell: Vector2i, to_cell: Vector2i) -> void:
	unregister(from_cell)
	register(entity, to_cell)
	notify_entity_moved(entity)

func notify_entity_moved(entity: Entity) -> void:
	for x in range(-2, 3):
		for y in range(-2, 3):
			var neighbor_cell: Vector2i = entity.cell + Vector2i(x, y)
			var proximity: Entity.Proximity = _get_proximity(entity.cell, neighbor_cell)
			var actor: Entity = get_actor_at_cell(neighbor_cell)
			if actor:
				actor.on_proximity_changed(proximity, entity)
			var furniture: Entity = get_furniture_at_cell(neighbor_cell)
			if furniture:
				furniture.on_proximity_changed(proximity, entity)

func _get_proximity(entity_cell: Vector2i, neighbor_cell: Vector2i) -> Entity.Proximity:
	var diff: Vector2i = (entity_cell - neighbor_cell).abs()
	if diff == Vector2i.ZERO:
		return Entity.Proximity.OVERLAPPED
	if diff.x <= 1 and diff.y <= 1 and (diff.x + diff.y) == 1:
		return Entity.Proximity.ADJACENT
	return Entity.Proximity.NONE

func swap_entities(entity_a: Entity, entity_b: Entity) -> void:
	var cell_a := entity_a.cell
	var cell_b := entity_b.cell
	_actors[cell_a] = entity_b
	_actors[cell_b] = entity_a
	notify_entity_moved(entity_a)

func get_actor_at_cell(cell: Vector2i) -> Entity:
	return _actors.get(cell, null)

func get_furniture_at_cell(cell: Vector2i) -> Entity:
	return _furniture.get(cell, null)

func is_cell_available(cell: Vector2i) -> bool:
	var is_walkable: bool = TileManager.is_walkable(cell)
	if not is_walkable:
		return false
	var actor: Entity = get_actor_at_cell(cell)
	if actor and not actor.can_swap:
		return false
	var furniture: Entity = get_furniture_at_cell(cell)
	if furniture and not furniture.can_overlap:
		return false
	return true
