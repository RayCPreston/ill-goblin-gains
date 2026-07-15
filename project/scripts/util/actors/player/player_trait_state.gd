class_name PlayerTraitState extends RefCounted

var applied_ids: Array[String] = []
var _inner_range_modifier: int = 0
var _tracking_memory_modifier: int = 0
var _search_hops_modifier: int = 0
var _chest_opens_on_adjacent: bool = false
var _emits_noise_while_waiting: bool = false
var _capture_charges: int = 0

func get_applied_ids() -> Array[String]:
	return applied_ids

func inner_range_modifier() -> int:
	return _inner_range_modifier

func set_inner_range_modifier(value: int) -> void:
	_inner_range_modifier = value

func tracking_memory_modifier() -> int:
	return _tracking_memory_modifier

func set_tracking_memory_modifier(value: int) -> void:
	_tracking_memory_modifier = value

func search_hops_modifier() -> int:
	return _search_hops_modifier

func set_search_hops_modifier(value: int) -> void:
	_search_hops_modifier = value

func chest_opens_on_adjacent() -> bool:
	return _chest_opens_on_adjacent

func set_chest_opens_on_adjacent(value: bool) -> void:
	_chest_opens_on_adjacent = value

func emits_noise_while_waiting() -> bool:
	return _emits_noise_while_waiting

func set_emits_noise_while_waiting(value: bool) -> void:
	_emits_noise_while_waiting = value

func add_capture_charges(amount: int) -> void:
	_capture_charges += amount

func try_consume_capture_charge() -> bool:
	if _capture_charges <= 0:
		return false
	_capture_charges -= 1
	return true
