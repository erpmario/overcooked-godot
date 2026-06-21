class_name Soup extends RefCounted

var __ingredients: Array[Ingredient] = []


func ingredients() -> Array[Ingredient]:
	return __ingredients
	

func ingredientData() -> Array[IngredientData]:
	var dataList: Array[IngredientData] = []
	for ingredient in __ingredients:
		dataList.append(ingredient.data())
	return dataList


func numIngredients() -> int:
	return __ingredients.size()
	

func qualityMultiplier() -> float:
	if __ingredients.is_empty():
		return 1.0
	
	var totalQuality: float = 0.0
	for ingredient in __ingredients:
		totalQuality += ingredient.quality()
	
	return totalQuality / float(__ingredients.size())


func score() -> int:
	var _score: int = 0
	for ingredient in __ingredients:
		_score += ingredient.score()
	return _score
	

func type() -> StringName:
	# Definitely refine this later cause this is jank.
	# A soup is an "onion soup" if at least half of its ingredients are onions.
	# Otherwise, it's a "tomato soup."
	var numOnions: int = __ingredients.reduce(
		func(count, ingredient: Ingredient):
			if ingredient.type() == Globals.Items.ONION:
				return count + 1
			else:
				return count,
		0
	)
	if numOnions >= numIngredients() / 2.0:
		return Globals.Soups.ONION
	else:
		return Globals.Soups.TOMATO
	

func addIngredient(ingredient: Ingredient) -> void:
	__ingredients.append(ingredient)
