extends Node

enum Outcome { NONE, WIN, LOSS }

var has_macguffin: bool = false
var is_run_over: bool = false
var outcome: Outcome = Outcome.NONE

func win(cause: String) -> void:
	_end_run(Outcome.WIN, cause)

func lose(cause: String) -> void:
	_end_run(Outcome.LOSS, cause)

func reset() -> void:
	has_macguffin = false
	is_run_over = false
	outcome = Outcome.NONE

func _end_run(result: Outcome, cause: String) -> void:
	if is_run_over:
		return
	is_run_over = true
	outcome = result
	var outcome_label: String = "WIN" if result == Outcome.WIN else "LOSS"
	Log.info("Run over — %s: %s" % [outcome_label, cause])
	GameEvents.run_ended.emit(result == Outcome.WIN, cause)
