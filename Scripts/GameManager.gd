class_name GameManager extends Node2D

signal gameOver

@export var itemsAtlas: Texture2D = preload("res://Assets/Graphics/objects.png")
@export var soupsAtlas: Texture2D = preload("res://Assets/Graphics/soups.png")
@export var timeLimit: float = 300.0

@onready var hud: HUD = $HUD
@onready var orderManager: OrderManager = $OrderManager
@onready var player: Player = $Player
@onready var tileMap: TileMapLayer = $TileMap
@onready var stationSpawners: Node = get_node_or_null("StationSpawners")

# The master grid mapping coordinates to tile objects
var interactableGrid: Dictionary[Vector2i, InteractableTile] = {}
# Tracks the live visual Sprite2D nodes sitting on top of the grid
var spriteGrid: Dictionary[Vector2i, Sprite2D] = {}
# Tracks live world-space UI elements
var potProgressGrid: Dictionary[Vector2i, ProgressBar] = {}

var score: int = 0
var timeRemaining: float
var isGameOver: bool = false


func _ready() -> void:
	# Listen to the player's interaction requests.
	player.interactionRequested.connect(_on_player_interactionRequested)

	# Let the player listen for the game over signal.
	gameOver.connect(player._on_gameOver)

	# Wire the OrderManager to the HUD (Game owns the connection between its children).
	orderManager.ordersUpdated.connect(_on_orderManager_ordersUpdated)

	# Now safe to initialize the OrderManager; signal is connected.
	orderManager.setupQueues()

	# Build internal grid based on the tilemap.
	__initializeGrid()
	
	timeRemaining = timeLimit
	hud.updateScore(0)
	hud.updateTime(timeRemaining)
	
	
func _process(delta: float) -> void:
	if isGameOver:
		return
		
	timeRemaining -= delta
	if timeRemaining <= 0:
		__endGame()
	else:
		hud.updateTime(timeRemaining)
	
	# Since the tiles are not Nodes, tick them manually.
	for coords in interactableGrid:
		var tile = interactableGrid[coords]
		tile.tick(delta)
		if tile is Pot:
			__managePotProgressBar(tile, coords)
	
	
func __initializeGrid() -> void:
	# Build a lookup map of tile cell -> StationSpawner for config-driven stations.
	var spawnerMap: Dictionary[Vector2i, StationSpawner] = {}
	if has_node("StationSpawners"):
		for child in $StationSpawners.get_children():
			if child is StationSpawner:
				var cell: Vector2i = tileMap.local_to_map(child.position)
				spawnerMap[cell] = child

	var usedCells: Array[Vector2i] = tileMap.get_used_cells()
	for cell in usedCells:
		var tileData: TileData = tileMap.get_cell_tile_data(cell)
		if tileData:
			var stationType: String = tileData.get_custom_data(Globals.Stations.STATION_TYPE)
			if stationType:
				# Pass the spawner's config if one was placed on this tile.
				var config: Resource = null
				if spawnerMap.has(cell):
					config = spawnerMap[cell].config
				__createStation(stationType, cell, config)


func __createStation(stationType: StringName, coords: Vector2i, config: Resource = null) -> void:
	var newTile: InteractableTile = null

	match stationType:
		Globals.Stations.COUNTER:
			newTile = Counter.new()
		Globals.Stations.POT:
			if config and config is PotConfig:
				newTile = Pot.new(config)
			else:
				push_warning("No PotConfig found for Pot at cell ", coords)
		Globals.Stations.SERVING_WINDOW:
			newTile = ServingWindow.new()
			newTile.soupServed.connect(_on_servingWindow_soupServed)
		Globals.Stations.PLATE_DISPENSER:
			if config and config is DispenserConfig:
				newTile = Dispenser.new(config)
			else:
				push_warning("No DispenserConfig found for PlateDispenser at cell ", coords)
		Globals.Stations.ONION_DISPENSER:
			if config and config is DispenserConfig:
				newTile = Dispenser.new(config)
			else:
				push_warning("No DispenserConfig found for OnionDispenser at cell ", coords)
		Globals.Stations.TOMATO_DISPENSER:
			if config and config is DispenserConfig:
				newTile = Dispenser.new(config)
			else:
				push_warning("No DispenserConfig found for TomatoDispenser at cell ", coords)
		_:
			print("Invalid station type: ", stationType)
			
	if newTile:
		interactableGrid[coords] = newTile
		newTile.visualsChanged.connect(_on_interactableTile_visualsChanged.bind(coords))
		
		
func __endGame() -> void:
	isGameOver = true
	hud.updateTime(0.0)
	gameOver.emit()
	
	
func _on_player_interactionRequested(targetPosition: Vector2) -> void:
	var gridCoords: Vector2i = tileMap.local_to_map(targetPosition)
	if interactableGrid.has(gridCoords):
		interactableGrid[gridCoords].interact(player)


func _on_orderManager_ordersUpdated(active: Array[Recipe], queue: Array[Recipe]) -> void:
	print("Game script received signal")
	hud.updateOrders(active, queue)


func _on_servingWindow_soupServed(soup: Soup) -> void:
	var points = orderManager.evaluateServedSoup(soup)
	score += points
	hud.updateScore(score)
	print("Total score: ", score)

# --- Dynamic Visual Rendering System ---

