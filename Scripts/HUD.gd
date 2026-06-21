class_name HUD extends CanvasLayer

@onready var scoreLabel: Label = $MarginContainer/BoxContainer/ScoreLabel
@onready var timeLabel: Label = $MarginContainer/BoxContainer/TimeLabel


func updateScore(newScore: int) -> void:
	scoreLabel.text = "Score: " + str(newScore)


func updateTime(secondsRemaining: float) -> void:
	var minutes: int = floor(secondsRemaining / 60)
	var seconds: int = int(secondsRemaining) % 60
	timeLabel.text = "Time: %02d:%02d" % [minutes, seconds]
