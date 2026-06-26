class_name HUD extends CanvasLayer

@onready var scoreLabel: Label = $MarginContainer/BoxContainer/ScoreLabel
@onready var timeLabel: Label = $MarginContainer/BoxContainer/TimeLabel
@onready var ordersLabel: Label = $MarginContainer/BoxContainer/OrdersLabel
@onready var activeOrdersContainer: HBoxContainer = $MarginContainer/BoxContainer/ActiveOrdersContainer
@onready var queueLabel: Label = $MarginContainer/BoxContainer/QueueLabel
@onready var queueContainer: HBoxContainer = $MarginContainer/BoxContainer/QueueContainer


func updateScore(newScore: int) -> void:
	scoreLabel.text = "Score: " + str(newScore)


func updateTime(secondsRemaining: float) -> void:
	var minutes: int = floor(secondsRemaining / 60)
	var seconds: int = int(secondsRemaining) % 60
	timeLabel.text = "Time: %02d:%02d" % [minutes, seconds]


func updateOrders(active: Array[Recipe], queue: Array[Recipe]) -> void:
	__rebuildOrderRow(activeOrdersContainer, active)
	__rebuildOrderRow(queueContainer, queue)
	ordersLabel.visible = not active.is_empty()
	queueLabel.visible = not queue.is_empty()


func __rebuildOrderRow(container: HBoxContainer, recipes: Array[Recipe]) -> void:
	for child in container.get_children():
		child.queue_free()

	for recipe in recipes:
		var icon := TextureRect.new()
		icon.texture = recipe.sprite
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.custom_minimum_size = Vector2(24, 24)
		container.add_child(icon)
