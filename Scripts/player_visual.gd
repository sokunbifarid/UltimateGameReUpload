extends MeshInstance3D

@export var rotate_rate : float = 20.0
var target_y_rot : float = 0

@onready var player : CharacterBody3D = get_parent()

func _process (delta):

	_move_bob(delta)

func _move_bob (_delta):
	var move_speed = player.velocity.length()
	
	if move_speed < 0.1 or not player.is_on_floor():
		scale.y = 1
		return
	
	var time = Time.get_unix_time_from_system()
	var y_scale = 1 + (sin(time * 30) * 0.08)
	scale.y = y_scale
