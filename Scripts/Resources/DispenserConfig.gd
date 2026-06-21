class_name DispenserConfig extends Resource

@export var ingredientData: IngredientData
@export var qualityDistribution: Array[Vector2] = [Vector2(1.0, 1.0)]


func rollQuality() -> float:
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
