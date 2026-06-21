class_name Counter extends InteractableTile

var __heldItem: Item = null:
	set(value):
		__heldItem = value
		visualsChanged.emit(self)
		

func heldItem() -> Item:
	return __heldItem


func interact(player: Player) -> void:
	# If counter is empty and player is holding an item, place the item.
	if not __heldItem and player.heldItem():
		__heldItem = player.dropItem()
		print("Placed ", __heldItem.type(), " on counter.")
	
	# If counter has an item and player is empty-handed, pick up the item.
	elif __heldItem and not player.heldItem():
		if player.pickUpItem(__heldItem):
			print("Picked up ", __heldItem.type(), " from counter.")
			__heldItem = null
