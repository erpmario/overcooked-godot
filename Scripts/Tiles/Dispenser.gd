class_name Dispenser extends InteractableTile

var __config: DispenserConfig


func _init(config: DispenserConfig) -> void:
	__config = config
	

func interact(player: Player) -> void:
	var item: Item = __config.dispense()
	if player.pickUpItem(item):
		if item is Ingredient:
			print("Got ", item.type(), " with quality x", item.quality(), " from dispenser.")
		else:
			print("Got ", item.type(), " from dispenser.")
