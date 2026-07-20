extends Node

## Authored dispatch: every recognized `stat`-kind property name and the
## Player field it resolves to. Add one line here per new `stat` trait —
## see docs/traits.md's Property/Parameter Reference.
const KNOWN_STAT_PROPERTIES: Array[String] = [
	"noise_radius",
	"vision_range",
	"throw_range",
	"vision_min_range",
	"smell_radius",
]

## Authored dispatch: every recognized `detection_modifier`-kind parameter name
## and the guard-side comparison it adjusts — see docs/traits.md's
## Property/Parameter Reference.
const KNOWN_DETECTION_MODIFIER_PARAMETERS: Array[String] = [
	"guard_inner_range",
	"guard_tracking_memory",
	"guard_search_hops",
	"guard_outer_zone",
]

## Authored dispatch: every recognized `flag`-kind name and the boolean
## capability it toggles — see docs/traits.md's Property/Parameter Reference.
const KNOWN_FLAGS: Array[String] = [
	"chest_opens_on_adjacent",
	"emits_noise_while_waiting",
]

## Authored dispatch: every recognized `charge`-kind trigger name and the
## charge pool it grants — see docs/traits.md's Property/Parameter Reference.
const KNOWN_CHARGE_TRIGGERS: Array[String] = [
	"on_capture",
	"on_sustained_detection_window",
]

## Authored dispatch: every recognized `chance`-kind trigger name — see
## docs/traits.md's Property/Parameter Reference.
const KNOWN_CHANCE_TRIGGERS: Array[String] = [
	"on_move",
]

## Authored dispatch: every recognized `chance`-kind outcome type — see
## docs/traits.md's Property/Parameter Reference.
const KNOWN_CHANCE_OUTCOME_TYPES: Array[String] = [
	"noise_multiplier",
]

const TRAITS_PATH: String = "res://data/traits.json"

var _definitions: Dictionary = {}

func _ready() -> void:
	_load_definitions()

func get_definition(id: String) -> Dictionary:
	return _definitions.get(id, {})

func get_ids_by_type(type: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in _definitions:
		if _definitions[id].get("type", "") == type:
			ids.append(id)
	return ids

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
		"flag":
			var flag: String = effect.get("flag", "")
			if not KNOWN_FLAGS.has(flag):
				Log.error("GameData: unrecognized flag '%s' on trait '%s'" % [flag, id])
				return false
		"charge":
			var trigger: String = effect.get("trigger", "")
			if not KNOWN_CHARGE_TRIGGERS.has(trigger):
				Log.error("GameData: unrecognized charge trigger '%s' on trait '%s'" % [trigger, id])
				return false
		"chance":
			var trigger: String = effect.get("trigger", "")
			if not KNOWN_CHANCE_TRIGGERS.has(trigger):
				Log.error("GameData: unrecognized chance trigger '%s' on trait '%s'" % [trigger, id])
				return false
			var outcome: Dictionary = effect.get("outcome", {})
			var outcome_type: String = outcome.get("type", "")
			if not KNOWN_CHANCE_OUTCOME_TYPES.has(outcome_type):
				Log.error("GameData: unrecognized chance outcome type '%s' on trait '%s'" % [outcome_type, id])
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
	elif kind == "flag":
		_apply_flag(effect, player)
	elif kind == "charge":
		_apply_charge(effect, player)
	elif kind == "chance":
		_apply_chance(effect, player)

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
		"vision_min_range":
			player.fov.min_range = _resolve(operation, player.fov.min_range, value)
		"smell_radius":
			player.smell_radius = _resolve(operation, player.smell_radius, value)

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
		"guard_outer_zone":
			if operation == "suppress":
				player.traits.set_outer_zone_suppressed_while_waiting(true)

func _apply_flag(effect: Dictionary, player: Player) -> void:
	var flag: String = effect.get("flag", "")
	var value: bool = bool(effect.get("value", false))
	match flag:
		"chest_opens_on_adjacent":
			player.traits.set_chest_opens_on_adjacent(value)
		"emits_noise_while_waiting":
			player.traits.set_emits_noise_while_waiting(value)

func _apply_charge(effect: Dictionary, player: Player) -> void:
	var trigger: String = effect.get("trigger", "")
	var charges: int = int(effect.get("charges", 0))
	match trigger:
		"on_capture":
			player.traits.add_capture_charges(charges)
		"on_sustained_detection_window":
			player.traits.add_disguise_charges(charges)

func _apply_chance(effect: Dictionary, player: Player) -> void:
	var trigger: String = effect.get("trigger", "")
	var one_in: int = int(effect.get("one_in", 0))
	var outcome: Dictionary = effect.get("outcome", {})
	var outcome_type: String = outcome.get("type", "")
	if trigger == "on_move" and outcome_type == "noise_multiplier":
		var multiplier: int = int(outcome.get("multiplier", 1))
		player.traits.set_move_noise_multiplier_chance(one_in, multiplier)

func _resolve(operation: String, current: int, value: int) -> int:
	match operation:
		"set":
			return value
		"delta":
			return current + value
	return current
