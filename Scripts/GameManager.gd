class_name GameManager extends Node2D

signal gameOver

@export var timeLimit: float = 300.0

@onready var hud: HUD = $HUD
@onready var orderManager: OrderManager = $OrderManager
@onready var player: Player = $Player
@onready var tileMap: TileMapLayer = $TileMap
@onready var stationSpawners: Node = $StationSpawners

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
	for child in stationSpawners.get_children():
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
				var config: StationConfig = null
				if spawnerMap.has(cell):
					config = spawnerMap[cell].config
				__createStation(stationType, cell, config)


func __createStation(stationType: StringName, coords: Vector2i, config: StationConfig = null) -> void:
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
			# Match the soup against recipes so we know what sprite to use.
			__matchSoupToRecipe(tile.soup())
			var sprite: Sprite2D = __spawnPotOverlaySprite(tile, coords)
			spriteGrid[coords] = sprite
	
	
func __spawnItemSprite(item: Item, coords: Vector2i) -> Sprite2D:
	var sprite = Sprite2D.new()
	var itemData: ItemData = item.data()

	if item is Plate and item.soup():
		# Match the plated soup to its recipe for the sprite.
		var soup: Soup = item.soup()
		__matchSoupToRecipe(soup)
		if soup.recipe:
			sprite.texture = soup.recipe.sprite
	else:
		sprite.texture = itemData.sprite

	# Center the sprite over the tile coordinates and add to scene tree
	var tileCenter: Vector2 = tileMap.map_to_local(coords)
	sprite.position = tileCenter
	add_child(sprite)
	return sprite
	
	
func __matchSoupToRecipe(soup: Soup) -> void:
	var soupIngredientData: Array[IngredientData] = soup.ingredientData()
	for recipe in orderManager.possibleRecipes:
		if recipe.matchesIngredients(soupIngredientData):
			soup.recipe = recipe
			return


func __spawnPotOverlaySprite(pot: Pot, coords: Vector2i) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	var soup: Soup = pot.soup()

	if soup.recipe:
		if pot.isCooked() and soup.recipe.potCookedTexture:
			sprite.texture = soup.recipe.potCookedTexture
		elif soup.recipe.potUncookedTexture:
			sprite.texture = soup.recipe.potUncookedTexture
		else:
			sprite.texture = soup.recipe.sprite

	# Center the sprite over the tile coordinates and add to scene tree
	var tileCenter: Vector2 = tileMap.map_to_local(coords)
	sprite.position = tileCenter
	add_child(sprite)
	return sprite
