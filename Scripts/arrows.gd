extends Node3D

enum Direction { LEFT, RIGHT }
@export var continue_btn : bool = false
@export var direction: Direction = Direction.RIGHT
@onready var area_3d: Area3D = $Area3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if continue_btn:
				var char = get_tree().get_first_node_in_group("Selector").in_front_char
				MultiplayerGlobal.selected_player = get_tree().get_first_node_in_group("Selector").get_selected_player()
				get_tree().change_scene_to_packed(MultiplayerGlobal.selected_level)

			elif direction == Direction.LEFT:
				get_tree().get_first_node_in_group("Selector").left_click()
			elif direction == Direction.RIGHT:
				get_tree().get_first_node_in_group("Selector").right_click()

func _on_area_3d_mouse_entered() -> void:
	anim_player.play("mouse_entered")

func _on_area_3d_mouse_exited() -> void:
	anim_player.play_backwards("mouse_entered")
