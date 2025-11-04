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

func _ready() -> void:
	selected_level = ScenesGlobal.levels.pick_random()
	var lv = selected_level.instantiate()
	add_child(lv)
	players["1"]["viewport"].add_child(LocalGlobal.player_1.instantiate())
	players["2"]["viewport"].add_child(LocalGlobal.player_2.instantiate())
	
	players["1"]["player"] = players["1"]["viewport"].get_child(0)
	players["2"]["player"] = players["2"]["viewport"].get_child(0)
	players["1"]["player"].make_it_use_gamepad(false)
	players["2"]["player"].make_it_use_gamepad(true)
	
	get_tree().get_first_node_in_group("multiplayer_spawner").make_local()
	var spawn_pos = get_tree().get_first_node_in_group("respwan_point").position
	players["1"]["player"].position = spawn_pos
	players["2"]["player"].position = spawn_pos + Vector3(1,0,0)
