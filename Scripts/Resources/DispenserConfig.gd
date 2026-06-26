class_name DispenserConfig extends StationConfig

@export var itemData: ItemData
# TODO: Maybe change this to something that supports inspector labels?
# Example: {"quality": 1.0, "weight": 1.0}
@export var qualityDistribution: Array[Vector2] = [Vector2(1.0, 1.0)]


func dispense() -> Item:
	# Alternative to hardcoding every possibility?
	# Works fine for now, but not scalable.
	var item: Item = null
	if itemData is IngredientData:
		item = Ingredient.new(itemData, __rollQuality())
	# Assume Plate if not an Ingredient. Can add more options if needed.
	else:
		item = Plate.new()
	return item


func __rollQuality() -> float:
	if qualityDistribution.is_empty():
		return 1.0
		
	var totalWeight: float = 0.0
	for drop in qualityDistribution:
		totalWeight += drop.y
		
	var roll: float = randf() * totalWeight
	var current: float = 0.0
	
	for drop in qualityDistribution:
		current += drop.y
		if roll <= current:
			return drop.x
			
	return qualityDistribution.back().x
