extends Node

const MOVE_UP: StringName = &"MoveUp"
const MOVE_DOWN: StringName = &"MoveDown"
const MOVE_LEFT: StringName = &"MoveLeft"
const MOVE_RIGHT: StringName = &"MoveRight"

const INTERACT: StringName = &"Interact"

# Map input actions to Godot's directional vectors.
var inputToVector: Dictionary[StringName, Vector2] = {
	MOVE_UP: Vector2.UP,
	MOVE_DOWN: Vector2.DOWN,
	MOVE_LEFT: Vector2.LEFT,
	MOVE_RIGHT: Vector2.RIGHT
}
