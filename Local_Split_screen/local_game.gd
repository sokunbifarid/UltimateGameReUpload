extends Node

var selected_level
@onready var players = {
	"1": {
		"viewport": $HBoxContainer/SubViewportContainer/SubViewport,
		"camera": null,
		"player": null
	},
	"2": {
		"viewport": $HBoxContainer/SubViewportContainer2/SubViewport,
		"camera": null,
		"player": null
	}
}

@onready var player_match_stats_player_1: VBoxContainer = $HBoxContainer/SubViewportContainer/PlayerMatchStats
@onready var player_match_stats_player_2: VBoxContainer = $HBoxContainer/SubViewportContainer2/PlayerMatchStats

func _ready() -> void:
	selected_level = ScenesGlobal.levels.pick_random()
	var lv = selected_level.instantiate()
	add_child(lv)
	lv.make_local()
	var p1 = LocalGlobal.player_1.instantiate()
	var p2 = LocalGlobal.player_2.instantiate()
	p1.ready.connect(player_1_ready)
	p2.ready.connect(player_2_ready)
	players["1"]["viewport"].add_child(p1)
	players["2"]["viewport"].add_child(p2)
	
	players["1"]["player"] = players["1"]["viewport"].get_child(0)
	players["2"]["player"] = players["2"]["viewport"].get_child(0)
	players["1"]["player"].make_it_use_gamepad(false)
	players["2"]["player"].make_it_use_gamepad(true)
	
	#players["1"]["player"].ready.connect(player_1_ready)
	#players["2"]["player"].ready.connect(player_2_ready)
	
	get_tree().get_first_node_in_group("multiplayer_spawner").make_local()
	var spawn_pos = get_tree().get_first_node_in_group("respwan_point").position
	players["1"]["player"].position = spawn_pos
	players["2"]["player"].position = spawn_pos + Vector3(1,0,0)

	#set_player_match_data_properties()
#
#func set_player_match_data_properties():
	#print("happening")
	#if ScenesGlobal.current_match_type == ScenesGlobal.MATCH_TYPE.LOCAL:
		#print("got here")
		#if players["1"]["player"]:
			#print("player 1 set")
			#player_match_stats_player_1.set_monitor(players["1"]["player"])
		#else:
			#print("player 1 not set")
			#player_match_stats_player_1.hide()
		#if players["2"]["player"]:
			#print("player 2 set")
			#player_match_stats_player_2.set_monitor(players["2"]["player"])
		#else:
			#print("player 2 not set")
			#player_match_stats_player_2.hide()

func player_1_ready():
	print("subatu")
	if ScenesGlobal.current_match_type == ScenesGlobal.MATCH_TYPE.LOCAL:
		print("got here for 1")
		if players["1"]["viewport"]:
			print("player 1 set")
			player_match_stats_player_1.set_monitor(players["1"]["viewport"].get_child(0))
		else:
			print("player 1 not set")
			player_match_stats_player_1.hide()

func player_2_ready():
	print("sbatasdsa")
	if ScenesGlobal.current_match_type == ScenesGlobal.MATCH_TYPE.LOCAL:
		print("got here for 2")
		if players["2"]["viewport"]:
			print("player 2 set")
			player_match_stats_player_2.set_monitor(players["2"]["viewport"].get_child(0))
		else:
			print("player 2 not set")
			player_match_stats_player_2.hide()