func __managePotProgressBar(pot: Pot, coords: Vector2i) -> void:
	# If pot is cooking, a progress bar is needed.
	if pot.isCooking():
		var progressBar: ProgressBar
		
		# If a bar doesn't exist yet, create one
		if not potProgressGrid.has(coords):
			progressBar = ProgressBar.new()
			progressBar.show_percentage = false

			progressBar.custom_minimum_size = Vector2(13, 1)
			
			var tileCenter: Vector2 = tileMap.map_to_local(coords)
			progressBar.position = tileCenter + Vector2(-7, 0)
			
			add_child(progressBar)
			potProgressGrid[coords] = progressBar
		else:
			progressBar = potProgressGrid[coords]
	
		# Update the fill value
		progressBar.ratio = pot.cookingProgress()
	
	# If pot is not cooking, destroy the progress bar if it exists.
	elif potProgressGrid.has(coords):
		potProgressGrid[coords].queue_free()
		potProgressGrid.erase(coords)

	
func _on_interactableTile_visualsChanged(tile: InteractableTile, coords: Vector2i) -> void:
	# Clear existing sprite at this grid location
	if spriteGrid.has(coords) and spriteGrid[coords]:
		spriteGrid[coords].queue_free()
		spriteGrid.erase(coords)
		
	# Determine what needs to be drawn based on Tile class
	if tile is Counter:
		if tile.heldItem():
			var sprite: Sprite2D = __spawnItemSprite(tile.heldItem(), coords)
			spriteGrid[coords] = sprite
	elif tile is Pot:
		if tile.soup():
			var sprite: Sprite2D = __spawnPotOverlaySprite(tile, coords)
			spriteGrid[coords] = sprite
	
	
func __spawnItemSprite(item: Item, coords: Vector2i) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = itemsAtlas
	sprite.region_enabled = true
	
	if item is Ingredient:
		match item.type():
			Globals.Items.ONION:
				sprite.region_rect = Rect2i(1 + 1 * 17, 1, 15, 15)
			Globals.Items.TOMATO:
				sprite.region_rect = Rect2i(1 + 14 * 17, 1, 15, 15)
			_:
				print("Invalid Ingredient type: ", item.type())
		
	elif item is Plate:
		if item.soup():
			# The different plated soups are in a different texture atlas.
			sprite.texture = soupsAtlas
			sprite.region_rect = __createSoupsAtlasRect(item.soup())
			# Slide the window over to the plated soups.
			sprite.region_rect.position.x += 9 * 15
		else:
			sprite.region_rect = Rect2i(1 + 0 * 17, 1, 15, 15)
		
	# Center the sprite over the tile coordinates and add to scene tree
	var tileCenter: Vector2 = tileMap.map_to_local(coords)
	sprite.position = tileCenter
	add_child(sprite)
	return sprite
	
	
func __spawnPotOverlaySprite(pot: Pot, coords: Vector2i) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = soupsAtlas
	sprite.region_enabled = true
	
	sprite.region_rect = __createSoupsAtlasRect(pot.soup())
	
	# Slide the atlas window over to the uncooked textures if the soup isn't cooked.
	if not pot.isCooked():
		sprite.region_rect.position.x += 18 * 15
		# The "uncooked 3 ingredient" textures are offset by 1 pixel in the y direction.
		if pot.soup().numIngredients() == 3:
			sprite.region_rect.position.y += 1
	
	# Center the sprite over the tile coordinates and add to scene tree
	var tileCenter: Vector2 = tileMap.map_to_local(coords)
	sprite.position = tileCenter
	add_child(sprite)
	return sprite


func __createSoupsAtlasRect(soup: Soup) -> Rect2i:
	var rect: Rect2i
	var ingredients: Array[Ingredient] = soup.ingredients()
	var ingredientCounts: Dictionary[StringName, int] = {
		Globals.Items.ONION: 0,
		Globals.Items.TOMATO: 0
	}
	for ingredient in ingredients:
		ingredientCounts[ingredient.type()] += 1
	
	# We know that at least one ingredient is present since the Soup object exists,
	# so we can short-circuit a lot of these checks.
	
	# If the soup contains only Onions:
	if ingredientCounts[Globals.Items.TOMATO] == 0:
		# This is one of the few cases where the textures are laid out in sequence,
		# so we can just use math to figure out the right start coordinate.
		rect = Rect2i(
			(-1 + ingredientCounts[Globals.Items.ONION]) * 15,
			0, 15, 15
		)
	
	# If the soup contains only Tomatoes:
	elif ingredientCounts[Globals.Items.ONION] == 0:
		# These textures are not laid out in any proper sequence,
		# so we just have to hardcode.
		match ingredientCounts[Globals.Items.TOMATO]:
			1:
				rect = Rect2i(3 * 15, 0, 15, 15)
			2:
				rect = Rect2i(6 * 15, 0, 15, 15)
			3:
				rect = Rect2i(8 * 15, 0, 15, 15)
		
	# If the soup contains a mixture of ingredients:
	else:
		# Again, these textures have no sequence, so we have to hardcode.
		# 1 Onion, 1 Tomato
		if ingredients.size() == 2:
			rect = Rect2i(4 * 15, 0, 15, 15)
		# 2 Onions, 1 Tomato
		elif ingredientCounts[Globals.Items.ONION] == 2:
			rect = Rect2i(5 * 15, 0, 15, 15)
		# 1 Onion, 2 Tomatoes
		else:
			rect = Rect2i(7 * 15, 0, 15, 15)
	
	return rect
