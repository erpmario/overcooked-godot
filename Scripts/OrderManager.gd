class_name OrderManager extends Node

# --- Inspector Tweakable Settings ---
@export_category("Order Settings")
@export var possibleRecipes: Array[Recipe] = []

@export_group("Queue Configurations")
@export var maxActiveOrders: int = 1
@export var visibleQueueSize: int = 2

@export_group("Scoring Multipliers")
@export var orderedMultiplier: float = 1.0
@export var nonOrderedMultiplier: float = 0.0
@export var fallbackBaseScore: int = 0

# --- Internal State ---
var activeOrders: Array[Recipe] = []
var orderQueue: Array[Recipe] = []

# Signal to tell the UI to update when the queue changes
signal ordersUpdated(active: Array[Recipe], queue: Array[Recipe])


func _ready() -> void:
	# Populate the initial queue and active orders when the game starts
	__fillQueues()


func __fillQueues() -> void:
	# Fill active orders up to the max
	while activeOrders.size() < maxActiveOrders:
		activeOrders.append(__getRandomRecipe())
		
	# Fill the visible queue up to the max
	while orderQueue.size() < visibleQueueSize:
		orderQueue.append(__getRandomRecipe())
		
	ordersUpdated.emit(activeOrders, orderQueue)


func __getRandomRecipe() -> Recipe:
	if possibleRecipes.is_empty():
		push_error("OrderManager has no recipes assigned!")
		return null
		
	# Weighted random selection algorithm
	var totaWeight: float = 0.0
	for recipe in possibleRecipes:
		totaWeight += recipe.spawnWeight
		
	var randomVal = randf() * totaWeight
	var currentWeight: float = 0.0
	
	for recipe in possibleRecipes:
		currentWeight += recipe.spawnWeight
		if randomVal <= currentWeight:
			return recipe
			
	return possibleRecipes.back()  # Fallback


# Evaluates a served soup, modifies the queue, and returns the final score
func evaluateServedSoup(servedSoup: Soup) -> int:
	var finalScore: int = 0
	var matchedRecipe: Recipe = null
	
	var soupIngredientIDs = servedSoup.ingredientData()
	
	# 1. Check if it matches any possible recipe
	for i in range(possibleRecipes.size()):
		if possibleRecipes[i].matchesIngredients(soupIngredientIDs):
			matchedRecipe = possibleRecipes[i]
			break
			
	var qualityMultiplier = servedSoup.qualityMultiplier()
	
	# 2. Calculate score and manage arrays based on match
	if matchedRecipe:
		if matchedRecipe in activeOrders:
			# It was an active order!
			finalScore = int(matchedRecipe.baseScore * orderedMultiplier * qualityMultiplier)
			
			# Remove the fulfilled order and shift the next one from the queue
			activeOrders.erase(matchedRecipe)
			if orderQueue.size() > 0:
				activeOrders.append(orderQueue.pop_front())
				
			print("Order fulfilled! Base: ", matchedRecipe.baseScore, " Quality x", qualityMultiplier, " Active Order x", orderedMultiplier, " Total: +", finalScore)
		else:
			# It was a valid recipe, but not an active one.
			finalScore = int(matchedRecipe.baseScore * nonOrderedMultiplier * qualityMultiplier)
			
			print("Served a non-ordered soup. Base: ", matchedRecipe.baseScore, " Quality x", qualityMultiplier, " Non-ordered Soup x", nonOrderedMultiplier, " Total: +", finalScore)
	else:
		# Not a match to any possible recipe.
		finalScore = int(fallbackBaseScore * nonOrderedMultiplier * qualityMultiplier) 
		print("Served a soup without an associated recipe. Base: ", fallbackBaseScore, " Quality x", qualityMultiplier, " Non-ordered Soup x", nonOrderedMultiplier, " Total: +", finalScore)
		
	# 3. Refill the empty queue slots and notify UI
	__fillQueues()
	
	return finalScore
