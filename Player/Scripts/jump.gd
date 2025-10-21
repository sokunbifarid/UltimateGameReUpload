extends LimboState

@export var animation_tree: AnimationTree

func _enter() -> void:
	# Set the condition to trigger the jump animation
	animation_tree["parameters/conditions/is_jumping"] = true
	agent.velocity.y = agent.JUMP_VELOCITY
	agent.cur_speed = agent.JUMP_HORIZONTAL_SPEED
	animation_tree.animation_finished.connect(_on_animation_tree_animation_finished)
 
func _exit() -> void:
	animation_tree["parameters/conditions/is_jumping"] = false
	agent.set_movements(true)
	agent.cur_speed = agent.RUN_SPEED

func _update(delta: float) -> void:
	var target_velocity = Vector3(agent.move_direction.x * agent.cur_speed, agent.velocity.y, agent.move_direction.z * agent.cur_speed)
	agent.velocity.x = lerp(agent.velocity.x, target_velocity.x, agent.movement_smoothing * delta)
	agent.velocity.z = lerp(agent.velocity.z, target_velocity.z, agent.movement_smoothing * delta)
	agent.face_direction(agent.move_direction, delta)

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "jump":
		get_root().dispatch("to_run")
