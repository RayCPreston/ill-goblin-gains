extends Node

enum Action { NONE, MOVE, WAIT }

const MOVE_INPUT: Dictionary = {
	"move_n" : Vector2i(0, -1),
	"move_ne": Vector2i(1, -1),
	"move_e": Vector2i(1, 0),
	"move_se": Vector2i(1, 1),
	"move_s": Vector2i(0, 1),
	"move_sw": Vector2i(-1, 1),
	"move_w": Vector2i(-1, 0),
	"move_nw": Vector2i(-1, -1)
}

func get_input_action(event: InputEvent) -> Action:
	if event.is_action_pressed("wait"):
		return Action.WAIT
	for move_input in MOVE_INPUT:
		if event.is_action_pressed(move_input):
			return Action.MOVE
	return Action.NONE

func get_move_direction(event: InputEvent) -> Vector2i:
	for move_input in MOVE_INPUT:
		if event.is_action_pressed(move_input):
			return MOVE_INPUT[move_input]
	return Vector2i.ZERO
