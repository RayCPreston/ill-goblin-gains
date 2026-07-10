class_name PlayerTraitState extends RefCounted

var applied_ids: Array[String] = []
var _inner_range_modifier: int = 0

func get_applied_ids() -> Array[String]:
	return applied_ids

func inner_range_modifier() -> int:
	return _inner_range_modifier

func set_inner_range_modifier(value: int) -> void:
	_inner_range_modifier = value
