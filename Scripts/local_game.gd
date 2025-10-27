extends Node
@export var levels : Array[PackedScene]
var selected_level
@onready var players = {
	"1": {
		"viewport": $HBoxContainer/SubViewportContainer/SubViewport,
		"camera": null,
		"player": $HBoxContainer/SubViewportContainer/SubViewport/Player
	},
	"2": {
		"viewport": $HBoxContainer/SubViewportContainer2/SubViewport,
		"camera": null,
		"player": $HBoxContainer/SubViewportContainer2/SubViewport/Player2
	}
}

func _ready() -> void:
	selected_level = levels.pick_random()
	var lv = selected_level.instantiate()
	add_child(lv)
	get_tree().get_first_node_in_group("multiplayer_spawner").make_local()

	players["1"]["player"].position = get_tree().get_first_node_in_group("respwan_point").position
	players["2"]["player"].position = get_tree().get_first_node_in_group("respwan_point").position + Vector3(1,0,0)
