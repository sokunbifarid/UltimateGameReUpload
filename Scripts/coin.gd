extends Area3D

@export var rotate_speed : float = 180.0

@export var bob_height : float = 0.2
@export var bob_speed : float = 5.0
@onready var start_y_pos : float = global_position.y

func _process (delta):
	# rotate
	rotation.y += deg_to_rad(rotate_speed) * delta
	
	# bob up and down
	var time = Time.get_unix_time_from_system()
	var y_pos = (1 + sin(time * bob_speed)) / 2 * bob_height
	
	global_position.y = start_y_pos + y_pos

func _on_body_entered(body):
	if not body.is_in_group("Player"):
		return
	
	body.increase_score(1)
	queue_free()
