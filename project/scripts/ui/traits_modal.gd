class_name TraitsModal
extends CanvasLayer

@onready var _list_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ListPanel/ListLabel
@onready var _name_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/DetailPanel/NameLabel
@onready var _description_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/DetailPanel/DescriptionLabel

var _applied_ids: Array[String] = []

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_menu"):
		_toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		var index: int = key_event.physical_keycode - KEY_1 + 1
		if index >= 1 and index <= _applied_ids.size():
			_show_detail(index - 1)
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	var player: Player = GridManager.get_player()
	if player == null:
		return
	_applied_ids = player.traits.get_applied_ids()
	_populate_list()
	_name_label.text = ""
	_description_label.text = "Press a number to view a trait."
	visible = true
	UiState.modal_open = true

func _close() -> void:
	visible = false
	UiState.modal_open = false

func _populate_list() -> void:
	var lines: PackedStringArray = []
	for i in range(_applied_ids.size()):
		var definition: Dictionary = GameData.get_definition(_applied_ids[i])
		lines.append("%d. %s" % [i + 1, definition.get("name", _applied_ids[i])])
	_list_label.text = "\n".join(lines)

func _show_detail(index: int) -> void:
	var definition: Dictionary = GameData.get_definition(_applied_ids[index])
	_name_label.text = definition.get("name", "")
	_description_label.text = definition.get("description", "")
