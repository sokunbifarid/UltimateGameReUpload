extends VBoxContainer
#developer code
@onready var health_progress_bar_node: ProgressBar = $PlayerStats/HeartHBoxContainer/healthProgressBar
@onready var powerup_progress_bar_node: ProgressBar = $PlayerStats/PowerupProgressBar

var target_player: CharacterBody3D

func set_monitor(target: CharacterBody3D):
	target_player = target
	target_player.UpdatePlayerStats.connect(set_player_stats)

func set_player_stats(health: int, powerup_exp: int):
	health_progress_bar_node.value = health
	powerup_progress_bar_node.value = powerup_exp
