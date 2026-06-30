class_name Item extends RefCounted

var __data: ItemData
var __type: StringName


func _init(type: StringName) -> void:
	__type = type
	

func data() -> ItemData:
	return __data
	
	
func type() -> StringName:
	return __type
