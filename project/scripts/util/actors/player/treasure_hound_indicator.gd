class_name TreasureHoundIndicator extends RefCounted

## Clockwise from N, matching the frame order baked into
## treasure_hound_indicator_grey.png and the child order in
## Player's TreasureHoundIndicators node.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
]

var _sprites: Array[Sprite2D] = []

func setup(sprites: Array[Sprite2D]) -> void:
	_sprites = sprites

func update(player_cell: Vector2i, macguffin_cell: Vector2i, active: bool) -> void:
	var index: int = _direction_index(macguffin_cell - player_cell) if active else -1
	for i in range(_sprites.size()):
		_sprites[i].visible = i == index

func _direction_index(offset: Vector2i) -> int:
	if offset == Vector2i.ZERO:
		return -1
	var direction: Vector2 = Vector2(offset).normalized()
	var best_index: int = 0
	var best_dot: float = -INF
	for i in range(DIRECTIONS.size()):
		var dot: float = direction.dot(Vector2(DIRECTIONS[i]).normalized())
		if dot > best_dot:
			best_dot = dot
			best_index = i
	return best_index
