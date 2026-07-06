class_name ProximityAlert extends RefCounted

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

func compute(origin: Vector2i, radius: int) -> Array[Vector2i]:
	var visited: Dictionary = { origin: true }
	var result: Array[Vector2i] = []
	var frontier: Array[Vector2i] = [origin]
	var steps: int = 0
	while steps < radius and not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for cell: Vector2i in frontier:
			for direction: Vector2i in DIRECTIONS:
				var neighbor: Vector2i = cell + direction
				if visited.has(neighbor) or _is_blocked(neighbor):
					continue
				if direction.x != 0 and direction.y != 0 and _cuts_corner(cell, direction):
					continue
				visited[neighbor] = true
				result.append(neighbor)
				next_frontier.append(neighbor)
		frontier = next_frontier
		steps += 1
	return result

func _cuts_corner(cell: Vector2i, direction: Vector2i) -> bool:
	var horizontal: Vector2i = cell + Vector2i(direction.x, 0)
	var vertical: Vector2i = cell + Vector2i(0, direction.y)
	return _is_blocked(horizontal) or _is_blocked(vertical)

func _is_blocked(cell: Vector2i) -> bool:
	if TileManager.is_opaque(cell):
		return true
	var furniture: Entity = GridManager.get_furniture_at_cell(cell)
	return furniture != null and furniture.blocks_vision
