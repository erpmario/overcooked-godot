class_name Player extends Area2D

# --- Signals ---
signal interactionRequested(targetPosition: Vector2)

# --- Configuration ---
# Set this to match tile size (e.g., 16, 32, 64)
@export var tileSize: int = 15
# How long (in seconds) it takes to move one tile. Lower is faster.
@export var movementSpeed: float = 0.15

@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rayCast: RayCast2D = $RayCast2D

# Map directional vectors to animation frames.
var animFrames: Dictionary[Vector2, int] = {
	Vector2.DOWN: 0,
	Vector2.RIGHT: 1,
	Vector2.UP: 2,
	Vector2.LEFT: 3
}

var __currentFacing: Vector2 = Vector2.DOWN
var __heldItem: Item = null
var __isMoving: bool = false
var __isGameOver: bool = false


func _ready() -> void:
	# When the game starts, force the player to snap perfectly to the grid
	position = position.snapped(Vector2(tileSize, tileSize))
	
	# Initialize animation frame properly
	var animFrame: int = animFrames[__currentFacing]
	animatedSprite.frame = animFrame


func heldItem() -> Item:
	return __heldItem
	

func pickUpItem(item: Item) -> bool:
	if __heldItem:
		return false
	__heldItem = item
	return true
	
	
func dropItem() -> Item:
	if not __heldItem:
		return null
	var item = __heldItem
	__heldItem = null
	return item
	
	
func isMoving() -> bool:
	return __isMoving
	

func _unhandled_input(event: InputEvent) -> void:
	# If currently sliding to a new tile (or game is over), ignore all new button presses
	if __isMoving or __isGameOver:
		return
	
	# Check all four directions to see if the player pressed one
	for direction in Inputs.inputToVector.keys():
		direction = direction as StringName
		if event.is_action_pressed(direction):
			move(direction)
			# Break out of the loop so we don't accidentally move diagonally
			break
			
	# Listen for the interaction key
	if event.is_action_pressed(Inputs.INTERACT):
		interact()
	
	# After input is processed, update sprite with proper animation set and frame.
	updateSprite()
	
	
func move(direction: StringName) -> void:
	# Get the Vector2 for the direction (e.g., Vector2(1, 0) for right)
	var directionVector: Vector2 = Inputs.inputToVector[direction]
	
	# Calculate exactly where the player will end up
	var targetPosition: Vector2 = position + (directionVector * tileSize)
	
	# Player can change direction even when up against a solid tile.
	__currentFacing = directionVector
	
	# --- Collision Check ---
	# Point the RayCast toward the target tile
	rayCast.target_position = directionVector * tileSize
	# Force the RayCast to update instantly instead of waiting for the next physics frame
	rayCast.force_raycast_update()
	
	# If the RayCast hits something, abort the movement
	if rayCast.is_colliding():
		return
		
	# --- Movement Animation ---
	__isMoving = true
	
	# Create a Tween to handle the smooth gliding animation
	var tween: Tween = create_tween()
	
	# Animate the "position" property of the player to the target position
	tween.tween_property(self, "position", targetPosition, movementSpeed).set_trans(Tween.TRANS_QUAD)
	
	# When the tween finishes its animation, unlock movement
	tween.tween_callback(func(): __isMoving = false)
	
	
func updateSprite() -> void:
	# Update the animation set based on what the player is currently holding.
	if __heldItem:
		if __heldItem is Plate:
			# The player is holding a soup, so figure out which type.
			if __heldItem.soup():
				var soupType: StringName = __heldItem.soup().type()
				match soupType:
					Globals.Soups.ONION:
						animatedSprite.animation = Globals.Animations.ONION_SOUP
					Globals.Soups.TOMATO:
						animatedSprite.animation = Globals.Animations.TOMATO_SOUP
					_:
						print("Invalid soup type: ", soupType)
			# The player is holding an empty plate.
			else:
				animatedSprite.animation = Globals.Animations.EMPTY_PLATE
		# The player is holding an ingredient, so figure out which type.
		elif __heldItem is Ingredient:
			var ingredientType: StringName = __heldItem.type()
			match ingredientType:
				Globals.Items.ONION:
					animatedSprite.animation = Globals.Animations.ONION
				Globals.Items.TOMATO:
					animatedSprite.animation = Globals.Animations.TOMATO
				_:
					print("Invalid ingredient type: ", ingredientType)
		else:
			print("Invalid item type: ", __heldItem.type())
	# The player is empty-handed.
	else:
		animatedSprite.animation = Globals.Animations.DEFAULT
	
	# Finally, update the animation frame based on the direction the player is facing.
	animatedSprite.frame = animFrames[__currentFacing]
	
	
func interact() -> void:
	var targetPosition: Vector2 = position + (__currentFacing * tileSize)
	interactionRequested.emit(targetPosition)
	

func _on_gameOver() -> void:
	__isGameOver = true
