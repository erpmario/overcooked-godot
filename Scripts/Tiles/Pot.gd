class_name Pot extends InteractableTile

var __config: PotConfig
var __soup: Soup = null
var __isCooked: bool = false
var __isCooking: bool = false
var __cookTimeElapsed: float = 0.0



func _init(config: PotConfig) -> void:
	__config = config


func soup() -> Soup:
	return __soup
	

func isCooked() -> bool:
	return __isCooked
	

func isCooking() -> bool:
	return __isCooking
	
	
func cookingProgress() -> float:
	return __cookTimeElapsed / __config.cookTimeRequired if __config.cookTimeRequired > 0.0 else 1.0


func interact(player: Player) -> void:
	# Pot does not need to respond to interaction when it is currently cooking a soup.
	if __isCooking:
		return
	
	var playerItem: Item = player.heldItem()
	
	# This is not the most efficient or clean way of implementing this by any stretch.
	# I chose to favor structural readability by separating behavior based on what Item the player is holding.
	# Should also allow for easy extensibility if more Item types are added.
	
	if playerItem is Plate:
		# Attempt to plate a cooked soup.
		if __isCooked and not playerItem.soup():
			playerItem.plateSoup(__soup)
			__soup = null
			__isCooked = false
			visualsChanged.emit(self)
			print("Plated soup.")
		else:
			__cookSoup()
	
	elif playerItem is Ingredient:
		# Attempt to add an ingredient to the pot.
		if not __isCooked:
			if not __soup:
				__soup = Soup.new()
			if __soup.numIngredients() < __config.capacity:
				__soup.addIngredient(playerItem)
				print("Added ", playerItem.type(), " to pot.")
				player.dropItem()
				visualsChanged.emit(self)
			else:
				__cookSoup()
	
	# Fall back on attempting to cook the soup.
	else:
		__cookSoup()
		

func tick(delta: float) -> void:
	if __isCooking:
		__cookTimeElapsed += delta
		if __cookTimeElapsed >= __config.cookTimeRequired:
			__isCooking = false
			__isCooked = true
			__cookTimeElapsed = 0.0
			visualsChanged.emit(self)
			print("Soup is cooked")
		

func __cookSoup() -> void:
	if __canCookSoup():
		__isCooking = true
		visualsChanged.emit(self)
		print("Soup is cooking")
		

func __canCookSoup() -> bool:
	return not __isCooked and __soup and __soup.numIngredients() > 0
