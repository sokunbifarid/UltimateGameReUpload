extends VBoxContainer
#developer code
@onready var health_progress_bar_node: ProgressBar = $HeartHBoxContainer/healthProgressBar
@onready var powerup_progress_bar_node: ProgressBar = $PowerupProgressBar
@onready var powerup_count_down_progress_bar: ProgressBar = $PowerupCountDownProgressBar


var target_player: CharacterBody3D

func _ready() -> void:
	set_powerup_use_count_down(0, 10)

#
#func set_monitor(target: CharacterBody3D):
	#await get_tree().process_frame
	#if target:
		#target_player = target
		#target.connect("UpdatePlayerStats", set_player_stats)
		#target.update_player_stats_in_ui()
	#else:
		#print("target is null")

func set_player_stats(health, powerup_exp):
	health_progress_bar_node.value = health
	powerup_progress_bar_node.value = powerup_exp
	print("received it here")

func set_powerup_use_count_down(value: float, max_value: float):
	powerup_count_down_progress_bar.max_value = max_value
	powerup_count_down_progress_bar.value = value
