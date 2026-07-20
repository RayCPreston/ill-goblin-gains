class_name RunStartModal
extends CanvasLayer

@onready var _positive_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PositivePanel/PositiveLabel
@onready var _negative_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/NegativePanel/NegativeLabel

func _ready() -> void:
	visible = false
	GameEvents.loadout_rolled.connect(_on_loadout_rolled)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("confirm"):
		_close()
		get_viewport().set_input_as_handled()

func _on_loadout_rolled(loadout: RunLoadout) -> void:
	_positive_label.text = _names_for(loadout.positive_trait_ids)
	_negative_label.text = _names_for(loadout.negative_trait_ids)
	visible = true
	UiState.modal_open = true

func _close() -> void:
	visible = false
	UiState.modal_open = false

func _names_for(ids: Array[String]) -> String:
	var lines: PackedStringArray = []
	for id: String in ids:
		var definition: Dictionary = GameData.get_definition(id)
		lines.append(str(definition.get("name", id)))
	return "\n".join(lines)
