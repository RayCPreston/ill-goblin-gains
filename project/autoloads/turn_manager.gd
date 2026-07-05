extends Node

enum Phase { PLAYER, WORLD }

var _phase: Phase = Phase.PLAYER
var _player: Entity
var _world_entities: Array[Entity] = []

func register_player(player: Entity) -> void:
	_player = player
	_player.turn_ended.connect(end_player_turn)

func register_world_entity(entity: Entity) -> void:
	_world_entities.append(entity)

func unregister_world_entity(entity: Entity) -> void:
	_world_entities.erase(entity)

func is_player_turn() -> bool:
	return _phase == Phase.PLAYER

func end_player_turn() -> void:
	if RunState.is_run_over:
		return
	_phase = Phase.WORLD
	run_world_turn()

func run_world_turn() -> void:
	for entity in _world_entities:
		entity.take_turn()
	if WorldState.alert_level == WorldState.AlertLevel.ALERT:
		WorldState.tick_tracking()
	_phase = Phase.PLAYER
