extends LimboState

@export var animation_tree: AnimationTree

func _enter() -> void:
	animation_tree["parameters/conditions/is_walking"] = true

func _exit() -> void:
	animation_tree["parameters/conditions/is_walking"] = false

func _update(delta: float) -> void:

	if !agent.is_moving :
		get_root().dispatch("to_idle")

	if agent.use_gamepad:
		if Input.is_action_just_pressed("make_run") :
			get_root().dispatch("to_run")
	else:
		if Input.is_action_just_pressed("shift"):
			get_root().dispatch("to_run")
