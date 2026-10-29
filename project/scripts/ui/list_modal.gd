class_name ListModal
extends CanvasLayer

## A toggled modal listing numbered entries; pressing an entry's number shows
## its detail. Subclasses supply the entries and fill the detail panel.

@export var toggle_action: StringName
@export_multiline var prompt_text: String = ""
@export_multiline var empty_text: String = ""

@onready var _list_label: Label = %ListLabel
@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel

var _ids: Array[String] = []
var _selected_index: int = -1

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		_toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	var index: int = _number_key_index(event)
	if index >= 0 and index < _ids.size():
		_select(index)
		get_viewport().set_input_as_handled()

func close() -> void:
	visible = false
	UiState.modal_open = false

func _entry_ids() -> Array[String]:
	return []

func _entry_name(_id: String) -> String:
	return ""

func _show_detail(_id: String) -> void:
	pass

func _toggle() -> void:
	if visible:
		close()
	elif not UiState.modal_open:
		_open()

func _open() -> void:
	_ids = _entry_ids()
	_selected_index = -1
	_populate_list()
	_name_label.text = ""
	_description_label.text = prompt_text if not _ids.is_empty() else ""
	visible = true
	UiState.modal_open = true

func _populate_list() -> void:
	if _ids.is_empty():
		_list_label.text = empty_text
		return
	var lines: PackedStringArray = []
	for i: int in range(_ids.size()):
		lines.append("%d. %s" % [i + 1, _entry_name(_ids[i])])
	_list_label.text = "\n".join(lines)

func _select(index: int) -> void:
	_selected_index = index
	_show_detail(_ids[index])

func _selected_id() -> String:
	return _ids[_selected_index] if _selected_index >= 0 else ""

func _number_key_index(event: InputEvent) -> int:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return -1
	var key_event: InputEventKey = event
	return key_event.physical_keycode - KEY_1
