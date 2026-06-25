extends Node

var _actors: Dictionary = {}
var _furniture: Dictionary = {}
var _player: Player = null

func register_player(player: Player) -> void:
	_player = player

func get_player() -> Player:
	return _player

func register_actor(entity: Entity, cell: Vector2i) -> void:
	_actors[cell] = entity

func register_furniture(entity: Entity, cell: Vector2i) -> void:
	_furniture[cell] = entity

func unregister_actor(cell: Vector2i) -> void:
	_actors.erase(cell)

func unregister_furniture(cell: Vector2i) -> void:
	_furniture.erase(cell)

func move_entity(entity: Entity, from_cell: Vector2i, to_cell: Vector2i) -> void:
	unregister_actor(from_cell)
	register_actor(entity, to_cell)
	notify_entity_moved(entity, from_cell)
	notify_entity_moved(entity, to_cell)

func notify_entity_moved(entity: Entity, cell: Vector2i) -> void:
	for x in range(-1, 2):
		for y in range(-1, 2):
			var neighbor_cell: Vector2i = cell + Vector2i(x, y)
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
	notify_entity_moved(entity_a, cell_a) 
	notify_entity_moved(entity_a, cell_b)
	notify_entity_moved(entity_b, cell_b)
	notify_entity_moved(entity_b, cell_a)

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
