extends Node

@export var level_1 : PackedScene
@export var level_2 : PackedScene
@export var local_character_selection : PackedScene
@export var local_split_game : PackedScene

var levels : Array[PackedScene] 
func _ready() -> void:
	levels = [level_1,level_2]
