extends Node

## Authored dispatch: every recognized `stat`-kind property name and the
## Player field it resolves to. Add one line here per new `stat` trait —
## see docs/traits.md's Property/Parameter Reference.
const KNOWN_STAT_PROPERTIES: Array[String] = [
	"noise_radius",
	"vision_range",
	"throw_range",
]

## Authored dispatch: every recognized `detection_modifier`-kind parameter name
## and the guard-side comparison it adjusts — see docs/traits.md's
## Property/Parameter Reference.
const KNOWN_DETECTION_MODIFIER_PARAMETERS: Array[String] = [
	"guard_inner_range",
	"guard_tracking_memory",
	"guard_search_hops",
]

const TRAITS_PATH: String = "res://data/traits.json"

var _definitions: Dictionary = {}

func _ready() -> void:
	_load_definitions()

func get_definition(id: String) -> Dictionary:
	return _definitions.get(id, {})

func apply_traits(ids: Array[String], player: Player) -> void:
	for id: String in ids:
		if not _definitions.has(id):
			Log.error("GameData: unknown trait id '%s'" % id)
			continue
		var definition: Dictionary = _definitions[id]
		_apply_effect(definition, player)
		player.traits.applied_ids.append(id)

func _load_definitions() -> void:
	var file: FileAccess = FileAccess.open(TRAITS_PATH, FileAccess.READ)
	if file == null:
		Log.error("GameData: could not open %s" % TRAITS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		Log.error("GameData: %s did not contain a JSON array" % TRAITS_PATH)
		return
	for entry: Variant in parsed:
		if not (entry is Dictionary):
			continue
		var definition: Dictionary = entry
		var id: String = definition.get("id", "")
		if id.is_empty():
			Log.error("GameData: trait definition missing an id")
			continue
		if _validate(definition):
			_definitions[id] = definition

func _validate(definition: Dictionary) -> bool:
	var id: String = definition.get("id", "?")
	var effect: Dictionary = definition.get("effect", {})
	var kind: String = effect.get("kind", "")
	match kind:
		"stat":
			var property: String = effect.get("property", "")
			if not KNOWN_STAT_PROPERTIES.has(property):
				Log.error("GameData: unrecognized stat property '%s' on trait '%s'" % [property, id])
				return false
		"detection_modifier":
			var parameter: String = effect.get("parameter", "")
			if not KNOWN_DETECTION_MODIFIER_PARAMETERS.has(parameter):
				Log.error("GameData: unrecognized detection_modifier parameter '%s' on trait '%s'" % [parameter, id])
				return false
		_:
			Log.error("GameData: unrecognized effect kind '%s' on trait '%s'" % [kind, id])
			return false
	return true

func _apply_effect(definition: Dictionary, player: Player) -> void:
	var effect: Dictionary = definition.get("effect", {})
	var kind: String = effect.get("kind", "")
	if kind == "stat":
		_apply_stat(effect, player)
	elif kind == "detection_modifier":
		_apply_detection_modifier(effect, player)

func _apply_stat(effect: Dictionary, player: Player) -> void:
	var property: String = effect.get("property", "")
	var operation: String = effect.get("operation", "")
	var value: int = int(effect.get("value", 0))
	match property:
		"noise_radius":
			player.noise_radius = _resolve(operation, player.noise_radius, value)
		"vision_range":
			player.fov.max_range = _resolve(operation, player.fov.max_range, value)
		"throw_range":
			player.throw_range = _resolve(operation, player.throw_range, value)

func _apply_detection_modifier(effect: Dictionary, player: Player) -> void:
	var parameter: String = effect.get("parameter", "")
	var operation: String = effect.get("operation", "")
	var value: int = int(effect.get("value", 0))
	match parameter:
		"guard_inner_range":
			player.traits.set_inner_range_modifier(_resolve(operation, player.traits.inner_range_modifier(), value))
		"guard_tracking_memory":
			player.traits.set_tracking_memory_modifier(_resolve(operation, player.traits.tracking_memory_modifier(), value))
		"guard_search_hops":
			player.traits.set_search_hops_modifier(_resolve(operation, player.traits.search_hops_modifier(), value))

func _resolve(operation: String, current: int, value: int) -> int:
	match operation:
		"set":
			return value
		"delta":
			return current + value
	return current
