extends VBoxContainer
#developer code
@onready var health_progress_bar_node: ProgressBar = $PlayerStats/HeartHBoxContainer/healthProgressBar
@onready var powerup_progress_bar_node: ProgressBar = $PlayerStats/PowerupProgressBar

var target_player: CharacterBody3D

func set_monitor(target: CharacterBody3D):
	await get_tree().process_frame
	await get_tree().process_frame
	if target:
		target_player = target
		health_progress_bar_node.value = target.health
		powerup_progress_bar_node.value = target.powerup_exp
		target_player.UpdatePlayerStats.connect(set_player_stats)
		print("target assigned: " + str(target))
	else:
		print("target is null")

func set_player_stats(health: int, powerup_exp: int):
	health_progress_bar_node.value = health
	powerup_progress_bar_node.value = powerup_exp
