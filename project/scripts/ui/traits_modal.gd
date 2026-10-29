class_name TraitsModal
extends ListModal

func _entry_ids() -> Array[String]:
	var player: Player = GridManager.get_player()
	if player == null:
		return []
	return player.traits.get_applied_ids()

func _entry_name(id: String) -> String:
	return GameData.get_trait_definition(id).get("name", id)

func _show_detail(id: String) -> void:
	var definition: Dictionary = GameData.get_trait_definition(id)
	_name_label.text = definition.get("name", "")
	_description_label.text = definition.get("description", "")
