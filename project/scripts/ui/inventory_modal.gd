class_name InventoryModal
extends ListModal

@onready var _usage_label: Label = %UsageLabel

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("confirm"):
		_use_selected()
		get_viewport().set_input_as_handled()
		return
	super(event)

func _entry_ids() -> Array[String]:
	var player: Player = GridManager.get_player()
	if player == null:
		return []
	return player.items.get_held_ids()

func _entry_name(id: String) -> String:
	return GameData.get_item_definition(id).get("name", id)

func _open() -> void:
	super()
	_usage_label.text = ""

func _show_detail(id: String) -> void:
	var definition: Dictionary = GameData.get_item_definition(id)
	_name_label.text = definition.get("name", "")
	_description_label.text = definition.get("description", "")
	var charges: int = GridManager.get_player().items.charges_of(id)
	_usage_label.text = "Charges: %d\nEnter: %s" % [charges, definition.get("action", "")]

func _use_selected() -> void:
	var id: String = _selected_id()
	if id.is_empty():
		return
	if GridManager.get_player().try_use_item(id):
		close()
