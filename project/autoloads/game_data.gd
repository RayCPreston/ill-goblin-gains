extends Node

## Authored dispatch: every recognized `stat`-kind property name and the
## Player field it resolves to. Add one line here per new `stat` trait —
## see docs/traits.md's Property/Parameter Reference.
const KNOWN_STAT_PROPERTIES: Array[String] = [
	"noise_radius",
	"vision_range",
	"throw_range",
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
		_:
			Log.error("GameData: unrecognized effect kind '%s' on trait '%s'" % [kind, id])
			return false
	return true

func _apply_effect(definition: Dictionary, player: Player) -> void:
	var effect: Dictionary = definition.get("effect", {})
	var kind: String = effect.get("kind", "")
	if kind == "stat":
		_apply_stat(effect, player)

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

func _resolve(operation: String, current: int, value: int) -> int:
	match operation:
		"set":
			return value
		"delta":
			return current + value
	return current
