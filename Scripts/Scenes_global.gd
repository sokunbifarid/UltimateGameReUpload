extends Node

@export var level_1 : PackedScene
@export var level_2 : PackedScene
@export var local_character_selection : PackedScene
@export var local_split_game : PackedScene

var levels : Array[PackedScene] 
#developer code
enum MATCH_TYPE{LOCAL, ONLINE}
var current_match_type: MATCH_TYPE = MATCH_TYPE.LOCAL
##

func _ready() -> void:
	levels = [level_1,level_2]
