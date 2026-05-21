class_name Level
extends Node2D

func _ready() -> void:
	TileManager.initialize([$"floor-layer", $"wall-layer"])
	VisionManager.initialize($actors/goblin)
