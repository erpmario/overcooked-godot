class_name Plate extends Item

var __soup: Soup = null


func _init(data: ItemData) -> void:
	super(data.name)
	__data = data


func soup() -> Soup:
	return __soup
	

func plateSoup(soupToPlate: Soup) -> bool:
	if __soup != null:
		return false
	__soup = soupToPlate
	return true
