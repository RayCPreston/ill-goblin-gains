class_name EndScreen
extends CanvasLayer

@onready var _outcome_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OutcomeLabel
@onready var _cause_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CauseLabel

func _ready() -> void:
	visible = false
	GameEvents.run_ended.connect(_on_run_ended)

func _on_run_ended(won: bool, cause: String) -> void:
	_outcome_label.text = "YOU ESCAPED" if won else "YOU WERE CAUGHT"
	_cause_label.text = cause
	visible = true
