# MainMenu3D.gd (Attached to root Node3D)
# MainMenu3D.gd
extends Node3D

@onready var camera = $Mainmenuscreen
@onready var local_button = $LocalButton
@onready var online_button = $OnlineButton
@onready var quit_button = $QuitButton


func _on_local_button_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Local game started")
		get_tree().paused = false
		get_tree().change_scene_to_file("res://Scenes/level_1.tscn")



func _on_quit_button_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Quit game")
		get_tree().quit()

#The Hover FeedBack
func _on_local_button_mouse_entered() -> void:
	local_button.scale = Vector3(1.2, 1.2, 1.2)
	 # Replace with function body.


func _on_local_button_mouse_exited() -> void:
	local_button.scale = Vector3.ONE # Replace with function body.


func _on_quit_button_mouse_entered() -> void:
	quit_button.scale = Vector3(1.2, 1.2, 1.2)
	

func _on_quit_button_mouse_exited() -> void:
	quit_button.scale = Vector3.ONE# Replace with function body.
