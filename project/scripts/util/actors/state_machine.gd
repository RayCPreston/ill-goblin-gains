class_name StateMachine extends RefCounted

var current_state: int = -1
var _states: Dictionary = {}

func register(state: int, on_execute: Callable, on_enter: Callable = Callable(), on_exit: Callable = Callable()) -> void:
	_states[state] = { "enter": on_enter, "execute": on_execute, "exit": on_exit }

func start(state: int) -> void:
	current_state = state
	_call(_states[current_state]["enter"])

func transition(state: int) -> void:
	if state == current_state:
		return
	if current_state in _states:
		_call(_states[current_state]["exit"])
	current_state = state
	_call(_states[current_state]["enter"])

func execute() -> void:
	if current_state in _states:
		_call(_states[current_state]["execute"])

func _call(callable: Callable) -> void:
	if callable.is_valid():
		callable.call()
