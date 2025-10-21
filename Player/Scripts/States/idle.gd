extends LimboState

@export var animation_tree: AnimationTree

func _enter() -> void:
	animation_tree["parameters/conditions/is_idle"] = true

func _exit() -> void:
	animation_tree["parameters/conditions/is_idle"] = false

func _update(delta: float) -> void:
	if agent.is_moving:
		get_root().dispatch("to_walk")
	#if animation_tree["parameters/conditions/is_idle"] !=  true:
		#animation_tree["parameters/conditions/is_idle"] = true
