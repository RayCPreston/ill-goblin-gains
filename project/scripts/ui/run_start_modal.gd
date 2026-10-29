class_name RunStartModal
extends CanvasLayer

@onready var _positive_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PositivePanel/PositiveLabel
@onready var _negative_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/NegativePanel/NegativeLabel
@onready var _equipment_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EquipmentPanel/EquipmentLabel

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
	_positive_label.text = _names_for(loadout.positive_trait_ids, GameData.get_trait_definition)
	_negative_label.text = _names_for(loadout.negative_trait_ids, GameData.get_trait_definition)
	_equipment_label.text = _names_for(loadout.item_ids, GameData.get_item_definition)
	visible = true
	UiState.modal_open = true

func _close() -> void:
	visible = false
	UiState.modal_open = false

func _names_for(ids: Array[String], definition_of: Callable) -> String:
	var lines: PackedStringArray = []
	for id: String in ids:
		var definition: Dictionary = definition_of.call(id)
		lines.append(str(definition.get("name", id)))
	return "\n".join(lines)
