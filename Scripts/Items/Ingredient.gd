class_name Ingredient extends Item

var __quality: float


func _init(data: IngredientData, quality: float = 1.0) -> void:
	super(data.name)
	__data = data
	__quality = quality if quality >= 0.0 else 1.0


func quality() -> float:
	return __quality


#func score() -> int:
	#return roundi(__baseScore * __quality)
