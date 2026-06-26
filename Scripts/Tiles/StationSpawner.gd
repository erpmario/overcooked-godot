class_name StationSpawner extends Node2D

# The developer places these in the scene visually over the TileMap.
# We export a generic Resource so you can drag a PotConfig OR DispenserConfig into it.
@export var config: StationConfig


func _ready() -> void:
	# Hide the node immediately when the game runs.
	hide()
