extends MeshInstance3D

@export var move_speed : float = 2.0
@export var move_direction : Vector3

@onready var start_pos : Vector3 = global_position
@onready var target_pos : Vector3 = start_pos + move_direction
@onready var model = $Model

func _process(delta: float) -> void:
	global_position = global_position.move_toward(target_pos, move_speed * delta)
	
	if global_position == start_pos:
		target_pos = start_pos + move_direction
	elif global_position == start_pos + move_direction:
		target_pos = start_pos
