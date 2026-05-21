extends Node

var _cells: Dictionary = {}

func register(entity: Entity, cell: Vector2i) -> void:
	_cells[cell] = entity

func unregister(cell: Vector2i) -> void:
	_cells.erase(cell)
	
func move_entity(entity: Entity, from_cell: Vector2i, to_cell: Vector2i) -> void:
	unregister(from_cell)
	register(entity, to_cell)

func swap_entities(entity_a: Entity, entity_b: Entity) -> void:
	var cell_a := entity_a.cell
	var cell_b := entity_b.cell
	_cells[cell_a] = entity_b
	_cells[cell_b] = entity_a

func get_entity_at_cell(cell: Vector2i) -> Entity:
	return _cells.get(cell, null)

func is_occupied(cell: Vector2i) -> bool:
	return _cells.has(cell)

func is_cell_available(cell: Vector2i) -> bool:
	return TileManager.is_walkable(cell) and not is_occupied(cell)
