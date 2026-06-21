class_name Dispenser extends InteractableTile

var __dispensedItem: StringName


func _init(item: StringName) -> void:
	__dispensedItem = item
	

func interact(player: Player) -> void:
	var item: Item = null
	# I feel like this could be implemented better? But I'm not sure how to go about it.
	match __dispensedItem:
		Globals.Items.PLATE:
			item = Plate.new()
		Globals.Items.ONION:
			item = Ingredient.new(Globals.Items.ONION, Globals.Scores.ONION)
		Globals.Items.TOMATO:
			item = Ingredient.new(Globals.Items.TOMATO, Globals.Scores.TOMATO)
		_:
			print("Invalid Item type: ", __dispensedItem)
	if player.pickUpItem(item):
		print("Got ", __dispensedItem, " from dispenser.")
