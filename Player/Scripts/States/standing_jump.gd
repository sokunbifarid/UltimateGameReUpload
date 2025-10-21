extends LimboState

@export var animation_tree: AnimationTree

func _enter() -> void:
	# Set the condition to trigger the jump animation
	animation_tree["parameters/conditions/is_standing_jump"] = true
	agent.set_movements(false)
	animation_tree.animation_finished.connect(_on_animation_tree_animation_finished)

func _exit() -> void:
	animation_tree["parameters/conditions/is_standing_jump"] = false

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "standing_jump":
		agent.set_movements(true)
		get_root().dispatch("to_idle")
