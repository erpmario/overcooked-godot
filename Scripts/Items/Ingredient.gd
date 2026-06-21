class_name Ingredient extends Item

# Deprecated. Replace with Recipe scoring.
var __baseScore: int

var __data: IngredientData
var __quality: float


func _init(data: IngredientData, baseScore: int, quality: float = 1.0) -> void:
	super(data.displayName)
	__baseScore = baseScore if baseScore >= 0 else 0
	__data = data
	__quality = quality if quality >= 0.0 else 1.0


func data() -> IngredientData:
	return __data


func quality() -> float:
	return __quality


func score() -> int:
	return roundi(__baseScore * __quality)
