extends LimboState

@export var animation_tree: AnimationTree

func _enter() -> void:
	animation_tree["parameters/conditions/is_running"] = true

func _exit() -> void:
	animation_tree["parameters/conditions/is_running"] = false

func _update(delta: float) -> void:
	if agent.use_gamepad:
		if !Input.is_action_pressed("make_run") and agent.move_direction == Vector3.ZERO:
			get_root().dispatch("to_walk")
	else:
		if !Input.is_action_pressed("run") and agent.move_direction == Vector3.ZERO:
			get_root().dispatch("to_walk")
