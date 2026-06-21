class_name Item extends RefCounted

var __type: StringName


func _init(type: StringName) -> void:
	__type = type
	
	
func type() -> StringName:
	return __type
