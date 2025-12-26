extends VBoxContainer
#developer code
@onready var health_progress_bar_node: ProgressBar = $HeartHBoxContainer/healthProgressBar
@onready var powerup_progress_bar_node: ProgressBar = $PowerupProgressBar


var target_player: CharacterBody3D


func set_monitor(target: CharacterBody3D):
	await get_tree().process_frame
	if target:
		target_player = target
		target.connect("UpdatePlayerStats", set_player_stats)
		target.update_player_stats_in_ui()
	else:
		print("target is null")

func set_player_stats(health, powerup_exp):
	health_progress_bar_node.value = health
	powerup_progress_bar_node.value = powerup_exp
	print("received it here")
