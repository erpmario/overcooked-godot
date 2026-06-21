class_name ServingWindow extends InteractableTile

signal soupServed(soup: Soup)


func interact(player: Player) -> void:
	var playerItem = player.heldItem()
	
	if playerItem is Plate:
		if playerItem.soup():
			soupServed.emit(playerItem.soup())
			player.dropItem()
