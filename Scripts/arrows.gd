extends Node3D

enum Direction { LEFT, RIGHT }
@export var local_game_scene : PackedScene
@export var player_num : int
@export var is_back_btn: bool = false
@export var continue_btn : bool = false
@export var direction: Direction = Direction.RIGHT

@export var is_local : bool =  false
@export var last_player: bool = false

@export var shift_ease: Tween.EaseType = Tween.EASE_OUT
@export var shift_trans: Tween.TransitionType = Tween.TRANS_BACK

@export var player_2_text : Area3D
@onready var area_3d: Area3D = $Area3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer


@warning_ignore("unused_parameter")

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if continue_btn:
				if !is_local:
					@warning_ignore("shadowed_global_identifier", "unused_variable")
					var char = get_tree().get_first_node_in_group("Selector").in_front_char
					MultiplayerGlobal.selected_player = get_tree().get_first_node_in_group("Selector").get_selected_player()
					get_tree().get_first_node_in_group("Main_menu").move_camera_to_online_menu()
				else:
					if last_player:
						LocalGlobal.player_2 = get_tree().get_first_node_in_group("Selector").get_selected_character(2)
						if local_game_scene:
							get_tree().change_scene_to_packed(local_game_scene)
					elif is_back_btn:
						move_camera(true)
						if player_2_text:
							move_player_text()
					else:
						LocalGlobal.player_1 = get_tree().get_first_node_in_group("Selector").get_selected_character(1)
						print("PLayer 1: ",LocalGlobal.player_1)
						if player_2_text:
							move_player_text(true)
						move_camera()

			elif direction == Direction.LEFT:
				if is_local:
					get_tree().get_first_node_in_group("Selector").left_click(player_num)
				else:
					get_tree().get_first_node_in_group("Selector").left_click()
			elif direction == Direction.RIGHT:
				if is_local:
					get_tree().get_first_node_in_group("Selector").right_click(player_num)
				else:
					get_tree().get_first_node_in_group("Selector").right_click()
func _on_area_3d_mouse_entered() -> void:
	anim_player.play("mouse_entered")

func _on_area_3d_mouse_exited() -> void:
	anim_player.play_backwards("mouse_entered")
func move_camera(back:bool = false):
	var cam : Camera3D = get_tree().get_first_node_in_group("camera")
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(shift_ease)
	tween.set_trans(shift_trans)
	var final_pos : float
	if back:
		final_pos = 0
	else:
		final_pos = 7.1
	tween.tween_property(cam,"position",Vector3(final_pos,cam.position.y,cam.position.z),2)

	# Rotate positions after tween completes
	tween.finished.connect(func():
		pass
	)

func move_player_text(go_back: bool = false):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(shift_ease)
	tween.set_trans(shift_trans)
	var final_pos : float
	if go_back:
		final_pos = 2.5
	else:
		final_pos = 4.5
	var new_pos = Vector3(player_2_text.position.x,final_pos,player_2_text.position.z)
	print("New POsi ",new_pos)
	tween.tween_property(player_2_text,"position",new_pos,2)

	# Rotate positions after tween completes
	tween.finished.connect(func():
		pass
	)
