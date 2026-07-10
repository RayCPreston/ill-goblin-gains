class_name GuardFov

const HALF_ARC_DEGREES: float = 27.5
const INNER_RANGE: int = 3
const OUTER_RANGE: int = 6

func compute(origin: Vector2i, facing: Guard.Facing, half_arc_degrees: float = HALF_ARC_DEGREES, inner_range: int = INNER_RANGE, outer_range: int = OUTER_RANGE) -> Array[Array]:
	var inner: Array[Vector2i] = []
	var outer: Array[Vector2i] = []
	var facing_angle: float = float(facing)
	var full_circle: bool = half_arc_degrees >= 180.0
	for dx in range(-outer_range, outer_range + 1):
		for dy in range(-outer_range, outer_range + 1):
			var target: Vector2i = origin + Vector2i(dx, dy)
			if target == origin:
				continue
			var dist: float = maxf(absf(float(dx)), absf(float(dy)))
			if dist > outer_range:
				continue
			if not full_circle and not _in_arc(dx, dy, facing_angle):
				continue
			if not _has_los(origin, target):
				continue
			if dist <= inner_range:
				inner.append(target)
			else:
				outer.append(target)
	return [inner, outer]

func _in_arc(dx: int, dy: int, facing_angle: float) -> bool:
	var angle: float = rad_to_deg(atan2(float(dy), float(dx)))
	if angle < 0.0:
		angle += 360
	var delta: float = absf(angle - facing_angle)
	if delta > 180.0:
		delta = 360.0 - delta
	return delta <= HALF_ARC_DEGREES

func _has_los(origin: Vector2i, target: Vector2i) -> bool:
	var dx: int =  target.x - origin.x
	var dy: int = target.y - origin.y
	var steps: int = maxi(absi(dx), absi(dy))
	for i in range(1, steps):
		var sample: Vector2i = Vector2i(
			origin.x + int(roundf(float(dx) * float(i) / float(steps))),
			origin.y + int(roundf(float(dy) * float(i) / float(steps)))
		)
		if TileManager.is_opaque(sample):
			return false
		var furniture: Entity = GridManager.get_furniture_at_cell(sample)
		if furniture and furniture.blocks_vision:
			return false
	return true
