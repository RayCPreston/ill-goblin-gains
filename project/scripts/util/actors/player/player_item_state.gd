class_name PlayerItemState extends RefCounted

var _held_ids: Array[String] = []
var _charges: Dictionary = {}

func add(id: String, charges: int) -> void:
	if not _charges.has(id):
		_held_ids.append(id)
	_charges[id] = int(_charges.get(id, 0)) + charges

func get_held_ids() -> Array[String]:
	return _held_ids.duplicate()

func charges_of(id: String) -> int:
	return _charges.get(id, 0)

func is_held(id: String) -> bool:
	return _charges.has(id)

## An item drops off the inventory once its last charge is spent.
func spend_charge(id: String) -> void:
	if not is_held(id):
		return
	_charges[id] -= 1
	if _charges[id] <= 0:
		_charges.erase(id)
		_held_ids.erase(id)
