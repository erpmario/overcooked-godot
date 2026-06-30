class_name Recipe extends Resource

@export var recipeName: StringName = &"New Soup"

# Set to a plain Texture2D or an AtlasTexture resource.
@export var sprite: Texture2D
@export var potUncookedTexture: Texture2D
@export var potCookedTexture: Texture2D

@export var ingredients: Array[IngredientData] = []

@export var baseScore: int = 5
@export var cookTime: float = 5.0
@export var spawnWeight: float = 1.0


func matchesIngredients(otherIngredients: Array[IngredientData]) -> bool:
	if ingredients.size() != otherIngredients.size():
		return false
	
	var myCounts: Dictionary[IngredientData, int] = __getCounts(ingredients)
	var theirCounts: Dictionary[IngredientData, int] = __getCounts(otherIngredients)
	
	return myCounts == theirCounts
	

func __getCounts(arr: Array[IngredientData]) -> Dictionary[IngredientData, int]:
	var counts: Dictionary[IngredientData, int] = {}
	for item in arr:
		if counts.has(item):
			counts[item] += 1
		else:
			counts[item] = 1
	return counts
