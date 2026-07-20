class_name PlayerTraitState extends RefCounted

var applied_ids: Array[String] = []
var _inner_range_modifier: int = 0
var _tracking_memory_modifier: int = 0
var _search_hops_modifier: int = 0
var _chest_opens_on_adjacent: bool = false
var _emits_noise_while_waiting: bool = false
var _capture_charges: int = 0
var _disguise_charges: int = 0
var _disguise_exposed: bool = false
var _seen_this_turn: bool = false
var _outer_zone_suppressed_while_waiting: bool = false
var _move_noise_multiplier_chance: int = 0
var _move_noise_multiplier: int = 1

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

## Disguise (sustained-detection-window charge): unlike Slippery's instant
## consume, this charge must keep suppressing detection for as long as the
## player stays inside a guard's cone(s), and only spend once the player is
## fully clear again — so it can't be told apart from "never triggered" by a
## single check. Tracking works in two parts:
## - has_disguise_charge()/mark_seen_this_turn(): called from
##   GuardStateMachine.check_immediate_sighting() every time a sighting would
##   otherwise escalate PATROL/CURIOUS/ALERT. Suppresses the escalation and
##   flags this turn as "seen" without touching the charge count yet.
## - resolve_disguise_turn(): called once per full turn, after every guard has
##   acted (see TurnManager.run_world_turn()), so it sees the OR of every
##   sighting this turn (both the pre-move Player._check_guard_sighting() pass
##   and each guard's own post-move check). Persists "currently exposed"
##   across turns while sightings continue; the moment a turn passes with no
##   sighting at all while exposed, that's "fully clear" — spend the charge
##   once here. Never touches the count if the player was never seen at all.
func add_disguise_charges(amount: int) -> void:
	_disguise_charges += amount

func has_disguise_charge() -> bool:
	return _disguise_charges > 0

func mark_seen_this_turn() -> void:
	_seen_this_turn = true

func resolve_disguise_turn() -> void:
	if _seen_this_turn:
		_disguise_exposed = true
	elif _disguise_exposed:
		_disguise_charges -= 1
		_disguise_exposed = false
	_seen_this_turn = false

func set_outer_zone_suppressed_while_waiting(value: bool) -> void:
	_outer_zone_suppressed_while_waiting = value

func is_outer_zone_suppressed(player_waited_last_turn: bool) -> bool:
	return _outer_zone_suppressed_while_waiting and player_waited_last_turn

func set_move_noise_multiplier_chance(one_in: int, multiplier: int) -> void:
	_move_noise_multiplier_chance = one_in
	_move_noise_multiplier = multiplier

## Rolls every `chance`-kind trait triggered `on_move`. Returns the noise
## radius multiplier to apply to this move's sound pulse (1 if nothing
## procced). Player doesn't know about probabilities or trait ids — it just
## calls this once and passes the result straight into _emit_noise().
func check_on_move_chance_effects() -> int:
	if _move_noise_multiplier_chance <= 0:
		return 1
	if randi() % _move_noise_multiplier_chance == 0:
		return _move_noise_multiplier
	return 1
