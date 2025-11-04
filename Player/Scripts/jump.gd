extends LimboState

@export var animation_tree: AnimationTree
@onready var timer: Timer = $Timer

func _enter() -> void:
	# Set the condition to trigger the jump animation
	animation_tree["parameters/conditions/is_jumping"] = true
	agent.velocity.y = agent.JUMP_VELOCITY
	agent.cur_speed = agent.JUMP_HORIZONTAL_SPEED
	timer.start()
	timer.timeout.connect(func():
		if agent.use_gamepad:
			if Input.is_action_pressed("make_run"):
				get_root().dispatch("to_run")
			else:
				get_root().dispatch("to_idle")
		else:
			if Input.is_action_pressed("shift"):
				get_root().dispatch("to_run")
			else:
				get_root().dispatch("to_idle")
	)

func _exit() -> void:
	animation_tree["parameters/conditions/is_jumping"] = false
	agent.set_movements(true)
	agent.cur_speed = agent.RUN_SPEED

func _update(delta: float) -> void:
	var target_velocity = Vector3(agent.move_direction.x * agent.cur_speed, agent.velocity.y, agent.move_direction.z * agent.cur_speed)
	agent.velocity.x = lerp(agent.velocity.x, target_velocity.x, agent.movement_smoothing * delta)
	agent.velocity.z = lerp(agent.velocity.z, target_velocity.z, agent.movement_smoothing * delta)
	agent.face_direction(agent.move_direction, delta)
