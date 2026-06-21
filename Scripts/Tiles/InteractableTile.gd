class_name InteractableTile extends RefCounted

# Emitted whenever the tile's internal data changes in a way that impacts visuals
signal visualsChanged(tile: InteractableTile)


func interact(player: Player) -> void:
	pass
	
	
func tick(delta: float) -> void:
	pass
