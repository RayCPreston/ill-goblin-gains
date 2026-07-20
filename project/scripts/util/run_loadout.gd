class_name RunLoadout
extends RefCounted

var positive_trait_ids: Array[String] = []
var negative_trait_ids: Array[String] = []

func reset() -> void:
	positive_trait_ids = []
	negative_trait_ids = []

func all_trait_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.append_array(positive_trait_ids)
	ids.append_array(negative_trait_ids)
	return ids
