extends CanvasLayer

@onready var health_container = $HealthContainer
var hearts : Array = []

@onready var score_text : Label = $ScoreText

func _ready ():
	if get_parent().in_selection:
		$HealthContainer.hide()
		score_text.hide()
		return
	hearts = health_container.get_children()
	
	var player = get_parent()
	
	player.OnTakeDamage.connect(_update_hearts)
	player.OnUpdateScore.connect(_update_score_text)
	
	_update_hearts(player.health)
	_update_score_text(PlayerStats.score)

func _process(delta: float) -> void:
	if get_parent().in_selection:
		$HealthContainer.hide()
		score_text.hide()
		return

func _update_hearts (health : int):
	for i in len(hearts):
		hearts[i].visible = i < health

func _update_score_text (score : int):
	score_text.text = "Score: " + str(score)
